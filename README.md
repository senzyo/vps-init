# 自用的VPS快速初始化脚本

- 此脚本仅在 Debian 测试过。
- 需要 root 权限。

## 重装系统

```bash
apt update
apt install -y curl
curl -fsSL https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh -o reinstall.sh
# bash reinstall.sh 系统名称 --ssh-key "你的 SSH 公钥"
bash reinstall.sh debian --ssh-key "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFnzo2Pgfh1Ko7Ssvk+XvDEUJ78d3cLiY9DQ3NG29cWk senzyosama@gmail.com" --ssh-port 40022
reboot
```

## 快速开始

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/senzyo/vps-init/refs/heads/main/initialize.sh)
```

## 验证配置

```bash
cat /etc/vim/vimrc

cat /etc/bash.bashrc

cat /etc/ssh/sshd_config
systemctl status sshd

cat /etc/nftables.conf
systemctl status nftables
nft list ruleset

sysctl net.ipv4.tcp_congestion_control
sysctl net.core.default_qdisc

systemctl status systemd-timesyncd
timedatectl status
timedatectl show-timesync --all
timedatectl timesync-status
```

## 更改主机名

```bash
hostnamectl set-hostname VPS
```

重新登录即可看到主机名已更改。

`sudo` 时可能会报错主机名错误, 对于 Debian, 调整 `/etc/hosts`, 增加一行 `127.0.1.1 VPS`:

```
127.0.0.1       localhost
127.0.1.1       VPS
::1             localhost ip6-localhost ip6-loopback
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters
```