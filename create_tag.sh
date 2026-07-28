#!/bin/bash
# bash create_tag.sh

PROJECT_DIR="code-review"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Project directory: $PROJECT_DIR"

TAG_NAME="v1.2.0"

echo "Tag to create: $TAG_NAME"

# 检查 SKILL.md 是否存在
if [ ! -f "$SCRIPT_DIR/$PROJECT_DIR/SKILL.md" ]; then
    echo "Error: SKILL.md not found in $PROJECT_DIR"
    exit 1
fi

# 检查 tag 是否已存在
if git rev-parse "$TAG_NAME" >/dev/null 2>&1; then
    echo "Error: Tag $TAG_NAME already exists locally."
    exit 1
fi

if git ls-remote --tags origin | grep -q "refs/tags/$TAG_NAME"; then
    echo "Error: Tag $TAG_NAME already exists on remote."
    exit 1
fi

# 显示创建前 3 个本地标签
echo "Before create tag, latest 3 local tags:"
git tag -l | sort -V | tail -n 3

# 显示创建前 3 个远程标签
echo "Before create tag, latest 3 remote tags:"
git ls-remote --tags origin | awk '{print $2}' | sed 's/refs\/tags\///' | sort -V | tail -n 3

# 创建本地标签并推送到远程
git tag "$TAG_NAME"
git push origin "$TAG_NAME"

# 显示创建后 3 个本地标签
echo "After create tag, latest 3 local tags:"
git tag -l | sort -V | tail -n 3

# 显示创建后 3 个远程标签
echo "After create tag, latest 3 remote tags:"
git ls-remote --tags origin | awk '{print $2}' | sed 's/refs\/tags\///' | sort -V | tail -n 3

echo "Tag $TAG_NAME created and pushed successfully."
echo "GitHub Actions workflow 'Release to ClawHub' will be triggered automatically."
