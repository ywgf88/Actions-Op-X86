#!/bin/bash
# diy-part1.sh —— 在 feeds update/install 之前执行
# 作用：把官方源里没有的第三方插件源码放进 package/ 目录
# 说明：openwrt/openwrt 官方源（packages/luci/routing/telephony）已包含
#       docker、luci-app-dockerman、xray-core、sing-box、v2ray-geoip 等，
#       所以 passwall 依赖包里这几个同名包要跳过，避免包名冲突。
set -e

PKGDIR="package"

clone() {
	local repo="$1" dst="$2"
	echo "==> 拉取 ${repo}"
	for i in 1 2 3; do
		rm -rf "${dst}"
		if git clone --depth 1 "${repo}" "${dst}"; then
			return 0
		fi
		echo "   第 ${i} 次失败，重试..."
		sleep 3
	done
	echo "!! 拉取 ${repo} 失败"
	return 1
}

# ---------------------------------------------------------------- PassWall 2
clone https://github.com/Openwrt-Passwall/openwrt-passwall2.git /tmp/src-passwall2
cp -rf /tmp/src-passwall2/luci-app-passwall2 "${PKGDIR}/"

# PassWall 2 依赖的私有包（官方源里没有的部分）
clone https://github.com/Openwrt-Passwall/openwrt-passwall-packages.git /tmp/src-passwall-pkgs
mkdir -p "${PKGDIR}/passwall-packages"
for d in /tmp/src-passwall-pkgs/*/; do
	name="$(basename "${d}")"
	case "${name}" in
		xray-core|sing-box|smartdns|hysteria|v2ray-geodata)
			echo "==> 跳过 ${name}（官方 packages 源已提供同名包）"
			;;
		*)
			cp -rf "${d}" "${PKGDIR}/passwall-packages/"
			;;
	esac
done

# ---------------------------------------------------------------- Clashoo
clone https://github.com/kenzok8/openwrt-clashoo.git /tmp/src-clashoo
cp -rf /tmp/src-clashoo/clashoo "${PKGDIR}/"
cp -rf /tmp/src-clashoo/luci-app-clashoo "${PKGDIR}/"

# ---------------------------------------------------------------- QuickFile（文件管理）
clone https://github.com/sbwml/luci-app-quickfile.git /tmp/src-quickfile
cp -rf /tmp/src-quickfile/luci-app-quickfile "${PKGDIR}/"
cp -rf /tmp/src-quickfile/quickfile "${PKGDIR}/"

# ---------------------------------------------------------------- DiskMan（磁盘管理）
clone https://github.com/sbwml/luci-app-diskman.git /tmp/src-diskman
cp -rf /tmp/src-diskman/luci-app-diskman "${PKGDIR}/"

# ---------------------------------------------------------------- Run（.run 安装器）
clone https://github.com/wukongdaily/luci-app-run.git /tmp/src-run
cp -rf /tmp/src-run/luci-app-run "${PKGDIR}/"

# ---------------------------------------------------------------- Partexp（分区扩容）
clone https://github.com/sirpdboy/luci-app-partexp.git /tmp/src-partexp
cp -rf /tmp/src-partexp/luci-app-partexp "${PKGDIR}/"

# ---------------------------------------------------------------- 主题：Argon（含内置配置页）
clone https://github.com/jerrykuku/luci-theme-argon.git "${PKGDIR}/luci-theme-argon"

# ---------------------------------------------------------------- 主题：Aurora（含配置插件）
clone https://github.com/eamonxg/luci-theme-aurora.git /tmp/src-aurora
cp -rf /tmp/src-aurora "${PKGDIR}/luci-theme-aurora"
clone https://github.com/eamonxg/luci-app-aurora-config.git "${PKGDIR}/luci-app-aurora-config"

# ---------------------------------------------------------------- 主题：Vantage（含仪表盘）
clone https://github.com/anothaDev/luci-theme-vantage.git /tmp/src-vantage
cp -rf /tmp/src-vantage/luci-theme-vantage "${PKGDIR}/"
cp -rf /tmp/src-vantage/luci-app-vantage "${PKGDIR}/"

rm -rf /tmp/src-*

echo "==> 第三方插件目录准备完成："
find "${PKGDIR}" -maxdepth 2 -name Makefile | sed 's|^|   |'
