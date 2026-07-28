# 项目业务依赖安装策略

> 本文档说明代码审查前是否安装被审查项目的**业务依赖**（如 `requirements.txt`、`pyproject.toml` 中声明的依赖）。
> 注意：这与**审查工具依赖**（Pyright、Pyrefly、pyupgrade、Ruff 等）是两类不同的依赖，审查工具依赖的安装策略见 [review_tools.md](review_tools.md)。

---

## 本地审查场景

- **不安装、不更新项目依赖**，以用户当前本地环境为准，避免破坏用户本地开发环境。
- **审查工具自动安装**：若本地未安装 Pyright / Pyrefly / pyupgrade / Ruff，按 [review_tools.md](review_tools.md) 的 fallback 链自动安装；若已安装，每次审查前升级到最新版本。
- 直接使用本地环境中的 Pyright / Pyrefly 执行检查。
- 若用户本地环境未安装某项目依赖，Pyright / Pyrefly 可能报告 `reportMissingTypeStubs` 或导入错误，按 [python_type_check.md](../language_checks/python_type_check.md) 中的分级标准处理。

## 远程 Claw 场景

- **在远程代码拉取（同步）完成后**，在项目 `.venv` 中安装/更新项目依赖，使 Pyright / Pyrefly 能准确解析第三方库类型。
- 同时在该 `.venv` 中安装/升级 Pyright / Pyrefly / pyupgrade / Ruff，确保工具能访问同一套 `site-packages`。

### 依赖安装/更新命令

根据项目实际使用的包管理器和依赖声明文件选择命令：

| 项目依赖声明 | pip | uv | conda |
|---|---|---|---|
| lock 文件（`uv.lock`） | - | `uv pip sync uv.lock` | - |
| lock 文件（`poetry.lock`） | - | -（使用 poetry） | - |
| lock 文件（`Pipfile.lock`） | - | -（使用 pipenv） | - |
| `pyproject.toml` / `setup.py` 包项目 | `pip install --upgrade -e .` | `uv pip install --upgrade -e .` | `conda env update -f environment.yml`（若存在）或 `conda install --file requirements.txt` |
| `requirements.txt` | `pip install --upgrade -r requirements.txt` | `uv pip install --upgrade -r requirements.txt` | `conda install --file requirements.txt` |
| `environment.yml` | - | - | `conda env update -f environment.yml` |

> **说明**：poetry / pipenv 项目按各自命令执行：`poetry install --sync --no-interaction`、`pipenv sync --dev`。

### 版本策略

按项目声明的依赖约束进行安装和更新，允许在约束范围内选择最新可用版本。升级到新版本有助于提前发现潜在兼容性问题。

### `.gitignore` 检查与自动修复

- 检查 `.gitignore` 是否已排除 `.venv/`、`venv/`、`env/` 等虚拟环境目录。
- 若未排除 `.venv/`，自动追加 `.venv/` 到 `.gitignore`。
- 在远程 Claw 场景下，将该 `.gitignore` 修改提交并推送到远程仓库，提交信息固定为：
  ```bash
  git add .gitignore
  git commit -m "chore: ignore .venv for code review"
  git push
  ```
- 推送失败时记录原因，不阻塞后续审查流程。

### 失败处理

- 依赖安装/更新失败时，降级为不安装依赖直接执行检查，并在报告中注明。

## 环境隔离要求

- 禁止在审查工具依赖与项目依赖之间混用系统环境。
- 本地场景不修改用户项目目录。
- 远程 Claw 场景下项目目录为临时工作区，可在项目 `.venv` 中操作。
