# 异常处理检查（Python 项目）

> 本文件为 `review_process.md` 第 7 节「异常处理检查」的详细内容，适用于 Python 项目。
> 若仓库中不存在 Python 文件（`.py`、`.pyi`），跳过本维度。

---

## 执行原则

> 通用原则（忽略范围、辅助定位）见 [common_principles.md](common_principles.md)。

- **项目配置优先**：若项目已配置 `ruff.toml` 或 `pyproject.toml` 中的 `[tool.ruff]`，以项目自身配置为准执行，不强制覆盖。
- **不重复计分**：同一处代码同时命中多条规则时（如 `except Exception: pass` 同时命中 BLE001 与 S110），在报告中只记录一次，并在描述中注明命中的规则编号。

---

## 检查项 1：异常链丢失（重点）

### 问题说明

在 `except` 代码块内部抛出新异常时，若不使用 `from`，Python 虽然会把原始异常挂到新异常的 `__context__`（隐式上下文），但**不会建立 `__cause__`（显式因果链）**。多数日志框架、APM 与 IDE 的堆栈展示只打印主链，`__context__` 常被折叠或省略，导致：

- 原始异常的类型、报错位置、传入参数等关键信息丢失；
- 只能看到最外层「包装后」的异常，无法定位真正的失败点；
- 排查线上问题时只能靠猜，尤其在外层统一封装 `raise Exception(f"...")` 的模式下几乎无法定位。

### 反例与正例

```python
# ❌ 反例 1：在 except 内抛新异常不带 from，原始异常堆栈丢失
try:
    result = fetch_order(order_id)
except Exception as error:
    raise Exception(f"error: {error}")   # 原始堆栈被丢弃

# ❌ 反例 2：只把 e 转成字符串拼进新异常，异常类型与 traceback 全丢
try:
    conn = create_conn()
except Exception as e:
    raise RuntimeError(f"error: {e}")

# ✅ 正例 1：使用 from 保留异常链（推荐）
try:
    result = fetch_order(order_id)
except Exception as error:
    raise Exception(f"error: {error}") from error

# ✅ 正例 2：抛自定义异常时同样保留 cause
try:
    conn = create_conn()
except (ConnectionError, TimeoutError) as e:
    raise DatabaseConnectError(f"error: {e}") from e

# ✅ 正例 3：不需要包装时直接裸抛，完整保留原异常与堆栈
try:
    result = fetch_order(order_id)
except Exception:
    logger.exception("error")
    raise
```

### 三种等价写法的取舍

| 写法 | 行为 | 适用场景 |
|---|---|---|
| `raise` | 原样重抛，完整保留原类型与堆栈 | 仅记录日志/做清理后继续向上抛，**推荐优先使用** |
| `raise New(...) from error` | 建立 `__cause__`，打印 `The above exception was the direct cause...` | 需要包装成业务异常时，**必须使用** |
| `raise New(...) from None` | 显式压制 `__context__`，只显示新异常 | 仅在对外部暴露、不希望泄漏内部细节时有意为之 |

> ⚠️ 若代码中出现 `raise New(...) from None`，需确认这是**有意为之**（如屏蔽敏感信息），否则视为问题；审查报告中应显式标注该处为「主动压制异常链」。

### 检查要点

- **检查项**：`except` 块内所有 `raise` 语句，是否使用了 `from`（特殊情况为裸 `raise` 或有意的 `from None`）
- **检查项**：包装后的新异常消息是否至少保留了原始异常信息（`{e}` / `str(e)` / `repr(e)`），避免出现「调用失败」这类无任何上下文的空壳消息
- **检查项**：是否为了拼字符串而把异常降级为 `str`，导致异常类型丢失；如需保留类型，可写入 `{type(e).__name__}` 或使用 `repr(e)`

### 分级

| 情形 | 分级 |
|---|---|
| `except` 内 `raise` 新异常未带 `from`，且新异常未包含原始异常信息 | 🔴 严重bug |
| `except` 内 `raise` 新异常未带 `from`，但消息中包含了 `str(e)` 等原始信息 | 🟠 注意问题 |
| `from None` 压制异常链且无明确理由 | 🟠 注意问题 |

---

## 检查项 2：静默吞掉异常

### 问题说明

`except` 捕获后既不记录日志、也不重新抛出、也不做补偿处理，异常被完全吃掉，调用方拿到的是「看似成功、实则失败」的结果。

### 检查要点

- **检查项**：是否存在 `except ...: pass`（仅 `pass` 或仅注释）
- **检查项**：`except` 中是否只有 `continue` / `break` / `return None`，没有任何日志或状态标记
- **检查项**：批量处理（如循环内逐条处理）时，单条失败是否被静默跳过而未计数、未汇总
- **检查项**：异常对象是否被绑定到变量却完全未使用（如 `except Exception as e:` 后文从未引用 `e`），往往是漏写日志的信号

### 分级

| 情形 | 分级 |
|---|---|
| 吞掉异常且涉及资源释放、事务提交、数据写入、金额计算等关键路径 | 🔴 严重bug |
| 吞掉异常但位于非关键路径（如可选增强功能、缓存刷新） | 🟠 注意问题 |

---

## 检查项 3：日志记录缺失堆栈

### 问题说明

在 `except` 中用 `logger.error(f"...{e}")` 只打印异常的字符串，缺少 traceback，等同于丢失堆栈信息。

### 反例与正例

```python
# ❌ 只有异常文本，没有堆栈
except Exception as e:
    logger.error(f"error: {e}")

# ✅ 自动附带 traceback
except Exception as e:
    logger.exception("%s", e)

# ✅ 显式开启堆栈
except Exception as e:
    logger.error("%s", e, exc_info=True)
```

### 检查要点

- **检查项**：`except` 块内的 `logger.error` / `logger.warning` 是否缺少 `exc_info=True`，或未改用 `logger.exception`
- **检查项**：是否只用 `print(e)` 或 `print(traceback.format_exc())` 代替日志框架
- **检查项**：日志量是否包含必要上下文（关键参数、业务 ID），避免只有一句「操作失败」
- **检查项**：日志中是否打印了敏感信息（凭据、Token、身份证号等），该维度与「日志规范」检查项联动

### 分级

| 情形 | 分级 |
|---|---|
| 关键路径异常日志完全无堆栈（`logger.error(str(e))`） | 🟠 注意问题 |
| 有堆栈但缺少关键上下文参数 | 🟡 一般问题 |

---

## 检查项 5：异常类型与 finally 使用

### 检查要点

- **检查项**：是否直接 `raise Exception("...")` / `raise BaseException("...")`，而非使用项目自定义异常或语义更明确的内置异常（`ValueError`、`KeyError`、`TimeoutError` 等）
- **检查项**：是否使用 `raise e` 而非 `raise`（前者会重置 traceback 起点，属于异常链的另一种丢失形式）
- **检查项**：`finally` 块中是否包含 `return` / `raise` / `break`，导致异常被静默丢弃
- **检查项**：`try` 包裹范围是否过大（整个函数体包在一个 `try` 里），导致无法定位具体失败语句
- **检查项**：资源清理是否应使用 `with` / `contextlib` 而非 `try...finally`
- **检查项**：自定义异常类是否继承自合适的基类（业务异常通常继承 `Exception`，避免继承 `BaseException`）

### 分级

| 情形 | 分级 |
|---|---|
| `finally` 中存在 `return`，导致异常被吞掉 | 🔴 严重bug |
| 使用 `raise e` 而非 `raise` | 🟠 注意问题 |
| 直接 `raise Exception` 而非具体/自定义异常类型 | 🟡 一般问题 |
| `try` 包裹范围过大 | 🟡 一般问题 |

---

## 检测手段

### 方式一：Ruff 规则扫描（优先）

异常处理相关规则：

| 规则 | 说明 | 对应检查项 |
|---|---|---|
| `B904` | `raise-without-from-inside-except`：`except` 内抛新异常未带 `from` | 检查项 1（核心） |
| `TRY002` | `raise-vanilla-class`：直接抛出 `Exception` / `BaseException` | 检查项 5 |
| `TRY201` | `verbose-raise`：使用 `raise e` 而非 `raise` | 检查项 5 |
| `TRY400` | `error-instead-of-exception`：`except` 内用 `logger.error` 而非 `logger.exception` | 检查项 4 |
| `BLE001` | `blind-except`：捕获 `Exception` / `BaseException` 等宽泛类型 | 检查项 3 |
| `S110` | `try-except-pass`：捕获后直接 `pass` | 检查项 2 |

执行方式（未配置 Ruff 的项目追加 `--select` 指定规则）：

```bash
# 未配置 Ruff 的项目：叠加异常相关规则
ruff check --select DEP,B904,TRY002,TRY201,TRY400,BLE001,S110 --output-format=json .

# 仅跑异常链检查（最常用）
ruff check --select B904 --output-format=json .
```

> Ruff 的安装、升级与 fallback 链详见 [review_tools.md > Ruff](../python_dependency_installation/review_tools.md#ruff)。

### 方式二：文本检索（Ruff 不可用时的兜底）

`B904` 只能命中直接的 `raise ... from` 缺失，仍需人工/文本复核。可用以下命令快速定位候选位置：

```bash
# 1) 定位所有 except 块
grep -rnE "^\s*except\b" --include="*.py" <仓库路径>

# 2) 定位所有 raise 语句（含裸 raise / 带 from / 不带 from）
grep -rnE "^\s*raise\b" --include="*.py" <仓库路径>

# 3) 重点复核：不带 from 的 raise（排除裸 raise 与 from None）
grep -rnE "raise\s+[A-Za-z_][A-Za-z0-9_.]*\(" --include="*.py" <仓库路径> | grep -v "from "
```

Windows / PowerShell 环境（Git Bash 不可用时）：

```powershell
Get-ChildItem -Path <仓库路径> -Recurse -Filter *.py |
  Select-String -Pattern 'raise\s+[A-Za-z_][A-Za-z0-9_.]*\(' |
  Where-Object { $_.Line -notmatch 'from ' }
```

> 上述命令只是**候选位置筛选**，命中的每一行都必须结合上下文确认是否位于 `except` 块内，再决定是否计入问题。

---

## 报告撰写要求

在审查报告中记录本维度问题时，描述必须包含以下要素：

1. **文件路径 + 行号**
2. **当前写法**（贴出原始代码片段）
3. **影响**：明确写出「原始异常的堆栈/类型信息丢失，无法定位真实失败点」
4. **修复建议**：给出改写后的代码，优先推荐 `raise XxxError(...) from error`，无需包装时推荐裸 `raise`
5. **规则来源**：若由 Ruff 检出，标注 `[Ruff B904]` 等规则编号

示例条目（外层用四反引号仅为展示，实际写入报告时无需外层围栏）：

````markdown
### 🟠 注意问题：`except` 内抛出新异常未保留异常链

**文件**：`app/services/order_service.py:128`
**规则来源**：[Ruff B904]

**当前写法**
```python
except Exception as error:
    error_message = str(error)
    raise Exception(f"error: {error_message}")
```

**影响**：新异常未通过 `from` 关联原始异常，原始异常的类型与调用堆栈被丢弃，
线上排障时只能看到「查询订单失败」这一层，无法定位真正的失败点。

**修复建议**
```python
except Exception as error:
    raise Exception(f"error: {error}") from error
```
````
