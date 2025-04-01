#!/bin/bash

RED=$'\e[1;31m'    # [Error]
GREEN=$'\e[1;32m'  # [Success]
YELLOW=$'\e[1;33m' # [Warning]
CYAN=$'\e[1;36m'   # [Notice]
NC=$'\e[0m'

if [[ "$EUID" -ne 0 ]]; then
	echo "${RED}[Error]${NC} 请以 root 权限运行此脚本"
	exit 1
fi

apt update
command -v curl &>/dev/null || apt install -y curl

# WORK_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
cd "$HOME" || exit

echo "${CYAN}[Notice]${NC} 正在下载脚本其他部分..."
curl -fsSL --retry 5 --retry-delay 3 "https://github.com/senzyo/vps-init/archive/refs/heads/main.zip" -o vps-init.zip || {
	echo "${RED}[Error]${NC} 多次尝试后下载依然失败"
	exit 1
}
echo "${GREEN}[Success]${NC} 下载成功"

command -v unzip &>/dev/null || apt install -y unzip
unzip -oq vps-init.zip
rm -f vps-init.zip
cd vps-init-main || exit

conf_file="/etc/bash.bashrc"
if ! grep -q "以下是自定义内容" "$conf_file"; then
	(
		printf "\n"
		cat bash.bashrc
	) | tee -a $conf_file >/dev/null
fi
ls -al /etc/bash.bashrc

command -v vim &>/dev/null || apt install -y vim

cp vimrc /etc/vim/vimrc
ls -al /etc/vim/vimrc

cp sshd_config /etc/ssh/sshd_config
ls -al /etc/ssh/sshd_config

cp nftables.conf /etc/nftables.conf
ls -al /etc/nftables.conf
systemctl enable nftables.service

apt install -y systemd-timesyncd
cat <<EOF | tee /etc/systemd/timesyncd.conf >/dev/null
[Time]
NTP=0.pool.ntp.org 1.pool.ntp.org 2.pool.ntp.org 3.pool.ntp.org
EOF
ls -al /etc/systemd/timesyncd.conf

echo "${GREEN}[Success]${NC} 已覆盖各种配置文件"

timedatectl set-ntp true
echo "${GREEN}[Success]${NC} 已设置时间同步"

enable_bbr() {
	conf_file="/etc/sysctl.d/99-sysctl.conf"
	[[ -f "$conf_file" ]] || touch $conf_file
	if ! grep -q "以下是自定义内容" "$conf_file"; then
		cat <<EOF | tee -a "$conf_file" >/dev/null
# 以下是自定义内容
net.ipv4.tcp_congestion_control = bbr
net.core.default_qdisc = fq
EOF
		sysctl --system
	fi
}

if sysctl net.ipv4.tcp_congestion_control | grep -q "bbr"; then
	echo "${GREEN}[Success]${NC} 当前拥塞控制算法已是 BBR"
else
	tried_modprobe=false
	while true; do
		if sysctl net.ipv4.tcp_available_congestion_control | grep -q "bbr"; then
			echo "${CYAN}[Notice]${NC} BBR 在可用算法列表中, 启用 BBR..."
			enable_bbr
			break
		fi
		echo "${YELLOW}[Warning]${NC} BBR 不在可用算法列表中"

		if lsmod | grep -q "tcp_bbr" || [ "$tried_modprobe" = true ]; then
			echo "${RED}[Error]${NC} BBR 模块已加载或已尝试过加载, 但仍不可用"
			break
		fi

		if modprobe tcp_bbr; then
			echo "${GREEN}[Success]${NC} BBR 模块加载成功, 检查是否可用"
			tried_modprobe=true
			continue
		else
			echo "${RED}[Error]${NC} BBR 模块加载失败"
			break
		fi
	done
fi

command -v gpg &>/dev/null || apt install -y gpg
curl -fsSL 'https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x7074ce75da7cc691c1ae1a7c7e51d1ad956055ca' | gpg --yes --dearmor -o /usr/share/keyrings/trzsz.gpg
echo 'deb [signed-by=/usr/share/keyrings/trzsz.gpg] https://ppa.launchpadcontent.net/trzsz/ppa/ubuntu jammy main' | tee /etc/apt/sources.list.d/trzsz.list
apt update
apt install -y trzsz

command -v column &>/dev/null || apt install -y bsdextrautils

# 之后是 Swap 部分
SWAP_FILE="/swapfile"
SWAPPINESS=10
SYSCTL_CONF="/etc/sysctl.d/99-sysctl.conf"

remove_swap() {
	echo "${CYAN}[Notice]${NC} 正在清理已有的 Swap..."

	ACTIVE_SWAPS=$(swapon --show=NAME --noheadings)
	swapoff -a &>/dev/null
	for s in $ACTIVE_SWAPS; do
		[[ -f "$s" ]] && rm -f "$s"
	done
	sed -i "\|\sswap\s|d" /etc/fstab &>/dev/null

	echo "${GREEN}[Success]${NC} 已清理 Swap"
}

create_swap() {
	REGEX="^[1-9][0-9]*$"
	while true; do
		read -rp "${CYAN}[Notice]${NC} 请输入 Swap 容量 (单位为 MB): " SWAP_SIZE </dev/tty
		SWAP_SIZE=$(echo "$SWAP_SIZE" | tr -d ' ')
		if [[ "$SWAP_SIZE" =~ $REGEX ]]; then
			if [ "$SWAP_SIZE" -gt 8192 ]; then
				echo "${RED}[Error]${NC} 最大 8192 MB, 请重新输入"
			else
				break
			fi
		else
			echo "${RED}[Error]${NC} 格式不合法, 请重新输入"
		fi
	done

	echo "${CYAN}[Notice]${NC} 正在创建 Swap..."
	dd if=/dev/zero of=$SWAP_FILE bs=1M count="$SWAP_SIZE"
	chmod 600 $SWAP_FILE
	mkswap $SWAP_FILE

	if ! grep -q "$SWAP_FILE" /etc/fstab; then
		echo "$SWAP_FILE none swap sw,pri=10 0 0" >>/etc/fstab
		echo "${GREEN}[Success]${NC} Swap 已永久生效"
	fi

	sysctl vm.swappiness=$SWAPPINESS &>/dev/null
	sed -i '/vm.swappiness/d' /etc/sysctl.conf &>/dev/null
	find /etc/sysctl.d/ -name "*.conf" -exec sed -i '/vm.swappiness/d' {} + &>/dev/null
	[[ -f "$SYSCTL_CONF" ]] || touch $SYSCTL_CONF
	echo "vm.swappiness=$SWAPPINESS" >>$SYSCTL_CONF
	echo "${GREEN}[Success]${NC} Swap 积极度永久为 $SWAPPINESS"

	swapon -a
}

if [[ $(cat /proc/swaps | wc -l) -gt 1 ]] ||
	[[ -f "$SWAP_FILE" ]] ||
	grep -q "\sswap\s" /etc/fstab; then
	remove_swap
fi
create_swap

echo '[free -h]----------------------------------------------------------------------------------------------------'
free -h
echo '[cat /proc/swaps]--------------------------------------------------------------------------------------------'
cat /proc/swaps
