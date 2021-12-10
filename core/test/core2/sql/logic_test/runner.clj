(ns core2.sql.logic-test.runner
  (:require [clojure.test :as t]
            [clojure.string :as str])
  (:import java.nio.charset.StandardCharsets
           java.security.MessageDigest))

(defprotocol DbEngine
  (get-engine-name [_])
  (execute-statement [_ statement])
  (execute-query [_ query]))

;; Parser

(defmulti parse-record (fn [[x & xs]]
                         (keyword (first (str/split x #"\s+")))))

(defmethod parse-record :statement [[x & xs]]
  (let [[_ mode] (str/split x #"\s+")
        statement (str/join "\n" xs)
        mode (keyword mode)]
    (assert (contains? #{:ok :error} mode))
    {:type :statement
     :mode mode
     :statement statement}))

(defmethod parse-record :query [[x & xs]]
  (let [[_ type-string sort-mode label] (str/split x #"\s+")
        [query _ result] (partition-by #{"----"} xs)
        query (str/join "\n" query)
        sort-mode (keyword (or sort-mode :nosort))
        record {:type :query
                :query query
                :type-string type-string
                :sort-mode sort-mode
                :label label}]
    (assert (contains? #{:nosort :rowsort :valuesort} sort-mode))
    (assert (re-find #"^[TIR]+$" type-string))
    (if-let [[_ values hash] (and (= 1 (count result))
                                  (re-find #"^(\d+) values hashing to (\p{XDigit}{32})$" (first result)))]
      (assoc record :result-set-size (Long/parseLong values) :result-set-md5sum hash)
      (assoc record :result-set-size (count result) :result-set (vec result)))))

(defmethod parse-record :skipif [[x & xs]]
  (let [[_ database-name] (str/split x #"\s+")]
    (assoc (parse-record xs) :skipif database-name)))

(defmethod parse-record :onlyif [[x & xs]]
  (let [[_ database-name] (str/split x #"\s+")]
    (assoc (parse-record xs) :onlyif database-name)))

(defmethod parse-record :halt [xs]
  (assert (= 1 (count xs)))
  {:type :halt})

(defmethod parse-record :hash-threshold [[x :as xs]]
  (assert (= 1 (count xs)))
  (let [[_ max-result-set-size] (str/split x #"\s+")]
    {:type :hash-threshold
     :max-result-set-size (Long/parseLong max-result-set-size)}))

(defn parse-script [script]
  (->> (str/split-lines script)
       (map #(str/replace % #"\s*#.+$" ""))
       (partition-by str/blank?)
       (remove #(every? str/blank? %))
       (mapv parse-record)))

;; Runner

(defmulti execute-record (fn [_ {:keys [type] :as record}]
                           type))

(defmethod execute-record :halt [db-engine _]
  (reduced db-engine))

(defmethod execute-record :hash-threshold [db-engine {:keys [max-result-set-size]}]
  (assoc db-engine :max-result-set-size max-result-set-size))

(defmethod execute-record :statement [db-engine {:keys [mode statement]}]
  (case mode
    :ok (execute-statement db-engine statement)
    :error (do (t/is (thrown? Exception (execute-statement db-engine statement)))
               db-engine)))

(defn- format-result-str [sort-mode result]
  (let [result-rows (for [vs result]
                      (for [v vs]
                        (cond
                          (nil? v) "NULL"
                          (= "" v) "(empty)"
                          (float? v) (format "%.3f" v)
                          :else (str v))))]
    (->> (case sort-mode
           :rowsort (flatten (sort-by (partial str/join " ") result-rows))
           :valuesort (sort (flatten result-rows))
           :nosort (flatten result-rows))
         (str/join "\n"))))

(defn- validate-type-string [type-string result]
  (doseq [row result
          [value type] (map vector row type-string)
          :let [java-class (case (str type)
                             "I" Long
                             "R" Double
                             "T" String)]]
    (t/is (or (nil? value) (cast java-class value)))))

(defn- md5 ^String [^String s]
  (->> (.getBytes s StandardCharsets/UTF_8)
       (.digest (MessageDigest/getInstance "MD5"))
       (BigInteger. 1)
       (format "%032x")))

;; TODO: parse query and qualify known table columns if
;; needed. Generate logical plan and format and hash result according
;; to sort mode. Projection will usually be positional.
(defmethod execute-record :query [db-engine {:keys [query type-string sort-mode label
                                                    result-set-size result-set result-set-md5sum]}]

  (let [result (execute-query db-engine query)
        result-str (format-result-str sort-mode result)]
    #_(validate-type-string type-string result)
    (when-let [row (first result)]
      (t/is (count type-string) (count row)))
    (t/is (= result-set-size (count result)))
    #_(when result-set
        (t/is (= (str/join "\n" result-set) result-str)))
    (when result-set-md5sum
      (t/is (= result-set-md5sum (md5 result-str)))))
  db-engine)

(defn- skip-record? [db-engine-name {:keys [skipif onlyif]
                                     :or {onlyif db-engine-name}}]
  (or (= db-engine-name skipif)
      (not= db-engine-name onlyif)) )

(defn execute-records [db-engine records]
  (->> (remove (partial skip-record? (get-engine-name db-engine)) records)
       (reduce execute-record db-engine)))
