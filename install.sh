#!/usr/bin/env bash
# install.sh - 安装 / 更新 sing-box 管理工具 sb
# 可反复运行（幂等）：再次执行即为更新。不会覆盖你已有的 config.json。
#
# 一键安装（无需先 clone）：
#   curl -fsSL https://raw.githubusercontent.com/renjunru/singbox-sb/main/install.sh | bash
set -euo pipefail

REPO_URL="https://github.com/renjunru/singbox-sb.git"
CACHE_DIR="$HOME/.local/share/singbox-sb"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
CONFIG_DIR="$HOME/.config/sing-box"
BIN_DIR="$HOME/.local/bin"

say()  { printf '\033[1;32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*"; }

# ---- 自举：经 curl|bash 运行时身边没有仓库文件，先克隆再转交 ----------------
if [ ! -f "$REPO_DIR/bin/sb" ]; then
  command -v git >/dev/null 2>&1 || {
    warn "需要 git（macOS 装 Xcode 命令行工具：xcode-select --install）。"; exit 1; }
  if [ -d "$CACHE_DIR/.git" ]; then
    say "更新本地仓库缓存：$CACHE_DIR"
    git -C "$CACHE_DIR" pull --ff-only
  else
    say "克隆仓库到：$CACHE_DIR"
    git clone --depth 1 "$REPO_URL" "$CACHE_DIR"
  fi
  exec bash "$CACHE_DIR/install.sh"
fi

mkdir -p "$BIN_DIR"

# ---- 依赖：python3（硬性） --------------------------------------------------
command -v python3 >/dev/null 2>&1 || { warn "缺少 python3，请先安装。"; exit 1; }

# ---- 依赖：sing-box 本体 ---------------------------------------------------
# 有 brew → 提示用户用 brew 装（便于后续升级）；无 brew → 自动下 GitHub release 二进制。
install_singbox_from_github() {
  local arch a tag url tmp bin
  arch="$(uname -m)"
  case "$arch" in
    arm64|aarch64) a=arm64 ;;
    x86_64|amd64)  a=amd64 ;;
    *) warn "未知架构 $arch，无法自动下载 sing-box，请手动安装。"; return 1 ;;
  esac
  say "未检测到 Homebrew，从 GitHub 下载 sing-box（darwin-$a）…"
  tag="$(curl -fsSL https://api.github.com/repos/SagerNet/sing-box/releases/latest \
        | grep -m1 '"tag_name"' | sed -E 's/.*"v?([0-9][^"]*)".*/\1/')"
  [ -n "${tag:-}" ] || { warn "取 sing-box 最新版本号失败，请手动安装。"; return 1; }
  url="https://github.com/SagerNet/sing-box/releases/download/v${tag}/sing-box-${tag}-darwin-${a}.tar.gz"
  tmp="$(mktemp -d)"
  curl -fsSL "$url" -o "$tmp/sb.tgz" || { warn "下载失败：$url"; rm -rf "$tmp"; return 1; }
  tar -xzf "$tmp/sb.tgz" -C "$tmp"
  bin="$(find "$tmp" -type f -name sing-box | head -n1)"
  [ -n "$bin" ] || { warn "解压后未找到 sing-box 二进制。"; rm -rf "$tmp"; return 1; }
  install -m 0755 "$bin" "$BIN_DIR/sing-box"
  rm -rf "$tmp"
  say "已安装 sing-box ${tag} → $BIN_DIR/sing-box"
}

if command -v sing-box >/dev/null 2>&1; then
  say "已检测到 sing-box：$(command -v sing-box)"
elif command -v brew >/dev/null 2>&1; then
  say "检测到 Homebrew，安装 sing-box：brew install sing-box"
  brew install sing-box || warn "brew install sing-box 失败，请手动安装后再 sb start。"
else
  install_singbox_from_github || warn "sing-box 未自动安装，请手动安装后再 sb start。"
fi

# ---- 安装脚本 sb -----------------------------------------------------------
install -m 0755 "$REPO_DIR/bin/sb" "$BIN_DIR/sb"
say "已安装脚本：$BIN_DIR/sb"

# ---- 铺设配置目录 ----------------------------------------------------------
mkdir -p "$CONFIG_DIR/rules"
cp "$REPO_DIR/rules/sources.json" "$CONFIG_DIR/rules/sources.json"
say "已更新规则源清单：$CONFIG_DIR/rules/sources.json"

# config.json：仅在不存在时生成；已存在则保留用户自己的，不覆盖
if [ -f "$CONFIG_DIR/config.json" ]; then
  warn "已存在 config.json，保留你现有配置（不覆盖）。如需对照新模板见 config.example.json"
else
  python3 -c "
import os,sys
src=open('$REPO_DIR/config.example.json').read()
src=src.replace('__HOME__', os.path.expanduser('~'))
open('$CONFIG_DIR/config.json','w').write(src)
"
  say "已生成初始配置：$CONFIG_DIR/config.json（节点为占位符，待导入订阅）"
fi

# ---- PATH 提示 -------------------------------------------------------------
case ":$PATH:" in
  *":$BIN_DIR:"*) : ;;
  *) warn "如果敲 sb 提示 command not found，把这行加进 ~/.zshrc 后重开终端：";
     printf '      export PATH="$HOME/.local/bin:$PATH"\n' ;;
esac

# ---- 后续步骤 --------------------------------------------------------------
cat <<'NEXT'

安装完成 ✅  接下来：

  1. 导入你自己的机场订阅：
       sb sub add 我的机场 "<你的订阅链接>"
       sb sub use 我的机场

  2. 下载分流规则集：
       sb rules update

  3. 启动：
       sb start            # tun 全局透明代理（需输入密码）
     或  sb start --mixed   # mixed 代理（不需 root）

  常用：sb status / sb log tail / sb test / sb stop
NEXT
