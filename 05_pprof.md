# pprofを使って解析する。

## 準備
コードを修正する
```diff
diff --git a/webapp/go/main.go b/webapp/go/main.go
index 2aedc7f..42fd86a 100644
--- a/webapp/go/main.go
+++ b/webapp/go/main.go
@@ -10,9 +10,12 @@ import (
        "os"
        "os/exec"
        "path/filepath"
+       "runtime"
        "strconv"
        "strings"

+       _ "net/http/pprof"
+
        _ "github.com/go-sql-driver/mysql"
        "github.com/jmoiron/sqlx"
        "github.com/labstack/echo"
@@ -239,6 +242,11 @@ func init() {
 }

 func main() {
+       runtime.SetBlockProfileRate(1)
+       runtime.SetMutexProfileFraction(1)
+       go func() {
+               log.Println(http.ListenAndServe("0.0.0.0:6060", nil))
+       }()
        // Echo instance
        e := echo.New()
        e.Debug = true

```

`make`して再ビルド、再起動しておく。graphvizをインストールしておく。
```
$ pwd
/home/isucon/isuumo/webapp/go
$ make
$ sudo systemctl restart isuumo.go
$ sudo apt install graphviz
```

EC2のセキュリティグループで1080ポートを開放しておく。ベンチ回しつつ以下のコマンドで計測を開始する。  
実行ディレクトリはバイナリがあるディレクトリ。`isuumo`はバイナリファイル名。

```
$ go tool pprof -seconds 90 -http="0.0.0.0:1080" isuumo http://localhost:6060/debug/pprof/profile
Fetching profile over HTTP from http://localhost:6060/debug/pprof/profile?seconds=90
Please wait... (1m30s)
Saved profile in /home/isucon/pprof/pprof.isuumo.samples.cpu.001.pb.gz
Serving web UI on http://0.0.0.0:1080
Couldn't find a suitable web browser!
Set the BROWSER environment variable to your desired browser.
```

これでリモートからも結果を確認できる。

再度結果を見たい場合はファイルを使う
```bash
$ go tool pprof -seconds 90 -http="0.0.0.0:1080" isuumo /home/isucon/pprof/pprof.isuumo.samples.cpu.001.pb.gz
```

## 参考
- https://blog.zoe.tools/entry/2020/07/26/181836