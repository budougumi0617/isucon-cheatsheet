#!/bin/bash -eu

## AppArmorが有効だとシンボリックリンクを/etc配下にはれない。
sudo systemctl stop apparmor
sudo systemctl disable apparmor

# いろいろな情報を出力しておく
# ./gh_push_memo.sh 1 "`ssh isu10A sudo cat /var/log/isucon/info.txt`"
sudo mkdir /var/log/isucon
sudo mkdir /tmp/isucon
echo "----- OS info ----- " | sudo tee /var/log/isucon/info.txt
cat /etc/os-release | sudo tee -a /var/log/isucon/info.txt
echo -e "\n\n----- CPU info ----- " | sudo tee -a /var/log/isucon/info.txt
cat /proc/cpuinfo | sudo tee -a /var/log/isucon/info.txt
echo -e "\n\n----- Disk info ----- " | sudo tee -a /var/log/isucon/info.txt
sudo df -Th | sudo tee -a /var/log/isucon/info.txt
echo -e "\n\n----- Network info ----- " | sudo tee -a /var/log/isucon/info.txt
sudo ip a | sudo tee -a /var/log/isucon/info.txt
echo -e "\n\n----- Process info ----- " | sudo tee -a /var/log/isucon/info.txt
sudo ps auxf | sudo tee -a /var/log/isucon/info.txt
echo -e "\n\n----- Active Service info ----- " | sudo tee -a /var/log/isucon/info.txt
sudo systemctl list-unit-files --type=service | grep service | sudo tee -a /var/log/isucon/info.txt

## 鍵情報の設定
# これはセットアップ手順の中でやっているはず。
# curl https://github.com/{budougumi0617,applepine1125}.keys >> ~/.ssh/authorized_keys
# chmod 600 ~/.ssh/authorized_keys

## 色々設定
cat <<EOF >> ~/.gitconfig
[user]
  name = budougumi0617
  email = budougumi0617@gmail.com
[color]
  ui = auto
[alias]
  br = branch
  co = checkout
  sw = switch
  rs = restore
  ci = commit
  st = status
  df = diff
[core]
    editor = vim
EOF

cat <<EOF >> ~/.bashrc
# git aliases
alias g='git'
alias gl='git pull'
alias gp='git push'
alias gaa='git add --all'
alias gst='git status'
alias gca='git commit -v -a'
alias gd='git diff'

# share commands
function share_history {
    history -a
    history -c
    history -r
}
PROMPT_COMMAND='share_history'
shopt -u histappend
export HISTSIZE=9999
EOF

cat <<EOF >> ~/.vimrc
set number
inoremap <silent> jj <ESC>
EOF


## alpのセットアップ
wget https://github.com/tkuchiki/alp/releases/download/v1.0.7/alp_linux_amd64.zip
unzip alp_linux_amd64.zip
sudo install ./alp /usr/local/bin/alp
rm alp_linux_amd64.zip
rm alp

## netdataのインストール
bash <(curl -Ss https://my-netdata.io/kickstart.sh)

## slow query用
sudo apt-get install percona-toolkit


# after install newrelic
#  echo "enable_process_metrics: true" | sudo tee -a /etc/newrelic-infra.yml
echo "install newrelic from below link"
echo "https://docs.newrelic.com/docs/infrastructure/install-infrastructure-agent/linux-installation/install-infrastructure-monitoring-agent-linux/"

# AppArmorを修正した場合は再起動が必要
echo "need reboot!: sudo shutdown -r now"

# MySQL向けの下準備
```
sudo touch /var/log/mysql/slow.log
sudo chmod -R 777 /var/log/mysql
```

# access.logなどがscpしやすいように
```
sudo chmod -R 777 /var/log/nginx/
```