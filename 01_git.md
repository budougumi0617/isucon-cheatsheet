# GitHubにコードをコミットする

## deploy keyを使う準備をする
`~/.ssh/config` を編集しておく
```
Host github.com
  HostName github.com
  IdentityFile ~/.ssh/id_ed25519
  User git
```
終わったらキーを使う設定をしておく。
```bash
ssh-keygen -t ed25519 -C "budougumi0617@gmail.com"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
chmod 600 ~/.ssh/config
```
```
ssh -T git@github.com
Hi budougumi0617/isucon10-training! You've successfully authenticated, but GitHub does not provide shell access.
```

## aliasとかはる
そのままgit使うとだるいのでgitconfig設定しておく

```bash
vim ~/.gitconfig
```
```
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
  graph = log --graph --date-order -C -M --pretty=format:\"<%h> %ad [%an] %Cgreen%d%Creset %s\" --all --date=short
  list = log --pretty=format:\"<%h> %ad [%an] %Cgreen%d%Creset %s\" --date=short
  df = diff
  review = "!f(){ git fetch -f upstream pull/$1/head:review;};f"
  stl = !git stash list | fzf --preview 'echo {} | grep -o stash@{.*} | xargs git stash show -p --color=always' --height 90% | grep -o stash@{.*}
[core]
    editor = vim
```

## git initしてコミットする
### deploy keyを設定する
公開鍵情報を確認して、リポジトリのdeploy keyに設定する。

https://github.com/budougumi0617/xxxxx/settings/keys

```
cat ~/.ssh/id_ed25519.pub
```
https://qiita.com/tamorieeeen/items/c24f8285448b607b12dd
`Allow write access` にチェックを入れるのをわすれないこと。

### コミットしてpushする

```bash
git init
git add .
# ゴミが入った場合やり直す
git rm --cached -r .
git branch -M master
git remote add origin git@github.com:budougumi0617/xxxxx.git
git push origin master
```

## その他
毎回gitって打つのダルいのでエイリアス貼っておく。
```bash
echo "alias g='git'" >> ~/.bashrc_bk && source ~/.bashrc
```
