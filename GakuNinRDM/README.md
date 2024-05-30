# CS-ood-rdmfs

OpenOnDemand（以下、OOD）のホストに学認RDMのストレージをmountするパッセンジャーアプリです。

## 事前条件

- OOD2.0+
- Python3.8+
- [CS-rdmfs](https://github.com/RCOSDP/CS-rdmfs)
- CS-rdmfs/bin/start.shが/usr/local/sbin/rdmfs_mount.shにコピーされていること

例えば、Rocky8系であれば、

```
sudo dnf module -y install python38
```

でPython3.8環境を整えた上で

```
sudo yum install -y fuse3 git attr
git clone --depth 1 https://github.com/RCOSDP/CS-rdmfs.git
sudo pip3 install --no-cache-dir -r CS-rdmfs/requirements.txt
sudo pip3 install CS-rdmfs/
sudo cp CS-rdmfs/bin/start.sh /usr/local/sbin/rdmfs_mount.sh
```

と導入できる。

## インストール

```
cd /var/www/ood/apps/sys
git clone --depth 1 https://github.com/RCOSDP/CS-ood-rdmfs
chmod 777 /var/www/ood/apps/sys/CS-ood-rdmfs /var/www/ood/apps/sys/CS-ood-rdmfs/tmp
```

参考：[Publish App](https://osc.github.io/ood-documentation/latest/app-development/tutorials-passenger-apps/ps-to-quota.html#publish-app)

