#!/bin/bash
#
# Cetron CT3003 定制版 diy-part1.sh
# 作用：在更新 feeds 之前，调整 feeds 列表、引入额外软件包源码
# 执行目录：OpenWrt 源码根目录
#

# 1. 去掉 helloworld（ssr-plus 等）feed：与 packages feed 里的 xray-core/chinadns-ng 重复，且本固件用不到
sed -i 's|^src-git helloworld|#src-git helloworld|' feeds.conf.default

# 2. 加入 PassWall2 插件源码
#    PassWall2 依赖的 xray-core / chinadns-ng / geoview / tcping / v2ray-geodata
#    在 Lean 自带 packages feed 里都有，不用再加 openwrt-passwall-packages，避免同名包冲突
echo 'src-git passwall2 https://github.com/Openwrt-Passwall/openwrt-passwall2.git' >>feeds.conf.default

# 3. 引入 Vantage 主题（LuCI 官方源没有这个主题，需要单独拉源码）
git clone --depth 1 https://github.com/anothaDev/luci-theme-vantage.git /tmp/vantage-src
rm -rf package/luci-theme-vantage package/luci-app-vantage
cp -rf /tmp/vantage-src/luci-theme-vantage package/
cp -rf /tmp/vantage-src/luci-app-vantage package/

# 4. 打印 feeds 列表，方便日志核对
cat feeds.conf.default
