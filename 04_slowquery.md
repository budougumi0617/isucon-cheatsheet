# MySQLのスロークエリを解析する
`mysqldumpslow` コマンドはデフォルトで入っているはず。

## インストール方法
```bash
$ sudo apt-get install percona-toolkit
$ pt-query-digest --version
pt-query-digest 3.0.6
```

## 事前準備
my.cnfを編集したらサービスを再起動しておく

```bash
$ systemctl list-unit-files --type=service | grep sql
mysql.service                                  enabled

$ sudo systemctl restart mysql
$ sudo systemctl restart isuumo.go
```

## スロークエリを確認する
ベンチマーク実行前にトランケートしておく
```bash
$ sudo truncate --size 0 /var/log/mysql/slow.log
$ sudo ls -lha /var/log/mysql/slow.log
-rw-r----- 1 mysql mysql 0 Jul 31 08:23 /var/log/mysql/slow.log
```

ベンチマークを実行する。
```
$ sudo ls -lha /var/log/mysql/slow.log
-rw-r----- 1 mysql mysql 42M Jul 31 08:33 /var/log/mysql/slow.log
```

## mysqldumpslowで解析する
sudoつけるのわすれないこと
```bash
$ sudo mysqldumpslow /var/log/mysql/slow.log
```

## pt-query-digestで解析する
sudoつけるのわすれないこと
```bash
$ sudo pt-query-digest /var/log/mysql/slow.log
```






## あとで読んでおいたほうが良さそうなスクリプト
- https://github.com/south37/isucon-settings/blob/master/scripts/check_mysql.sh
- https://github.com/catatsuy/memo_isucon/blob/master/etc/my.cnf