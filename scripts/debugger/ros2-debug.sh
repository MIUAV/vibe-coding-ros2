#!/bin/bash
# ros2-debug.sh — ROS2 常见错误自动诊断
# 用法: bash ros2-debug.sh [error_log_file]
# 示例: bash ros2-debug.sh build.log
# 示例: bash ros2-debug.sh  # 交互模式，粘贴错误日志

set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'

ERROR_LOG="${1:-}"

# ── 读取错误日志 ───────────────────────────────────────────
if [[ -n "$ERROR_LOG" && -f "$ERROR_LOG" ]]; then
    ERROR_CONTENT=$(cat "$ERROR_LOG")
elif [[ -t 0 ]]; then
    echo -e "${BLUE}=== ROS2 错误诊断 ===${NC}"
    echo "粘贴 colcon build 错误日志（Ctrl+D 结束输入）:"
    echo "---"
    ERROR_CONTENT=$(cat)
else
    ERROR_CONTENT=$(cat)
fi

if [[ -z "$ERROR_CONTENT" ]]; then
    echo -e "${RED}没有检测到错误内容${NC}"
    exit 1
fi

# ══════════════════════════════════════════════════════════════
# 诊断规则
# ══════════════════════════════════════════════════════════════

DIAGNOSED=false

# ── 1. CMake 依赖地狱 ─────────────────────────────────────
if echo "$ERROR_CONTENT" | grep -qE "(undefined reference|ld: cannot find|cannot find -l)"; then
    DIAGNOSED=true
    echo -e "\n${RED}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║ 1. CMake 依赖地狱                                          ║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}检测到链接错误。常见原因：${NC}"
    echo ""
    echo "  ① ament_export_dependencies 缺失（三行必须同时存在）"
    echo "  ② CMakeLists.txt 中 find_package 不完整"
    echo "  ③ 链接库顺序错误（依赖者在前，被依赖者在后）"
    echo ""

    # 提取具体的 undefined reference
    UNDEF=$(echo "$ERROR_CONTENT" | grep "undefined reference" | head -3)
    if [[ -n "$UNDEF" ]]; then
        echo -e "${CYAN}未定义符号:${NC}"
        echo "$UNDEF" | sed 's/^/  /'
        echo ""
    fi

    echo -e "${GREEN}快速修复：${NC}"
    echo "  在 CMakeLists.txt 末尾添加（如果缺失）："
    echo '  ament_export_dependencies(rclcpp)'
    echo '  ament_export_include_directories(include)'
    echo '  ament_export_libraries(\${PROJECT_NAME})'
    echo ""
    echo "  或检查 find_package 是否包含所有依赖："
    echo "  find_package(ament_cmake REQUIRED)"
    echo "  find_package(rclcpp REQUIRED)"
fi

# ── 2. QoS 静默失败 ───────────────────────────────────────
if echo "$ERROR_CONTENT" | grep -qE "(BEST_EFFORT|RELIABLE|QOS|quality of service)" || \
   echo "$ERROR_CONTENT" | grep -qE "(topic.*not.*connect|publish.*drop|subscribe.*miss)"; then
    echo -e "\n${YELLOW}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║ 2. QoS 配置错误                                            ║${NC}"
    echo -e "${YELLOW}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "  ROS2 QoS 不匹配会导致发布者-订阅者无法通信（静默失败）。"
    echo ""
    echo "  规则："
    echo "  • 控制命令（cmd_vel）→ RELIABLE"
    echo "  • 传感器数据（camera/laser）→ BEST_EFFORT"
    echo "  • Lifecycle 状态 → RELIABLE"
    echo ""
    echo "  修复示例："
    echo "  // 错误：BEST_EFFORT 用于控制命令"
    echo "  auto pub = create_publisher< geometry_msgs::msg::Twist >(\"cmd_vel\","
    echo "    rclcpp::SensorDataQoS());  // ❌"
    echo ""
    echo "  // 正确：RELIABLE 用于控制命令"
    echo "  auto pub = create_publisher< geometry_msgs::msg::Twist >(\"cmd_vel\","
    echo "    rclcpp::QoS(10).reliable());  // ✅"
fi

# ── 3. Lifecycle 状态机错误 ───────────────────────────────
if echo "$ERROR_CONTENT" | grep -qE "(LifecycleNode|lifecycle|cb_return|CallbackReturn)" || \
   echo "$ERROR_CONTENT" | grep -qE "(transition.*fail|state.*invalid|cannot.*activate)"; then
    echo -e "\n${YELLOW}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║ 3. Lifecycle 状态机错误                                      ║${NC}"
    echo -e "${YELLOW}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "  LifecycleNode 必须按严格顺序转换状态："
    echo "  UNCONFIGURED → Inactive → Active → Finalized"
    echo ""
    echo "  常见错误："
    echo "  • 在 on_configure 返回 SUCCESS 前创建 timer（timer 在 Inactive 不能运行）"
    echo "  • publisher 在 on_activate 后才调用 on_activate()"
    echo "  • 在 on_cleanup 之外 reset() publisher"
    echo ""
    echo "  调试命令："
    echo "  ros2 lifecycle list /node_name  # 查看当前状态"
    echo "  ros2 lifecycle set /node_name configure  # 触发状态转换"
fi

# ── 4. 头文件缺失 ─────────────────────────────────────────
if echo "$ERROR_CONTENT" | grep -qE "(fatal error:|No such file or directory.*\.h|\.hpp.*not found)"; then
    echo -e "\n${YELLOW}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║ 4. 头文件缺失                                               ║${NC}"
    echo -e "${YELLOW}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    MISSING_H=$(echo "$ERROR_CONTENT" | grep -oE "[a-zA-Z_/]+\.h[p]*" | sort -u | head -5)
    if [[ -n "$MISSING_H" ]]; then
        echo "缺失的头文件："
        echo "$MISSING_H" | sed 's/^/  /'
        echo ""
        echo "可能的依赖包："
        echo "$MISSING_H" | while read h; do
            case "$h" in
                *rclcpp*) echo "  $h → apt install ros-${ROS_DISTRO:-humble}-rclcpp ;;
                *geometry_msgs*) echo "  $h → apt install ros-${ROS_DISTRO:-humble}-geometry-msgs ;;
                *std_msgs*) echo "  $h → apt install ros-${ROS_DISTRO:-humble}-std-msgs ;;
                *sensor_msgs*) echo "  $h → apt install ros-${ROS_DISTRO:-humble}-sensor-msgs ;;
                *) echo "  $h → 需要手动查找所属包";;
            esac
        done
    fi
fi

# ── 5. 内存错误 ────────────────────────────────────────────
if echo "$ERROR_CONTENT" | grep -qE "(segmentation fault|SIGSEGV|SIGABRT|abort|core dumped|heap.*overflow|use-after-free)"; then
    echo -e "\n${RED}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║ 5. 内存错误（严重）                                          ║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "  可能原因："
    echo "  • shared_ptr 使用不当（use-after-free）"
    echo "  • vector/map 访问越界"
    echo "  • 线程安全问题（数据竞争）"
    echo ""
    echo "  调试方法："
    echo "  1. 用 ASAN 重新编译："
    echo "     CXXFLAGS=\"-fsanitize=address\" colcon build --packages-select PKG"
    echo "  2. 运行节点复现错误："
    echo "     ros2 run PKG NODE_NAME"
    echo "  3. 查看 ASAN 输出定位错误"
fi

# ── 6. 死锁 / 数据竞争 ─────────────────────────────────────
if echo "$ERROR_CONTENT" | grep -qE "(deadlock|mutex|lock.*inversion|deadlock.*detect|spin.*hang|futex)" || \
   echo "$ERROR_CONTENT" | grep -qE "(hang|stuck|timeout)"; then
    echo -e "\n${RED}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║ 6. 死锁 / 线程挂起                                            ║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "  检查："
    echo "  ① Mutex 是否按固定顺序获取（多锁时容易死锁）"
    echo "  ② Timer 回调是否持有锁时间过长"
    echo "  ③ spin() 是否在主线程（rclcpp::executors::MultiThreadedExecutor）"
    echo ""
    echo "  诊断命令："
    echo "  ros2 run rqt_graph rqt_graph  # 查看节点连接"
    echo "  ros2 run rqt_console rqt_console  # 查看日志"
fi

# ── 7. colcon build 特定错误 ───────────────────────────────
if echo "$ERROR_CONTENT" | grep -qE "(colcon build|ament_cmake|cmake.*error)"; then
    echo -e "\n${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║ 7. 编译系统错误                                               ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "  常见原因："
    echo "  ① build_depend vs exec_depend 混淆"
    echo "  ② ament_export_dependencies 缺少某些依赖"
    echo "  ③ament_python 包缺少 setup.py"
    echo ""
    echo "  诊断命令："
    echo "  colcon build --packages-select PKG --cmake-clean-cache --event-handlers console_direct+"
    echo "  source /opt/ros/${ROS_DISTRO:-humble}/setup.bash"
fi

# ── 8. 无具体匹配 ─────────────────────────────────────────
if [[ "$DIAGNOSED" == "false" ]]; then
    echo -e "\n${YELLOW}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║ 未知错误                                                     ║${NC}"
    echo -e "${YELLOW}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "  未能自动诊断。请："
    echo "  1. 粘贴完整错误信息到 ROS2 社区搜索"
    echo "  2. 检查是否是多个独立错误叠加"
    echo ""
    echo "  常见工具："
    echo "  ros2 doctor --verbose  # 系统级诊断"
    echo "  ros2 pkg list  # 确认包已安装"
fi

# ── 通用建议 ───────────────────────────────────────────────
echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║ 通用调试流程                                                 ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "  Step 1: colcon build --packages-select PKG --cmake-clean-cache 2>&1 | tee build.log"
echo "  Step 2: bash ros2-debug.sh build.log"
echo "  Step 3: ros2 run PKG NODE --ros-args --log-level debug 2>&1 | tee run.log"
echo "  Step 4: ros2 doctor --verbose"
echo ""
echo "  LLM 修复：将 build.log 完整内容发给 LLM（GPT-4/Claude）"
