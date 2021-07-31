# monitoring

## netadata
### install
https://learn.netdata.cloud/docs/get-started#install-on-linux-with-one-line-installer-recommended

```bash
bash <(curl -Ss https://my-netdata.io/kickstart.sh)
sudo cp ./file/netdata/netdata.conf /etc/netdata/netdata.conf
sudo cp ./file/netdata/apps_groups.conf /etc/netdata/apps_groups.conf
sudo systemctl restart netdata
```

install途中に各設定ファイルなどの場所がでてくるのでメモしておく。

```bash
  It will be installed at these locations:

   - the daemon     at /usr/sbin/netdata
   - config files   in /etc/netdata
   - web files      in /usr/share/netdata
   - plugins        in /usr/libexec/netdata
   - cache files    in /var/cache/netdata
   - db files       in /var/lib/netdata
   - log files      in /var/log/netdata
   - pid file       at /var/run/netdata.pid
   - logrotate file at /etc/logrotate.d/netdata
```

インストールが終わったら19999ポートにアクセスしてnetdataが起動していることを確認する。

> To start using Netdata, open a browser and navigate to http://NODE:19999, replacing NODE with either localhost or the hostname/IP address of a remote node.


*AWS的にセキュリティグループをちゃんと設定している場合は19999ポートを開放しておくこと。*

### 設定を変更する

インストールが完了したらGo用の設定にして再起動
https://learn.netdata.cloud/docs/configure/nodes#netdatas-configuration-files

```bash
$ sudo rm /etc/netdata/netdata.conf
$ sudo ln -s ~/isuumo/etc/netdata/netdata.conf /etc/netdata/netdata.conf
$ sudo ln -s ~/isuumo/etc/netdata/apps_groups.conf /etc/netdata/apps_groups.conf
$ sudo systemctl restart netdata
```

### cloudへの接続方法

netdata.cloudを使うとwarroomが作れる。ADD nodesをする接続用のコマンドが出てくる。

```bash
sudo netdata-claim.sh -token=L.... -rooms=ccb25.... -url=https://app.netdata.cloud
Token: ****************
Base URL: https://app.netdata.cloud
Id: 0eb...
Rooms: 7fb....
Hostname: ip-1...
Proxy:
Netdata user: netdata
Generating private/public key for the first time.
Generating RSA private key, 2048 bit long modulus (2 primes)
.............+++++
.......................................................................................................+++++
e is 65537 (0x010001)
Extracting public key from private key.
writing RSA key
Connection attempt 1 successful
Node was successfully claimed.
```

### 見方
この状態でベンチマークを実行してみる。isucon10の場合は↓

```bash
$ pwd
/home/isucon/isuumo/bench
$ ./bench --target-url http://localhost:80
```

この状態で「Applications」を見るとどの層で負荷が高いかわかる。



### 停止方法
```
sudo systemctl stop netdata
sudo systemctl disable netdata
```

### 参考
- https://github.com/catatsuy/memo_isucon#netdata
- https://github.com/south37/isucon-settings/blob/master/setup_netdata.sh
- https://github.com/south37/isucon-settings/tree/master/netdata