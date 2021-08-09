#!/bin/bash -eu

# うまくいかないときはAppArmorを無効にしているか確認すること

# ref: https://github.com/KasuyaMofu/hidennotare/blob/1ccca56ab52c0c1cf176a4cf1f46d6e8021881ae/02-middleware.md
# 設定ファイルをシンボリックリンクで見るようにしてgit repoで管理するためのスクリプト
# まとめて確認
# cat move_list.txt | xargs -L 1 ls -l
# まとめて追加
# cat move_list.txt | xargs -L 1 ./mover.sh

PWDDIR=`pwd`
function replace-file () {
  if [ ! -e $1 ]; then
     echo "$1 not exist"; return 1;
  fi
  if [ -L $1 ]; then
    echo "$1 is symbolic"; return 1;
  fi

  FILENAME=`basename $1`
  echo "--before"
  ls -l $1
  sudo mv $1 ${PWDDIR}/${FILENAME}
  sudo ln -s ${PWDDIR}/${FILENAME} $1
  echo "--after"
  ls -l $1
}

replace-file $1