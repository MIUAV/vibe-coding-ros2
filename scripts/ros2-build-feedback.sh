#!/bin/bash
# ros2-build-feedback.sh — 捕获 colcon build 错误并提取关键依赖缺失信息
# 用法: bash ros2-build-feedback.sh <pkg_name> [--fix]
# AI Agent 使用此脚本获取编译错误并自动修正

set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

PKG_NAME="${1:-}"
DO_FIX="${2:-}"

if [[ -z "$PKG_NAME" ]]; then
    echo -e "${RED}用法: $0 <包名> [--fix]${NC}"
    echo "  <包名> : ROS2 包名"
    echo "  --fix  : 自动修复发现的错误"
    exit 1
fi

# 加载 ROS2 环境
load_ros2() {
    if [[ -n "$ROS_DISTRO" ]]; then
        return 0
    fi
    for distro in humble iron rolling galactic foxy; do
        if [[ -f "/opt/ros/$distro/setup.bash" ]]; then
            source "/opt/ros/$distro/setup.bash"
            return 0
        fi
    done
    echo -e "${RED}! 未检测到 ROS2 环境${NC}"
    return 1
}

# ── 编译并捕获错误 ───────────────────────────
run_build() {
    echo -e "${BLUE}=== colcon build: $PKG_NAME ===${NC}"
    load_ros2 || exit 1
    
    BUILD_OUTPUT=$(colcon build --packages-select "$PKG_NAME" --symlink-install 2>&1)
    BUILD_RC=$?
    
    echo "$BUILD_OUTPUT"
    return $BUILD_RC
}

# ── 解析错误类型 ─────────────────────────────
parse_errors() {
    local output="$1"
    
    echo ""
    echo -e "${BLUE}=== 错误分析 ===${NC}"
    
    # 1. 缺失依赖
    MISSING=$(echo "$output" | grep -oP "non-existent dependency '\K[^']+")
    if [[ -n "$MISSING" ]]; then
        echo -e "${RED}[1] 缺失依赖:${NC}"
        for dep in $(echo "$MISSING" | sort -u); do
            echo -e "  ! find_package(${dep} REQUIRED) 缺失"
            echo -e "  修复: 在 CMakeLists.txt 添加: find_package(${dep} REQUIRED)"
        done
    fi
    
    # 2. 未定义引用
    UNDEF=$(echo "$output" | grep -oP "undefined reference to '\K[^']+")
    if [[ -n "$UNDEF" ]]; do
        echo -e "${RED}[2] 未定义引用:${NC}"
        for sym in $(echo "$UNDEF" | sort -u | head -5); do
            echo -e "  ! $sym"
            echo -e "     修复: 在 ament_target_dependencies 中添加对应库"
        done
    fi
    
    # 3. ament_export_dependencies 缺失
    if echo "$output" | grep -q "ament_export_dependencies"; then
        echo -e "${RED}[3] ament_export_dependencies 缺失${NC}"
        echo -e "  修复: 在 CMakeLists.txt find_package 后添加: ament_export_dependencies()"
        echo -e "  或替换为: ament_auto_find_build_dependencies() + ament_auto_package()"
    fi
    
    # 4. 消息类型错误
    if echo "$output" | grep -q "cannot find message file"; then
        echo -e "${RED}[4] 消息类型文件缺失${NC}"
        echo -e "  检查: rosidl_generate_interfaces 中的 .msg 文件名是否正确"
    fi
    
    # 5. C++ 标准错误
    if echo "$output" | grep -q "CMAKE_CXX_STANDARD"; then
        echo -e "${RED}[5] C++ 标准版本问题${NC}"
        echo -e "  修复: 在 CMakeLists.txt 添加: set(CMAKE_CXX_STANDARD 17)"
    fi
    
    # 无错误
    if [[ -z "$MISSING" && -z "$UNDEF" && ! "$output" =~ ament_export_dependencies ]]; then
        echo -e "${GREEN}[OK] 未发现已知错误模式${NC}"
        echo "  可能需要手动检查编译输出"
    fi
}

# ── 自动修复 ─────────────────────────────────
auto_fix() {
    local pkg_dir
    pkg_dir=$(pwd)
    
    echo ""
    echo -e "${BLUE}=== 自动修复 ===${NC}"
    
    # 修复 1: 添加缺失依赖到 CMakeLists.txt
    if [[ -n "$MISSING" ]]; then
        for dep in $(echo "$MISSING" | sort -u); do
            dep_clean=$(echo "$dep" | tr '-' '_')
            if ! grep -q "find_package(${dep}" "$pkg_dir/CMakeLists.txt" 2>/dev/null; then
                echo -e "  + 添加缺失依赖: find_package(${dep} REQUIRED)"
                sed -i "s/find_package(ament_cmake REQUIRED)/find_package(ament_cmake REQUIRED)\nfind_package(${dep} REQUIRED)/" \
                    "$pkg_dir/CMakeLists.txt"
            fi
        done
    fi
    
    echo -e "${YELLOW}! 自动修复完成，请重新编译验证:${NC}"
    echo "  colcon build --packages-select $PKG_NAME --symlink-install"
}

# ── 主逻辑 ───────────────────────────────────
run_build
BUILD_RC=$?

if [[ $BUILD_RC -eq 0 ]]; then
    echo ""
    echo -e "${GREEN}✓ 编译成功${NC}"
    exit 0
fi

parse_errors "$BUILD_OUTPUT"

if [[ "$DO_FIX" == "--fix" ]]; then
    auto_fix
fi

exit $BUILD_RC
