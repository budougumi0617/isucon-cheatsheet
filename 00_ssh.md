# 接続設定
pemファイルがなくても接続できるようにする。


## GitHubに公開されている公開鍵を登録する
isuconユーザーでログインして以下のコマンドを実行する。
```bash
curl https://github.com/{budougumi0617,applepine1125}.keys >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

## リモートインスタンスのsshの設定を変更する
`sudo vim  /etc/ssh/sshd_config` してこの辺の設定を有効化する。
```yaml
PubkeyAuthentication yes
# Expect .ssh/authorized_keys2 to be disregarded by default in future.
AuthorizedKeysFile      .ssh/authorized_keys .ssh/authorized_keys2
```

`Ubuntu 18.04.5 LTS`には`RSAAuthentication` の設定はなかった。

sshをリスタートする。
```bash
sudo /etc/init.d/ssh restart
[ ok ] Restarting ssh (via systemctl): ssh.service.
```

## ローカルPCにssh設定を書いて接続を試してみる。

ローカルPCの`~/.ssh/config`ファイルに接続情報を書いておく。

```
# ISUCON練習用
Host isu10A
  HostName 333.333.333.333 # EC2コンソールで確認したpublic ip
  IdentityFile ~/.ssh/id_ed25519
  User isucon
```

これでpemファイルがなくてもsshできるようになる。

```bash
ssh isu10A
Enter passphrase for key '/Users/budougumi0617/.ssh/id_ed25519':
Welcome to Ubuntu 18.04.5 LTS (GNU/Linux 5.4.0-1054-aws x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

  System information as of Sat Jul 31 07:20:10 UTC 2021

  System load:  0.0                Processes:           113
  Usage of /:   13.7% of 48.41GB   Users logged in:     1
  Memory usage: 32%                IP address for eth0: 172.31.30.186
  Swap usage:   0%

 * Super-optimized for small spaces - read how we shrank the memory
   footprint of MicroK8s to make it the smallest full K8s around.

   https://ubuntu.com/blog/microk8s-memory-optimisation

26 packages can be updated.
1 of these updates is a security update.
To see these additional updates run: apt list --upgradable

New release '20.04.2 LTS' available.
Run 'do-release-upgrade' to upgrade to it.



The programs included with the Ubuntu system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Ubuntu comes with ABSOLUTELY NO WARRANTY, to the extent permitted by
applicable law.
isucon@ip-333-333-333-333:~$
```


## 参考
- https://tkmr.hatenablog.com/entry/2017/10/25/201426
- http://tatamo.81.la/blog/2018/09/16/isucon8-qual-2/
- https://support.kagoya.jp/flex/manual/ssh_rsa/rsa_pub.html