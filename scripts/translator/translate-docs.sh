#!/bin/bash
# translate-docs.sh — 多语言文档翻译工作流
# 依赖: DeepL API (DEEPL_API_KEY) 或 Google Translate (googletrans)
# 用法: ./translate-docs.sh <file_or_dir> <target_lang> [--deepl|--google]
# 示例: ./translate-docs.sh AGENTS.md zh-CN --deepl

set -e

SOURCE="${1:-}"
LANG="${2:-zh-CN}"
TRANSLATOR="${3:---deepl}"

if [[ -z "$SOURCE" ]]; then
    echo "用法: $0 <文件或目录> <目标语言> [--deepl|--google]"
    echo "  例: $0 AGENTS.md zh-CN --deepl"
    echo "  例: $0 i18n/ ja-JP --google"
    exit 1
fi

# ── 翻译器选择 ──────────────────────────────
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
    local file="$1"
    local ext="${file##*.}"
    local basename="${file%.*}"
    local lang_ext="${LANG}"
    
    # 目标文件
    local target="${basename}.${lang_ext}.${ext}"
    
    # 跳过已经是目标语言的文件
    if [[ "$file" == *"${LANG}"* ]]; then
        echo "跳过（已是目标语言）: $file"
        return
    fi
    
    echo "翻译: $file → $target"
    
    # 读取原文
    local content
    content=$(cat "$file")
    
    # 翻译
    local translated
    if [[ "$TRANSLATOR" == "--google" ]]; then
        translated=$(translate_google "$content")
    else
        if [[ -z "$DEEPL_API_KEY" ]]; then
            echo "错误: 需要设置 DEEPL_API_KEY 环境变量"
            echo "  export DEEPL_API_KEY=your_key_here"
            exit 1
        fi
        translated=$(translate_deepl "$content")
    fi
    
    # 写入目标文件
    echo "$translated" > "$target"
    echo "  ✓ 已保存: $target"
}

# ── 主逻辑 ──────────────────────────────────
if [[ -f "$SOURCE" ]]; then
    translate_file "$SOURCE"
elif [[ -d "$SOURCE" ]]; then
    echo "=== 批量翻译目录: $SOURCE ==="
    find "$SOURCE" -type f \( -name "*.md" -o -name "*.txt" \) | while read f; do
        translate_file "$f"
    done
else
    echo "错误: 找不到文件或目录: $SOURCE"
    exit 1
fi

echo ""
echo "✓ 翻译完成"
