# 前端 Node 环境管理指南

> 本文档说明代码审查前如何准备前端项目所需的 Node.js 运行环境，以及如何避免不同项目之间的 Node 版本污染。
>
> **重要区分**：
> - **Node 运行环境**：本文档所述的 Node.js 版本管理，服务于被审查前端项目的依赖安装与工具执行。
> - **前端项目业务依赖**：被审查项目自身运行所需的依赖（如 `package.json` 中声明的依赖），其安装策略见 [project_dependencies.md](project_dependencies.md)。

---

## 执行原则

- **环境隔离优先**：不同前端项目可能依赖不同的 Node 版本，禁止在系统全局 Node 环境上混用，避免版本污染。
- **Volta 作为默认 Node 管理器**：若当前环境未安装 Node，或需要按项目切换 Node 版本，优先使用 [Volta](https://volta.sh) 进行安装和管理。
- **项目配置优先**：若项目已声明 `package.json` 中的 `engines.node` 字段，或存在 `.nvmrc`、`.node-version`、`.volta` 等版本锁定文件，优先按项目声明安装对应 Node 版本。

---

## Node 环境检测

在执行任何前端检查前，先检测当前环境是否具备可用的 Node.js：

1. 检测全局 Node 命令：
   ```bash
   node --version
   npm --version
   ```
2. 检测项目是否已配置 Volta：
   ```bash
   volta --version
   ```
3. 检测项目是否使用 nvm（存在 `.nvmrc`）：
   ```bash
   nvm --version
   ```

### 检测结果处理

| 场景 | 处理方式 |
|---|---|
| 系统已安装 Node，且版本满足项目 `engines.node` 约束 | 直接使用当前 Node 环境 |
| 系统已安装 Node，但版本不满足项目约束 | 使用 Volta 安装项目所需 Node 版本并切换 |
| 系统未安装 Node | 使用 Volta 安装项目所需 Node 版本 |
| 项目未声明 Node 版本约束 | 使用 Volta 安装当前 LTS 版本 |

---

## Volta 安装与使用

### 安装 Volta

若当前环境未安装 Volta，按官方方式安装：

- **Unix/Linux/macOS**：
  ```bash
  curl https://get.volta.sh | bash
  ```
- **Windows / PowerShell**：
  ```powershell
  winget install Volta.Volta
  ```

安装完成后，确保 `volta` 命令可用：

```bash
volta --version
```

### 使用 Volta 安装 Node

```bash
# 安装指定 Node 版本
volta install node@<version>

# 示例：安装 Node 20 LTS
volta install node@20
```

### 项目级 Node 版本固定

进入项目目录后，执行：

```bash
volta pin node@<version>
```

此命令会在 `package.json` 中写入 `volta` 字段，后续在该项目目录下执行 `node` / `npm` / `npx` 时，Volta 会自动使用固定版本。

---

## 本地审查场景

- **不修改用户 Node 环境**，以用户当前本地环境为准。
- 若用户本地未安装 Node 或版本不匹配，提示用户自行安装 Volta 并切换版本，审查工具不自动修改系统环境。
- 直接使用用户本地 `node_modules`（若已存在）。

---

## 远程 Claw 场景

- **在远程代码拉取（同步）完成后**，先检测 Node 环境。
- 若未安装 Node，或版本不满足项目要求，使用 Volta 安装/切换至项目所需 Node 版本。
- 然后再执行项目依赖安装（详见 [project_dependencies.md](project_dependencies.md)）。

### 远程场景 Node 准备流程

1. 检测 `volta` 是否可用；若未安装，按「Volta 安装与使用」章节安装 Volta。
2. 读取项目 Node 版本约束（`.nvmrc`、`.node-version` 或 `package.json` 中的 `engines.node`）。
3. 使用 `volta install node@<version>` 安装目标 Node 版本。
4. 在项目目录执行 `volta pin node@<version>`，固定该项目使用的 Node 版本。
5. 验证 `node --version` 和 `npm --version` 是否符合预期。

> **说明**：Windows / PowerShell 环境下，需使用对应的 PowerShell 语法（如 `Get-Command volta`、`winget install` 等），但准备流程与上述步骤一致。

---

## 失败处理

- Node 环境准备失败时，降级为直接执行前端检查（如 `npx tsc`、`npx eslint`），并在报告中注明「Node 环境准备失败，检查结果可能不完整」。
- 若因 Node 版本不匹配导致检查工具报错，应在报告中明确记录当前 Node 版本与项目要求的版本。

---

## 环境隔离要求

- 禁止在审查工具依赖与项目依赖之间混用系统 Node 环境。
- 本地场景不修改用户项目目录。
- 远程 Claw 场景下项目目录为临时工作区，可使用 Volta 固定项目 Node 版本，但不应将 `package.json` 中的 `volta` 字段修改提交到远程仓库（除非项目原本就使用 Volta）。
