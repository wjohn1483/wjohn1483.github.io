---
title: Tensorflow JS介紹
tags: Tool Computer-Vision
layout: article
footer: false
aside:
  toc: true
mathjax_autoNumber: true
published: true
---

隨著機器學習的模型可以做到越來越多的事情，人們希望可以在更多的場域來使用機器學習的模型，也因此它們也逐漸的被部署到除了電腦以外的裝置上，這篇文章主要是來簡單介紹一下tensorflow.js，把模型部署在瀏覽器上，讓更多人可以輕易地存取。

<!--more-->

在這篇文章裡面主要會介紹一下tensorflow.js的一些功能，並說明Google團隊先前透過tensorflow.js製作的一個應用[Move Mirror](https://experiments.withgoogle.com/move-mirror)大概是如何被製作出來的。

## Tensorflow JS

[tensorflow.js](https://www.tensorflow.org/js?hl=zh-tw)是一個JavaScript的套件，讓機器學習的模型可以在瀏覽器裡面被執行，除了可以把用python訓練出來的模型放在瀏覽器上以外，還可以使用官方包好的模型來去做有趣的應用，可以參考[這邊的範例](https://github.com/tensorflow/tfjs-examples)來開始編寫tensorflow.js。

## Pose Detection

在[Move Mirror](https://experiments.withgoogle.com/move-mirror)裡面，我們可以透過使用者的動作來找到相似的圖片，主要的方法是透過CDCL的模型來去對電腦鏡頭拍攝出來的人像做辨識，從中取得每個關節的座標，接著把座標正規化以後去跟照片去算cosine similarity，而在[部落格文章](https://blog.tensorflow.org/2018/07/move-mirror-ai-experiment-with-pose-estimation-tensorflow-js.html)當中還有講述把模型給的信心分數放進算座標距離的方法和快速計算多張照片的方式，建議閱讀文章的內容來更理解詳細的做法。

有了這個CDCL模型和距離計算的方式，我們可以對它稍做修改，改成給定一張照片，去計算電腦鏡頭拍攝的人像和照片的距離有多少，來讓使用者可以練習擺跟照片一樣的姿勢，我個人修改過後的結果可以[在這邊看到](https://wjohn1483.github.io/Pose-Copier/dist/?model=movenet)。
