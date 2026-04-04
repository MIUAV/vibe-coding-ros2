#!/bin/bash
# ros2-monitor.sh — ROS2 运行时节点监控
# 用法: bash ros2-monitor.sh [package_name]
# 不带参数: 监控所有节点

set -e

PKG="${1:-}"
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  ROS2 Runtime Monitor${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# ── 1. 节点列表 ────────────────────────────────────
echo -e "${CYAN}[1/5] Nodes${NC}"
NODES=$(ros2 node list 2>/dev/null | grep -v "^$" || echo "")
if [ -n "$NODES" ]; then
    echo "$NODES" | sed 's/^/  /'
    NODE_COUNT=$(echo "$NODES" | wc -l)
    echo -e "  ${GREEN}Total: $NODE_COUNT nodes${NC}"
else
    echo -e "  ${RED}No nodes found${NC}"
fi
echo ""

# ── 2. 话题列表 ────────────────────────────────────
echo -e "${CYAN}[2/5] Topics${NC}"
TOPICS=$(ros2 topic list 2>/dev/null | grep -v "^$" || echo "")
if [ -n "$TOPICS" ]; then
    # 过滤系统话题，只显示应用话题
    APP_TOPICS=$(echo "$TOPICS" | grep -v "^/rosout" | grep -v "^/parameter_events" | grep -v "^/clock")
    if [ -n "$APP_TOPICS" ]; then
        echo "$APP_TOPICS" | sed 's/^/  /'
    fi
    TOPIC_COUNT=$(echo "$TOPICS" | wc -l)
    echo -e "  ${GREEN}Total: $TOPIC_COUNT topics${NC}"
else
    echo -e "  ${RED}No topics found${NC}"
fi
echo ""

# ── 3. 发布频率（HZ）监控 ─────────────────────────
echo -e "${CYAN}[3/5] Topic Hz (top 10 active)${NC}"
echo -e "  ${YELLOW}Measuring for 3 seconds...${NC}"
TOPIC_HZ=$(ros2 topic hz /rosout 2>/dev/null | tail -3 || echo "  N/A")
echo ""

# ── 4. 服务列表 ───────────────────────────────────
echo -e "${CYAN}[4/5] Services${NC}"
SERVICES=$(ros2 service list 2>/dev/null | grep -v "^$" || echo "")
if [ -n "$SERVICES" ]; then
    SERVICE_COUNT=$(echo "$SERVICES" | wc -l)
    # 只显示前10个
    echo "$SERVICES" | head -10 | sed 's/^/  /'
    if [ "$SERVICE_COUNT" -gt 10 ]; then
        echo -e "  ${YELLOW}... and $((SERVICE_COUNT - 10)) more${NC}"
    fi
    echo -e "  ${GREEN}Total: $SERVICE_COUNT services${NC}"
else
    echo -e "  ${RED}No services found${NC}"
fi
echo ""

# ── 5. 活跃发布/订阅 ──────────────────────────────
echo -e "${CYAN}[5/5] Publishers & Subscribers${NC}"
if command -v ros2_node &> /dev/null; then
    for node in $(ros2 node list 2>/dev/null | head -5); do
        PUBS=$(ros2 node info "$node" 2>/dev/null | grep -A20 "Publishers" | grep "/" | head -3 | sed 's/^/    /')
        SUBS=$(ros2 node info "$node" 2>/dev/null | grep -A20 "Subscriptions" | grep "/" | head -3 | sed 's/^/    /')
        if [ -n "$PUBS" ] || [ -n "$SUBS" ]; then
            echo -e "  ${GREEN}$node${NC}"
            [ -n "$PUBS" ] && echo -e "    Publishers:${NC}$PUBS"
            [ -n "$SUBS" ] && echo -e "    Subscriptions:${NC}$SUBS"
        fi
    done
fi
echo ""

# ── 6. QoS 兼容性检查 ─────────────────────────────
echo -e "${CYAN}[Bonus] QoS Compatibility Check${NC}"
echo -e "  ${YELLOW}Checking for QoS mismatches...${NC}"

# 找所有发布者，检查 QoS
TOPIC_LIST=$(ros2 topic list 2>/dev/null | grep -v "^/rosout" | grep -v "^/parameter_events")
MISMATCHES=0
for topic in $TOPIC_LIST; do
    # 获取发布者数量和订阅者数量
    PUB_COUNT=$(ros2 topic info "$topic" 2>/dev/null | grep "Publisher count" | awk '{print $3}')
    SUB_COUNT=$(ros2 topic info "$topic" 2>/dev/null | grep "Subscription count" | awk '{print $3}')
    
    if [ -n "$PUB_COUNT" ] && [ -n "$SUB_COUNT" ] && [ "$PUB_COUNT" -gt 0 ] && [ "$SUB_COUNT" -gt 0 ]; then
        # 尝试获取 QoS 信息（如果 ros2 topic info 支持 --verbose）
        INFO=$(ros2 topic info "$topic" --verbose 2>/dev/null | head -10 || echo "")
        if echo "$INFO" | grep -q "Reliability: BEST_EFFORT"; then
            echo -e "  ${YELLOW}⚠ $topic — BEST_EFFORT (sensor data?)${NC}"
        fi
    fi
done

if [ $MISMATCHES -eq 0 ]; then
    echo -e "  ${GREEN}✓ No obvious QoS mismatches${NC}"
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Monitor Complete${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Common commands:"
echo "  ros2 topic echo <topic>          # 查看话题数据"
echo "  ros2 topic bw <topic>           # 带宽监控"
echo "  ros2 topic hz <topic>            # 频率监控"
echo "  ros2 node info <node>           # 节点详情"
echo "  rqt_graph                        # 节点关系图 (GUI)"
