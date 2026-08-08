# 常见问题

| 问题 | 解决方案 |
|------|---------|
| SSH 克隆失败 | 1. 按「仓库获取规范 > GitHub SSH 密钥检查与配置」流程自动检查/生成密钥并发送给用户；2. 若自动流程后仍失败，尝试切换到 HTTPS 方式克隆 |
| HTTPS 克隆失败（网络超时/连接重置） | 1. 检查网络连接；2. 尝试使用镜像加速（如 ghproxy.com、ghps.cc 等）；3. 检查是否需配置 HTTP 代理 |
| 无 Git 配置（git 命令不存在） | 1. 提示用户安装 Git；2. 若无法安装，尝试使用 curl/wget 下载 ZIP 包解压作为备选 |
| Tag 不存在 | 使用 git tag -l 查看可用 tag，或使用 commit hash 替代 |
| 文件夹不存在 | 自动创建 CodeReview 及项目子文件夹 |
| 已忽略与误报问题清单不存在 | 首次审查时 `ignored_issues.md` 可能不存在，属于正常情况，工具会自动创建 |
| 已忽略或误报问题仍在报告中出现 | 1. 检查 `ignored_issues.md` 中对应条目的「文件路径」和「问题标题」是否与新报告中的问题完全一致；2. 确认用户是否使用了标准标记（忽略：`（忽略）` / `(ignore)` 等；误报：`（误报）` / `(false positive)` / `(FP)` 等）；3. 若用户手动编辑了清单，检查格式是否正确（应为 Markdown 表格行）；4. 如需恢复跟踪，从清单中删除对应条目即可 |
| 误标记（不想忽略或误报却被记录） | 1. 打开 `ignored_issues.md` 手动删除对应条目；2. 下次审查将恢复跟踪该问题；3. 若频繁误标记，检查标记识别规则是否过于宽泛 |
| Pyright / Pyrefly / pyupgrade / Ruff 等工具未安装 | 统一参考 [references/python_dependency_installation/review_tools.md](references/python_dependency_installation/review_tools.md)。执行前应先检测环境（uv / Conda / pip / pipx）和已安装版本，优先升级 |
| Pyright 安装失败 | 按 [review_tools.md > Pyright](references/python_dependency_installation/review_tools.md#pyright) 的 fallback 链执行，全部失败后注明「Pyright 安装失败，未执行类型检查」 |
| Pyrefly 安装失败 | 按 [review_tools.md > Pyrefly](references/python_dependency_installation/review_tools.md#pyrefly) 的 fallback 链执行，全部失败后注明「Pyrefly 安装失败，未执行交叉验证检查」，不影响 Pyright 主检查 |
| Pyright 检查报错（内存/超时） | 1. 尝试增加 Node 内存限制：`NODE_OPTIONS="--max-old-space-size=4096" pyright`；2. 检查是否存在循环导入或超大文件导致分析超时；3. 若仍失败，跳过类型检查维度 |
| Pyrefly 检查报错（内存/超时） | 1. 检查是否存在循环导入、超大文件或复杂类型推导导致分析超时；2. 尝试限制分析范围或排除大型生成文件；3. 若仍失败，跳过 Pyrefly 交叉验证维度 |
| Pyright 版本不兼容 | 检查项目 `pyrightconfig.json` 或 `pyproject.toml` 中 Python 版本配置，并按 [review_tools.md](references/python_dependency_installation/review_tools.md) 升级 |
| pyupgrade 安装失败 | 按 [review_tools.md > pyupgrade](references/python_dependency_installation/review_tools.md#pyupgrade) 的 fallback 链执行，全部失败后注明「pyupgrade 检查未执行」 |
| Ruff 安装失败 | 优先使用项目已配置的 `ruff check`；否则按 [review_tools.md > Ruff](references/python_dependency_installation/review_tools.md#ruff) 的 fallback 链执行，全部失败后注明「Ruff 弃用检查未执行」 |
| 前端项目 Node 环境不存在或版本不匹配 | 按 [frontend_dependency_installation/node_environment.md](references/frontend_dependency_installation/node_environment.md) 使用 Volta 安装/切换 Node 版本；失败后注明「Node 环境准备失败」并降级执行 |
| 前端项目 `node_modules` 缺失导致 tsc/ESLint 大量误报 | 按 [frontend_dependency_installation/project_dependencies.md](references/frontend_dependency_installation/project_dependencies.md) 安装项目业务依赖；安装失败后在报告中注明并降级执行 |
| 前端项目存在多个锁文件 | 按 pnpm > yarn > bun > npm 优先级选择包管理器，避免混用导致依赖不一致 |
