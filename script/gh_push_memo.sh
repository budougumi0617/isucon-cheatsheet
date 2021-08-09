#!/bin/bash -eu

# ./gh_push_memo.sh 1 "`ssh isu10A cat /home/isucon/slow_dgst_20210731_151419.log`"
# って感じで使うと第一引数の番号のissueに第二引数の結果をコメントしてくれる。実行はgit repo内でやる（-Rで指定してもいいが…）
BODY="
\`\`\`
$2
\`\`\`
"
gh issue comment $1 -b "$BODY"
