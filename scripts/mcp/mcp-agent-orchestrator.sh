#!/usr/bin/env bash
# ============================================================
# mcp-agent-orchestrator.sh — 一键启动多 Agent 协作开发
#
# 功能：驱动 Claude Code / Copilot / Codex 等 Agent
#       自动完成完整的 ROS2 机器人开发任务
#
# 用法:
#   ./mcp-agent-orchestrator.sh <case> [--agent claude|codex|copilot]
#
#   示例:
#     ./mcp-agent-orchestrator.sh go2-scurve --agent claude
#     ./mcp-agent-orchestrator.sh manipulator-pickplace --agent codex
#     ./mcp-agent-orchestrator.sh custom --agent copilot
#       (custom 会启动交互式需求输入)
#
# 环境变量:
#   AGENT_MODEL   — 指定 Agent 模型（默认 claude-sonnet-4）
#   AGENT_TIMEOUT — 单次 Agent 超时秒数（默认 300）
#   WORKSPACE     — 开发工作区路径（默认 ~/ros2_ws）
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# ── 默认配置 ─────────────────────────────────────────
AGENT="${AGENT:-claude}"          # claude | codex | copilot | copilot-chat
MODEL="${AGENT_MODEL:-claude-sonnet-4-20250514}"
TIMEOUT="${AGENT_TIMEOUT:-300}"    # 5分钟
WORKSPACE="${WORKSPACE:-$HOME/ros2_ws}"
LOG_DIR="$PROJECT_ROOT/logs/mcp-$(date +%Y%m%d_%H%M%S)"
CASE_NAME="${1:-}"

# ── 颜色 ─────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; PURPLE='\033[0;35m'; NC='\033[0m'

log()    { echo -e "${BLUE}[INFO]${NC}   $*"; }
log_ok() { echo -e "${GREEN}[OK]${NC}    $*"; }
log_warn(){ echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_err(){ echo -e "${RED}[ERROR]${NC}  $*"; }
log_step(){ echo -e "${PURPLE}[STEP]${NC}   $*"; }

# ── 帮助 ─────────────────────────────────────────────
usage() {
  cat <<EOF
用法: $0 <案例> [选项]

案例:
  go2-scurve           宇树 GO2 机器狗 S 曲线（Gazebo）
  manipulator-pickplace  机械臂自主抓取（MoveIt2）
  custom                交互式自定义任务

选项:
  --agent <claude|codex|copilot>  指定 Agent 类型（默认: claude）
  --model <model>                 指定模型（默认: claude-sonnet-4-20250514）
  --workspace <path>              指定工作区（默认: ~/ros2_ws）
  --timeout <seconds>             Agent 超时（默认: 300）
  --case <name>                  案例名称（用于日志）
  -h, --help                     显示此帮助

环境变量:
  AGENT_MODEL   默认 claude-sonnet-4-20250514
  AGENT_TIMEOUT 默认 300 秒
  WORKSPACE     默认 ~/ros2_ws

示例:
  $0 go2-scurve --agent claude
  $0 manipulator-pickplace --agent codex --workspace /opt/ros2_ws
  AGENT_MODEL=claude-opus-4 $0 custom --agent claude

Agent 类型说明:
  claude     — Claude Code（官方 CLI）+ Sonnet 4
  codex       — OpenAI Codex CLI（官方）
  copilot     — GitHub Copilot CLI（官方）
  copilot-chat — GitHub Copilot Chat VSCode 集成

工作流程:
  1. 分析案例需求
  2. 读取相关 SKILL.md
  3. 启动 Agent 执行
  4. 收集结果
  5. 验证输出
EOF
}

# ── 参数解析 ─────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --agent)   AGENT="$2"; shift 2 ;;
    --model)   MODEL="$2"; shift 2 ;;
    --workspace) WORKSPACE="$2"; shift 2 ;;
    --timeout) TIMEOUT="$2"; shift 2 ;;
    --case)   CASE_NAME="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) CASE_NAME="$1"; shift ;;
  esac
done

if [[ -z "$CASE_NAME" ]]; then
  log_err "缺少案例名称"
  usage; exit 1
fi

# ── Agent CLI 检查 ───────────────────────────────────
check_agent() {
  case "$AGENT" in
    claude)
      if command -v claude &>/dev/null; then
        log_ok "Claude Code CLI 已安装: $(claude --version 2>/dev/null | head -1)"
      else
        log_err "Claude Code CLI 未安装"
        log "安装: https://docs.anthropic.com/en/docs/claude-code/overview"
        return 1
      fi
      ;;
    codex)
      if command -v codex &>/dev/null || command -v npx &>/dev/null; then
        log_ok "OpenAI Codex 可用"
      else
        log_err "Codex 未安装"
        return 1
      fi
      ;;
    copilot)
      if command -v gh &>/dev/null && gh auth status &>/dev/null; then
        log_ok "GitHub CLI 已认证"
      else
        log_err "GitHub CLI 未安装或未认证"
        return 1
      fi
      ;;
    *) log_err "未知 Agent: $AGENT"; return 1 ;;
  esac
}

# ── 案例定义 ─────────────────────────────────────────
run_case() {
  local case="$1"
  log_step "执行案例: $case (Agent: $AGENT, Model: $MODEL)"

  mkdir -p "$LOG_DIR"

  case "$case" in
    go2-scurve)
      run_go2_scurve
      ;;
    manipulator-pickplace)
      run_manipulator_pickplace
      ;;
    custom)
      run_custom
      ;;
    *)
      log_err "未知案例: $case"
      log "可用案例: go2-scurve, manipulator-pickplace, custom"
      exit 1
      ;;
  esac
}

# ── 案例 1: GO2 S 曲线 ─────────────────────────────
run_go2_scurve() {
  log_step "加载 GO2 S 曲线案例..."
  log "案例路径: $PROJECT_ROOT/examples/mcp-workflow/cases/go2-scurve/README.md"

  # 读取案例 SKILL 清单
  local skills=(
    "$PROJECT_ROOT/agents/skills/quadruped/motion-control/SKILL.md"
    "$PROJECT_ROOT/agents/skills/quadruped/sdf-xacro-model/SKILL.md"
    "$PROJECT_ROOT/agents/skills/simulator/gazebo-harmonic/gazebo-simulation-env/SKILL.md"
    "$PROJECT_ROOT/AGENTS.md"
    "$PROJECT_ROOT/agents/documents/Methodology_and_Principles/ANTI_PATTERNS.md"
  )

  log "加载 Skills:"
  for skill in "${skills[@]}"; do
    [[ -f "$skill" ]] && log "  ✓ $(basename "$(dirname "$skill")")/$(basename "$skill")" || log "  ✗ $skill (不存在)"
  done

  # 构造 Agent prompt
  local prompt_file="$LOG_DIR/go2_scurve_prompt.md"
  cat > "$prompt_file" <<PROMPT
# GO2 S 曲线自主开发任务

你是机器人系统工程师，负责让宇树 GO2 机器狗在 Gazebo 中沿 S 曲线行走。

## 目标
让 GO2 机器狗完成 S 曲线行走（S = 两个半圆 + 直线段，周期 3 秒）。

## 技术要求
- 步态: Trot（对角线同步）
- 控制器: /cmd_vel 话题发布 Twist
- 仿真: Gazebo Harmonic
- 轨迹: S 曲线（两个半圆 + 直线）

## 必须使用的 Skills（按顺序）
1. quadruped/motion-control — 步态规划 + S 曲线轨迹生成
2. quadruped/sdf-xacro-model — GO2 URDF/XACRO 模型
3. simulator/gazebo-harmonic/gazebo-simulation-env — Gazebo 世界配置

## 工作流程（必须执行）
1. 读取 AGENTS.md（极简工作流）
2. 读取 agents/documents/Methodology_and_Principles/ANTI_PATTERNS.md（C++/QoS/并发规范）
3. 读取 quadruped/motion-control SKILL.md
4. 生成 ROS2 功能包（使用 ros2-package-generator.sh）
5. 实现 S 曲线控制器（参考 examples/mcp-workflow/cases/go2-scurve/README.md）
6. 实现 Gazebo 世界文件
7. 编译验证
8. 运行仿真

## 输出要求
- 生成完整的 go2_scurve_project/
- 所有 ROS2 包必须能 colcon build
- 提交到 git

## 约束
- C++ 节点: SharedPtr, rclcpp::init/shutdown
- launch 文件: LaunchDescription 结构
- 完成后运行 scripts/check_ros2_package.sh 验证
PROMPT

  log "Prompt 已写入: $prompt_file"
  launch_agent "$prompt_file" "go2_scurve"
}

# ── 案例 2: 机械臂抓取 ─────────────────────────────
run_manipulator_pickplace() {
  log_step "加载机械臂抓取案例..."
  log "案例路径: $PROJECT_ROOT/examples/mcp-workflow/cases/manipulator-pickplace/README.md"

  local prompt_file="$LOG_DIR/manipulator_pickplace_prompt.md"
  cat > "$prompt_file" <<PROMPT
# 机械臂自主抓取任务

你是机器人系统工程师，负责实现机械臂"识别目标 → 运动规划 → 抓取 → 放置"的完整流程。

## 目标
在 Gazebo + MoveIt2 中完成目标物体抓取放置（成功率 > 80%）。

## 技术要求
- 机械臂: 5+ DOF
- 感知: 点云目标检测
- 规划: MoveIt2 + OMPL
- 控制: 力控夹爪
- 仿真: Gazebo

## 必须使用的 Skills
1. manipulator/sdf-xacro-model — 机械臂 URDF
2. manipulator/motion-control/grasp-planning — 抓取规划
3. manipulator/motion-control/impedance-control — 力控
4. perception/lidar-camera-fusion — 点云处理
5. manipulator/skill-planning — MoveIt2 配置

## 工作流程
1. 读取 AGENTS.md
2. 读取 agents/documents/Methodology_and_Principles/ANTI_PATTERNS.md
3. 读取 manipulator/motion-control/grasp-planning SKILL.md
4. 生成 ROS2 包（使用 ros2-package-generator.sh）
5. 实现点云处理节点
6. 实现抓取规划服务
7. 实现 MoveIt2 运动规划
8. 实现力控夹爪
9. 编译 + 仿真验证

## 约束
- 所有节点: SharedPtr, rclcpp::init/shutdown
- launch 文件: LaunchDescription 结构
- 编译验证
PROMPT

  log "Prompt 已写入: $prompt_file"
  launch_agent "$prompt_file" "manipulator_pickplace"
}

# ── 自定义案例 ───────────────────────────────────
run_custom() {
  log_step "自定义案例（交互式）..."

  local task
  echo -e "${YELLOW}请描述你的开发任务:${NC}"
  read -r -p "> " task

  if [[ -z "$task" ]]; then
    log_err "任务为空"
    exit 1
  fi

  log "你输入的任务: $task"

  local robot_type
  echo -e "${YELLOW}机器人类型:${NC}"
  echo "  1. quadruped (机器狗)"
  echo "  2. manipulator (机械臂)"
  echo "  3. wheeled_vehicle (轮式)"
  echo "  4. humanoid (人形)"
  echo "  5. multi_rotor_uav (无人机)"
  echo "  6. underwater (水下)"
  echo "  7. common (通用)"
  read -r -p "选择 [1-7]: " choice

  local robots=(quadruped manipulator wheeled_vehicle humanoid multi_rotor_uav underwater common)
  local robot="${robots[$((choice-1))]:-common}"

  local prompt_file="$LOG_DIR/custom_task_prompt.md"
  cat > "$prompt_file" <<PROMPT
# 自定义机器人开发任务

## 用户任务描述
$task

## 机器人类型
$robot

## 工作流程
1. 分析任务 → 确定需要的 Skills
2. 读取 AGENTS.md
3. 读取 agents/documents/Methodology_and_Principles/ANTI_PATTERNS.md
4. 搜索相关 SKILL.md（agents/skills/$robot/*/SKILL.md）
5. 生成 ROS2 功能包
6. 实现代码
7. 编译验证
8. 运行验证

## 约束
- 使用 ros2-package-generator.sh 生成包结构
- 遵循 AGENTS.md 的文件生成顺序
- C++ 节点: SharedPtr, rclcpp::init/shutdown
- launch 文件: LaunchDescription 结构
- 代码编译通过

## 输出
- 完整的 ROS2 功能包
- 可运行的节点
- git 提交记录
PROMPT

  log "Prompt 已写入: $prompt_file"
  launch_agent "$prompt_file" "custom_task"
}

# ── 启动 Agent ─────────────────────────────────────
launch_agent() {
  local prompt_file="$1"
  local case_tag="$2"
  local agent_log="$LOG_DIR/${case_tag}_agent_$(date +%H%M%S).log"

  log_step "启动 $AGENT Agent (超时: ${TIMEOUT}s)..."

  case "$AGENT" in
    claude)
      launch_claude "$prompt_file" "$agent_log"
      ;;
    codex)
      launch_codex "$prompt_file" "$agent_log"
      ;;
    copilot)
      launch_copilot "$prompt_file" "$agent_log"
      ;;
    copilot-chat)
      log_warn "copilot-chat 需要 VS Code，请手动在 VS Code 中打开项目并执行"
      log "提示: 在 VS Code 中按 Ctrl+Shift+P → 'Copilot: 打开聊天'"
      exit 0
      ;;
  esac
}

launch_claude() {
  local prompt="$1"
  local log_file="$2"

  log "启动 Claude Code..."
  log "Working directory: $WORKSPACE"
  log "Project root: $PROJECT_ROOT"
  log "Prompt: $prompt"

  # Claude Code 使用 --print 输出结果，--input 输入 prompt
  timeout "$TIMEOUT" claude \
    --print \
    --model "$MODEL" \
    --max-turns 20 \
    --no-input \
    --system "$(cat <<'SYSTEM'
你是一个专业的 ROS2 机器人开发工程师。
你必须：
1. 遵循 AGENTS.md 的执行顺序
2. 遵循 agents/documents/Methodology_and_Principles/ANTI_PATTERNS.md 的 C++/QoS/并发规范
3. 使用 ros2-package-generator.sh 生成包结构
4. 所有 C++ 节点使用 SharedPtr
5. 所有 launch 文件使用 LaunchDescription 结构
6. 完成后运行 scripts/check_ros2_package.sh 验证
7. 每完成一个包都 git commit
SYSTEM
)" \
    -- "$(cat "$prompt")" \
    2>&1 | tee "$log_file"

  local exit_code=${PIPESTATUS[0]}
  if [[ $exit_code -eq 124 ]]; then
    log_warn "Agent 超时（${TIMEOUT}s）"
  elif [[ $exit_code -ne 0 ]]; then
    log_err "Agent 失败（退出码: $exit_code）"
  else
    log_ok "Agent 执行完成"
  fi

  log "日志: $log_file"
}

launch_codex() {
  local prompt="$1"
  local log_file="$2"

  log "启动 OpenAI Codex..."

  timeout "$TIMEOUT" codex \
    --prompt "$(cat "$prompt")" \
    --output "$log_file" \
    2>&1 || true

  log_ok "Codex 执行完成（日志: $log_file）"
}

launch_copilot() {
  local prompt="$1"
  local log_file="$2"

  log "启动 GitHub Copilot..."

  # gh copilot 使用
  timeout "$TIMEOUT" gh copilot suggest \
    --language zh-CN \
    -- "$task" \
    2>&1 | tee "$log_file" || true

  log_ok "Copilot 执行完成（日志: $log_file）"
}

# ── 结果汇总 ───────────────────────────────────────
summarize() {
  echo ""
  echo "══════════════════════════════════════"
  echo -e "  ${BLUE}MCP Agent 执行报告${NC}"
  echo "══════════════════════════════════════"
  echo ""
  echo "案例: $CASE_NAME"
  echo "Agent: $AGENT ($MODEL)"
  echo "工作区: $WORKSPACE"
  echo "日志目录: $LOG_DIR"
  echo ""
  echo "Agent 日志:"
  find "$LOG_DIR" -name "*.log" | while read f; do
    echo "  $(basename "$f") ($(wc -l < "$f") 行)"
  done
  echo ""
  echo "Git 状态:"
  cd "$WORKSPACE" && git log --oneline -3 2>/dev/null || echo "(工作区无 git)"
  echo ""
}

# ── 主流程 ─────────────────────────────────────────
main() {
  echo ""
  echo "══════════════════════════════════════"
  echo -e "  ${PURPLE}MCP Agent Orchestrator${NC}"
  echo -e "  ${BLUE}v0.0.1-beta${NC}"
  echo "══════════════════════════════════════"
  echo ""
  log "案例: $CASE_NAME"
  log "Agent: $AGENT"
  log "模型: $MODEL"
  log "超时: ${TIMEOUT}s"
  log "工作区: $WORKSPACE"
  echo ""

  # 检查 Agent
  if ! check_agent; then
    log_err "Agent 检查失败"
    exit 1
  fi

  # 创建工作区
  mkdir -p "$WORKSPACE/src"

  # 执行案例
  run_case "$CASE_NAME"

  # 汇总
  summarize
}

main "$@"
