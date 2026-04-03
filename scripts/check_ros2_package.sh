#!/bin/bash
# check_ros2_package.sh — 验证 ROS2 包结构完整性
# 用法: bash check_ros2_package.sh <pkg_dir>
# 退出码: 0=通过, 1=有错误

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
PKG_DIR="$1"; ERRORS=0

check() {
    if "$2"; then
        echo -e "${GREEN}✓${NC} $1"
    else
        echo -e "${RED}✗${NC} $1"
        ((ERRORS++))
    fi
}

if [[ -z "$PKG_DIR" ]]; then
    echo "用法: $0 <pkg_dir>"; exit 1
fi

echo "=== 检查: $PKG_DIR ==="
[[ -d "$PKG_DIR" ]] || { echo "目录不存在"; exit 1; }

check "package.xml 存在" "[[ -f $PKG_DIR/package.xml ]]"
check "CMakeLists.txt 存在" "[[ -f $PKG_DIR/CMakeLists.txt ]]"
check "有 <depend> 声明" "grep -qc '<depend>' $PKG_DIR/package.xml"
check "find_package(ament_cmake)" "grep -q 'find_package(ament_cmake' $PKG_DIR/CMakeLists.txt"
check "ament_target_dependencies" "grep -q 'ament_target_dependencies' $PKG_DIR/CMakeLists.txt"
check "install(TARGETS" "grep -q 'install(TARGETS' $PKG_DIR/CMakeLists.txt"
check "ament_package()" "grep -q 'ament_package()' $PKG_DIR/CMakeLists.txt"

echo -e "\n=== 结果: $ERRORS 个错误 ==="
[[ $ERRORS -eq 0 ]] && echo -e "${GREEN}✓ 全部通过${NC}"
exit $ERRORS
