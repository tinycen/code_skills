# Code Skills

自动化代码审查技能集合，为 AI 助手提供代码质量检查与报告生成能力。

## 项目概述

本仓库包含面向 AI 编程助手的技能（Skill），目前提供以下核心能力：

- **code-review**：自动化代码审查工具，支持从 GitHub/CNB 等 Git 仓库克隆代码、执行多维度代码质量检查、生成结构化审查报告并按场景保存与分发。

## 技能列表

| 技能 | 版本 | 说明 |
|------|------|------|
| [code-review](code-review/) | 1.2.0 | 代码审查 - 自动化代码质量检查与报告生成 |

## 快速开始

### 安装 code-review 技能

**方式一：Prompt 安装（推荐）**

在 AI 对话中发送以下 Prompt 即可完成安装：

```
请帮我安装 code-review 技能。
来源：https://clawhub.ai/tinycen/skills/code-review
下载并放置到当前工具对应的技能目录中。
```

**方式二：OpenClaw CLI 安装**

```bash
openclaw skills install @tinycen/code-review
```

**方式三：手动安装**

1. 下载 `code-review` 目录，并将其移动到对应工具的技能目录

详细安装说明请参考 [code-review/references/installation.md](code-review/references/installation.md)。

### 使用示例

安装完成后，在仓库目录下，对话中直接触发代码审查：

```
帮我审查代码
```

或在远程 Claw 环境中，通过对话，指定远程仓库：

```
帮我审查代码，仓库地址：git@github.com:org/repo.git
```

## 功能特性

### code-review 技能

- **多维度代码检查**：命名规范、方法逻辑、代码质量、依赖管理、类型检查等
- **智能问题分级**：严重bug、注意问题、一般问题、轻微问题四级分类
- **已忽略问题管理**：支持标记忽略问题，自动去重避免重复报告
- **定时审查支持**：支持定时触发，自动检测版本变化决定是否执行审查
- **多语言支持**：Python、TypeScript/JavaScript 等语言的专项检查
- **结构化报告**：生成标准化 Markdown 格式审查报告
- **灵活分发**：支持本地保存、远程推送、对话通知等多种分发方式

### 检查维度

| 维度 | 说明 |
|------|------|
| 命名规范 | 变量、方法、类命名是否符合语言规范 |
| 方法逻辑 | 函数复杂度、异常处理、资源管理 |
| 代码质量 | 代码重复、硬编码、魔法数字 |
| 依赖管理 | 依赖版本、安全性、必要性 |
| 类型检查 | Python: Pyright/Pyrefly，TypeScript/JavaScript: tsc |

### 问题分级

| 级别 | 标识 | 说明 |
|------|------|------|
| 🔴 严重bug | CRITICAL | 必须立即修复，可能导致崩溃、数据丢失或安全漏洞 |
| 🟠 注意问题 | WARNING | 需要关注，可能影响稳定性或可维护性 |
| 🟡 一般问题 | INFO | 代码质量问题，建议优化以提高可读性 |
| 🟢 轻微问题 | MINOR | 代码风格问题，建议改进以保持一致性 |

## 目录结构

```
code_skills/
├── README.md                           # 本文件
├── LICENSE                             # MIT 许可证
└── code-review/                        # 代码审查技能
    ├── SKILL.md                        # 技能入口文件
    └── references/                     # 参考文档
        ├── review_process.md           # 审查流程与规则
        ├── report_template.md          # 审查报告模板
        ├── ignored_issues_template.md  # 已忽略问题清单模板
        ├── repository_access.md        # 仓库获取规范
        ├── installation.md             # 安装与更新
        ├── dependency_installation.md  # 依赖安装指南
        └── language_checks/            # 语言专项检查
            ├── python_type_check.md    # Python 类型检查
            ├── python_dependency.md    # Python 依赖检查
            └── typescript_javascript_check.md  # TypeScript/JavaScript 检查
```

## 报告输出结构

审查报告保存在项目 `docs/code_reviews/` 目录下：

```
docs/code_reviews/
├── <日期>-<模型>-代码审查报告.md    # 新生成的审查报告
├── fixed/                        # 由用户手动标注：已修复/阅读的报告
├── archived/                     # 已归档的报告（自动整理）
└── ignored_issues.md             # 已忽略问题清单（自动整理）
```

## 许可证

本项目采用 [MIT 许可证](LICENSE)。

## 相关链接

- [ClawHub > code-review](https://clawhub.ai/tinycen/skills/code-review)
- [代码审查技能文档](code-review/SKILL.md)
