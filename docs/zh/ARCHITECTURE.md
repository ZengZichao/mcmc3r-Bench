# 技术架构

| Field | Value |
|---|---|
| lang | zh-CN |
| pair | ../en/ARCHITECTURE.md |
| applies_to | 0.1.0 |
| doc_version | 1.0 |
| last_reviewed | 2026-10-24 |
| canonical | false |
| status | current |

**语言：** [English](../en/ARCHITECTURE.md) | 中文

## 总览

```
UI（Shiny 模块 + bslib）
  mod_calibration / mod_mcmc_summary / mod_marginal / mod_help / mod_about
        │  只调用 service 函数
服务层
  services_calibration / services_mcmc / services_marginal / services_export
        │  校验、隔离工作目录、调用导出 API
上游层
  mcmc3r（锁定 SHA）+ ape + corpcor + coda
横切：i18n、主题、错误目录、日志、文件安全、绘图、会话临时目录、版本元数据、双语文档。
```

## 加载顺序

`app.R` 初始化应用目录、请求大小选项、i18n 表与随包字体。`global.R` 在优先被加载的
环境中执行相同初始化。Shiny 可能多次加载 `R/` 文件；需要在重复加载后保留的状态存放
在 R option（i18n 表与字体标志）或仅在不存在时创建的环境中。

`R/app_ui.R` 一次性构建整个页面。导航在客户端完成：所有页面区块都在 DOM 中，通过
显示/隐藏切换。这样在切换页面或语言时保留输入值与上传数据。服务器端输出仅在对应页面
激活时渲染，避免零宽绘图设备。

## 分层与规则

- UI 模块从不直接调用 `mcmc3r::`。
- service 函数不接触 `input`、`output` 或 `session`。
- 所有上游调用都在 `withr::with_dir()` 内。
- 所有文件写入都发生在会话临时目录。
- 所有用户可见文案都经过 `tr()` 或带有 `data-i18n` key。
- 所有颜色来自主题令牌；模块不硬编码亮色值。
- 所有错误都是 `app_error`，带稳定错误码、消息 key 与建议 key。

## 状态

`app_server` 持有：

- `lang`：`reactiveVal`，从 URL 查询初始化，并由客户端更新。
- `theme`：`reactiveVal`，从 URL 查询初始化，并由客户端读取 `localStorage`
  与系统偏好后更新。
- `active_tab`：`reactiveVal`，由导航按钮更新。
- `session_dir`：会话开始时创建的唯一临时目录。

模块服务器各自持有上传数据、参数、结果与错误的 `reactiveValues`，不跨会话共享可变状态。

## 临时目录结构

```
tempdir()/mcmc3r-bench/<session-token>/
├── uploads/                 # 清理后的上传文件副本
├── runs/
│   └── run-<timestamp>-<random>/
│       ├── beta.txt
│       ├── 1/mcmc.txt
│       └── ...
└── exports/                 # 临时下载打包
```

`session$onSessionEnded()` 删除整个会话目录。上传文件使用 `basename()` 复制，并替换
特殊字符。ZIP 成员不会按压缩包路径解压；选定条目会流式写入经过清理的目标位置。

## 数据流

### 校准

```
输入 → cal_validate() → x 序列 → mcmc3r::dL/dB/dU 与 pL/pB/pU
     → data.frame(x, density, cdf) → 图/表/CSV/PNG/PDF
```

分位数使用 `qL/qB/qU` 与 `tryCatch`；失败映射为 CAL-010。非有限边界值替换为 `NA`，
并报告 CAL-011。

### MCMC 汇总

```
上传 → data.table::fread → 严格前缀选择 → 数值转换
     → 删除非有限行 → 均值/中位数/分位数 → 表/CSV
```

不直接调用上游 `mcmc.sum()`，因为它在单列与非有限输入上会失败；图形界面显式实现等价
汇总，并与上游函数对比测试。

### 边际似然

```
ZIP/文件 → ZIP 校验 → beta 校验 → 运行目录
         → 仅含 lnL 的链文件 → withr::with_dir(上游调用)
         → logML/SE/mean.logl → 图/表/CSV/ZIP 打包
```

ZIP 模式下 beta 来自压缩包；单独文件模式下 beta 来自上传文件或 `make.beta()`。
每次请求使用唯一的运行目录。

## 错误与日志

`app_error` 携带 `type`、`code`、`message_key`、`hint_key`、`detail` 与 `context`。
界面显示双语消息、建议与折叠的技术详情。诊断信息包含版本与结构计数，不包含文件内容或
完整路径。日志为 INFO/WARN/ERROR 级别的结构化 key=value 行；不记录上传文件名与数据值。

## 资源上限

| 资源 | 上限 |
|---|---|
| 单文件上传 | 50 MB |
| 单次请求总量 | 100 MB |
| ZIP 解压后 | 200 MB |
| ZIP 文件数 | 500 |
| ZIP 压缩比 | 100:1 |
| MCMC 行数 | 500,000 |
| 校准采样点 | 5,000 |
| Beta 点数（步进采样） | 50 |
| Beta 点数（高斯–勒让德） | 100（硬上限 256） |
| 链数 | 50 |

`options(shiny.maxRequestSize = LIMITS$upload_total_mb * 1024^2)` 是传输层上限；
业务校验逐个文件执行。

## 配置

| 变量 | 用途 | 默认 |
|---|---|---|
| `MCMC3R_APP_VERSION` | 覆盖显示版本（CI 校验） | `VERSION` |
| `MCMC3R_LOG_LEVEL` | 日志级别 | `INFO` |
| `MCMC3R_MAX_UPLOAD_MB` | 单文件上传上限（MB，1–500） | `50` |
| `MCMC3R_DEFAULT_THEME` | 自托管默认主题（`light`、`dark`、`auto`） | `auto` |
| `MCMC3R_APP_DIR` | 脚本与测试的应用根目录 | 当前目录 |
| `CONNECT_CLOUD_CLIENT_ID` / `CONNECT_CLOUD_CLIENT_SECRET` / `CONNECT_CLOUD_ACCOUNT` | CI 部署认证 | 未设置 |
| `MCMC3R_ENABLE_MORPHO` | 为 0.3.0 形态学模块保留 | `false` |

运行中的应用不读取 secret，也不把 secret 写入日志。

## 并发

Connect Cloud 为每个应用运行单个实例；CPU 与内存取决于套餐。所有计算同步进行，
运行期间按钮不可重复触发，长任务由输入上限约束。不使用后台队列、数据库或跨会话缓存。

## 缓存

v0.1.0 不缓存校准结果或用户数据。主题或语言变化时，从内存结果重新渲染图与表。未来若
增加缓存，只能用于纯校准数据，并将主题加入缓存 key。

## 部署形态

应用是标准 Shiny 应用（无 `DESCRIPTION`、无包构建）。`renv.lock` 记录 CRAN 包与
锁定的 GitHub 上游。部署脚本显式传入运行时文件列表，并把生成的 manifest 过滤为运行时
依赖闭包，因此文档、测试、开发脚本与本地库不会被上传。
