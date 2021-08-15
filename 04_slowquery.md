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
$ sudo pt-query-digest /var/log/mysql/slow.log > slow_dgst_`date "+%Y%m%d_%H%M%S"`.log
$ ls
slow_dgst_20210731_151419.log
```


## index貼る
`pt-query-digest` コマンドで解析した内容を使ってindex貼っていく。
出力した解析結果からSQLを持ってきてEXPLAINもしておくと確実。貼った後にrowsとかkeyが変わっていればindexが効いている。


```sql
mysql> EXPLAIN SELECT * FROM chair WHERE stock > 0 ORDER BY price ASC, id ASC LIMIT 20\G
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: chair
   partitions: NULL
         type: ALL
possible_keys: NULL
          key: NULL
      key_len: NULL
          ref: NULL
         rows: 29411
     filtered: 33.33
        Extra: Using where; Using filesort
1 row in set, 1 warning (0.01 sec)

mysql> ALTER TABLE isuumo.chair ADD INDEX idx_chair_price_id(price, id);
Query OK, 0 rows affected (0.05 sec)
Records: 0  Duplicates: 0  Warnings: 0

mysql> EXPLAIN SELECT * FROM chair WHERE stock > 0 ORDER BY price ASC, id ASC LIMIT 20\G
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: chair
   partitions: NULL
         type: index
possible_keys: NULL
          key: idx_chair_price_id
      key_len: 8
          ref: NULL
         rows: 20
     filtered: 33.33
        Extra: Using where
1 row in set, 1 warning (0.02 sec)

```

## あとで読んでおいたほうが良さそうなスクリプト
- https://github.com/south37/isucon-settings/blob/master/scripts/check_mysql.sh
- https://github.com/catatsuy/memo_isucon/blob/master/etc/my.cnf