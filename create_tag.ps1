# ./create_tag.ps1
# 功能：从 code-review/SKILL.md 读取版本号，创建并推送 v<version> 标签到 github 远程，
#       随后将 code-review 目录打包为 zip 文件（使用 PowerShell 内置 Compress-Archive）

$ErrorActionPreference = "Stop"

$PROJECT_DIR = "code-review"

# 获取当前脚本所在目录
$SCRIPT_DIR = $PSScriptRoot

Write-Host "Project directory: $PROJECT_DIR"

$SKILL_MD = Join-Path $SCRIPT_DIR "$PROJECT_DIR\SKILL.md"

# 检查 SKILL.md 是否存在
if (-not (Test-Path $SKILL_MD)) {
    Write-Host "Error: SKILL.md not found in $PROJECT_DIR"
    exit 1
}

# 从 SKILL.md 读取 version 并生成 tag
$VERSION = (Select-String -Path $SKILL_MD -Pattern '^version:\s*(\S+)' | Select-Object -First 1).Matches[0].Groups[1].Value
if ([string]::IsNullOrWhiteSpace($VERSION)) {
    Write-Host "Error: Could not parse version from $PROJECT_DIR/SKILL.md"
    exit 1
}

$TAG_NAME = "v$VERSION"

Write-Host "Tag to create: $TAG_NAME"

# 检查 tag 是否已存在（本地）
if (git rev-parse "$TAG_NAME" 2>$null) {
    Write-Host "Error: Tag $TAG_NAME already exists locally."
    exit 1
}

# 检查 tag 是否已存在（远程）
$remoteTag = git ls-remote --tags github 2>$null | Select-String "refs/tags/$TAG_NAME`$"
if ($remoteTag) {
    Write-Host "Error: Tag $TAG_NAME already exists on remote."
    exit 1
}

# 标签排序辅助函数：尝试按语义化版本排序，失败时回退字符串排序
function Sort-Tags {
    param([string[]]$Tags)
    $Tags | Sort-Object {
        try { [version]($_.TrimStart('v')) } catch { [version]"0.0.0" }
    }
}

# 显示创建前 3 个本地标签
Write-Host "Before create tag, latest 3 local tags:"
Sort-Tags (git tag -l) | Select-Object -Last 3

# 显示创建前 3 个远程标签
Write-Host "Before create tag, latest 3 remote tags:"
Sort-Tags (@(git ls-remote --tags github) | ForEach-Object { ($_ -split "`t")[-1] -replace '^refs/tags/', '' }) | Select-Object -Last 3

# 创建本地标签并推送到远程
git tag $TAG_NAME
if ($LASTEXITCODE -ne 0) { Write-Host "Error: Failed to create tag $TAG_NAME"; exit 1 }

git push github $TAG_NAME
if ($LASTEXITCODE -ne 0) { Write-Host "Error: Failed to push tag $TAG_NAME"; exit 1 }

# 显示创建后 3 个本地标签
Write-Host "After create tag, latest 3 local tags:"
Sort-Tags (git tag -l) | Select-Object -Last 3

# 显示创建后 3 个远程标签
Write-Host "After create tag, latest 3 remote tags:"
Sort-Tags (@(git ls-remote --tags github) | ForEach-Object { ($_ -split "`t")[-1] -replace '^refs/tags/', '' }) | Select-Object -Last 3

Write-Host "Tag $TAG_NAME created and pushed successfully."
Write-Host "GitHub Actions workflow 'Release to ClawHub' will be triggered automatically."

# ---------- 打包 code-review 目录为 zip ----------
Write-Host ""
Write-Host "Packing $PROJECT_DIR into zip..."

$ZIP_NAME = "$PROJECT_DIR`_$TAG_NAME.zip"
$ZIP_PATH = Join-Path $SCRIPT_DIR $ZIP_NAME

# 若已存在同名 zip 则先删除
if (Test-Path $ZIP_PATH) {
    Remove-Item -Path $ZIP_PATH -Force
}

# 使用 PowerShell 内置 Compress-Archive 打包（目录本身作为 zip 根目录）
Compress-Archive -Path (Join-Path $SCRIPT_DIR $PROJECT_DIR) -DestinationPath $ZIP_PATH -Force

if (Test-Path $ZIP_PATH) {
    $zipSize = "{0:F2}" -f ((Get-Item $ZIP_PATH).Length / 1KB)
    Write-Host "Zip created successfully: $ZIP_PATH ($zipSize KB)"
} else {
    Write-Host "Error: Failed to create zip file $ZIP_PATH"
    exit 1
}
