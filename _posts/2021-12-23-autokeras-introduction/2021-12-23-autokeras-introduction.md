---
title: AutoKeras介紹
tags: Tool
layout: article
footer: false
aside:
  toc: true
mathjax_autoNumber: true
published: true
---

現在市面上有眾多AutoML的框架，而用深度學習並有Neural Architecture Search（NAS）功能的並不多，這邊紀錄一下使用AutoKeras的心得。

<!--more-->

## 安裝AutoKeras

安裝的方式很簡單，只需要`pip install`就行了，不過值得一提的是，在文章撰寫的當下，雖然[AutoKeras的官網](https://autokeras.com/install/)上寫支援tensorflow 2.3.0以上的版本，但實際用tensorflow 2.7.0的時候會出現問題，建議還是先使用tensorflow 2.3.0。

```bash
pip3 install tensorflow==2.3.0 autokeras
```

## 利用AutoKeras做text classification

在[AutoKeras的官網](https://autokeras.com/tutorial/overview/)上有很多tutorial來做不同的任務，像是text classification、image classification等等，這邊嘗試的是tutorial裡面的text classification，任務是sentiment analysis，給定一個評論，判斷這個評論是正面還是負面的。

### 準備訓練用的資料

底下的程式碼會去從網路上抓取dataset下來，並做成numpy，值得一提的是，文字的部分我們並沒有轉成index，而是單純的string，轉成index的部分會交由autokeras放在模型裡面。

```python
import os

import numpy as np
import tensorflow as tf
from sklearn.datasets import load_files


print("Preparing data...")
dataset = tf.keras.utils.get_file(
    fname="aclImdb.tar.gz",
    origin="http://ai.stanford.edu/~amaas/data/sentiment/aclImdb_v1.tar.gz",
    extract=True,
)

# set path to dataset
IMDB_DATADIR = os.path.join(os.path.dirname(dataset), "aclImdb")

classes = ["pos", "neg"]
train_data = load_files(
    os.path.join(IMDB_DATADIR, "train"), shuffle=True, categories=classes
)
test_data = load_files(
    os.path.join(IMDB_DATADIR, "test"), shuffle=False, categories=classes
)

x_train = np.array(train_data.data)
y_train = np.array(train_data.target)
x_test = np.array(test_data.data)
y_test = np.array(test_data.target)

# Minimize training size for tutorial
sample_size = 1000
x_train = x_train[:sample_size]
y_train = y_train[:sample_size]

print("Data samples...")
print(x_train.shape)  # (sample_size,)
print(y_train.shape)  # (sample_size,)
print(x_train[0][:50])  # b'Zero Day leads you to think, even re-think why two'
print(y_train[0:30])  # [1 0 1 0 0 1 1 0 0 1 0 0 0 1 0 1 1 1 1 1 1 1 0 0 1 0 0 0 1 0]
```

### 訓練模型

在這邊我們使用autokeras裡面的TextClassifier，設定`max_trials`為2，代表嘗試2種不同的模型架構，可以視情況把這個數字調大，而`overwrite`會將上次訓練的結果覆蓋掉，如果想接續上次訓練，可以改成`False`。

在`fit()`裡面有設定`epochs`，表示每一個模型架構會訓練多少個epoch。

```python
import autokeras as ak


print("Building model...")
# Initialize the text classifier.
clf = ak.TextClassifier(
    overwrite=True, max_trials=2
)  # It only tries 2 models as a quick demo.
clf.fit(x_train, y_train, epochs=10)
```

值得一提的是，`TextClassifier`可以設定模型的metrics要是什麼，預設是`val_loss`，可以依據任務的需求來做修改。

```python
cls = ak.TextClassifier(
    overwrite=True,
    max_trials=2,
    objective="accuracy",  # Change to other metric that is suitable for your task
)
```

另外，`TextClassifier`會自己去判斷label有多少個，並自己對label做index，只是在預測的時候並不會自動把index轉回原本label的樣子，建議這邊自己先用`sklearn.preprocessing.LabelEncoder`先對label做index，並在`fit()`的時候餵入轉好index的資料，之後在預測時，就可以使用`LabelEncoder`來轉回label原本的樣子。

```python
import pickle


# Before training
labeler = LabelEncoder().fit(label)
label = np.array(labeler.transform(label))
pickle.dump(labeler, open("/path/to/labeler.pkl", "wb"), pickle.HIGHEST_PROTOCOL)

# After training
labeler = pickle.load(open("/path/to/labeler.pkl", "rb"))
results = model.predict(feature, verbose=1)
predictions = labeler.inverse_transform(np.argmax(results, axis=1))
```

### 儲存模型

這邊會儲存表現最好的模型。

```python
model = clf.export_model()
try:
    model.save("./model", save_format="tf")
except Exception:
    model.save("./model.h5")
```

### 模型預測

autokeras輸出的模型跟一般keras訓練出來的模型相同，所以我們可以用keras的`load_model()`來讀取模型，不過會需要在後面加上`custom_objects`，把autokeras自定義的object帶進來。

```python
from tensorflow.keras.models import load_model


model = load_model("./model", custom_objects=ak.CUSTOM_OBJECTS)
model.summary()
model.predict(x_test, verbose=1)
```

## 結論

可以稍微瀏覽一下[autokeras的tutorial](https://autokeras.com/tutorial/overview/)，如果碰到的任務種類有在裡面，可以嘗試看看，只不過會需要跑在可以連上外網的機器上，因為autokeras會去網路上抓一些pretrain的模型下來，另外也需要注意一下硬碟的使用量，因為autokeras會把每個trial訓練的模型儲存下來，很容易把硬碟吃滿，不然就是需要在[ak.TextClassifier](https://autokeras.com/text_classifier/)裡面限制`max_model_size`的大小。