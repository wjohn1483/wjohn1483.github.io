---
title: 網路安全的基本知識
tags: Network-Security
layout: article
footer: false
aside:
  toc: true
mathjax: true
mathjax_autoNumber: true
published: true
---

有鑑於有時會接觸到一些網路安全的東西，這邊簡單紀錄一下碰到的一些東西。

<!--more-->

## 非對稱式密碼學

在網路安全當中的很多基礎是建立在[非對稱式密碼學（Asymmetric cryptography）](https://zh.wikipedia.org/wiki/%E5%85%AC%E5%BC%80%E5%AF%86%E9%92%A5%E5%8A%A0%E5%AF%86)上，而非對稱式密碼學又是奠基在[RSA](https://zh.wikipedia.org/wiki/RSA%E5%8A%A0%E5%AF%86%E6%BC%94%E7%AE%97%E6%B3%95)等非對稱加密演算法上。非對稱加密演算法可以產生出成對的公鑰和私鑰，用公鑰加密的文件只能用私鑰來解開，而用私鑰加密的文件也只能用公鑰來解開，在這樣的基礎上，我們就可以與其他人安全的傳遞資料，不怕被其他人偷看。

### 安全傳遞訊息

這邊簡單說明一下，如何使用非對稱加密演算法來安全的傳遞訊息。

假如說今天愛麗絲想要傳遞訊息給鮑伯，但怕透過網路的話她所傳遞的訊息會被別人看到，這時，鮑伯可以用非對稱加密演算法先產生一對公鑰和私鑰，透過網路將公鑰傳遞給愛麗絲，而愛麗絲將她想要傳遞的訊息透過鮑伯的公鑰加密以後，透過網路再傳回給鮑伯，鮑伯再用私鑰來將訊息讀取出來。

![透過非對稱加密演算法安全傳遞訊息](https://upload.wikimedia.org/wikipedia/commons/thumb/0/03/Public_key_encryption_alice_to_bob.svg/langzh-500px-Public_key_encryption_alice_to_bob.svg.png)

如果有人一直在竊聽兩個人的對話，他雖然可以拿到鮑伯的公鑰以及愛麗絲透過公鑰加密過後的訊息，但因為沒有鮑伯的私鑰的關係，所以也看不到愛麗絲傳給鮑伯的訊息。

### 數位簽章

在上面的例子當中，雖說第三人沒有辦法看到愛麗絲傳遞給鮑伯的訊息，但他擁有鮑伯的公鑰，可以巧妙的偽裝成愛麗絲傳遞訊息給鮑伯。為了防止有人偽裝成愛麗絲，愛麗絲可以利用她自己的私鑰搭配雜湊函數來對訊息做簽名，而鮑伯拿到訊息以後，除了用自己的私鑰解開以外，還需要用愛麗絲的公鑰對簽名做驗證，如此便能防止有人假冒了。

## 常見的網路安全名詞

### [SSL/TLS](https://zh.wikipedia.org/wiki/%E5%82%B3%E8%BC%B8%E5%B1%A4%E5%AE%89%E5%85%A8%E6%80%A7%E5%8D%94%E5%AE%9A)

SSL的全稱是Secure Sockets Layer，而TLS的全稱是Transport Layer Security，SSL是TLS的前身，而這兩個都是transport layer的安全協定。

### OAuth

OAuth是一個開放的標準，來讓第三方的app有權利可以存取使用者在其他網站上面的資源，而不用將使用者的帳號密碼給第三方app，OAuth其實是個生活中常用到的標準，舉凡在Slack裡面連結Google Drive的帳戶，或是在電子信箱裡面連結其他電子信箱等，底層使用的可能都是OAuth的標準。

OAuth具體的操作方式可以參考[這篇文章](https://petertc.medium.com/oauth-2-0-196a5550b668)，簡單來說，假設我今天想要透過服務A存取我放在服務B的資料，我得要先去服務B那邊申請說我想要讓第三方服務存取資料，並從服務B拿到Authorization Code，接著我把這Authorization Code給服務A，服務A會拿著這個Authorization Code去服務B那邊換取Access Token，之後服務A就可以使用這Access Token存取我在服務B上面的資料了。

### Yubikey

[Yubikey](https://zh.wikipedia.org/wiki/YubiKey)是由Yubico這家公司出產的身分認證裝置，常用在二階段認證上，在使用的時候是插在電腦上，並在需要時觸碰它。

### X.509

[X.509](https://zh.wikipedia.org/wiki/X.509)是一個格式標準，常用在包括SSL/TLS在內的網路協定裡。它的概念是說，當我想要跟某台素未蒙面的主機聯繫的時候，我不清楚那台主機能不能夠被信任、是不是別人假裝的，這時就會需要一個公正的CA（Certificate Authority）來幫忙，如果對方的主機可以提供我所信任的CA的憑證（Certificate），那麼我就相信對方是可以被信任的而傳送資料過去。

而CA的架構是金字塔型，主要頒發憑證的是中間的認證中心，他們上面還有更高的認證中心，詳細的資訊可以參考[這篇文章](https://www.imacat.idv.tw/tech/sslcerts.html.zh-tw#sslx509)。

### Athenz

[Athenz](https://github.com/yahoo/athenz)是由Yahoo開源、基於X.509權限管理系統，使用集中式的授權，並以role為基礎，透過指定某個role對某個資源允許或拒絕某些動作來達成授權行為，任何服務想要知道我有沒有權限存取資料的時候，都要去跟權限管理系統詢問，所以可能會有單點故障以及流量的問題，具體的授權流程可以參考[官方的文件](https://github.com/yahoo/athenz/blob/master/docs/auth_flow.md)。

### mTLS

mTLS的全稱應該是Mutual TLS，指的是雙方都去驗證對方的身分。在一般的情境下，可能只有使用者需要去驗證服務是不是可以被信任的，但有些時候如果要交換一些比較機密的資料時，就會需要兩邊都做驗證，也就是雙方要各自準備好各自的key、certificate和CA的certificate。

* Server需要準備：server.key、server.crt、ca.crt
* Client需要準備：client.key、client.crt、ca.crt

### Okta

[Okta](https://en.wikipedia.org/wiki/Okta_(identity_management))是一家公司，提供其他企業SSO（Single Sign On）的服務，讓企業的員工可以只登入一次就可以存取各式各樣的服務，Okta還提供其他多重要素驗證等等的服務。

### CKMS

[CKMS](https://www.cryptomathic.com/products/key-management/crypto-key-management-system)的全稱好像是Crypto Key Management System，是一個幫忙更新、部署key的系統。

## 參考資料

1. [基礎密碼學(對稱式與非對稱式加密技術)](https://medium.com/@RiverChan/%E5%9F%BA%E7%A4%8E%E5%AF%86%E7%A2%BC%E5%AD%B8-%E5%B0%8D%E7%A8%B1%E5%BC%8F%E8%88%87%E9%9D%9E%E5%B0%8D%E7%A8%B1%E5%BC%8F%E5%8A%A0%E5%AF%86%E6%8A%80%E8%A1%93-de25fd5fa537)
2. [妳知道第三方應用是怎麼存取妳的雲端資料嗎？](https://petertc.medium.com/oauth-2-0-196a5550b668)
3. [黑毛到白毛的攻城獅之路: Athenz 的授權流程](https://jimwayne.blogspot.com/2019/04/athenz.html)
4. [如何製作SSL X.509憑證？](https://www.imacat.idv.tw/tech/sslcerts.html.zh-tw#sslx509)
5. [SSL/TLS 双向认证(一) -- SSL/TLS 工作原理_ustccw-CSDN博客](https://www.google.com/url?sa=t&rct=j&q=&esrc=s&source=web&cd=&ved=2ahUKEwjKlqe_qcHuAhWRyYsBHaRAB8AQFjADegQICBAC&url=https%3A%2F%2Fblog.csdn.net%2Fustccw%2Farticle%2Fdetails%2F76691248&usg=AOvVaw3SJiQY0B573tpV5gZmAb-x)



