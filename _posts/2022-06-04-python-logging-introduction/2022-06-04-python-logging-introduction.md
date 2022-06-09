---
title: Python logging介紹
tags: Tool Python
layout: article
footer: false
aside:
  toc: true
mathjax_autoNumber: true
published: true
---

這篇文章簡單介紹一下python logging這個package的使用方法。

<!--more-->

在python裡面想要去debug你的程式除了使用`print()`直接把變數印出來以外，可以使用原生的`logging` package來去把log給印出來。

## Log的分類

在開始介紹logging怎麼使用之前，我們可以先來認識一下log有分成不同的等級，在[python的文件](https://docs.python.org/3/howto/logging.html#when-to-use-logging)中有介紹什麼時候該使用哪種方法來顯示訊息，像是`print()`主要是用來顯示usage等一般用途，而`logging.warning()`是表示發現到有問題，但並不影響執行，詳細的介紹建議閱讀上面的文件，底下簡單介紹一下log的分級。

* DEBUG：顯示詳細的訊息，主要是在追查問題的時候使用

* INFO：顯示確認的訊息，表示程式有正確地在執行

* WARNING：表示有些預料外的事情發生或預告可能的問題像是硬碟空間快不夠了，但程式仍可以繼續執行

* ERROR：程式執行的過程當中碰到了一些問題，可能有些function不能被執行了

* CRITICAL：程式碰到了更嚴重的問題，已經無法繼續執行

## 簡單使用logging

在`logging`裡面有根據上述不同等級的log有對應的function可以呼叫，可以看底下的例子

```python
import logging

logging.debug("Debug message")
logging.info("Info message")
logging.warning("Warning message")
logging.error("Error message")
logging.critical("Critical message")
```

在實際執行上面的程式碼以後我們可以得到下面的結果

```bash
WARNING:root:Warning message
ERROR:root:Error message
CRITICAL:root:Critical message
```

在使用`logging`的function時，`logging`會去創建一個名叫`root`的logger，並把訊息透過這個logger來紀錄，而其預設的格式是`severity:logger name:message`，而且只會顯示WARNING以上的訊息，如果想要設定顯示哪種log的等級的話，可以在最前面呼叫`basicConcig()`來設定

```python
import logging

logging.basicConfig(level=logging.DEBUG)
logging.debug("Debug message")
logging.info("Info message")
logging.warning("Warning message")
logging.error("Error message")
logging.critical("Critical message")
```

此時得到的結果會是

```bash
DEBUG:root:Debug message
INFO:root:Info message
WARNING:root:Warning message
ERROR:root:Error message
CRITICAL:root:Critical message
```

這樣的作法在當程式碼裡面有引入多個module的時候也適用

```python
# main.py
import logging

from lib import func


def main():
    logging.info(f"info from main")
    logging.error(f"error from main")
    func()


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    main()
```

```python
# lib.py
import logging


def func():
    logging.info(f"info from lib")
    logging.error(f"error from lib")
```

在上面我們寫了兩個python script，分別為**main.py**和**lib.py**，其中**main.py**會去呼叫定義在**lib.py**裡面的`func()`，這時如果去執行**main.py**的話會得到下面的結果

```bash
INFO:root:info from main
ERROR:root:error from main
INFO:root:info from lib
ERROR:root:error from lib
```

在**lib.py**裡面設定的訊息也一樣會被顯示出來，然而美中不足的是，如果我們沒有特意在log裡面留下跟檔案有關的訊息的話，就很難從log裡面看出這個是從哪裡產生出來的log了，底下會介紹python文件當中比較建議，為每個檔案建立logger的方法。

## 使用複數logger

在上面我們碰到了無法辨別log是從哪個module產生出來的問題，而解決這個問題的[建議做法](https://docs.python.org/3/howto/logging.html#advanced-logging-tutorial)是對每一個module都建立專屬於他們的logger，也就是使用`logging.getLogger()`來建立logger以後，再用logger來紀錄我們的訊息。

這邊我們把上面例子中的`logging`都替換成`logger`

```python
# main.py
import logging

from lib import func

logger = logging.getLogger(__name__)

def main():
    logger.info(f"info from main")
    logger.error(f"error from main")
    func()


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    main()
```

```python
# lib.py
import logging

logger = logging.getLogger(__name__)

def func():
    logger.info(f"info from lib")
    logger.error(f"error from lib")
```

這邊我們將`__name__`傳入`logging.getLogger()`當中，這時logging就會幫我們建立一個以`__name__`為名稱的logger，而`__name__`會在python裡面被代換成檔案名稱，這時再執行**main.py**就能得到以下的結果

```bash
INFO:__main__:info from main
ERROR:__main__:error from main
INFO:lib:info from lib
ERROR:lib:error from lib
```

如此便能方便地知道這個log是從哪個module產生的了。

## Logger的階層

在上面的例子裡面我們建立了兩個logger，分別是`__main__`和`lib`，這兩個logger不會各自將訊息直接印出來，而是將訊息傳到他們上層的logger，讓上層logger中的handler來決定log要怎麼被處理，在這個例子裡面它們會將log傳給`root`這個logger，再去看`root`裡面的handler的設定來去做處理，詳細的處理流程可以參考[文件](https://docs.python.org/3/howto/logging.html#logging-flow)

![Logging Flow](https://docs.python.org/3/_images/logging_flow.png)

雖然在程式碼裡面看起來我們沒有為root logger設定任何handler，但其實在我們呼叫`logging.basicConfig()`的時候它就會[自動幫我們建立好](https://docs.python.org/dev/library/logging.html#logging.basicConfig)，如果想要自行設定的話也可以使用`logging.getLogger()`，在其中不給任何的參數來拿到root logger，接著再透過`logger.addHandler()`來去新增handler。

## Logging Format

如果說我們想要自定義顯示出來的log的格式的話，可以在`logging.basicConfig()`的地方設定root logger中handler印出log的格式，因為底下的logger會把log往上傳給root logger，所以只需要在root logger中設定好，所有印出來的log都會是一樣的格式。

假如我們在**main.py**裡面多加個參數

```python
import logging

from lib import func

logger = logging.getLogger(__name__)

def main():
    logger.info(f"info from main")
    logger.error(f"error from main")
    func()


if __name__ == "__main__":
    log_format="%(asctime)s %(filename)s:%(lineno)d - %(message)s"
    logging.basicConfig(level=logging.INFO, format=log_format)
    main()
```

而**lib.py**維持不變，這時印出來的訊息就會變成

```bash
2022-06-04 23:02:58,775 main.py:8 - info from main
2022-06-04 23:02:58,775 main.py:9 - error from main
2022-06-04 23:02:58,775 lib.py:6 - info from lib
2022-06-04 23:02:58,775 lib.py:7 - error from lib
```

更多logging支援的attribute，可以看其[官方文件](https://docs.python.org/3/library/logging.html#logrecord-attributes)。

### 在log中加入顏色

如果想在terminal裡面讓不同等級的log有不同顏色的話，可以參考從[這裡](https://stackoverflow.com/questions/384076/how-can-i-color-python-logging-output)改編而來的方法，寫一個**log.py**

```python
# log.py
import logging


class CustomFormatter(logging.Formatter):
    grey = "\x1b[38;20m"
    cyan = "\x1b[36;20m"
    light_green = "\x1b[32;20m"
    yellow = "\x1b[33;20m"
    red = "\x1b[31;20m"
    bold_red = "\x1b[31;1m"
    reset = "\x1b[0m"
    log_format = "%(asctime)s - %(name)s - %(levelname)s - %(message)s (%(filename)s:%(lineno)d)"

    FORMATS = {
        logging.DEBUG: light_green + log_format + reset,
        logging.INFO: cyan + log_format + reset,
        logging.WARNING: yellow + log_format + reset,
        logging.ERROR: red + log_format + reset,
        logging.CRITICAL: bold_red + log_format + reset
    }

    def format(self, record):
        log_fmt = self.FORMATS.get(record.levelno)
        formatter = logging.Formatter(log_fmt)
        return formatter.format(record)


root_logger = logging.getLogger()
root_handler = logging.StreamHandler()
root_handler.setFormatter(CustomFormatter())
root_logger.addHandler(root_handler)
```

在上面的程式碼裡面我們自訂了一個formatter，並根據不同等級的log加入不同顏色的前綴和後綴，而且在底下也設定了root logger的handler，要使用的時候我們在新的程式碼裡面簡單import它並設定level就可以了

```python
# main.py
import logging

import log
from lib import func

logger = logging.getLogger(__name__)

def main():
    logger.debug("debug message")
    logger.info("info message")
    logger.warning("warning message")
    logger.error("error message")
    logger.critical("critical message")
    func()


if __name__ == "__main__":
    logging.getLogger().setLevel(logging.DEBUG)
    main()
```

跑出來的log就能有顏色了

![Colorful Log](./colorful_log.png)

不過要小心的是，如果把log寫成檔案的話，這些顏色前綴和後綴都會被寫進檔案裡面，建議視情況來使用

```bash
[32;20m2022-06-09 18:20:41,750 - __main__ - DEBUG - debug message (main.py:11)[0m
[36;20m2022-06-09 18:20:41,750 - __main__ - INFO - info message (main.py:12)[0m
[33;20m2022-06-09 18:20:41,750 - __main__ - WARNING - warning message (main.py:13)[0m
[31;20m2022-06-09 18:20:41,750 - __main__ - ERROR - error message (main.py:14)[0m
[31;1m2022-06-09 18:20:41,750 - __main__ - CRITICAL - critical message (main.py:15)[0m
[36;20m2022-06-09 18:20:41,750 - lib - INFO - info from lib (lib.py:8)[0m
[31;20m2022-06-09 18:20:41,750 - lib - ERROR - error from lib (lib.py:9)[0m
```
