#!/bin/bash
# bash create_tag.sh

PROJECT_DIR="code-review"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Project directory: $PROJECT_DIR"

# 检查 SKILL.md 是否存在
if [ ! -f "$SCRIPT_DIR/$PROJECT_DIR/SKILL.md" ]; then
    echo "Error: SKILL.md not found in $PROJECT_DIR"
    exit 1
fi

# 从 SKILL.md 读取 version 并生成 tag
VERSION=$(grep -E '^version:' "$SCRIPT_DIR/$PROJECT_DIR/SKILL.md" | head -n 1 | sed -E 's/^version:[[:space:]]*//' | tr -d '[:space:]')
if [ -z "$VERSION" ]; then
    echo "Error: Could not parse version from $PROJECT_DIR/SKILL.md"
    exit 1
fi

TAG_NAME="v$VERSION"

echo "Tag to create: $TAG_NAME"

# 可选：提示 README.md 中的版本是否一致
README_VERSION=$(grep -E "\|\s*\[?$PROJECT_DIR\]?\(" "$SCRIPT_DIR/README.md" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n 1 || true)
if [ -n "$README_VERSION" ] && [ "$README_VERSION" != "$VERSION" ]; then
    echo "Warning: README.md shows version $README_VERSION, but $PROJECT_DIR/SKILL.md has $VERSION"
fi

# 检查 tag 是否已存在
if git rev-parse "$TAG_NAME" >/dev/null 2>&1; then
    echo "Error: Tag $TAG_NAME already exists locally."
    exit 1
fi

if git ls-remote --tags github | grep -q "refs/tags/$TAG_NAME"; then
    echo "Error: Tag $TAG_NAME already exists on remote."
    exit 1
fi

# 显示创建前 3 个本地标签
echo "Before create tag, latest 3 local tags:"
git tag -l | sort -V | tail -n 3

# 显示创建前 3 个远程标签
echo "Before create tag, latest 3 remote tags:"
git ls-remote --tags github | awk '{print $2}' | sed 's/refs\/tags\///' | sort -V | tail -n 3

# 创建本地标签并推送到远程
git tag "$TAG_NAME"
git push github "$TAG_NAME"

# 显示创建后 3 个本地标签
echo "After create tag, latest 3 local tags:"
git tag -l | sort -V | tail -n 3

# 显示创建后 3 个远程标签
echo "After create tag, latest 3 remote tags:"
git ls-remote --tags github | awk '{print $2}' | sed 's/refs\/tags\///' | sort -V | tail -n 3

echo "Tag $TAG_NAME created and pushed successfully."
echo "GitHub Actions workflow 'Release to ClawHub' will be triggered automatically."
