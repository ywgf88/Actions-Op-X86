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

echo "==> 默认网络与主题由 files/etc/uci-defaults/99-x86-defaults 在首次开机时生效"
