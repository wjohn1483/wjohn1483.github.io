---
title: 在遠端的job執行完成時發送通知
tags: Tool
layout: article
footer: false
aside:
  toc: true
mathjax_autoNumber: true
published: true
---

這邊記錄一個方法來當server上的job跑完時，可以在MacBook上面跳出一個通知。

<!--more-->

## 方法簡介

使用的方法是透過在SSH連線至遠端server的時候，順便做port forwarding，把自己電腦的port 22接上遠端server，如此便可以讓遠端server透過SSH連線回電腦上使用command line跳出通知。

## 在MacBook上面允許SSH連線

首先，我們必須要讓MacBook可以接受SSH離線，只需要在`設定→共享`裡面打開SSH連線的設定就可以了，在[Apple官方的使用手冊](https://support.apple.com/zh-tw/guide/mac-help/mchlp1066/mac)上有詳細的說明。

## Forward Local Port

在SSH連線到遠端server的時候，可以多加`-R`這個option，便可以把本機的port接到遠端server上。

```bash
ssh -R 2000:localhost:22 <username>@<hostname>
```

在上面的指令當中，便是將遠端server的port 2000跟本機的port 22做連結。

## 從Server連回本機

在連上server以後，可以先試著將底下的`username`換成本機的使用者名稱測試看看能不能連回來。

```bash
ssh -p 2000 <username>@localhost
```

如果能順利連回來的話，接下來便是把public key放到本機裡面，以避免每次連線都要打密碼，詳細的流程看底下的步驟，主要是參考[這篇文章](https://help.dreamhost.com/hc/en-us/articles/216499537-How-to-configure-passwordless-login-in-Mac-OS-X-and-Linux)。

1. 在server上使用底下的指令創造key

    ```bash
    ssh-keygen
    ```

2. 把創建出來，帶有`.pub`副檔名的檔案裡面所有的內容複製進本機的**~/.ssh/authorized_keys**這份檔案中，如果這個檔案原本不存在，可以直接用文字編輯器建立

3. 在server上透過key來連線至本機

    ```bash
    ssh -i <path to private key> -p <port> <username>@localhost
    ```

    預設private key的路徑會是**~/.ssh/id_rsa**。

## 傳送Notification

在能順利從server連回本機以後，就可以透過command line來傳送notification了，底下的指令是使用MacBook原生的指令來產生notification，其他argument可以參考[這篇文章](https://code-maven.com/display-notification-from-the-mac-command-line)。

```bash
osascript -e 'display notification "" with title "Job Finished!" subtitle ""'
```

在通知跳出來以後，可以對著通知按右鍵對通知做設定。

## 總結

上面使用了一個簡單的方式來讓server控制本機發送通知，可以將連線、發送通知寫成腳本，並在server完成job時呼叫這個腳本來提醒你job已經跑完了。

```bash
[Your command] || send_notification.sh
```

## 參考資料

1. [SSH back to the local machine from a remote SSH session](https://serverfault.com/questions/175798/ssh-back-to-the-local-machine-from-a-remote-ssh-session)

