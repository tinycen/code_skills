# 工作流二：定时触发代码审查

本文件定义定时任务、自动化调度触发时的代码审查流程。

> 本工作流只描述步骤顺序与分支判断，具体执行规范引用 `references/` 下的对应文档。

---

## 定时任务前缀识别

- **创建流程**：创建定时任务（cron）时，触发消息必须带有前缀 `【定时自动审查任务】`，用于标识该任务为定时自动审查任务。
- **审查流程**：收到携带该前缀的触发消息时，必须按本工作流执行。

---

## 执行步骤

### 步骤 1：确定目标位置

- 根据配置的仓库 SSH 地址，按路径规则计算本地绝对路径。
- 若该路径不存在：按 [references/repository_access.md > 克隆仓库](references/repository_access.md#克隆仓库) 尝试克隆。
- 若克隆失败：终止流程并报告错误。

### 步骤 2：准备与本地版本检查

- 进入本地绝对路径。
- 检查本地仓库是否有未提交的修改（`git status --short`）。
  - 若有修改：自动执行 `git reset --hard HEAD` 与 `git clean -fd` 撤销所有本地修改。
- 检查仓库是否存在 tag 标签：
  - 存在 tag：获取本地最新 tag，进入步骤 3。
  - 不存在 tag：获取本地 HEAD，进入步骤 4。

### 步骤 3：版本号检查（存在 tag 时执行）

按 [references/repository_access.md > 版本信息获取](references/repository_access.md#版本信息获取) 执行：

- 获取远程最新 tag。
- 远程获取失败时按规范重试，最多 3 次。
- 对比本地与远程最新 tag：
  - 不一致：执行 `git fetch origin --tags` 后进入步骤 5。
  - 一致：强制终止流程，反馈「本地 tag 与远程一致，版本未变化，跳过本次审查」。

> 此规则无条件适用，绝不允许以"例行检查"、"周期审查"等理由绕过。

### 步骤 4：代码变更检查（不存在 tag 时执行）

按 [references/repository_access.md > 版本信息获取](references/repository_access.md#版本信息获取) 执行：

- 获取远程 HEAD。
- 远程获取失败时按规范重试，最多 3 次。
- 对比本地 HEAD 与远程 HEAD：
  - 不一致：执行 `git fetch origin --tags` 后进入步骤 5。
  - 一致：强制终止流程，反馈「本地 HEAD 与远程一致，版本未变化，跳过本次审查」。

> 此规则无条件适用，绝不允许以"例行检查"、"周期审查"等理由绕过。

### 步骤 5：执行审查

触发条件满足时，按 [workflows/manual_workflow.md](workflows/manual_workflow.md) 步骤 4-9 执行完整审查流程。
