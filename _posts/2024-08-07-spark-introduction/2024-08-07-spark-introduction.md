---
title: Spark Introduction
tags: Spark
layout: article
footer: false
aside:
  toc: true
mathjax_autoNumber: true
published: true
---

這篇文章記錄一下最近學習到對於spark執行上的理解。

<!--more-->

## Spark的基本架構

![Spark architecture](https://i0.wp.com/sparkbyexamples.com/wp-content/uploads/2023/03/Driver-2.jpg?w=731&ssl=1)

*[What is Spark Job - Spark By {Examples}](https://sparkbyexamples.com/spark/what-is-spark-job/)*

Spark的基本架構長得如上圖，當我們提交一個spark application給cluster manager像是yarn以後，application首先會先被交由一個driver來執行，driver可以想成是在cluster內某一個instance上的process，而這個process會根據你寫的程式碼去要求cluster manager給予executor來去執行對應的任務。

![Spark stage](https://i0.wp.com/sparkbyexamples.com/wp-content/uploads/2023/03/spark-Stage-1.jpg?w=711&ssl=1)

*[What is Spark Stage? Explained - Spark By {Examples}](https://sparkbyexamples.com/spark/what-is-spark-stage/)*

一個application通常會根據你寫的程式碼又被細分成好幾個job和stage，一個job會被產生是當你對dataframe或是rdd採取一些特定的action像是`count()`、`collect()`、`write()`等，而每個job底下又可能有好幾個stage，端看你這個action需不需要shuffle、與其他instance傳輸資料，最後的每一個task就是實際上會丟到executor上執行的資料partition。

## 如何計算Spark Application需要多少資源

這邊我們需要先區分一下instance和executor，instance是你這個cluster裡面實際的機器，而executor是spark用來執行task的process，所以在一個instance上面有可能會被分配到一個或多個executor，根據你機器的規格和executor對於core和memory的要求來決定。

而每一個task會交由一個core來執行，所以當一個executor有4個核心的時候，spark會以multi-thread的方式來平行化地執行4個task，如果task裡面有包含到python udf，那麼會在每一個核心上面長一個python執行器，由每個核心的python執行器來執行udf。

值得一提的是，spark好像只會看instance的核心數來分配executor，如果你的executor需要很多memory，需要小心造成OOM，舉例來說假設一個instance上面有16個core、64GB的記憶體，而我們設定`spark.executor.cores=2`、`spark.executor.memory=16g`，這時spark會覺得這個instance有機會可以放16/2=8個executor，但由於memory的關係其實最多只能放4個，如果8個都放上去就有可能造成問題，需要設定`spark.executor.instances`來限制executor的數量。

## 為什麼python udf會被執行多次

PySpark執行python udf的方式是會先把拿到的資料partition再切成好幾個batch，把每個batch轉換成PyArrow的格式以後交由python執行器來執行，而現在pandas udf支援透過iterator的方式來存取，spark會把每一個batch的iterator丟進python執行器來跑udf，這時如果udf有一些比較吃重的初始化工作的時候，就可以寫在iterator前，之後就可以透過iterator來吃資料，不用再重新初始化一次。

如果我們透過Spark UI去看每一個task的log的時候，可能還是會發現udf裡面初始化的部分被執行了多次，這邊有幾種可能，一個可能是因為executor有多個核心、使用multi-thread執行，所以同一個executor上不同task的log被混在一起，另一個可能是spark沒有把結果保留下來，後面又重算了一次，原因可能是job和job之間做了其他事情，executor需要釋放記憶體去執行其他的任務，當後面的job又需要前面job計算的結果時導致重算，我們可以透過`cache()`、`persist()`來讓spark強制把結果儲存下來，避免重算的發生。

在一個[StackOverflow的討論串](https://stackoverflow.com/questions/58696198/spark-udf-executed-many-times)上面有提供另一個方式是把udf設定成`Nondeterministic`，讓spark只執行一次這個udf，或許也可以試試看，但如果後面需要重算，這個做法還是會讓udf被執行多次。

```python
@pandas_udf(...)
def test():
    pass

test = test.asNondeterministic()
```

## 參考資料

* [What is Spark Job - Spark By {Examples}](https://sparkbyexamples.com/spark/what-is-spark-job/)

* [What is Spark Stage? Explained - Spark By {Examples}](https://sparkbyexamples.com/spark/what-is-spark-stage/)

* [Tune Spark Executor Number, Cores, and Memory - Spark By {Examples}](https://sparkbyexamples.com/spark/spark-tune-executor-number-cores-and-memory/)
