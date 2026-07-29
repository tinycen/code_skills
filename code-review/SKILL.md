---
name: code-review
description: 代码审查 Skill - 自动化代码质量检查与报告生成工具。支持从 GitHub 等仓库克隆代码、执行多维度代码质量检查、生成结构化审查报告并按场景保存与分发。当用户提到"代码审查"、"code review"、"检查代码质量"、"审查报告"等操作时，或当用户主动提及使用本 skill / 调用本技能时，请使用本 skill。
version: 1.2.1
author: tinycen
---

# 代码审查 Skill 使用指南

本 Skill 提供自动化代码审查能力。本文档为入口导航页，具体执行规范拆分到 `workflows/` 与 `references/` 下的对应文件中。

> 路径规则与仓库获取规范详见 [references/repository_access.md](references/repository_access.md)。

---

## 🎯 场景路由表

| 场景 | 文档 |
|------|------|
| 手动触发代码审查（用户主动要求 / 本地审查 / 远程对话） | [workflows/manual_workflow.md](workflows/manual_workflow.md) |
| 定时触发代码审查（自动化调度 / 定时任务） | [workflows/scheduled_workflow.md](workflows/scheduled_workflow.md) |
| 仓库获取、SSH 配置、版本信息获取 | [references/repository_access.md](references/repository_access.md) |
| 审查规则、检查维度、问题分级 | [references/review_process.md](references/review_process.md) |
| 报告格式、保存、分发与通知 | [references/report_delivery.md](references/report_delivery.md) |
| 审查报告模板 | [references/report_template.md](references/report_template.md) |
| 已忽略问题清单模板 | [references/ignored_issues_template.md](references/ignored_issues_template.md) |
| 安装与更新 | [references/installation.md](references/installation.md) |

---

## 🔧 工作流

`workflows/` 目录包含本 Skill 的核心执行流程，按触发场景分为两个工作流：

| 工作流 | 说明 | 文档 |
|--------|------|------|
| 工作流一：手动触发 | 用户主动要求审查时使用，无条件执行完整审查流程。 | [workflows/manual_workflow.md](workflows/manual_workflow.md) |
| 工作流二：定时触发 | 定时任务或自动化调度触发时使用，先检查版本是否变化，仅在有变化时执行审查。 | [workflows/scheduled_workflow.md](workflows/scheduled_workflow.md) |

执行前必须先确定当前场景并选择对应工作流，禁止混用。

---

## 📁 文件目录结构

```
code-review/
├── SKILL.md                        # 入口文件（本文件），场景路由
├── workflows/                      # 工作流编排
│   ├── manual_workflow.md          # 工作流一：手动触发
│   └── scheduled_workflow.md       # 工作流二：定时触发
└── references/                     # 参考文档
    ├── review_process.md           # 代码审查流程与规则
    ├── report_template.md          # 审查报告模板
    ├── report_delivery.md          # 报告保存、分发与通知
    ├── ignored_issues_template.md  # 已忽略问题清单模板
    ├── repository_access.md        # 仓库获取规范
    ├── installation.md             # 安装与更新
    ├── python_dependency_installation/          # Python 依赖安装
    │   ├── review_tools.md                      # 审查工具依赖安装
    │   └── project_dependencies.md              # 项目业务依赖安装
    ├── frontend_dependency_installation/        # 前端依赖安装
    │   ├── node_environment.md                  # Node 环境管理（Volta）
    │   └── project_dependencies.md              # 前端项目业务依赖安装
    └── language_checks/                         # 语言专项检查
        ├── python_type_check.md                 # Python 类型检查
        ├── python_pypi_packaging.md             # Python PyPI 包依赖与打包
        └── typescript_javascript_check.md       # TypeScript/JavaScript 检查
```

---

## 📂 报告输出目录结构

审查报告默认输出到被审查项目的 `docs/code_reviews/` 目录：

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
> - **报告扫描范围**：仅扫描 `fixed/`，不扫描 `archived/`（已归档），也不扫描根目录下的新生成报告。
> - **原报告引用**：`ignored_issues.md` 中「原报告」字段只记录文件名，对应文件已归档于 `docs/code_reviews/archived/` 子目录。

---

## ❓ 常见问题

详见 [FAQ.md](FAQ.md)。

---

## 📦 安装与更新

Skill 的安装说明与更新步骤，详见 [references/installation.md](references/installation.md)。
审查执行过程中所需工具依赖（Pyright、Pyrefly、pyupgrade、Ruff 等）的环境检测、安装与升级说明，详见 [references/python_dependency_installation/review_tools.md](references/python_dependency_installation/review_tools.md)。
被审查 Python 项目业务依赖的安装策略，详见 [references/python_dependency_installation/project_dependencies.md](references/python_dependency_installation/project_dependencies.md)。
被审查前端项目的 Node 环境准备（Volta）与业务依赖安装策略，分别详见 [references/frontend_dependency_installation/node_environment.md](references/frontend_dependency_installation/node_environment.md) 和 [references/frontend_dependency_installation/project_dependencies.md](references/frontend_dependency_installation/project_dependencies.md)。
