# 安装与更新

> 本文档仅涉及 **code-review 技能本身** 的安装与更新。审查工具（Pyright、Pyrefly、pyupgrade、Ruff 等）与项目业务依赖等审查环境准备，另见 SKILL.md「📦 安装与更新 > 审查环境准备」。

本技能支持多种使用场景，请根据当前环境选择对应的安装方式。

---

## 通用方式：Prompt 安装（推荐）

> **适用所有 AI 对话场景**，无需关心技能目录、CLI 命令或工具差异。
> 只要你的工具支持技能加载和对话式安装，直接在对话中发送以下 Prompt 即可完成安装：

```
请帮我安装 code-review 技能。
来源：https://clawhub.ai/tinycen/skills/code-review
下载并放置到当前工具对应的技能目录中。
```

> 💡 若 ClawHub 官方域名在国内网络不通，可使用国内镜像源，Prompt 改为：

```
请帮我安装 code-review 技能。
来源：https://cn.clawhub-mirror.com/tinycen/code-review
下载并放置到当前工具对应的技能目录中。
```

**优势**：
- **零配置**：不需要了解技能目录路径，AI 助手会自动检测当前工具的技能存放位置
- **跨工具通用**：无论使用 Qoder、Cursor、Windsurf 还是其他 AI IDE，同一句 Prompt 即可完成
- **自动适配**：AI 助手会根据当前环境选择 CLI 安装、API 下载或其他合适的方式

同样，**更新**也可以通过 Prompt 完成：

```
请帮我更新 code-review 技能到最新版本。
来源：https://clawhub.ai/tinycen/skills/code-review
```

> 💡 同样，若官方域名网络不通，可使用国内镜像源更新：

```
请帮我更新 code-review 技能到最新版本。
来源：https://cn.clawhub-mirror.com/tinycen/code-review
```

> 💡 如果无法自动安装，请参考下方的安装方式。

---

## 场景一：OpenClaw / Claw 兼容场景

> 适用于通过 OpenClaw CLI 或兼容工具管理技能的环境。技能已托管至 [ClawHub](https://clawhub.ai/tinycen/skills/code-review)。

### 安装

#### CLI 安装

```bash
openclaw skills install @tinycen/code-review
```

安装器会将技能文件部署到 `skills/` 目录下对应目录，并同步更新 `SKILLS.md`，使 Agent 下一轮推理即可使用该技能。

#### 对话内安装

在对话中直接发送：

```
/skills install @tinycen/code-review
```

#### 安装前检查

```bash
# 查看技能详情（版本、验证状态、签名等）
openclaw skills list --verbose

# 对未验证的技能先执行扫描
openclaw skills vet @tinycen/code-review
```

> 技能页面：https://clawhub.ai/tinycen/skills/code-review

### 更新

```bash
# 更新本技能
openclaw skills update @tinycen/code-review

# 或更新工作区内所有已安装的 ClawHub 技能
openclaw skills update --all
```

对话内也可直接发送：

```
/skills update @tinycen/code-review
/skills update --all
```

#### 覆盖重装

```bash
openclaw skills install --force @tinycen/code-review
```

#### 确认更新生效

```bash
openclaw skills list --verbose
```

### 本地修改后的热重载

如果你手动修改了本地技能文件（非 ClawHub 拉取），无需重装，走重载即可：

- **自动**：`skills.load.watch: true`（默认开启）时，文件变更约 250ms 内自动注入当前 Agent 上下文
- **手动强制**：`openclaw skills reload`，不重启 Gateway，不影响正在运行的会话

> ⚠️ 以下两种情况光 reload 不够，需要 `/restart` 或开新会话：
> - 技能涉及 **Tool Policy 变更**（权限/工具白名单）
> - 修改了 **System Prompt 注入逻辑**（需在 Session 初始化时重新解析 SKILL.md）

### 版本锁定（防止自动更新覆盖）

```bash
# 锁定指定版本
openclaw skill pin --session <sid> --skill code-review --version <版本号>

# 取消锁定
openclaw skill unpin --session <sid> --skill code-review

# 批量更新所有未锁定的技能（graceful 策略会等当前任务跑完再换）
openclaw skill update-all --session <sid> --strategy graceful
```

---

## 场景二：IDE / 其他 CLI 编程场景

> 适用于 Qoder、Cursor、Open Code 等 AI IDE 或其他不依赖 OpenClaw CLI 的编程工具。
> 由于不同工具的技能目录各不相同，本场景采用「下载 + 手动放置」的通用策略。

### 首次安装

1. **下载技能包**到当前项目的 `download_skills/` 暂存目录：

```powershell
# PowerShell
$dest = "download_skills"
New-Item -ItemType Directory -Path $dest -Force | Out-Null
Invoke-WebRequest -Uri "https://clawhub.ai/api/skills/download?slug=code-review&ownerHandle=tinycen" -OutFile "$dest/code-review.zip"
Expand-Archive -Path "$dest/code-review.zip" -DestinationPath "$dest/code-review" -Force
Remove-Item "$dest/code-review.zip"
```

```bash
# Bash
mkdir -p download_skills
curl -L -o download_skills/code-review.zip "https://clawhub.ai/api/skills/download?slug=code-review&ownerHandle=tinycen"
unzip download_skills/code-review.zip -d download_skills/code-review
rm download_skills/code-review.zip
```

2. **移动到对应技能目录**：

   下载完成后，将 `download_skills/code-review/` 整个目录移动到你所用工具的技能目录中。不同工具的技能目录请参考其官方文档，例如：

   | 工具 | 项目级路径示例 | 用户级路径示例 |
   |------|--------------|--------------|
   | Qoder | `.qoder/skills/code-review/` | `~/.qoder-cn/skills/code-review/` |
   | 其他 IDE | 请参考对应工具文档 | — |

   > 💡 如果不确定技能目录位置，可咨询当前 AI 助手：「这个工具的技能目录在哪里？」

3. **删除暂存目录**（可选）：

   移动完成后可手动删除 `download_skills/` 目录以保持项目整洁。

### 更新（覆盖安装）

更新时自动检测技能已安装位置，直接覆盖更新：

1. **查找已有技能位置**：在当前项目及其上级目录中搜索包含 `code-review/SKILL.md` 的目录：

```powershell
# PowerShell - 查找已安装位置
Get-ChildItem -Path ., .. -Recurse -Filter "SKILL.md" -ErrorAction SilentlyContinue |
  Where-Object { $_.DirectoryName -like "*code-review*" } |
  Select-Object -ExpandProperty FullName
```

```bash
# Bash - 查找已安装位置
find . .. -path "*/code-review/SKILL.md" 2>/dev/null
```

2. **下载并覆盖**：将新版技能包下载到检测到的位置，覆盖旧文件（下载命令同首次安装步骤 1，将目标路径替换为检测到的技能目录）。

3. **若未检测到已有安装**：按首次安装流程重新执行。

### 本地修改后的生效

文件保存后，Agent 在下一轮对话或重新加载上下文时即可读取最新内容，无需额外操作。

---

## 国内网络环境下使用镜像安装

> ClawHub 在国内常常连接失败，因此官方推荐国内用户优先使用中国镜像地址进行安装与更新。

**等效镜像域名**：

| 地址 | 说明 |
|------|------|
| `https://cn.clawhub-mirror.com/` | 官方推荐的国内镜像地址（本技能安装路径：`https://cn.clawhub-mirror.com/tinycen/code-review`） |

**命令行切换方式（任选一种）**：

```bash
# 方式一：单次安装时指定 registry
npx clawhub@latest install 技能名 --registry=https://cn.clawhub-mirror.com

# 方式二：全局修改配置，以后默认走镜像
clawhub config set registry https://cn.clawhub-mirror.com
```

> 💡 设置 registry 后，后续所有 ClawHub 技能的安装 / 更新命令都会默认走中国镜像，无需每次都指定。

---

## 常见问题

### OpenClaw CLI `@owner/slug` 格式安装失败

**现象**：执行 `openclaw skills install @tinycen/code-review` 时报错，提示 slug 格式不合法。

**原因**：ClawHub CLI 的 `normalizeSkillSlugOrFail` 函数会拒绝包含 `/` 的 slug，但错误提示又建议使用 `@owner/slug` 格式，两者矛盾。`install`、`update` 等命令均受影响。

**临时方案**：通过 API 手动下载安装（参考「场景二 > 首次安装」的下载命令）。

---

## 速查表

| 场景 | 安装方式 | 更新方式 |
|------|---------|----------|
| **Prompt 安装（推荐）** | **对话中发送安装 Prompt（见通用方式）** | **对话中发送更新 Prompt** |
| OpenClaw CLI | `openclaw skills install @tinycen/code-review` | `openclaw skills update @tinycen/code-review` |
| OpenClaw 对话内 | `/skills install @tinycen/code-review` | `/skills update @tinycen/code-review` |
| IDE / 其他 CLI | 下载到 `download_skills/` 后移动到技能目录 | 检测已有位置，下载覆盖 |
| OpenClaw 本地修改生效 | 等 250ms 自动 / `openclaw skills reload` | — |
| OpenClaw 版本锁定 | `openclaw skill pin --session <sid> --skill code-review --version <ver>` | — |
