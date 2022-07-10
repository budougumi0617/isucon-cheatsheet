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
+       "github.com/felixge/fgprof"
        _ "github.com/go-sql-driver/mysql"
        "github.com/jmoiron/sqlx"
        "github.com/labstack/echo"
@@ -239,6 +242,11 @@ func init() {
 }

 func main() {
+       http.DefaultServeMux.Handle("/debug/fgprof", fgprof.Handler())
+       go func() {
+              log.Println(http.ListenAndServe(":6060", nil))
+       }()

        // Echo instance
        e := echo.New()
        e.Debug = true

```

`make`して再ビルド、再起動しておく。
```
$ pwd
/home/isucon/isuumo/webapp/go
$ make
$ sudo systemctl restart isuumo.go
$ sudo apt install graphviz
```

EC2のセキュリティグループで6060ポートを開放しておく。ベンチ回しつつ以下のコマンドで計測を開始する。  
実行ディレクトリはバイナリがあるディレクトリ。`isuumo`はバイナリファイル名。

ベンチマーク実行中に次のようにローカルマシンからアクセスすれば開ける。
```
$ go tool pprof --http=:6060 http://${リモートサーバのIP}:6060/debug/fgprof?seconds=10
```

これでリモートからも結果を確認できる。

再度結果を見たい場合はファイルを使う。ローカルマシンから次のように実行する。
```bash
curl -so pprof.trace http://${リモートサーバのIP}:6060/debug/fgprof?seconds=10
go tool pprof --http=:6061 pprof.trace
```

## 参考
- https://qiita.com/shiimaxx/items/edb56b3e928d2438e769
- https://www.mobtown.jp/article/fgprof/