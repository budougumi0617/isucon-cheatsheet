# MySQLの設定

## ローカルからのアクセスを有効したりスロークエリを有効にする
`/etc/mysql/my.cnf`の設定を変更する。

```
[mysqld]
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow.log
long_query_time = 0
bind-address = 0.0.0.0
```

my.cnfを編集したらサービスを再起動しておく

```bash
$ systemctl list-unit-files --type=service | grep sql
mysql.service                                  enabled

$ sudo systemctl restart mysql
$ sudo systemctl restart isuumo.go
```

## リモートアクセスを許可する
複数台アクセスだったりローカルからアクセスできるようにしておく。
bind-access以外にもGRANT設定が必要。
```
$ cat env.sh
MYSQL_HOST="127.0.0.1"
MYSQL_PORT=3306
MYSQL_USER=isucon
MYSQL_DBNAME=isuumo
MYSQL_PASS=isucon
$ mysql -h 127.0.0.1 -uisucon -pisucon
> grant all privileges on *.* to isucon@"%" identified by 'isucon' with grant option;
```

ガバガバだけれどリモートからつながるようになる。

## dumpしておく
```bash
$ mysql -uisucon -pisucon -e "show databases;"
mysql: [Warning] Using a password on the command line interface can be insecure.
+--------------------+
| Database           |
+--------------------+
| information_schema |
| isuumo             |
| mysql              |
| performance_schema |
| sys                |
+--------------------+

$ mysqldump --single-transaction -u isucon -pisucon isuumo > /tmp/isuumo_dump.sql
```

ローカルで
```bash
$ scp isu10A:/tmp/isuumo_dump.sql .
```

## チューニング
- https://gist.github.com/south37/d4a5a8158f49e067237c17d13ecab12a#innodb-buffer
- http://www.slideshare.net/kazeburo/mysql-casual7isucon


```
innodb_buffer_pool_size = 1GB # ディスクイメージをメモリ上にバッファさせる値をきめる設定値
innodb_flush_log_at_trx_commit = 2 # 1に設定するとトランザクション単位でログを出力するが 2 を指定すると1秒間に1回ログファイルに出力するようになる
innodb_flush_method = O_DIRECT # データファイル、ログファイルの読み書き方式を指定する(実験する価値はある)
```

## 読んでおいたほうが良さそうなスクリプト
- https://github.com/south37/isucon-settings/blob/master/scripts/check_mysql.sh
- https://github.com/catatsuy/memo_isucon/blob/master/etc/my.cnf


## 参考
- https://kazegahukeba.hatenablog.com/entry/2019/09/13/015113