# 主题系统

| Field | Value |
|---|---|
| lang | zh-CN |
| pair | ../en/THEME.md |
| applies_to | 0.1.0 |
| doc_version | 1.0 |
| last_reviewed | 2026-10-24 |
| canonical | false |
| status | current |

**语言：** [English](../en/THEME.md) | 中文

## 范围

亮色与暗色主题覆盖页面、卡片、表单、按钮、表格、代码块、提示、弹窗、文件输入、页脚、
图与导出。主题与语言相互独立：四种组合都必须可用。

## 令牌

语义令牌定义在两处：`R/fct_theme.R`（绘图/导出）与 `www/css/app.css` 的 CSS 变量。
两者必须同步。

| 令牌 | 亮色 | 暗色 | 用途 |
|---|---|---|---|
| `bg` | `#F7F9FB` | `#0B1220` | 页面背景 |
| `surface` | `#FFFFFF` | `#111A2B` | 卡片与表格 |
| `surface2` | `#EEF3F7` | `#172236` | 次级表面 |
| `text` | `#10243E` | `#E6EDF5` | 主文字 |
| `text_muted` | `#48617A` | `#A9B7C6` | 次级文字 |
| `primary` | `#0C7A7C` | `#3CC7C2` | 按钮、链接、主曲线 |
| `primary_soft` | `#D9F0EF` | `#123B3A` | 选中态、提示背景 |
| `accent` | `#B87316` | `#F2B45C` | 警告与高亮 |
| `accent_ink` | `#6B4300` | `#FFD79A` | 警告文字 |
| `danger` | `#B23A2E` | `#FF7A6B` | 错误 |
| `border` | `#D5DFE8` | `#263445` | 边框与分隔线 |
| `focus` | `#1F6FEB` | `#7CC4FF` | 焦点环 |
| `plot_bg` | `#FFFFFF` | `#0B1220` | 图背景 |
| `plot_fg` | `#10243E` | `#E6EDF5` | 图文字与坐标轴 |
| `plot_grid` | `#DCE4EC` | `#263445` | 网格线 |

亮色主色使用 `#0C7A7C` 而非更浅的青绿色，使白色按钮文字的对比度至少达到 4.5:1。

## 无闪烁初始化

`<head>` 中的内联脚本在页面绘制前运行：

1. 读取 `?theme=`、`localStorage["mcmc3r-bench-theme"]` 与
   `prefers-color-scheme`。
2. 设置 `<html data-bs-theme="light|dark">`、`theme-dark` 类与 `data-theme`。
3. 更新 `<meta name="theme-color">`。

服务器渲染的 HTML 不硬编码亮色背景或文字颜色。

优先级：URL 参数 > 保存的偏好 > 系统偏好 > 亮色。

## 切换

顶部切换器更新属性、保存偏好、更新标签与 `aria-label`，并发送
`Shiny.setInputValue("theme", value)`。服务器用 `reactiveVal` 保存，供绘图与导出使用。
切换不刷新页面、不重置输入、不重新计算上游结果。

## 绘图

`fct_plots` 接收 `theme` 并使用 `plot_colors()`。base graphics 设置
`par(bg, fg, col.axis, col.lab, col.main, col.sub)`，网格线使用 `--plot-grid`。
`plotOutput` 容器没有固定白色背景。

主题变化时，图与表从内存结果重新渲染。字体通过 `sysfonts` 与 `showtext` 注册一次；
PNG 使用 cairo 设备，PDF 使用 cairo_pdf，并按导出调整 DPI。

## 表格

DT 使用 Bootstrap 5 样式。暗色模式覆盖表格背景、表头、斑马纹、悬停、链接与空状态
文字，确保没有白色单元格。

## 导出

| 场景 | 默认 | 可选 |
|---|---|---|
| 屏幕图 | 跟随应用主题 | — |
| PNG/PDF | 打印（亮色）主题 | 匹配屏幕主题 |
| CSV | 无主题 | — |

导出使用所选主题从结果对象重新生成，绝不复用屏幕位图。元数据记录 `screen_theme` 与
`export_theme`。

## 可访问性

- 正文对比度 ≥ 4.5:1（主要文字目标 ≥ 7:1）。
- 两种背景上的焦点环均可见。
- 状态使用图标 + 文字，不只依赖颜色。
- 尊重 `prefers-reduced-motion`。
- 切换器有可访问名称与 `aria-pressed`。
- 两种主题使用相同的键盘与屏幕阅读器走查。

## QA 矩阵

2 语言 × 2 主题 × 2 视口（桌面 1440×900、移动 375×812）= 8 张截图，存放在
`docs/assets/screenshots/`。检查空、加载、成功、警告、错误状态，以及表格、代码块、
提示、弹窗与下载。
