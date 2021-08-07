#!/bin/bash -eu

# ref: https://github.com/KasuyaMofu/hidennotare/blob/1ccca56ab52c0c1cf176a4cf1f46d6e8021881ae/02-middleware.md
# 設定ファイルをシンボリックリンクで見るようにしてgit repoで管理していたのを戻すくん

if [ ! -e $1 ]; then
   echo "$1 not exist"; return 1;
fi

if [ ! -L $1 ]; then
  "$1 is not symbolic"
fi

MVFROM=`readlink $1`
echo "--before"
ls -l $1
sudo unlink $1
sudo mv ${MVFROM} $1
echo "--after"
ls -l $1