# 工作流一：手动触发代码审查

本文件定义用户主动要求审查代码时的完整流程，包括本地审查场景与远程对话场景。

> 本工作流只描述步骤顺序与分支判断，具体执行规范引用 `references/` 下的对应文档。

---

## 触发条件

以下任一条件满足时，使用本工作流：

- 用户明确说出"帮我审查代码"、"检查代码质量"、"生成审查报告"等。
- 当前在代码仓库内使用 /code-review 等方式调用本技能，直接触发本 skill。
- 通过插件工具或远程对话方式调用。

> 本工作流**无条件执行完整审查**，不检查版本是否变化。

---

## 执行步骤

### 步骤 1：确定审查场景与目标位置

- **远程对话场景 / 插件工具场景**：
  - 用户提供仓库 SSH 地址（如 `git@github.com:org/repo.git`）。
  - 按路径规则计算本地绝对路径，进入步骤 2。
- **本地审查场景**：
  - 用户直接提供本地代码路径，或当前工作目录即为目标代码仓库。
  - 若路径不存在：终止流程并报告本地仓库路径不存在。
  - 若路径存在：直接使用当前本地代码，记录来源为「本地已存在」。

### 步骤 2：获取远程代码（仅远程对话场景执行）

按 [references/repository_access.md](references/repository_access.md) 执行仓库获取流程：

- 先执行 GitHub SSH 密钥检查与配置（仅 GitHub）。
- 检查目标本地绝对路径是否已存在仓库代码。
- 若已存在：执行更新本地仓库。
- 若不存在：执行克隆仓库。
- 若克隆/推送过程中因权限被拒绝：执行 GitHub SSH 权限重试。
- 记录实际来源方式。

### 步骤 3：获取版本信息

按 [references/repository_access.md > 版本信息获取](references/repository_access.md#版本信息获取) 执行：

- 获取最新 tag 版本号。
- 获取最近提交信息（截止提交）。

### 步骤 4：扫描已整理报告并更新已忽略与误报问题清单

按 [references/review_process.md > 已忽略与误报问题去重与报告归档](references/review_process.md#已忽略与误报问题去重与报告归档) 执行：

- 扫描 `docs/code_reviews/fixed/` 目录下的报告文件。
- 提取标记为「忽略」或「误报」的问题，去重后追加到 `ignored_issues.md`。
- 扫描完成后将 `fixed/` 下全部报告移动到 `archived/`。
- 若归档失败：记录失败原因并继续审查流程，在最终通知中说明。

### 步骤 5：加载已忽略与误报问题清单

按 [references/review_process.md > 已忽略与误报问题去重与报告归档](references/review_process.md#已忽略与误报问题去重与报告归档) 加载 `ignored_issues.md`，提取文件路径与问题标题供审查去重使用。

### 步骤 6：执行代码审查

按 [references/review_process.md](references/review_process.md) 执行：

- 执行前置过滤，跳过废弃/旧文件与文件夹。
- 按检查维度逐项审查。
- 问题分级：严重bug、注意问题、一般问题、轻微问题。
- 跳过已忽略与误报问题。

审查范围、维度说明与分级标准详见 `references/review_process.md`。

### 步骤 7：生成审查报告

按 [references/templates/report.md](references/templates/report.md) 生成 Markdown 格式报告：

- 报告必须包含截止提交信息。
- 报告命名规则、空分类隐藏规则等详见 [references/report_delivery.md > 报告格式与命名](references/report_delivery.md#报告格式与命名)。

### 步骤 8：保存与分发审查报告及忽略与误报清单

按 [references/report_delivery.md](references/report_delivery.md) 执行：

- 默认保存到项目 `docs/code_reviews/` 目录。
- `ignored_issues.md` 与报告一同保存。
- 远程对话场景下尝试 git 提交并推送。
- 推送失败时执行重试与降级通知。

### 步骤 9：发送审查通知

按 [references/report_delivery.md > 通知机制](references/report_delivery.md#通知机制) 输出审查概要并按需附带报告路径或链接。
