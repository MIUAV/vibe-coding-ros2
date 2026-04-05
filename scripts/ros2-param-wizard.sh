#!/bin/bash
# ros2-param-wizard.sh — 参数声明验证 + YAML 生成向导
# 用法: bash ros2-param-wizard.sh <pkg_name> [--validate]
# 示例: bash ros2-param-wizard.sh my_robot --validate

set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

PKG_NAME="${1:-}"
MODE="${2:-}"

if [[ -z "$PKG_NAME" ]]; then
    echo -e "${RED}用法: $0 <pkg_name> [--validate]${NC}"
    echo "  pkg_name: 包名（必须在当前工作区）"
    echo "  --validate: 仅验证已有 params.yaml，不生成"
    exit 1
fi

PARAM_FILE="$PKG_NAME/config/params.yaml"

# ── 验证模式 ──────────────────────────────────────────────
if [[ "$MODE" == "--validate" ]]; then
    echo -e "${BLUE}=== 参数验证: $PKG_NAME ===${NC}"

    if [[ ! -f "$PARAM_FILE" ]]; then
        echo -e "${RED}✗ params.yaml 不存在: $PARAM_FILE${NC}"
        exit 1
    fi

    ERRORS=0

    # 检查参数类型
    echo "检查参数声明..."
    while IFS= read -r line; do
        # 跳过注释和空行
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue

        # 检查参数名格式（ROS2 参数名不能有 -）
        if [[ "$line" =~ ^[[:space:]]*[-a-zA-Z_]+: ]]; then
            param_name=$(echo "$line" | sed 's/:.*//' | tr -d ' ')
            if [[ "$param_name" =~ - ]]; then
                echo -e "  ${RED}✗ 参数名不能有连字符: $param_name${NC}"
                ERRORS=$((ERRORS + 1))
            fi
        fi

        # 检查重复声明
    done < "$PARAM_FILE"

    if [[ $ERRORS -eq 0 ]]; then
        echo -e "${GREEN}✓ 参数声明验证通过${NC}"
    else
        echo -e "${RED}✗ 发现 $ERRORS 个错误${NC}"
        exit 1
    fi
    exit 0
fi

# ── 生成模式 ──────────────────────────────────────────────
echo -e "${BLUE}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║      ROS2 参数定义向导 — ros2-param-wizard         ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════╝${NC}"

mkdir -p "$PKG_NAME/config"

PARAMS=""
while true; do
    echo ""
    echo "添加参数（空名称结束）："
    echo -ne "  参数名: "; read param_name
    [[ -z "$param_name" ]] && break

    if [[ "$param_name" =~ - ]]; then
        echo -e "  ${RED}✗ 参数名不能包含连字符${NC}"
        continue
    fi

    echo "  类型: 1=int 2=double 3=bool 4=string 5=int[]"
    echo -ne "  选择: "; read type_choice

    case "$type_choice" in
        1) param_type="integer"; read -p "  默认值: " default_val ;;
        2) param_type="double"; read -p "  默认值: " default_val ;;
        3) param_type="bool"; read -p "  默认值 (true/false): " default_val ;;
        4) param_type="string"; read -p "  默认值: " default_val ;;
        5) param_type="integer array"; read -p "  默认值 (逗号分隔): " default_val ;;
        *) echo "未知类型"; continue ;;
    esac

    echo -ne "  描述: "; read description
    echo -ne "  只读 (y/N): "; read readonly
    readonly_val=$([[ "$readonly" =~ ^[yY]$ ]] && echo "true" || echo "false")

    PARAMS="$PARAMS
  $param_name:
    type: $param_type
    default: $default_val
    description: $description
    read_only: $readonly_val"
    echo -e "  ${GREEN}✓ 已添加${NC}"
done

if [[ -z "$PARAMS" ]]; then
    echo -e "${YELLOW}无参数，跳过生成${NC}"
    exit 0
fi

cat > "$PARAM_FILE" <<YAMLEOF
# 参数文件 — $PKG_NAME
# 由 ros2-param-wizard.sh 自动生成

/**:
  ros__parameters:
$PARAMS
YAMLEOF

echo ""
echo -e "${GREEN}✓ 参数文件已生成: $PARAM_FILE${NC}"
echo ""
cat "$PARAM_FILE"
echo ""
echo "使用方式："
echo "  ros2 run $PKG_NAME node_name --ros-args --params-file $PARAM_FILE"
