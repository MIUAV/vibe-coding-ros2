#!/bin/bash
# auto-switch.sh — Memory-Bank 自动切换脚本
# 用途：根据上下文关键词自动选择并激活对应的 memory-bank 模板
# 用法: bash agents/memory-bank/templates/auto-switch.sh <描述文本>
# 示例: bash agents/memory-bank/templates/auto-switch.sh "我想做一个无人机导航包"

set -e

MEMORY_BANK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATES_DIR="$MEMORY_BANK_ROOT/templates"
ACTIVE_CONTEXT="$MEMORY_BANK_ROOT/active-context.md"

INPUT="${1:-}"

# ── 机器人类型检测 ──────────────────────────────
detect_robot() {
  local text="$1"
  case "$text" in
    *无人机*|*uav*|*drone*|*multirotor*|*px4*|*mavros*) echo "multi-rotor-uav" ;;
    *wheeled*|*轮式*|*差速*|*ackermann*|*car-like*) echo "wheeled-vehicle" ;;
    *quadruped*|*四足*|*go2*|*anybot*|*spot*) echo "quadruped" ;;
    *manipulator*|*机械臂*|*arm*|*抓取*|*grasp*) echo "manipulator" ;;
    *humanoid*|*人形*|*双足*|*biped*) echo "humanoid" ;;
    *underwater*|*auv*|*rov*|*水下*|*潜艇*) echo "underwater" ;;
    *multi-robot*|*多机*|*编队*|*swarm*) echo "multi-robot" ;;
    *) echo "" ;;
  esac
}

# ── 任务类型检测 ──────────────────────────────
detect_task() {
  local text="$1"
  case "$text" in
    *导航*|*nav2*|*path*|*路径*|*planning*) echo "navigation" ;;
    *感知*|*检测*|*yolo*|*segment*|*目标识别*) echo "perception" ;;
    *控制*|*控制*|*trajectory*|*轨迹*|*pid*|*mpc*) echo "motion-control" ;;
    *仿真*|*gazebo*|*simulator*|*数字孪生*) echo "simulation" ;;
    *多机*|*编队*|*formation*|*swarm*) echo "multi-agent" ;;
    *强化学习*|*reinforcement*|*rl*|*ddpg*|*ppo*) echo "reinforcement-learning" ;;
    *slam*|*建图*|*mapping*|*localization*) echo "slam-mapping" ;;
    *) echo "" ;;
  esac
}

# ── 开发阶段检测 ──────────────────────────────
detect_phase() {
  local text="$1"
  case "$text" in
    *需求*|*功能定义*|*要做什么*|*需求分析*) echo "1-requirements" ;;
    *架构*|*接口定义*|*模块划分*|*设计*) echo "2-architecture" ;;
    *生成包*|*骨架*|*从零开始*|*原型*) echo "3-prototyping" ;;
    *实现*|*写代码*|*节点逻辑*|*开发*) echo "4-implementation" ;;
    *联调*|*集成*|*仿真验证*|*测试*) echo "5-integration" ;;
    *部署*|*上线*|*运行*|*交付*) echo "6-deployment" ;;
    *) echo "" ;;
  esac
}

# ── 主逻辑 ──────────────────────────────────
echo "=== Memory-Bank Auto-Switch ==="
echo "Input: $INPUT"
echo

ROBOT=$(detect_robot "$INPUT")
TASK=$(detect_task "$INPUT")
PHASE=$(detect_phase "$INPUT")

CONTEXT=""

# 加载对应的机器人模板
if [[ -n "$ROBOT" ]]; then
  ROBOT_FILE="$TEMPLATES_DIR/robot-type/_ROBOT_TYPE_PROMPT.md"
  if [[ -f "$ROBOT_FILE" ]]; then
    echo "[Robot] Detected: $ROBOT → loading robot-type template"
    ROBOT_CONTENT=$(sed -n "/## $ROBOT.md/,/^---/p" "$ROBOT_FILE" 2>/dev/null | head -1)
    # 直接读取对应文件
    ROBOT_MD="$TEMPLATES_DIR/robot-type/$ROBOT.md"
    if [[ -f "$ROBOT_MD" ]]; then
      echo "  → $ROBOT_MD"
    fi
  fi
fi

# 加载对应的任务模板
if [[ -n "$TASK" ]]; then
  TASK_MD="$TEMPLATES_DIR/task-type/$TASK.md"
  if [[ -f "$TASK_MD" ]]; then
    echo "[Task] Detected: $TASK → $TASK_MD"
  fi
fi

# 加载对应的阶段模板
if [[ -n "$PHASE" ]]; then
  PHASE_MD="$TEMPLATES_DIR/phase/$PHASE.md"
  if [[ -f "$PHASE_MD" ]]; then
    echo "[Phase] Detected: $PHASE → $PHASE_MD"
  fi
fi

echo
echo "=== Available Templates ==="
echo
echo "Robot-Type:"
ls "$TEMPLATES_DIR/robot-type/" 2>/dev/null | grep -v '^_'
echo
echo "Task-Type:"
ls "$TEMPLATES_DIR/task-type/" 2>/dev/null | grep -v '^_'
echo
echo "Phase:"
ls "$TEMPLATES_DIR/phase/" 2>/dev/null | grep -v '^_'

echo
echo "=== Manual Switch ==="
echo "复制对应模板内容到: $ACTIVE_CONTEXT"
echo "例: cp $TEMPLATES_DIR/robot-type/wheeled-vehicle.md $ACTIVE_CONTEXT"
