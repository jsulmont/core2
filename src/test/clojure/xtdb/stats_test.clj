(ns xtdb.stats-test
  (:require [clojure.test :as t :refer [deftest]]
            [xtdb.datalog :as xt]
            [xtdb.logical-plan :as lp]
            [xtdb.node :as node]
            [xtdb.test-util :as tu]
            [xtdb.util :as util]))

(t/use-fixtures :each tu/with-allocator)

(deftest test-scan
  (with-open [node (node/start-node {:xtdb/live-chunk {:rows-per-block 2 , :rows-per-chunk 2}})]
    (let [scan-emitter (util/component node :xtdb.operator.scan/scan-emitter)]
      (xt/submit-tx node [[:put :foo {:id "foo1"}]
                          [:put :bar {:id "bar1"}]])

      (xt/submit-tx node [[:put :foo {:id "foo2"}]
                          [:put :baz {:id "baz1"}]])

      (-> (xt/submit-tx node [[:put :foo {:id "foo3"}]
                              [:put :bar {:id "bar2"}]])
          (tu/then-await-tx* node))

      (t/is (= {:row-count 3}
               (:stats (lp/emit-expr '{:op :scan, :scan-opts {:table foo}, :columns [[:column id]]}
                                     {:scan-col-types {['$ 'id] :utf8},
                                      :scan-emitter scan-emitter}))))

      (t/is (= {:row-count 2}
               (:stats (lp/emit-expr '{:op :scan, :scan-opts {:table bar}, :columns [[:column id]]}
                                     {:scan-col-types {['$ 'id] :utf8},
                                      :scan-emitter scan-emitter})))))))

(deftest test-project
  (t/is (= {:row-count 5}
           (:stats
             (lp/emit-expr
               '{:op :project,
                 :projections [[:column foo]],
                 :relation
                 {:op :xtdb.test-util/blocks,
                  :stats {:row-count 5}
                  :blocks [[{:foo 1}]]}}
               {})))))

(deftest test-rename
  (t/is (= {:row-count 12}
           (:stats
             (lp/emit-expr
               '{:op :rename,
                 :columns {foo bar}
                 :relation
                 {:op :xtdb.test-util/blocks,
                  :stats {:row-count 12}
                  :blocks [[{:foo 1}]]}}
               {})))))
