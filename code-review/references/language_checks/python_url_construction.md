# URL 构造检查（Python 项目）

> 本文件为 `review_process.md` 第 11 节「URL 构造检查」的详细内容，适用于 Python 项目。
> 若仓库中不存在 Python 文件（`.py`、`.pyi`），跳过本维度。

---

## 执行原则

> 通用原则（忽略范围、辅助定位）见 [common_principles.md](common_principles.md)。

- **只查手工拼接**：仅当 URL 的查询串（query string）或路径段由代码**手工拼接**（f-string、`+`、`%`、`.format()`）时才计入问题；使用 HTTP 客户端自带的查询参数机制（如 `requests` / `httpx` / `aiohttp` 的 `params=`、`urllib` 的 `urlencode`、`yarl` / `furl` / `hyperlink` 等参数化构造）不算问题。清单仅列举常见示例，**不限于上述库**：凡参数值由库内部统一编码、调用方无需手工维护 `?`/`&` 的构造方式，均视为合规。
- **不重复计分**：同一处拼接同时命中多条检查项（如既未转义又硬编码 `?`/`&`）时，在报告中只记录一次。

---

## 检查项 1：f-string / 字符串拼接构造查询串（重点）

### 问题说明

用 f-string 手工拼接 URL 查询串时，参数值不会经过 URL 编码：

- 参数值含空格、中文、`&`、`=`、`#`、`+` 等特殊字符时，产生**格式错误的 URL** 或**语义错误**（如值中的 `&` 被解析为参数分隔符，`+` 被服务端解码为空格）；
- 每新增一个参数都要手工维护 `?`、`&`、`=` 的拼接位置，极易出现**重复 `?`、漏 `&`、漏 URL 编码**；
- 可选参数（如 `status` 为 `None` 时是否拼入）的分支逻辑散落在字符串里，扩展时容易出错。

### 反例与正例

```python
# ❌ 反例 1：f-string 手工拼接查询串，值未转义，加参数要改字符串
url = f"{base_url}/api/orders?status={status}&page={page}"

# ❌ 反例 2：可选参数用条件拼接，? 与 & 的位置手工维护
url = f"{base_url}/api/orders?status={status}"
if keyword:
    url += f"&keyword={keyword}"

# ✅ 正例 1：urlencode 自动转义，参数集中在 dict 中便于扩展
from urllib.parse import urlencode

params = {"status": status, "page": page}
url = f"{base_url}/api/orders?{urlencode(params)}"

# ✅ 正例 2：使用 HTTP 客户端自带的 params 参数（推荐，连 ? 都不用管）
response = requests.get(f"{base_url}/api/orders", params={"status": status, "page": page})

# ✅ 正例 3：可选参数先组装 dict，再统一编码
params = {"page": page}
if keyword:
    params["keyword"] = keyword
url = f"{base_url}/api/orders?{urlencode(params)}"
```

### 检查要点

- **检查项**：f-string / `%` / `.format()` / `+` 拼接的 URL 中，`?` 之后是否存在 `{变量}` 或字符串相加
- **检查项**：拼接的参数值是否未经 `quote` / `urlencode` 转义直接嵌入
- **检查项**：是否通过条件分支往字符串后追加 `&key={value}`（应改为 dict 组装后统一编码）
- **检查项**：`urlencode` 时是否遗漏 `doseq=True`（值为 list 时需逐个编码）

### 分级

| 情形 | 分级 |
|---|---|
| 拼接的参数值来自外部输入（用户输入、API 返回、数据库字段），存在注入或 URL 破坏风险 | 🟠 注意问题 |
| 拼接的参数值均为内部受控枚举/常量（如 `status = "open"`），当前无转义风险 | 🟡 一般问题 |

---

## 检查项 2：路径段手工拼接

### 检查要点

- **检查项**：路径段是否未经过 `quote(...)` 转义就直接拼入 URL 路径（路径段中的 `/`、`?`、`#` 会改变 URL 结构，如 `user_id = "a/b"` 变成两级路径）
- **检查项**：拼接时是否统一处理了多余/缺失的 `/`（如 `base_url` 末尾带 `/` 而 path 开头也带 `/`，产生 `//`）
- **检查项**：多次拼接是否建议改用 `urllib.parse.urljoin` 或框架提供的路由反转（如 Django `reverse`、FastAPI `url_path_for`）

### 分级

| 情形 | 分级 |
|---|---|
| 路径段来自外部输入且未 `quote` 转义，可能改变 URL 结构（路径穿越风险） | 🟠 注意问题 |
| 仅 `/` 拼接不规范（多余斜杠等），值受控 | 🟡 一般问题 |

---

## 检测手段

### 方式一：Ruff / linter 规则扫描

目前 Ruff 无直接对应规则，可关注：

| 规则 | 说明 | 对应检查项 |
|---|---|---|
| `S310` | `urlopen` 使用可疑 URL（间接线索，命中处常伴随手工拼接） | 检查项 1 / 2 辅助定位 |

执行方式：

```bash
ruff check --select S310 --output-format=json .
```

### 方式二：文本检索（主要手段）

```bash
# 1) 定位 f-string 中含查询串特征的行（?key= 后跟插值，双引号场景）
grep -rnE 'f".*\?.*= *\{' --include="*.py" <仓库路径>

# 2) 定位字符串相加追加查询参数的行（如 += "&keyword=" ）
grep -rnE '\+ *["'"'"'] *&?[a-zA-Z_]+=' --include="*.py" <仓库路径>

# 3) 定位 .format / % 拼接 URL 的行
grep -rnE 'https?://.*(\{[a-zA-Z_]+\}|%s|%\()' --include="*.py" <仓库路径>
```

Windows / PowerShell 环境（Git Bash 不可用时）：

```powershell
Get-ChildItem -Path <仓库路径> -Recurse -Filter *.py |
  Select-String -Pattern 'https?://.*\?.*=\{' 
```

> 上述命令只是**候选位置筛选**，命中的每一行必须结合上下文确认：参数值来源是否为外部输入、是否已有 `urlencode` / `params=` 兜底，再决定是否计入问题及分级。

---

## 报告撰写要求

在审查报告中记录本维度问题时，描述必须包含以下要素：

1. **文件路径 + 行号**
2. **当前写法**（贴出原始代码片段）
3. **影响**：明确写出「参数值未经 URL 编码，含特殊字符时产生错误请求；后续加参数需手工维护 `?`/`&` 拼接，易出错」
4. **修复建议**：给出改写后的代码，优先推荐 `urlencode(params)` 或 HTTP 客户端的 `params=` 参数
5. **规则来源**：若由工具检出，标注对应规则编号

示例条目（外层用四反引号仅为展示，实际写入报告时无需外层围栏）：

````markdown
### 🟡 一般问题：URL 查询串使用 f-string 手工拼接

**文件**：`app/services/order_service.py:86`

**当前写法**
```python
url = f"{base_url}/api/orders?status={status}&page={page}"
```

**影响**：`status`、`page` 未经 URL 编码直接嵌入查询串，值含特殊字符（空格、中文、`&`、`+`）时
会产生格式错误或语义错误的请求；后续新增参数需手工维护 `?` 与 `&` 的拼接位置，容易出错。

**修复建议**
```python
from urllib.parse import urlencode

params = {"status": status, "page": page}
url = f"{base_url}/api/orders?{urlencode(params)}"
# 或直接使用 HTTP 客户端参数化构造：
resp = requests.get(f"{base_url}/api/orders", params=params)
```
````
