# 项目结构与目录划分检查

> 本文件为 `review_process.md` 第 9 节「项目结构与目录划分检查」的详细内容。
> 适用于具有明确框架约定或推荐结构的项目（如 FastAPI、Django、Next.js、React 等）。
> 若项目为无明确框架结构的纯脚本或辅助代码集合，可跳过本维度。

---

## 执行原则

- **框架优先**：以项目所用框架/生态的官方或社区主流约定为基准，不强制统一所有项目的风格。
- **职责清晰**：目录和文件的划分应体现代码职责，便于快速定位和维护。
- **适度约束**：不追求过度拆分，避免为了结构而结构；目录层级建议不超过 3-4 层。
- **可理解性**：新接触项目的开发者应能通过目录名称大致判断其内容。

---

## 通用检查项

### 目录职责

- **检查项**：同一目录内的文件是否围绕同一职责，避免「万能目录」变成垃圾桶
  - 反例：`common/`、`utils/`、`helpers/`、`misc/` 中混入大量业务逻辑
  - 反例：`service/` 目录中同时包含数据访问、HTTP 处理、邮件发送等无关代码
- **检查项**：业务模块、工具函数、配置、测试、静态资源等是否各归其位
  - 正例：配置文件集中在 `config/` 或项目根目录，静态资源放在 `public/` / `static/`
- **检查项**：目录层级是否过深（建议不超过 3-4 层）
  - 反例：`src/features/users/modules/auth/components/forms/LoginForm.tsx`

### 入口与边界

- **检查项**：项目入口文件是否明确且位置合理
  - Python: `main.py`、`app/main.py`、`manage.py`
  - Node.js: `src/index.ts`、`app.js`
  - Next.js: `app/layout.tsx` / `pages/_app.tsx`
- **检查项**：是否存在多个互相冲突的入口或冗余的旧入口文件
- **检查项**：测试文件是否与源码清晰对应（统一放在 `tests/` 或紧邻被测文件）

### 命名一致性

- **检查项**：同一层级目录的命名风格是否统一（不混用 snake_case、camelCase、kebab-case）
- **检查项**：目录名是否简洁且具有描述性，能体现模块职责
- **检查项**：是否避免空目录或只包含单个文件的过度拆分目录

---

## FastAPI 项目

### 推荐结构参考

```text
project/
├── app/
│   ├── __init__.py
│   ├── main.py              # 应用入口
│   ├── config.py            # 配置
│   ├── dependencies.py      # 依赖注入
│   ├── routers/             # API 路由（按业务模块拆分）
│   ├── models/              # ORM / 数据库模型
│   ├── schemas/             # Pydantic 序列化/反序列化模型
│   ├── services/            # 业务逻辑
│   └── utils/               # 纯工具函数（无业务逻辑）
├── tests/
├── requirements.txt
└── Dockerfile
```

### 检查项

- **检查项**：路由是否按业务模块拆分，避免所有接口堆在 `main.py`
- **检查项**：数据库模型（ORM）与 Pydantic schema 是否分离
- **检查项**：业务逻辑是否集中在 `services/`，而非直接写在路由或模型中
- **检查项**：依赖注入（`dependencies.py`）是否被合理使用，避免路由函数过于臃肿
- **检查项**：配置是否按环境拆分（如 `.env` + `config.py`），避免硬编码

---

## Django 项目

### 推荐结构参考

```text
project/
├── manage.py
├── project/                 # 项目配置目录
│   ├── settings/
│   ├── urls.py
│   └── wsgi.py / asgi.py
├── apps/                    # 业务 app（或放在项目根目录）
│   ├── users/
│   │   ├── models.py
│   │   ├── views.py
│   │   ├── serializers.py
│   │   ├── urls.py
│   │   ├── admin.py
│   │   └── migrations/
├── templates/
├── static/
├── tests/
└── requirements.txt
```

### 检查项

- **检查项**：是否遵循 Django 默认结构：`project/`、`apps/`、`templates/`、`static/`、`migrations/`
- **检查项**：自定义 app 是否通过 `INSTALLED_APPS` 注册
- **检查项**：`models.py`、`views.py`、`serializers.py`、`urls.py` 是否按 app 拆分
- **检查项**：模板和静态文件是否按 app 或全局正确放置
- **检查项**：管理后台配置（`admin.py`）是否与模型一一对应，避免集中注册到项目级目录

---

## React / Next.js 项目

### 推荐结构参考

```text
project/
├── app/                     # Next.js App Router 路由
│   ├── layout.tsx
│   ├── page.tsx
│   └── api/                 # API 路由
├── components/              # 可复用组件
│   ├── ui/                  # 基础 UI 组件
│   └── features/            # 业务组件
├── lib/                     # 工具函数、客户端/服务端共享逻辑
├── hooks/                   # 自定义 React Hooks
├── types/                   # TypeScript 类型定义
├── styles/                  # 全局样式
├── public/                  # 静态资源
├── tests/
└── package.json
```

### 检查项

- **检查项**：Next.js App Router 项目是否区分 `app/`（路由）与 `components/`（可复用组件）
- **检查项**：是否避免在 `app/` 目录中存放大量非路由组件
- **检查项**：客户端组件（`'use client'`）与服务端组件是否按职责分离
- **检查项**：公共工具、Hooks、类型定义是否分别放在 `lib/`、`hooks/`、`types/` 等目录
- **检查项**：静态资源是否统一放在 `public/`
- **检查项**：API 路由（`app/api/` 或 `pages/api/`）是否与页面路由清晰区分
- **检查项**：样式文件是否与组件同目录或统一放在 `styles/`，避免散落各处

---

## 问题分级参考

| 级别 | 典型问题 |
|------|---------|
| 🔴 严重 bug | 路由/入口文件位置错误导致运行失败（如 Next.js 页面放错目录、Django app 未注册、FastAPI 路由未引入主应用） |
| 🟠 注意问题 | 业务逻辑泄漏到通用目录；API 与页面未分离；模型与 schema 未拆分 |
| 🟡 一般问题 | 目录层级过深；测试文件位置不一致；同一层级命名风格混用；存在「垃圾桶」目录趋势 |
| 🟢 轻微问题 | 空目录残留；个别文件命名与所在目录风格不一致；注释掉的旧目录未清理 |

---

## 审查建议

- 结构问题通常没有唯一正确答案，应优先参考项目自身 README、框架官方文档或团队约定。
- 对于历史项目，允许存在与当前推荐结构不一致的地方，但应标记其是否造成实际维护困难。
- 提出结构类问题时，建议同时给出具体的迁移方案或目录调整示例，而不是仅指出「结构不好」。
