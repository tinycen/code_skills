# Python 项目审查依赖安装重构方案

> 本方案供确认后执行。确认后将对以下文件进行实际修改：
> - `code-review/references/language_checks/python_dependency.md` → 重命名为 `python_pypi_packaging.md`
> - `code-review/references/review_process.md`
> - `code-review/references/language_checks/python_type_check.md`
> - `code-review/references/dependency_installation.md`

---

## 一、重构目标

1. 明确区分**审查工具依赖**与**项目业务依赖**。
2. 对 Python / PyPI 项目，按**本地审查场景**与**远程 Claw 场景**分别制定依赖安装策略。
3. 确保 Pyright / Pyrefly 在需要时能解析项目依赖，提高类型检查准确性。
4. 明确审查工具（Pyright、Pyrefly、pyupgrade、Ruff）每次审查前均更新到最新版本。

---

## 二、文件重命名

### `python_dependency.md` → `python_pypi_packaging.md`

当前文件内容实际针对 **PyPI 包项目的依赖管理与打包结构检查**，而非通用 Python 依赖安装。重命名后更准确。

**需要同步更新的引用：**

- `code-review/references/review_process.md` 第 206 行：
  ```markdown
  > 详见 [language_checks/python_pypi_packaging.md](language_checks/python_pypi_packaging.md)
  ```

---

## 三、`python_type_check.md` 新增章节

在「执行原则」之后新增：**「项目依赖安装策略（按场景）」**。

### 新增内容草案

```markdown
## 项目依赖安装策略（按场景）

> 本节说明审查前是否安装项目的**业务依赖**（如 `requirements.txt`、`pyproject.toml` 中声明的依赖）。
> 注意：这与下文"Pyright / Pyrefly 安装"是两类不同的依赖，请勿混淆。

### 本地审查场景

- **不安装、不更新项目依赖**，以用户当前本地环境为准。
- 直接使用用户已安装的 Pyright / Pyrefly 执行检查。
- 若用户本地环境未安装某依赖，Pyright / Pyrefly 可能报告 `reportMissingTypeStubs` 或导入错误，按本文件分级标准处理。

### 远程 Claw 场景

- **在远程代码拉取（同步）完成后**，在项目 `.venv` 中安装/更新项目依赖，使 Pyright / Pyrefly 能准确解析第三方库类型。
- 同时在该 `.venv` 中安装/升级 Pyright / Pyrefly / pyupgrade / Ruff，确保工具能访问同一套 `site-packages`。

#### 依赖安装/更新命令

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

#### 版本策略

按项目声明的依赖约束进行安装和更新，允许在约束范围内选择最新可用版本。升级到新版本有助于提前发现潜在兼容性问题。

#### `.gitignore` 检查与自动修复

- 检查 `.gitignore` 是否已排除 `.venv/`、`venv/`、`env/` 等虚拟环境目录。
- 若未排除，自动追加 `.venv/` 到 `.gitignore`。
- 在远程 Claw 场景下，将该 `.gitignore` 修改提交并推送到远程仓库，提交信息固定为：
  ```bash
  git add .gitignore
  git commit -m "chore: ignore .venv for code review"
  git push
  ```
- 推送失败时记录原因，不阻塞后续审查流程。

#### 失败处理

- 依赖安装/更新失败时，降级为不安装依赖直接执行检查，并在报告中注明。

### 环境隔离要求

- 禁止在审查工具依赖与项目依赖之间混用系统环境。
- 本地场景不修改用户项目目录。
- 远程 Claw 场景下项目目录为临时工作区，可在项目 `.venv` 中操作。
```

---

## 四、`dependency_installation.md` 修改

### 1. 重写第 5 行「重要区分」

原内容：

```markdown
> **重要区分**：这些依赖仅服务于代码审查流程，不应与目标项目的业务依赖混淆。建议在独立的审查环境、临时虚拟环境或隔离的工具环境中进行安装/升级，避免污染被审查项目本身。
```

修改为：

```markdown
> **重要区分**：
> - **审查工具依赖**：本文档所述的 Pyright、Pyrefly、pyupgrade、Ruff 等，仅服务于代码审查流程。
> - **项目业务依赖**：被审查项目自身运行所需的依赖（如 `requirements.txt`、`pyproject.toml` 中声明的依赖），其安装策略见 [python_type_check.md > 项目依赖安装策略](language_checks/python_type_check.md#项目依赖安装策略)。
>
> 审查工具依赖应在独立的审查环境、临时虚拟环境或项目隔离的 `.venv` 中安装/升级。本地场景下不应污染被审查项目；远程 Claw 场景下可在项目临时工作区的 `.venv` 中统一安装。
```

### 2. 在「已安装检测与升级策略」中强化每次审查前升级

在现有段落中补充：

```markdown
- 每次执行代码审查前，均应对 Pyright、Pyrefly、pyupgrade、Ruff 执行**升级到最新版本**，以确保使用最新的规则集和类型推断能力。
- 若某工具升级失败，仍尝试用当前已安装版本执行；若当前版本也不可用，再进入该工具的 fallback 链。
```

---

## 五、远程 Claw 场景：依赖安装与类型检查子流程

> 本流程是嵌套在 `SKILL.md` 工作流一「步骤 6：执行代码审查」之中的子流程，**不等同于** SKILL.md 的顶层工作流。其目的是明确远程 Claw 场景下，代码拉取同步后至类型检查前的具体操作顺序。

```
1. 远程代码已拉取/同步完成（对应 SKILL.md 步骤 2）
        ↓
2. 检查项目是否存在 .venv
   - 存在：激活
   - 不存在：创建 .venv
        ↓
3. 检查 .gitignore 是否排除 .venv/
   - 已排除：继续
   - 未排除：自动追加 .venv/，提交并推送 .gitignore
        ↓
4. 在 .venv 中安装 / 更新项目依赖
   - 有 lock 文件：按 lock 同步
   - 无 lock 文件：按 pyproject.toml / setup.py / requirements.txt 声明安装/更新
        ↓
5. 在 .venv 中安装 / 升级 Pyright、Pyrefly、pyupgrade、Ruff
        ↓
6. 使用 .venv 中的 Python 执行 Pyright / Pyrefly / pyupgrade / Ruff 检查
        ↓
7. 将检查结果作为线索，继续 SKILL.md 工作流一的后续审查步骤
```

---

## 六、待确认事项

本方案基于前序讨论整理，以下要点请确认：

1. ✅ 文件重命名为 `python_pypi_packaging.md`。
2. ✅ 本地场景不安装/更新项目依赖，以用户现存环境为准。
3. ✅ 远程 Claw 场景下，在代码拉取同步后安装/更新项目依赖。
4. ✅ 存在 lock 文件时，以 lock 文件为准安装/更新依赖。
5. ✅ 无 lock 文件时，按项目声明的依赖约束安装，允许在约束范围内更新到最新版本。
6. ✅ Pyright、Pyrefly、pyupgrade、Ruff 每次审查前均升级到最新版本。
7. ✅ 远程 Claw 场景下，若 `.gitignore` 未排除 `.venv/`，自动追加并提交推送。

---

## 七、确认后执行的操作清单

- [ ] 重命名 `code-review/references/language_checks/python_dependency.md` → `python_pypi_packaging.md`
- [ ] 更新 `code-review/references/review_process.md` 中的引用
- [ ] 在 `code-review/references/language_checks/python_type_check.md` 中新增「项目依赖安装策略（按场景）」章节
- [ ] 修改 `code-review/references/dependency_installation.md` 开头的「重要区分」说明
- [ ] 在 `code-review/references/dependency_installation.md` 中补充每次审查前升级审查工具的说明
- [ ] （可选）在 `code-review/SKILL.md` 目录结构中补充 `language_checks/` 子文件说明

---

*方案整理时间：2026-07-28*
