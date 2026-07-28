# ClawHub 自动发布工作流说明

> 记录日期：2026-07-28
> 主题：通过 GitHub Actions 在推送 tag 后自动将 `code-review` 技能发布到 ClawHub。

## 一、变更内容概览

| 文件 | 类型 | 说明 |
|------|------|------|
| `.github/workflows/skill-publish.yml` | 新增/修改 | ClawHub 技能发布**可复用工作流**（`workflow_call`），参考 `references/skill-publish.yml`，但改为通过输入参数显式指定 ClawHub CLI 来源仓库 |
| `.github/workflows/release-clawhub.yml` | 新增 | **tag 触发工作流**，推送 `v*` 标签时调用上面的可复用工作流 |
| `create_tag.sh` | 重写 | 适配本项目：版本号硬编码在脚本 `TAG_NAME` 变量中，创建并推送 tag |

## 二、发布流程

```mermaid
flowchart LR
    A[更新 create_tag.sh 中的 TAG_NAME] --> B[bash create_tag.sh]
    B --> C[创建并推送 v{VERSION} 标签]
    C --> D[触发 Release to ClawHub 工作流]
    D --> E[调用 skill-publish.yml]
    E --> F[发布 code-review 到 ClawHub]
```

### 使用步骤

1. （手动）更新 `create_tag.sh` 中的 `TAG_NAME` 变量（如 `TAG_NAME="v1.2.0"`），同时（手动）更新 `SKILL.md` frontmatter 的 `version` 与 `README.md` 的版本表格。
2. 执行：

   ```bash
   bash create_tag.sh
   ```

3. 脚本会校验 `SKILL.md` 是否存在、tag 在本地/远程是否重复，然后创建并推送 `v{VERSION}` 标签。
4. GitHub Actions 自动运行 `Release to ClawHub` 工作流，将技能发布到 ClawHub。

### 使用前准备

在仓库 **GitHub Settings → Secrets and variables → Actions** 中添加 Secret：

- `CLAWHUB_TOKEN`：ClawHub 发布 Token（真实发布必需，`dry_run: false` 时缺失会报错退出）。

## 三、常见问题（Q&A）

### Q1：为什么有 2 个 workflow 文件？`clawhub_token` 和 `CLAWHUB_TOKEN` 大小写为什么不一样？

**两个文件的分工：**

- `skill-publish.yml`：可复用工作流（`on: workflow_call`），定义"怎么发布到 ClawHub"的通用逻辑，**本身不会自动运行**。
- `release-clawhub.yml`：实际触发入口，推送 `v*` 标签时调用 `skill-publish.yml`。

**大小写差异是 GitHub Actions 的 secrets 映射语法：**

```yaml
secrets:
  被调用工作流的参数名: ${{ secrets.仓库里的Secret名 }}
```

即：

```yaml
secrets:
  clawhub_token: ${{ secrets.CLAWHUB_TOKEN }}
```

- 左边小写 `clawhub_token`：`skill-publish.yml` 中定义的**输入参数名**（接口名）。
- 右边大写 `CLAWHUB_TOKEN`：仓库中实际配置的 **Secret 名称**（按惯例大写）。

### Q2：ClawHub 上没有仓库能发布吗？技能已发布过，更新能自动对应吗？

本技能已发布至 ClawHub：`https://clawhub.ai/tinycen/skills/code-review`，因此当前场景是**更新已有技能版本**。

`skill-publish.yml` 通过 `owner` + 技能目录名（slug，即 `code-review`）标识 ClawHub 上的技能，并附带 `--source-repo`、`--source-commit`、`--source-path` 等来源信息。CLI 返回三种状态：

| 状态 | 含义 |
|------|------|
| `would-publish` | dry-run 预览，将会发布 |
| `published` | 有变更，已发布新版本 |
| `unchanged` | 内容无变化，跳过（alreadySynced） |

因此**更新已有技能可以自动对应**，前提是 `owner`（`@tinycen`）和技能 slug 与 ClawHub 上已有的一致。`release-clawhub.yml` 中已配置：

```yaml
with:
  root: code-review
  dry_run: false
  owner: "@tinycen"
  tags: latest
```

### Q3：ClawHub 的 Catalog metadata（Categories / Topics）会自动填充吗？

**不会。** 根据 [OpenClaw Skill format 文档](https://docs.openclaw.ai/clawhub/skill-format)，`SKILL.md` frontmatter 仅支持以下字段：

- `name`、`description`、`version`（根级字段）
- `metadata.openclaw`（运行时元数据：`requires.env`、`requires.bins`、`primaryEnv`、`envVars`、`emoji`、`homepage`、`os` 等）

文档中**没有定义** `categories`、`topics` 字段。因此 ClawHub 页面上的：

- Categories：`Development`、`Productivity`、`Agents`
- Topics：`#code`、`#code-review`、`#automation`、`#quality-assurance`、`#python`

属于 ClawHub 网站的 Catalog metadata，需要在 **ClawHub 后台页面手动配置并保存**，无法通过 `SKILL.md` 或 workflow 自动填充。

### Q4：为什么 `skill-publish.yml` 不通过 OIDC 自动解析 ClawHub CLI 来源？

原版 `references/skill-publish.yml` 使用 GitHub OIDC 令牌中的 `job_workflow_ref` 来自动定位可复用工作流所在的仓库，再从该仓库 checkout CLI 源码。

但在本项目中，`release-clawhub.yml` 调用的是**本地副本** `./.github/workflows/skill-publish.yml`，OIDC 会错误地把来源解析为当前仓库 `code_skills`，导致 `bun install` 时找不到 `package.json`。

因此本地副本做了以下调整：

- 新增 `clawhub_source_repo` / `clawhub_source_ref` 输入参数（默认 `openclaw/clawhub@main`）。
- 移除 OIDC 解析步骤和 `id-token: write` 权限。
- 直接通过输入参数 checkout ClawHub CLI 源码。

这样 `skill-publish.yml` 仍作为本地可复用工作流存在，与 `release-clawhub.yml` 的两层结构保持不变，同时避免了 OIDC 自引用问题。

## 四、关键文件说明

### `.github/workflows/release-clawhub.yml`

```yaml
name: Release to ClawHub

on:
  push:
    tags:
      - 'v*'

permissions:
  contents: read

jobs:
  publish-skill:
    uses: ./.github/workflows/skill-publish.yml
    with:
      root: code-review
      dry_run: false
      owner: "@tinycen"
      tags: latest
      registry: https://clawhub.ai
      site: https://clawhub.ai
      clawhub_source_repo: openclaw/clawhub
      clawhub_source_ref: main
    secrets:
      clawhub_token: ${{ secrets.CLAWHUB_TOKEN }}
```

### `skill-publish.yml` 核心步骤

1. Checkout 仓库代码，安装 Bun。
2. 通过输入参数 `clawhub_source_repo` / `clawhub_source_ref` 显式 checkout ClawHub CLI 源码（默认 `openclaw/clawhub@main`）。
3. 校验发布模式：非 dry-run 时必须提供 `clawhub_token`。
4. 写入 ClawHub 配置（registry + token）。
5. 定位技能目录（含 `SKILL.md` 的目录），逐个执行 `skill publish`。
6. 输出结构化 JSON 结果（`published` / `unchanged` / `failed` 等）并上传为 artifact。

### `create_tag.sh` 关键逻辑

1. 版本号硬编码在脚本中的 `TAG_NAME` 变量（如 `TAG_NAME="v1.2.0"`），每次发版前手动修改。
2. 前置校验：`SKILL.md` 存在、tag 本地/远程均不重复。
3. 创建本地 tag 并推送到 `origin`，触发 GitHub Actions。
4. 前后各展示最新 3 个本地/远程 tag 便于确认。

## 五、注意事项

- 发版前需保持三处版本号一致：`create_tag.sh` 中的 `TAG_NAME`、`code-review/SKILL.md` frontmatter 的 `version`、`README.md` 技能列表表格。
- `dry_run` 默认值为 `true`（可复用工作流中定义），`release-clawhub.yml` 已显式设为 `false` 执行真实发布。
- 若发布失败，可在 Actions 运行记录中下载 `clawhub-skill-publish-json` artifact 查看结构化错误信息。
