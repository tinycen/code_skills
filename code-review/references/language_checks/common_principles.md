# 检查执行通用原则

> 本文件为 `language_checks/` 各语言维度检查文件共用的执行原则，供各维度文件引用，避免重复表述。
> 各维度可在本通用原则之外，补充自身特有的工具配置与执行约束。

## 忽略范围

- 执行代码扫描和检查时，应跳过 `.gitignore` 中指定的文件和目录，并按 `review_process.md` 前置规则排除废弃/旧文件。若使用 `find` 命令扫描，可通过 `git check-ignore` 或工具自带的忽略逻辑排除。
- 常见应跳过的目录：
  - Python：`__pycache__/`、`.venv/`、虚拟环境目录、构建产物等
  - JavaScript/TypeScript：`node_modules/`、`dist/`、`build/`、`.next/`、`.nuxt/`、构建产物等

## 辅助定位

- 自动化工具（Ruff / grep / Pyright / Pyrefly / tsc / ESLint 等）的诊断信息仅作为问题「线索」，不能直接等同于最终分级结果。必须结合代码上下文阅读分析后，判断是否为真实问题及其实际严重程度。