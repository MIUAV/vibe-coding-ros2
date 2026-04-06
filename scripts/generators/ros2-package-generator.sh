#!/bin/bash
# ros2-package-generator.sh — Wrapper that delegates to ros2-package-generator.py
#
# Usage: bash ros2-package-generator.sh <pkg_name> <type> [deps...] [--verify]
#
# For full functionality, use the Python generator directly:
#   python3 ros2-package-generator.py <pkg_name> <type> [deps...] [--node-type TYPE]

set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

PKG_NAME="${1:-}"
PKG_TYPE="${2:-cpp}"
shift 2 || true

# Parse --verify flag
VERIFY=0
REMAINING_DEPS=""
for arg in "$@"; do
    if [[ "$arg" == "--verify" ]]; then
        VERIFY=1
    else
        if [[ -n "$REMAINING_DEPS" ]]; then
            REMAINING_DEPS="$REMAINING_DEPS,$arg"
        else
            REMAINING_DEPS="$arg"
        fi
    fi
done
DEPS="${REMAINING_DEPS:-rclcpp,std_msgs}"

if [[ -z "$PKG_NAME" ]]; then
    echo -e "${RED}用法: $0 <包名> <类型> [依赖...] [--verify]${NC}"
    echo "  类型: cpp | python | mixed"
    echo "  依赖: rclcpp,std_msgs,geometry_msgs (逗号分隔)"
    echo "  --verify: 生成后自动运行编译验证"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_GEN="$SCRIPT_DIR/ros2-package-generator.py"

# ── Delegate to Python generator ─────────────────────────
if [[ -f "$PYTHON_GEN" ]]; then
    if python3 "$PYTHON_GEN" "$PKG_NAME" "$PKG_TYPE" "$DEPS" --node-type lifecycle >/dev/null 2>&1; then
        echo -e "${GREEN}✓ 包已生成: $PKG_NAME/${NC}"
    else
        echo -e "${RED}Python generator failed${NC}"
        python3 "$PYTHON_GEN" "$PKG_NAME" "$PKG_TYPE" "$DEPS" --node-type lifecycle 2>&1 | tail -5
        exit 1
    fi
else
    echo -e "${RED}Python generator not found: $PYTHON_GEN${NC}"
    exit 1
fi

echo ""
echo "生成的文件:"
find "$PKG_NAME" -type f | sort | sed 's/^/  /'
echo ""

# ── Auto verify ─────────────────────────────────────────
if [[ $VERIFY -eq 1 ]]; then
    VERIFY_SCRIPT="$SCRIPT_DIR/../ros2-build-verify-loop.sh"
    if [[ -f "$VERIFY_SCRIPT" ]]; then
        echo -e "${BLUE}🔍 运行编译验证...${NC}"
        if bash "$VERIFY_SCRIPT" "$PKG_NAME"; then
            echo -e "${GREEN}✓ 编译验证通过${NC}"
        else
            echo -e "${YELLOW}⚠ 编译验证失败，请检查上面的错误${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ ros2-build-verify-loop.sh 未找到，跳过验证${NC}"
    fi
fi

echo ""
echo -e "${YELLOW}下一步:${NC}"
echo "  1. rosdep install --from-paths $PKG_NAME --ignore-src -r -y"
echo "  2. colcon build --packages-select $PKG_NAME --symlink-install"
echo "  3. source install/setup.bash"
echo "  4. ros2 run $PKG_NAME ${PKG_NAME}_node"
