# 前端项目业务依赖安装策略

> 本文档说明代码审查前是否安装被审查前端项目的**业务依赖**（即 `package.json` 中声明的依赖）。
> 注意：这与**审查工具依赖**（TypeScript、ESLint 等）是两类不同的依赖，审查工具的安装策略见 [node_environment.md](node_environment.md) 及本文档相关章节。

---

## 本地审查场景

- **不安装、不更新项目依赖**，以用户当前本地环境为准，避免破坏用户本地开发环境。
- 直接使用本地已存在的 `node_modules/` 执行检查。
- 若用户本地未安装 `node_modules`，`tsc` / `ESLint` 可能报告大量导入错误，按 [typescript_javascript_check.md](../language_checks/typescript_javascript_check.md) 中的 fallback 链处理，并在报告中注明。

## 远程 Claw 场景

- **在远程代码拉取（同步）完成后，且 Node 环境准备就绪后**，安装/更新项目依赖，使 `tsc` / `ESLint` 能准确解析第三方库类型、插件和配置。
- 安装位置为项目临时工作区内的 `node_modules/`，不污染系统环境。

### 依赖安装/更新命令

根据项目实际使用的包管理器和锁文件选择命令：

| 锁文件 | 包管理器 | 安装命令 |
|---|---|---|
| `package-lock.json` | npm | `npm ci` 或 `npm install` |
| `yarn.lock` | yarn | `yarn install --frozen-lockfile` |
| `pnpm-lock.yaml` | pnpm | `pnpm install --frozen-lockfile` |
| `bun.lockb` | bun | `bun install` |
| 无锁文件 | npm | `npm install` |

> **说明**：
> - 优先使用锁文件保证可复现性；若锁文件与 `package.json` 不一致，使用包管理器自动更新锁文件（`npm install`、`yarn install`、`pnpm install`）。
> - monorepo 项目（如 Turborepo、Nx、pnpm workspace）应在根目录执行安装命令，工具会自动处理各子包依赖。

### 包管理器检测

若项目未明确使用何种包管理器，按以下优先级判断：

1. 根据锁文件判断：`pnpm-lock.yaml` → pnpm，`yarn.lock` → yarn，`bun.lockb` → bun，`package-lock.json` → npm。
2. 若存在多个锁文件，按 **pnpm > yarn > bun > npm** 的优先级选择（pnpm 和 yarn 的锁文件更严格）。
3. 若无任何锁文件，默认使用 npm。

### 版本策略

- 按 `package.json` 中声明的依赖约束进行安装。
- 允许在约束范围内选择最新可用版本，但优先遵循锁文件。
- 若项目配置了 `engines.node` 或 `engines.npm`，安装依赖前应确保 Node 环境满足要求（详见 [node_environment.md](node_environment.md)）。

### `.gitignore` 检查

- 检查 `.gitignore` 是否已排除 `node_modules/`、构建产物目录（`dist/`、`build/`、`.next/`、`.nuxt/` 等）。
- 若未排除，自动追加到 `.gitignore`。
- 在远程 Claw 场景下，可将该 `.gitignore` 修改提交并推送到远程仓库，提交信息固定为：
  ```bash
  git add .gitignore
  git commit -m "chore: ignore node_modules for code review"
  git push
  ```
- 推送失败时记录原因，不阻塞后续审查流程。

### 失败处理

- 依赖安装/更新失败时，降级为不安装依赖直接执行检查，并在报告中注明。
- 若 `tsc` / `ESLint` 因缺少 `node_modules` 产生大量误报，应在报告中说明「项目依赖安装失败，类型/静态检查结果可能不完整」。

---

## 环境隔离要求

- 禁止在审查工具依赖与项目依赖之间混用系统 Node 环境。
- 本地场景不修改用户项目目录。
- 远程 Claw 场景下项目目录为临时工作区，可在项目内安装 `node_modules`，但不得将 `node_modules` 提交到远程仓库。
