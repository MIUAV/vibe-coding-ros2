#!/bin/bash
# ros-mcp-integration.sh — 启动 ROS-MCP Server 让 AI Agent 获取真实 ROS2 运行时上下文
# 用法: bash ros-mcp-integration.sh [--check]
# AI Agent 通过此脚本获取: ros2 topic list, ros2 pkg list, colcon info 等实时信息

set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

# ── 检测 ROS2 环境 ───────────────────────────
detect_ros2() {
    if [[ -n "$ROS_DISTRO" ]]; then
        echo -e "${GREEN}✓ 检测到 ROS2: $ROS_DISTRO${NC}"
        return 0
    fi
    
    for distro in humble iron rolling galactic foxy; do
        if [[ -f "/opt/ros/$distro/setup.bash" ]]; then
            echo -e "${GREEN}✓ 发现 ROS2: $distro${NC}"
            source "/opt/ros/$distro/setup.bash"
            return 0
        fi
    done
    
    echo -e "${RED}✗ 未检测到 ROS2 安装${NC}"
    return 1
}

# ── MCP Server 检查 ───────────────────────────
check_mcp_server() {
    echo -e "${GREEN}=== ROS2 MCP 集成检查 ===${NC}"
    
    # 检查 ros-mcp-server 是否安装
    if command -v ros-mcp-server &>/dev/null; then
        echo -e "${GREEN}✓ ros-mcp-server 已安装${NC}"
        ROS_MCP_CMD="ros-mcp-server"
    elif [[ -d "/opt/ros-mcp" ]]; then
        echo -e "${GREEN}✓ ros-mcp-server 在 /opt/ros-mcp${NC}"
        ROS_MCP_CMD="/opt/ros-mcp/bin/ros-mcp-server"
    else
        echo -e "${YELLOW}! ros-mcp-server 未安装${NC}"
        echo "  安装方法:"
        echo "    git clone https://github.com/robotmcp/ros-mcp-server.git"
        echo "    cd ros-mcp-server && pip install -e ."
        echo "    或参考: https://github.com/robotmcp/ros-mcp-server"
        ROS_MCP_CMD=""
    fi
    
    # 检查 MCP 可用工具
    echo ""
    echo "MCP 可用工具（供 AI Agent 使用）："
    echo "  - ros2_topic_list      → ros2 topic list"
    echo "  - ros2_topic_info      → ros2 topic info <name>"
    echo "  - ros2_pkg_list        → ros2 pkg list"
    echo "  - ros2_node_list       → ros2 node list"
    echo "  - ros2_param_list     → ros2 param list"
    echo "  - colcon_info         → colcon info"
    echo "  - ros2_lifecycle_list  → ros2 lifecycle list"
    
    echo ""
    echo "AI Agent 使用示例："
    echo '  ./scripts/mcp/mcp-agent-orchestrator.sh go2-scurve \'
    echo '    --mcp-tools "ros2_topic_list,ros2_pkg_list,colcon_info" \'
    echo '    --agent claude'
    
    [[ -n "$ROS_MCP_CMD" ]] && return 0 || return 1
}

# ── 启动 MCP Server（后台）───────────────────
start_mcp_server() {
    detect_ros2 || exit 1
    
    if [[ -z "$ROS_MCP_CMD" ]]; then
        echo -e "${RED}✗ 无法启动 MCP Server（未安装）${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}启动 ros-mcp-server...${NC}"
    $ROS_MCP_CMD &
    MCP_PID=$!
    echo $MCP_PID > /tmp/ros-mcp-server.pid
    echo -e "${GREEN}✓ MCP Server 已启动 (PID: $MCP_PID)${NC}"
    echo "  PID 文件: /tmp/ros-mcp-server.pid"
    echo "  停止: kill \$(cat /tmp/ros-mcp-server.pid)"
}

# ── 验证 MCP 工具可用 ─────────────────────────
verify_mcp_tools() {
    echo -e "${GREEN}=== 验证 MCP 工具 ===${NC}"
    
    echo "1. ros2 topic list:"
    ros2 topic list | head -5
    echo "   ... (共 \$(ros2 topic list | wc -l) 个话题)"
    
    echo ""
    echo "2. ros2 pkg list:"
    ros2 pkg list | head -5
    echo "   ... (共 \$(ros2 pkg list | wc -l) 个包)"
    
    echo ""
    echo "3. ros2 node list:"
    ros2 node list
    
    echo ""
    echo "MCP 工具验证完成。AI Agent 现在可以通过 MCP 获取真实 ROS2 上下文。"
}

# ── 主逻辑 ───────────────────────────────────
case "${1:-}" in
    --check)
        check_mcp_server
        ;;
    --start)
        start_mcp_server
        ;;
    --verify)
        detect_ros2 || exit 1
        check_mcp_server
        verify_mcp_tools
        ;;
    *)
        echo "用法: $0 <--check|--start|--verify>"
        echo "  --check   : 检查 MCP Server 安装状态"
        echo "  --start   : 启动 MCP Server (后台)"
        echo "  --verify  : 验证 MCP 工具可用性"
        echo ""
        check_mcp_server
        ;;
esac
