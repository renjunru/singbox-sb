#!/usr/bin/env bash
# install.sh - 安装 / 更新 sing-box 管理工具 sb
# 可反复运行（幂等）：再次执行即为更新。不会覆盖你已有的 config.json。
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config/sing-box"
BIN_DIR="$HOME/.local/bin"

say()  { printf '\033[1;32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*"; }

# ---- 依赖检查 --------------------------------------------------------------
command -v python3 >/dev/null 2>&1 || { warn "缺少 python3，请先安装。"; exit 1; }
if ! command -v sing-box >/dev/null 2>&1; then
  warn "未检测到 sing-box 本体。安装后请先装：brew install sing-box"
fi

# ---- 安装脚本 sb -----------------------------------------------------------
mkdir -p "$BIN_DIR"
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
