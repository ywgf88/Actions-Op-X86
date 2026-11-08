#!/bin/bash
# diy-part2.sh —— 在 .config 放入 openwrt 之后、make defconfig 之前执行
# 作用：校验必需的第三方包目录是否齐全（缺失时尽早报错，而不是编译到一半才失败）
set -e

echo "==> 检查第三方插件目录"

check_dir() {
	if [ ! -d "package/$1" ]; then
		echo "❌ 缺少 package/$1，请检查 diy-part1.sh 是否执行成功"
		exit 1
	fi
	echo "   ✓ $1"
}

check_dir luci-app-passwall2
check_dir passwall-packages/geoview
check_dir passwall-packages/tcping
check_dir passwall-packages/chinadns-ng
check_dir clashoo
check_dir luci-app-clashoo
check_dir quickfile
check_dir luci-app-quickfile
check_dir luci-app-diskman
check_dir luci-app-run
check_dir luci-app-partexp
check_dir luci-theme-argon
check_dir luci-theme-vantage
check_dir luci-app-vantage
check_dir luci-theme-aurora
check_dir luci-app-aurora-config

echo "==> 目标板 / 版本："
grep -E '^CONFIG_TARGET_(x86|BOARD|SUBTARGET|PROFILE|DEVICE)|^CONFIG_VERSION_NUMBER' .config || true

echo "==> 检查 rootfs 分区大小（默认 104MB 装不下本配置的约 520MB 包，会卡在 root.ext4）"
rootfs_partsize=$(grep -oP '^CONFIG_TARGET_ROOTFS_PARTSIZE=\K[0-9]+' .config || echo 0)
if [ "${rootfs_partsize:-0}" -lt 512 ]; then
	echo "❌ CONFIG_TARGET_ROOTFS_PARTSIZE=${rootfs_partsize}MB 太小，打包镜像必然 out of space，请改为 1024"
	exit 1
fi
echo "   ✓ rootfs 分区 ${rootfs_partsize}MB"

echo "==> 默认网络与主题由 files/etc/uci-defaults/99-x86-defaults 在首次开机时生效"
