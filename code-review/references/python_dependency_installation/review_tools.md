# 审查工具依赖安装指南

> 本文档统一说明代码审查 Skill 执行过程中所需工具依赖（Pyright、Pyrefly、pyupgrade、Ruff）的环境检测、安装、升级与执行方式。
>
> **重要区分**：
> - **审查工具依赖**：本文档所述的 Pyright、Pyrefly、pyupgrade、Ruff 等，仅服务于代码审查流程。
> - **项目业务依赖**：被审查项目自身运行所需的依赖（如 `requirements.txt`、`pyproject.toml` 中声明的依赖），其安装策略见 [project_dependencies.md](project_dependencies.md)。
>
> **安装位置**：
> - **本地审查场景**：审查工具依赖应安装在独立的审查环境、临时虚拟环境或用户隔离的工具环境中，**不修改被审查项目本身**，也不安装项目业务依赖。
> - **远程 Claw 场景**：审查工具依赖可与项目业务依赖一起，在项目临时工作区的 `.venv` 中统一安装/升级。

---

## 环境检测

在安装或升级任何审查工具前，先检测当前环境可用的包管理器。按以下优先级选择：

| 优先级 | 包管理器 | 检测命令（Unix/Linux/macOS） | 检测命令（Windows / PowerShell） |
|---|---|---|---|
| 1 | uv | `which uv` | `Get-Command uv` |
| 2 | Conda | `which conda` | `Get-Command conda` |
| 3 | pip | `which pip` | `Get-Command pip` |
| 4 | pipx | `which pipx` | `Get-Command pipx` |

- 若检测到多个包管理器，按 **uv > Conda > pip > pipx** 的优先级选择。
- 若未检测到任何 Python 包管理器，先安装 `pip`（通常随 Python 一起安装）或 `uv`。

根据检测结果，使用对应命令安装或升级依赖（将 `<package>` 替换为实际包名）：

| 包管理器 | 安装命令 | 升级命令 |
|---|---|---|
| uv | `uv pip install <package>` | `uv pip install --upgrade <package>` |
| Conda | `conda install -c conda-forge <package>` | `conda update -c conda-forge <package>` |
| pip | `pip install <package>` | `pip install --upgrade <package>` |
| pipx | `pipx install <package>` | `pipx upgrade <package>` |

> 使用 uv 或 pip 时，若当前不在虚拟环境中且目标项目存在 `.venv/`、`.conda/` 等虚拟环境目录，应优先激活该虚拟环境后再执行安装/升级，以减少对系统环境的干扰。

---

## 已安装检测与升级策略

对每个工具，执行前先检查是否已安装：

1. 优先尝试 CLI 形式：`python -m <tool> --version`（如 `python -m pyright --version`）
2. 再尝试全局命令：`<tool> --version`（如 `pyright --version`）

- 若已安装：按上表使用检测到的包管理器执行**升级**。
- 若未安装：按上表使用检测到的包管理器执行**安装**。
- **每次执行代码审查前，均应对 Pyright、Pyrefly、pyupgrade、Ruff 执行升级到最新版本**，以确保使用最新的规则集和类型推断能力。
- 若某工具升级失败，仍尝试用当前已安装版本执行；若当前版本也不可用，再进入各工具专属的 fallback 链。

---

## Pyright

- 检查版本：`python -m pyright --version` 或 `pyright --version`
- 执行命令：
  - Python 包形式：`python -m pyright --outputjson`
  - npm 全局形式：`pyright --outputjson`
  - npx 形式：`npx pyright --outputjson`
- 专属 fallback 链（Python 包管理器安装/升级失败后使用）：
  1. `npm install -g pyright`
  2. `npx pyright`（首次会自动下载）
  3. 若全部失败，在报告中注明「Pyright 安装失败，未执行类型检查」并跳过该维度

---

## Pyrefly

- 检查版本：`python -m pyrefly --version` 或 `pyrefly --version`
- 执行命令：
  - Python 包形式：`python -m pyrefly check --output-format=json`
  - 全局命令形式：`pyrefly check --output-format=json`
- 专属 fallback 链（Python 包管理器安装/升级失败后使用）：
  1. `pipx install pyrefly`
  2. 若全部失败，在报告中注明「Pyrefly 安装失败，未执行交叉验证检查」并跳过该补充维度

---

## pyupgrade

- 检查版本：`python -m pyupgrade --version` 或 `pyupgrade --version`
- 执行命令：`pyupgrade --py<VERSION>-plus --diff`
- 专属 fallback 链（Python 包管理器安装/升级失败后使用）：
  1. `pipx install pyupgrade`
  2. 若全部失败，在报告中注明「pyupgrade 检查未执行（原因：安装失败）」并跳过该子项

其中 `<VERSION>` 取项目目标 Python 版本的最高支持版本或最高测试版本（详见 [python_type_check.md > 目标 Python 版本识别](../language_checks/python_type_check.md#目标-python-版本识别)）。

---

## Ruff

- 检查版本：`python -m ruff --version` 或 `ruff --version`
- 项目配置优先：若项目 `pyproject.toml` 或 `ruff.toml` 中已配置 Ruff，优先使用项目自身的版本要求
- 执行命令：
  - 若项目已配置 Ruff：`ruff check`
  - 否则：`ruff check --select DEP --output-format=json`
- 专属 fallback 链（Python 包管理器安装/升级失败后使用）：
  1. 若全部失败，在报告中注明「Ruff 弃用检查未执行（原因：安装失败）」并跳过该子项

---

## 常见问题

| 问题 | 解决方案 |
|---|---|
| 未检测到任何包管理器 | 先安装 `pip`（通常随 Python 一起安装）或 `uv`，再返回本指南执行安装 |
| 工具已安装但版本过低 | 先执行对应包管理器的升级命令；若升级失败，尝试卸载后重新安装 |
| Conda 通道找不到包 | 尝试添加 `conda-forge` 通道：`conda config --add channels conda-forge` |
| pip 安装超时或失败 | 临时切换镜像源：`pip install -i https://pypi.tuna.tsinghua.edu.cn/simple <package>` |
| 权限不足（Linux/macOS） | 避免使用 `sudo pip install`，优先使用虚拟环境、`--user` 参数或 pipx |
| 权限不足（Windows） | 使用管理员 PowerShell，或改用 `--user` 参数 / 虚拟环境 |
