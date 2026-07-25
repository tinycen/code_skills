# 仓库获取规范

所有涉及远程仓库的克隆与更新操作，统一遵循以下规范，确保路径一致、行为可复现。

> 路径规则：`<workspace>/repos/<域名>/<仓库名>`，其中 `<workspace>` 为与技能根目录平级的 `workspace` 目录；域名根据仓库地址自动识别（github.com → github，cnb.cool → cnb）。所有克隆/拉取操作必须显式指定该绝对路径，禁止依赖默认目录或相对路径。

---

## GitHub SSH 密钥检查与配置（仅 GitHub）

首次从 GitHub 拉取/推送代码前，必须执行以下检查流程，确保 SSH 认证可用：

1. **检查本地是否存在 SSH 密钥**
   - 检查默认密钥路径：`~/.ssh/id_ed25519.pub` 或 `~/.ssh/id_rsa.pub`
   - 若存在：进入步骤 2
   - 若不存在：进入步骤 3（自动生成）

2. **测试 SSH 连接**
   - 执行 `ssh -T git@github.com`
   - 若返回 `Hi <username>! You've successfully authenticated...`：检查通过，继续后续操作
   - 若返回 `Permission denied` 或连接失败：进入步骤 4（权限重试）

3. **自动生成 SSH 密钥（无密钥时）**
   - 生成 ed25519 密钥对：
     ```bash
     ssh-keygen -t ed25519 -C "code-review@automation" -f ~/.ssh/id_ed25519 -N ""
     ```
   - 读取公钥内容：`cat ~/.ssh/id_ed25519.pub`
   - **将公钥内容发送给用户**，并提示：
     > 检测到本地未配置 GitHub SSH 密钥，已自动生成。请将以下公钥添加到 GitHub 账号的 **Settings → SSH and GPG keys → New SSH key** 中，添加完成后告知我，我将继续执行。\n\n`<公钥内容>`
   - 等待用户确认已添加后，重新执行步骤 2

4. **已有密钥但权限不足（GitHub SSH 权限重试）**
   - 当克隆或推送因 `Permission denied (publickey)` 或 `Could not read from remote repository` 失败时：
     - **不重新生成 SSH 密钥**（避免之前的配置失效）
     - 读取当前使用的公钥内容（`~/.ssh/id_ed25519.pub` 或 `~/.ssh/id_rsa.pub`）
     - **将公钥内容发送给用户**，并提示：
       > 当前 SSH 密钥无法访问目标仓库，可能是该仓库需要额外权限，或密钥尚未添加到 GitHub 账号。请将以下公钥添加到 GitHub 账号的 **Settings → SSH and GPG keys → New SSH key** 中，或确认该密钥对目标仓库有访问权限。处理完成后告知我，我将继续执行。\n\n`<公钥内容>`
     - 等待用户确认后，重新尝试失败的 Git 操作

---

## 克隆仓库

### 优先级策略

当本地不存在目标仓库时，按以下优先级尝试克隆到路径规则指定的绝对路径：

1. SSH 克隆（如 `git@github.com:org/repo.git`）
2. HTTPS 克隆（如 `https://github.com/org/repo.git`）
3. 镜像加速克隆（如 `https://ghproxy.com/https://github.com/org/repo.git`）
4. 其他可用代理或镜像源

→ 若所有方式均失败，终止流程并报告网络/配置问题。

### 操作命令

```bash
# GitHub - 方式1：SSH（优先）
git clone git@github.com:<组织>/<仓库名>.git <workspace>/repos/github/<仓库名>

# GitHub - 方式2：HTTPS（SSH 失败时尝试）
git clone https://github.com/<组织>/<仓库名>.git <workspace>/repos/github/<仓库名>

# GitHub - 方式3：镜像加速（网络受限时尝试，示例使用 ghproxy）
git clone https://ghproxy.com/https://github.com/<组织>/<仓库名>.git <workspace>/repos/github/<仓库名>

# GitHub - 方式4：其他可用镜像（如 fastgit、ghps.cc 等，根据实际情况选择）
git clone https://mirror.ghproxy.com/https://github.com/<组织>/<仓库名>.git <workspace>/repos/github/<仓库名>

# CNB
git clone git@cnb.cool/<组织>/<仓库名>.git <workspace>/repos/cnb/<仓库名>
```

---

## 更新本地仓库

### 更新步骤

当本地已存在目标仓库时：

1. 进入该仓库目录
2. 执行 `git reset --hard HEAD` 重置本地修改
3. 执行 `git clean -fd` 清理未跟踪文件
4. 执行 `git pull origin main` 拉取最新代码

### 操作命令

```bash
cd <workspace>/repos/<域名>/<仓库名>
git reset --hard HEAD
git clean -fd
git pull origin main
```

---

## 版本信息获取

```bash
# 获取当前 HEAD 的最新 tag（适用于工作流触发场景）
git describe --tags --abbrev=0

# 获取仓库全局最新 tag（适用于定时触发场景，对比版本号）
# 注意：不要直接用 git describe 对比 origin/<分支>，否则远程分支在 tag 后若有新提交，会产生 v0.5.9-5-g1da1189 这类后缀，导致与本地 tag 名称 v0.5.9 误判为不一致
git describe --tags --abbrev=0 $(git rev-list --tags --max-count=1)

# 获取远程最新 tag（适用于定时触发场景，直接解析远程 tag 列表）
# ⚠️ 重要：该命令可能因网络超时返回空值。必须捕获输出并检查非空，若为空则最多重试 3 次（每次间隔 5 秒），
# 若仍失败则终止审查流程并向用户反馈"无法获取远程仓库 tag 信息，请检查网络连接或仓库访问权限"
git ls-remote --tags --sort=-creatordate origin | grep -v '\^{}' | head -n 1 | awk '{print $2}' | sed 's|refs/tags/||'

# 获取远程 HEAD（适用于定时触发场景，对比 commit 变更）
# ⚠️ 重要：该命令可能因网络超时返回空值。必须捕获输出并检查非空，若为空则最多重试 3 次（每次间隔 5 秒），
# 若仍失败则终止审查流程并向用户反馈"无法获取远程仓库 HEAD 信息，请检查网络连接或仓库访问权限"
git ls-remote origin HEAD | awk '{print $1}'

# 获取最近提交（截止提交）
git log -1 --pretty=format:"%H %s"

# 获取远程更新信息（定时触发场景）
# 仅在前述远程信息获取成功后才执行
git fetch origin --tags
```
