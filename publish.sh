#!/bin/bash
# vibe-coding-ros2 发布脚本
# 本脚本仅用于生成本地发布包，不再直接推送到主仓库
# 所有贡献必须通过 Fork + Pull Request 方式提交
# 详见贡献指南: i18n/zh-CN/CONTRIBUTING.md 或 i18n/en/CONTRIBUTING.md

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

ORG_NAME="MIUAV"
REPO_NAME="vibe-coding-ros2"
MAIN_BRANCH="latest"

echo "========================================"
echo "vibe-coding-ros2 发布准备"
echo "========================================"

echo ""
echo "[信息] 本项目采用 Fork + Pull Request 协作模式"
echo "[信息] 禁止直接推送到主仓库"
echo "[信息] 详见: i18n/zh-CN/CONTRIBUTING.md"
echo ""

# 检查是否是 git 仓库
if [ ! -d .git ]; then
    echo "[错误] 当前目录不是 Git 仓库"
    exit 1
fi

# 显示当前分支状态
echo "[1/5] 检查当前仓库状态..."
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "未在分支上")
echo "  当前分支: ${CURRENT_BRANCH}"
echo "  远程仓库: $(git remote get-url origin 2>/dev/null || echo '未配置')"

# 显示待提交的变更
echo ""
echo "[2/5] 待提交的变更..."
if git status --porcelain | grep -q .; then
    git status --short
else
    echo "  (无变更)"
fi

# 合并提交为单次发布
echo ""
echo "[3/5] 合并提交 (可选)..."
read -p "是否将所有变更合并为单次提交? (y/N): " CONFIRM
if [[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" ]]; then
    # 交互式获取提交信息
    read -p "输入提交标题: " COMMIT_TITLE
    read -p "输入提交描述 (可选): " COMMIT_BODY
    
    FIRST_COMMIT=$(git rev-list --max-parents=0 HEAD 2>/dev/null || echo "")
    if [ -n "$FIRST_COMMIT" ]; then
        git reset --soft $FIRST_COMMIT
        git add -A
        git reset publish.sh
        git commit -m "${COMMIT_TITLE}" -m "${COMMIT_BODY}"
        echo "  提交完成: ${COMMIT_TITLE}"
    else
        echo "  [警告] 已是首次提交，跳过合并"
    fi
fi

# 生成发布指南
echo ""
echo "[4/5] 生成发布指南..."
RELEASE_NOTE="${SCRIPT_DIR}/RELEASE_NOTES.md"
cat > "${RELEASE_NOTE}" << EOF
# 发布说明

日期: $(date '+%Y-%m-%d')
版本: v$(git describe --tags --always --dirty 2>/dev/null || echo 'dev')

## 当前提交

$(git log --oneline -5)

## 下一步操作

如需发布你的更改，请执行以下步骤:

1. 推送到你的 Fork 仓库
   git push origin ${CURRENT_BRANCH}

2. 在 GitHub 创建 Pull Request
   https://github.com/${ORG_NAME}/${REPO_NAME}/compare/${MAIN_BRANCH}...YOUR_BRANCH

3. 等待 Maintainer 审核

4. 审核通过后合并

详细流程见 CONTRIBUTING 文档。
EOF
echo "  已生成: ${RELEASE_NOTE}"

# 显示最终说明
echo ""
echo "[5/5] 发布准备完成"
echo "========================================"
echo ""
echo "如需发布更改到主仓库，请按以下步骤操作:"
echo ""
echo "  1. 推送到你的 Fork 仓库"
echo "     git push origin ${CURRENT_BRANCH}"
echo ""
echo "  2. 在 GitHub 创建 Pull Request"
echo "     访问: https://github.com/${ORG_NAME}/${REPO_NAME}/compare/${MAIN_BRANCH}"
echo ""
echo "  3. 等待 Maintainer 审核后合并"
echo ""
echo "详细贡献流程请参阅: i18n/zh-CN/CONTRIBUTING.md"
echo "========================================"
