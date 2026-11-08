# CT3003 固件编译（Lean's OpenWrt + GitHub Actions）

> ⚠️ **本文为历史存档，配置已失效**。仓库现已更名为 `Actions-Op-X86`，并于 2026-11-08 切换为编译
> **x86-64 generic / 官方 OpenWrt 25.12.6** 固件，默认管理地址 `192.168.100.1`、默认主题 **Argon**。
> 当前配置请以 [README.md](README.md) 为准，详细构建说明见 [README-x86.md](README-x86.md)。
> 下文中的 `192.168.1.1`、Vantage 主题、Lean lede 源码等均为旧值，请勿照用。

基于 [P3TERX/Actions-OpenWrt](https://github.com/P3TERX/Actions-OpenWrt) 模板改造，用来编译 **Cetron CT3003（MT7981 / Filogic，256M 内存 + 128M SPI-NAND）** 的固件。

## 这份配置做了什么

| 项目 | 设置 |
| --- | --- |
| 源码 | `coolsnowwolf/lede`（master）+ LuCI `openwrt-25.12` 分支 |
| 目标 | `mediatek / filogic` → `Cetron CT3003`（`cetron_ct3003`） |
| 版本号 | `25.12.2`（通过 `CONFIG_VERSION_NUMBER` 自定义） |
| 主题 | Vantage（`luci-theme-vantage`，源码来自 `anothaDev/luci-theme-vantage`） |
| 代理插件 | PassWall2（`luci-app-passwall2`，Xray 核心 + nftables 透明代理） |
| 网络 | 默认 IPv4 单栈，不生成 wan6 / IPv6 地址段 |
| 体积 | 编译后自动检查，超过 58MB 直接判失败 |
| 默认地址 | `http://192.168.1.1`，主机名 `CT3003`，时区 CST-8 |
| 输出 | Actions Artifacts + Releases 页面 |

## 目录结构

```
.config                              # 精简配置（只写关键项，其余由 make defconfig 补全）
diy-part1.sh                         # feeds 调整：去掉 helloworld、加 passwall2、拉 Vantage 主题
diy-part2.sh                         # 默认主题/主机名/时区/IPv4 单栈
.github/workflows/openwrt-builder.yml # 编译流程，含目标校验与体积校验
```

## 关于「25.12.2」的说明

Lean 的源码只有一个 `master` 分支，本身不带发行版本号（内核与软件包是滚动更新的）。这里通过 `CONFIG_VERSIONOPT` 把版本标识写成 `25.12.2`，同时 LuCI 用的是 `openwrt-25.12` 分支，所以界面、`/etc/openwrt_release`、`/etc/banner` 显示的都是 25.12.2。

## 使用方法

1. 进入 **Actions** → 左侧 **OpenWrt Builder** → 右侧 **Run workflow**。
2. 约 1.5～2 小时编译完成：
   - `OpenWrt_firmware_cetron_ct3003_xxx`：固件目录（Artifacts）
   - **Releases**：永久保存的固件
3. 下载 `*sysupgrade.bin`，在 LuCI「系统 - 备份与升级 - 固件升级」里刷入。

## 想改的地方

| 需求 | 改哪里 |
| --- | --- |
| 换默认 LAN IP | `diy-part2.sh` 第 4 段取消注释并改数字 |
| 加软件包 | `.config` 加 `CONFIG_PACKAGE_xxx=y` |
| 换主题 | `.config` 换 `CONFIG_PACKAGE_luci-theme-*`，并同步改 `diy-part2.sh` 的 sed |
| 提高体积上限 | workflow 的 `MAX_FIRMWARE_MB` |
| 换成官方源码 | workflow 的 `REPO_URL` / `REPO_BRANCH` |

## 注意

- `make defconfig` 会补齐默认软件包，所以 `.config` 里没写的选项不等于没装。
- 体积主要被 `xray-core`、`v2ray-geodata`（geoip/geosite）和 WiFi 驱动占用；压缩后一般 30～45MB，58MB 上限比较宽松。
- 编译机是 GitHub 免费 runner，本仓库已设 `timeout-minutes: 360`。
- 仓库是从已归档的模板 fork 出来的，仓库本身可正常读写、可跑 Actions。
