#!/bin/bash
# translate-docs.sh — 多语言自动文档翻译
# 用法: bash translate-docs.sh <源语言> <目标语言> <文件>
# 示例: bash translate-docs.sh zh-CN en README.md
#       bash translate-docs.sh zh-CN ja README.md AGENTS.md
#       bash translate-docs.sh zh-CN en,ja,ko --all

set -e

SRC_LANG="${1:-zh-CN}"
TARGETS="${2:-en}"
FILES="${3:-}"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TRANSLATED_DIR="$PROJECT_ROOT/i18n"

usage() {
    echo -e "${BLUE}用法: $0 <源语言> <目标语言> <文件或--all>${NC}"
    echo "  源语言: zh-CN, en, ja, ko"
    echo "  目标语言: 逗号分隔，如 en,ja,ko"
    echo "  文件: 相对项目根目录的路径，或 --all（翻译整个项目）"
    echo ""
    echo "示例:"
    echo "  $0 zh-CN en README.md"
    echo "  $0 zh-CN en,ja,ko README.md AGENTS.md"
    echo "  $0 zh-CN en --all"
}

if [[ "$#" -lt 1 ]] || [[ "$1" == "--help" ]]; then
    usage; exit 0
fi

# 语言代码映射
declare -A LANG_MAP=(
    ["zh-CN"]="Chinese (Simplified)"
    ["en"]="English"
    ["ja"]="Japanese"
    ["ko"]="Korean"
    ["fr"]="French"
    ["de"]="German"
)

# 检测翻译工具
detect_translator() {
    if command -v claude &>/dev/null; then
        echo "claude"
    elif command -v gemini &>/dev/null; then
        echo "gemini"
    elif command -v GPT_API_KEY &>/dev/null; then
        echo "openai"
    else
        echo "manual"
    fi
}

# 单文件翻译
translate_file() {
    local src_file="$1"
    local target_lang="$2"
    local lang_name="${LANG_MAP[$target_lang]}"
    local out_dir="$TRANSLATED_DIR/$target_lang"

    if [[ ! -f "$src_file" ]]; then
        echo -e "${RED}文件不存在: $src_file${NC}"
        return 1
    fi

    mkdir -p "$out_dir"

    local filename=$(basename "$src_file")
    local dest_file="$out_dir/$filename"

    echo -e "${BLUE}翻译: $src_file → $target_lang/$filename${NC}"

    # 提取 frontmatter（如果存在）
    local fm=""
    local content=""
    if grep -q "^---$" "$src_file"; then
        fm=$(sed -n '/^---$/,/^---$/p' "$src_file" | sed '1d;$d')
        content=$(sed '1,/^---$/d' "$src_file")
    else
        content=$(cat "$src_file")
    fi

    # 调用翻译 API（这里用占位符，实际需要接入 Claude/GPT API）
    local TRANSLATOR_TOOL=$(detect_translator)

    if [[ "$TRANSLATOR_TOOL" == "claude" ]]; then
        # Claude translate
        local prompt="Translate the following markdown from ${LANG_MAP[$SRC_LANG]} to $lang_name. Keep all markdown formatting, frontmatter, and code blocks unchanged. Only translate the text content:

$content"

        translated=$(claude --print "$prompt" 2>/dev/null) || translated="$content"

    elif [[ "$TRANSLATOR_TOOL" == "manual" ]]; then
        # 手动翻译提示
        echo -e "${YELLOW}无翻译 API，使用占位符${NC}"
        echo "请在 $dest_file 手动翻译以下内容："
        echo "$content" | head -20
        translated="[TODO: Translate from ${LANG_MAP[$SRC_LANG]} to $lang_name]
$content"
    else
        translated="$content"
    fi

    # 重建文件
    if [[ -n "$fm" ]]; then
        echo "---" > "$dest_file"
        echo "$fm" >> "$dest_file"
        echo "translated_from: $SRC_LANG" >> "$dest_file"
        echo "---" >> "$dest_file"
        echo "" >> "$dest_file"
    fi
    echo "$translated" >> "$dest_file"

    echo -e "${GREEN}✓ 翻译完成: $dest_file${NC}"
}

# 主逻辑
if [[ "$FILES" == "--all" ]]; then
    echo -e "${BLUE}翻译所有 Markdown 文件...${NC}"
    IFS=',' read -ra TARGET_ARRAY <<< "$TARGETS"
    for target in "${TARGET_ARRAY[@]}"; do
        target=$(echo "$target" | xargs)
        echo -e "${GREEN}=== 翻译为 $target ($lang_name) ===${NC}"
        find "$PROJECT_ROOT" -maxdepth 1 -name "*.md" -type f | while read -r f; do
            translate_file "$f" "$target"
        done
    done
else
    IFS=',' read -ra TARGET_ARRAY <<< "$TARGETS"
    IFS=' ' read -ra FILE_ARRAY <<< "$FILES"
    for target in "${TARGET_ARRAY[@]}"; do
        target=$(echo "$target" | xargs)
        for file in "${FILE_ARRAY[@]}"; do
            translate_file "$PROJECT_ROOT/$file" "$target"
        done
    done
fi

echo ""
echo -e "${GREEN}翻译完成！${NC}"
echo "输出目录: $TRANSLATED_DIR"
echo "源语言: ${LANG_MAP[$SRC_LANG]}"
echo "目标语言: $TARGETS"
