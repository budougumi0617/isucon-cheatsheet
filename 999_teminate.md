# 最後にやることリスト

## 不要なサービスを起動しないようにしておく
```bash
sudo systemctl stop newrelic-infra.service
sudo systemctl disable newrelic-infra.service
sudo systemctl stop netdata
sudo systemctl disable netdata
```

## Newrelicのコードを消す

## nginxのログ出力を変えておく？

## MySQLの設定を変えておく