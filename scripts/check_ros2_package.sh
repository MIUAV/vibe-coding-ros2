#!/bin/bash
# check_ros2_package.sh — 验证 ROS2 包结构完整性
# 用法: bash check_ros2_package.sh <pkg_dir>
# 退出码: 0=通过, 1=有错误

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
PKG_DIR="${1:-}"; ERRORS=0; WARNINGS=0

log_info()  { echo -e "${BLUE}[INFO]${NC}  $*"; }
log_pass() { echo -e "${GREEN}✓${NC}  $*"; }
log_fail() { echo -e "${RED}✗${NC}  $*"; ((ERRORS++)); }
log_warn() { echo -e "${YELLOW}WARN${NC}  $*"; ((WARNINGS++)); }

header() {
  echo ""
  echo -e "${BLUE}═══════════════════════════════════════${NC}"
  echo -e "${BLUE}  ROS2 Package Checker — v0.0.1-beta${NC}"
  echo -e "${BLUE}═══════════════════════════════════════${NC}"
}

if [[ -z "$PKG_DIR" ]]; then
  echo "用法: $0 <pkg_dir>"
  echo "示例: $0 ./my_robot_pkg"
  exit 1
fi

header
log_info "检查目录: $PKG_DIR"
echo ""

# 前置检查
if [[ ! -d "$PKG_DIR" ]]; then
  log_fail "目录不存在: $PKG_DIR"
  exit 1
fi

# ── 1. package.xml 检查 ──────────────────────────
echo -e "${BLUE}[1] package.xml${NC}"

if [[ ! -f "$PKG_DIR/package.xml" ]]; then
  log_fail "package.xml 不存在"
else
  log_pass "package.xml 存在"

  # Format 3
  if grep -q 'format="3"' "$PKG_DIR/package.xml"; then
    log_pass "Format 3"
  elif grep -q 'format="2"' "$PKG_DIR/package.xml"; then
    log_warn "Format 2（建议升级到 Format 3）"
  else
    log_warn "未声明 format（建议使用 format=\"3\"）"
  fi

  # <depend> 声明
  DEP_COUNT=$(grep -c '<depend>' "$PKG_DIR/package.xml" 2>/dev/null || echo 0)
  if [[ $DEP_COUNT -gt 0 ]]; then
    log_pass "有 <depend> 声明: $DEP_COUNT 个"
  else
    log_fail "没有 <depend> 声明"
  fi

  # build_type
  if grep -q '<build_type>ament_cmake</build_type>' "$PKG_DIR/package.xml"; then
    log_pass "build_type: ament_cmake"
  elif grep -q '<build_type>ament_python</build_type>' "$PKG_DIR/package.xml"; then
    log_pass "build_type: ament_python"
  elif grep -q '<build_type>colcon</build_type>' "$PKG_DIR/package.xml"; then
    log_pass "build_type: colcon"
  else
    log_warn "未声明 build_type"
  fi
fi

# ── 2. CMakeLists.txt 检查 ──────────────────────
echo ""
echo -e "${BLUE}[2] CMakeLists.txt${NC}"

if [[ ! -f "$PKG_DIR/CMakeLists.txt" ]]; then
  log_fail "CMakeLists.txt 不存在"
else
  log_pass "CMakeLists.txt 存在"

  for item in \
    "find_package(ament_cmake REQUIRED)" \
    "find_package(rclcpp REQUIRED)" \
    "ament_target_dependencies" \
    "install(TARGETS" \
    "ament_package()"; do

    if grep -q "$item" "$PKG_DIR/CMakeLists.txt"; then
      log_pass "$item"
    else
      log_fail "缺少: $item"
    fi
  done

  # C++ 标准
  if grep -q "CMAKE_CXX_STANDARD 17" "$PKG_DIR/CMakeLists.txt"; then
    log_pass "C++ 标准: 17"
  elif grep -q "CMAKE_CXX_STANDARD" "$PKG_DIR/CMakeLists.txt"; then
    log_warn "C++ 标准未设置为 17"
  fi
fi

# ── 3. src 目录检查 ────────────────────────────
echo ""
echo -e "${BLUE}[3] 源码目录${NC}"

if [[ -d "$PKG_DIR/src" ]]; then
  SRC_COUNT=$(find "$PKG_DIR/src" -name '*.cpp' -o -name '*.c' 2>/dev/null | wc -l)
  log_pass "src/ 存在: $SRC_COUNT 个 C/C++ 文件"
else
  log_warn "src/ 目录不存在"
fi

# ── 4. Python 包检查 ───────────────────────────
if [[ -f "$PKG_DIR/package.xml" ]] && grep -q 'ament_python' "$PKG_DIR/package.xml"; then
  echo ""
  echo -e "${BLUE}[4] Python 包${NC}"

  if [[ -f "$PKG_DIR/setup.py" ]]; then
    log_pass "setup.py 存在"
    if grep -q "entry_points" "$PKG_DIR/setup.py"; then
      log_pass "entry_points 声明"
    else
      log_fail "setup.py 缺少 entry_points"
    fi
  else
    log_fail "Python 包缺少 setup.py"
  fi

  if [[ -d "$PKG_DIR/$PKG_DIR" ]]; then
    log_pass "Python 包目录: $PKG_DIR/$PKG_DIR"
  fi
fi

# ── 5. msg/srv/action 检查 ─────────────────────
echo ""
echo -e "${BLUE}[5] 接口定义${NC}"

for iface in msg srv action; do
  if [[ -d "$PKG_DIR/$iface" ]]; then
    IFACE_COUNT=$(find "$PKG_DIR/$iface" -name "*.${iface}" 2>/dev/null | wc -l)
    if [[ $IFACE_COUNT -gt 0 ]]; then
      log_pass "$iface/: $IFACE_COUNT 个文件"

      # 检查 CMakeLists.txt 是否有 rosidl_generate_interfaces
      if grep -q "rosidl_generate_interfaces" "$PKG_DIR/CMakeLists.txt" 2>/dev/null; then
        log_pass "CMakeLists.txt 有 rosidl_generate_interfaces"
      else
        log_fail "有 $iface 但 CMakeLists.txt 缺少 rosidl_generate_interfaces"
      fi

      # 检查 package.xml 是否有 rosidl
      if grep -q "rosidl_default_generators" "$PKG_DIR/package.xml" 2>/dev/null; then
        log_pass "package.xml 有 rosidl_default_generators"
      else
        log_fail "有 $iface 但 package.xml 缺少 rosidl_default_generators"
      fi
    else
      log_warn "$iface/ 目录存在但为空"
    fi
  fi
done

# ── 6. launch 文件检查 ─────────────────────────
echo ""
echo -e "${BLUE}[6] Launch 文件${NC}"

if [[ -d "$PKG_DIR/launch" ]]; then
  LAUNCH_COUNT=$(find "$PKG_DIR/launch" -name '*.launch.py' 2>/dev/null | wc -l)
  if [[ $LAUNCH_COUNT -gt 0 ]]; then
    log_pass "launch/: $LAUNCH_COUNT 个 launch 文件"
  else
    log_warn "launch/ 存在但没有 .launch.py 文件"
  fi
else
  log_warn "launch/ 目录不存在（建议添加）"
fi

# ── 总结 ────────────────────────────────────
echo ""
echo "═══════════════════════════════════════"
echo -e "  ${RED}✗ $ERRORS 个错误${NC} | ${YELLOW}⚠ $WARNINGS 个警告${NC}"
echo "═══════════════════════════════════════"

if [[ $ERRORS -eq 0 ]]; then
  if [[ $WARNINGS -eq 0 ]]; then
    echo -e "${GREEN}✓ 全部检查通过${NC}"
  else
    echo -e "${YELLOW}有警告，建议修复${NC}"
  fi
else
  echo -e "${RED}✗ 检查失败，请修复上述错误${NC}"
fi

exit $ERRORS
