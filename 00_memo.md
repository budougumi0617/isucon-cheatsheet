# 雑メモ

動いているサービスを確認する
```bash
$ systemctl list-unit-files --type=service
```

設定内容を確認する
```bash
$ sudo cat /etc/systemd/system/isuumo.go.service
[Unit]
Description=isuumo.go

[Service]
WorkingDirectory=/home/isucon/isuumo/webapp/go
EnvironmentFile=/home/isucon/env.sh
PIDFile=/home/isucon/isuumo/webapp/go/server.pid

User=isucon
Group=isucon
ExecStart=/home/isucon/isuumo/webapp/go/isuumo
ExecStop=/bin/kill -s QUIT $MAINPID

Restart   = always
Type      = simple

[Install]
WantedBy=multi-user.target

```

## OSのバージョン確認
https://docs.newrelic.com/docs/infrastructure/install-infrastructure-agent/linux-installation/install-infrastructure-monitoring-agent-linux/


## Linuxサーバにログインしたらいつもやっているオペレーション - ゆううきブログ
https://blog.yuuk.io/entry/linux-server-operations

## 参考
- https://shiningcureseven.hatenablog.com/entry/2020/10/10/174514
- https://qiita.com/DQNEO/items/0b5d0bc5d3cf407cb7ff
