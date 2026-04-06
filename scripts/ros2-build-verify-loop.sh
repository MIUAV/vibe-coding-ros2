#!/bin/bash
# ros2-build-verify-loop.sh — AI 代码生成后的自动验证修复循环
#
# 工作流:
#   colcon build → 分析错误 → AI 修复建议 → 重试（最多 3 轮）
#   → 静态分析 → 生成测试计划 → 全部通过则结束
#
# 用法:
#   bash ros2-build-verify-loop.sh <package_path> [max_retries]
#
# 核心原理:
#   AI 生成代码 → 编译失败 → 分析错误类型 → 回传给 AI → 重新生成

set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'

PKG_PATH="${1:-.}"
MAX_RETRIES="${2:-3}"
RETRIES=0

log()   { echo -e "${BLUE}[LOOP]${NC}  $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
ok()    { echo -e "${GREEN}[OK]${NC}   $1"; }

BUILD_LOG="/tmp/colcon_build_$$.log"

# ── Step 1: colcon build ────────────────────────
run_build() {
  log "Step 1/4: colcon build (attempt $((RETRIES+1))/$MAX_RETRIES)"

  cd "$PKG_PATH"

  # 首次清理
  if [ $RETRIES -eq 0 ] && { [ -d build ] || [ -d install ]; }; then
    warn "Cleaning previous artifacts..."
    rm -rf build install log
  fi

  # 编译
  colcon build --event-handlers console_direct+ 2>&1 | tee "$BUILD_LOG"
}

# ── Step 2: 静态分析 ─────────────────────────
run_static() {
  log "Step 2/4: static analysis"
  cd "$PKG_PATH"

  # cpplint
  if command -v cpplint &>/dev/null; then
    local errors=$(find src -name "*.cpp" 2>/dev/null | head -10 | xargs cpplint 2>/dev/null | grep -c "error" || echo 0)
    if [ "$errors" -gt 0 ]; then
      warn "cpplint: $errors errors"
    else
      ok "cpplint: OK"
    fi
  fi

  # clang-tidy
  if command -v clang-tidy &>/dev/null; then
    local errors=$(find src -name "*.cpp" 2>/dev/null | head -5 | \
      xargs clang-tidy 2>/dev/null | grep -c "error:" || echo 0)
    if [ "$errors" -gt 0 ]; then
      warn "clang-tidy: $errors errors"
    else
      ok "clang-tidy: OK"
    fi
  fi
}

# ── Step 3: LLM API 调用（带重试）─────────────────────
call_llm_with_retry() {
  local error_log="$1"
  local attempt=1
  local max_attempts=3
  local response=""

  while [ $attempt -le $max_attempts ]; do
    log "LLM API call attempt $attempt/$max_attempts..."

    # 检查 LLM 命令是否可用
    if ! command -v llm &>/dev/null; then
      warn "llm CLI not found — skipping AI fix (install: pip install llm)"
      return 1
    fi

    # 构造 prompt
    local prompt=""
    prompt+="Fix this ROS2 colcon build error. Reply ONLY with fixed CMakeLists.txt content."
    prompt+=" No explanations, just the corrected CMakeLists.txt content."
    prompt+=""
    prompt+="Build error:"
    prompt+="$(cat "$error_log" 2>/dev/null | head -50)"

    # 调用 LLM（带超时）
    response=$(echo "$prompt" | timeout 30 llm -m gpt-4 2>&1) || true

    # 检查 LLM 是否成功返回
    if [ -z "$response" ]; then
      warn "LLM returned empty response (attempt $attempt/$max_attempts)"
    elif echo "$response" | grep -qi "error\|rate.limit\|timeout\|unavailable"; then
      warn "LLM error detected: $(echo "$response" | head -1)"
    else
      log "LLM returned valid response"
      echo "$response"
      return 0
    fi

    attempt=$((attempt + 1))
    if [ $attempt -le $max_attempts ]; then
      warn "Retrying LLM in 5s..."
      sleep 5
    fi
  done

  error "LLM API failed after $max_attempts attempts — no AI fix available"
  echo "FALLBACK: manual fix required. See build log: $error_log"
  return 1
}

# ── Step 3: 错误分类与修复建议 ─────────────────
analyze_errors() {
  log "Step 3/4: error analysis"
  cd "$PKG_PATH"

  local cmake_errs=$(grep -c "^CMake Error" "$BUILD_LOG" 2>/dev/null || echo 0)
  local link_errs=$(grep -c "undefined reference\|ld: cannot find" "$BUILD_LOG" 2>/dev/null || echo 0)
  local hdr_errs=$(grep -c "fatal error:\|No such file" "$BUILD_LOG" 2>/dev/null || echo 0)

  [ $cmake_errs -gt 0 ] && error "CMake errors: $cmake_errs"
  [ $link_errs -gt 0 ]  && error "Link errors: $link_errs"
  [ $hdr_errs -gt 0 ]   && error "Header errors: $hdr_errs"

  echo ""
  echo -e "${CYAN}=== AI Fix Instructions (copy to your AI) ===${NC}"
  echo "Package: $(basename "$PKG_PATH")"
  echo "Build log: $BUILD_LOG"
  echo ""
  echo "--- Critical errors ---"
  grep -E "error:|undefined reference|cannot find" "$BUILD_LOG" 2>/dev/null | head -20
  echo ""
  echo "Quick fixes:"
  [ $link_errs -gt 0 ] && echo "1. Missing ament_export_dependencies — add all 3 lines to CMakeLists.txt"
  [ $hdr_errs -gt 0 ]  && echo "2. Missing headers — add find_package and include_directories"
  [ $cmake_errs -gt 0 ] && echo "3. CMake config error — check find_package with REQUIRED"
  echo ""

  # 尝试 LLM 自动修复（带重试）
  echo -e "${CYAN}=== Attempting AI-assisted fix ===${NC}"
  if call_llm_with_retry "$BUILD_LOG" >/tmp/llm_fix_output.txt 2>&1; then
    llm_response=$(cat /tmp/llm_fix_output.txt)
    if [[ -n "$llm_response" && "$llm_response" != "FALLBACK: manual fix required" ]]; then
      echo ""
      echo -e "${GREEN}✓ LLM generated a fix suggestion (review before applying)${NC}"
      echo ""
      echo "--- LLM Output ---"
      echo "$llm_response" | head -30
      echo ""
      echo -e "${YELLOW}To apply: manually update CMakeLists.txt with the LLM suggestion${NC}"
    fi
  else
    echo -e "${YELLOW}⚠ LLM fix unavailable — please apply fixes manually${NC}"
  fi
}

# ── Step 4: 生成测试计划 ──────────────────────
gen_test_plan() {
  log "Step 4/4: test plan"
  local pkg=$(basename "$PKG_PATH")
  echo ""
  echo -e "${CYAN}=== Test Plan ===${NC}"
  echo "| ID | Test | Method |"
  echo "| T1 | Node starts | launch + check process |"
  echo "| T2 | Topic publish | ros2 topic echo |"
  echo "| T3 | QoS compatible | ros2 topic info --verbose |"
  echo "| T4 | Lifecycle states | ros2 lifecycle list |"
  echo "| T5 | Params load | ros2 param list |"
  echo ""
}

# ── 主循环 ───────────────────────────────────
main() {
  echo -e "${BLUE}=====================================${NC}"
  echo -e "${BLUE}  ROS2 Build-Verify-Loop${NC}"
  echo -e "${BLUE}=====================================${NC}"
  echo ""

  while [ $RETRIES -lt $MAX_RETRIES ]; do
    log "Iteration $((RETRIES+1))/$MAX_RETRIES"

    if run_build; then
      ok "Build succeeded!"
      run_static
      gen_test_plan
      ok "All done! ✓"
      exit 0
    fi

    analyze_errors

    RETRIES=$((RETRIES+1))
    if [ $RETRIES -ge $MAX_RETRIES ]; then
      error "Max retries reached. Fix errors and retry."
      exit 1
    fi

    warn "Retrying in 3s..."
    sleep 3
  done
}

main "$@"
