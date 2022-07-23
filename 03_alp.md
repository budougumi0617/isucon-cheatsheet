# alpを使ってアクセスログを解析してみる。
https://github.com/tkuchiki/alp/blob/main/README.ja.md

アクセスログ解析ツールを使ってログを解析する。

## インストール
https://github.com/tkuchiki/alp/releases

最新を確認しておいたほうがいいかもしれない。

```
wget https://github.com/tkuchiki/alp/releases/download/v1.0.5/alp_linux_amd64.zip
unzip alp_linux_amd64.zip
sudo install ./alp /usr/local/bin/alp
```

## アクセスログをalpで解析するフォーマットに変更する
nginxの設定を変更する。

`/etc/nginx/nginx.conf` の設定にこんな感じの記述をする。
```conf
    log_format ltsv "time:$time_local"
                "\thost:$remote_addr"
                "\tforwardedfor:$http_x_forwarded_for"
                "\treq:$request"
                "\tstatus:$status"
                "\tmethod:$request_method"
                "\turi:$request_uri"
                "\tsize:$body_bytes_sent"
                "\treferer:$http_referer"
                "\tua:$http_user_agent"
                "\treqtime:$request_time"
                "\tcache:$upstream_http_x_cache"
                "\truntime:$upstream_http_x_runtime"
                "\tapptime:$upstream_response_time"
                "\tvhost:$host";

    access_log  /var/log/nginx/access.log ltsv;
```
スニペット用意したならばこれでもよい。
```bash
sudo ln -s ~/isuports/etc/nginx/nginx.conf /etc/nginx/nginx.conf
```

## ngninxを再起動する
再起動して設定を反映させる。
```bash
sudo systemctl restart nginx
sudo systemctl status nginx
● nginx.service - A high performance web server and a reverse proxy server
   Loaded: loaded (/lib/systemd/system/nginx.service; enabled; vendor preset: enabled)
   Active: active (running) since Sat 2021-07-31 07:47:09 UTC; 4s ago
     Docs: man:nginx(8)
  Process: 2761 ExecStop=/sbin/start-stop-daemon --quiet --stop --retry QUIT/5 --pidfile /run/nginx.pid (code=exited, status=0/SUCCESS)
  Process: 2773 ExecStart=/usr/sbin/nginx -g daemon on; master_process on; (code=exited, status=0/SUCCESS)
  Process: 2764 ExecStartPre=/usr/sbin/nginx -t -q -g daemon on; master_process on; (code=exited, status=0/SUCCESS)
 Main PID: 2775 (nginx)
    Tasks: 2 (limit: 2347)
   CGroup: /system.slice/nginx.service
           ├─2775 nginx: master process /usr/sbin/nginx -g daemon on; master_process on;
           └─2777 nginx: worker process

Jul 31 07:47:09 ip-172-31-30-186 systemd[1]: Stopped A high performance web server and a reverse proxy server.
Jul 31 07:47:09 ip-172-31-30-186 systemd[1]: Starting A high performance web server and a reverse proxy server...
Jul 31 07:47:09 ip-172-31-30-186 systemd[1]: nginx.service: Failed to parse PID from file /run/nginx.pid: Invalid argument
Jul 31 07:47:09 ip-172-31-30-186 systemd[1]: Started A high performance web server and a reverse proxy server.
```

## アクセスログをリセットする
ベンチマーク実行するまえにアクセスログをトランケートしておく。  
（alpの`--pos`オプションを使うならばトランケートする必要はない）。

```bash
$ ls -lah /var/log/nginx/access.log
-rw-r--r-- 1 root root 2.8M Jul 31 07:14 /var/log/nginx/access.log
$ sudo truncate --size 0 /var/log/nginx/access.log
$ ls -lah /var/log/nginx/access.log
-rw-r--r-- 1 root root 0 Jul 31 07:51 /var/log/nginx/access.log
```

## alpで解析を開始する
ベンチマーク実行後にalpを実行してみる。

```bash
$ cat /var/log/nginx/access.log | alp ltsv -m "/api/estate/.+","/api/recommended_estate/.+","/api/chair/.+" --sort=sum -r
+-------+-----+------+-----+-----+-----+--------+----------------------------+-------+-------+---------+-------+-------+-------+-------+--------+-----------+-----------+--------------+-----------+
| COUNT | 1XX | 2XX  | 3XX | 4XX | 5XX | METHOD |            URI             |  MIN  |  MAX  |   SUM   |  AVG  |  P90  |  P95  |  P99  | STDDEV | MIN(BODY) | MAX(BODY) |  SUM(BODY)   | AVG(BODY) |
+-------+-----+------+-----+-----+-----+--------+----------------------------+-------+-------+---------+-------+-------+-------+-------+--------+-----------+-----------+--------------+-----------+
|  2120 |   0 | 2115 |   0 |   5 |   0 | GET    | /api/estate/.+             | 0.004 | 0.624 | 185.240 | 0.087 | 0.188 | 0.224 | 0.276 |  0.079 |     0.000 | 31647.000 | 22045223.000 | 10398.690 |
|  1465 |   0 | 1460 |   0 |   5 |   0 | GET    | /api/chair/.+              | 0.036 | 0.616 | 163.555 | 0.112 | 0.208 | 0.252 | 0.304 |  0.080 |     0.000 | 30177.000 | 15820035.000 | 10798.659 |
|   405 |   0 |  399 |   0 |   6 |   0 | POST   | /api/estate/.+             | 0.598 | 2.001 |  40.304 | 0.100 | 0.264 | 0.636 | 1.620 |  0.297 |     0.000 | 33918.000 |  1206118.000 |  2978.069 |
|   245 |   0 |  245 |   0 |   0 |   0 | GET    | /api/recommended_estate/.+ | 0.076 | 0.588 |  36.615 | 0.149 | 0.208 | 0.236 | 0.336 |  0.054 | 13128.000 | 13727.000 |  3276996.000 | 13375.494 |
|     1 |   0 |    1 |   0 |   0 |   0 | POST   | /initialize                | 2.376 | 2.376 |   2.376 | 2.376 | 2.376 | 2.376 | 2.376 |  0.000 |    23.000 |    23.000 |       23.000 |    23.000 |
|   121 |   0 |  121 |   0 |   0 |   0 | POST   | /api/chair/.+              | 0.004 | 0.052 |   1.584 | 0.013 | 0.028 | 0.032 | 0.052 |  0.010 |     0.000 |     0.000 |        0.000 |     0.000 |
|     1 |   0 |    1 |   0 |   0 |   0 | POST   | /api/chair                 | 0.308 | 0.308 |   0.308 | 0.308 | 0.308 | 0.308 | 0.308 |  0.000 |     0.000 |     0.000 |        0.000 |     0.000 |
|     1 |   0 |    1 |   0 |   0 |   0 | POST   | /api/estate                | 0.272 | 0.272 |   0.272 | 0.272 | 0.272 | 0.272 | 0.272 |  0.000 |     0.000 |     0.000 |        0.000 |     0.000 |
+-------+-----+------+-----+-----+-----+--------+----------------------------+-------+-------+---------+-------+-------+-------+-------+--------+-----------+-----------+--------------+-----------+
```

### いろいろな解析方法
参考例があるのでこれでいろいろできる。ありがたし…

https://github.com/tkuchiki/alp/blob/main/docs/usage_samples.ja.md


## ローカルでアクセスログの解析をする
sshの設定が完了しているならばこれで取得できる。
```bash
$ scp isu10A:/var/log/nginx/access.log .
```

## 設定
毎回コマンドラインオプション使うのがめんどいときはこんな感じ。`-c CONFIG_FILE` で呼び出せる。
```yaml
file:                       # string
  "/var/log/nginx/access.log"
sort:                       # max|min|avg|sum|count|uri|method|max-body|min-body|avg-body|sum-body|p1|p50|p99|stddev
  "sum"
reverse:                    # boolean
  true
query_string:               # boolean
query_string_ignore_values: # boolean
decode_uri:                 # boolean
format:                     # string
limit:                      # 5000
noheaders:                  # boolean
show_footers:               # boolean
matching_groups:            # array
  - "/api/estate/.+"
  - "/api/recommended_estate/.+"
  - "/api/chair/.+"
filters:                    # string
output:                     # string(comma separated)
pos_file:                   # string
nosave_pos:                 # boolean
percentiles:                # array
ltsv:
  apptime_label: # apptime
  status_label:  # status code
  size_label:    # size
  method_label:  # method
  uri_label:     # uri
  time_label:    # time

```

## 参考
- https://shiningcureseven.hatenablog.com/entry/2020/10/10/174514
- https://github.com/tkuchiki/alp/blob/main/README.ja.md
- https://github.com/tkuchiki/alp/blob/main/docs/usage_samples.ja.md