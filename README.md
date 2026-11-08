# Actions-Op-X86

使用 GitHub Actions 云编译 OpenWrt 固件。基于 [P3TERX/Actions-OpenWrt](https://github.com/P3TERX/Actions-OpenWrt) 模板改造。

> 📌 仓库曾用名 `Actions-OpenWrt-CT3003`，2026-11-08 起更名为 **`Actions-Op-X86`**，以反映当前编译目标。
> 当前 `.config` 编译的是 **x86-64 generic 通用固件**，不是 Cetron CT3003；旧设备（Lean lede / mediatek-filogic）的配置说明保留在 [README-CT3003.md](README-CT3003.md)，仅供存档，已不适用于当前编译流程。
> GitHub 会自动把旧仓库地址重定向到新地址，收藏的旧链接仍可访问。

## 一、一眼看懂

| 你关心的 | 当前值 | 配置依据 |
|---|---|---|
| **设备名称 / 目标平台** | **x86/64 generic**（通用 x86-64 软路由、PC、虚拟机），镜像名 `openwrt-25.12.6-x86-64-generic-*` | `.config` → `CONFIG_TARGET_x86_64_DEVICE_generic=y` |
| **固件源码与分支** | 官方 `openwrt/openwrt`，分支/标签 **`v25.12.6`**（openwrt-25.12 发布分支的 25.12.6 版本）；仓库自身默认分支 `main` | workflow → `REPO_URL` / `REPO_BRANCH` |
| **内置插件** | PassWall2、Clashoo、QuickFile、DiskMan、Partexp、Run、Docker(Dockerman) 等，详见[第三节](#三内置插件清单) | `.config` + `diy-part1.sh` |
| **默认管理地址（IP）** | **`http://192.168.100.1`**（LAN `192.168.100.1/24`，WAN 走 DHCP，默认纯 IPv4） | `files/etc/uci-defaults/99-x86-defaults` |
| **默认主题** | **Argon**（简体中文界面）；另装 Vantage、Aurora、Bootstrap，可自行切换 | `99-x86-defaults` → `luci.main.mediaurlbase=/luci-static/argon` |

## 二、源码、分支与镜像

| 项目 | 值 |
|---|---|
| 源码仓库 | `https://github.com/openwrt/openwrt`（官方源，**不用** Lean `coolsnowwolf/lede`） |
| 源码分支/标签 | `v25.12.6` |
| 版本号 | `25.12.6`（`CONFIG_VERSION_NUMBER`） |
| 目标 | `x86` / `64` / `generic` |
| 包格式 | `apk`（OpenWrt 25.12 起，不再是 opkg/.ipk） |
| 镜像 | `openwrt-25.12.6-x86-64-generic-squashfs-combined-efi.img.gz`（UEFI），传统 BIOS 用 `squashfs-combined.img.gz` |
| 输出位置 | Actions Artifacts + Releases |

> 注：`.github/workflows/update-checker.yml` 仍写着旧的 `coolsnowwolf/lede` / `master`，它只用于「源码更新检查」，**不参与编译**，当前也只支持手动触发。若日后启用定时检查，需同步改成与 `openwrt-builder.yml` 一致。

## 三、内置插件清单

### 主要功能插件

| 分类 | 插件 | 说明 / 源码 |
|---|---|---|
| 代理 | `luci-app-passwall2` | PassWall2，nftables 透明代理 + 全核心；`Openwrt-Passwall/openwrt-passwall2` |
| 代理 | `clashoo` + `luci-app-clashoo` | `kenzok8/openwrt-clashoo` |
| 代理依赖 | `chinadns-ng`、`geoview`、`tcping`、`dnsmasq-full` | 来自 `openwrt-passwall-packages`（xray-core / sing-box / smartdns / hysteria / v2ray-geodata 故意跳过，官方源已有同名包） |
| 文件管理 | `quickfile` + `luci-app-quickfile` + `luci-nginx` | `sbwml/luci-app-quickfile`（Rust 编写，最耗时） |
| 磁盘管理 | `luci-app-diskman` | `sbwml/luci-app-diskman` |
| 分区扩容 | `luci-app-partexp` | `sirpdboy/luci-app-partexp` |
| 容器 | `docker`、`dockerd`、`docker-compose`、`luci-app-dockerman` | 官方 packages 源 |
| 工具 | `luci-app-run` | `.run` 安装器，`wukongdaily/luci-app-run` |
| 命令行 | `htop`、`nano`、`curl`、`wget-ssl`、`unzip`、`ca-bundle` | 官方源 |
| 磁盘工具 | `fdisk`、`parted`、`blkid`、`losetup`、`resize2fs`、`btrfs-progs`、`e2fsprogs`、`f2fs-tools`、`xfs-mkfs`、`exfat-mkfs`、`dosfstools`、`wipefs`、`smartmontools`、`swap-utils` | 供 DiskMan / Partexp 调用 |

### 主题与语言

- 主题：**Argon（默认）**、Vantage（含仪表盘 `luci-app-vantage`）、Aurora（含 `luci-app-aurora-config`）、Bootstrap（保底）
- 中文：`CONFIG_LUCI_LANG_zh_Hans=y` + `luci-i18n-*-zh-cn`（base / firewall / dockerman / passwall2 / clashoo / argon-config / vantage / partexp）

### 明确不安装的组件

`odhcp6c`、`odhcpd`、`odhcpd-ipv6only`、`luci-proto-ipv6`、`ipv6helper` —— 默认 **IPv4 单栈**，不下发 DHCPv6 / RA（内核 IPv6 保留，避免影响 nftables）。

> 完整的第三方源码来源表见 [README-x86.md](README-x86.md) 第三节。
> `make defconfig` 会自动补齐默认软件包，因此上表之外的包也可能被装入。

## 四、首次开机后的默认状态

| 项 | 值 |
|---|---|
| 管理地址 | `http://192.168.100.1` |
| LAN | `192.168.100.1/24`，静态 IPv4 |
| WAN | DHCP（PPPoE 请到「网络 - 接口」修改） |
| IPv6 | 默认不下发 |
| 主机名 | `OpenWrt-x86` |
| 时区 | `Asia/Shanghai`（CST-8） |
| 默认语言 | 简体中文 |
| 默认主题 | Argon |
| 登录密码 | 本仓库未改写，沿用官方镜像默认值，首次登录后请立即设置 |

想改这些值，编辑 `files/etc/uci-defaults/99-x86-defaults`：

| 需求 | 改哪里 |
|---|---|
| 换 LAN IP | `network.lan.ipaddr` |
| 换默认主题 | `luci.main.mediaurlbase` 改成 `/luci-static/vantage` 或 `/luci-static/aurora` |
| 换固件源码/分支 | `.github/workflows/openwrt-builder.yml` 的 `REPO_URL` / `REPO_BRANCH` |
| 增删插件 | `.config` 加 `CONFIG_PACKAGE_xxx=y`；第三方插件还需在 `diy-part1.sh` 拉取源码 |
| 加中文包 | `.config` 加对应的 `luci-i18n-xxx-zh-cn` |

## 五、编译与刷写

1. 仓库 **Actions** → **OpenWrt Builder** → **Run workflow**。
2. 首次编译约 **3~6 小时**（含 Rust 的 quickfile、Go 的 clashoo/xray，云 runner 2~4 核，`JOBS=3`）。
3. 完成后在 **Artifacts** 或 **Releases** 下载镜像。
4. 解压 `*-squashfs-combined-efi.img.gz`，用 balenaEtcher / Rufus / `dd` 写入 U 盘或硬盘。x86 升级是**整盘重刷**，保留配置请先备份 `/etc/config`。

常见报错与排查见 [README-x86.md](README-x86.md) 第七节。

## 六、文档索引

| 文件 | 状态 |
|---|---|
| `README.md` | 本文件，当前配置的速览（以上信息为准） |
| `README-x86.md` | 当前 x86 配置的详细构建说明、第三方源码表、排错 |
| `README-CT3003.md` | **历史存档**：Cetron CT3003 / Lean lede / Vantage 主题 / `192.168.1.1`，已不适用于当前 `.config` |

## 七、致谢与许可

- [P3TERX/Actions-OpenWrt](https://github.com/P3TERX/Actions-OpenWrt)（模板）、[OpenWrt](https://github.com/openwrt/openwrt)、[GitHub Actions](https://github.com/features/actions)
- [Mikubill/transfer](https://github.com/Mikubill/transfer)、[softprops/action-gh-release](https://github.com/softprops/action-gh-release)、[Mattraks/delete-workflow-runs](https://github.com/Mattraks/delete-workflow-runs)、[dev-drprasad/delete-older-releases](https://github.com/dev-drprasad/delete-older-releases)、[peter-evans/repository-dispatch](https://github.com/peter-evans/repository-dispatch)
- 第三方插件与主题作者见 [README-x86.md](README-x86.md) 第三节

[MIT](LICENSE) © P3TERX，本仓库改造部分同样适用 MIT。
