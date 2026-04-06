#!/usr/bin/env bash
# ============================================================
# init-agent.sh — vibe-coding-ros2 项目初始化脚本
#
# 用法:
#   ./init-agent.sh          # 生成所有本地配置
#   ./init-agent.sh --check  # 检查环境依赖
#   ./init-agent.sh --help   # 显示帮助
# ============================================================

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

info()  { echo -e "${BLUE}[INFO]${NC}  $*"; }
ok()    { echo -e "${GREEN}[OK]${NC}   $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# ── 帮助 ─────────────────────────────────────────────────
usage() {
  cat <<'EOF'
用法: ./init-agent.sh [选项]

初始化 vibe-coding-ros2 项目。clone 后第一件事运行此脚本。

选项:
  --check   仅检查环境依赖（ROS2、colcon 等）
  -h, --help  显示帮助

生成的文件（不在版本控制）:
  .gitignore    Git 忽略配置（构建产物、编辑器配置）
  .vscode/     VS Code 工作区配置
EOF
}

# ── 参数解析 ─────────────────────────────────────────────
MODE="all"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --check) MODE="check"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) error "未知参数: $1"; exit 1 ;;
  esac
done

# ── 环境检查 ─────────────────────────────────────────────
check_deps() {
  info "检查环境依赖..."

  local missing=0

  command -v git >/dev/null 2>&1 || { error "git 未安装"; missing=1; }
  command -v bash >/dev/null 2>&1 || { error "bash 未安装"; missing=1; }

  if [[ -n "$ROS_DISTRO" ]]; then
    ok "ROS2 detected: $ROS_DISTRO"
    command -v colcon >/dev/null 2>&1 || { warn "colcon 未安装（ROS2 扩展）"; }
  else
    warn "ROS2 未检测到（运行 source /opt/ros/\${ROS_DISTRO}/setup.bash）"
  fi

  if [[ -d "/usr/share/bash-completion/completions" ]]; then
    ok "bash-completion installed"
  fi

  if [[ $missing -eq 0 ]]; then
    ok "环境检查通过"
  fi
  return $missing
}

# ── 生成本地配置文件 ───────────────────────────────────
generate_local() {
  info "生成本地配置文件..."

  # .gitignore
  cat > "$ROOT_DIR/.gitignore" <<'GITIGNORE'
# 构建产物（不同机器路径不同）
build/
install/
log/

# 编辑器配置
.vscode/settings.json
.cursor/
.idea/

# MCP token
mcp.json

# Python
__pycache__/
*.pyc
*.egg-info/

# 临时文件
*.tmp
*.log
*.bak
*.swp
*~
GITIGNORE
  ok ".gitignore"

  # .vscode/settings.json
  mkdir -p "$ROOT_DIR/.vscode"
  cat > "$ROOT_DIR/.vscode/settings.json" <<'VSCODE'
{
  "editor.formatOnSave": true,
  "files.associations": {
    "*.cpp": "cpp",
    "*.hpp": "cpp",
    "*.py": "python",
    "*.sh": "bash",
    "*.yaml": "yaml",
    "*.md": "markdown"
  },
  "shellcheck.enable": true,
  "shellcheck.run": "onType"
}
VSCODE
  ok ".vscode/settings.json"
}

# ── 主流程 ─────────────────────────────────────────────
main() {
  if [[ "$MODE" == "check" ]]; then
    check_deps
    return
  fi

  info "初始化 vibe-coding-ros2..."

  generate_local

  echo ""
  ok "初始化完成！"
  echo ""
  echo "下一步："
  echo "  1. source /opt/ros/\${ROS_DISTRO}/setup.bash"
  echo "  2. bash scripts/generators/ros2-package-generator.sh <pkg_name> cpp rclcpp,std_msgs"
  echo "  3. bash scripts/ros2-build-verify-loop.sh <pkg_name>"
}

main "$@"
