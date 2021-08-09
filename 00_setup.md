# 最初にいろいろ構築する
## 事前準備
- private repoを作っておくこと。
- メモ用のissueを1つ作っておくこと
    - 何もコミットしていない状態だとissueつくれないかもしれない。
- ローカルにcloneしておくこと
    - info.txtとかをpushできるように


## サーバにログインしたらやること
### ssh の設定
#### 鍵の登録
`isucon`ユーザーになっているか確認する。まずログイン用に鍵の登録をする。

```bash
curl https://github.com/{budougumi0617,applepine1125}.keys >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

#### sshの設定を更新する　
`sudo vim /etc/ssh/sshd_config`してこの辺の設定を有効化する。
```
PubkeyAuthentication yes
# Expect .ssh/authorized_keys2 to be disregarded by default in future.
AuthorizedKeysFile      .ssh/authorized_keys .ssh/authorized_keys2
```

終わったら`ssh`をリスタートする。
```
sudo /etc/init.d/ssh restart
```
#### ローカルから接続確認
ローカルPCにssh設定を書いて接続を試してみる。

```
# ISUCON練習用
Host isu11A
  HostName 127.0.0.1 # EC2コンソールのpublic ip
  IdentityFile ~/.ssh/id_ed25519_nopw
  User isucon
```

### gitの設定
#### 鍵を作る
**iscuonユーザ（作業用ユーザ）でログインしていることを確認すること**
```
echo -e "Host github.com
  HostName github.com
  IdentityFile ~/.ssh/id_ed25519
  User git
" >> ~/.ssh/config
chmod 600 ~/.ssh/config
```

GitHubに登録する鍵をつくる。
```bash
ssh-keygen -t ed25519 -C "budougumi0617@gmail.com"
```
```bash
chmod 600  ~/.ssh/id_ed25519.pub
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
cat ~/.ssh/id_ed25519.pub
```

`cat`した結果をrepoのdeploy keyに設定しておく。

https://github.com/budougumi0617/xxxxx/settings/keys

**Allow write accessのチェックを有効にして登録することを忘れないこと！**

動作確認してみる。
```
ssh -T git@github.com
```

### セットアップスクリプトを実行する
全部一気にやってくれるくんを動かす
```
cd ~/
git clone git@github.com:budougumi0617/isucon-cheatsheet.git
cd ~/isucon-cheatsheet/script/
./tool_setup.sh
```


セットアップスクリプトは何回かYESを選択する必要があるので他の作業をしつつ進捗を見守ること。

### コードをpushしておく！
再起動前にいろいろ見れるようにコードが入っているディレクトリをpushしておく。
```
git init
echo "*.png" >> .gitignore
echo "*.jpg" >> .gitignore
echo "*.jpeg" >> .gitignore
git add .
git commit -m "initial commit"
cp -r ~/isucon-cheatsheet/script ./
git add .
git commit -m "add scripts"
git branch -M master
git remote add origin git@github.com:budougumi0617/xxxxx.git
git push origin master
```

ここで1つissueを作っておくこと！！！

#### 情報確認！
セットアップとGitHub上の更新が終わったら、再起動中にシステムの情報を確認するためにローカルから転送コマンドを実行しておく。

```bash
# ローカルPCのrepoから実行すること
./gh_push_memo.sh 1 "`ssh isu11A sudo cat /var/log/isucon/info.txt`"
```

**終わったらここで一度再起動してAppArmorを無効化しておく。**

### NewRelicのインストール
#### インストールスクリプト実行からプラグインの設定など
https://docs.newrelic.com/docs/infrastructure/install-infrastructure-agent/linux-installation/install-infrastructure-monitoring-agent-linux/

再度ログインしたら↑のリンクからNewrelic infraのインストールスクリプトを作ってインストールする。

```bash
echo "enable_process_metrics: true" | sudo tee -a /etc/newrelic-infra.yml
sudo apt-get install nri-mysql
```

#### MySQLをモニタリング
MySQL用のプラグインを導入する。

```bash
sudo mysql -e "CREATE USER 'newrelic'@'localhost' IDENTIFIED BY 'newrelic' WITH MAX_USER_CONNECTIONS 5;"
sudo mysql -e "GRANT SELECT ON *.* TO 'newrelic'@'localhost';"
sudo mysql -e "GRANT REPLICATION CLIENT ON *.* TO 'newrelic'@'localhost' WITH MAX_USER_CONNECTIONS 5;"
sudo mysql -e "GRANT SELECT ON *.* TO 'newrelic'@'localhost' WITH MAX_USER_CONNECTIONS 5;"
sudo cp /etc/newrelic-infra/integrations.d/mysql-config.yml.sample /etc/newrelic-infra/integrations.d/mysql-config.yml
```

YAMLは編集しておく。
```yaml
instances:
  - name: mysql-server
    command: status
    arguments:
        hostname: localhost
        port: 3306
        username: newrelic
        password: newrelic # ここ！！！！！！！！！！！
```


#### ログをフォワードする
```bash
sudo cp /etc/newrelic-infra/logging.d/systemd.yml.example /etc/newrelic-infra/logging.d/logging.yml
```

こんな感じでログを取り込みたいサービスを確認する（OS再起動中に確認しておいてもいいかも）。
```
systemctl list-unit-files --type=service | grep isu
```

確認したら、こんな感じで設定ファイルを更新する。

```yaml
sudo vim /etc/newrelic-infra/logging.d/logging.yml
cat /etc/newrelic-infra/logging.d/logging.yml
logs:
  - name: isuumo
    systemd: isuumo.go
```

#### 環境変数を設定しておく
APM用にNerelicのライセンスキーを環境変数にしておく。こんな感じで`EnvironmentFile`を調べて登録する。
```
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

ローカルからメモをしておいてもよいかも
```bash
# ./gh_push_memo.sh 1 "`ssh isu10A sudo cat /etc/systemd/system/isuumo.go.service`"
./gh_push_memo.sh 1 "`ssh isu11A sudo cat /etc/systemd/system/xx`"
```

```bash
cat ~/env_file
echo "NEW_RELIC_LICENSE_KEY=??" >> ~/env_file
```

APMエージェントの導入は別でやるとして、一度再起動する。

```bash
sudo systemctl restart newrelic-infra.service
```
NewRelic Oneを見てもろもろのメトリクスが取得できているか確認する。

### 各middlewareの設定ファイルの更新
#### git配下に入れて修正する。
もろもろの設定ファイルをgit管理化に入れる。apparmorが死んでいればシンボリックリンクを使って設定ファイルを用意できる。  
`git init`したディレクトリに移動して以下を実行する。

```bash
mkdir etc
cd etc
cat ~/isucon-cheatsheet/script/move_list.txt | xargs -L 1 ls -l
cat ~/isucon-cheatsheet/script/move_list.txt | xargs -L 1 ~/isucon-cheatsheet/script/mover.sh
cat ~/isucon-cheatsheet/script/move_list.txt | xargs -L 1 ls -l
```

MySQLらへんの設定はそもそもファイルがない、最初からシンボリックリンクになっていることがあるので、スクリプトがうまく動かなかったら`/etc/mysql/`を覗いてみる。

場合によってはmy.cnfはこんな感じにしておく
```
#
# The MySQL database server configuration file.
#
# You can copy this to one of:
# - "/etc/mysql/my.cnf" to set global options,
# - "~/.my.cnf" to set user-specific options.
#
# One can use all long options that the program supports.
# Run program with --help to get a list of available options and with
# --print-defaults to see which it would actually understand and use.
#
# For explanations see
# http://dev.mysql.com/doc/mysql/en/server-system-variables.html

#
# * IMPORTANT: Additional settings that can override those from this file!
#   The files must end with '.cnf', otherwise they'll be ignored.
#

!includedir /etc/mysql/conf.d/
!includedir /etc/mysql/mysql.conf.d/
```


#### alp用のnginxの設定変更

`/etc/nginx/nginx.conf` をこんな感じにログ出力を変更する。
```
    log_format ltsv "time:$time_local"
                "\thost:$remote_addr"
                "\tforwardedfor:$http_x_forwarded_for"
                "\treq:$request"
                "\tstatus:$status"
                "\tmethod:$request_method"
                "\turi:$request_uri"
                "\tsize:$body_bytes_sent"
                "\treferer:$http_referer"
                "\tua:$http_user_agent"
                "\treqtime:$request_time"
                "\tcache:$upstream_http_x_cache"
                "\truntime:$upstream_http_x_runtime"
                "\tapptime:$upstream_response_time"
                "\tvhost:$host";

    access_log  /var/log/nginx/access.log ltsv;
```

終わったら再起動
```
sudo systemctl restart nginx
sudo systemctl status nginx
```


#### MySQLの設定変更・情報取得
my.cnfを変更しておく。

**TODO: ここでもうbinlogとかの設定変更もしておく？？？？**

```
[mysqld]
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow.log
long_query_time = 0
bind-address = 0.0.0.0
```

ユーザーもリモートアクセスできるようにしておく。

```bash
sudo mysql -h 127.0.0.1 -uisucon -pisucon -e "grant all privileges on *.* to isucon@"%" identified by 'isucon' with grant option;"
```

終わったら再起動する。
```
$ systemctl list-unit-files --type=service | grep sql
mysql.service                                  enabled

$ sudo systemctl restart mysql
$ sudo systemctl restart isuumo.go
```

ダンプしてローカルでも見れるようにするのと、データ量を見ておく。
```bash
# DBの名前を確認する
mysql -uisucon -pisucon -e "show databases;"
mysqldump --single-transaction -u isucon -pisucon DB_NAME > /tmp/isucon_dump.sql
mysql -uisucon -pisucon isuumo -e "SELECT table_name, engine, table_rows, avg_row_length, floor((data_length+index_length)/1024/1024) as allMB, floor((data_length)/1024/1024) as dMB, floor((index_length)/1024/1024) as iMB FROM information_schema.tables WHERE table_schema=database() ORDER BY (data_length+index_length) DESC;" > /tmp/isucon/mysql_data_size.txt
```

リモートアクセスできるようになったらローカルPCのgit repoで以下のコマンドを使ってテーブル情報を作っておく。
さっきの
```bash
tbls doc my://isucon:isucon@${REMOTE_HOST}:3306/isuumo ./doc/schema
./gh_push_memo.sh 1 "`ssh isu11A cat /tmp/isucon/mysql_data_size.txt`"
```

