package main

import (
	"os"

	"github.com/labstack/echo"
	"github.com/labstack/gommon/log"
	"github.com/newrelic/go-agent/v3/integrations/logcontext/nrlogrusplugin"
	nrecho "github.com/newrelic/go-agent/v3/integrations/nrecho-v3"
	"github.com/newrelic/go-agent/v3/newrelic"
	echologrus "github.com/plutov/echo-logrus"
	"github.com/sirupsen/logrus"
)

var logger = logrus.New()

func main() {
	app, nrerr := newrelic.NewApplication(
		newrelic.ConfigAppName("ISUUMO"),
		newrelic.ConfigFromEnvironment(),
		newrelic.ConfigDistributedTracerEnabled(true),
		newrelic.ConfigDebugLogger(os.Stdout),
	)
	if nrerr != nil {
		os.Exit(1)
	}
	//logrusにLogs in Context用のフォーマッターを設定
	logger.SetFormatter(nrlogrusplugin.ContextFormatter{})

	// echoだった場合
	// Echo instance
	e := echo.New()
	e.Debug = true
	e.Logger.SetLevel(log.DEBUG)

	e.Use(nrecho.Middleware(app))
	logger.SetLevel(logrus.DebugLevel)
	echologrus.Logger = logger
	e.Logger = echologrus.GetEchoLogger()
	e.Use(echologrus.Hook())
}

func hoge(c echo.Context) {
	// 関数の冒頭
	txn := nrecho.FromContext(c)
	defer txn.End()

	//　ログの保存
	logger.WithContext(c.Request().Context()).Errorf("Request parameter \"id\" parse error : %v")

	// クエリの保存
	query := `SELECT * FROM chair WHERE id = ?`
	s := createDataStoreSegment(query, id)
	s.StartTime = txn.StartSegmentNow()
	// 何らかのDB操作
	s.End()
}
