---
title: Bandit Algorithms Notes
tags: Bandit
layout: article
footer: false
aside:
  toc: true
mathjax_autoNumber: false
published: true
---

最近剛好有機會碰了一下一直聽過但都沒有實際碰過的Bandit Algorithms，這邊紀錄一下從網路上學習到的知識。

<!--more-->

Bandit算法一開始被設計出來是為了要解決在有限的資源下要如何創造最大的收益，網路文章中給的例子通常都是在一個滿是吃角子老虎機台的房間當中，如何用手中有限的籌碼獲得最大的報酬，也就是找到獲獎機率比較大的吃角子老虎機台，這時候使用者會面臨繼續玩原本預期收益最大的吃角子老虎機，或是去玩看看新的吃角子老虎機，也就是在exploitation和exploration兩者之間抉擇。

在原本的Multi-Armed Bandit裡面，我們只考慮不同吃角子老虎的機台，並沒有考慮使用者本身的偏好，像是某個使用者可能特別偏好某個有特殊外型的吃角子老虎機，對於該使用者而言那台吃角子老虎機的預期收益會比較大，如果有考慮到使用者本身資訊的bandit通常被稱為contextual bandit，反之被稱為context-free bandit。

在任何的一個bandit algorithm裡面，我們會對每一個arm，也就是每一個吃角子老虎機台打一個分數，並從這些機台裡面選一個分數最高的去使用，而不同的算法會有不同打分數的方式，比較著名的context-free bandit的算法有UCB、Thompson Sampling，比較著名的contextual bandit算法有LinUCB。

## Epsilon Greedy

在進到Bandit的算法之前，我們可以先用一個簡單的方法來平衡exploitation和exploration，我們可以每次在決定要玩哪台吃角子老虎機的時候先擲一個骰子，令其有$\epsilon$的機率會去選擇以前沒有玩過的吃角子老虎機試試看，反之就繼續玩目前玩過的所有吃角子老虎機裡面，預期收益最大的。

## Upper Confidence Bound (UCB)

在使用epsilon greedy做exploration的時候，每一個arm被選中的機會是相等的，但實際上每一個arm曾經被看過的次數和互動過的次數都不同，在exploration的時候可以有更聰明一點的方法，而UCB的概念是對於每一個arm給予的分數是基於它有可能所帶來的最高報酬，其分數的公式如下

$$\mu_i+\sqrt{\frac{2\ln (n)}{n_i}}$$

$\mu_i$是每一個$arm_i$前n次嘗試獲得的平均報酬，$n$是總嘗試次數，$n_i$是$arm_i$被嘗試的次數。

左邊這項可以理解成過去這個$arm_i$所能夠帶給我們的平均報酬是多少，展現的是exploitation的部分，而右邊這項會讓比較少曝光的$arm_i$有比較高的分數，令其有機會被展示出來，展現的是exploration的部分。

## Thompson Sampling

Thompson sampling的想法是，每次使用同一個arm所獲得的報酬可能會是浮動的，表示每一個arm的報酬可能是某種distribution，每次使用的時候就會從distribution裡面隨機抽樣出來當作是這次使用的報酬，而Thompson sampling覺得這個distribution應該是beta distribution，一個beta distribution會由兩個變數a、b來決定，也就是每個arm自帶的參數，因此在某個時間點選擇要使用哪一個arm的時候，就是每一個arm都從beta distribution裡面抽樣一個數字出來，看誰的數字最大就選擇哪個arm。

## LinUCB

LinUCB相較於UCB，多了使用者的資訊在裡面，其公式長得大概像這樣

$$LinUCB_a=E(r_a \vert x)+\alpha STD(r_a \vert x)=x^T*\theta_a+\alpha\sqrt{x^TA_a^{-1}x}$$

在上面的$x$表示的是使用者的特徵向量，而$\theta_a$和$A_a$是某一個arm本身自帶的參數，跟UCB一樣，左邊這項表示對過去這個使用者對這個arm的喜好程度，而右邊這項表示使用者願意exploration的分數。

## 參考資料

1. [Contextual Bandit算法在推荐系统中的实现及应用](https://zhuanlan.zhihu.com/p/35753281)

2. [Re：从零开始的Multi-armed Bandit](https://blog.tsingjyujing.com/ml/rl/mab-summary)

3. [在生产环境的推荐系统中部署Contextual bandit (LinUCB)算法的经验和陷阱](https://yangxudong.github.io/contextual-bandit/)

4. [MAB系列1：Contextual-free Bandits](https://zhuanlan.zhihu.com/p/381585388)

5. [MAB系列2：Contextual Bandits: LinUCB](https://zhuanlan.zhihu.com/p/384427160)
