#!/bin/bash
# ros2-cmake-fix.sh — CMake 依赖问题自动修复
# 用法: bash ros2-cmake-fix.sh <package_path>
# 示例: bash ros2-cmake-fix.sh my_robot

RED='\033[0;31m'; GREEN='\\033[0;32m'; YELLOW='\\033[1;33m'; BLUE='\\033[0;34m'; NC='\\033[0m'

PKG_PATH="${1:-.}"

if [[ ! -f "$PKG_PATH/CMakeLists.txt" ]]; then
    echo -e "${RED}错误: $PKG_PATH 不是 ROS2 包（缺少 CMakeLists.txt）${NC}"
    exit 1
fi

echo -e "${BLUE}=== CMake 依赖诊断: $PKG_PATH ===${NC}"
echo ""

CMakeFile="$PKG_PATH/CMakeLists.txt"
PKGXML="$PKG_PATH/package.xml"

# ── 1. 提取 find_package ──────────────────────────────────
echo "1. 提取 find_package 列表..."
FINDS=$(grep "^find_package" "$CMakeFile" | sed 's/find_package(\([A-Za-z_0-9]*\).*/\1/' | sort -u)
echo "  CMakeLists.txt 中的 find_package:"
echo "$FINDS" | sed 's/^/    /'

# ── 2. 提取 <depend> 列表 ────────────────────────────────
echo ""
echo "2. package.xml 依赖检查..."
if [[ -f "$PKGXML" ]]; then
    DEPS=$(grep -E "<(depend|build_depend|exec_depend)>" "$PKGXML" \
        | sed 's/.*>\([A-Za-z_0-9_-]*\)<.*/\1/' | sort -u)
    echo "  package.xml 中的依赖:"
    echo "$DEPS" | sed 's/^/    /'
else
    echo -e "  ${YELLOW}警告: package.xml 不存在${NC}"
    DEPS=""
fi

# ── 3. 检测缺失的 find_package ───────────────────────────
echo ""
echo "3. 缺失的 find_package 检测..."

MISSING=""
for dep in $DEPS; do
    # 跳过 rosidl 相关的特殊依赖
    [[ "$dep" == "rosidl_default_generators" || "$dep" == "builtin_interfaces" ]] && continue
    # 跳过 cmake 标准依赖
    [[ "$dep" == "ament_cmake" || "$dep" == "ament_cmake_python" ]] && continue

    if ! grep -q "find_package($dep" "$CMakeFile"; then
        MISSING="$MISSING $dep"
        echo -e "  ${RED}✗ 缺失: find_package($dep REQUIRED)${NC}"
    fi
done

if [[ -z "$MISSING" ]]; then
    echo -e "  ${GREEN}✓ 所有 package.xml 依赖已包含在 find_package${NC}"
fi

# ── 4. 检测 ament_export_dependencies ───────────────────
echo ""
echo "4. ament_export_dependencies 检查..."

if grep -q "ament_export_dependencies" "$CMakeFile"; then
    echo -e "  ${GREEN}✓ ament_export_dependencies 存在${NC}"

    # 检查三行是否同时存在
    H3=0; H2=0; H1=0
    grep -q "ament_export_dependencies" "$CMakeFile" && H3=1
    grep -q "ament_export_include_directories" "$CMakeFile" && H2=1
    grep -q "ament_export_libraries" "$CMakeFile" && H1=1

    if [[ $H3 -eq 1 && $H2 -eq 1 && $H1 -eq 1 ]]; then
        echo -e "  ${GREEN}✓ 三行 export 完整${NC}"
    else
        echo -e "  ${RED}✗ 缺少某些 export 行:${NC}"
        [[ $H3 -eq 0 ]] && echo -e "    ${RED}缺失: ament_export_dependencies${NC}"
        [[ $H2 -eq 0 ]] && echo -e "    ${RED}缺失: ament_export_include_directories${NC}"
        [[ $H1 -eq 0 ]] && echo -e "    ${RED}缺失: ament_export_libraries\${PROJECT_NAME}${NC}"
    fi
else
    echo -e "  ${YELLOW}⚠ ament_export_dependencies 不存在（可能导致链接错误）${NC}"
fi

# ── 5. 生成修复建议 ───────────────────────────────────────
if [[ -n "$MISSING" ]] || ! grep -q "ament_export_dependencies" "$CMakeFile"; then
    echo ""
    echo -e "${YELLOW}5. 自动修复建议:${NC}"
    echo ""

    if [[ -n "$MISSING" ]]; then
        echo "  # 在 find_package 区域添加缺失的依赖："
        for dep in $MISSING; do
            echo "  find_package($dep REQUIRED)"
        done
        echo ""
    fi

    echo "  # 确保 CMakeLists.txt 末尾包含（如果没有）："
    echo "  ament_export_dependencies(rclcpp)"
    echo "  ament_export_include_directories(include)"
    echo "  ament_export_libraries(\${PROJECT_NAME})"
    echo ""
    echo -e "${GREEN}手动应用以上修复后，重新 colcon build --packages-select ${PKG_PATH}${NC}"
fi
