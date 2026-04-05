#!/bin/bash
# ros2-msg-generator.sh — 交互式消息定义向导
# 用法: bash ros2-msg-generator.sh [pkg_name]
# 工作方式: CLI 问答，生成 .msg 文件

set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'

PKG_NAME="${1:-}"

# ── 字段类型映射 ───────────────────────────────────────────
FIELD_TYPES=(
    "bool" "byte" "char" "int8" "uint8" "int16" "uint16"
    "int32" "uint32" "int64" "uint64" "float32" "float64"
    "string" "wstring"
    "time" "duration"
    "builtin_interfaces/Time" "builtin_interfaces/Duration"
)

ROS2_TYPES=(
    "std_msgs/Byte" "std_msgs/Bool" "std_msgs/Char"
    "std_msgs/Int8" "std_msgs/UInt8" "std_msgs/Int16" "std_msgs/UInt16"
    "std_msgs/Int32" "std_msgs/UInt32" "std_msgs/Int64" "std_msgs/UInt64"
    "std_msgs/Float32" "std_msgs/Float64"
    "std_msgs/String"
    "std_msgs/Float64MultiArray"
)

# ── 工具函数 ─────────────────────────────────────────────
select_or_input() {
    local prompt="$1"; shift
    local options=("$@")
    echo -e "${CYAN}$prompt${NC}"
    PS3="选择编号或输入自定义值: "
    select opt in "${options[@]}"; do
        if [[ -n "$opt" ]]; then
            echo "$opt"
            return 0
        fi
    done
}

ask() {
    local var_name="$1"; shift
    local prompt="$*"
    echo -ne "${CYAN}$prompt${NC}: "
    read "$var_name"
}

ask_with_default() {
    local var_name="$1"; shift
    local default="$1"; shift
    echo -ne "${CYAN}$*${NC} [$default]: "
    read input
    eval "$var_name=\"\${input:-\$default}\""
}

confirm() {
    local prompt="$1"
    echo -ne "${CYAN}$prompt${NC} [y/N]: "
    read ans
    [[ "$ans" =~ ^[yY]$ ]]
}

# ── 主流程 ───────────────────────────────────────────────
echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║       ROS2 消息定义向导 — ros2-msg-generator           ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

# 1. 包名
if [[ -z "$PKG_NAME" ]]; then
    ask PKG_NAME "输入包名（不含空格）"
fi

if [[ -z "$PKG_NAME" ]]; then
    echo -e "${RED}包名不能为空${NC}"
    exit 1
fi

# 2. 消息名
ask MSG_NAME "输入消息名（如 LaserScan、RobotPose）"
if [[ -z "$MSG_NAME" ]]; then
    echo -e "${RED}消息名不能为空${NC}"
    exit 1
fi

# 首字母大写规范化
MSG_NAME_CAP="$(tr '[:lower:]' '[:upper:]' <<< ${MSG_NAME:0:1})${MSG_NAME:1}"

# 3. 字段定义
echo ""
echo -e "${YELLOW}═══ 添加字段（空字段名结束）═══${NC}"
echo ""

FIELDS=()
FIELD_TYPES_STR=""
while true; do
    echo "--- 字段 $(( ${#FIELDS[@]} / 2 + 1 )) ---"

    ask FIELD_NAME "  字段名（英文，下划线分隔）"
    if [[ -z "$FIELD_NAME" ]]; then
        if [[ ${#FIELDS[@]} -eq 0 ]]; then
            echo -e "${YELLOW}至少需要一个字段${NC}"
            continue
        fi
        break
    fi

    # 字段类型
    echo "  字段类型："
    PS3="  选择类型编号: "
    select TYPE_CHOICE in "builtin 类型" "std_msgs 类型" "自定义类型" "输入自定义"; do
        case "$TYPE_CHOICE" in
            "builtin 类型")
                PS3="  选择 builtin 类型: "
                select BUILTIN in "${FIELD_TYPES[@]}"; do
                    FIELD_TYPE="$BUILTIN"
                    break 2
                done ;;
            "std_msgs 类型")
                PS3="  选择 std_msgs 类型: "
                select STD in "${ROS2_TYPES[@]}"; do
                    FIELD_TYPE="$STD"
                    break 2
                done ;;
            "自定义类型")
                ask FIELD_TYPE "  输入自定义类型（如 geometry_msgs/PoseStamped）"
                break ;;
            "输入自定义")
                ask FIELD_TYPE "  输入自定义类型"
                break ;;
        esac
    done

    # 数组?
    ARRAY=""
    if confirm "  是否为数组?"; then
        if confirm "  固定大小数组?"; then
            ask ARRAY_SIZE "  数组大小"
            ARRAY="[$ARRAY_SIZE]"
        else
            ARRAY="[]"
        fi
    fi

    # 常量?
    CONST=""
    if confirm "  是否为常量?"; then
        ask CONST_VAL "  常量值"
        CONST=" $FIELD_NAME=$CONST_VAL"
    fi

    # 描述
    ask COMMENT "  字段描述（可选）"
    if [[ -n "$COMMENT" ]]; then
        COMMENT="# $COMMENT"
    fi

    FIELDS+=("$FIELD_NAME" "$FIELD_TYPE$ARRAY$CONST")
    [[ -n "$COMMENT" ]] && FIELDS+=("$COMMENT")
    FIELD_TYPES_STR="$FIELD_TYPES_STR $FIELD_TYPE"

    echo ""
done

# 4. 生成目录
MSG_DIR="$PKG_NAME/msg"
mkdir -p "$MSG_DIR"

# 5. 生成 .msg 文件
cat > "$MSG_DIR/${MSG_NAME_CAP}.msg" <<'EOF'
# ============================================================
# 自动生成 by ros2-msg-generator.sh
# ============================================================
EOF

for ((i=0; i<${#FIELDS[@]}; i+=2)); do
    name="${FIELDS[i]}"
    def="${FIELDS[i+1]}"
    if [[ "$def" == \#* ]]; then
        echo "$def" >> "$MSG_DIR/${MSG_NAME_CAP}.msg"
    else
        echo "$def  $name" >> "$MSG_DIR/${MSG_NAME_CAP}.msg"
    fi
done

echo ""
echo -e "${GREEN}✓ 消息已生成: $MSG_DIR/${MSG_NAME_CAP}.msg${NC}"
echo ""
echo "文件内容："
echo "---"
cat "$MSG_DIR/${MSG_NAME_CAP}.msg"
echo "---"

# 6. 给出后续指令
echo ""
echo -e "${YELLOW}下一步：${NC}"
echo "  1. 将 $MSG_DIR/ 复制到已有的 ROS2 包中"
echo "  2. 或配合 ros2-package-generator.sh:"
echo "     bash scripts/generators/ros2-package-generator.sh $PKG_NAME cpp rclcpp,std_msgs,..."
echo ""
echo "  3. 如果是自定义消息，确保 CMakeLists.txt 包含:"
echo "     rosidl_generate_interfaces(\${PROJECT_NAME}"
echo "       msg/${MSG_NAME_CAP}.msg"
echo "     )"
echo ""
echo -e "${GREEN}生成完成！${NC}"
