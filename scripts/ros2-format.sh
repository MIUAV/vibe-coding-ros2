#!/bin/bash
# ros2-format.sh — ROS2 代码格式化和检查
# 用法: bash ros2-format.sh [--check-only]
# 示例: bash ros2-format.sh        # 格式化所有文件
# 示例: bash ros2-format.sh --check-only  # 仅检查不修改

set -e

CHECK_ONLY="${1:-}"

# 检测 clang-format
if ! command -v clang-format &>/dev/null; then
    echo "clang-format not found. Installing..."
    sudo apt-get update && sudo apt-get install -y clang-format
fi

echo "=== ROS2 代码格式化工具 ==="
echo ""

# 查找所有 C++/C 源文件
C_FILES=$(find . -name "*.cpp" -o -name "*.hpp" -o -name "*.c" -o -name "*.h" \
    ! -path "./.git/*" \
    ! -path "./build/*" \
    ! -path "./install/*" \
    ! -path "./log/*" 2>/dev/null)

FILE_COUNT=$(echo "$C_FILES" | wc -l)
echo "找到 $FILE_COUNT 个 C/C++ 文件"

if [[ -z "$CHECK_ONLY" ]]; then
    echo "正在格式化..."
    echo "$C_FILES" | xargs clang-format -i
    echo "✓ 格式化完成"
else
    echo "检查格式（不修改）..."
    ERRORS=0
    for f in $C_FILES; do
        if ! clang-format --Werror --dry-run "$f" 2>/dev/null; then
            echo "  ✗ 格式错误: $f"
            ERRORS=$((ERRORS + 1))
        fi
    done
    if [[ $ERRORS -eq 0 ]]; then
        echo "✓ 所有文件格式正确"
    else
        echo "✗ $ERRORS 个文件格式错误（运行不带 --check-only 修复）"
        exit 1
    fi
fi
