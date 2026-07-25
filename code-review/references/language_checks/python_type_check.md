# 类型与弃用检查（Python 项目）

> 本文件为 `review_process.md` 第 6 节「类型与弃用检查」的详细内容，适用于 Python 项目。
> 若仓库中不存在 Python 文件（`.py`、`.pyi`），跳过本维度。

---

## 执行原则

- **忽略范围**：执行代码扫描和类型检查时，应跳过 `.gitignore` 中指定的文件和目录（如 `__pycache__/`、`node_modules/`、`.venv/`、虚拟环境目录、构建产物等）。若使用 `find` 命令扫描，可通过 `git check-ignore` 或工具自带的忽略逻辑排除。
- **辅助定位**：Pyright 的诊断信息仅作为问题「线索」，不能直接等同于最终分级结果。必须结合代码上下文阅读分析后，判断是否为真实问题及其实际严重程度。
- **项目配置优先**：若项目已配置 `pyrightconfig.json`、`pyproject.toml` 中的 `tool.pyright`，以项目自身配置为准。执行时优先使用项目已有配置，不强制覆盖。

## Pyright 安装与执行

- ⚠️ **强制四步 fallback 链**：必须按以下顺序执行，每步失败才进入下一步，禁止在任何中间步骤直接跳过类型检查：
  1. `pip install pyright`（或 `pip install pyright==<指定版本>`）→ 成功后使用 `python -m pyright --outputjson` 执行
  2. 若 pip 失败，`npm install -g pyright` → 成功后使用 `pyright --outputjson` 执行
  3. 若 npm 失败，`npx pyright --outputjson`（首次会自动下载）
  4. 若 npx 也失败，在报告中注明「Pyright 安装失败，未执行类型检查」并跳过该维度
- 将 JSON 输出中的 `generalDiagnostics` 作为问题线索来源。

## 过时与弃用代码检查

当项目中存在 Python 项目配置文件（如 `setup.py`、`pyproject.toml`、`setup.cfg`、`Pipfile`、`tox.ini` 等）时，应额外检查项目代码是否使用了与目标 Python 版本不兼容的过时语法或已被弃用的 API。

### 目标 Python 版本识别

从项目配置文件中提取目标 Python 版本信息，作为过时检查的基准：

| 配置文件 | 版本字段 |
|---|---|
| `pyproject.toml` | `[project]` 下的 `requires-python`（如 `requires-python = ">=3.10"`） |
| `setup.py` | `setup()` 中的 `python_requires` 参数 |
| `setup.cfg` | `[options]` 下的 `python_requires` |
| `Pipfile` | `[requires]` 下的 `python_version` |
| `tox.ini` | `envlist` 中声明的 Python 版本（如 `py310,py311`） |
| `.github/workflows/*.yml` | CI 矩阵中配置的 `python-version` |

- 若项目中多处声明了目标版本，以**最高支持版本或最高测试版本**为准（如 CI 矩阵测试了 3.10/3.11/3.12，则以 3.12 为基准），以确保能检出更多弃用与过时问题
- 若项目仅声明了最低版本（如 `requires-python = ">=3.10"`）而未明确上限，以该**最低版本**作为基准
- 若项目未显式声明目标版本，默认以 **Python 3.10** 作为基准版本

### 过时语法检查（pyupgrade）

使用 `pyupgrade` 检测与目标 Python 版本不兼容的过时语法：

- ⚠️ **强制三步 fallback 链**：必须按以下顺序执行，每步失败才进入下一步：
  1. `pip install pyupgrade` → 成功后使用 `pyupgrade --py<VERSION>-plus` 执行（如 `pyupgrade --py312-plus`）
  2. 若 pip 失败，`pipx install pyupgrade` → 成功后使用 `pyupgrade --py<VERSION>-plus` 执行
  3. 若 pipx 也失败，在报告中注明「pyupgrade 检查未执行（原因：xxx）」并跳过该子项
- 使用 `--diff` 参数查看建议的修改，但不自动应用（仅作为问题线索）

**常见过时语法示例**：

| 过时写法 | 现代替代 | 最低 Python 版本 |
|---|---|---|
| `typing.List`、`typing.Dict`、`typing.Set` | 内置 `list`、`dict`、`set` | 3.9+ |
| `typing.Optional[X]` | `X \| None` | 3.10+ |
| `typing.Union[X, Y]` | `X \| Y` | 3.10+ |
| `from __future__ import annotations`（若仅需类型注解延迟求值） | 3.10+ 已原生支持大部分场景 | 3.10+ |
| `typing.TypeGuard` | `typing_extensions.TypeIs` 或内置 `TypeIs` | 3.13+ |
| `asyncio.coroutine` / `@asyncio.coroutine` | `async def` | 3.10+（已移除） |
| `distutils` 模块 | `setuptools` / `packaging` | 3.12+（已移除） |
| `imp` 模块 | `importlib` | 3.12+（已移除） |

### 弃用 API 检查（Ruff）

若项目已配置 Ruff（`pyproject.toml` 中 `[tool.ruff]` 或存在 `ruff.toml`），优先使用项目配置执行检查；否则使用独立安装：

- ⚠️ **强制三步 fallback 链**：
  1. 若项目 `pyproject.toml` 或 `tox.ini` 中包含 Ruff 相关配置或脚本，优先使用 `ruff check` 执行
  2. 若项目无相关配置，`pip install ruff` → 使用 `ruff check --select DEP --output-format=json` 执行
  3. 若安装失败，在报告中注明「Ruff 弃用检查未执行（原因：xxx）」并跳过该子项

**重点关注规则**：

| Ruff 规则 | 说明 |
|---|---|
| `DEP001` | 使用了 `@deprecated` 或 `warnings.warn(DeprecationWarning)` 标记的函数/方法 |
| `UP` 系列 | pyupgrade 规则，检测可升级为现代语法的过时写法 |
| `PYI` 系列 | 针对 `.pyi` 类型存根文件的检查 |

此外，手动扫描以下弃用模式：
- 代码中使用了 `warnings.warn(..., DeprecationWarning)` 或 `@deprecated` 装饰器标记的 API
- 标准库中已弃用的模块/函数（如 `distutils`、`imp`、`optparse`、`cgi`、`pipes` 等，随 Python 版本不同而异）
- 第三方依赖中标记为弃用的 API（结合 `DeprecationWarning` 输出判断）

## 问题分级参考（Pyright / pyupgrade / Ruff 诊断 → 审查级别对照）

下表提供 Pyright、pyupgrade、Ruff 各类诊断规则与审查级别的**初步对应关系**，供审查时参考。最终级别需结合代码实际逻辑判断：

| 诊断来源与规则 | 参考级别 | 说明与典型误报场景 |
|---|---|---|
| `reportGeneralTypeIssues` | 🔴 严重bug | 类型不兼容、无法赋值等。**误报可能**：使用了动态类型（如 `Any`）、鸭子类型、运行时动态注入属性、或 C 扩展模块无类型存根 |
| `reportOptionalMemberAccess` | 🔴 严重bug | 对 Optional 对象访问成员。**误报可能**：前面已有显式的 `if x is not None:` 守卫，但 Pyright 未推断出；或使用 `@overload` 分支已做处理 |
| `reportArgumentType` | 🟠 注意问题 | 函数参数类型不匹配。**误报可能**：传入的是鸭子类型对象，满足运行时行为但无显式继承；或装饰器改变了函数签名 |
| `reportReturnType` | 🟠 注意问题 | 返回值类型不匹配。**误报可能**：使用 `cast()` 或类型断言的场景；或协议类（Protocol）已实现但无显式声明 |
| `reportAssignmentType` | 🟠 注意问题 | 赋值类型不兼容。**误报可能**：变量在不同分支被赋值为兼容类型，但 Pyright 推断为联合类型 |
| `reportAttributeAccessIssue` | 🟠 注意问题 | 访问不存在的属性。**误报可能**：使用 `setattr` / `__getattr__` 动态设置属性；或运行时通过 Mixin 注入 |
| `reportCallIssue` | 🟠 注意问题 | 调用签名错误。**误报可能**：使用 `*args` / `**kwargs` 转发参数时类型展开不完整 |
| `reportUnknownParameterType` | 🟡 一般问题 | 参数类型注解缺失（在严格模式下）。**注意**：若项目未要求类型注解，可忽略 |
| `reportUnknownVariableType` | 🟡 一般问题 | 变量类型注解缺失（在严格模式下）。**注意**：简单推导类型（如 `x = 1`）通常无需注解 |
| `reportUnknownMemberType` | 🟡 一般问题 | 成员类型无法推断（在严格模式下）。**误报可能**：第三方库未提供类型存根 |
| `reportMissingTypeArgument` | 🟡 一般问题 | 泛型缺少类型参数。**注意**：旧版本 Python 代码可能未使用泛型语法 |
| `reportMissingTypeStubs` | 🟢 轻微问题 | 第三方库缺少类型存根。通常不影响运行，可考虑添加 stub 或使用 `type: ignore` |
| `reportUnusedExpression` / `reportUnusedVariable` | 🟢 轻微问题 | 未使用的表达式或变量。**注意**：需确认是否为调试残留或副作用表达式 |
| pyupgrade: `typing.List/Dict/Set` → 内置类型 | 🟠 注意问题 | 使用了 `typing` 模块中已被内置泛型替代的类型别名。这是**潜在的技术债务**，在目标 Python 版本下已有更简洁的现代写法。**误报可能**：项目的实际运行环境低于基准版本，仍需兼容低版本 |
| pyupgrade: `Union`/`Optional` → `\|` 语法 | 🟠 注意问题 | 使用了旧式联合类型语法。在 Python 3.10+ 项目中应使用 `\|` 语法。**误报可能**：项目实际运行环境仍为 3.9 |
| pyupgrade: `.format()` / `%` → f-string | 🟡 一般问题 | 使用了旧式字符串格式化方式。**注意**：某些场景下 `.format()` 可能更清晰（如模板字符串复用） |
| Ruff `DEP001`: 弃用 API 调用 | 🟠 注意问题 | 使用了标记 `@deprecated` 或发出 `DeprecationWarning` 的 API。这是**潜在的技术债务**，被弃用的 API 可能在未来版本中被移除。**误报可能**：第三方库自身标记弃用但尚无替代方案；或项目锁定了库版本短期内不会升级 |
| Ruff `UP` 系列: 可升级语法 | 🟡 一般问题 | 代码中存在可升级为现代语法的写法。**注意**：需确认目标 Python 版本确实支持替代语法 |
| 标准库弃用模块（`distutils`、`imp`、`optparse` 等） | 🟠 注意问题 | 使用了已在目标 Python 版本中被弃用或移除的标准库模块。**严重性**：若目标 Python 版本已移除该模块，会导致运行时 ImportError，应升级为 🔴 |

> **关键原则**：
> - **弃用问题特别关注**：无论 Pyright、pyupgrade 还是 Ruff 报告的弃用/过时问题，都应认真记录。即使当前版本可正常运行，弃用 API 和过时语法是潜在的风险点，应在报告中明确标注替代方案
> - Pyright/pyupgrade/Ruff 报告的错误（error）和警告（warning）不等于审查分级。例如：
>   - Pyright 的 `error` 若属于已知的设计模式（如反射、元类动态创建属性、猴子补丁），经确认后可降级或不纳入问题列表
>   - Pyright 的 `warning` 若实际会导致运行时异常（如对可能为 None 的对象未做检查即使用），应升级处理
>   - pyupgrade 的建议若与项目实际支持的最低 Python 版本不兼容，应忽略（如基准版本为 CI 最高测试版本，但项目仍需兼容低版本）
> - 必须阅读报错位置的上下文代码（至少包含所在函数/类及调用链），确认是真实问题后再归类。禁止直接按规则名称机械映射
> - 若项目使用 monorepo 结构（如多个子包各有独立的 `pyproject.toml`），需针对各子包分别执行检查
