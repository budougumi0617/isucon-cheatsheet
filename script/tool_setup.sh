#!/bin/bash -eu

## 鍵情報の設定
curl https://github.com/{budougumi0617,applepine1125}.keys >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

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
