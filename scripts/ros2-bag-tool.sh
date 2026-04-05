#!/bin/bash
# ros2-bag-tool.sh — ROS2 Bag 录制与回放工具
# 用法:
#   ./ros2-bag-tool.sh record <topic1,topic2> [output_name]
#   ./ros2-bag-tool.sh play <bag_dir> [--loop]
#   ./ros2-bag-tool.sh info <bag_dir>

set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

CMD="${1:-}"
TOPICS="${2:-}"
BAG_NAME="${3:-}"

BAG_DIR="${HOME}/ros2_bags/$(date +%Y%m%d_%H%M%S)"

mkdir -p "$BAG_DIR"

case "$CMD" in
  record)
    if [ -z "$TOPICS" ]; then
      echo -e "${RED}用法: $0 record <topic1,topic2> [output_name]${NC}"
      echo "  例: $0 record /scan,/cmd_vel my_bag"
      exit 1
    fi

    # 转换逗号为空格
    TOPICS_SPACE="${TOPICS//,/ }"

    if [ -n "$BAG_NAME" ]; then
      BAG_PATH="${BAG_DIR}/${BAG_NAME}"
    else
      BAG_PATH="${BAG_DIR}/recording_$(date +%H%M%S)"
    fi

    echo -e "${BLUE}=== ROS2 Bag 录制 ===${NC}"
    echo -e "Topics: $TOPICS_SPACE"
    echo -e "Output: $BAG_PATH"
    echo -e "${YELLOW}按 Ctrl+C 停止录制${NC}"
    echo ""

    ros2 bag record -o "$BAG_PATH" $TOPICS_SPACE
    ;;

  play)
    BAG_PATH="$TOPICS"  # 第二个参数是路径
    if [ ! -d "$BAG_PATH" ]; then
      echo -e "${RED}Bag 目录不存在: $BAG_PATH${NC}"
      echo "可用 bags:"
      ls "$HOME"/ros2_bags/*/ 2>/dev/null | head -10
      exit 1
    fi

    echo -e "${BLUE}=== ROS2 Bag 回放: $BAG_PATH ===${NC}"
    ros2 bag play "$BAG_PATH" ${@:4}
    ;;

  info)
    BAG_PATH="$TOPICS"
    if [ ! -d "$BAG_PATH" ]; then
      echo -e "${RED}Bag 目录不存在: $BAG_PATH${NC}"
      exit 1
    fi

    echo -e "${BLUE}=== Bag 信息: $BAG_PATH ===${NC}"
    ros2 bag info "$BAG_PATH"
    ;;

  list)
    echo -e "${BLUE}=== 已录制的 Bags ===${NC}"
    if [ -d "$HOME/ros2_bags" ]; then
      find "$HOME/ros2_bags" -maxdepth 2 -name "*.db3" -o -name "*.mcv" 2>/dev/null | head -20 | while read f; do
        BAG_DIR=$(dirname "$f")
        SIZE=$(du -sh "$BAG_DIR" 2>/dev/null | cut -f1)
        echo -e "  ${GREEN}$BAG_DIR${NC} ($SIZE)"
        ros2 bag info "$BAG_DIR" 2>/dev/null | grep -E "Topics|Duration" | sed 's/^/    /'
      done
    else
      echo "  没有录制的 bag"
    fi
    ;;

  *)
    echo -e "${BLUE}=== ROS2 Bag 工具 ===${NC}"
    echo ""
    echo "用法:"
    echo "  $0 record <topics> [name]   # 录制话题"
    echo "  $0 play <bag_path> [opts]   # 回放"
    echo "  $0 info <bag_path>          # 查看信息"
    echo "  $0 list                     # 列出已录制的 bag"
    echo ""
    echo "示例:"
    echo "  $0 record /scan,/cmd_vel,/odom              # 录制多个话题"
    echo "  $0 play ~/ros2_bags/20260405/my_recording  # 回放"
    echo "  $0 info ~/ros2_bags/20260405/my_recording  # 查看"
    echo ""
    echo "默认保存目录: ~/ros2_bags/"
    ;;
esac
