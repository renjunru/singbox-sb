# singbox-sb（`sb`）

一个用于 macOS 的 sing-box 命令行管理工具，配套一份精心设计的分流配置模板。
一条命令安装，导入自己的机场订阅即可使用。

> ⚠️ 本仓库**不含任何节点 / 账号信息**。配置模板里的节点全是占位符，
> 你需要导入自己的机场订阅来填充。

## 特性

- **两种模式**：`tun` 全局透明代理（root 守护）/ `mixed` 系统代理（免 root）
- **订阅导入**：支持 sing-box JSON、Clash/Mihomo YAML、Loon/Surge、Shadowrocket/base64、明文 URI；
  自动按地区（港/日/新/台/美）重建策略组
- **分流规则**：AI / YouTube / Google / GitHub / Telegram / 国内直连等按服务切换出口
- **诊断**：日志归档、连接快照、出口 IP 测试、Clash 面板

## 依赖

- macOS
- [`sing-box`](https://sing-box.sagernet.org/)：`brew install sing-box`
- `python3`（macOS 自带）

## 安装

### 一键安装（推荐）

```bash
curl -fsSL https://raw.githubusercontent.com/renjunru/singbox-sb/main/install.sh | bash
```

一条命令搞定：装 **sing-box 本体** + 装 **`sb` 脚本** + 铺 **配置模板 / 规则清单**。

- 已装 Homebrew → 自动 `brew install sing-box`（便于日后升级）
- 没装 Homebrew → 自动从 GitHub 下载对应架构的 sing-box 二进制到 `~/.local/bin/`
- 已装 sing-box → 跳过

> ⚠️ `curl | bash` 会执行远程脚本。介意的话用下面的「手动安装」，可先 `cat install.sh` 审阅再跑。

### 手动安装（可审阅）

```bash
git clone https://github.com/renjunru/singbox-sb.git
cd singbox-sb
./install.sh
```

无论哪种方式，`install.sh` 都会：

- 把 `sb` 安装到 `~/.local/bin/`
- 在 `~/.config/sing-box/` 生成初始 `config.json`（节点为占位符）和规则源清单
- 反复运行即为更新；**不会覆盖**你已有的 `config.json`

> 若敲 `sb` 提示 command not found，把 `export PATH="$HOME/.local/bin:$PATH"`
> 加进 `~/.zshrc` 后重开终端。

## 快速开始

```bash
sb sub add 我的机场 "<你的订阅链接>"   # 保存订阅
sb sub use 我的机场                    # 把节点应用进 config.json
sb rules update                        # 下载分流规则集
sb start                               # 启动 tun 全局代理
sb status                              # 一行概览（进程/端口/API/各组当前出口）
sb status -v                           # 详情（全网络服务/候选节点/进程）
```

日常切换出口（无需重启，秒生效）：

```bash
sb use us list      # 列出 us 组节点（编号/★当前/延迟）
sb use us 2         # 临时切到该组第 2 个节点
sb use proxy auto   # 切到该组的 *-auto 自动测速
sb set us 2         # 设为持久默认（写 config.json，重启后仍生效）
```

> 组名：`proxy ai youtube google github telegram`（按服务）｜ `hk jp sg tw us`（按地区）｜ `main`（= 4 个服务组一起设）。
> 完整命令清单见 `sb`（无参数）打印的帮助。

## 更新

一键安装过的：再跑一次同一条命令即可（内部自动拉取最新仓库到 `~/.local/share/singbox-sb` 并覆盖脚本）：

```bash
curl -fsSL https://raw.githubusercontent.com/renjunru/singbox-sb/main/install.sh | bash
```

手动 clone 过的：

```bash
git pull
./install.sh        # 幂等，覆盖旧脚本，保留你的 config.json
```

## 目录约定

| 位置 | 内容 |
| --- | --- |
| `~/.local/bin/sb` | 脚本本体（在 `$PATH` 里，可直接 `sb`） |
| `~/.config/sing-box/` | 配置、订阅、规则、日志、缓存 |

脚本与配置分离：升级脚本不动配置，改配置不碰代码。

## 配置模板说明

`config.example.json` 是脱敏后的完整配置：保留了路由 / DNS / fakeip / 策略组架构，
节点字段是占位符。安装时会把里面的 `__HOME__` 替换成你的家目录写入 `config.json`。
导入订阅（`sb sub use`）会重建节点与地区分组，顶层策略组 / 路由 / DNS 保持不变。

## License

MIT
