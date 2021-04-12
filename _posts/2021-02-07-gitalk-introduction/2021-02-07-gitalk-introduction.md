---
title: 利用Gitalk在靜態網頁裡面新增留言區
tags: Tool
layout: article
footer: false
aside:
  toc: true
mathjax: true
mathjax_autoNumber: true
published: true
---

先前在設定檔裡面發現這個部落格主題可以開啟留言的功能，這邊簡單介紹一下其背後所使用的Gitalk以及如何設定它。

<!--more-->

## Gitalk

[Gitalk](https://github.com/gitalk/gitalk)是一個使用GitHub issue來當作留言板的工具，讓使用者們可以簡單的在他們的網頁上面安插一些javascript就可以做到留言板的效果，還可以支援Markdown語法，可以看[官方的demo](https://gitalk.github.io/)來感受成品大概長什麼樣子。

## 套用在部落格上

在jekyll的主題，[jekyll-TeXt-theme](https://github.com/kitian616/jekyll-TeXt-theme)裡面，已經有內建好可以搭配Gitalk使用，只是需要一些前置步驟並修改一下設定。

### 建立GitHub Application

為了要讓Gitalk可以直接在GitHub上面幫你留言，我們需要建立一個GitHub Application，讓Gitalk以[OAuth](https://wjohn1483.github.io/2021/01/26/security-introduction/#oauth)的方式代替你去GitHub上的issue留言，創建一個Application可以點[這邊](https://github.com/settings/applications/new)。

* Application name：應用程式的名字，可以隨意取
* Homepage URL：應用程式的首頁，以GitHub page的部落格而言，我是填GitHub page的網址
* Application description：非必填
* Authorization callback URL：同上面的**Homepage URL**

在建立好GitHub Application以後，網頁上應該會出現client id和client secret，在後面的設定會使用到，值得一提的是，client secret只會顯示這麼一次，記得要好好的保存起來。

### 修改_config.yml

在_config.yml裡面可以找到[有關comment設定的部分](https://github.com/kitian616/jekyll-TeXt-theme/blob/master/_config.yml#L118-L144)，需要修改的地方有兩塊，一個是需要把`provider`改成gitalk，另一個是在底下`gitalk`的區塊要把列出來的資訊填好，而設定中的`repository`是將來儲存comment的repo，未來comment會儲存在該repo的issue裡面，必須要是public的，這個repo可以跟存放網頁的repo不同，一個修改過後的範例貼在底下，記得要將client id和client secret改掉。

```yaml
comments:
  provider: gitalk # false (default), "disqus", "gitalk", "valine", "custom"

  # Disqus
  disqus:
    shortname: # the Disqus shortname for the site

  ## Gitalk
  # please refer to https://github.com/gitalk/gitalk for more info.
  gitalk:
    clientID    : ENV_CLIENT_ID # GitHub Application Client ID
    clientSecret: ENV_CLIENT_SECRET # GitHub Application Client Secret
    repository  : "wjohn1483.github.io" # GitHub repo
    owner       : "wjohn1483" # GitHub repo owner
    admin: # GitHub repo owner and collaborators, only these guys can initialize GitHub issues, IT IS A LIST.
      - "wjohn1483"
      # - your GitHub Id
    proxy: https://netnr-proxy.cloudno.de/https://github.com/login/oauth/access_token

  # Valine
  # please refer to https://valine.js.org/en/ for more info.
  valine:
    app_id      : # LeanCloud App id
    app_key     : # LeanCloud App key
    placeholder : # Prompt information
    visitor     : # false (default)
    meta        : # "[nick, mail, link]" (default) nickname, E-mail, Personal-site
```

值得一提的是，原本預設的proxy好像開始限定流量了，所以如果用預設的proxy會無法使用，範例中參考了[Gitalk issue](https://github.com/gitalk/gitalk/issues/429)中的解法，改掉預設的proxy。

### 在文章當中加入key

為了要讓Gitalk知道那篇文章對應到那個issue，我們需要給每一篇文章獨一無二的id，並寫在文章的front matter裡面。

```yaml
---
layout: article
title: Document - Writing Posts
mathjax: true
key: your-article-id
---
```

這個id在front matter裡面稱作`key`，它的命名規則可以參考[這裡](https://tianqi.name/jekyll-TeXt-theme/docs/en/layouts#page-layout)。

在設定好以後，在本機執行編譯的指令，應該就能在每篇文章底下找到留言板了。

```bash
JEKYLL_ENV=production bundle exec jekyll build
```

## 直接使用在靜態網頁上

如果想要直接使用在單個html上面，不想跟jekyll主題綁在一起的話，可以參考[Gitalk文件當中的方式](https://github.com/gitalk/gitalk#install)，使用起來相當的簡單。

只需要在你的html裡面`<head>`的地方，多引入Gitalk的javascript。

```html
<head>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/gitalk@1/dist/gitalk.css">
    <script src="https://cdn.jsdelivr.net/npm/gitalk@1/dist/gitalk.min.js"></script>
</head>
```

並在`<body>`裡面新增`<script type="text/javascript">`，把相關的變數設定好，client id和client secret的取得可以參考文章上面的[建立GitHub Application](#建立github-application)。

```javascript
const gitalk = new Gitalk({
  clientID: 'GitHub Application Client ID',
  clientSecret: 'GitHub Application Client Secret',
  repo: 'GitHub repo',      // The repository of store comments,
  owner: 'GitHub repo owner',
  admin: ['GitHub repo owner and collaborators, only these guys can initialize github issues'],
  id: location.pathname,      // Ensure uniqueness and length less than 50
  distractionFreeMode: false,  // Facebook-like distraction free mode
  proxy: 'https://netnr-proxy.cloudno.de/https://github.com/login/oauth/access_token'
})

gitalk.render('gitalk-container')
```

這邊有帶入[Gitalk issue](https://github.com/gitalk/gitalk/issues/429)裡面所提到的，其他人所提供的proxy，如果想用原本預設的proxy，直接將proxy的設定拿掉就行。

最後在想要插入Gitalk的地方放個`<div>`就可以了。

```html
<div id="gitalk-container"></div>
```

## 參考資料

1. [主题TeXt评论系统设置中的坑](https://xsaxy.gitee.io/blog/post/2019/12/10/%E4%B8%BB%E9%A2%98TeXt%E8%AF%84%E8%AE%BA%E7%B3%BB%E7%BB%9F%E8%AE%BE%E7%BD%AE%E4%B8%AD%E7%9A%84%E5%9D%91.html)
2. [在授权gitalk后出现403错误](https://github.com/gitalk/gitalk/issues/429)
3. [记录一次 Bug 排查过程并分享一些经验](https://mp.weixin.qq.com/s/Lwl9rf95EqlTYLfconjflQ)
