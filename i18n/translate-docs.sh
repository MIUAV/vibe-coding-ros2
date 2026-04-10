#!/bin/bash
# translate-docs.sh — 多语言文档翻译工作流
# 依赖: DeepL API (DEEPL_API_KEY) 或 Google Translate (googletrans)
# 用法: bash i18n/translate-docs.sh <文件> <目标语言> [--deepl|--google]
# 示例: bash i18n/translate-docs.sh README.md ja-JP --deepl
# 示例: bash i18n/translate-docs.sh CLAUDE.md zh-CN --google

set -e

# 项目根目录（脚本所在位置）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
I18N_DIR="$SCRIPT_DIR"

SOURCE="${1:-}"
LANG="${2:-zh-CN}"
TRANSLATOR="${3:---deepl}"

if [[ -z "$SOURCE" ]]; then
    echo "用法: $0 <文件或目录> <目标语言> [--deepl|--google]"
    echo "  例: $0 README.md ja-JP --deepl"
    echo "  例: $0 CLAUDE.md zh-CN --google"
    echo "  例: $0 agents/memory-bank/ ko-KR --deepl"
    exit 1
fi

# ── 翻译器 ──────────────────────────────
translate_deepl() {
    local text="$1"
    curl -s "https://api-free.deepl.com/v2/translate" \
        -H "Authorization: DeepL-Auth-Key $DEEPL_API_KEY" \
        -d "text=$text" \
        -d "target_lang=${LANG}" \
        | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['translations'][0]['text'])"
}

translate_google() {
    local text="$1"
    python3 -c "
from googletrans import Translator
t = Translator()
result = t.translate('''$text''', dest='${LANG}')
print(result.text)
"
}

# ── 翻译单个文件 ─────────────────────────────
translate_file() {
    local src_file="$1"   # 相对路径
    local abs_file="$2"   # 绝对路径

    # 跳过已是目标语言的文件
    if [[ "$src_file" == *"${LANG}"* ]]; then
        echo "  跳过（已是目标语言）: $src_file"
        return
    fi

    local ext="${src_file##*.}"
    local basename="${src_file%.*}"

    # 目标文件路径：i18n/<basename>.<LANG>.<ext>
    local target="$I18N_DIR/${basename}.${LANG}.${ext}"

    echo "  翻译: $src_file → $(basename "$target")"

    # 读取原文
    local content
    content=$(cat "$abs_file")

    # 翻译
    local translated
    if [[ "$TRANSLATOR" == "--google" ]]; then
        translated=$(translate_google "$content")
    else
        if [[ -z "$DEEPL_API_KEY" ]]; then
            echo "  错误: 需要设置 DEEPL_API_KEY 环境变量"
            echo "  export DEEPL_API_KEY=your_key_here"
            return 1
        fi
        translated=$(translate_deepl "$content")
    fi

    # 写入目标文件
    echo "$translated" > "$target"
    echo "    ✓ $target"
}

# ── 主逻辑 ──────────────────────────────────
echo "=== 翻译工作流 ==="
echo "  目标语言: $LANG"
echo "  翻译器: ${TRANSLATOR#--}"
echo "  i18n 目录: $I18N_DIR"
echo ""

# 判断是文件还是目录
if [[ -f "$PROJECT_ROOT/$SOURCE" ]]; then
    # 单文件
    translate_file "$SOURCE" "$PROJECT_ROOT/$SOURCE"
elif [[ -d "$PROJECT_ROOT/$SOURCE" ]]; then
    # 目录：批量翻译
    echo "=== 批量翻译目录: $SOURCE ==="
    find "$PROJECT_ROOT/$SOURCE" -type f \( -name "*.md" -o -name "*.txt" \) | sort | while read abs_file; do
        # 计算相对于项目根的路径
        rel_file="${abs_file#$PROJECT_ROOT/}"
        translate_file "$rel_file" "$abs_file"
    done
else
    echo "错误: 找不到文件或目录: $PROJECT_ROOT/$SOURCE"
    exit 1
fi

echo ""
echo "✓ 翻译完成。输出目录: $I18N_DIR"
