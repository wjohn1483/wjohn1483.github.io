---
title: nginx Reverse Proxy
tags: Tool
layout: article
footer: false
aside:
  toc: true
mathjax_autoNumber: true
published: true
---

最近想要把在同一台機器上面的不同服務都使用同一個port來去做serving，這邊記錄一下嘗試使用nginx來做reverse proxy的過程。

<!--more-->

在機器上因為不同的需求開了兩個不同的服務在不同的port，但想要讓這兩個服務都透過相同的port 80來給使用者來做使用，這時候我們可以使用nginx的反向代理功能來讓使用者使用相同的port 80，搭配不同的path來連到不同的服務。

## 安裝nginx

底下是在CentOS上面安裝時使用的指令，不同的作業系統的安裝方法可以參考[官網](https://www.nginx.com/resources/wiki/start/topics/tutorials/install/)上的介紹。

```bash
sudo yum install -y nginx
```

## 設定nginx

關於nginx的設定都放在`/etc/nginx/nginx.conf`裡面，我們可以在http$\rightarrow$server的區塊裡面，新增不同的path來讓nginx來做反向代理。

```nginx
# For more information on configuration, see:
#   * Official English Documentation: http://nginx.org/en/docs/
#   * Official Russian Documentation: http://nginx.org/ru/docs/

user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

# Load dynamic modules. See /usr/share/doc/nginx/README.dynamic.
include /usr/share/nginx/modules/*.conf;

events {
    worker_connections 1024;
}

http {
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   65;
    types_hash_max_size 4096;

    gzip_static off;

    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;

    # Load modular configuration files from the /etc/nginx/conf.d directory.
    # See http://nginx.org/en/docs/ngx_core_module.html#include
    # for more information.
    include /etc/nginx/conf.d/*.conf;

    server {
        listen       80;
        listen       [::]:80;
        server_name  <YOUR_HOST_NAME>;

        # Load configuration files for the default server block.
        include /etc/nginx/default.d/*.conf;

        location / {
            proxy_pass http://localhost:8000;
        }

        location /test {
            rewrite ^/test(/.*)$ $1 break;
            proxy_pass http://localhost:9000;
            proxy_redirect / /test/;
        }

        error_page 404 /404.html;
        location = /404.html {
        }

        error_page 500 502 503 504 /50x.html;
        location = /50x.html {
        }
    }
}
```

在上面的例子裡面，我們新增了底下的設定

```nginx
        location / {
            proxy_pass http://localhost:8000;
        }

        location /test {
            rewrite ^/test(/.*)$ $1 break;
            proxy_pass http://localhost:9000;
            proxy_redirect / /test/;
        }
```

我們使用`proxy_pass`來將不同path的request傳到對應的服務上，假如使用者連到`HOST/`，就會導到`localhost:8000`，如果連到`HOST/test/`就會導到`localhost:9000`。

不過如果只有單純的`proxy_pass`，被重新導向的路徑會也帶上使用者加上的`/test/`，倘若希望在導向的時候將這個path給去除，讓服務收到的request是`/`的話，可以使用`rewrite`來對request做修改。

同樣地，如果服務收到`/`的request以後，想重新導向到服務的`/redirect`路徑，這時使用者實際上要request的就會需要是`HOST/test/redirect`，我們可以使用`proxy_redirect`來幫服務的重新導向加上`/test/`的前綴。

## 啟動nginx

在寫好configuration以後，我們可以透過`nginx -t`來檢驗設定檔有沒有寫錯的地方，如果順利通過就能將nginx的服務起起來了。

```bash
sudo /usr/sbin/nginx -t
sudo service nginx start
sudo service nginx reload
chkconfig nginx on
```

而nginx本身的log會寫到底下的路徑，每當有使用者連線進來，就會寫到`access.log`，如果發生了錯誤會寫到`error.log`。

```bash
/var/log/nginx/access.log
/var/log/nginx/error.log
```

如果之後設定檔有做其他的修改，只需要執行`nginx reload`就可以讓新的設定生效。

## 參考資料

1. [如何設置和配置為反向代理](https://blog.containerize.com/zh-hant/how-to-setup-and-configure-nginx-as-reverse-proxy/)
