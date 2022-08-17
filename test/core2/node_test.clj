(ns core2.node-test
  (:require [clojure.test :as t]
            [core2.api :as c2]
            [core2.test-util :as tu]
            [core2.util :as util]))

(defn- with-mock-clocks [f]
  (tu/with-opts {:core2.log/memory-log {:clock (tu/->mock-clock)}
                 :core2.tx-producer/tx-producer {:clock (tu/->mock-clock)}}
    f))

(t/use-fixtures :each with-mock-clocks tu/with-node)

(t/deftest test-delete-without-search-315
  (let [!tx1 (c2/submit-tx tu/*node* [[:sql "INSERT INTO foo (id) VALUES ('foo')"]])]
    (t/is (= [{:id "foo",
               :application_time_start (util/->zdt #inst "2020")
               :application_time_end (util/->zdt util/end-of-time)}]
             (c2/sql-query tu/*node* "SELECT foo.id, foo.application_time_start, foo.application_time_end FROM foo"
                           {:basis {:tx !tx1}})))

    #_ ; FIXME #45
    (let [!tx2 (c2/submit-tx tu/*node* [[:sql "DELETE FROM foo"]])]
      (t/is (= [{:id "foo",
                 :application_time_start (util/->zdt #inst "2020")
                 :application_time_end (util/->zdt #inst "2021")}]
               (c2/sql-query tu/*node* "SELECT foo.id, foo.application_time_start, foo.application_time_end FROM foo"
                             {:basis {:tx !tx2}
                              :basis-timeout (java.time.Duration/ofMillis 500)}))))))