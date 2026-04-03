#!/bin/bash
# skill-frontmatter-validator.sh — 验证所有 SKILL.md 的 Frontmatter 格式
# 用法: bash skill-frontmatter-validator.sh [agents/skills/]

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
ERRORS=0; WARNINGS=0; FIXED=0

SKILLS_DIR="${1:-agents/skills}"

info()  { echo -e "${BLUE}[INFO]${NC}  $*"; }
ok()    { echo -e "${GREEN}✓${NC}  $*"; }
fail()  { echo -e "${RED}✗${NC}  $*"; ((ERRORS++)); }
warn()  { echo -e "${YELLOW}WARN${NC}  $*"; ((WARNINGS++)); }
fix()   { echo -e "${GREEN}FIX${NC}   $*"; ((FIXED++)); }

header() {
  echo ""
  echo -e "${BLUE}═══════════════════════════════════════════${NC}"
  echo -e "${BLUE}  Skill Frontmatter Validator${NC}"
  echo -e "${BLUE}═══════════════════════════════════════════${NC}"
}

usage() {
  echo "用法: $0 [SKILLS_DIR]"
  echo "示例: $0 agents/skills"
  echo "       $0 agents/skills/navigation"
}

# ── Frontmatter 字段定义 ────────────────────────────────
REQUIRED_FIELDS=("name" "description")
OPTIONAL_FIELDS=("argument-hint" "user-invocable" "status" "version" "author" "tags")

check_frontmatter() {
  local file="$1"
  local dir; dir=$(dirname "$file")
  local skill_name; skill_name=$(basename "$dir")

  # 读取 frontmatter（--- ... --- 之间的内容）
  local fm; fm=$(sed -n '/^---$/,/^---$/p' "$file" | sed '1d;$d')

  if [[ -z "$fm" ]]; then
    fail "$file: 缺少 Frontmatter（没有 --- 分隔符）"
    return
  fi

  local has_errors=0

  # ── 1. 检查 name 字段 ──────────────────────
  if echo "$fm" | grep -q "^name:"; then
    local name_val; name_val=$(echo "$fm" | grep "^name:" | sed 's/^name: *//' | tr -d '[:space:]')
    if [[ -z "$name_val" ]]; then
      fail "$file: name 字段为空"
      has_errors=1
    elif [[ "$name_val" != "$(basename "$dir")" ]]; then
      warn "$file: name='$name_val' 与目录名 '$skill_name' 不一致"
    fi
  else
    fail "$file: 缺少 name 字段"
    has_errors=1
  fi

  # ── 2. 检查 description 字段 ─────────────────
  if echo "$fm" | grep -q "^description:"; then
    local desc_val; desc_val=$(echo "$fm" | grep "^description:" | sed 's/^description: *//' | tr -d '[:space:]')
    if [[ -z "$desc_val" ]]; then
      fail "$file: description 字段为空"
      has_errors=1
    fi
  else
    fail "$file: 缺少 description 字段"
    has_errors=1
  fi

  # ── 3. 检查 argument-hint 字段 ─────────────────
  if ! echo "$fm" | grep -q "^argument-hint:"; then
    warn "$file: 缺少 argument-hint（AI 路由需要）"
  fi

  # ── 4. 检查 user-invocable 字段 ─────────────────
  if ! echo "$fm" | grep -q "^user-invocable:"; then
    warn "$file: 缺少 user-invocable（建议添加）"
  fi

  # ── 5. 检查 YAML 语法 ──────────────────────
  if ! echo "$fm" | python3 -c "import yaml, sys; yaml.safe_load(sys.stdin)" 2>/dev/null; then
    fail "$file: Frontmatter YAML 语法错误"
    has_errors=1
  fi

  if [[ $has_errors -eq 0 ]]; then
    ok "$file"
  fi
}

fix_frontmatter() {
  local file="$1"
  local dir; dir=$(dirname "$file")
  local skill_name; skill_name=$(basename "$dir")

  # 读取原始内容
  local content; content=$(cat "$file")

  # 检查是否缺少 Frontmatter
  if ! echo "$content" | head -1 | grep -q "^---"; then
    # 添加 Frontmatter
    local new_fm="---
name: $skill_name
description: TODO: 描述这个技能的功能
argument-hint: \"TODO: 触发词1\" / \"触发词2\"
user-invocable: true
---

"

    echo "$new_fm$content" > "$file"
    fix "$file: 添加了缺失的 Frontmatter"
  fi
}

auto_fix="${AUTO_FIX:-false}"

header
info "扫描目录: $SKILLS_DIR"
echo ""

if [[ ! -d "$SKILLS_DIR" ]]; then
  fail "目录不存在: $SKILLS_DIR"
  exit 1
fi

# 收集所有 SKILL.md
mapfile -t FILES < <(find "$SKILLS_DIR" -name "SKILL.md" | sort)
info "找到 ${#FILES[@]} 个 SKILL.md"
echo ""

# 检查每个文件
for file in "${FILES[@]}"; do
  check_frontmatter "$file"
done

# 报告
echo ""
echo "═══════════════════════════════════════════"
echo -e "  ${RED}✗ $ERRORS 个错误${NC} | ${YELLOW}⚠ $WARNINGS 个警告${NC}"
echo "═══════════════════════════════════════════"

if [[ $ERRORS -gt 0 ]]; then
  echo -e "${RED}有错误，请修复后再提交${NC}"
  echo ""
  echo "提示: AUTO_FIX=true $0 可自动修复"
fi

exit $ERRORS
