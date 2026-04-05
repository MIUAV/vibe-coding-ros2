#!/bin/bash
# ros2-bag-analyzer.sh — ROS2 Bag 日志分析工具
# 用法: bash ros2-bag-analyzer.sh <bag_dir> [--report]
# 示例: bash ros2-bag-analyzer.sh ./ros2bag_2026-04-05_15-30-00 --report

set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

BAG_DIR="${1:-}"
REPORT_MODE="${2:-}"

if [[ -z "$BAG_DIR" ]]; then
    echo -e "${RED}用法: $0 <bag_dir> [--report]${NC}"
    echo "  bag_dir: ros2 bag 目录（包含 metadata.yaml）"
    echo "  --report: 输出 JSON 格式报告"
    exit 1
fi

if [[ ! -d "$BAG_DIR" ]]; then
    echo -e "${RED}目录不存在: $BAG_DIR${NC}"
    exit 1
fi

METADATA="$BAG_DIR/metadata.yaml"
if [[ ! -f "$METADATA" ]]; then
    echo -e "${RED}不是有效的 ros2 bag（缺少 metadata.yaml）${NC}"
    exit 1
fi

echo -e "${BLUE}=== ROS2 Bag 分析: $BAG_DIR ===${NC}"
echo ""

# ── 1. 基本信息 ─────────────────────────────────────────
echo "1. 录制信息"
echo "---"
DURATION=$(grep "^duration:" "$METADATA" | awk '{print $2}')
START_TIME=$(grep "^start_time:" "$METADATA" | awk '{print $2}')
END_TIME=$(grep "^end_time:" "$METADATA" | awk '{print $2}')
TOPIC_COUNT=$(grep "^topic_count:" "$METADATA" | awk '{print $2}')

echo "  录制时长: ${DURATION:-?}s"
echo "  Topic 数量: ${TOPIC_COUNT:-?}"
if [[ -n "$START_TIME" ]]; then
    START_HUMAN=$(date -d "@${START_TIME%.*}" 2>/dev/null | head -1 || echo "$START_TIME")
    echo "  开始时间: $START_HUMAN"
fi

# ── 2. Topic 列表 ────────────────────────────────────────
echo ""
echo "2. Topic 列表"
echo "---"
TOPICS=$(grep -A 1000 "^topics:" "$METADATA" | grep "^  -" | head -20)

if command -v ros2 &>/dev/null; then
    echo "  (使用 ros2 bag info 获取详细信息)"
    ros2 bag info "$BAG_DIR" 2>/dev/null | head -30 || true
fi

# ── 3. 消息频率分析 ───────────────────────────────────────
echo ""
echo "3. 消息频率分析"
echo "---"

# 从 metadata 提取各 topic 的消息数和频率
echo "  Topic 频率（估算）："
grep -A 500 "^topics:" "$METADATA" | grep "^    message_count:" | head -10
grep -A 500 "^topics:" "$METADATA" | grep "^    frequency:" | head -10

# ── 4. 文件大小 ─────────────────────────────────────────
echo ""
echo "4. 存储信息"
echo "---"
TOTAL_SIZE=$(du -sh "$BAG_DIR" 2>/dev/null | cut -f1)
echo "  总大小: ${TOTAL_SIZE:-?}"
FILE_COUNT=$(find "$BAG_DIR" -name "*.db3" -o -name "*.mcap" 2>/dev/null | wc -l)
echo "  数据文件: ${FILE_COUNT}"

# ── 5. 错误检测 ─────────────────────────────────────────
echo ""
echo "5. 错误模式检测"
echo "---"

ERROR_COUNT=0
WARN_COUNT=0

# 查找大文件（可能的数据问题）
BIG_FILES=$(find "$BAG_DIR" -name "*.db3" -size +1G 2>/dev/null | head -5)
if [[ -n "$BIG_FILES" ]]; then
    echo -e "  ${YELLOW}⚠ 发现大文件（>1GB），可能录制时内存溢出:${NC}"
    echo "$BIG_FILES" | sed 's/^/    /'
    ERROR_COUNT=$((ERROR_COUNT + 1))
fi

# 查找 topic 频率异常（< 1Hz 的传感器 topic 可能有问题）
LOW_FREQ=$(grep -A 500 "^topics:" "$METADATA" | awk '/frequency:/{freq=$2} /name:/{name=$2} freq>0 && freq<1{print "  " name " " freq " Hz"}' | head -10)
if [[ -n "$LOW_FREQ" ]]; then
    echo -e "  ${YELLOW}⚠ 低频 topic（<1Hz）:${NC}"
    echo "$LOW_FREQ"
    WARN_COUNT=$((WARN_COUNT + 1))
fi

# 检查是否有丢失消息的 topic
ZERO_FREQ=$(grep -A 500 "^topics:" "$METADATA" | awk '/frequency:/{freq=$2} name && freq==0{print "  " name " 0 Hz (inactive)"} /name:/{name=$2}' | head -10)
if [[ -n "$ZERO_FREQ" ]]; then
    echo -e "  ${RED}✗ 零频率 topic（无消息）:${NC}"
    echo "$ZERO_FREQ"
    ERROR_COUNT=$((ERROR_COUNT + 1))
fi

# ── 6. 诊断结论 ─────────────────────────────────────────
echo ""
echo "6. 诊断结论"
echo "---"
if [[ $ERROR_COUNT -eq 0 && $WARN_COUNT -eq 0 ]]; then
    echo -e "  ${GREEN}✓ Bag 正常，无明显错误${NC}"
else
    echo -e "  ${YELLOW}⚠ 发现 $WARN_COUNT 个警告，$ERROR_COUNT 个错误${NC}"
fi

# ── 7. 下一步建议 ───────────────────────────────────────
echo ""
echo "7. 分析建议"
echo "---"
echo "  播放 bag:"
echo "    ros2 bag play $BAG_DIR --remap /scan:=/scan_replay"
echo ""
echo "  查看特定 topic:"
echo "    ros2 bag play $BAG_DIR"
echo "    ros2 topic echo /scan"
echo ""
echo "  时间同步回放（按 timestamp）："
echo "    ros2 bag play $BAG_DIR --clock --rate 1.0"
echo ""
echo "  提取特定时间范围："
echo "    ros2 bag play $BAG_DIR --start 10 --duration 30"
echo ""
echo "  MCAP 格式（如有）："
echo "    ros2 bag info $BAG_DIR --mcap"
