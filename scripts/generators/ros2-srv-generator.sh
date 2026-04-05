#!/bin/bash
# ros2-srv-generator.sh — .srv / .action 文件生成向导
# 用法: bash ros2-srv-generator.sh
# 支持: .srv (请求/响应) 和 .action (Goal/Result/Feedback)

set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'

ask() {
    echo -ne "${CYAN}$1${NC}: "
    read "$2"
}

confirm() {
    echo -ne "${CYAN}$1${NC} [y/N]: "
    read ans
    [[ "$ans" =~ ^[yY]$ ]]
}

# ── 主流程 ───────────────────────────────────────────────
echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     ROS2 .srv / .action 文件生成向导                  ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

echo "类型选择："
echo "  1) .srv  （服务：请求 + 响应）"
echo "  2) .action（动作：Goal + Result + Feedback）"
echo -ne "${CYAN}选择类型${NC}: "
read type_choice

if [[ "$type_choice" == "2" ]]; then
    MODE="action"
else
    MODE="srv"
fi

# ── 基础信息 ───────────────────────────────────────────
ask "包名（输出目录）" PKG_NAME
ask "文件名（如 AddTwoInts、MoveArm）" FILE_NAME

FILE_NAME_CAP="$(tr '[:lower:]' '[:upper:]' <<< ${FILE_NAME:0:1})${FILE_NAME:1}"
DIR=""
if [[ -n "$PKG_NAME" ]]; then
    DIR="$PKG_NAME/srv"
    [[ "$MODE" == "action" ]] && DIR="$PKG_NAME/action"
    mkdir -p "$DIR"
fi

# ── 字段输入函数 ───────────────────────────────────────
input_fields() {
    local section="$1"
    local fields=()
    local count=0

    echo ""
    echo -e "${YELLOW}═══ $section（空字段名结束）═══${NC}"

    while true; do
        count=$((count + 1))
        echo ""
        echo "  --- 字段 $count ---"

        echo -ne "    字段名: "; read fname
        [[ -z "$fname" ]] && break

        echo "    类型选项:"
        echo "      1) builtin    (bool/int8/int16/float32/string...)"
        echo "      2) std_msgs   (String/Float64/PoseStamped...)"
        echo "      3) geometry_msgs (Twist/Pose/Vector3...)"
        echo "      4) sensor_msgs (LaserScan/Image/PointCloud2...)"
        echo "      5) 自定义     (如 my_pkg/MyMsg)"
        echo -ne "    选择: "; read tchoice

        case "$tchoice" in
            1) echo -ne "    builtin类型: "; read ftype ;;
            2) echo -ne "    std_msgs类型: "; read ftype ;;
            3) echo -ne "    geometry_msgs类型: "; read ftype ;;
            4) echo -ne "    sensor_msgs类型: "; read ftype ;;
            *) echo -ne "    自定义类型: "; read ftype ;;
        esac

        # 数组?
        array_suffix=""
        if confirm "    是否数组?"; then
            echo -ne "    固定大小? 数组长度（直接回车=动态数组）: "; read arrsize
            if [[ -n "$arrsize" ]]; then
                array_suffix="[$arrsize]"
            else
                array_suffix="[]"
            fi
        fi

        echo -ne "    描述（可选）: "; read fdesc
        [[ -n "$fdesc" ]] && fdesc="# $fdesc"

        full_def="${ftype}${array_suffix}  ${fname}"
        [[ -n "$fdesc" ]] && fields+=("$fdesc")
        fields+=("$full_def")
    done

    # 输出结果到调用者
    for item in "${fields[@]}"; do
        echo "$item"
    done
}

# ── 生成内容 ───────────────────────────────────────────
if [[ "$MODE" == "srv" ]]; then

    echo ""
    echo -e "${YELLOW}═══ 请求字段（--- 以上是请求，以下是响应 ---）═══${NC}"
    REQUEST_FIELDS=()
    RESPONSE_FIELDS=()
    IN_RESPONSE=0

    while true; do
        echo ""
        echo "--- 请求字段（空字段名结束，或输入 '---' 进入响应）---"
        echo -ne "  字段名: "; read fname

        if [[ "$fname" == "---" ]]; then
            IN_RESPONSE=1
            break
        fi
        [[ -z "$fname" ]] && break

        echo -ne "  类型: "; read ftype
        array_suffix=""
        if confirm "  数组?"; then
            echo -ne "  固定大小（回车=动态）: "; read arrsize
            array_suffix="[${arrsize:-}]"
        fi
        echo -ne "  描述: "; read fdesc
        [[ -n "$fdesc" ]] && fdesc="# $fdesc"

        full="${ftype}${array_suffix}  ${fname}"
        REQUEST_FIELDS+=("$fdesc")
        REQUEST_FIELDS+=("$full")
    done

    echo ""
    echo "--- 响应字段（空字段名结束）---"
    while true; do
        echo -ne "  字段名: "; read fname
        [[ -z "$fname" ]] && break

        echo -ne "  类型: "; read ftype
        array_suffix=""
        if confirm "  数组?"; then
            echo -ne "  固定大小（回车=动态）: "; read arrsize
            array_suffix="[${arrsize:-}]"
        fi
        echo -ne "  描述: "; read fdesc
        [[ -n "$fdesc" ]] && fdesc="# $fdesc"

        full="${ftype}${array_suffix}  ${fname}"
        RESPONSE_FIELDS+=("$fdesc")
        RESPONSE_FIELDS+=("$full")
    done

    # ── 写文件 ───────────────────────────────────────
    {
        echo "# ============================================================"
        echo "# 自动生成 by ros2-srv-generator.sh"
        echo "# ============================================================"
        echo ""
        for item in "${REQUEST_FIELDS[@]}"; do
            echo "$item"
        done
        echo ""
        echo "---"
        echo ""
        for item in "${RESPONSE_FIELDS[@]}"; do
            echo "$item"
        done
    } > "$DIR/${FILE_NAME_CAP}.srv"

    echo ""
    echo -e "${GREEN}✓ .srv 已生成: $DIR/${FILE_NAME_CAP}.srv${NC}"
    echo ""
    cat "$DIR/${FILE_NAME_CAP}.srv"

else
    # ── ACTION ───────────────────────────────────────
    GOAL_FIELDS=()
    FEEDBACK_FIELDS=()
    RESULT_FIELDS=()

    echo ""
    echo -e "${YELLOW}═══ Goal 字段（空字段名结束）═══${NC}"
    input_fields "Goal" | while read line; do GOAL_FIELDS+=("$line"); done 2>/dev/null

    # 用临时文件传递数组
    TMPGOAL=$(mktemp)
    TMPFB=$(mktemp)
    TMPRES=$(mktemp)

    echo ""
    echo -e "${YELLOW}═══ Goal 字段（空字段名结束）═══${NC}"
    while true; do
        echo -ne "  字段名: "; read fname
        [[ -z "$fname" ]] && break
        echo -ne "  类型: "; read ftype
        echo "$ftype  $fname" >> "$TMPGOAL"
    done

    echo ""
    echo -e "${YELLOW}═══ Result 字段（空字段名结束）═══${NC}"
    while true; do
        echo -ne "  字段名: "; read fname
        [[ -z "$fname" ]] && break
        echo -ne "  类型: "; read ftype
        echo "$ftype  $fname" >> "$TMPRES"
    done

    echo ""
    echo -e "${YELLOW}═══ Feedback 字段（空字段名结束）═══${NC}"
    while true; do
        echo -ne "  字段名: "; read fname
        [[ -z "$fname" ]] && break
        echo -ne "  类型: "; read ftype
        echo "$ftype  $fname" >> "$TMPFB"
    done

    {
        echo "# ============================================================"
        echo "# 自动生成 by ros2-srv-generator.sh"
        echo "# ============================================================"
        echo ""
        echo "---"
        echo "# Goal"
        cat "$TMPGOAL" 2>/dev/null || true
        echo ""
        echo "---"
        echo "# Result"
        cat "$TMPRES" 2>/dev/null || true
        echo ""
        echo "---"
        echo "# Feedback"
        cat "$TMPFB" 2>/dev/null || true
    } > "$DIR/${FILE_NAME_CAP}.action"

    rm -f "$TMPGOAL" "$TMPFB" "$TMPRES"

    echo ""
    echo -e "${GREEN}✓ .action 已生成: $DIR/${FILE_NAME_CAP}.action${NC}"
    echo ""
    cat "$DIR/${FILE_NAME_CAP}.action"
fi

echo ""
echo -e "${YELLOW}下一步：${NC}"
echo "  1. 将 .srv / .action 文件加入 CMakeLists.txt："
echo "     rosidl_generate_interfaces(\${PROJECT_NAME}"
echo "       srv/${FILE_NAME_CAP}.srv"
echo "       # 或 action/${FILE_NAME_CAP}.action"
echo "     )"
echo "  2. colcon build --packages-select $PKG_NAME"
echo "  3. source install/setup.bash"
if [[ "$MODE" == "srv" ]]; then
    echo "  4. 测试：ros2 service call /${FILE_NAME,,} ${PKG_NAME}/srv/${FILE_NAME_CAP}"
else
    echo "  4. 测试：ros2 action send_goal /${FILE_NAME,,} ${PKG_NAME}/action/${FILE_NAME_CAP}"
fi
