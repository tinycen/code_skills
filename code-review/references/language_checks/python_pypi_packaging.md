# 依赖管理检查（PyPI 项目）

> 本文件为 `review_process.md` 第 5 节「依赖管理检查」的详细内容，适用于 Python（PyPI）项目。
> 若仓库中不存在 Python 文件（`.py`），跳过本维度。

---

## 依赖声明

- **检查项**：requirements.txt 是否存在
- **检查项**：依赖版本是否固定
- **检查项**：是否存在冲突依赖
- **检查项**：依赖包是否存在已知漏洞（CVE）

## 包导入导出

- **检查项**：__init__.py 是否正确导出
- **检查项**：循环导入是否存在
- **检查项**：未使用的导入是否清理

## 包结构

### 推荐目录布局

#### src layout（推荐用于较复杂的库）

```text
project/
├── src/
│   └── package_name/          # 包源码
│       ├── __init__.py
│       └── ...
├── tests/                     # 测试代码
├── docs/                      # 文档
├── pyproject.toml             # 包元数据与构建配置
├── README.md
├── LICENSE
└── MANIFEST.in                # 控制非代码文件是否打入分发包
```

#### flat layout（适合简单项目）

```text
project/
├── package_name/              # 包源码，与项目根目录平级
│   ├── __init__.py
│   └── ...
├── tests/
├── pyproject.toml
├── README.md
└── LICENSE
```

### 检查项

- **检查项**：目录结构是否规范，是否在 src layout 与 flat layout 之间混用
- **检查项**：包目录名是否为合法 Python 标识符（不以数字开头、不含连字符/空格等非法字符），否则相对导入无法被正确解析
- **检查项**：包名目录是否与 `pyproject.toml` / `setup.py` / `setup.cfg` 中声明的 `name` 一致
- **检查项**：setup.py / pyproject.toml 是否完整，是否包含必要的元数据（name、version、author、license、dependencies 等）
- **检查项**：MANIFEST.in 是否配置，确保模板、数据文件、配置文件等非 Python 文件被打包
- **检查项**：测试是否独立放在 `tests/` 目录，避免与源码混在一起
- **检查项**：是否包含 `README.md`、`LICENSE` 等必要的项目元数据文件
- **检查项**：是否意外把构建产物（`dist/`、`build/`、`.egg-info/`、`.pyc`、 `__pycache__/`）提交到仓库
- **检查项**：`.gitignore` 是否排除了虚拟环境目录（`venv/`、`.venv/`）和构建产物
