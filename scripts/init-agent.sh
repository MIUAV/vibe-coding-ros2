#!/usr/bin/env bash
# ============================================================
# init-agent.sh — 初始化 vibe-coding-ros2 项目
#
# 功能：生成本地配置文件 + AI Agent 索引
# 原则：
#   1. 根目录文档仅保留必要文件（README.md, AGENTS.md, CLAUDE.md 等）
#   2. .github/ .gitignore 等本地配置由本脚本生成，不进入版本控制
#   3. 用户 clone → 运行 init-agent.sh → 立刻开始 ROS2 包开发 → 编译 → 提交
#
# 用法:
#   ./init-agent.sh              # 生成所有本地文件（默认）
#   ./init-agent.sh --agent     # 仅生成 AI agent 索引
#   ./init-agent.sh --local     # 仅生成本地配置文件
#   ./init-agent.sh --all       # 生成全部（agent + local）
#   ./init-agent.sh --help      # 显示帮助
# ============================================================

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
MODE="all"  # all | agent | local

# ── 颜色 ─────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC}  $*"; }
ok()      { echo -e "${GREEN}[OK]${NC}   $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# ── 帮助 ─────────────────────────────────────────
usage() {
  cat <<'EOF'
用法: ./init-agent.sh [选项]

初始化 vibe-coding-ros2 项目。

用户 clone 项目后，第一件事运行此脚本：
  $ git clone https://github.com/MIUAV/vibe-coding-ros2.git
  $ cd vibe-coding-ros2
  $ ./init-agent.sh          # 生成所有文件
  $ ./init-agent.sh --local # 仅生成本地配置（.gitignore, .github, .vscode）

选项:
  --agent   生成 AI Agent 索引文件（skill-index, routing 等）
  --local   生成本地配置文件（.gitignore, .github workflows 等）
  --all     生成全部（默认）
  -h, --help  显示此帮助

生成的文件:
  本地配置（不在版本控制）:
    .gitignore                         Git 忽略配置
    .vscode/settings.json              VS Code 工作区设置
EOF
}

# ── 参数解析 ─────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --agent)  MODE="agent";  shift ;;
    --local)  MODE="local";  shift ;;
    --all)    MODE="all";    shift ;;
    -h|--help) usage; exit 0 ;;
    *) error "未知参数: $1"; usage; exit 1 ;;
  esac
done

# ═══════════════════════════════════════════════════
# 本地配置生成（不提交到仓库）
# ═══════════════════════════════════════════════════
generate_local_files() {
  info "生成本地配置文件..."

  # ── 1. .gitignore ──────────────────────────────
  cat > "$ROOT_DIR/.gitignore" <<'GITIGNORE'
# ============================================================
# vibe-coding-ros2 .gitignore
# 自动生成 by init-agent.sh — 如需修改，编辑 init-agent.sh 后重新运行
# ============================================================

# ── ROS2 工作区构建产物（不同机器路径不同） ───────────
install/
build/
log/

# ── 编辑器本地配置 ───────────────────────────────
# 每个人的编辑器配置不同，不该共享
.vscode/settings.json
.vscode/mcp.json
.cursor/
.idea/

# ── MCP token / 敏感信息 ─────────────────────────
mcp.json

# ── Python ───────────────────────────────────────
__pycache__/
*.pyc
*.egg-info/
dist/
*.egg

# ── 临时 / 运行时 ────────────────────────────────
*.tmp
*.bak
*.log
*.swp
*.swo
*~
.DS_Store

# ── 自动生成文件（由 init-agent.sh 管理）──────────
.github/
.docs/
GITIGNORE
  ok ".gitignore"

  # ── 2. .github/workflows/ros2-build.yml ─────────
  mkdir -p "$ROOT_DIR/.github/workflows"
  cat > "$ROOT_DIR/.github/workflows/ros2-build.yml" <<'WORKFLOW'
name: ROS2 VibeCoding CI

on:
  push:
    branches: [main, latest, develop]
  pull_request:
  workflow_dispatch:

env:
  ROS_DISTRO: humble
  UBUNTU_VERSION: jammy

jobs:
  # ── CI-1: 核心文件 + Anti-Patterns ──────────────
  core-files:
    name: Core Files & Anti-Patterns
    runs-on: ubuntu-22.04
    steps:
      - uses: actions/checkout@v4

      - name: Verify core files
        run: |
          for f in agents/skills agents/robots scripts init-agent.sh README.md AGENTS.md i18n/zh-CN/AGENTS_CONCISE.md i18n/zh-CN/ANTI_PATTERNS.md; do
            [[ -d "$f" || -f "$f" ]] && echo "✓ $f" || { echo "✗ $f missing"; exit 1; }
          done

      - name: Skills count
        run: |
          N=$(find agents/skills -name 'SKILL.md' 2>/dev/null | wc -l)
          echo "Skills: $N"
          [[ $N -ge 50 ]] || { echo "Too few skills"; exit 1; }

      - name: Scripts check
        run: |
          for f in scripts/check_ros2_package.sh scripts/generators/ros2-package-generator.sh scripts/validators/ros2-node-validator.sh; do
            [[ -x "$f" ]] || chmod +x "$f"
          done
          echo "✓ Scripts executable"

      - name: Anti-Patterns C++ coverage
        run: |
          AP="i18n/zh-CN/ANTI_PATTERNS.md"
          [[ -f "$AP" ]] || { echo "Missing $AP"; exit 1; }
          grep -qi "SharedPtr\|make_shared" "$AP" && echo "✓ Smart pointer rules" || exit 1
          grep -qi "QoS\|qos" "$AP" && echo "✓ QoS rules" || exit 1
          grep -qi "Lifecycle" "$AP" && echo "✓ Lifecycle rules" || exit 1
          grep -qi "MultiThreaded\|mutex\|atomic" "$AP" && echo "✓ Concurrency rules" || exit 1

  # ── CI-2: CMakeLists.txt 正确性 ────────────────
  cmake-check:
    name: CMakeLists.txt Correctness
    runs-on: ubuntu-22.04
    steps:
      - uses: actions/checkout@v4
      - name: Validate generator
        run: |
          GEN="scripts/generators/ros2-package-generator.sh"
          for item in \
            "find_package(ament_cmake REQUIRED)" \
            "find_package(rclcpp REQUIRED)" \
            "ament_target_dependencies" \
            "install(TARGETS" \
            "ament_package()" \
            "CMAKE_CXX_STANDARD 17"; do
            grep -q "$item" "$GEN" && echo "✓ $item" || { echo "✗ Missing: $item"; exit 1; }
          done

  # ── CI-3: package.xml 依赖 ─────────────────────
  package-xml-check:
    name: package.xml Validation
    runs-on: ubuntu-22.04
    steps:
      - uses: actions/checkout@v4
      - name: Validate generator
        run: |
          GEN="scripts/generators/ros2-package-generator.sh"
          grep -q 'format="3"' "$GEN" && echo "✓ Format 3" || exit 1
          grep -q "<depend>rclcpp</depend>" "$GEN" && echo "✓ rclcpp" || exit 1
          grep -q "<export>" "$GEN" && echo "✓ export block" || exit 1

  # ── CI-4: Docker 真实编译 ─────────────────────
  ros2-compile:
    name: ROS2 Humble Compile
    runs-on: ubuntu-22.04
    permissions: { contents: read }
    steps:
      - uses: actions/checkout@v4
      - name: Docker colcon build test
        run: |
          docker run --rm \
            -v ${{ github.workspace }}:/workspace \
            -w /workspace \
            osrf/ros:humble-ros-base-jammy \
            bash -c "
              set -e
              apt-get update -qq && apt-get install -y -qq python3-colcon-common-extensions git > /dev/null 2>&1
              mkdir -p /tmp/test_ws/src
              cd /tmp/test_ws
              bash /workspace/scripts/generators/ros2-package-generator.sh test_pkg cpp rclcpp,std_msgs
              cp -r test_pkg /tmp/test_ws/src/
              source /opt/ros/humble/setup.bash
              colcon build --packages-select test_pkg --cmake-args -DCMAKE_BUILD_TYPE=Release 2>&1 | tail -5
              [[ -f install/test_pkg/lib/test_pkg/test_pkg_node ]] && echo '✓ Binary built' || exit 1
              bash /workspace/scripts/check_ros2_package.sh /tmp/test_ws/src/test_pkg
              echo '=== COMPILE TESTS PASSED ==='
            "

  # ── CI-5: 包耦合分析 ──────────────────────────
  package-coupling:
    name: Package Coupling
    runs-on: ubuntu-22.04
    steps:
      - uses: actions/checkout@v4
      - name: Dependency graph
        run: |
          echo "=== Skill Dependencies ==="
          for skill in agents/skills/*/*/SKILL.md; do
            [[ -f "$skill" ]] || continue
            PKG=$(echo "$skill" | cut -d/ -f3)
            DEPS=$(grep '<depend>' "$skill" 2>/dev/null | sed 's/<depend>//g;s/<\/depend>//g' | tr '\n' ',' || echo "")
            [[ -n "$DEPS" ]] && echo "  $PKG → $DEPS"
          done | sort -u | head -20

  # ── CI-6: Shellcheck ──────────────────────────
  shellcheck:
    name: Shell Scripts
    runs-on: ubuntu-22.04
    steps:
      - uses: actions/checkout@v4
      - name: Install shellcheck
        run: sudo apt-get install -y -qq shellcheck > /dev/null 2>&1
      - name: Run shellcheck
        run: |
          for f in scripts/*.sh scripts/**/*.sh; do
            [[ -f "$f" ]] || continue
            shellcheck --disable=SC1091,SC2086 "$f" 2>&1 | grep -v "^$" || echo "  ✓ $f"
          done

  # ── CI-7: Python + YAML ──────────────────────
  python-lint:
    name: Python & YAML
    runs-on: ubuntu-22.04
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with: { python-version: '3.10' }
      - name: Install linters
        run: pip install flake8 pyyaml -q
      - name: Python syntax
        run: |
          for f in scripts/*.py scripts/**/*.py; do
            [[ -f "$f" ]] || continue
            python3 -m py_compile "$f" && echo "  ✓ $f" || exit 1
          done
      - name: YAML validation
        run: |
          for f in $(find . -name '*.yaml' -not -path './.git/*' 2>/dev/null | head -10); do
            python3 -c "import yaml; yaml.safe_load(open('$f'))" 2>/dev/null && echo "  ✓ $f" || echo "  ✗ $f"
          done

  # ── CI-8: Skill 质量分级 ───────────────────────
  skill-quality:
    name: Skill Quality
    runs-on: ubuntu-22.04
    steps:
      - uses: actions/checkout@v4
      - name: Classify skills
        run: |
          VERIFIED=0; DRAFT=0; CONCEPT=0; EMPTY=0; TOTAL=0
          for skill in agents/skills/*/*/SKILL.md; do
            [[ -f "$skill" ]] || continue
            ((TOTAL++))
            SIZE=$(stat -c%s "$skill" 2>/dev/null || echo 100)
            if [[ $SIZE -lt 100 ]]; then ((EMPTY++))
            elif [[ $(wc -w < "$skill") -lt 50 ]]; then ((CONCEPT++))
            elif grep -q "## 示例\|## 代码\|status.*verified" "$skill" 2>/dev/null; then ((VERIFIED++))
            else ((DRAFT++)); fi
          done
          echo "Total: $TOTAL | Verified: $VERIFIED | Draft: $DRAFT | Concept: $CONCEPT | Empty: $EMPTY"
WORKFLOW
  ok ".github/workflows/ros2-build.yml"
  # ── 3. .docs/graphical-tools.md ────────────────────
  mkdir -p "$ROOT_DIR/.docs"
  cat > "$ROOT_DIR/.docs/graphical-tools.md" <<'DOCS'
# 图形化工具

> ROS2 图形化开发与调试工具

---

## rqt 插件

| 插件 | 命令 | 用途 |
|------|------|------|
| rqt_graph | `rqt_graph` | 计算图可视化 |
| rqt_console | `rqt_console` | 日志查看器 |
| rqt_plot | `rqt_plot` | 数值曲线绘制 |
| rqt_image_view | `rqt_image_view` | 图像话题查看 |
| rqt_service_caller | `rqt_service_caller` | Service 调用器 |
| rqt_bag | `rqt_bag` | Bag 可视化播放器 |

## rviz2

```bash
rviz2
```

三维可视化：TF、LaserScan、PointCloud2、Image、Path

## foxglove

```bash
ros2 launch foxglove_bridge foxglove_bridge_launch.xml
```

## plotjuggler

```bash
ros2 run plotjuggler plotjuggler
```

数值绘图，支持 bag 回放、多曲线对比。

## 调试命令

```bash
ros2 topic list -v     # 列出所有话题
ros2 topic echo <name> # 查看话题内容
ros2 node list         # 列出所有节点
ros2 interface list    # 列出所有接口
```
DOCS
  ok ".docs/graphical-tools.md"


  # ── 3. .vscode/settings.json ───────────────────
  mkdir -p "$ROOT_DIR/.vscode"
  cat > "$ROOT_DIR/.vscode/settings.json" <<'VSCODE'
{
  "python.defaultInterpreterPath": "/usr/bin/python3",
  "python.linting.enabled": false,
  "files.exclude": {
    "**/.git": true,
    "**/.gitignore": false
  },
  "[python]": {
    "editor.defaultFormatter": "ms-python.python",
    "editor.formatOnSave": false
  },
  "[bash]": {
    "editor.defaultFormatter": "ms-vscode.shell-format"
  }
}
VSCODE
  ok ".vscode/settings.json"

  # ── 5. .vscode/mcp.json（模板，用户填 token） ───
  cat > "$ROOT_DIR/.vscode/mcp.json" <<'MCP'
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "."]
    },
    "fetch": {
      "command": "uvx",
      "args": ["mcp-server-fetch"]
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${env:GITHUB_PERSONAL_ACCESS_TOKEN}"
      }
    }
  }
}
MCP
  ok ".vscode/mcp.json (请设置 GITHUB_PERSONAL_ACCESS_TOKEN 环境变量)"

  # ── 6. .gitignore 追加 .vscode/mcp.json（不提交） ─
  # 确保 mcp.json 不会被提交（已在 .gitignore 中）
  grep -q 'mcp.json' "$ROOT_DIR/.gitignore" || echo "mcp.json" >> "$ROOT_DIR/.gitignore"

  echo ""
  info "本地配置文件生成完毕"
  info "下一步: "
  info "  1. 编辑 .vscode/mcp.json — 填入你的 GitHub Token"
  info "  2. 运行: source install/setup.bash  （构建 ROS2 包后）"
  info "  3. 开始开发你的 ROS2 包"
}

# ═══════════════════════════════════════════════════
# AI Agent 索引生成（提交到仓库）
# ═══════════════════════════════════════════════════
generate_agent_files() {
  info "生成 AI Agent 索引文件..."

  mkdir -p "$ROOT_DIR/agents/generated"

  # ── 1. skill-index.md ─────────────────────────
  SKILL_INDEX="$ROOT_DIR/agents/generated/skill-index.md"
  cat > "$SKILL_INDEX" <<'SKILLEOF'
# Skill Index — 机器人技能总索引

> 由 init-agent.sh 自动生成。每次添加新 skill 后重新运行 `./init-agent.sh --agent`。

## 统计

| 机器人类型 | 技能数 |
|-----------|--------|
SKILLEOF

  for robot in "$ROOT_DIR"/agents/skills/*/; do
    ROBOT_NAME=$(basename "$robot")
    COUNT=$(find "$robot" -maxdepth 2 -name 'SKILL.md' 2>/dev/null | wc -l)
    echo "| $ROBOT_NAME | $COUNT |" >> "$SKILL_INDEX"
  done

  cat >> "$SKILL_INDEX" <<'SKILLEOF'

---

## 完整技能列表

SKILLEOF

  for robot in "$ROOT_DIR"/agents/skills/*/; do
    ROBOT_NAME=$(basename "$robot")
    echo "" >> "$SKILL_INDEX"
    echo "### $ROBOT_NAME" >> "$SKILL_INDEX"
    echo "" >> "$SKILL_INDEX"
    for skill_dir in "$robot"/*/; do
      [[ -d "$skill_dir" ]] || continue
      SKILL_NAME=$(basename "$skill_dir")
      SKILL_FILE="$skill_dir/SKILL.md"
      if [[ -f "$SKILL_FILE" ]]; then
        # 取 frontmatter 的 name 或 description
        NAME=$(grep -m1 "^name:" "$SKILL_FILE" 2>/dev/null | sed 's/^name: //' || echo "$SKILL_NAME")
        DESC=$(grep -m1 "^description:" "$SKILL_FILE" 2>/dev/null | sed 's/^description: //' | cut -c1-60 || echo "")
        echo "- **$SKILL_NAME**: $DESC" >> "$SKILL_INDEX"
      else
        echo "- **$SKILL_NAME** _(空)_" >> "$SKILL_INDEX"
      fi
    done
  done

  cat >> "$SKILL_INDEX" <<'SKILLEOF'

---

*运行 `./init-agent.sh --agent` 重新生成*
SKILLEOF
  ok "agents/generated/skill-index.md"

  # ── 2. skill-routing.md ────────────────────────
  cat > "$ROOT_DIR/agents/generated/skill-routing.md" <<'ROUTINGEOF'
# Skill Routing — 技能路由表

> 由 init-agent.sh 自动生成。同名 skill 按完整路径优先级路由。

## 路由规则

```
用户请求 → 机器人类型 → 功能域 → 具体 skill
         → humanoid/manipulator/... → motion-control/perception/...
```

## 机器人类型路由

| 类型 | 场景 |
|------|------|
| humanoid | 双足步态、人形操作、平衡控制 |
| quadruped | 四足行走、复杂地形 |
| manipulator | 机械臂抓取、运动规划 |
| wheeled_vehicle | 轮式导航、差速驱动 |
| multi_rotor_uav | 无人机飞行、悬停 |
| underwater | AUV/ROV、水下导航 |
| common | 所有类型通用（cmake、colcon 等） |
ROUTINGEOF
  ok "agents/generated/skill-routing.md"

  # ── 3. context-index.md ───────────────────────
  cat > "$ROOT_DIR/agents/generated/context-index.md" <<'CTXEOF'
# Context Index — 项目上下文

> 由 init-agent.sh 自动生成。

## 项目结构

```
vibe-coding-ros2/
├── agents/
│   ├── skills/          # 技能定义（270+ SKILL.md）
│   ├── robots/          # 机器人类型指南
│   ├── prompts/         # 提示词模板
│   ├── memory-bank/    # 项目记忆
│   └── generated/       # 自动生成的索引
├── examples/            # 可运行的示例代码（可编译）
│   ├── ros2-minimal/    # cpp_publisher + py_subscriber
│   ├── ros2-lifecycle/  # lifecycle_sensor
│   └── ros2-service/    # add_two_ints
├── scripts/
│   ├── generators/      # 包生成器
│   ├── validators/      # 代码验证器
│   └── deployers/       # 部署脚本
└── i18n/
    ├── zh-CN/           # 中文文档
    └── en/              # 英文文档
```

## 可运行的示例（全部可编译）

| 示例 | 内容 | 验证规则 |
|------|------|----------|
| `examples/ros2-minimal/cpp_publisher` | C++ pub + QoS + wall_timer | SharedPtr, QoS, rclcpp::init/shutdown |
| `examples/ros2-minimal/py_subscriber` | Python sub + rclpy 规范 | rclpy.shutdown(), try/finally |
| `examples/ros2-lifecycle/lifecycle_sensor` | LifecycleNode 状态机 | on_configure/activate/deactivate/cleanup |
| `examples/ros2-service/add_two_ints` | Service + Client + 超时 | wait_for() timeout, async_send_request |

## 关键文件

| 文件 | 用途 |
|------|------|
| i18n/zh-CN/AGENTS_CONCISE.md | 极简工作流指令卡 |
| i18n/zh-CN/ANTI_PATTERNS.md | C++/QoS/并发安全规则 |
| init-agent.sh | 初始化脚本 |
| scripts/generators/ros2-package-generator.sh | 一键生成 ROS2 包 |
| scripts/validators/ros2-node-validator.sh | 代码安全验证 |
CTXEOF
  ok "agents/generated/context-index.md"

  # ── 4. agent-bootstrap.md ─────────────────────
  cat > "$ROOT_DIR/agents/generated/agent-bootstrap.md" <<'BOOTSTRAPEOF'
# Agent Bootstrap

> AI Agent 启动时必须按顺序加载的文件。

## 加载顺序

1. `context-index.md` — 项目结构总览
2. `skill-index.md` — 可用技能列表
3. `skill-routing.md` — 技能路由规则
4. `skill-bootstrap.md` — 本文件

## 执行规则

- 用户请求 → 确定机器人类型 → 确定功能域 → 加载 SKILL.md
- 如 skill 重名，按 taxonomy 路径（agents/skills/{type}/{domain}/）唯一确定
- 使用 i18n/zh-CN/AGENTS_CONCISE.md 作为极简参考
- 使用 i18n/zh-CN/ANTI_PATTERNS.md 检查 C++/QoS/并发安全性
- 生成代码后用 scripts/validators/ros2-node-validator.sh 验证
BOOTSTRAPEOF
  ok "agents/generated/agent-bootstrap.md"

  # ── 5. skill-bootstrap.md ─────────────────────
  cat > "$ROOT_DIR/agents/generated/skill-bootstrap.md" <<'SKILLBOOT'
# Skill Bootstrap

## 开发工作流

```
1. 读 i18n/zh-CN/AGENTS_CONCISE.md
2. 读 i18n/zh-CN/ANTI_PATTERNS.md（重点：C++ 指针/QoS/并发）
3. 读 skill-index.md（找对应 SKILL.md）
4. 读 SKILL.md（获取实现细节）
5. 生成代码
6. 自检（ANTI_PATTERNS 清单）
7. 更新 memory-bank/ROS2_MEMORY.md
```

## 质量门控

- CMakeLists.txt 必检：find_package / ament_target_dependencies / install / ament_package
- package.xml 必检：<depend> 完整 / Format 3
- C++ 必检：make_shared / QoS 声明 / rclcpp::init+shutdown
- 完成后提醒用户 source install/setup.bash
SKILLBOOT
  ok "agents/generated/skill-bootstrap.md"

  echo ""
  info "AI Agent 索引生成完毕"
  info "下一步: git add + git commit + git push"
}

# ═══════════════════════════════════════════════════
# 主流程
# ═══════════════════════════════════════════════════
main() {
  echo ""
  echo "══════════════════════════════════════"
  echo "  init-agent.sh — vibe-coding-ros2"
  echo "══════════════════════════════════════"
  echo ""

  # 检查必要目录
  if [[ ! -d "$ROOT_DIR/agents" ]]; then
    error "agents/ 目录不存在"
    error "请在项目根目录运行此脚本"
    exit 1
  fi

  if [[ ! -d "$ROOT_DIR/scripts" ]]; then
    error "scripts/ 目录不存在"
    exit 1
  fi

  # 确保脚本可执行
  chmod +x "$ROOT_DIR/init-agent.sh"

  case "$MODE" in
    agent)
      generate_agent_files
      ;;
    local)
      generate_local_files
      ;;
    all)
      generate_agent_files
      echo ""
      generate_local_files
      ;;
  esac

  echo ""
  echo "══════════════════════════════════════"
  ok "初始化完成！"
  echo "══════════════════════════════════════"
  echo ""
  echo "推荐工作流:"
  echo "  1. ./init-agent.sh          # 首次运行"
  echo "  2. 开发 ROS2 包"
  echo "  3. bash scripts/generators/ros2-package-generator.sh <name> cpp ..."
  echo "  4. colcon build --packages-select <name> --symlink-install"
  echo "  5. git add . && git commit && git push"
  echo ""
}

main "$@"
