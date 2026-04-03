#!/bin/bash
# migrate-root-docs.sh — 将根目录文档迁移到 i18n/zh-CN/

set -euo pipefail

ROOT="/home/node/.openclaw/workspace/vibe-coding-ros2"
DEST="$ROOT/i18n/zh-CN"
SRC="$ROOT"

echo "Moving root .md files to $DEST ..."

for f in README.md AGENTS.md AGENTS_CONCISE.md ANTI_PATTERNS.md QUICKSTART.md DEPLOYMENT.md CONTRIBUTING.md; do
    if [[ -f "$ROOT/$f" ]]; then
        cp "$ROOT/$f" "$DEST/$f"
        echo "  ✓ $f → $DEST/$f"
    else
        echo "  — $f not found, skipping"
    fi
done

echo ""
echo "Done. Run: git add i18n/zh-CN/ && git commit -m 'chore: move root docs to i18n/zh-CN'"
