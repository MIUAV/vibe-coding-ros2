#!/bin/bash
# ros2-env-check.sh — ROS2 环境诊断工具
# 用法: bash ros2-env-check.sh [--full]
#        --full: 详细诊断（包含依赖检查）

set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

FULL_MODE=0
if [[ "$1" == "--full" ]]; then FULL_MODE=1; fi

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  ROS2 Environment Diagnostic${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

ERRORS=0
WARNINGS=0

# ── 1. ROS2 环境变量 ────────────────────────────────
echo -e "${BLUE}[1/7] ROS2 Environment Variables${NC}"
if [ -z "$ROS_DISTRO" ]; then
    echo -e "  ${RED}✗ ROS_DISTRO not set${NC}"
    ERRORS=$((ERRORS+1))
else
    echo -e "  ${GREEN}✓ ROS_DISTRO=$ROS_DISTRO${NC}"
fi

if [ -z "$ROS_ROOT" ]; then
    echo -e "  ${RED}✗ ROS_ROOT not set${NC}"
    ERRORS=$((ERRORS+1))
else
    echo -e "  ${GREEN}✓ ROS_ROOT=$ROS_ROOT${NC}"
fi

if [ -z "$AMENT_PREFIX_PATH" ]; then
    echo -e "  ${RED}✗ AMENT_PREFIX_PATH not set${NC}"
    ERRORS=$((ERRORS+1))
else
    echo -e "  ${GREEN}✓ AMENT_PREFIX_PATH set${NC}"
fi

if [ -z "$COLCON_PREFIX" ]; then
    echo -e "  ${YELLOW}⚠ COLCON_PREFIX not set (optional)${NC}"
    WARNINGS=$((WARNINGS+1))
fi

echo ""

# ── 2. ROS2 版本检测 ────────────────────────────────
echo -e "${BLUE}[2/7] ROS2 Distribution${NC}"
if command -v ros2 &> /dev/null; then
    ROS2_VERSION=$(ros2 --version 2>/dev/null | head -1 || echo "unknown")
    echo -e "  ${GREEN}✓ ros2 CLI available: $ROS2_VERSION${NC}"
else
    echo -e "  ${RED}✗ ros2 CLI not found (install ros2 CLI)${NC}"
    ERRORS=$((ERRORS+1))
fi

# 检测 Ubuntu 版本 → ROS2 发行版
UBUNTU_CODENAME=$(lsb_release -sc 2>/dev/null || echo "unknown")
EXPECTED_ROS2=""
case "$UBUNTU_CODENAME" in
    jammy) EXPECTED_ROS2="Humble" ;;
    focal) EXPECTED_ROS2="Foxy" ;;
    noble) EXPECTED_ROS2="Jazzy" ;;
    *)    EXPECTED_ROS2="unknown" ;;
esac

if [ "$EXPECTED_ROS2" != "unknown" ]; then
    if [ "$ROS_DISTRO" == "$EXPECTED_ROS2" ]; then
        echo -e "  ${GREEN}✓ Ubuntu $UBUNTU_CODENAME → ROS2 $ROS_DISTRO (matched)${NC}"
    else
        echo -e "  ${YELLOW}⚠ Ubuntu $UBUNTU_CODENAME expects ROS2 $EXPECTED_ROS2, but ROS_DISTRO=$ROS_DISTRO${NC}"
        WARNINGS=$((WARNINGS+1))
    fi
fi

echo ""

# ── 3. 核心工具检测 ────────────────────────────────
echo -e "${BLUE}[3/7] Core Tools${NC}"

check_tool() {
    local tool=$1
    local pkg=$2
    if command -v "$tool" &> /dev/null; then
        echo -e "  ${GREEN}✓ $tool${NC}"
    else
        echo -e "  ${RED}✗ $tool not found (install: apt install $pkg)${NC}"
        ERRORS=$((ERRORS+1))
    fi
}

check_tool "colcon" "python3-colcon-ros"
check_tool "ament_cmake" "ros-humble-ament-cmake"
check_tool "ros2 pkg" "ros-humble-ros2cli"

echo ""

# ── 4. 工作区检测 ────────────────────────────────
echo -e "${BLUE}[4/7] Workspace${NC}"

WS_ROOT=$(pwd)
if [ -f "$WS_ROOT/package.xml" ]; then
    echo -e "  ${GREEN}✓ package.xml found in current directory${NC}"
    PKG_NAME=$(grep '<name>' "$WS_ROOT/package.xml" | head -1 | sed 's/.*<name>//;s/<\/name>//')
    echo -e "  ${GREEN}  Package name: $PKG_NAME${NC}"
elif [ -d "$WS_ROOT/src" ]; then
    echo -e "  ${GREEN}✓ src/ directory found${NC}"
    PKG_COUNT=$(find "$WS_ROOT/src" -maxdepth 2 -name "package.xml" 2>/dev/null | wc -l)
    echo -e "  ${GREEN}  Packages in src/: $PKG_COUNT${NC}"
else
    echo -e "  ${YELLOW}⚠ No package.xml or src/ in current directory${NC}"
    WARNINGS=$((WARNINGS+1))
fi

if [ -d "$WS_ROOT/build" ]; then
    echo -e "  ${GREEN}✓ build/ directory exists${NC}"
else
    echo -e "  ${YELLOW}⚠ No build/ directory (need to run colcon build)${NC}"
    WARNINGS=$((WARNINGS+1))
fi

echo ""

# ── 5. 依赖检查 (--full 模式) ─────────────────────
if [ $FULL_MODE -eq 1 ]; then
    echo -e "${BLUE}[5/7] Dependencies (full check)${NC}"
    
    REQUIRED_DEPS=("rclcpp" "std_msgs" "geometry_msgs" "nav2_msgs")
    for dep in "${REQUIRED_DEPS[@]}"; do
        if ros2 pkg list 2>/dev/null | grep -q "^${dep}$"; then
            echo -e "  ${GREEN}✓ $dep${NC}"
        else
            echo -e "  ${RED}✗ $dep not found${NC}"
            ERRORS=$((ERRORS+1))
        fi
    done
else
    echo -e "${BLUE}[5/7] Dependencies${NC}"
    echo -e "  ${YELLOW}  Run with --full for dependency check${NC}"
fi

echo ""

# ── 6. 常见冲突检测 ───────────────────────────────
echo -e "${BLUE}[6/7] Common Issues${NC}"

# ROS1 ROS2 冲突
if [ -n "$ROS_PACKAGE_PATH" ]; then
    echo -e "  ${RED}✗ ROS_PACKAGE_PATH is set (ROS1 conflict!)${NC}"
    echo -e "    ${YELLOW}  Run: unset ROS_PACKAGE_PATH${NC}"
    ERRORS=$((ERRORS+1))
else
    echo -e "  ${GREEN}✓ No ROS_PACKAGE_PATH (no ROS1 conflict)${NC}"
fi

# source multiple setup.bash
SETUP_COUNT=$(env | grep -c "AMENT_PROGRAMMATICALLY" 2>/dev/null || echo 0)
if [ "$SETUP_COUNT" -gt 0 ]; then
    echo -e "  ${YELLOW}⚠ Multiple ROS2 environments may be sourced${NC}"
    WARNINGS=$((WARNINGS+1))
fi

# 检查 /opt/ros 权限
if [ ! -r "/opt/ros/$ROS_DISTRO/setup.bash" ] 2>/dev/null; then
    if [ -n "$ROS_DISTRO" ]; then
        echo -e "  ${RED}✗ Cannot read /opt/ros/$ROS_DISTRO/setup.bash (permission issue)${NC}"
        ERRORS=$((ERRORS+1))
    fi
fi

echo ""

# ── 7. Git 状态 ───────────────────────────────────
echo -e "${BLUE}[7/7] Git Status${NC}"
if [ -d ".git" ]; then
    echo -e "  ${GREEN}✓ Git repository initialized${NC}"
    BRANCH=$(git branch --show-current 2>/dev/null || echo "detached")
    echo -e "  ${GREEN}  Branch: $BRANCH${NC}"
    if git diff --quiet 2>/dev/null; then
        echo -e "  ${GREEN}  Working tree: clean${NC}"
    else
        echo -e "  ${YELLOW}⚠ Working tree has uncommitted changes${NC}"
        WARNINGS=$((WARNINGS+1))
    fi
    if git log --oneline -1 --format="%ai" | grep -q "^$(date +%Y-%m-%d)"; then
        echo -e "  ${GREEN}  Last commit: today${NC}"
    else
        echo -e "  ${YELLOW}⚠ Last commit not today${NC}"
        WARNINGS=$((WARNINGS+1))
    fi
else
    echo -e "  ${YELLOW}⚠ Not a git repository${NC}"
    WARNINGS=$((WARNINGS+1))
fi

echo ""

# ── 总结 ─────────────────────────────────────────
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "  Errors:   $ERRORS"
echo -e "  Warnings: $WARNINGS"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✅ Environment OK — ready to build!${NC}"
    echo ""
    echo "Next steps:"
    echo "  colcon build --event-handlers console_direct+"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ Environment OK but has warnings${NC}"
    exit 0
else
    echo -e "${RED}❌ Environment has errors — fix before building${NC}"
    echo ""
    echo "Common fixes:"
    echo "  1. Source ROS2: source /opt/ros/\$ROS_DISTRO/setup.bash"
    echo "  2. Unset ROS1: unset ROS_PACKAGE_PATH"
    echo "  3. Check Ubuntu version matches ROS2 distro"
    exit 1
fi
