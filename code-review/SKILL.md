---
name: code-review
description: 代码审查 Skill - 自动化代码质量检查与报告生成工具。支持从 GitHub 等仓库克隆代码、执行多维度代码质量检查、生成结构化审查报告并按场景保存与分发。当用户提到"代码审查"、"code review"、"检查代码质量"、"审查报告"等操作时，或 当用户主动提及使用本 skill / 调用本技能 时，请使用本 skill。
version: 1.2.0
author: code-review
---

# 代码审查 Skill 使用指南

本 Skill 提供自动化代码审查能力，支持从 GitHub 仓库克隆代码、执行多维度代码质量检查、生成结构化审查报告并按场景保存与分发。

> 路径规则：`<workspace>/repos/<域名>/<仓库名>`，其中 `<workspace>` 为与技能根目录（本 SKILL.md 所在目录）平级的 `workspace` 目录（即 `<skill_root>/../workspace`）；域名根据仓库地址自动识别（github.com → github，cnb.cool → cnb）。所有克隆/拉取操作必须显式指定该绝对路径，禁止依赖默认目录或相对路径。

## 🎯 场景路由表

| 场景 | 参考文档 |
|------|---------|
| 代码审查流程与规则 | `references/review_process.md` |
| 审查报告模板 | `references/report_template.md` |
| 已忽略问题清单模板 | `references/ignored_issues_template.md` |
| 仓库获取规范 | `references/repository_access.md` |
| 安装与更新 | `references/installation.md` |

## 📁 文件目录结构

```
code-review/
├── SKILL.md                        # 入口文件（本文件），全局导航与核心规则
├── references/                     # 参考文档
│   ├── review_process.md           # 代码审查流程与规则
│   ├── report_template.md          # 审查报告模板
│   ├── ignored_issues_template.md  # 已忽略问题清单模板
│   ├── repository_access.md        # 仓库获取规范
│   ├── installation.md             # 安装与更新
│   ├── python_dependency_installation/          # Python 依赖安装
│   │   ├── review_tools.md                      # 审查工具依赖安装
│   │   └── project_dependencies.md              # 项目业务依赖安装
│   ├── frontend_dependency_installation/        # 前端依赖安装
│   │   ├── node_environment.md                  # Node 环境管理（Volta）
│   │   └── project_dependencies.md              # 前端项目业务依赖安装
│   └── language_checks/                         # 语言专项检查
│       ├── python_type_check.md                 # Python 类型检查
│       ├── python_pypi_packaging.md             # Python PyPI 包依赖与打包
│       └── typescript_javascript_check.md       # TypeScript/JavaScript 检查
```

**报告输出目录结构**（在项目 `docs/code_reviews/` 下自动生成）：

```
docs/code_reviews/
├── <日期>-<模型>-代码审查报告.md    # 新生成的审查报告（待用户处理）
├── fixed/                          # 待工具扫描的收件箱（用户手动放入已审阅报告）
│   └── <日期>-<模型>-代码审查报告.md
├── archived/                       # 已被工具扫描归档的报告（不再重复扫描）
│   ├── <日期>-<模型>-代码审查报告.md
│   └── ...
└── ignored_issues.md               # 已忽略问题清单（自动维护，跨次审查持久化）
```

> `fixed/` 与 `archived/` 目录说明：
> - **`fixed/`（收件箱）**：用户查看报告后，将已确认处理（标记了忽略或修复了问题）的报告移至 `fixed/` 目录。
> - **`archived/`（归档）**：工具在审查前扫描 `fixed/` 目录中的报告提取忽略标记后，**自动把 `fixed/` 下全部报告移动到 `archived/` 目录**，使 `fixed/` 保持为空。下次审查只扫描用户新放入 `fixed/` 的报告，避免重复扫描。
> - **报告扫描范围**（指工具提取忽略标记时扫描的报告范围，区别于审查流程中对代码文件的扫描）：仅扫描 `fixed/`，不扫描 `archived/`（已归档），也不扫描根目录下的新生成报告。
> - **原报告引用**：`ignored_issues.md` 中「原报告」字段只记录文件名，对应文件已归档于 `docs/code_reviews/archived/` 子目录。

## 🔧 核心工作流

> **场景判断**：执行前必须先确定当前场景，选择对应工作流，**禁止混用**。
> - 若用户主动要求审查代码（如"帮我审查代码"、"检查代码质量"），使用**工作流一（手动触发）**—— 无条件执行完整审查。
> - 若当前为定时任务、自动化调度触发，或用户明确说"定时触发"、"scheduled trigger"，使用**工作流二（定时触发）**—— 必须按条件判断是否触发审查，条件不满足时直接终止流程。

### 工作流一：手动触发代码审查

```
步骤 1：确定审查场景与目标位置
  → 判断当前为本地审查场景还是远程对话场景
  → 远程对话场景 / 插件工具场景（如 Open Claw）：
     - 用户提供仓库 SSH 地址（如 git@github.com:org/repo.git）
     - 解析域名与仓库名，按照路径规则计算本地绝对路径
     - 进入步骤 2
  → 本地审查场景（含在代码仓库内直接触发此技能）：
     - 用户直接提供本地代码路径，或当前工作目录即为目标代码仓库
     - 若路径不存在：终止流程并报告本地仓库路径不存在
     - 若路径存在：直接使用当前本地代码，记录来源为「本地已存在」

步骤 2：获取远程代码（仅远程对话场景执行）
  → 若目标为 GitHub 仓库：先执行「仓库获取规范 > GitHub SSH 密钥检查与配置」流程
  → 按路径规则计算目标本地绝对路径，检查该路径是否已存在仓库代码
  → 若已存在：按「仓库获取规范 > 更新本地仓库」执行更新，记录来源为「本地已存在」
  → 若不存在：按「仓库获取规范 > 克隆仓库」执行克隆，记录实际使用的来源方式
  → 若克隆/推送过程中因权限被拒绝：执行「仓库获取规范 > GitHub SSH 权限重试」流程

步骤 3：获取版本信息
  → 执行 git describe --tags --abbrev=0 获取最新 tag 版本号
  → 执行 git log -1 --pretty=format:"%H %s" 获取最近提交信息（截止提交）

步骤 4：扫描已整理报告并更新已忽略问题清单
  → 检查项目 `docs/code_reviews/fixed/` 目录是否存在
  → 若存在：遍历该目录下的所有 `.md` 报告文件，扫描其中用户标记为「忽略」的问题
  → 提取忽略问题的关键信息：文件路径、问题标题、级别、备注
  → 将新提取的忽略问题去重后追加到 `ignored_issues.md` 清单中
  → 若 `ignored_issues.md` 不存在：按 `references/ignored_issues_template.md` 格式创建新文件并写入表头
  → 忽略标记识别规则（满足任一即视为忽略）：
     - 问题标题中包含 `（忽略）`、`(ignore)`、`(IGNORE)`、`【忽略】`、`[忽略]`、`[IGNORE]`、`[ignore]` 等标记
     - 问题描述或修复建议中明确包含「忽略此问题」「忽略」「不修复」「已知问题，暂不处理」「ignore this issue」「won't fix」等显式声明
  → 扫描范围严格限定：仅扫描 `docs/code_reviews/fixed/` 目录下的报告文件，不扫描 `docs/code_reviews/` 根目录下的新生成报告，也不扫描 `docs/code_reviews/archived/` 目录（已归档，不重复扫描）
  → 去重追加规则：追加前检查待添加问题是否已存在于清单中（按「文件路径 + 问题标题」匹配），已存在则跳过，避免重复写入
  → 保留用户原标记的备注信息（如标题中括号内的说明）作为「备注」字段写入
  → **扫描后归档**：扫描+去重追加完成后，将 `docs/code_reviews/fixed/` 目录下的**全部报告文件**移动到 `docs/code_reviews/archived/` 目录（若 `archived/` 不存在则自动创建）。归档后 `fixed/` 目录保持为空，下次审查仅扫描用户新放入的报告，避免重复扫描。
     - ⚠️ **移动失败保护**：若文件移动失败（如权限拒绝、磁盘错误等），记录失败原因（错误信息与涉及文件名）并继续审查流程，**不中断本次审查**；在最终通知中向用户说明「fixed/ 目录归档失败，请手动处理：`<错误信息>`」。
     - 若 `fixed/` 目录不存在或为空：视为无已整理报告，直接继续

步骤 5：加载已忽略问题清单
  → 检查项目 `docs/code_reviews/` 目录下是否存在 `ignored_issues.md` 文件
  → 若存在：解析该文件，提取所有已记录的忽略问题（关键字段：文件路径、问题标题）
  → 若不存在：将已忽略问题列表置为空，继续后续流程
  → 将已忽略问题列表加载到内存，供审查步骤去重使用
  → 解析规则：以 Markdown 表格行数据为准，逐行读取，提取「文件路径」「问题标题」作为去重匹配键

步骤 6：执行代码审查
  → 按照 references/review_process.md 定义的审查规则执行
  → 检查范围：命名规范、方法逻辑、代码质量、依赖管理、类型与弃用检查（Python / TypeScript/JavaScript 项目）等
  → 问题分级：严重bug、注意问题、一般问题、轻微问题
  → **跳过已忽略问题**：审查过程中发现的问题若与已忽略问题清单中的条目在「文件路径 + 问题标题」上匹配（标题相似度 ≥ 80% 或完全一致，且文件路径相同），则跳过该问题，不纳入统计、不写入报告；在通知中单独注明「已跳过 X 个已忽略问题」
  → **跳过废弃/旧文件**：审查前必须先执行前置过滤，排除用户标注的废弃/旧文件与文件夹（详见 `review_process.md > 跳过废弃 / 旧文件与文件夹`）。具体包括：
     - 固定命名废弃目录（如 `deprecated`、`old_file`、`legacy`、`archive`、`bak` 等）及其内部全部内容
     - 用户通过 `.code_review_ignore` 或 `.cr_skip` 标记文件声明的跳过项
     - 文件名以 `deprecated_`、`old_`、`legacy_`、`obsolete_`、`archive_`、`bak_` 前缀开头的文件
     - 被过滤内容不进入统计、不进入问题检测、不写入报告；若某维度因过滤无文件可审，直接跳过该维度
  → Python 项目特殊说明：
    - 若仓库包含 Python 文件，优先执行 Pyright 类型检查作为辅助线索，并自动执行 Pyrefly 进行交叉验证
    - ⚠️ **强制四步 fallback 链**：详见 `review_process.md > 检查维度 > 类型与弃用检查 > Pyright 安装与执行`（即 `python_type_check.md` 第 28–37 行），必须按顺序执行，每步失败才进入下一步，禁止在任何中间步骤直接跳过类型检查
    - 若项目存在配置文件（`setup.py`、`pyproject.toml`、`setup.cfg` 等），还需执行过时语法检查（pyupgrade）和弃用 API 检查（Ruff），详见 `python_type_check.md > 过时与弃用代码检查`
    - 执行检查时跳过 `.gitignore` 指定的文件和目录
    - Pyright 与 Pyrefly 的诊断信息仅作为问题线索，必须结合代码上下文阅读分析后，按 `python_type_check.md` 的问题分级参考表判断真实问题及级别，禁止机械映射


步骤 7：生成审查报告
  → 按照 references/report_template.md 生成 Markdown 格式报告
  → 报告必须包含截止提交信息（最新 commit hash 与 message）
  → 报告文件名：<检测日期>-<当前大模型的名称>-代码审查报告.md
  → 某级别没有问题时不展示该级别板块

步骤 8：保存与分发审查报告及忽略清单
  → 根据沟通场景和保存规则输出报告（详见「核心规则 > 报告保存与分发」）
  → 优先使用用户指定的保存方式（如有）
  → 默认保存：将报告保存到项目 `docs/code_reviews/` 目录（若目录不存在则自动创建）
  → **忽略清单保存**：将 `ignored_issues.md` 保存到同一目录 `docs/code_reviews/` 下；若远程推送报告，忽略清单也一并提交推送
  → 远程对话场景 / 插件工具场景（如 Open Claw）：在完成默认保存后，优先尝试 git 提交并推送报告文件（仅提交报告，不修改其他代码，不创建 tag 标签）
     - ⚠️ 推送失败保护：若 `git push` 失败（如 SSH 权限拒绝、网络超时、连接重置等），必须自动重试，最多重试 3 次，每次重试间隔 5 秒
     - 记录每次重试的失败原因（stderr 输出）
     - 若 3 次重试后仍失败：
       1. 向用户明确反馈推送失败及原因：「报告已生成本地保存，但推送至远程仓库失败。失败原因：`<stderr>`。请检查 SSH 密钥权限、网络连接或远程仓库配置。」
       2. 随后依次尝试文件收发技能发送报告，或直接发送报告内容给用户
  → 本地审查场景：仅执行默认保存，无需额外推送或发送
  → 获取报告访问路径或链接用于通知

步骤 9：发送审查通知
  → 输出审查概要（问题总数、各级别数量、已跳过已忽略问题数量）
  → 根据沟通场景推送通知（对话渠道或本地输出）
  → 附带报告链接或文件路径
```

### 工作流二：定时触发代码审查

> **定时任务前缀识别**：
> - **创建流程**：在创建定时任务（cron）时，触发消息必须带有前缀 `【定时自动审查任务】`，用于标识该任务为定时自动审查任务。
> - **审查流程**：当收到的触发消息携带前缀 `【定时自动审查任务】` 时，必须按本工作流（工作流二）执行定时触发代码审查流程。

```
步骤 1：确定目标位置
  → 根据配置的仓库 SSH 地址，按照路径规则计算本地绝对路径
  → 若该路径不存在：按「仓库获取规范 > 克隆仓库」尝试克隆；若克隆失败，终止流程

步骤 2：准备与本地版本检查
  → 进入按路径规则计算的本地绝对路径
  → 检查本地仓库是否有未提交的修改（git status --short）
     - 若有修改：自动执行 git reset --hard HEAD 与 git clean -fd 撤销所有本地修改（仅限定时任务或远程沟通场景执行此操作，本地审查场景禁止自动撤销）
  → 检查仓库是否存在 tag 标签：
     - 存在 tag：获取本地最新 tag（git describe --tags --abbrev=0 $(git rev-list --tags --max-count=1)），记录该 tag，进入步骤 3
       （说明：获取仓库中全局最新 tag，而非当前 HEAD 的 describe 结果，避免本地分支状态干扰）
     - 不存在 tag：获取本地 HEAD（git rev-parse HEAD），记录该 HEAD，进入步骤 4

步骤 3：版本号检查（存在 tag 时执行，优先）
  → 获取远程最新 tag：git ls-remote --tags --sort=-creatordate origin | grep -v '\^{}' | head -n 1 | awk '{print $2}' | sed 's|refs/tags/||'
     （说明：直接从远程获取 tag 列表并解析最新一个，不依赖远程分支 HEAD 的 describe 状态，避免审查报告推送后产生的提交距离后缀干扰）
  → ⚠️ 远程获取失败保护：
     - 若上述命令返回空值（网络超时或连接失败），必须立即重试，最多重试 3 次，每次重试间隔 5 秒
     - 记录每次重试的错误输出（stderr）供排查
     - 若 3 次重试后仍为空值：终止审查流程，向用户反馈错误信息：「无法获取远程仓库 tag 信息，请检查网络连接、仓库访问权限或远程仓库是否可达。原始错误：`<stderr>`」
  → 远程获取成功（非空值）后，对比本地（fetch 之前）和远程最新 tag 名称是否一致
  → 若 tag 不一致：执行 git fetch origin --tags 拉取远程代码及标签，触发审查
  → 若 tag 一致：⚠️ 强制终止流程，不执行任何后续步骤，向用户反馈「本地 tag 与远程一致（`{本地tag}` == `{远程tag}`），版本未变化，跳过本次审查」。此规则无条件适用，绝不允许以"例行检查"、"周期审查"等任何理由绕过此条件。

步骤 4：代码变更检查（不存在 tag 时执行）
  → 获取远程 HEAD：git ls-remote origin HEAD | awk '{print $1}'
  → ⚠️ 远程获取失败保护：
     - 若上述命令返回空值（网络超时或连接失败），必须立即重试，最多重试 3 次，每次重试间隔 5 秒
     - 记录每次重试的错误输出（stderr）供排查
     - 若 3 次重试后仍为空值：终止审查流程，向用户反馈错误信息：「无法获取远程仓库 HEAD 信息，请检查网络连接、仓库访问权限或远程仓库是否可达。原始错误：`<stderr>`」
  → 远程获取成功（非空值）后，对比本地 HEAD（fetch 之前）与远程 HEAD
  → 若不一致：执行 git fetch origin --tags 拉取远程代码，触发审查
  → 若一致：⚠️ 强制终止流程，不执行任何后续步骤，向用户反馈「本地 HEAD 与远程一致（`{本地HEAD}` == `{远程HEAD}`），版本未变化，跳过本次审查」。此规则无条件适用，绝不允许以"例行检查"、"周期审查"等任何理由绕过此条件。

步骤 5：执行审查（同工作流一步骤 4-9）
  → 触发条件满足时执行完整审查流程（含扫描已整理报告并更新清单、加载已忽略问题清单、执行审查、生成报告、保存与分发、发送通知）
```

## 📦 仓库获取规范

远程仓库的克隆、更新、SSH 密钥检查及对应 Git 操作命令，详见 [references/repository_access.md](references/repository_access.md)。

## 📋 审查问题分级

| 级别 | 标识 | 说明 |
|------|------|------|
| 🔴 严重bug | CRITICAL | 必须立即修复的严重问题，可能导致程序崩溃、数据丢失或安全漏洞 |
| 🟠 注意问题 | WARNING | 需要关注的问题，可能影响程序稳定性或可维护性 |
| 🟡 一般问题 | INFO | 代码质量问题，建议优化以提高可读性和可维护性 |
| 🟢 轻微问题 | MINOR | 代码风格问题，建议改进以保持一致性 |

## 核心规则

- **仓库下载**：优先使用 SSH 克隆，失败时依次尝试 HTTPS、镜像加速等备选方式，确保下载成功率
- **来源记录**：审查报告必须记录仓库代码的实际获取来源；若来源为「本地已存在」，则报告中不展示「仓库来源」板块
- **版本检查**：定时触发时优先检查版本号（tag）。若仓库存在 tag，仅当本地与远程最新 tag 不一致时触发审查；若仓库不存在 tag，则按本地 commit 与远程是否不一致（代码发生变更）决定是否触发审查
- 前置过滤、检查维度、问题分级、报告内容约束、已忽略问题去重与报告归档机制，详见 [references/review_process.md](references/review_process.md)
- 报告格式、命名、保存、分发与通知机制，详见 [references/report_delivery.md](references/report_delivery.md)

## 问题定位指南

### 常见问题

详见 [FAQ.md](FAQ.md)。

## 安装与更新

Skill 的安装说明与更新步骤，详见 [references/installation.md](references/installation.md)。
审查执行过程中所需工具依赖（Pyright、Pyrefly、pyupgrade、Ruff 等）的环境检测、安装与升级说明，详见 [references/python_dependency_installation/review_tools.md](references/python_dependency_installation/review_tools.md)。
被审查 Python 项目业务依赖的安装策略，详见 [references/python_dependency_installation/project_dependencies.md](references/python_dependency_installation/project_dependencies.md)。
被审查前端项目的 Node 环境准备（Volta）与业务依赖安装策略，分别详见 [references/frontend_dependency_installation/node_environment.md](references/frontend_dependency_installation/node_environment.md) 和 [references/frontend_dependency_installation/project_dependencies.md](references/frontend_dependency_installation/project_dependencies.md)。
