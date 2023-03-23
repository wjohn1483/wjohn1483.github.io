---
title: 將PySpark Executor的Log蒐集到Driver
tags: Tool
layout: article
footer: false
aside:
  toc: true
mathjax_autoNumber: true
published: true
---

這篇文章記錄一下如何用spark內建的accumulator把在executor的資訊帶回driver上。

<!--more-->

在寫PySpark的程式時，我們很常會寫一些user-defined function（UDF），在executor上面執行這些UDF來處理資料，如果在UDF裡面有`print`之類的指令來印出處理的過程，雖說可以在spark UI上面能找到executor印出來的結果，但是當處理的步驟很多、UDF也很多的時候，就需要花一些時間去定位這個UDF是在哪個stage執行，才可以找到對應的log。

如果想要省去在spark UI上面尋找特定UDF log的麻煩，我們可以透過[spark內建的accumulator](https://spark.apache.org/docs/latest/api/python/reference/api/pyspark.Accumulator.html)來把各個executor上的log蒐集起來到driver上，最後在driver上一次把所有的log都印出來，如此便能在同一個地方看到各個UDF執行的log了。

## Pyspark Accumulator

[Accumulator](https://spark.apache.org/docs/latest/api/python/reference/api/pyspark.Accumulator.html)是一個累加器，executor們可以對accumulator進行`add`的動作，來更新accumulator的數值，常用的是int和float的累加，一個簡單的範例可以從[spark的官方文件](https://spark.apache.org/docs/latest/api/python/reference/api/pyspark.Accumulator.html)裡面看到。

## Custom AccumulatorParam

目前原生支援的accumulator只有支援數值型的資料型態，為了要把我們UDF執行的log放進accumulator裡面，我們需要自己寫一個`AccumulatorParam`的class，讓Accumulator可以接受數值以外的資料，底下是一個讓accumulator吃`dict`的範例，可以按照每次不同的需求而修改

```python
from pyspark.accumulators import AccumulatorParam


class DictParam(AccumulatorParam):
    def zero(self, init_value: dict):
        return init_value

    def addInPlace(self, v1: dict, v2: dict):
        for key in v2.keys():
            v1[key] = v2[key]
        return v1
```

在上面的class裡面有兩個method，`zero()`是在初始化accumulator的時候會被呼叫的method，可以在這邊設定一開始的預設值，而`addInPlace()`是決定每個executor的資料要如何被整合在一起的method，在上面的例子裡面，我們可以想像每個executor會回傳一個`dict`的資料，這些`dict`會逐個丟入`addInPlace()`來收斂成一個`dict`。

在UDF裡面寫入log的方式就跟一般accumulator使用的方法一樣，只不過這邊就會變成你所定義的資料型態了，一個簡單的測試可以參考底下的例子

```python
from pyspark.sql import SparkSession
from pyspark.accumulators import AccumulatorParam


class DictParam(AccumulatorParam):
    def zero(self, init_value: dict):
        return init_value

    def addInPlace(self, v1: dict, v2: dict):
        for key in v2.keys():
            v1[key] = v2[key]
        return v1


def manipulate_dict(x, accumulator):
    accumulator.add({x: f"This is the executor processing {x}"})
    return x**2


def main():
    spark = SparkSession.builder.enableHiveSupport().getOrCreate()
    rdd = spark.sparkContext.parallelize(range(10))

    accumulator = spark.sparkContext.accumulator({}, DictParam())

    result = rdd.map(lambda x: manipulate_list(x, accumulator)).collect()
    print(result)
    print(accumulator)


if __name__ == '__main__':
    main()
```

在上面的程式碼裡面，我們寫了一個`manipulate_dict()`的UDF，在function裡面會去把收到的參數放進accumulator裡面並回傳參數的平方出去，這個程式執行後在driver印出來的結果如下

```python
[0, 1, 4, 9, 16, 25, 36, 49, 64, 81]
{0: 'This is the executor processing 0', 1: 'This is the executor processing 1', 2: 'This is the executor processing 2', 3: 'This is the executor processing 3', 4: 'This is the executor processing 4', 5: 'This is the executor processing 5', 6: 'This is the executor processing 6', 7: 'This is the executor processing 7', 8: 'This is the executor processing 8', 9: 'This is the executor processing 9'}
```

如果說只是想要寫入單純的字串到accumulator裡面，可以改用`list`的param來達成搜集executor log的目的

```python
from pyspark.sql import SparkSession
from pyspark.accumulators import AccumulatorParam


class ListParam(AccumulatorParam):
    def zero(self, init_value: list):
        return init_value

    def addInPlace(self, v1: list, v2: list):
        v1 += v2
        return v1


def manipulate_list(x, accumulator):
    accumulator.add([f"This is the executor processing {x}"])
    return x**2


def main():
    spark = SparkSession.builder.enableHiveSupport().getOrCreate()
    rdd = spark.sparkContext.parallelize(range(10))

    accumulator = spark.sparkContext.accumulator([], ListParam())

    result = rdd.map(lambda x: manipulate_list(x, accumulator)).collect()
    print(result)
    print(accumulator)


if __name__ == '__main__':
    main()
```

在driver上印出的結果如下

```python
[0, 1, 4, 9, 16, 25, 36, 49, 64, 81]
['This is the executor processing 0', 'This is the executor processing 1', 'This is the executor processing 2', 'This is the executor processing 3', 'This is the executor processing 4', 'This is the executor processing 5', 'This is the executor processing 6', 'This is the executor processing 7', 'This is the executor processing 8', 'This is the executor processing 9']
```

透過自定義`AccumulatorParam`，我們可以很彈性地在UDF回傳想要印在driver上的資料，讓debug spark的程式變得輕鬆一些。

## References

* [Custom PySpark Accumulators](https://towardsdatascience.com/custom-pyspark-accumulators-310f63ca3c8c)

* [dictionary - accumulator in pyspark with dict as global variable - Stack Overflow](https://stackoverflow.com/questions/44640184/accumulator-in-pyspark-with-dict-as-global-variable)
