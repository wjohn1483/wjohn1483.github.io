---
title: OpenClaw 介紹
tags: Tool
layout: article
footer: false
aside:
  toc: true
mathjax_autoNumber: true
published: true
---

這篇文章記錄一下如何安裝並使用OpenClaw。


<!--more-->

## OpenClaw 是什麼

[OpenClaw](https://openclaw.ai/) 是一個開源的 AI 工具，核心概念是讓 AI 助手能安全地控制你的電腦：你透過聊天介面（例如 Telegram）下指令，OpenClaw 在本地執行對應操作，並把結果回傳給你。所有邏輯都在你的機器上執行，你可以自行決定要開放哪些工具與權限，適合用來做遠端查資料、跑腳本、或整合其他服務（例如寫入 Google 試算表）。

## 安裝 OpenClaw

我自己安裝的方式是把OpenClaw裝在一個docker container裡面，避免OpenClaw把本機的環境搞亂、把個人的資訊外洩出去。

可以先去OpenClaw的GitHub上面把整個repo clone下來，直接使用他們的Dockerfile來建立docker container。

```bash
git clone https://github.com/openclaw/openclaw.git
docker build -t openclaw:local -f Dockerfile .
docker run -i -t --name openclaw -p 8000:8000 openclaw:local bash
```

這邊在建立container的時候有設定讓host的port 8000連線到container的port 8000，好方便之後連線到OpenClaw的Web介面。如果你需要在container裡面使用root的權限安裝其他套件像是go、brew、python等等的話，可以自行修改Dockerfile，看是在創造image的時候安裝好，或是把`USER node`去除掉，直接用root跑。

進入到container以後就可以來安裝OpenClaw了。

```bash
curl -fsSL https://openclaw.ai/install.sh | bash
```

過程中會提示你輸入一些資訊，像是LLM的key、telegram的token、以及一些其他設定，如果還沒有準備好的話也可以先跳過，之後再回頭來設定。

安裝完成後，往上看一下log會看到一個 **token**，用來在瀏覽器或遠端連線時驗證身份。請務必把這個 token 記下來或妥善保存，後續連線到 OpenClaw 的 Web 介面時都會需要用到。

## 使用 OpenClaw

因為OpenClaw預設是使用systemd來管理process，但是在docker裡面沒有，我們需要手動執行底下指令來啟動OpenClaw。

```bash
openclaw gateway run
```

安裝完成並啟動後，OpenClaw 預設會在 **http://127.0.0.1:18789** 提供 Web 介面，但是因為我們在container裡面，需要讓外面的request可以傳送到0.0.0.0，因此我們可以透過socat來幫我們達成這件事情。

```bash
socat TCP-LISTEN:8000,fork,bind=0.0.0.0 TCP:127.0.0.1:18789
```

這時候就可以在host上面透過瀏覽器連線到

```
http://localhost:8000/?token=<token>
```

來打開OpenClaw的Web介面了，接下來就可以開始使用OpenClaw。

若你希望在外出時也能從手機或另一台電腦操作，就需要把 port 暴露到網路上。可以透過 SSH tunnel 連回自家電腦，或使用 [Cloudflare Tunnel](https://www.cloudflare.com/products/tunnel/) 這類服務，把本地服務安全地對外開放。若想了解如何設定 Cloudflare Tunnel，可參考本站文章：[使用 Cloudflare Tunnel 實現遠端訪問](https://wjohn1483.github.io/2025/11/23/cloudflare-tunnel/)。

## 連結 Telegram

首先你會需要先建立一個Telegram bot，可以參考本站文章：[Telegram Bot](https://wjohn1483.github.io/2025/10/18/n8n/#telegram-bot)，接著在Telegram上面隨意傳一個訊息給bot，OpenClaw就會收到pairing的request。

透過下面的指令可以查看Telegram上面有哪些pairing的request。

```bash
openclaw pairing list telegram
```

接著執行：

```bash
openclaw pairing approve telegram <CODE>
```

將 `<CODE>` 換成上一步取得的代碼，即可完成 Telegram 與 OpenClaw 的綁定。之後即可在 Telegram 中對你的電腦下達指令。

## 連結其他服務

### Brave Search API

在讓OpenClaw跑起來以後，通常會希望他可以搜尋網路上的資料，這時候可以透過Brave Search API來達成，我們可以先去[Brave Search API](https://brave.com/search/api/)申請一個API key，通常免費的方案就可以滿足一般需求，接下來在container裡面執行底下指令來設定Brave Search API。

```bash
openclaw configure --section web
```

### Google Sheets

因為OpenClaw本身可以執行程式碼，所以如果有想要讓他可以操作的服務，可以把相關的credential給他以後，並告訴他位置在哪裡，讓他可以自己讀取並使用。

以Google試算表為例，做法大致如下：

1. **取得 Google Service 憑證**：在 Google Cloud Console 建立 Service Account，下載 JSON 金鑰檔。若你還沒做過，可參考本站 [如何製作 Slack 機器人](https://wjohn1483.github.io/2020/05/07/slack-bot/#與google-sheet互動) 一文中的「與 Google Sheet 互動」與「建立 service account」章節，步驟與取得 Google Sheets API 憑證相同。
2. **放置憑證**：將取得的憑證檔（或 token）放到container的 `~/.openclaw/credentials/` 目錄下。
3. **更新工具說明**：可透過 OpenClaw 的 prompt 介面，請 AI 協助你更新或維護 `TOOLS.md` 等文件，讓OpenClaw知道有哪些工具可用、如何呼叫。像是下面的prompt：

```
我將可以操作google sheet的credential放在~/.openclaw/credentials/google_service_account.json，請幫我更新TOOLS.md，每當需要操作google sheet的時候，請使用這個credential。
```

## 結論

OpenClaw 是一個方便在本地執行的 AI 操作工具，透過 Telegram 即可遠端對電腦下指令，並可搭配 Cloudflare Tunnel、Google 試算表等服務擴充使用情境。若你希望減少重複操作、或想用自然語言控制自家電腦，可以考慮試試看 OpenClaw。

## 參考資料

* [OpenClaw](https://github.com/openclaw/openclaw)
* [OpenClaw Documentation](https://docs.openclaw.ai/start/getting-started)
