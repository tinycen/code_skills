# 类型与弃用检查（TypeScript/JavaScript 项目）

> 本文件为 `review_process.md` 第 7 节「类型与弃用检查」的详细内容，适用于 TypeScript/JavaScript 项目。
> 仅当目录中存在 `package.json` **且**包含 TypeScript/JavaScript 文件（`.ts`、`.tsx`、`.js`、`.jsx`）时，才对该目录执行本维度检查。`package.json` 的位置即为 JS/TS 项目的边界——无论是仓库根目录还是子目录中的子项目均适用。缺少 `package.json` 的目录即使存在零散的 JS/TS 文件，也应跳过（这些文件可能是其他项目的辅助脚本，不属于独立的 JS/TS 工程）。

---

## 执行原则

- **忽略范围**：执行代码扫描和检查时，应跳过 `.gitignore` 中指定的文件和目录（如 `node_modules/`、`dist/`、`build/`、`.next/`、`.nuxt/`、构建产物等）。若使用 `find` 命令扫描，可通过 `git check-ignore` 或工具自带的忽略逻辑排除。
- **辅助定位**：tsc 和 ESLint 的诊断信息仅作为问题「线索」，不能直接等同于最终分级结果。必须结合代码上下文阅读分析后，判断是否为真实问题及其实际严重程度。
- **项目配置优先**：若项目已配置 `tsconfig.json`、`tsconfig.*.json`、`.eslintrc.*`、`eslint.config.*`，以项目自身配置为准。执行时优先使用项目已有配置，不强制覆盖。

## 环境准备

> 本节说明执行 tsc / ESLint 前的前端环境与依赖准备策略。

### 本地审查场景

- 以用户当前本地环境为准，不自动安装 Node、不安装项目依赖。
- 若用户本地缺少 `node_modules`，按下方 fallback 链降级执行，并在报告中注明环境状态。

### 远程 Claw 场景

- **Node 环境准备**：先按 [frontend_dependency_installation/node_environment.md](../frontend_dependency_installation/node_environment.md) 检测 Node 环境；若未安装或版本不匹配，使用 Volta 安装/切换至项目所需 Node 版本。
- **项目依赖安装**：Node 环境就绪后，按 [frontend_dependency_installation/project_dependencies.md](../frontend_dependency_installation/project_dependencies.md) 安装/更新 `node_modules`，确保第三方类型、ESLint 插件和框架配置可正确解析。
- 依赖安装完成后，再执行下方的 tsc / ESLint 检查。

## TypeScript 编译检查（tsc）

- ⚠️ **强制四步 fallback 链**：必须按以下顺序执行，每步失败才进入下一步，禁止在任何中间步骤直接跳过编译检查：
  1. 若项目 `package.json` 中包含 `tsc` 相关脚本（如 `"typecheck": "tsc --noEmit"`），优先使用 `npm run <script>` 执行
  2. 若项目无相关脚本，使用 `npx tsc --noEmit` 执行（会自动使用项目本地安装的 TypeScript）
  3. 若 npx 失败（如项目未安装 TypeScript），尝试 `npm install -g typescript` → 成功后使用 `tsc --noEmit` 执行
  4. 若全局安装也失败，在报告中注明「TypeScript 编译检查未执行（原因：xxx）」并跳过该子项
- 重点关注 tsc 输出中的**弃用警告**（diagnostic code `6385`、`6387` 等），这些表示代码中使用了标记为 `@deprecated` 的 API。

## ESLint 检查

- ⚠️ **强制四步 fallback 链**：必须按以下顺序执行，每步失败才进入下一步，禁止在任何中间步骤直接跳过 ESLint 检查：
  1. 若项目 `package.json` 中包含 lint 相关脚本（如 `"lint": "eslint ."` 或 `"lint:js": "eslint --ext .js,.ts,.tsx ."`），优先使用 `npm run <script>` 执行
  2. 若项目无相关脚本，使用 `npx eslint .` 执行
  3. 若 npx 失败（如项目未安装 ESLint 或无配置文件），检测项目的包管理器（根据锁文件判断：`pnpm-lock.yaml` → `pnpm add -D eslint`，`yarn.lock` → `yarn add -D eslint`，`package-lock.json` → `npm install -D eslint`），安装后重新执行 `npx eslint .`
  4. 若安装也失败，在报告中注明「ESLint 检查未执行（原因：xxx）」并跳过该子项
- **注意**：即使 ESLint 安装成功，若项目缺少 ESLint 配置文件或必要的插件（如 `@typescript-eslint`），检查结果可能不完整，应在报告中注明
- 使用 `--format json` 获取结构化输出，便于问题归类。

## 问题分级参考（tsc / ESLint 诊断 → 审查级别对照）

下表提供 TypeScript 编译器和 ESLint 常见诊断与审查级别的**初步对应关系**，供审查时参考。最终级别需结合代码实际逻辑判断：

| 诊断来源与规则 | 参考级别 | 说明与典型误报场景 |
|---|---|---|
| tsc: 弃用警告（`ts(6385)`、`ts(6387)`） | 🟠 注意问题 | 使用了标记 `@deprecated` 的 API。这是**潜在的技术债务**，被弃用的 API 可能在未来版本中被移除，导致升级时出现 breaking change。**误报可能**：第三方库自身标记弃用但尚无替代方案；或项目锁定了库版本短期内不会升级 |
| tsc: 类型错误（TS2xxx） | 🔴 严重bug | 类型不兼容、属性不存在、参数类型错误等。**误报可能**：使用了 `as any` 类型断言绕过的场景；或动态属性访问未正确声明类型 |
| tsc: 可能的 null/undefined（TS2531、TS2532） | 🔴 严重bug | 对象可能为 null 或 undefined。**误报可能**：已有运行时守卫但 TypeScript 未推断出 |
| ESLint: `deprecation/deprecation` | 🟠 注意问题 | 与 tsc 弃用警告类似，ESLint 插件检测到的弃用 API 使用 |
| ESLint: `@typescript-eslint/no-deprecated` | 🟠 注意问题 | TypeScript ESLint 规则检测到的弃用使用 |
| ESLint: `no-unused-vars` / `@typescript-eslint/no-unused-vars` | 🟡 一般问题 | 未使用的变量或导入。**注意**：需确认是否为调试残留 |
| ESLint: `@typescript-eslint/no-explicit-any` | 🟡 一般问题 | 使用了 `any` 类型。**注意**：某些场景（如第三方库无类型定义）下使用 `any` 是合理的 |
| ESLint: `@typescript-eslint/no-non-null-assertion` | 🟡 一般问题 | 使用了非空断言 `!`。**注意**：若已有运行时守卫，可酌情忽略 |
| ESLint: `no-console` | 🟢 轻微问题 | 生产代码中残留 `console.log`。**注意**：需区分调试残留和有意保留的日志输出 |

> **关键原则**：
> - **弃用问题特别关注**：无论 tsc 还是 ESLint 报告的弃用警告，都应认真记录。即使当前版本可正常运行，弃用 API 是潜在的风险点，应在报告中明确标注替代方案（若文档中有说明）
> - tsc/ESLint 的 error 不等于审查分级。例如：tsc 的类型错误若属于已知的第三方库类型定义缺陷，经确认后可降级或不纳入问题列表
> - 必须阅读报错位置的上下文代码（至少包含所在函数/类及调用链），确认是真实问题后再归类。禁止直接按规则名称机械映射
> - 若项目使用 monorepo 结构（如 Turborepo、Nx、pnpm workspace），需针对各子包分别执行检查
