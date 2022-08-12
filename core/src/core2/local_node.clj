(ns core2.local-node
  (:require [clojure.pprint :as pp]
            [core2.api :as api]
            [core2.datalog :as d]
            [core2.error :as err]
            [core2.ingester :as ingest]
            [core2.operator :as op]
            [core2.sql.parser :as p]
            [core2.sql.plan :as sql.plan]
            [core2.tx-producer :as txp]
            [core2.util :as util]
            [core2.vector.indirect :as iv]
            [juxt.clojars-mirrors.integrant.core :as ig])
  (:import (core2 IResultCursor IResultSet)
           core2.ingester.Ingester
           (core2.tx_producer ITxProducer)
           (java.io Closeable Writer)
           (java.lang AutoCloseable)
           (java.time Duration Instant)
           (java.util.concurrent CompletableFuture TimeUnit)
           (java.util.function Consumer Function)
           java.util.Iterator
           (org.apache.arrow.memory BufferAllocator RootAllocator)))

(set! *unchecked-math* :warn-on-boxed)

(definterface PreparedQueryAsync
  (^java.util.concurrent.CompletableFuture openQueryAsync #_<IResultCursor> [queryOpts])
  (^void close []))

(defprotocol PNode
  (prepare-ra ^core2.local_node.PreparedQueryAsync [_ query])
  (prepare-sql ^core2.local_node.PreparedQueryAsync [_ query])
  ;; TODO to do `-prepare-datalog` we need `d/compile-query` to not take the actual args

  ;; TODO in theory we shouldn't need this, but it's still used in tests
  (await-tx-async
    ^java.util.concurrent.CompletableFuture #_<TransactionInstant> [node tx]))

(deftype CursorResultSet [^IResultCursor cursor
                          ^AutoCloseable maybe-pq
                          ^:unsynchronized-mutable ^Iterator next-values]
  IResultSet
  (columnTypes [_] (.columnTypes cursor))

  (hasNext [res]
    (boolean
     (or (and next-values (.hasNext next-values))
         ;; need to call rel->rows eagerly - the rel may have been reused/closed after
         ;; the tryAdvance returns.
         (do
           (while (and (.tryAdvance cursor
                                    (reify Consumer
                                      (accept [_ rel]
                                        (set! (.-next-values res)
                                              (.iterator (iv/rel->rows rel))))))
                       (not (and next-values (.hasNext next-values)))))
           (and next-values (.hasNext next-values))))))

  (next [_] (.next next-values))
  (close [_]
    (.close cursor)
    (util/try-close maybe-pq)))

(defn cursor->result-set
  (^core2.IResultSet [^IResultCursor cursor]
   (cursor->result-set cursor nil))
  (^core2.IResultSet [^IResultCursor cursor, ^AutoCloseable maybe-pq]
   (CursorResultSet. cursor maybe-pq nil)))

(defrecord Node [^Ingester ingester
                 ^ITxProducer tx-producer
                 !system
                 close-fn]
  api/PClient
  (-open-datalog-async [this query args]
    (let [{ra-query :query, :keys [args]} (-> (dissoc query :basis :basis-timeout)
                                              (d/compile-query args))
          pq (prepare-ra this ra-query)]
      (try
        (-> (.openQueryAsync pq (merge {:params args}
                                       (select-keys query [:basis :basis-timeout])))
            (.thenApply (reify Function
                          (apply [_ res-cursor]
                            (try
                              (cursor->result-set res-cursor pq)
                              (catch Throwable e
                                (util/try-close res-cursor)
                                (throw e)))))))
        (catch Throwable e
          (.close pq)
          (throw e)))))

  (-open-sql-async [this query query-opts]
    (let [pq (prepare-sql this query)]
      (try
        (-> (.openQueryAsync pq query-opts)
            (.thenApply (reify Function
                          (apply [_ res-cursor]
                            (try
                              (cursor->result-set res-cursor pq)
                              (catch Throwable e
                                (util/try-close res-cursor)
                                (throw e)))))))
        (catch Throwable e
          (.close pq)
          (throw e)))))

  PNode
  (prepare-ra [_ query]
    (let [pq (op/open-prepared-ra query)]
      (reify PreparedQueryAsync
        (openQueryAsync [_ {:keys [basis ^Duration basis-timeout] :as query-opts}]
          (let [{:keys [current-time tx], :or {current-time (Instant/now)}} basis]
            (-> (ingest/snapshot-async ingester tx)
                (cond-> basis-timeout (.orTimeout (.toMillis basis-timeout) TimeUnit/MILLISECONDS))
                (util/then-apply
                  (fn [db]
                    (.openCursor pq (-> query-opts
                                        (dissoc :basis :basis-timeout)
                                        (assoc :current-time current-time
                                               :srcs {'$ db}))))))))
        AutoCloseable
        (close [_] (.close pq)))))

  (prepare-sql [this query]
    (let [{:keys [errs plan]} (-> (p/parse query)
                                  (sql.plan/plan-query))]
      (when errs
        (throw (err/illegal-arg :invalid-sql-query
                                {::err/message "Invalid SQL query:"
                                 :errs errs})))

      (let [pq (prepare-ra this plan)]
        (reify PreparedQueryAsync
          (openQueryAsync [_ query-opts]
            (.openQueryAsync pq (-> (dissoc query-opts :?)
                                    (assoc :params (zipmap (map #(symbol (str "?_" %)) (range))
                                                           (:? query-opts))))))
          (close [_] (.close pq))))))

  (await-tx-async [_ tx]
    (-> (if-not (instance? CompletableFuture tx)
          (CompletableFuture/completedFuture tx)
          tx)
        (util/then-compose (fn [tx]
                             (.awaitTxAsync ingester tx)))))

  api/PStatus
  (status [_] {:latest-completed-tx (.latestCompletedTx ingester)})

  api/PSubmitNode
  (submit-tx [_ tx-ops]
    (.submitTx tx-producer tx-ops))

  (submit-tx [_ tx-ops opts]
    (.submitTx tx-producer tx-ops opts))

  Closeable
  (close [_]
    (when close-fn
      (close-fn))))

(defmethod print-method Node [_node ^Writer w] (.write w "#<Core2Node>"))
(defmethod pp/simple-dispatch Node [it] (print-method it *out*))

(defmethod ig/prep-key ::node [_ opts]
  (merge {:ingester (ig/ref :core2/ingester)
          :tx-producer (ig/ref ::txp/tx-producer)}
         opts))

(defmethod ig/init-key ::node [_ deps]
  (map->Node (assoc deps :!system (atom nil))))

(defmethod ig/halt-key! ::node [_ ^Node node]
  (.close node))

(defmethod ig/init-key :core2/allocator [_ _] (RootAllocator.))
(defmethod ig/halt-key! :core2/allocator [_ ^BufferAllocator a] (.close a))

(defn- with-default-impl [opts parent-k impl-k]
  (cond-> opts
    (not (ig/find-derived opts parent-k)) (assoc impl-k {})))

(defn start-node ^core2.local_node.Node [opts]
  (let [system (-> (into {::node {}
                          :core2/allocator {}
                          :core2/row-counts {}
                          :core2.indexer/indexer {}
                          :core2.indexer/internal-id-manager {}
                          :core2/ingester {}
                          :core2.metadata/metadata-manager {}
                          :core2.temporal/temporal-manager {}
                          :core2.buffer-pool/buffer-pool {}
                          :core2.watermark/watermark-manager {}
                          ::txp/tx-producer {}}
                         opts)
                   (doto ig/load-namespaces)
                   (with-default-impl :core2/log :core2.log/memory-log)
                   (with-default-impl :core2/object-store :core2.object-store/memory-object-store)
                   (doto ig/load-namespaces)
                   ig/prep
                   ig/init)]

    (-> (::node system)
        (doto (-> :!system (reset! system)))
        (assoc :close-fn #(do (ig/halt! system)
                              #_(println (.toVerboseString ^RootAllocator (:core2/allocator system))))))))

(defrecord SubmitNode [^ITxProducer tx-producer, !system, close-fn]
  api/PSubmitNode
  (submit-tx [_ tx-ops]
    (.submitTx tx-producer tx-ops))

  (submit-tx [_ tx-ops opts]
    (.submitTx tx-producer tx-ops opts))

  AutoCloseable
  (close [_]
    (when close-fn
      (close-fn))))

(defmethod print-method SubmitNode [_node ^Writer w] (.write w "#<Core2SubmitNode>"))
(defmethod pp/simple-dispatch SubmitNode [it] (print-method it *out*))

(defmethod ig/prep-key ::submit-node [_ opts]
  (merge {:tx-producer (ig/ref :core2.tx-producer/tx-producer)}
         opts))

(defmethod ig/init-key ::submit-node [_ {:keys [tx-producer]}]
  (map->SubmitNode {:tx-producer tx-producer, :!system (atom nil)}))

(defmethod ig/halt-key! ::submit-node [_ ^SubmitNode node]
  (.close node))

(defn start-submit-node ^core2.local_node.SubmitNode [opts]
  (let [system (-> (into {::submit-node {}
                          :core2.tx-producer/tx-producer {}
                          :core2/allocator {}}
                         opts)
                   ig/prep
                   (doto ig/load-namespaces)
                   ig/init)]

    (-> (::submit-node system)
        (doto (-> :!system (reset! system)))
        (assoc :close-fn #(ig/halt! system)))))
