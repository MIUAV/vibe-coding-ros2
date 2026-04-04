#!/bin/bash
TARGET="${1:-agents/skills}"
TOTAL=0; ERRORS=0; WARNINGS=0

echo "SKILL.md 验证器 — $TARGET"
echo ""

while IFS= read -r file; do
  TOTAL=$((TOTAL+1))
  FRONTMATTER=$(awk '/^---$/{c=1;next}/^---$/{c=0;exit}c' "$file")
  HAS_NAME=0; HAS_DESC=0; HAS_TAB=0
  
  echo "$FRONTMATTER" | grep -q "^name:" && HAS_NAME=1
  echo "$FRONTMATTER" | grep -q "^description:" && HAS_DESC=1
  echo "$FRONTMATTER" | grep -q $'\t' && HAS_TAB=1
  
  BN="$(basename "$(dirname "$file")")/$(basename "$file")"
  
  if [ "$HAS_NAME" -eq 0 ] || [ "$HAS_DESC" -eq 0 ]; then
    echo "FAIL: $BN — missing $([ $HAS_NAME -eq 0 ] && echo name; [ $HAS_DESC -eq 0 ] && echo description)"
    ERRORS=$((ERRORS+1))
  elif [ "$HAS_TAB" -eq 1 ]; then
    echo "WARN: $BN — contains tabs"
    WARNINGS=$((WARNINGS+1))
  else
    echo "OK:   $BN"
  fi
done < <(find "$TARGET" -name "SKILL.md" -type f 2>/dev/null | sort)

echo ""
echo "=========================================="
echo "Result: $ERRORS errors, $WARNINGS warnings (total: $TOTAL files)"
echo "=========================================="

if [ $ERRORS -gt 0 ]; then
  exit 1
fi
exit 0
