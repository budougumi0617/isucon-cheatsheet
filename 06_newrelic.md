# Newrelicを使ってモニタリングする。

## 事前準備
https://blog.newrelic.co.jp/best-practices/create-new-license-key/

デフォルトのライセンスキーは簡単に消せないので新規に発行しておく。

## Infrastructure Agentの導入
- https://blog.newrelic.co.jp/isucon/install-newrelic-infrastructure-for-isucon10-qualify/
- https://qiita.com/koinori/items/4b897f28faae517acd38
Ubuntu18.04系はdebian10でよいはず。

ここからDebian10を選んでスクリプトを発行する。
https://docs.newrelic.com/docs/infrastructure/install-infrastructure-agent/linux-installation/install-infrastructure-monitoring-agent-linux/

```bash
# Add the New Relic Infrastructure Agent gpg key \
curl -s https://download.newrelic.com/infrastructure_agent/gpg/newrelic-infra.gpg | sudo apt-key add - && \
\
# Create a configuration file and add your license key \
echo "license_key: ****..." | sudo tee -a /etc/newrelic-infra.yml && \
\
# Create the agent’s apt repository \
printf "deb [arch=amd64] https://download.newrelic.com/infrastructure_agent/linux/apt buster main" | sudo tee -a /etc/apt/sources.list.d/newrelic-infra.list && \
\
# Update your apt cache \
sudo apt-get update && \
\
# Run the installation script \
sudo apt-get install newrelic-infra -y
OK
license_key: ****...
Hit:1 http://ap-northeast-1.ec2.archive.ubuntu.com/ubuntu bionic InReleaseapt buster main
Hit:2 http://ap-northeast-1.ec2.archive.ubuntu.com/ubuntu bionic-updates InRelease
Hit:3 http://ap-northeast-1.ec2.archive.ubuntu.com/ubuntu bionic-backports InRelease
Get:4 https://download.newrelic.com/infrastructure_agent/linux/apt buster InRelease [10.8 kB]
Get:5 http://security.ubuntu.com/ubuntu bionic-security InRelease [88.7 kB]
Get:6 https://download.newrelic.com/infrastructure_agent/linux/apt buster/main amd64 Packages [93.1 kB]
Fetched 193 kB in 1s (195 kB/s)
Reading package lists... Done
Reading package lists... Done
Building dependency tree
Reading state information... Done
Recommended packages:
  td-agent-bit
The following NEW packages will be installed:
  newrelic-infra
0 upgraded, 1 newly installed, 0 to remove and 25 not upgraded.
Need to get 42.1 MB of archives.
After this operation, 124 MB of additional disk space will be used.
Get:1 https://download.newrelic.com/infrastructure_agent/linux/apt buster/main amd64 newrelic-infra amd64 1.19.4 [42.1 MB]
Fetched 42.1 MB in 1s (39.3 MB/s)
Selecting previously unselected package newrelic-infra.
(Reading database ... 132839 files and directories currently installed.)
Preparing to unpack .../newrelic-infra_1.19.4_amd64.deb ...
Unpacking newrelic-infra (1.19.4) ...
Setting up newrelic-infra (1.19.4) ...
Created symlink /etc/systemd/system/multi-user.target.wants/newrelic-infra.service → /etc/systemd/system/newrelic-infra.service.
i
```

```bash
$ systemctl list-unit-files --type=service | grep newrelic
newrelic-infra.service                         enabled
```

`/etc/newrelic-infra.yml` を修正して `enable_process_metrics: true` を追加する。

```bash
$ sudo systemctl restart newrelic-infra.service
```

これでサーバのメトリクスは取得できるようになる。

## On-host integrationの導入
MySQL入れる。

```
$ sudo apt-get install nri-mysql
```

専用ユーザーをMySQLに作っておく
```bash
sudo mysql -e "CREATE USER 'newrelic'@'localhost' IDENTIFIED BY 'newrelic' WITH MAX_USER_CONNECTIONS 5;"
sudo mysql -e "GRANT SELECT ON *.* TO 'newrelic'@'localhost';"
sudo mysql -e "GRANT REPLICATION CLIENT ON *.* TO 'newrelic'@'localhost' WITH MAX_USER_CONNECTIONS 5;"
sudo mysql -e "GRANT SELECT ON *.* TO 'newrelic'@'localhost' WITH MAX_USER_CONNECTIONS 5;"
cd /etc/newrelic-infra/integrations.d
sudo cp mysql-config.yml.sample mysql-config.yml
```
YMLは編集しておく
```
$ cat mysql-config.yml
integration_name: com.newrelic.mysql

instances:
  - name: mysql-server
    command: status
    arguments:
        hostname: localhost
        port: 3306
        username: newrelic
        password: newrelic
        # New users should leave this property as `true`, to identify the
        # monitored entities as `remote`. Setting this property to `false` (the
        # default value) is deprecated and will be removed soon, disallowing
        # entities that are identified as `local`.
        # Please check the documentation to get more information about local
        # versus remote entities:
        # https://github.com/newrelic/infra-integrations-sdk/blob/master/docs/entity-definition.md
        remote_monitoring: true
        extended_innodb_metrics: true
    labels:
        env: production
        role: write-replica
```

再起動する。

```bash
$ sudo systemctl restart newrelic-infra.service
```

infrasturucture → Third-party servicesでMySQLのダッシュボードからメトリクスが見れることを確認する。
https://one.newrelic.com/-/0oqQaBON5w1


## APMエージェントを使う
### 環境変数をどう読んでいるか確認する。
Nerelicのライセンスキーを環境変数に入れておかないといけないので環境変数の読み込み方法を確認しておく。
```bash
$ cat /etc/systemd/system/isuumo.go.service
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

環境変数（`NEW_RELIC_LICENSE_KEY`）にライセンスキーを登録しておく。

```bash
$ cat ~/env.sh
MYSQL_HOST="127.0.0.1"
MYSQL_PORT=3306
MYSQL_USER=isucon
MYSQL_DBNAME=isuumo
MYSQL_PASS=isucon
NEW_RELIC_LICENSE_KEY=***....
```

### コードを変更する

コードを変更する。
```diff
diff --git a/webapp/go/main.go b/webapp/go/main.go
index 519d16f..a79c4cd 100644
--- a/webapp/go/main.go
+++ b/webapp/go/main.go
@@ -21,6 +21,8 @@ import (
        "github.com/labstack/echo"
        "github.com/labstack/echo/middleware"
        "github.com/labstack/gommon/log"
+       nrecho "github.com/newrelic/go-agent/v3/integrations/nrecho-v3"
+       "github.com/newrelic/go-agent/v3/newrelic"
 )

 const Limit = 20
@@ -242,6 +244,16 @@ func init() {
 }

 func main() {
+       app, nrerr := newrelic.NewApplication(
+               newrelic.ConfigAppName("ISUUMO"),
+               newrelic.ConfigFromEnvironment(),
+               newrelic.ConfigDistributedTracerEnabled(true),
+               newrelic.ConfigDebugLogger(os.Stdout),
+       )
+       if nrerr != nil {
+               os.Exit(1)
+       }
+
        runtime.SetBlockProfileRate(1)
        runtime.SetMutexProfileFraction(1)
        go func() {
@@ -250,12 +262,14 @@ func main() {
        // Echo instance
        e := echo.New()
        e.Debug = true
+
        e.Logger.SetLevel(log.DEBUG)

        // Middleware
        e.Use(middleware.Logger())
        e.Use(middleware.Recover())
-
+       // nrecho
+       e.Use(nrecho.Middleware(app))
        // Initialize
        e.POST("/initialize", initialize)
```

```go
nrecho "github.com/newrelic/go-agent/v3/integrations/nrecho-v3"
"github.com/newrelic/go-agent/v3/newrelic"


app, nrerr := newrelic.NewApplication(
              newrelic.ConfigAppName("ISUUMO"),
               newrelic.ConfigFromEnvironment(),
               newrelic.ConfigDistributedTracerEnabled(true),
               newrelic.ConfigDebugLogger(os.Stdout),
       )
       if nrerr != nil {
               os.Exit(1)
       }
```

```go
// nrecho
e.Use(nrecho.Middleware(app))
```

### SQLパーサーを追加する

`file/go/newrelic_query_parser.go` を入れておく。そしてmain.goを変更する  
// 本当はSQL使うところ全部を変更しないといけない。

```diff
diff --git a/webapp/go/main.go b/webapp/go/main.go
index 519d16f..94a7735 100644
--- a/webapp/go/main.go
+++ b/webapp/go/main.go
@@ -322,6 +336,8 @@ func initialize(c echo.Context) error {
 }

 func getChairDetail(c echo.Context) error {
+       txn := nrecho.FromContext(c)
+       defer txn.End()
        id, err := strconv.Atoi(c.Param("id"))
        if err != nil {
                c.Echo().Logger.Errorf("Request parameter \"id\" parse error : %v", err)
@@ -330,7 +346,10 @@ func getChairDetail(c echo.Context) error {

        chair := Chair{}
        query := `SELECT * FROM chair WHERE id = ?`
+       s := createDataStoreSegment(query, id)
+       s.StartTime = txn.StartSegmentNow()
        err = db.Get(&chair, query, id)
+       s.End()
        if err != nil {
                if err == sql.ErrNoRows {
                        c.Echo().Logger.Infof("requested id's chair not found : %v", id)
```

```go
txn := nrecho.FromContext(c)
defer txn.End()

s := createDataStoreSegment(query, id)
s.StartTime = txn.StartSegmentNow()

s.End()
```

### ビルドして起動する

`go mod download` と`go mod tidy`しておく


`make`して再起動。
```
$ make
isucon@********:~/isuumo/webapp/gogo build -o isuumo
go: downloading github.com/newrelic/go-agent/v3 v3.14.1
go: downloading github.com/newrelic/go-agent/v3/integrations/nrecho-v3 v1.0.1
go: downloading google.golang.org/grpc v1.27.0
go: downloading github.com/golang/protobuf v1.3.3
go: downloading google.golang.org/genproto v0.0.0-20190819201941-24fa4b261c55
isucon@********:~/isuumo/webapp/go$ sudo systemctl restart isuumo.go
```

様子がおかしかったら`journalctl -fxu isuumo.go`でログをみる。


```
Aug 01 02:11:20 ******** isuumo[9751]: (9751) 2021/08/01 02:11:20.314206 {"level":"info","msg":"collector message","context":{"msg":"Reporting to: https://rpm.newrelic.com/accounts/xxxxxxxx/applications/xxxxx"}}
```

みたいなログが出ていればダイジョブなはず。

起動できたらNewRelic OneでAPMのページをみてみる。


## logを取り込む方法
一番雑な取り込み方法は`journald`経由。rootモードじゃないと取り込めないが、デフォルトはルートモードのはず。

YMLをコピーして編集する。**logging.yml**という名前でコピーすること。
https://docs.newrelic.com/jp/docs/logs/enable-log-management-new-relic/enable-log-monitoring-new-relic/forward-your-logs-using-infrastructure-agent/#enable

```bash
$ sudo cp /etc/newrelic-infra/logging.d/systemd.yml.example /etc/newrelic-infra/logging.d/logging.yml
$ cat /etc/newrelic-infra/logging.d/logging.yml
###############################################################################
# Log forwarder configuration file example                                    #
# Source: systemd                                                             #
# Available customization parameters: attributes, max_line_kb, pattern        #
###############################################################################
logs:
  - name: isuumo
    systemd: isuumo.go

```

サービスを再起動する。
```bash
sudo systemctl restart newrelic-infra.service
```

ただし`systemctl status newrelic-infra`をみてfluent-bitがうまく起動していなかったら諦めたほうがよい。


### logs in context対応
```go

// c.Echo().Logger をlogger.... に一括置換する。
c.Echo().Logger
logger.WithContext(c.Request().Context())
```

## パージ方法
```bash
$ sudo systemctl stop newrelic-infra.service
$ sudo systemctl disable newrelic-infra.service
```

アプリのコードは地道に削除するしかない…