---
title: Python Import Introduction
tags: Python
layout: article
footer: false
aside:
  toc: true
mathjax: true
mathjax_autoNumber: true
published: true
---

在寫python時，常搞不懂import路徑的寫法，這邊簡單介紹一下python import的邏輯。

<!--more-->

## Script v.s. Module

執行python檔案有兩種方式：

* 把該檔案視為top-level script來執行：`python main.py`
* 把它當作module執行：在其他檔案裡面透過`import`來執行，或是`python -m main.py`

當一個python檔案被執行的時候，它會被給予一個名字，儲存在`__name__`這個變數裡面，如果它被當作top-level script執行，`__name__`就會被指定成`__main__`，如果被當作module執行，`__name__`會被指定成該檔案的名字加上packge的路徑。

> 值得一提的是，雖然`python -m main.py`是把main.py當作module來執行，但印出來的`__name__`仍然是`__main__`，不過在底下執行relative import是沒有問題的。

舉例來說，如果我們當下的目錄結構長得像底下這樣

```bash
.
├── main.py
└── package
    └── moduleA.py
```

當我們下`python main.py`或是`python package/moduleA.py`時，他們的`__name__`都是`__main__`，如果我們在`main.py`裡面`import package.moduleA`，並在`moduleA.py`裡面把`__name__`印出來，會發現印出來的`__name__`會是`package.moduleA`。

值得一提的是，如果你今天是直接打`python`進入interactive shell，那麼當下shell的`__name__`就會是`__main__`。

### Relative Import

relative import會透過module的名字來去決定package的位置，假設我們現在稍微修改一下目錄的架構變成底下

```bash
.
├── main.py
└── package
    ├── moduleA.py
    └── subpackage
        └── moduleB.py
```

假如說我們用import的方式在當前目錄執行`moduleB.py`（`from package.subpackage import moduleB`），那麼當前的`__name__`就會是`package.subpackage.moduleB`，而我們在`moduleB.py`裡面有`from .. import moduleA`，這時python就會去`package`裡面尋找`moduleA`，就可以順利的import進來。

但如果今天是用直接執行的方式`python package/subpackage/moduleB.py`，會因為`__name__`為`__main__`而找不到parent package，噴底下的error。

```bash
Traceback (most recent call last):
  File "package/subpackage/moduleB.py", line 1, in <module>
    from .. import moduleA
ImportError: attempted relative import with no known parent package
```

這時可以改用`python -m package.subpackage.moduleB`來把`moduleB.py`當作module執行。

### Absolute Import

根據當前執行目錄的絕對路徑來import module，值得一提的是，當前執行的目錄並不是你執行python時所在的目錄，而是top-level script所在的目錄。

```
.
├── main.py
└── package
    ├── moduleA.py
    └── subpackage
        └── moduleB.py
```

以上面的結構來說，若我在當前目錄`./`執行`python package/moduleA.py`，那麼若要在`moduleA.py`裡面import moduleB，就得要用`from subpackage import moduleB`，而不是`from package.subpackage import moduleB`，因為`moduleA.py`在`./package`裡面，python會從那邊起始點。

## \_\_init\_\_.py的用途

在上面的例子當中，我們都沒有使用到`__init__.py`，但應該在很多地方都可以看到他的蹤影，而`__init__.py`的作用是將一個目錄轉變成package。

舉例來說，在上面的例子裡面，我們將`__init__.py`放到`package/`底下，這時`package`就變成了一個regular package。

### Regular Packages

在python裡面[主要有兩種package](https://docs.python.org/3/reference/import.html#regular-packages)，分別是regular package和namespace package，而regular package就如同上面所說的，只要有`__init__.py`在目錄裡面的，就是regular package。當我們import regular package的時候，`__init__.py`會被執行，也因此我們可以在`__init__.py`裡面做一些手腳，讓這個package變得更易於使用。

### Namespace Packages

倘若我們不放`__init__.py`在目錄裡面，在python 3.3以後，我們依然可以`import package`，就像上面absolute import的章節中做的一樣，但不一樣的是，被import進來的`package`會被當作namespace package。[Namespace package](https://packaging.python.org/guides/packaging-namespace-packages/)的用途主要是讓你可以切分多個sub-package到不同的目錄當中，但仍屬於同樣的namespace，以方便使用者import，舉例來說，我們在regular package的方式下做好了一個package如下。

```bash
mynamespace/
    __init__.py
    subpackage_a/
        __init__.py
        ...
    subpackage_b/
        __init__.py
        ...
    module_b.py
setup.py
```

而我們import他們的方式會是

```python
from mynamespace import subpackage_a
from mynamespace import subpackage_b
```

但某些時候我們可能只需要`subpackage_a`就行，不想要額外安裝`subpackage_b`，這時可以將`mynamespace`拆成兩個package，拆成兩個package的方法可以參考[官方文件](https://packaging.python.org/guides/packaging-namespace-packages/#native-namespace-packages)。

```
mynamespace-subpackage-a/
    setup.py
    mynamespace/
        subpackage_a/
            __init__.py

mynamespace-subpackage-b/
    setup.py
    mynamespace/
        subpackage_b/
            __init__.py
        module_b.py
```

使用者就可以根據自己的需求pip install相對應的package，而這兩個package在安裝完以後都會同屬於`mynamespace`這個namespace底下，因此一樣可以用`from mynamespace import subpackage_a, subpackage_b`來import。

值得一提的是，如果import`.zip`檔，一樣會被當作是namespace package。

```python
In [1]: import sys

In [2]: sys.path.append("./module_zip.zip")

In [3]: import module_zip

In [4]: module_zip.__path__
Out[4]: _NamespacePath(['./module_zip.zip/module_zip'])

In [5]: module_zip
Out[5]: <module 'module_zip' (namespace)>
```

## Reference

1. [Relative imports for the billionth time](https://stackoverflow.com/questions/14132789/relative-imports-for-the-billionth-time)
2. [The import system](https://docs.python.org/3/reference/import.html#regular-packages)
