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
mkdir ~/.ssh
touch  ~/.ssh/authorized_keys
curl https://github.com/{budougumi0617,glassmonkey,yopidax}.keys >> ~/.ssh/authorized_keys
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
echo "*.pdf" >> .gitignore
echo ".bundle/" >> .gitignore
git add .
git commit -m "initial commit"
cp -r ~/isucon-cheatsheet/script ./
git add .
git commit -m "add scripts"
git branch -M main
git remote add origin git@github.com:budougumi0617/isucon12q.git
git push origin main
```

ここで1つissueを作っておくこと！！！

#### 情報確認！
セットアップとGitHub上の更新が終わったら、再起動中にシステムの情報を確認するためにローカルから転送コマンドを実行しておく。

```bash
# ローカルPCのrepoから実行すること
./gh_push_memo.sh 1 "`ssh isu11f_1 sudo cat /var/log/isucon/info.txt`"
```

**終わったらここで一度再起動してAppArmorを無効化しておく。**

### 各middlewareの設定ファイルの更新
#### git配下に入れて修正する。
もろもろの設定ファイルをgit管理化に入れる。apparmorが死んでいればシンボリックリンクを使って設定ファイルを用意できる。  
`git init`したディレクトリに移動して以下を実行する。


```bash
sudo systemctl disable apparmor
```

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

`/etc/mysql/mysql.conf.d/` らへんの `[mysqld]` の設定が最終的な設定になっている気がするので設定を変更するときはそちらを更新する。
こちらに書いていない設定は消えている気がする。


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

コメントアウトは `#` で。

終わったら再起動
```
sudo systemctl restart nginx
sudo systemctl status nginx
```


#### MySQLの設定変更・情報取得
my.cnfを変更しておく。

https://gist.github.com/yoku0825/ea57b64d26dc645358f2de87f6ef8518

**TODO: ここでもうbinlogとかの設定変更もしておく？？？？**

```
[mysqld]
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow.log
long_query_time = 0.1
bind-address = 0.0.0.0
```
念の為ファイル作成と手元でクエリ解析できるように権限変えておく

```bash
# tool_setup.shでやってあるので不要。
sudo touch /var/log/mysql/slow.log
sudo chmod -R 777 /var/log/mysql
```

ユーザーもリモートアクセスできるようにしておく。

```bash
sudo mysql -h 127.0.0.1 -uisucon -pisucon -e "grant all privileges on *.* to isucon@"%" identified by 'isucon' with grant option;"
```

MySQL8系の場合は↓かも
```bash
sudo mysql -h 127.0.0.1 -uisucon -pisucon -e "CREATE USER myuser@'%' IDENTIFIED BY 'password';"
sudo mysql -h 127.0.0.1 -uisucon -pisucon -e "grant all privileges on *.* to isucon@\"%\" with grant option;"
```

終わったら再起動する。
```
systemctl list-unit-files --type=service | grep sql
mysql.service                                  enabled

sudo systemctl restart mysql
sudo systemctl restart isuumo.go
```

設定が変わっているか確認する。
```bash
mysql -uisucon -pisucon -e "show variables like 'slow_query%';"
```

ダンプしてローカルでも見れるようにするのと、データ量を見ておく。
```bash
# DBの名前を確認する
mysql -uisucon -pisucon -e "show databases;"
mysqldump --single-transaction -u isucon -pisucon DB_NAME > /tmp/isucon_dump.sql
mysql -uisucon -pisucon isuumo -e "SELECT table_name, engine, table_rows, avg_row_length, floor((data_length+index_length)/1024/1024) as allMB, floor((data_length)/1024/1024) as dMB, floor((index_length)/1024/1024) as iMB FROM information_schema.tables WHERE table_schema=database() ORDER BY (data_length+index_length) DESC;" > /tmp/isucon/mysql_data_size.txt
```

リモートアクセスできるようになったらローカルPCのgit repoで以下のコマンドを使ってテーブル情報を作っておく。
さっきのデータ量もローカルPCからissueにコメントしておく
```bash
tbls doc my://isucon:isucon@${REMOTE_HOST}:3306/isuumo ./doc/schema
./gh_push_memo.sh 1 "`ssh isu11A cat /tmp/isucon/mysql_data_size.txt`"
```

#### netdataの設定変更しておく
まず、19999ポートにアクセスしてnetdataが起動していることを確認する。

`/etc/netdata/apps_groups.conf` を編集してアプリのメトリクスだけを見れるようにしておく。

```
# こんな感じの設定を書いておく。
issumo: *isuumo*
```

https://app.netdata.cloud/ を開いてadd nodesしておく。  
終わったら再起動。
```bash
sudo systemctl restart netdata
```

### アプリケーションを確認してやること
### Makefile書く
ベンチマーク実行時の流れなどをMakefileに書いておくこと
```
all: isuumo

isuumo: *.go
        GOOS=linux GOARCH=amd64 go build -o isuumo

bench:
        sudo truncate --size 0 /var/log/mysql/slow.log
        sudo truncate --size 0 /var/log/nginx/access.log
        sudo systemctl restart nginx.service
        sudo systemctl restart isuumo.go
        cd ~/isuumo/bench; ./bench --target-url http://localhost:80

alp:
        alp -c alp.yaml ltsv
```
