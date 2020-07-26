---
title: REINFORCE和Proximal Policy Optimization
tags: Reinforcement-Learning
layout: article
footer: false
aside:
  toc: true
mathjax: true
mathjax_autoNumber: false
published: true
---

在製作model的時候，有時會參雜一些人工定義分數的部分，這時我們就不能夠單純使用gradient descent來訓練我們的model，因為人工定義的分數是無法被微分的，然而我們還是可以靠一些方式來把這些分數整合到model的objective function中，並利用我們熟悉的gradient descent來訓練。

<!--more-->

## REINFORCE

首先，我們先來定義一下state、action和reward之間的關係。當機器看到眼前的state $$s_1$$時，會根據自身的演算法決定做出動作$$a_1$$，此時環境會根據機器做出的$$a_1$$給予reward $$r_1$$，而隨著這個動作，機器所看到的state會從$$s_1$$轉移到$$s_2$$，接著機器會根據$$s_2$$做出動作$$a_2$$，並獲得$$r_2$$，以此類推。而我們的目標就是希望機器能學會一個厲害的policy，使得expected reward最大。

$$\begin{aligned} expected\ reward & =\sum R(\tau)p_\theta(\tau)\\ & =\mathbb{E}_{\tau\sim p_\theta(\tau)}[R(\tau)] \end{aligned}$$

其中$$\tau$$是trajectory，指的是$$\left[ s_1, a_1, s_2, a_2, ... \right]$$的序列，而$$R(\tau)$$是序列$$\tau$$中所獲得的所有$$r_i$$的總和、$$\theta$$是policy的參數、$$p_\theta(\tau)$$是序列$$\tau$$出現的機率，因為policy會影響到action $$a_i$$的產生，所以$$\tau$$的機率跟$$\theta$$有關。

若我們以expected reward為objective function，對它做微分，我們可以得到

$$\begin{aligned}\bigtriangledown R_\theta &= \sum R(\tau) \bigtriangledown p_\theta(\tau) \end{aligned}$$

因為$$R(\tau)$$是由環境給予的，亦可以是人工定義的，跟policy的參數沒有什麼關係，所以當我們做微分的時候不會有什麼影響，接著再稍微整理一下

$$\begin{aligned} \bigtriangledown R_\theta &= \sum R(\tau)\bigtriangledown p_\theta(\tau) \\ &= \sum R(\tau) p_\theta(\tau)\frac{\bigtriangledown p_\theta(\tau)}{p_\theta(\tau)} \\ &= \sum R(\tau)p_\theta(\tau)\bigtriangledown\log p_\theta(\tau) \\ &= \mathbb{E}_{\tau\sim p_\theta(\tau)} [R(\tau)\bigtriangledown\log p_\theta(\tau)] \\ &\approx \frac{1}{N}\sum\limits_{n=1}\limits^{N}R(\tau^n)\bigtriangledown\log p_\theta(\tau^n) \\ &\approx \frac{1}{N}\sum\limits_{n=1}\limits^{N}\sum\limits_{t=1}\limits^{T_n}R(\tau^n)\bigtriangledown\log p_\theta(a_t^n\vert s_t^n) \end{aligned}$$

在式子最後所得出來的式子，其實跟常見的、label是one-hot vector的cross entropy很類似，只不過多出了$$R(\tau^n)$$，在概念上可以想像成，每一步都在讓model自己產生的action的log probability越大越好，但是用$$R(\tau^n)$$來控制log probability要多大。

### Advantage

在前面的段落裡，我們可以看到，當環境給予的reward都是正值的時候，objective function裡$$R(\tau^n)$$這項的值會是正的，使得在$$s_t^n$$時，機器所採取的任何一個$$a_t^n$$的log probability都是會漸漸變大的，雖說隨著時間的拉長，能獲得較大reward的$$a_t^n$$的log probability應該會是最大的，然而訓練起來要花的時間就會比較多，因此通常在訓練的時候，會稍微調整一下objective function，變成底下

$$\bigtriangledown R_\theta=\frac{1}{N}\sum\limits_{n=1}\limits^{N}\sum\limits_{t=1}\limits^{T_n}[R(\tau^n)-b]\bigtriangledown\log p_\theta(a_t^n\vert s_t^n),\ b=\mathbb{E}[R(\tau)] $$

這邊的$$b$$是trajectory的平均reward，使得$$[R(\tau^n)-b]$$這項的意思變成，這個action $$a_t^n$$相對於平均而言有多好。

而再更精細的去看objective function會發現$$R(\tau^n)$$代表的是整個trajectory的reward，但卻用來衡量每個時間點$$a_t^n$$的好壞，這樣有一點不太公平，可能在某個$$s_t^n$$採取$$a_t^n$$對拿到reward是很有幫助的，但因為其他action表現得不好，使得整個trajectory拿到的reward低於平均，這時這個好的action的log probability就會被降低，為了讓前面這項更能反映每個action的好壞，會再修改成

$$\bigtriangledown R_\theta=\frac{1}{N}\sum\limits_{n=1}\limits^{N}\sum\limits_{t=1}\limits^{T_n}\left[ \sum\limits_{t^\prime=t}\limits^{T_n}\gamma^{t^\prime-t}r_{t^\prime}^n-b \right]\bigtriangledown\log p_\theta(a_t^n\vert s_t^n),\ \gamma<1$$

也就是用該action未來的reward再稍微打個折以後加總起來，當作是這個action有多好，而前面中括號裡的這項通常會被拉出來變成$$A^\theta(s_t,a_t)$$稱為advantage function用以衡量在$$s_t$$採取$$a_t$$相較其他action有多好。

## Proximal Policy Optimization (PPO)

### On-policy v.s. Off-policy

> On-policy：要訓練的model正是與環境互動的


> Off-policy：要訓練的model和與環境互動的model不同

在前面REINFORCE的式子裡面我們可以看到它是一個on-policy的方法，那on-policy的方法需要很長的訓練時間，因為跟環境互動完的trajectory拿來更新一次model的參數以後就不能夠再被使用了，因為新的model所採取的action會不一樣，而PPO就是嘗試把REINFORCE從on-policy變成off-policy，好讓訓練時間縮短。

### Importance Sampling

PPO使用的便是將importance sampling融入進objective function裡面，這邊先提一下什麼是importance sampling。

在一般我們計算從某個機率分佈$$p$$抽樣出$$x$$的$$f(x)$$的期望值時，會寫成底下的式子

$$\mathbb{E}_{x\sim p}[f(x)] \approx \frac{1}{N}\sum\limits_{i=1}\limits^{N}f(x_i)$$

倘若今天因為某種特殊的原因，使得我們無法直接從機率分佈$$p$$直接抽樣的時候，我們可以使用另外一個機率分佈$$q$$抽樣出$$x$$再經過$$p$$、$$q$$之間的轉換來達到一樣的結果

$$\begin{aligned} \mathbb{E}_{x\sim p}[f(x)] &=\int f(x)p(x)dx \\ &= \int f(x)\frac{p(x)}{q(x)}q(x)dx \\ &= \mathbb{E}_{x\sim q}\left[ f(x)\frac{p(x)}{q(x)} \right] \end{aligned}$$

而importance sampling代表的就是底下的式子

$$\mathbb{E}_{x\sim p}[f(x)]=\mathbb{E}_{x\sim q}\left[f(x)\frac{p(x)}{q(x)}\right]$$

雖然看起來當機率分佈$$p$$無法被取樣的時候，我們可以使用任意的機率分佈$$q$$來替代，但這其中還是會有一些誤差，我們知道一個機率分佈的變異數的算法如下

$$Var[X]=\mathbb{E}[X^2]-(\mathbb{E}[X])^2$$

機率分佈$$p$$的變異數為

$$Var_{x\sim p}[f(x)]=\mathbb{E}_{x\sim p}[f(x)^2]-(\mathbb{E}_{x\sim p}[f(x)])^2$$

如果使用importance sampling來得到的變異數為

$$\begin{aligned} Var_{x\sim q}\left[f(x)\frac{p(x)}{q(x)}\right] &=\mathbb{E}_{x\sim q}\left[f(x)^2\frac{p(x)^2}{q(x)^2}\right]-\left(\mathbb{E}_{x\sim q}\left[f(x)\frac{p(x)}{q(x)}\right]\right)^2 \\ &= \mathbb{E}_{x\sim p}\left[f(x)^2\frac{p(x)}{q(x)}\right]-\left(\mathbb{E}_{x\sim p}[f(x)]\right)^2\end{aligned}$$

從上式我們可以看到，當機率分佈$$p$$和$$q$$兩者的差異過大的時候，會造成兩者的變異數也相差很多，所以在使用importance sampling的時候，使用機率分佈較近的$$q$$是很重要的。

### PPO

在這裡，我們想要將前面的REINFORCE從on-policy換成off-policy，讓原先跟環境做互動的$$\pi_\theta$$換成$$\pi_{\theta^\prime}$$，為此我們套用上面的importance sampling

$$\begin{aligned} \bigtriangledown R_\theta &= \mathbb{E}_{(s_t,a_t)\sim\pi_\theta} \left[ A^\theta(s_t,a_t)\bigtriangledown\log p_\theta(a_t^n\vert s_t^n)\right] \\ &= \mathbb{E}_{(s_t,a_t)\sim\pi_{\theta^\prime}}\left[\frac{p_\theta(s_t, a_t)}{p_{\theta^\prime}(s_t, a_t)}A^\theta(s_t,a_t)\bigtriangledown\log p_\theta(a_t^n\vert s_t^n)\right] \\ &= \mathbb{E}_{(s_t,a_t)\sim\pi_{\theta^\prime}}\left[\frac{p_\theta(a_t\vert s_t)}{p_{\theta^\prime}(a_t\vert s_t)}\frac{p_\theta(s_t)}{p_{\theta^\prime}(s_t)}A^{\theta^\prime}(s_t,a_t)\bigtriangledown\log p_\theta(a_t^n\vert s_t^n)\right] \end{aligned}$$

從第二行到第三行中間做了一件特別的事情，這裡假設$$\pi_\theta$$和$$\pi_{\theta^\prime}$$所能得到的reward是差不多的，所以將$$\theta$$跟環境做互動得到的$$A^\theta(s_t,a_t)$$替換成了$$A^{\theta^\prime}(s_t,a_t)$$。

而又假設一個state $$s_t$$被觀測到的機率其實跟model沒有什麼關係的話，$$\frac{p_\theta(s_t)}{p_{\theta^\prime}(s_t)}$$就可以忽略不看，最終我們就可以得到底下的式子做為我們的objective function

$$J^{\theta^\prime}(\theta)=\mathbb{E}_{(s_t,a_t)\sim\pi_{\theta^\prime}}\left[\frac{p_\theta(a_t\vert s_t)}{p_{\theta^\prime}(a_t\vert s_t)}A^{\theta^\prime}(s_t,a_t)\right]$$

因為$$\bigtriangledown f(x)=f(x)\bigtriangledown\log f(x)$$，我們可以得到$$\bigtriangledown p_\theta(a_t\vert s_t)=p_\theta(a_t\vert s_t)\bigtriangledown\log p_\theta(a_t\vert s_t)$$

但由於importance sampling在兩個機率分佈差異很大的時候會讓結果壞掉，所以PPO做的事情便是在objective function裡面多加$$\beta KL(\theta, \theta^\prime)$$這項，其中$$\beta$$是一個hyperparameter，讓兩個機率分佈差異不要太大

$$J_{PPO}^{\theta^\prime}=J^{\theta^\prime}(\theta)-\beta KL(\theta, \theta^\prime)$$

值得一提的是，這邊的$$KL()$$不是只兩個model參數之間的KL divergence，而是兩者的output，也就是兩者的behavior所算出來的KL divergence。

而PPO的前身，TRPO的式子跟PPO幾乎一樣，只是它把KL這項當作是一個限制，在實作起來會比起PPO來要來得複雜得多。

$$J_{TRPO}^{\theta^\prime}(\theta)=J^{\theta^\prime}(\theta),\ KL(\theta, \theta^\prime)<\delta$$

## 參考資料

* [DRL Lecture 2:  Proximal Policy Optimization (PPO)](https://www.youtube.com/watch?v=OAKAZhFmYoI)