(ns core2.core.datalog
  (:require [clojure.set :as set]
            [clojure.spec.alpha :as s]
            [clojure.string :as str]
            [core2.error :as err]
            [core2.logical-plan :as lp]
            [core2.operator :as op]
            [core2.util :as util]
            [core2.vector.writer :as vw])
  (:import (clojure.lang MapEntry)
           (core2.operator IRaQuerySource)
           (java.lang AutoCloseable)
           (java.time LocalDate)
           (org.apache.arrow.memory BufferAllocator)))

(s/def ::logic-var simple-symbol?)

;; TODO flesh out
(def ^:private eid? (some-fn string? number? inst? keyword? (partial instance? LocalDate)))

(s/def ::eid eid?)
(s/def ::value (some-fn eid?))

(s/def ::fn-call
  (s/and list?
         (s/cat :f simple-symbol?
                :args (s/* ::form))))

(s/def ::form
  (s/or :logic-var ::logic-var
        :fn-call ::fn-call
        :literal ::value))

(s/def ::find-arg
  (s/or :logic-var ::logic-var
        :form ::form))

(s/def ::semi-join
  (s/cat :exists '#{exists?}
         :args ::args-list
         :terms (s/+ ::term)))

(s/def ::anti-join
  (s/cat :not-exists '#{not-exists?}
         :args ::args-list
         :terms (s/+ ::term)))

(s/def ::find (s/coll-of ::find-arg :kind vector? :min-count 1))
(s/def ::keys (s/coll-of symbol? :kind vector?))

(s/def ::args-list (s/coll-of ::logic-var, :kind vector?, :min-count 0))

(s/def ::binding
  (s/or :collection (s/tuple ::logic-var '#{...})
        :relation (s/tuple ::args-list)
        :scalar ::logic-var
        :tuple ::args-list))

(s/def ::source
  (s/and simple-symbol?
         (comp #(str/starts-with? % "$") name)))

(s/def ::in-binding
  (s/or :source ::source
        :collection (s/tuple ::logic-var '#{...})
        :relation (s/tuple ::args-list)
        :scalar ::logic-var
        :tuple ::args-list))

(s/def ::in (s/* ::in-binding))

(s/def ::e (s/or :literal ::eid, :logic-var ::logic-var))

(s/def ::triple
  (s/and vector?
         (s/conformer identity vec)
         (s/cat :e ::e
                :a keyword?
                :v (s/? (s/or :literal ::value,
                              :logic-var ::logic-var
                              :unwind (s/tuple ::logic-var #{'...}))))))

(s/def ::call-clause
  (s/and vector?
         ;; top-level can only be a fn-call because otherwise the EDN Datalog syntax is ambiguous
         ;; (it wasn't ever meant to handle this...)
         (s/cat :form (s/spec (s/or :fn-call ::fn-call))
                :return (s/? ::binding))))

(s/def ::and (s/cat :and #{'and}
                    :terms (s/+ ::term)))

(s/def ::or-branches
  (s/+ (s/and (s/or :term ::term, :and ::and)
              (s/conformer (fn [[type arg]]
                             (case type
                               :term [arg]
                               :and (:terms arg)))
                           (fn [terms]
                             (if (= (count terms) 1)
                               [:term (first terms)]
                               [:and {:and 'and, :terms terms}]))))))

(s/def ::union-join
  (s/cat :union-join #{'union-join}
         :args ::args-list
         :branches ::or-branches))

(s/def ::sub-query
  (s/cat :q #{'q}, :query ::query))

(s/def ::temporal-literal ::util/datetime-value)

(s/def ::for-all-app-time (s/cat :k #{'for-all-app-time}, :e ::e))

(s/def ::for-app-time-at
  (s/cat :k #{'for-app-time-at}, :e ::e,
         :time-at ::temporal-literal))

(s/def ::for-app-time-in
  (s/cat :k #{'for-app-time-in}, :e ::e
         :time-from (s/nilable ::temporal-literal)
         :time-to (s/nilable ::temporal-literal)))

(s/def ::for-all-sys-time (s/cat :k #{'for-all-sys-time}, :e ::e))

(s/def ::for-sys-time-at
  (s/cat :k #{'for-sys-time-at}, :e ::e,
         :time-at ::temporal-literal))

(s/def ::for-sys-time-in
  (s/cat :k #{'for-sys-time-in}, :e ::e
         :time-from (s/nilable ::temporal-literal)
         :time-to (s/nilable ::temporal-literal)))

(s/def ::rule
  (s/and list?
         (s/cat :name simple-symbol?
                :args (s/+ (s/or :literal ::value,
                                 :logic-var ::logic-var)))))

(s/def ::rule-head
  (s/and list?
         (s/cat :name simple-symbol?
                :args (s/+ ::logic-var))))

(s/def ::rule-definition
  (s/and vector?
         (s/cat :head ::rule-head
                :body (s/+ ::term))))

(s/def ::rules (s/coll-of ::rule-definition :kind vector?))

(s/def ::term
  (s/or :triple ::triple
        :semi-join ::semi-join
        :anti-join ::anti-join
        :union-join ::union-join

        :for-all-app-time ::for-all-app-time
        :for-app-time-in ::for-app-time-in
        :for-app-time-at ::for-app-time-at

        :for-all-sys-time ::for-all-sys-time
        :for-sys-time-in ::for-sys-time-in
        :for-sys-time-at ::for-sys-time-at

        :call ::call-clause
        :sub-query ::sub-query
        :rule ::rule))

(s/def ::where
  (s/coll-of ::term :kind vector? :min-count 1))

(s/def ::offset nat-int?)
(s/def ::limit nat-int?)

(s/def ::order-element
  (s/and vector?
         (s/cat :find-arg ::find-arg
                :direction (s/? #{:asc :desc}))))

(s/def ::order-by (s/coll-of ::order-element :kind vector?))

(s/def ::query
  (s/keys :req-un [::find]
          :opt-un [::keys ::in ::where ::order-by ::offset ::limit ::rules]))

(s/def ::relation-arg
  (s/or :maps (s/coll-of (s/map-of simple-keyword? any?))
        :vecs (s/coll-of vector?)))

(defn- conform-query [query]
  (let [conformed-query (s/conform ::query query)]
    (when (s/invalid? conformed-query)
      (throw (err/illegal-arg :malformed-query
                              {::err/message "Malformed query"
                               :query query
                               :explain (s/explain-data ::query query)})))
    conformed-query))

(comment

  (s/conform ::query '{:find [(/ x y) (sum z)]
                       :keys [x-div-y sum-z]
                       :in [[[x y z]]]})

  (s/conform ::query '{:find [(/ x y) (sum z)]
                       :where [[(= (pos? x))]]
                       :keys [x-div-y sum-z]
                       :in [[[x y z]]]})

  (s/conform ::query '{:find [e]
                       :in [[first-name]]
                       :where [[e :first-name first-name]]})

  (s/conform ::query
             '{:find [e]
               :in [[first-name ...]]
               :where [[e :first-name first-name]]})

  (def x [[:triple {:e [:logic-var 'e], :a :first-name, :v [:logic-var 'first-name]}]])

  :FIXME)

(declare plan-query)

(defn- col-sym
  ([col]
   (-> (symbol col) (vary-meta assoc :column? true)))
  ([prefix col]
   (col-sym (str (format "%s_%s" prefix col)))))

(defn- wrap-select [plan predicates]
  (-> (case (count predicates)
        0 plan
        1 [:select (first predicates) plan]
        [:select (list* 'and predicates) plan])
      (with-meta (meta plan))))

(defn- unify-preds [var->cols]
  ;; this enumerates all the binary join conditions
  ;; once mega-join has multi-way joins we could throw the multi-way `=` over the fence
  (->> (vals var->cols)
       (filter #(> (count %) 1))
       (mapcat
        (fn [cols]
          (->> (set (for [col cols
                          col2 cols
                          :when (not= col col2)]
                      (set [col col2])))
               (map #(list* '= %)))))
       (vec)))

(defn- wrap-unify [plan var->cols]
  (-> [:project (vec (for [[lv cols] var->cols]
                       (or (cols lv)
                           {(col-sym lv) (first cols)})))
       (-> plan
           (wrap-select (unify-preds var->cols)))]
      (with-meta (-> (meta plan) (assoc ::vars (set (keys var->cols)))))))

(defn- with-unique-cols [plans param-vars]
  (as-> plans plans
    (->> plans
         (into [] (map-indexed
                   (fn [idx plan]
                     (let [{::keys [vars]} (meta plan)
                           var->col (->> vars
                                         (into {} (map (juxt col-sym (partial col-sym (str "_r" idx))))))]
                       (-> [:rename var->col
                            plan]
                           (with-meta (into (meta plan)
                                            {::vars (set (vals var->col))
                                             ::var->col var->col}))))))))
    (-> plans
        (with-meta {::var->cols (-> (concat (->> plans (mapcat (comp ::var->col meta)))
                                            param-vars)
                                    (->> (group-by key))
                                    (update-vals #(into #{} (map val) %)))}))))

(defn- mega-join [rels param-vars]
  (let [rels (with-unique-cols rels param-vars)]
    (-> (case (count rels)
          0 (-> [:table [{}]] (with-meta {::vars #{}}))
          1 (first rels)
          [:mega-join [] rels])
        (wrap-unify (::var->cols (meta rels))))))

(defn- form-vars [form]
  (letfn [(form-vars* [[form-type form-arg]]
            (case form-type
              :fn-call (into #{} (mapcat form-vars*) (:args form-arg))
              :logic-var #{form-arg}
              :literal #{}
              :form (form-vars form-arg)))]
    (form-vars* form)))

(defn- binding-vars [binding]
  (letfn [(binding-vars* [[binding-type binding-arg]]
            (case binding-type
              :source #{}
              :collection #{(first binding-arg)}
              :relation (set (first binding-arg))
              :scalar #{binding-arg}
              :tuple (set binding-arg)))]
    (binding-vars* binding)))

(defn- combine-term-vars [term-varses]
  (let [{:keys [provided-vars] :as vars} (->> term-varses
                                              (apply merge-with set/union))]
    (-> vars
        (update :required-vars set/difference provided-vars))))

(defn- term-vars [[term-type term-arg]]
  (letfn [(sj-term-vars [spec]
            (let [{:keys [args terms]} term-arg
                  arg-vars (set args)
                  {:keys [required-vars]} (combine-term-vars (map term-vars terms))]

              (when-let [unsatisfied-vars (not-empty (set/difference required-vars arg-vars))]
                (throw (err/illegal-arg :unsatisfied-vars
                                        {:vars unsatisfied-vars
                                         :term (s/unform spec term-arg)})))

              ;; semi-joins do not provide vars
              {:required-vars required-vars}))]

    (case term-type
      :call (let [{:keys [form return]} term-arg]
              {:required-vars (form-vars form)
               :provided-vars (when-let [[return-type return-arg] return]
                                (case return-type
                                  :scalar #{return-arg}))})

      :triple {:provided-vars (into #{}
                                    (comp (map term-arg)
                                          (keep (fn [[val-type val-arg]]
                                                  (when (= :logic-var val-type)
                                                    val-arg))))
                                    [:e :v])}

      :union-join (let [{:keys [args branches]} term-arg
                        arg-vars (set args)
                        branches-vars (for [branch branches]
                                        (into {:branch branch}
                                              (combine-term-vars (map term-vars branch))))
                        provided-vars (->> branches-vars
                                           (map (comp set :provided-vars))
                                           (apply set/intersection))
                        required-vars (->> branches-vars
                                           (map (comp set :required-vars))
                                           (apply set/union))]

                    (when-let [unsatisfied-vars (not-empty (set/difference required-vars arg-vars))]
                      (throw (err/illegal-arg :unsatisfied-vars
                                              {:vars unsatisfied-vars
                                               :term (s/unform ::union-join term-arg)})))

                    {:provided-vars (set/intersection arg-vars provided-vars)
                     :required-vars (set/difference arg-vars provided-vars)})

      :semi-join (sj-term-vars ::semi-join)
      :anti-join (sj-term-vars ::anti-join)

      :sub-query (let [{:keys [query]} term-arg]
                   {:provided-vars (set (or (:keys query)
                                            (->> (:find query)
                                                 (filter (comp #{:logic-var} first))
                                                 (map form-vars)
                                                 (apply set/union))))
                    :required-vars (set (map second (:in query)))}))))

(defn- ->param-sym [lv]
  (-> (symbol (str "?" (name lv)))
      (with-meta {::param? true})))

(defn- plan-in-tables [{in-bindings :in}]
  (let [in-bindings (->> in-bindings
                         (into [] (map-indexed
                                   (fn [idx [binding-type binding-arg]]
                                     (let [table-key (symbol (str "?in" idx))]
                                       (-> (case binding-type
                                             :source {::in-cols [binding-arg]}
                                             :scalar {::vars #{binding-arg}, ::in-cols [(->param-sym binding-arg)]}
                                             :tuple {::vars (set binding-arg), ::in-cols (mapv ->param-sym binding-arg)}
                                             :relation (let [cols (first binding-arg)]
                                                         {::table-key table-key, ::in-cols cols, ::vars (set cols)})
                                             :collection (let [col (first binding-arg)]
                                                           {::table-key table-key, ::vars #{col}, ::in-cols [col]}))
                                           (assoc ::binding-type binding-type)))))))]
    (-> in-bindings
        (->> (into [] (keep (fn [{::keys [table-key in-cols vars]}]
                              (when table-key
                                (-> [:table in-cols table-key]
                                    (with-meta {::vars vars})))))))
        (with-meta {::in-bindings in-bindings
                    ::param-vars (into {}
                                       (comp (remove ::table-key)
                                             (mapcat ::vars)
                                             (map (juxt identity ->param-sym)))
                                       in-bindings)}))))

(defn- ->temporal-clauses [temporal-rules]
  (letfn [(with-time-in-clause [clauses time-k {:keys [time-from time-to]}]
            (-> clauses (assoc time-k (list 'in time-from time-to))))

          (with-time-at-clause [clauses time-k {:keys [time-at]}]
            (-> clauses (assoc time-k (list 'at time-at))))]

    (->> temporal-rules
         (reduce (fn [acc {:keys [e] :as rule}]
                   (-> acc
                       (update e
                               (fn [e-preds {:keys [k] :as rule}]
                                 (case k
                                   for-all-app-time (-> e-preds (assoc :for-app-time :all-time))
                                   for-app-time-in (-> e-preds (with-time-in-clause :for-app-time rule))
                                   for-app-time-at (-> e-preds (with-time-at-clause :for-app-time rule))

                                   for-all-sys-time (-> e-preds (assoc :for-sys-time :all-time))
                                   for-sys-time-in (-> e-preds (with-time-in-clause :for-sys-time rule))
                                   for-sys-time-at (-> e-preds (with-time-at-clause :for-sys-time rule))))
                               rule)))
                 {}))))

(defn- wrap-scan-col-preds [scan-col col-preds]
  (case (count col-preds)
    0 scan-col
    1 {scan-col (first col-preds)}
    {scan-col (list* 'and col-preds)}))

(defn- plan-scan [triples temporal-clauses]
  (let [attrs (into #{} (map :a) triples)

        attr->lits (-> triples
                       (->> (keep (fn [{:keys [a], [v-type v-arg] :v}]
                                    (when (= :literal v-type)
                                      {:a a, :lit v-arg})))
                            (group-by :a))
                       (update-vals #(into #{} (map :lit) %)))]

    (-> [:scan {:table (or (some-> (first (attr->lits '_table)) symbol)
                           'xt_docs)
                :for-app-time (:for-app-time temporal-clauses '(at :now))
                ;; defaults handled by scan
                :for-sys-time (:for-sys-time temporal-clauses)}
         (-> attrs
             (disj '_table)
             (->> (mapv (fn [attr]
                          (-> attr
                              (wrap-scan-col-preds (for [lit (get attr->lits attr)]
                                                     (list '= attr lit))))))))]
        (with-meta {::vars attrs}))))

(defn- attr->unwind-col [a]
  (col-sym "__uw" a))

(defn- wrap-unwind [plan triples]
  (->> triples
       (transduce
        (comp (keep (fn [{:keys [a], [v-type _v-arg] :v}]
                      (when (= v-type :unwind)
                        a)))
              (distinct))

        (completing (fn [plan a]
                      (let [uw-col (attr->unwind-col a)]
                        (-> [:unwind {uw-col a}
                             plan]
                            (vary-meta update ::vars conj uw-col)))))
        plan)))

(defn- plan-triples [triples temporal-clauses]
  (let [triples (group-by :e triples)]
    (vec
     (for [e (set/union (set (keys triples))
                        (set (keys temporal-clauses)))
           :let [triples (->> (conj (get triples e) {:e e, :a :id, :v e})
                              (map #(update % :a col-sym)))
                 temporal-clauses (get temporal-clauses e)]]
       (let [var->cols (-> triples
                           (->> (keep (fn [{:keys [a], [v-type v-arg] :v}]
                                        (case v-type
                                          :logic-var {:lv v-arg, :col a}
                                          :unwind {:lv (first v-arg), :col (attr->unwind-col a)}
                                          nil)))
                                (group-by :lv))
                           (update-vals #(into #{} (map :col) %)))]

         (-> (plan-scan triples temporal-clauses)
             (wrap-unwind triples)
             (wrap-unify var->cols)))))))

(defn- plan-call [{:keys [form return]}]
  (letfn [(with-col-metadata [[form-type form-arg]]
            [form-type
             (case form-type
               :logic-var (if (str/starts-with? (name form-arg) "?")
                            form-arg
                            (col-sym form-arg))
               :fn-call (-> form-arg (update :args #(mapv with-col-metadata %)))
               :literal form-arg)])]
    (-> (s/unform ::form (with-col-metadata form))
        (with-meta (into {::required-vars (form-vars form)}

                         (when-let [[return-type return-arg] return]
                           (-> (case return-type
                                 :scalar {::return-var return-arg
                                          ::vars #{return-arg}})
                               (assoc ::return-type return-type))))))))

(defn- wrap-calls [plan calls]
  (letfn [(wrap-scalars [plan scalars]
            (let [scalars (->> scalars
                               (into [] (map-indexed
                                         (fn [idx form]
                                           (let [{::keys [return-var]} (meta form)]
                                             (-> form
                                                 (vary-meta assoc ::return-col (col-sym (str "_c" idx) return-var))))))))
                  var->cols (-> (concat (->> (::vars (meta plan)) (map (juxt identity identity)))
                                        (->> scalars (map (comp (juxt ::return-var ::return-col) meta))))
                                (->> (group-by first))
                                (update-vals #(into #{} (map second) %)))]
              (-> [:map (vec (for [form scalars]
                               {(::return-col (meta form)) form}))
                   plan]
                  (with-meta (-> (meta plan) (update ::vars into (map ::return-col scalars))))
                  (wrap-unify var->cols))))]

    (let [{selects nil, scalars :scalar} (group-by (comp ::return-type meta) calls)]
      (-> plan
          (cond-> scalars (wrap-scalars scalars))
          (wrap-select selects)))))

(defn- ->apply-mapping [apply-params]
  ;;TODO symbol names will clash with nested applies
  ;; (where an apply is nested inside the dep side of another apply)
  (when (seq apply-params)
    (->> (for [param apply-params]
           (let [param-symbol (-> (symbol (str "?ap_" param))
                                  (with-meta {:correlated-column? true}))]
             (MapEntry/create param param-symbol)))
         (into {}))))

(defn- plan-semi-join [sj-type {:keys [args terms] :as sj}]
  (let [{sj-required-vars :required-vars} (term-vars [sj-type sj])
        required-vars (if (seq sj-required-vars) (set args) #{})
        apply-mapping (->apply-mapping required-vars)]

    (-> (plan-query
         (cond-> {:find (vec (for [arg args]
                               [:logic-var arg]))
                  :where terms}
           (seq required-vars) (assoc ::apply-mapping apply-mapping)))
        (vary-meta into {::required-vars required-vars
                         ::apply-mapping apply-mapping}))))

(defn- wrap-semi-joins [plan sj-type semi-joins]
  (->> semi-joins
       (reduce (fn [acc sq-plan]
                 (let [{::keys [apply-mapping]} (meta sq-plan)]
                   (-> (if apply-mapping
                         [:apply sj-type apply-mapping
                          acc sq-plan]

                         [sj-type (->> (::vars (meta sq-plan))
                                       (mapv (fn [v] {v v})))
                          acc sq-plan])
                       (with-meta (meta acc)))))
               plan)))

(defn- plan-union-join [{:keys [args branches] :as uj}]
  (let [{:keys [required-vars]} (term-vars [:union-join uj])
        apply-mapping (->apply-mapping required-vars)]
    (-> branches
        (->> (mapv (fn [branch]
                     (plan-query
                      {:find (vec (for [arg args]
                                    [:logic-var arg]))
                       ::apply-mapping apply-mapping
                       :where branch})))
             (reduce (fn [acc plan]
                       (-> [:union-all acc plan]
                           (with-meta (meta acc))))))
        (vary-meta into {::required-vars required-vars, ::apply-mapping apply-mapping}))))

(defn- wrap-union-joins [plan union-joins param-vars]
  (if-let [apply-mapping (->> union-joins
                              (into {} (mapcat (comp ::apply-mapping meta)))
                              not-empty)]
    (let [sq-plan (mega-join union-joins param-vars)
          [plan-u sq-plan-u :as rels] (with-unique-cols [plan sq-plan] param-vars)
          apply-mapping-u (update-keys apply-mapping (::var->col (meta plan-u)))]
      (-> [:apply :cross-join apply-mapping-u
           plan-u sq-plan-u]
          (wrap-unify (::var->cols (meta rels)))))

    (mega-join (into [plan] union-joins) param-vars)))

(defn- plan-sub-query [{:keys [query]}]
  (let [required-vars (->> (:in query)
                           (into #{} (map
                                      (fn [[in-type in-arg :as in]]
                                        (when-not (= in-type :scalar)
                                          (throw (err/illegal-arg :non-scalar-subquery-param
                                                                  (s/unform ::in-binding in))))
                                        in-arg))))
        apply-mapping (->apply-mapping required-vars)]
    (-> (plan-query (-> query
                        (dissoc :in)
                        (assoc ::apply-mapping apply-mapping)))
        (vary-meta into {::required-vars required-vars, ::apply-mapping apply-mapping}))))

(defn- wrap-sub-queries [plan sub-queries param-vars]
  (if-let [apply-mapping (->> sub-queries
                              (into {} (mapcat (comp ::apply-mapping meta)))
                              (not-empty))]
    (let [sq-plan (mega-join sub-queries param-vars)
          [plan-u sq-plan-u :as rels] (with-unique-cols [plan sq-plan] param-vars)
          apply-mapping-u (update-keys apply-mapping (::var->col (meta plan-u)))]
      (-> [:apply :cross-join apply-mapping-u
           plan-u sq-plan-u]
          (wrap-unify (::var->cols (meta rels)))))

    (mega-join (into [plan] sub-queries) param-vars)))

;;;;;;;;;;;;;;;;;;;;;;;;
;; rule substitution
;;;;;;;;;;;;;;;;;;;;;;;;

(defrecord ReplacementCtx [var->replacement replacement-fn])

(defn ->replacement-ctx [var->replacement replacement-fn]
  (->ReplacementCtx var->replacement replacement-fn))

(defn get-replacement [{:keys [var->replacement replacement-fn] :as ctx} var]
  (if-let [replacement (var->replacement var)]
    [replacement ctx]
    (let [replacement (replacement-fn var)]
      [replacement (update ctx :var->replacement assoc var replacement)])))

(defn new-replacement-ctx [vars-to-keep {:keys [var->replacement] :as ctx}]
  (assoc ctx :var->replacement (select-keys var->replacement vars-to-keep)))

(defn wrap-replacement [replacement]
  (if (simple-symbol? replacement) [:logic-var replacement] [:literal replacement]))

(defn replace-arg-list [arg-list ctx]
  (reduce (fn [[arg-list ctx] var]
            (let [[replacement ctx] (get-replacement ctx var)]
              [(if (simple-symbol? replacement)
                 (conj arg-list replacement)
                 arg-list) ctx]))
          [[] ctx]
          arg-list))

(declare replace-vars*)

(defmulti replace-vars (fn [clause _replace-ctx] (first clause))
  :default ::default)

(defmethod replace-vars ::default [[type _] _]
  (throw (ex-info "No such clause known!" {:type type})))

(defmethod replace-vars :logic-var [[_ var] replace-ctx]
  (let [[replacement new-ctx] (get-replacement replace-ctx var)]
    [(wrap-replacement replacement) new-ctx]))

(defmethod replace-vars :literal [literal replace-ctx]
  [literal replace-ctx])

(defmethod replace-vars :scalar [[_ var] replace-ctx]
  (let [[replacement new-ctx] (get-replacement replace-ctx var)]
    [[:scalar replacement] new-ctx]))

(defmethod replace-vars :form [[_ form] replace-ctx]
  (let [[replacement new-ctx] (replace-vars form replace-ctx)]
    [[:form replacement] new-ctx]))

(defmethod replace-vars :triple [[_ {:keys [e v]} :as triple] replace-cxt]
  (let [[new-e replace-ctx] (replace-vars e replace-cxt)
        [new-v replace-ctx] (replace-vars v replace-ctx)]
    [(-> triple (update 1 assoc :e new-e) (update 1 assoc :v new-v))
     replace-ctx]))

(defmethod replace-vars :semi-join [[_ {:keys [args terms]}] replace-ctx]
  (let [[new-args replace-ctx] (replace-arg-list args replace-ctx)
        new-ctx (new-replacement-ctx args replace-ctx)
        [new-terms _] (replace-vars* terms new-ctx)]
    [[:semi-join
      {:exists 'exists?
       :args new-args
       :terms new-terms}]
     replace-ctx]))

(defmethod replace-vars :anti-join [[_ {:keys [args terms]}] replace-ctx]
  (let [[new-args replace-ctx] (replace-arg-list args replace-ctx)
        new-ctx (new-replacement-ctx args replace-ctx)
        [new-terms _] (replace-vars* terms new-ctx)]
    [[:anti-join
      {:not-exists 'not-exists?
       :args new-args
       :terms new-terms}]
     replace-ctx]))

(defmethod replace-vars :union-join [[_ {:keys [args branches]}] replace-ctx]
  (let [[new-args replace-ctx] (replace-arg-list args replace-ctx)
        new-ctx (new-replacement-ctx args replace-ctx)
        [new-branches _] (reduce (fn [[brs ctx] branch]
                                   (let [[new-br ctx] (replace-vars* branch ctx)]
                                     [(conj brs new-br) ctx]))
                                 [[] new-ctx]
                                 branches)]
    [[:union-join
      {:union-join 'union-join
       :args new-args
       :branches new-branches}]
     replace-ctx]))

(defmethod replace-vars :call [[_ {:keys [form]} :as _call] replace-ctx]
  (let [[fn-call new-ctx] (replace-vars form replace-ctx)]
    [[:call {:form fn-call}] new-ctx]))

(defmethod replace-vars :fn-call [[_ {:keys [args]} :as fn-call] replace-ctx]
  (let [[new-args new-ctx]
        (reduce (fn [[new-args replace-ctx] arg]
                  (let [[new-arg replace-ctx] (replace-vars arg replace-ctx)]
                    [(conj new-args new-arg) replace-ctx]))
                [[] replace-ctx]
                args)]
    [(update fn-call 1 assoc :args new-args) new-ctx]))

(defmethod replace-vars :sub-query [[_ {:keys [query]} :as _sub-query] replace-ctx]
  (let [{:keys [find in keys where order-by rules]} query]
    (if-not rules
      (let [[new-find replace-ctx] (replace-vars* find replace-ctx)
            [new-in replace-ctx] (replace-vars* in replace-ctx)
            [new-keys replace-ctx] (reduce (fn [[res replace-ctx] key-symbol]
                                             (let [[replacement new-replace-ctx] (get-replacement replace-ctx key-symbol)]
                                               [(conj res replacement) new-replace-ctx]))
                                           [[] replace-ctx]
                                           keys)
            [new-order-by replace-ctx] (let [[new-order-by-elements replace-ctx]
                                             (-> (map :find-arg order-by)
                                                 (replace-vars* replace-ctx))]
                                         [(map #(assoc %1 :find-arg %2) order-by new-order-by-elements) replace-ctx])
            new-ctx (new-replacement-ctx (->> (concat (map form-vars find)
                                                      (map binding-vars in))
                                              (apply set/union))
                                         replace-ctx)
            [new-where _] (replace-vars* where new-ctx)]
        [[:sub-query
          {:q 'q
           :query (cond-> {:find new-find
                           :in new-in
                           :where new-where}
                    keys (assoc :keys new-keys)
                    order-by (assoc :order-by new-order-by))}]
         replace-ctx])
      (throw (err/illegal-arg :rules-not-supported-in-subquery
                              (s/unform ::rules rules))))))

(defmethod replace-vars :rule [rule replace-ctx]
  (let [[new-args new-replace-ctx]
        (->> rule second :args
             (reduce (fn [[new-args replace-ctx] [arg-type value :as arg]]
                       (case arg-type
                         :logic-var (let [[replacement replace-ctx] (get-replacement replace-ctx value)]
                                      [(conj new-args (wrap-replacement replacement)) replace-ctx])
                         :literal [(conj new-args arg) replace-ctx]))
                     [[] replace-ctx]))]
    [(update rule 1 assoc :args new-args) new-replace-ctx]))

(defn replace-vars* [exprs replace-ctx]
  (reduce (fn [[res replace-ctx] clause]
            (let [[updated-clause new-replace-ctx] (replace-vars clause replace-ctx)]
              [(conj res updated-clause) new-replace-ctx]))
          [[] replace-ctx]
          exprs))

(defn unique-symbol-fn [prefix]
  (let [cnt (atom -1)]
    (fn [suffix]
      (symbol (str "_" prefix "_" (swap! cnt inc) "_" suffix)))))

(defn gensym-rule [{:keys [head body] :as rule}]
  (let [unique-rule-arg-symbol (unique-symbol-fn "rule_arg")
        args (:args head)
        new-args (mapv unique-rule-arg-symbol args)
        old->new (zipmap args new-args)
        replace-ctx (->replacement-ctx old->new unique-rule-arg-symbol)]
    (-> rule
        (assoc :head (assoc head :args new-args))
        (assoc :body (first (replace-vars* body replace-ctx))))))

(defn gensym-rules [rules]
  (map gensym-rule rules))

(declare expand-rules)

(defn rewrite-rule [rule-name->rules {:keys [name args] :as rule-invocation}]
  (if-let [rules (get rule-name->rules name)]
    (if (= (count args) (-> rules first :head :args count))
      (let [branches (->> rules
                          (mapv (fn [{:keys [head body] :as _rule}]
                                  (let [var-inner->var-outer (zipmap (:args head) (map second args))
                                        replace-ctx (->replacement-ctx var-inner->var-outer identity)]
                                    (-> (expand-rules rule-name->rules body)
                                        (replace-vars* replace-ctx)
                                        first)))))]
        [:union-join
         {:union-join 'union-join
          :args (->> (filter (comp #{:logic-var} first) args)
                     (mapv second))
          :branches branches}])
      (throw (err/illegal-arg :rule-wrong-arity
                              {:rule-invocation (s/unform ::rule rule-invocation)})))
    (throw (err/illegal-arg :unknown-rule
                            {:rule-invocation (s/unform ::rule rule-invocation)}))))

(defn- expand-rules [rule-name->rules where-clauses]
  (mapv (fn [[type arg :as clause]]
          (case type
            (:triple :call) clause

            (:semi-join :anti-join)
            (->> clause second :terms
                 (expand-rules rule-name->rules)
                 (update clause 1 assoc :terms))

            :union-join
            (->> clause second :branches
                 (mapv (partial expand-rules rule-name->rules))
                 (update clause 1 assoc :branches))

            :sub-query
            (->> clause second :query :where
                 (expand-rules rule-name->rules)
                 (update-in clause [1 :query] assoc :where))

            :rule (rewrite-rule rule-name->rules arg)

            clause))
        where-clauses))

(defn check-rule-arity [rule-name->rules]
  (run! (fn [[name rules]]
          (let [arities (map #(-> % :head :args count) rules)]
            (when-not (apply = arities)
              (throw (err/illegal-arg :rule-definitions-require-unique-arity
                                      {:rule-name name})))))
        rule-name->rules))

(defn- plan-body [{where-clauses :where, apply-mapping ::apply-mapping, rules :rules, :as query}]
  (let [in-rels (plan-in-tables query)
        {::keys [param-vars]} (meta in-rels)

        rule-name->rules (->> rules
                              gensym-rules
                              (group-by (comp :name :head)))
        _ (check-rule-arity rule-name->rules)
        where-clauses (expand-rules rule-name->rules where-clauses)

        {triple-clauses :triple, call-clauses :call, sub-query-clauses :sub-query
         semi-join-clauses :semi-join, anti-join-clauses :anti-join, union-join-clauses :union-join
         :as grouped-clauses}
        (-> where-clauses
            (->> (group-by first))
            (update-vals #(mapv second %)))

        temporal-rules (mapcat grouped-clauses [:for-all-app-time :for-app-time-at :for-app-time-in
                                                :for-all-sys-time :for-sys-time-at :for-sys-time-in])
        temporal-clauses (->temporal-clauses temporal-rules)]

    (loop [plan (mega-join (vec (concat in-rels (plan-triples triple-clauses temporal-clauses)))
                           (concat param-vars apply-mapping))

           calls (some->> call-clauses (mapv plan-call))
           union-joins (some->> union-join-clauses (mapv plan-union-join))
           semi-joins (some->> semi-join-clauses (mapv (partial plan-semi-join :semi-join)))
           anti-joins (some->> anti-join-clauses (mapv (partial plan-semi-join :anti-join)))
           sub-queries (some->> sub-query-clauses (mapv plan-sub-query))]

      (if (and (empty? calls) (empty? sub-queries)
               (empty? semi-joins) (empty? anti-joins) (empty? union-joins))
        (-> plan
            (vary-meta assoc ::in-bindings (::in-bindings (meta in-rels))))

        (let [{available-vars ::vars} (meta plan)]
          (letfn [(available? [clause]
                    (set/superset? available-vars (::required-vars (meta clause))))]

            (let [{available-calls true, unavailable-calls false} (->> calls (group-by available?))
                  {available-sqs true, unavailable-sqs false} (->> sub-queries (group-by available?))
                  {available-ujs true, unavailable-ujs false} (->> union-joins (group-by available?))
                  {available-sjs true, unavailable-sjs false} (->> semi-joins (group-by available?))
                  {available-ajs true, unavailable-ajs false} (->> anti-joins (group-by available?))]

              (if (and (empty? available-calls) (empty? available-sqs)
                       (empty? available-ujs) (empty? available-sjs) (empty? available-ajs))
                (throw (err/illegal-arg :no-available-clauses
                                        {:available-vars available-vars
                                         :unavailable-subqs unavailable-sqs
                                         :unavailable-calls unavailable-calls
                                         :unavailable-union-joins unavailable-ujs
                                         :unavailable-semi-joins unavailable-sjs
                                         :unavailable-anti-joins unavailable-ajs}))

                (recur (cond-> plan
                         union-joins (wrap-union-joins union-joins param-vars)
                         available-calls (wrap-calls available-calls)
                         available-sjs (wrap-semi-joins :semi-join available-sjs)
                         available-ajs (wrap-semi-joins :anti-join available-ajs)
                         available-sqs (wrap-sub-queries available-sqs param-vars))

                       unavailable-calls unavailable-sqs
                       unavailable-ujs unavailable-sjs unavailable-ajs)))))))))

;; HACK these are just the grouping-fns used in TPC-H
;; - we're going to want a better way to recognise them
(def ^:private grouping-fn? '#{count count-distinct sum avg min max})

(defn- plan-head-exprs [{find-clause :find, :keys [order-by]}]
  (letfn [(with-col-name [prefix idx fc]
            (-> (vec fc) (with-meta {::col (col-sym prefix (str idx))})))

          (plan-head-form [col [form-type form-arg :as form]]
            (if (and (= form-type :fn-call)
                     (grouping-fn? (:f form-arg)))
              (let [{:keys [f], [[agg-arg-type :as agg-arg]] :args} form-arg]
                (if (= agg-arg-type :logic-var)
                  (-> col
                      (with-meta {::agg {col (s/unform ::form form)}, ::col col}))

                  (let [projection-sym (col-sym col "_agg")]
                    (-> col
                        (with-meta {::col col
                                    ::agg {col (list f projection-sym)}
                                    ::agg-projection {projection-sym (s/unform ::form agg-arg)}})))))

              (-> (s/unform ::form form)
                  (with-meta {::grouping-vars (form-vars form), ::col col}))))]

    (->> (concat (->> find-clause
                      (into [] (map-indexed (partial with-col-name "_column"))))
                 (->> order-by
                      (into [] (comp (map :find-arg)
                                     (map-indexed (partial with-col-name "_ob"))))))
         (into {} (comp (distinct)
                        (map
                         (fn [[arg-type arg :as find-arg]]
                           [find-arg
                            (case arg-type
                              :logic-var (-> arg (with-meta {::grouping-vars #{arg}, ::col arg}))
                              :form (let [{::keys [col]} (meta find-arg)]
                                      (plan-head-form col arg)))])))))))

(defn- plan-find [{find-args :find, rename-keys :keys} head-exprs]
  (let [clauses (->> find-args
                     (mapv (fn [rename-key clause]
                             (let [expr (get head-exprs clause)
                                   {::keys [col]} (meta expr)
                                   col (or (some-> rename-key col-sym) col)]
                               (-> (if (= col expr) col {col expr})
                                   (with-meta {::var col}))))
                           (or rename-keys (repeat nil))))]
    (-> clauses
        (with-meta {::vars (->> clauses (into #{} (map (comp ::var meta))))}))))

(defn- wrap-find [plan find-clauses]
  (-> [:project find-clauses plan]
      (with-meta (-> (meta plan) (assoc ::vars (::vars (meta find-clauses)))))))

(defn- plan-order-by [{:keys [order-by]} head-exprs]
  (some->> order-by
           (mapv (fn [{:keys [find-arg direction] :or {direction :asc}}]
                   [(::col (meta (get head-exprs find-arg)))
                    {:direction direction}]))))

(defn- wrap-order-by [plan order-by-clauses]
  (-> [:order-by order-by-clauses plan]
      (with-meta (meta plan))))

(defn- plan-group-by [head-exprs]
  (let [head-exprs (vals head-exprs)]
    (when-let [aggs (->> head-exprs (into {} (keep (comp ::agg meta))) (not-empty))]
      (let [grouping-vars (->> head-exprs (into [] (mapcat (comp ::grouping-vars meta))))]
        (-> (into grouping-vars
                  (map (fn [[col agg]]
                         {col agg}))
                  aggs)
            (with-meta {::vars (into (set grouping-vars) (map key) aggs)
                        ::agg-projections (->> head-exprs
                                               (into [] (keep (comp ::agg-projection meta)))
                                               (not-empty))}))))))

(defn- wrap-group-by [plan group-by-clauses]
  (let [{::keys [agg-projections]} (meta group-by-clauses)]
    (-> [:group-by group-by-clauses
         (if agg-projections
           [:map agg-projections plan]
           plan)]
        (with-meta (-> (meta plan) (assoc ::vars (::vars (meta group-by-clauses))))))))

(defn- wrap-head [plan query]
  (let [head-exprs (plan-head-exprs query)
        find-clauses (plan-find query head-exprs)
        order-by-clauses (plan-order-by query head-exprs)
        group-by-clauses (plan-group-by head-exprs)]

    (-> plan
        (cond-> group-by-clauses (wrap-group-by group-by-clauses)
                order-by-clauses (wrap-order-by order-by-clauses))
        (wrap-find find-clauses))))

(defn- wrap-top [plan {:keys [limit offset]}]
  (if (or limit offset)
    (-> [:top (cond-> {}
                offset (assoc :skip offset)
                limit (assoc :limit limit))
         plan]
        (with-meta (meta plan)))

    plan))

(defn- plan-query [conformed-query]
  (-> (plan-body conformed-query)
      (wrap-head conformed-query)
      (wrap-top conformed-query)))

(defn- extract-logic-var-or-scalars [coll]
  (when (coll? coll)
    (for [x coll]
      (if (and (vector? x) (= 2 (count x))
               (or (= :logic-var (first x))
                   (= :scalar (first x))))
        (second x)
        (extract-logic-var-or-scalars x)))))

(defn- extract-symbols [coll]
  (when (coll? coll)
    (for [x coll]
      (if (symbol? x) x (extract-symbols x)))))

(defn- check-unknown-vars
  [conformed-query]
  (let [scrub (fn [coll] (->> coll flatten (remove nil?) distinct set))
        find-vars (scrub (extract-logic-var-or-scalars (:find conformed-query)))
        where-bindings (scrub (extract-logic-var-or-scalars (:where conformed-query)))
        in-bindings (scrub (extract-symbols (:in conformed-query)))
        known-bindings (set/union where-bindings in-bindings)
        unknown-vars (set/difference find-vars known-bindings)]
    (when-not (empty? unknown-vars)
      (throw (err/illegal-arg
              :find-unknown-vars
              {::err/message (str ":find unknown variables: " (pr-str unknown-vars))
               :unknown-vars unknown-vars})))
    conformed-query))

(defn compile-query [query]
  (-> (conform-query query)
      (check-unknown-vars)
      (plan-query)))

(defn- args->params [args in-bindings]
  (->> (mapcat (fn [{::keys [binding-type in-cols]} arg]
                 (case binding-type
                   (:source :scalar) [(MapEntry/create (first in-cols) arg)]
                   :tuple (zipmap in-cols arg)
                   (:collection :relation) nil))
               in-bindings
               args)
       (into {})))

(defn- args->tables [args in-bindings]
  (->> (mapcat (fn [{::keys [binding-type in-cols table-key]} arg]
                 (case binding-type
                   (:source :scalar :tuple) nil

                   :collection (let [in-col (first in-cols)
                                     binding-k (keyword in-col)]
                                 (if-not (coll? arg)
                                   (throw (err/illegal-arg :bad-collection
                                                           {:binding in-col
                                                            :coll arg}))
                                   [(MapEntry/create table-key
                                                     (vec (for [v arg]
                                                            {binding-k v})))]))

                   :relation (let [conformed-arg (s/conform ::relation-arg arg)]
                               (if (s/invalid? conformed-arg)
                                 (throw (err/illegal-arg :bad-relation
                                                         {:binding in-cols
                                                          :relation arg
                                                          :explain-data (s/explain-data ::relation-arg arg)}))
                                 (let [[rel-type rel] conformed-arg
                                       ks (mapv keyword in-cols)]
                                   [(MapEntry/create table-key
                                                     (case rel-type
                                                       :maps rel
                                                       :vecs (mapv #(zipmap ks %) rel)))])))))
               in-bindings
               args)
       (into {})))

(defn open-datalog-query ^core2.IResultSet [^BufferAllocator allocator, ^IRaQuerySource ra-src, wm-src
                                            {:keys [basis] :as query} args]
  (let [plan (compile-query (dissoc query :basis :basis-timeout))
        {::keys [in-bindings]} (meta plan)

        plan (-> plan
                 #_(doto clojure.pprint/pprint)
                 #_(->> (binding [*print-meta* true]))
                 (lp/rewrite-plan {})
                 #_(doto clojure.pprint/pprint)
                 (doto (lp/validate-plan)))

        ^core2.operator.PreparedQuery pq (.prepareRaQuery ra-src plan)]

    (when (not= (count in-bindings) (count args))
      (throw (err/illegal-arg :in-arity-exception {::err/message ":in arity mismatch"
                                                   :expected (count in-bindings)
                                                   :actual args})))

    (let [^AutoCloseable
          params (vw/open-params allocator (args->params args in-bindings))]
      (try
        (-> (.bind pq wm-src
                   {:params params, :table-args (args->tables args in-bindings), :basis basis})
            (.openCursor)
            (op/cursor->result-set params))
        (catch Throwable t
          (.close params)
          (throw t))))))
