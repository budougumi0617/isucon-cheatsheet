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

## 要確認
複数台からアクセスする場合はgrantの設定が必要らしい…？


## 読んでおいたほうが良さそうなスクリプト
- https://github.com/south37/isucon-settings/blob/master/scripts/check_mysql.sh
- https://github.com/catatsuy/memo_isucon/blob/master/etc/my.cnf