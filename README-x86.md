# Actions-OpenWrt · x86-64 / OpenWrt 25.12.6

> 当前配置的速览（设备名称 / 固件分支 / 插件清单 / 默认 IP / 默认主题）见 [README.md](README.md)，本文是详细构建说明。

把原来编译 **Cetron CT3003（Lean lede）** 的模板，改成编译 **官方 openwrt/openwrt 25.12.6 的 x86 固件**。
不使用 Lean（coolsnowwolf/lede）源码。

## 一、和原模板的差异

| 项目 | 原来（CT3003） | 现在（x86） |
|---|---|---|
| 源码 | `coolsnowwolf/lede` master | `openwrt/openwrt` `v25.12.6`（openwrt-25.12 分支的 25.12.6 发布） |
| 目标 | `mediatek/filogic` CT3003 | `x86/64` generic（`CONFIG_TARGET_x86_64_DEVICE_generic`） |
| 包格式 | opkg (.ipk) | 25.12 起为 apk (.apk) |
| 体积检查 | 58M（128M NAND） | 单镜像 300M 防呆（x86 无 NAND 限制） |
| 镜像 | `*sysupgrade*.bin` | `*squashfs-combined-efi.img.gz` 等 |
| 权限 | 无 `permissions` | 显式 `contents: write` / `actions: write`（否则上传 Release、删旧 run 会 403） |

## 二、文件说明

```
.config                              编译配置（目标 x86/64 + 全部插件/主题/中文包）
diy-part1.sh                         在 feeds 阶段前拉取第三方插件源码到 package/
diy-part2.sh                           校验第三方目录是否齐全，缺了立刻报错
files/etc/uci-defaults/99-x86-defaults 首次开机默认值（IPv4、主机名、时区、默认主题）
.github/workflows/openwrt-builder.yml  编译流水线
```

`.config` 里固化了这些选择：

- 目标：`x86` / `64` / `generic`
- 中文：`luci-i18n-base-zh-cn`、`luci-i18n-firewall-zh-cn`、`luci-i18n-dockerman-zh-cn`、`luci-i18n-passwall2-zh-cn`、`luci-i18n-clashoo-zh-cn`、`luci-i18n-argon-config-zh-cn`、`luci-i18n-vantage-*-zh-cn`、`luci-i18n-partexp-zh-cn` + `CONFIG_LUCI_LANG_zh_Hans=y`
- 主题：Argon、Vantage、Aurora（默认 Argon，可换），Bootstrap 保底
- 插件：`luci-app-run`、`luci-app-quickfile`(+`quickfile`+`luci-nginx`)、`luci-app-partexp`、`luci-app-diskman`、PassWall2、Clashoo、Docker + `luci-app-dockerman`
- 网络：不装 `odhcp6c` / `odhcpd` / `luci-proto-ipv6`，即默认纯 IPv4

## 三、第三方源码来源（官方源里都没有，故在 diy-part1.sh 中拉取）

| 包 | 仓库 |
|---|---|
| `luci-app-passwall2` | `Openwrt-Passwall/openwrt-passwall2` |
| PassWall 依赖（`chinadns-ng`/`geoview`/`tcping`/`shadowsocks-rust`/`shadowsocksr-libev`/`simple-obfs`/`v2ray-plugin`/`dns2socks`/`microsocks`/`ipt2socks`/`shadow-tls`/`naiveproxy`/`xray-plugin`） | `Openwrt-Passwall/openwrt-passwall-packages` |
| `clashoo` + `luci-app-clashoo` | `kenzok8/openwrt-clashoo` |
| `quickfile` + `luci-app-quickfile` | `sbwml/luci-app-quickfile` |
| `luci-app-diskman` | `sbwml/luci-app-diskman` |
| `luci-app-run` | `wukongdaily/luci-app-run` |
| `luci-app-partexp` | `sirpdboy/luci-app-partexp` |
| Argon 主题（含内置配置页 + 中文包） | `jerrykuku/luci-theme-argon` |
| Aurora 主题 + 配置插件 | `eamonxg/luci-theme-aurora`、`eamonxg/luci-app-aurora-config` |
| Vantage 主题 + 仪表盘 | `anothaDev/luci-theme-vantage` |

> `openwrt-passwall-packages` 里的 `xray-core` / `sing-box` / `smartdns` / `hysteria` / `v2ray-geodata`
> **故意跳过**：官方 packages 源已提供同名包（xray-core 26.10.21、sing-box 1.13.21 等），
> 两份同名包同时存在会冲突。

## 四、怎么用

1. 确认以下 5 个文件已按原路径存在于仓库 `ywgf88/Actions-Op-X86`（当前仓库已包含，无需重复添加）：
   - `.config`
   - `diy-part1.sh`
   - `diy-part2.sh`
   - `files/etc/uci-defaults/99-x86-defaults`
   - `.github/workflows/openwrt-builder.yml`
2. 若修改过上述文件，提交并推送（可用本地 `git`，或 GitHub 网页「Add file → Upload files」）。
3. 仓库 `Actions` → `OpenWrt Builder` → `Run workflow`。
4. 首次编译约 **3~6 小时**（含 Rust 的 `quickfile`、Go 的 `clashoo`/`xray`，云 runner 2~4 核）
   ，成功后在 `Releases` 里下载。

## 五、首次开机后的默认状态

| 项 | 值 |
|---|---|
| 管理地址 | `http://192.168.100.1` |
| LAN | `192.168.100.1/24`，IPv4，静态 |
| WAN | DHCP（PPPoE 请在「网络 - 接口」里改） |
| IPv6 | 默认不下发（DHCPv6 / RA 已去掉） |
| 主机名 | `OpenWrt-x86` |
| 时区 | `Asia/Shanghai` (CST-8) |
| 默认主题 | Argon |
| 默认语言 | 简体中文 |

想改 LAN 地址：编辑 `files/etc/uci-defaults/99-x86-defaults` 里的 `network.lan.ipaddr`。
想换默认主题：把同一文件里的 `/luci-static/argon` 改成 `/luci-static/vantage` 或 `/luci-static/aurora`。

## 六、刷写

解压 `openwrt-25.12.6-x86-64-generic-squashfs-combined-efi.img.gz`，
用 balenaEtcher / Rufus 写入 U 盘或硬盘（UEFI 用 `combined-efi`，老 BIOS 用 `combined`）。
x86 没有 sysupgrade 校验逻辑，**升级是整盘重刷**；想保留配置请先备份 `/etc/config`。

## 七、排错提示

- 报 `Unknown package 'xxx' in ...`：说明该插件目录没拉到，看 `diy-part1.sh` 那一步的日志。
- 报 `missing dependencies`：CI 的 `Validate target config` 会先把没选上的必需包列出来。
- 编译超时/被 cancel：`JOBS` 已降到 3；仍超时就删掉 `quickfile`（Rust，最耗时间）后再编。
- Release 上传 403：确认 workflow 顶部 `permissions: contents: write` 未被删。
