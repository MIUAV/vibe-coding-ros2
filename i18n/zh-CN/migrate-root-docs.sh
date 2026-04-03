#!/bin/bash
# migrate-root-docs.sh — 将根目录文档迁移到 i18n/zh-CN/

set -euo pipefail

ROOT="/home/node/.openclaw/workspace/vibe-coding-ros2"
DEST="$ROOT/i18n/zh-CN"
SRC="$ROOT"

echo "Syncing non-root docs to $DEST ..."

for f in AGENTS_CONCISE.md ANTI_PATTERNS.md QUICKSTART.md DEPLOYMENT.md CONTRIBUTING.md; do
    if [[ -f "$ROOT/$f" ]]; then
        cp "$ROOT/$f" "$DEST/$f"
        echo "  ✓ $f → $DEST/$f"
    else
        echo "  — $f not found, skipping"
    fi
done

echo ""
echo "Done. Root keeps README.md + AGENTS.md only."
