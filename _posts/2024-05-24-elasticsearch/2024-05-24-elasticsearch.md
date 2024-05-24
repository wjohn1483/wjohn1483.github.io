---
title: 架設Elasticsearch來搜尋log
tags: Tool
layout: article
footer: false
aside:
  toc: true
mathjax_autoNumber: true
published: true
---

這篇文章記錄一下如何架設一個etlasticsearch的伺服器來儲存log，好方便使用者來做搜尋。

<!--more-->

[Elasticsearch](https://www.elastic.co/)是一個開源的搜尋系統，使用者可以將檔案或是文字透過RESTful API的方式上傳到elasticsearch上做index，接著一樣透過RESTful API的方式來根據使用者設定的條件來取得對應的文件，這篇文章會介紹一下如何透過docker架設一個elasticsearch伺服器，並搭配Kibana和Filebeat來監控路徑下的檔案並透過UI來操作。

## 架設Elasticsearch

[架設Elasticsearch](https://www.elastic.co/guide/en/elasticsearch/reference/current/install-elasticsearch.html)的方式有很多種，一個比較簡單的方式是直接去抓docker image下來

```bash
docker network create elastic
docker pull docker.elastic.co/elasticsearch/elasticsearch:8.13.4
sudo sysctl -w vm.max_map_count=262144
docker run --name es01 --net elastic -p 9200:9200 -it -m 1GB docker.elastic.co/elasticsearch/elasticsearch:8.13.4
```

上面的指令會創建一個叫`elastic`的網路，之後創建的container都會放在這個網路底下，而在執行`docker run`以後，最後會停在一個畫面，上會顯示使用者`elastic`的密碼，以及Kibana的enrollment token，我們需要將這個密碼存下來，在之後要使用UI或是打API時都會使用到。

如果想要測試elasticsearch有沒有順利地被建立起來，可以透過底下的指令試打看看

```bash
export ELASTIC_PASSWORD="YOUR_PASSWORD_HERE"
docker cp es01:/usr/share/elasticsearch/config/certs/http_ca.crt .
curl --cacert http_ca.crt -u elastic:${ELASTIC_PASSWORD} https://localhost:9200
```

要跟elasticsearch溝通除了需要帳號密碼以外，我們還需要一個http certificate，這邊可以直接從container裡面複製出來。

## 架設Kibana

Kibana是用來跟Elasticsearch互動的UI介面，一樣也可以透過docker來建立

```bash
docker pull docker.elastic.co/kibana/kibana:8.13.4
docker run --name kib01 --net elastic -p 5601:5601 docker.elastic.co/kibana/kibana:8.13.4
```

這時使用瀏覽器連線到[http://localhost:5601](http://localhost:5601)應該就可以看到kibana的介面了，畫面上會顯示要你填入enrollment token，把上方elasticsearch顯示的enrollment token直接填入就可以讓兩者順利連線了。

## 上傳Document

在建立好elasticsearch和kibana以後，接著就可以把我們想要從中搜尋的文件給上傳上去了，elasticsearch提供了很多方式可以上傳，這邊介紹如何透過python和filebeat來上傳。

### 使用Python上傳Document

首先我們需要先安裝elasticsearch的套件

```bash
pip3 install elasticsearch
```

接著就可以透過python來連線到elasticsearch了

```python
from elasticsearch import Elasticsearch

es = Elasticsearch("https://localhost:9200",
                   basic_auth=("elastic", "YOUR_PASSWORD_HERE"),
                   ca_certs="./http_ca.crt")
```

這邊需要提供elasticsearch所架設的位置、帳號密碼和http certificate的路徑來建立連線。

下一步便是建立一個elasticsearch的index，好把我們想要搜尋的document放進這個index裡面

```python
es.indices.create(index="YOUR_INDEX_NAME")
# es.indices.delete(index="YOUR_INDEX_NAME", ignore=[400, 404])
```

如果想要刪除，重新建立index的話，可以使用上面`delete`的function來把整個index刪掉。

最後就是將document上傳上去

```python
es.index(
    index="YOUR_INDEX_HERE",
    id=f"{document_id}",
    document={
        "name": f"{document_name}",
    }
)
```

這邊我們上傳了一個document，其id是`f"{document_id}"`，底下有一個field是`name`，其對應的value是`f"{document_name}"`，這裡可以根據你對document的理解和處理來新增多個field，但id只能有一個。

這時，在Kibana上面做仿側邊欄的**Search→Content**裡面應該就能看到你上傳上去的index和document了，如果想透過python來query的話，可以使用下面的方式透過document name來搜尋

```python
response = es.search(index="YOUR_INDEX_HERE",
                     body={
                         "query": {
                             "match": {
                                 "name": f"{document_name}",
                             }
                         }
                     })
```

[Elasticsearch還有提供多種方式](https://www.elastic.co/guide/en/elasticsearch/reference/current/search-with-elasticsearch.html)來做搜尋，如果需要的話可以再自行研究。

### 使用Filebeat上傳Document

上面使用python的方式是我們主動將document上傳到elasticsearch上，另一個方式是使用filebeat去監聽特定路徑下的檔案更動，如果有新的更動就將新的資料上傳到elastcissearch上，filebeat是[Logstash](https://www.elastic.co/logstash)裡面比較輕量化的檔案監聽套件，如果需求比較複雜的話可以嘗試使用Logstash看看。

[安裝filebeat的方式](https://www.elastic.co/guide/en/beats/filebeat/current/filebeat-installation-configuration.html)有很多種方法，底下使用的是rpm的安裝方式

```bash
curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-8.13.4-x86_64.rpm
sudo rpm -vi filebeat-8.13.4-x86_64.rpm
```

安裝好以後，我們可以打開`/etc/filebeat/filebeat.yml`來設定filebeat，首先需要設定filebeat連接到elasticsearch，在`output.elasticsearch`的區塊改成底下的設定

```yaml
output.elasticsearch:
  hosts: ["https://localhost:9200"]
  preset: balanced
  prototol: "https"
  username: "elastic"
  password: "${ES_PASS}"
  ssl.certificate_authorities: ["/path/to/your/certificate"]
```

這邊的`${ES_PASS}`是存放在filebeat keystore的變數，如果直接把密碼寫在yml裡面會有洩漏的風險，[filebeat提供了keystore的功能](https://www.elastic.co/guide/en/beats/filebeat/8.13/keystore.html)讓你把機密資訊存起來，使用的方式是先建立keystore

```bash
filebeat keystore create
```

接著就能透過底下的指令來設定變數

```bash
filebeat keystore add ES_PASS
```

再來我們就可以跳到`filebeat.inputs`的地方來設定要監聽的路徑，底下是一個簡單的模板

```yaml
filebeat.inputs:
- type: filestream
  id: your_input_id
  enabled: true
  paths:
    - /path/to/your/logs
    # e.g. - /var/log/*.log
  # json.keys_under_root: true
  # json.add_error_key: true
  index: "your_index"
```

如果想要監聽其他路徑的檔案並放到不同的index裡面，只需要再另外加一個`type`的區塊就可以了，這邊我們需要設定這個input的id、要監聽的路徑以及想要放到elasticsearch的哪個index裡面。

設定好以後，執行底下的指令讓filebeat跑起來，就可以在Kibana上面看到filebeat上傳的index了，在左邊側邊欄裡面的**Management→Stack Management→Index Management**也可以看到相關的設定。

```bash
filebeat -e
```

如果在上傳的時候發現問題，想讓filebeat重新上傳整個index，除了在kibana裡面砍掉index外，我們需要把底下的資料夾也砍掉，讓filebeat忘記過去曾經上傳過的東西以後，重啟filebeat的服務來整個重新上傳。

```bash
/var/lib/filebeat/registry
```

#### Parse json log

Filebeat預設會是一行一行地讀取路徑底下的檔案，如果這個檔案是紀錄json的log，每一行是一個json object的話，我們可以在`filebeat.inputs`多加`json.keys_under_root`和`json.add_error_key`來讓filebeat幫我們去parse json的log。

這時如果去kibana上面看會發現到filebeat把整個json object放到`message`這個field裡面，沒有把json的key、value塞到對應的field

```yaml
processors:
  - decode_json_fields:
    fields: ["message"]
    process_array: false
    max_depth: 2
    target: ""
    overwrite_keys: true
    add_error_key: false
```

我們還需要在`/etc/filebeat/filebeat.yml`裡面`processors`的區塊多加`decode_json_fields`來明確地告訴filebeat我們想要解析`message`這個field，設定好並重啟filebeat的服務以後就可以在kibana上面看到json object裡面的key、value被塞進elasticsearch index裡document的field了。

## 參考資料

* [親愛的，我把ElasticSearch上雲了 :: 第 12 屆 iThome 鐵人賽](https://ithelp.ithome.com.tw/users/20130639/ironman/3747)

* [ 一篇文章搞懂filebeat（ELK）](https://www.cnblogs.com/zsql/p/13137833.html)
