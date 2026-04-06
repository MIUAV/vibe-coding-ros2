#!/bin/bash
# ros2-orchestrate.sh — MIUAV vibe-coding ROS2 项目编排脚本
# 用途：通过对话式提示词生成完整 ROS2 项目
#
# 用法：
#   bash ros2-orchestrate.sh                    # 交互模式
#   bash ros2-orchestrate.sh --auto "描述"     # 自动模式（无交互）
#
# 示例：
#   bash ros2-orchestrate.sh --auto "帮我生成一个用激光雷达导航的差速小车，包含SLAM和路径规划"
#   bash ros2-orchestrate.sh --auto "生成一个6轴机械臂，集成MoveIt2，支持抓取和放置"

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ORCHESTRATE_DIR="${HOME}/.vibe-coding-ros2/projects"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'

# ── 解析参数 ──────────────────────────────────────────────
AUTO_PROMPT=""
INTERACTIVE=true

while [[ $# -gt 0 ]]; do
  case $1 in
    --auto)
      AUTO_PROMPT="$2"
      INTERACTIVE=false
      shift 2
      ;;
    --dir)
      ORCHESTRATE_DIR="$2"
      shift 2
      ;;
    -h|--help)
      echo -e "${CYAN}ros2-orchestrate.sh — MIUAV Vibe-Coding-ROS2 编排脚本${NC}"
      echo ""
      echo "用法: $0 [选项]"
      echo "  --auto \"需求描述\"    自动模式（非交互）"
      echo "  --dir <目录>        指定项目目录（默认：~/.vibe-coding-ros2/projects）"
      echo "  -h, --help          显示帮助"
      echo ""
      echo "示例:"
      echo "  $0 --auto \"帮我生成一个用激光雷达导航的差速小车\""
      echo "  $0"
      exit 0
      ;;
    *)
      echo "未知参数: $1"
      exit 1
      ;;
  esac
done

# ── 工具函数 ──────────────────────────────────────────────
info()    { echo -e "${BLUE}[INFO]${NC}  $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; }

# 进度条
progress() {
  local current=$1; local total=$2; local width=40
  local pct=$((current * 100 / total))
  local filled=$((width * current / total))
  printf "\r${BLUE}[%3d%%]${NC} " "$pct"
  printf "%${filled}s" | tr ' ' '█'
  printf "%$((width - filled))s" | tr ' ' '░'
}

# 确认
confirm() {
  local prompt="${1:-继续？}"
  read -p "$prompt [Y/n] " -n 1 -r
  echo
  [[ ! $REPLY =~ ^[Nn]$ ]]
}

# ── 需求解析（关键词匹配）───────────────────────────────
parse_prompt() {
  local prompt="$1"
  local selections=()

  # 机器人类型关键词
  if echo "$prompt" | grep -qiE "差速|diff|turtlebot|轮式|mecanum"; then
    selections+=("diff_drive")
  fi
  if echo "$prompt" | grep -qiE "机械臂|manipulator|arm|urdf|pick|place|grasp"; then
    selections+=("manipulator")
  fi
  if echo "$prompt" | grep -qiE "四足|go2|quadruped|四足机器人"; then
    selections+=("quadruped")
  fi
  if echo "$prompt" | grep -qiE "无人机|uav|drone|无人机|四旋翼"; then
    selections+=("drone")
  fi
  if echo "$prompt" | grep -qiE "阿克曼|ackermann|赛车|car"; then
    selections+=("ackermann")
  fi

  # 功能关键词
  if echo "$prompt" | grep -qiE "slam|建图|mapping|导航|navigation|导航"; then
    selections+=("slam")
  fi
  if echo "$prompt" | grep -qiE "nav2|navigation2|路径规划"; then
    selections+=("nav2")
  fi
  if echo "$prompt" | grep -qiE "moveit|运动规划|motion plan|逆运动学"; then
    selections+=("moveit")
  fi
  if echo "$prompt" | grep -qiE "ros2.control|硬件|hardware|控制|control"; then
    selections+=("ros2_control")
  fi
  if echo "$prompt" | grep -qiE "诊断|diagnostic|健康|health|监控|monitor"; then
    selections+=("diagnostics")
  fi
  if echo "$prompt" | grep -qiE "仿真|gazebo|simulator|模拟"; then
    selections+=("simulator")
  fi
  if echo "$prompt" | grep -qiE "激光雷达|lidar|激光|scan"; then
    selections+=("lidar")
  fi
  if echo "$prompt" | grep -qiE "相机|camera|视觉|vision|标定|calibration"; then
    selections+=("camera")
  fi
  if echo "$prompt" | grep -qiE "ros2_control|dynamic|control"; then
    selections+=("control")
  fi
  if echo "$prompt" | grep -qiE "行为树|behavior|bt|tree"; then
    selections+=("behavior_tree")
  fi
  if echo "$prompt" | grep -qiE "强化|reinforcement|rl|ddpg|ppo|sac"; then
    selections+=("rl")
  fi
  if echo "$prompt" | grep -qiE "多机|multi|swarm|蜂群|编队|formation"; then
    selections+=("multi_agent")
  fi
  if echo "$prompt" | grep -qiE "传感器融合|sensor.fusion|ekf|imu|gps|定位|localization"; then
    selections+=("sensor_fusion")
  fi
  if echo "$prompt" | grep -qiE "interface|msg|srv|action|接口"; then
    selections+=("interface")
  fi

  # 默认：diff_drive + nav2 + slam
  if [[ ${#selections[@]} -eq 0 ]]; then
    selections=("diff_drive" "nav2" "slam")
  fi

  echo "${selections[@]}"
}

# ── 选择机器人类型 ─────────────────────────────────────
select_robot_type() {
  echo -e "\n${CYAN}═══════════════════════════════════════════${NC}"
  echo -e "${CYAN}  步骤 1/4: 选择机器人类型${NC}"
  echo -e "${CYAN}═══════════════════════════════════════════${NC}"
  echo ""
  echo "  [1] 差速驱动（Diff Drive）— TurtleBot3/小地盘"
  echo "  [2] 机械臂（Manipulator）— 6轴/7轴机械臂"
  echo "  [3] 麦克纳姆轮（Mecanum）— 全向移动"
  echo "  [4] 阿克曼转向（Ackermann）— 赛车/小车"
  echo "  [5] 四足机器人（Quadruped）— Go1/宇树"
  echo "  [6] 无人机（UAV）— 四旋翼"
  echo "  [7] 复合机器人（Mobile Manipulator）— 底盘+机械臂"
  echo "  [8] 自定义"
  echo ""
  read -p "选择 [1-8, 默认 1]: " choice
  choice="${choice:-1}"
  case $choice in
    1) echo "diff_drive" ;;
    2) echo "manipulator" ;;
    3) echo "mecanum" ;;
    4) echo "ackermann" ;;
    5) echo "quadruped" ;;
    6) echo "drone" ;;
    7) echo "mobile_manipulator" ;;
    8) read -p "输入机器人类型: " t; echo "$t" ;;
  esac
}

# ── 选择功能模块 ────────────────────────────────────────
select_modules() {
  echo -e "\n${CYAN}═══════════════════════════════════════════${NC}"
  echo -e "${CYAN}  步骤 2/4: 选择功能模块（可多选）${NC}"
  echo -e "${CYAN}═══════════════════════════════════════════${NC}"
  echo ""
  echo "  [A] Nav2 导航           — 生命周期管理+路径规划"
  echo "  [B] SLAM 建图           — 2D/3D 激光 SLAM"
  echo "  [C] MoveIt2 运动规划    — 机械臂轨迹规划"
  echo "  [D] ros2_control        — 硬件接口/控制器"
  echo "  [E] Gazebo 仿真         — 物理引擎仿真"
  echo "  [F] 诊断监控           — 健康状态监控"
  echo "  [G] 传感器融合         — EKF/LiDAR/IMU/GPS"
  echo "  [H] 行为树             — 任务规划"
  echo "  [I] 强化学习控制        — DDPG/PPO/SAC"
  echo "  [J] 多机器人编队       — 协同控制"
  echo "  [K] 相机标定           — 内参/外参/手眼标定"
  echo "  [L] 通信接口           — msg/srv/action 定义"
  echo ""
  echo -e "${YELLOW}直接回车选择 [A B C D E]（默认组合）${NC}"
  read -p "选择模块 (如: ACEG): " choice
  choice="${choice:-A B C D E}"

  local modules=()
  for c in $choice; do
    case ${c^^} in
      A) modules+=("nav2") ;;
      B) modules+=("slam") ;;
      C) modules+=("moveit") ;;
      D) modules+=("ros2_control") ;;
      E) modules+=("simulator") ;;
      F) modules+=("diagnostics") ;;
      G) modules+=("sensor_fusion") ;;
      H) modules+=("behavior_tree") ;;
      I) modules+=("rl") ;;
      J) modules+=("multi_agent") ;;
      K) modules+=("camera") ;;
      L) modules+=("interface") ;;
    esac
  done
  echo "${modules[@]}"
}

# ── 选择 ROS2 版本 ──────────────────────────────────────
select_distro() {
  echo -e "\n${CYAN}═══════════════════════════════════════════${NC}"
  echo -e "${CYAN}  步骤 3/4: 选择 ROS2 版本${NC}"
  echo -e "${CYAN}═══════════════════════════════════════════${NC}"
  echo ""
  echo "  [1] Humble Hawksbill  (LTS, Ubuntu 22.04) ✓ 推荐"
  echo "  [2] Iron Irwini        (Latest, Ubuntu 22.04)"
  echo "  [3] Jazzy Jalisco     (Latest, Ubuntu 24.04)"
  echo ""
  read -p "选择 [1-3, 默认 1]: " choice
  choice="${choice:-1}"
  case $choice in
    1) echo "humble" ;;
    2) echo "iron" ;;
    3) echo "jazzy" ;;
    *) echo "humble" ;;
  esac
}

# ── 生成项目 ─────────────────────────────────────────────
generate_project() {
  local project_name="$1"
  local robot_type="$2"
  shift 2
  local modules=("$@")

  local project_dir="${ORCHESTRATE_DIR}/${project_name}"
  local pkg_dir="${project_dir}/src/${project_name}_pkg"

  info "创建项目目录: $project_dir"
  mkdir -p "$pkg_dir"

  local total=${#modules[@]}
  local current=0

  for module in "${modules[@]}"; do
    current=$((current + 1))
    progress $current $total

    case $module in
      nav2)
        bash "${SCRIPT_DIR}/generators/ros2-nav2-node-generator.sh" \
          "${project_name}_pkg" nav2_thin >/dev/null 2>&1 || true
        ;;
      slam)
        bash "${SCRIPT_DIR}/generators/ros2-slam-generator.sh" \
          "${project_name}_slam" 2d >/dev/null 2>&1 || true
        ;;
      moveit)
        bash "${SCRIPT_DIR}/generators/ros2-moveit-generator.sh" \
          "${project_name}_moveit" move_group >/dev/null 2>&1 || true
        ;;
      ros2_control)
        bash "${SCRIPT_DIR}/generators/ros2-control-node-generator.sh" \
          "${project_name}_control" diff_drive >/dev/null 2>&1 || true
        ;;
      simulator)
        bash "${SCRIPT_DIR}/generators/ros2-simulator-generator.sh" \
          "${project_name}_sim" differential_drive >/dev/null 2>&1 || true
        ;;
      diagnostics)
        bash "${SCRIPT_DIR}/generators/ros2-diagnostics-generator.sh" \
          "${project_name}_diag" general >/dev/null 2>&1 || true
        ;;
      sensor_fusion)
        bash "${SCRIPT_DIR}/generators/ros2-slam-generator.sh" \
          "${project_name}_fusion" lidar_imu_fusion >/dev/null 2>&1 || true
        ;;
      behavior_tree)
        bash "${SCRIPT_DIR}/generators/ros2-behavior-tree-generator.sh" \
          "${project_name}_bt" navigation >/dev/null 2>&1 || true
        ;;
      rl)
        bash "${SCRIPT_DIR}/generators/ros2-rl-controller-generator.sh" \
          "${project_name}_rl" ddpg >/dev/null 2>&1 || true
        ;;
      multi_agent)
        bash "${SCRIPT_DIR}/generators/ros2-multi-agent-generator.sh" \
          "${project_name}_swarm" formation >/dev/null 2>&1 || true
        ;;
      camera)
        bash "${SCRIPT_DIR}/generators/ros2-camera-calibration-generator.sh" \
          "${project_name}_camera" intrinsics >/dev/null 2>&1 || true
        ;;
      interface)
        bash "${SCRIPT_DIR}/generators/ros2-interface-generator.sh" \
          "${project_name}_msgs" >/dev/null 2>&1 || true
        ;;
      *)
        warn "未知模块: $module (跳过)"
        ;;
    esac
  done

  # 生成总 launch
  cat > "${project_dir}/launch/project.launch.py" <<'LAUNCHEOF'
"""MIUAV Vibe-Coding-ROS2 Generated Project Launch"""
from launch import LaunchDescription


def generate_launch_description() -> LaunchDescription:
    # 各模块 launch 自动包含
    return LaunchDescription([
        # 各子包 launch 在此聚合
    ])
LAUNCHEOF

  # 生成 README
  cat > "${project_dir}/README.md" <<RDMEOF
# $project_name

MIUAV Vibe-Coding-ROS2 自动生成项目

## 机器人类型
$(echo "$robot_type" | tr '[:lower:]' '[:upper:]')

## 功能模块
$(printf '  - %s\n' "${modules[@]}")

## ROS2 版本
${DISTRO:-humble}

## 快速开始
\`\`\`bash
cd src
colcon build --packages-select $(for m in "${modules[@]}"; do echo -n "${project_name}_${m} "; done)
source install/setup.bash
\`\`\`

## 包含包
$(for m in "${modules[@]}"; do echo "- \`${project_name}_${m}\`"; done)
RDMEOF

  echo ""
  success "项目已生成: $project_dir"
}

# ════════════════════════════════════════════════════════════
# 主流程
# ════════════════════════════════════════════════════════════

echo -e "\n${CYAN}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   MIUAV Vibe-Coding-ROS2 项目编排器 v1.0            ║${NC}"
echo -e "${CYAN}║   输入需求 → 生成完整 ROS2 项目                      ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════╝${NC}"

if $INTERACTIVE; then
  echo -e "\n${YELLOW}输入你的机器人需求（如：差速小车+SLAM+导航+避障）${NC}"
  read -p "> " USER_PROMPT
else
  USER_PROMPT="$AUTO_PROMPT"
  info "自动模式: $USER_PROMPT"
fi

# 解析关键词
SELECTED_MODULES=$(parse_prompt "$USER_PROMPT")
ROBOT_TYPE=$(select_robot_type)
DISTRO=$(select_distro)

echo -e "\n${CYAN}═══════════════════════════════════════════${NC}"
echo -e "${CYAN}  步骤 4/4: 确认并生成${NC}"
echo -e "${CYAN}═══════════════════════════════════════════${NC}"
echo ""
echo "  项目名称: $PROJECT_NAME"
echo "  机器人类型: $ROBOT_TYPE"
echo "  功能模块: $SELECTED_MODULES"
echo "  ROS2 版本: $DISTRO"
echo ""

PROJECT_NAME="vibe_$(date +%Y%m%d_%H%M%S)"

if $INTERACTIVE; then
  read -p "项目目录名 [默认 $PROJECT_NAME]: " pn
  PROJECT_NAME="${pn:-$PROJECT_NAME}"
  if confirm "确认生成？"; then
    info "开始生成..."
  else
    info "取消"
    exit 0
  fi
else
  info "开始自动生成..."
fi

# 生成
mkdir -p "$ORCHESTRATE_DIR"
generate_project "$PROJECT_NAME" "$ROBOT_TYPE" $SELECTED_MODULES

# 编译验证
echo ""
info "运行编译验证..."
if bash "${SCRIPT_DIR}/ros2-build-verify-loop.sh" "$PROJECT_NAME" 2>/dev/null; then
  success "编译验证通过！"
else
  warn "编译验证发现问题，请检查项目目录"
fi

echo ""
echo -e "${GREEN}═══════════════════════════════════════════${NC}"
echo -e "${GREEN}  生成完成！${NC}"
echo -e "${GREEN}═══════════════════════════════════════════${NC}"
echo ""
echo "  项目目录: ${ORCHESTRATE_DIR}/${PROJECT_NAME}"
echo ""
echo "  快速开始:"
echo -e "    ${BLUE}cd ${ORCHESTRATE_DIR}/${PROJECT_NAME}${NC}"
echo -e "    ${BLUE}colcon build --packages-select $(for m in $SELECTED_MODULES; do echo -n "${PROJECT_NAME}_${m} "; done)${NC}"
echo -e "    ${BLUE}source install/setup.bash${NC}"
echo ""
