#!/bin/bash
# ros2-debug.sh — ROS2 常见问题调试脚本
# 用法: bash ros2-debug.sh [check|topic|node|pkg|qos|all]
#
# 示例:
#   bash ros2-debug.sh check      # 环境检查
#   bash ros2-debug.sh topic      # 话题检查
#   bash ros2-debug.sh qos         # QoS 匹配检查
#   bash ros2-debug.sh all        # 全部检查

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

CMD="${1:-all}"

info()  { echo -e "${BLUE}[INFO]${NC}  $*"; }
ok()    { echo -e "${GREEN}✓${NC}  $*"; }
warn()  { echo -e "${YELLOW}WARN${NC}  $*"; }
err()   { echo -e "${RED}✗${NC}   $*"; }

header() {
  echo ""
  echo -e "${BLUE}═══════════════════════════════════════${NC}"
  echo -e "${BLUE}  ROS2 Debugger — v0.0.1-beta${NC}"
  echo -e "${BLUE}═══════════════════════════════════════${NC}"
}

# ── 1. 环境检查 ────────────────────────────────
check_env() {
  header
  echo -e "${BLUE}[1] 环境检查${NC}"
  echo "──────────────────────────────────────"

  # ROS2 安装检查
  if command -v ros2 &>/dev/null; then
    ok "ros2 CLI 已安装"
    ros2 --version 2>/dev/null | sed 's/^/  /'
  else
    err "ros2 CLI 未安装"
  fi

  # ROS_DOMAIN_ID
  DOMAIN=${ROS_DOMAIN_ID:-未设置}
  info "ROS_DOMAIN_ID: $DOMAIN"
  if [[ "$DOMAIN" == "未设置" ]]; then
    warn "ROS_DOMAIN_ID 未设置（默认 0），跨机器通信可能失败"
    echo "  修复: export ROS_DOMAIN_ID=42"
  fi

  # ROS_DISTRO
  if [[ -n "$ROS_DISTRO" ]]; then
    ok "ROS_DISTRO=$ROS_DISTRO"
  else
    warn "ROS_DISTRO 未设置"
  fi

  # colcon
  if command -v colcon &>/dev/null; then
    ok "colcon 已安装"
  else
    err "colcon 未安装"
  fi

  # source 检查
  if [[ -f "/opt/ros/humble/setup.bash" ]]; then
    ok "Humble 安装存在"
  elif [[ -f "/opt/ros/iron/setup.bash" ]]; then
    ok "Iron 安装存在"
  elif [[ -f "/opt/ros/jazzy/setup.bash" ]]; then
    ok "Jazzy 安装存在"
  else
    warn "未检测到标准 ROS2 安装"
  fi
}

# ── 2. 话题检查 ────────────────────────────────
check_topics() {
  header
  echo -e "${BLUE}[2] 话题检查${NC}"
  echo "──────────────────────────────────────"

  if ! command -v ros2 &>/dev/null; then
    err "ros2 CLI 不可用，跳过话题检查"
    return
  fi

  # 活跃话题
  echo -e "${BLUE}活跃话题:${NC}"
  ros2 topic list 2>/dev/null | sed 's/^/  /' || warn "无法获取话题列表（是否已 source？）"

  # 话题带宽
  echo ""
  echo -e "${BLUE}高带宽话题 (>1MB/s):${NC}"
  ros2 topic list 2>/dev/null | while read topic; do
    BW=$(ros2 topic bw "$topic" 2>/dev/null | grep "Average:" | awk '{print $2}')
    if [[ -n "$BW" ]]; then
      # 转换为 MB/s
      VAL=$(echo "$BW" | sed 's/ MB\/s//; s/ KB\/s//; s/ B\/s//')
      UNIT=$(echo "$BW" | grep -o "MB\|KB\|B")
      if [[ "$UNIT" == "MB" ]] || [[ ( "$UNIT" == "KB" && $(echo "$VAL > 1000" | bc -l 2>/dev/null || echo 0) -eq 1) ]]; then
        echo -e "  ${RED}$topic${NC}: $BW"
      fi
    fi
  done || true

  # 缺失 QoS 的发布者
  echo ""
  echo -e "${BLUE}检测 QoS 配置:${NC}"
  ros2 topic list 2>/dev/null | head -5 | while read topic; do
    INFO=$(ros2 topic info "$topic" 2>/dev/null | head -10)
    if echo "$INFO" | grep -q "Reliability"; then
      echo "  $topic"
      echo "$INFO" | sed 's/^/    /'
    fi
  done || warn "无法获取 QoS 信息"
}

# ── 3. 节点检查 ────────────────────────────────
check_nodes() {
  header
  echo -e "${BLUE}[3] 节点检查${NC}"
  echo "──────────────────────────────────────"

  if ! command -v ros2 &>/dev/null; then
    err "ros2 CLI 不可用"
    return
  fi

  echo -e "${BLUE}运行中的节点:${NC}"
  ros2 node list 2>/dev/null | sed 's/^/  /' || warn "无法获取节点列表"

  echo ""
  echo -e "${BLUE}节点信息:${NC}"
  ros2 node list 2>/dev/null | while read node; do
    echo "  $node"
    ros2 node info "$node" 2>/dev/null | grep -E "Subscriptions:|Publishers:|Services:" | sed 's/^/    /' | head -5
  done || true
}

# ── 4. 包检查 ─────────────────────────────────
check_pkg() {
  header
  echo -e "${BLUE}[4] 包检查${NC}"
  echo "──────────────────────────────────────"

  if ! command -v ros2 &>/dev/null; then
    err "ros2 CLI 不可用"
    return
  fi

  echo -e "${BLUE}已安装的相关包:${NC}"
  ros2 pkg list 2>/dev/null | grep -iE "control|navigation|perception|motion|robot" | sed 's/^/  /' | head -20

  echo ""
  echo -e "${BLUE}可执行文件:${NC}"
  ros2 pkg executables 2>/dev/null | grep -iE "control|navigation|perception" | sed 's/^/  /' | head -20
}

# ── 5. QoS 匹配检查 ───────────────────────────
check_qos() {
  header
  echo -e "${BLUE}[5] QoS 匹配检查${NC}"
  echo "──────────────────────────────────────"
  echo "提示: QoS 不匹配会导致静默通信失败（不报错，但无数据）"
  echo ""

  if ! command -v ros2 &>/dev/null; then
    err "ros2 CLI 不可用"
    return
  fi

  echo -e "${BLUE}所有话题的 QoS 概览:${NC}"
  for topic in $(ros2 topic list 2>/dev/null | head -10); do
    INFO=$(ros2 topic info "$topic" 2>/dev/null)
    REL=$(echo "$INFO" | grep "Reliability:" | awk '{print $2}')
    DUR=$(echo "$INFO" | grep "Durability:" | awk '{print $2}')
    echo "  $topic"
    echo "    Reliability: $REL | Durability: $DUR"
  done

  echo ""
  echo -e "${BLUE}常见 QoS 场景参考:${NC}"
  echo "  传感器(/scan, /image):  Reliability=best_effort, Durability=volatile"
  echo "  控制命令(/cmd_vel):      Reliability=reliable, Durability=volatile"
  echo "  地图/状态发布:           Reliability=reliable, Durability=transient_local"
  echo "  参数同步:                Reliability=reliable, Durability=transient_local"
}

# ── 6. 快速诊断 ────────────────────────────────
quick_diag() {
  header
  echo -e "${BLUE}[6] 快速诊断${NC}"
  echo "──────────────────────────────────────"

  echo "=== 编译问题 ==="
  if [[ -f "CMakeLists.txt" ]]; then
    grep -q "find_package(ament_cmake" CMakeLists.txt && ok "find_package(ament_cmake" || err "缺少 find_package(ament_cmake)"
    grep -q "ament_package()" CMakeLists.txt && ok "ament_package()" || err "缺少 ament_package()"
    grep -q "install(TARGETS" CMakeLists.txt && ok "install(TARGETS" || err "缺少 install(TARGETS)"
    grep -q "ament_target_dependencies" CMakeLists.txt && ok "ament_target_dependencies" || err "缺少 ament_target_dependencies"
  fi

  echo ""
  echo "=== package.xml ==="
  if [[ -f "package.xml" ]]; then
    grep -q 'format="3"' package.xml && ok "Format 3" || warn "未使用 Format 3"
    grep -q "<depend>rclcpp</depend>" package.xml && ok "rclcpp depend" || err "缺少 rclcpp depend"
    grep -q "ament_cmake" package.xml && ok "ament_cmake build_type" || warn "缺少 ament_cmake build_type"
  fi
}

# 主流程
case "$CMD" in
  check)  check_env ;;
  topic)  check_topics ;;
  node)   check_nodes ;;
  pkg)    check_pkg ;;
  qos)    check_qos ;;
  diag)   quick_diag ;;
  all)
    check_env
    check_topics
    check_nodes
    quick_diag
    echo ""
    echo "═══════════════════════════════════════"
    echo "  完整诊断完成"
    echo "  如需单项检查: ros2-debug.sh [check|topic|node|qos|diag]"
    ;;
  *) echo "用法: $0 [check|topic|node|pkg|qos|diag|all]"
     echo "  check  — 环境检查（ROS2 安装/DOMAIN_ID）"
     echo "  topic  — 话题 + QoS 检查"
     echo "  node   — 节点列表"
     echo "  pkg    — 包列表"
     echo "  qos    — QoS 匹配检查"
     echo "  diag   — CMakeLists.txt/package.xml 快速诊断"
     echo "  all    — 全部检查（默认）"
     ;;
esac
