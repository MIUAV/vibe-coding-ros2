#!/bin/bash
# ros2-node-validator.sh — 验证 ROS2 节点代码的 C++/QoS/指针安全
# 用法: bash ros2-node-validator.sh <node_file.cpp>
# 退出码: 0=通过, 1=有错误

set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

NODE_FILE="$1"
ERRORS=0; WARNINGS=0

info() { echo -e "${BLUE}[INFO]${NC}  $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC}  $1"; ((WARNINGS++)); }
err()  { echo -e "${RED}[ERR]${NC}   $1";  ((ERRORS++));   }
ok()   { echo -e "${GREEN}[PASS]${NC}  $1"; }

header() {
  echo ""
  echo -e "${BLUE}══════════════════════════════════════${NC}"
  echo -e "${BLUE}  ROS2 Node Validator — v0.0.1-beta${NC}"
  echo -e "${BLUE}══════════════════════════════════════${NC}"
  echo ""
}

validate_file() {
  local file="$1"

  if [[ ! -f "$file" ]]; then
    err "文件不存在: $file"
    return
  fi

  echo -e "检查文件: ${GREEN}$file${NC}"
  echo "──────────────────────────────────────"

  # ── 1. 智能指针检查 ────────────────────────────────
  echo -e "\n${BLUE}[1] 智能指针 / 裸指针${NC}"

  # 🚫 裸 new/delete
  if grep -qE '\bnew\s+\w+\s*\(' "$file"; then
    err "发现裸 new — 必须用 make_shared / make_unique"
    grep -nE '\bnew\s+\w+\s*\(' "$file" | sed 's/^/  /'
  else
    ok "无裸 new"
  fi

  if grep -qE '\bdelete\s+\w+' "$file"; then
    err "发现 delete — 禁止手动 delete"
  fi

  # ✅ make_shared / make_unique
  if grep -qE 'make_shared|make_unique' "$file"; then
    ok "使用智能指针"
  else
    warn "未找到 make_shared/make_unique（可能是纯头文件或模板）"
  fi

  # 🚫 裸指针类型（排除注释）
  if grep -vE '^\s*//' "$file" | grep -qE '\b\w+\*\s+(?!SharedPtr|WeakPtr)' ; then
    :
  fi

  # ── 2. QoS 检查 ───────────────────────────────────
  echo -e "\n${BLUE}[2] QoS 配置${NC}"

  if grep -qE 'QoS|qos_profile|best_effort|reliable|transient_local' "$file"; then
    ok "找到 QoS 配置"
  else
    warn "未找到 QoS 声明 — 检查是否为 sensor/cmd 类型"
  fi

  # 🚫 默认 QoS 用于传感器/命令（应该明确声明）
  if grep -qE 'create_subscription|create_publisher' "$file" && ! grep -qE 'QoS|qos' "$file"; then
    warn "发布/订阅未声明 QoS — 可能导致静默通信失败"
  fi

  # ── 3. rclcpp 初始化/关闭 ──────────────────────────
  echo -e "\n${BLUE}[3] rclcpp 生命周期${NC}"

  if grep -qE 'rclcpp::init' "$file"; then
    ok "rclcpp::init 存在"
  else
    err "缺少 rclcpp::init"
  fi

  if grep -qE 'rclcpp::shutdown' "$file"; then
    ok "rclcpp::shutdown 存在"
  else
    err "缺少 rclcpp::shutdown — 资源不会正确清理"
  fi

  # ── 4. Executor 检查 ──────────────────────────────
  echo -e "\n${BLUE}[4] Executor 并发模式${NC}"

  if grep -qE 'MultiThreadedExecutor' "$file"; then
    if grep -qE 'mutex|lock_guard|atomic' "$file"; then
      ok "MultiThreadedExecutor + 线程安全机制"
    else
      err "MultiThreadedExecutor 但无 Mutex/atomic — 线程不安全"
    fi
  elif grep -qE 'SingleThreadedExecutor|spin\(' "$file"; then
    ok "使用 SingleThreadedExecutor（安全模式）"
  fi

  # 🚫 危险：spin 后又加 executor
  if grep -qE 'rclcpp::spin' "$file" && grep -qE 'add_node|Executor' "$file"; then
    warn "spin() 和 executor.add_node() 混用 — 行为未定义"
  fi

  # ── 5. 回调中的危险操作 ────────────────────────────
  echo -e "\n${BLUE}[5] 回调安全${NC}"

  if grep -qE 'rclcpp::shutdown' "$file" | grep -qE 'callback|lambda' "$file"; then
    err "回调中调用 rclcpp::shutdown — 会导致死锁"
  fi

  if grep -qE 'sleep\(|usleep' "$file"; then
    warn "发现 sleep — 回调中 sleep 会阻塞主循环"
  fi

  # ── 6. Lifecycle 节点检查 ──────────────────────────
  echo -e "\n${BLUE}[6] Lifecycle 节点${NC}"

  if grep -qE 'LifecycleNode|lifecycle' "$file"; then
    for cb in on_configure on_activate on_deactivate on_cleanup; do
      if grep -qE "$cb" "$file"; then
        ok "发现 $cb"
      else
        err "Lifecycle 节点缺少 $cb 回调"
      fi
    done
  fi

  # ── 7. SharedPtr 循环引用 ──────────────────────────
  echo -e "\n${BLUE}[7] 循环引用检测${NC}"

  # 检测 mutual ownership（简化的启发式检查）
  if grep -qE 'std::shared_ptr' "$file"; then
    local shared_count=$(grep -cE 'std::shared_ptr' "$file" || echo 0)
    if [[ $shared_count -gt 1 ]]; then
      if ! grep -qE 'weak_ptr' "$file"; then
        warn "多个 shared_ptr 但无 weak_ptr — 可能有循环引用风险"
      fi
    fi
  fi

  # ── 8. 服务调用超时 ────────────────────────────────
  echo -e "\n${BLUE}[8] 服务调用${NC}"

  if grep -qE 'async_send_request|create_client' "$file"; then
    if grep -qE 'wait_for|timeout' "$file"; then
      ok "服务调用有超时保护"
    else
      warn "服务调用无超时 — 可能导致死锁"
    fi
  fi

  # ── 9. Launch 文件检查 ────────────────────────────
  echo -e "\n${BLUE}[9] Launch 文件检查${NC}"

  local launch_file="${file%.cpp}.launch.py"
  if [[ -f "$launch_file" ]]; then
    if grep -qE 'LaunchDescription' "$launch_file"; then
      ok "launch 文件包含 LaunchDescription"
    else
      err "launch 文件缺少 LaunchDescription"
    fi
  else
    warn "未找到 launch 文件: $launch_file"
  fi
}

summary() {
  echo ""
  echo "══════════════════════════════════════"
  echo -e "  结果: ${RED}$ERRORS 个错误${NC}, ${YELLOW}$WARNINGS 个警告${NC}"
  echo "══════════════════════════════════════"

  if [[ $ERRORS -gt 0 ]]; then
    echo -e "${RED}验证失败 — 代码不可靠${NC}"
  elif [[ $WARNINGS -gt 0 ]]; then
    echo -e "${YELLOW}有警告 — 建议修复${NC}"
  else
    echo -e "${GREEN}✓ 验证通过${NC}"
  fi

  return $ERRORS
}

# 主流程
if [[ -z "$NODE_FILE" ]]; then
  echo -e "${RED}用法: $0 <node_file.cpp>${NC}"
  echo ""
  echo "示例:"
  echo "  $0 src/my_robot_node.cpp"
  echo "  $0 examples/cpp/node.cpp"
  exit 1
fi

header
validate_file "$NODE_FILE"
summary
