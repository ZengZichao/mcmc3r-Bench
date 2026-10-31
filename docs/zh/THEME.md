# 主题系统

| Field | Value |
|---|---|
| lang | zh-CN |
| pair | ../en/THEME.md |
| applies_to | 0.1.0 |
| doc_version | 1.1 |
| last_reviewed | 2026-10-25 |
| canonical | false |
| status | current |

**语言：** [English](../en/THEME.md) | 中文

## 范围

亮色与暗色主题覆盖页面、卡片、表单、按钮、表格、代码块、提示、弹窗、文件输入、页脚、
图与导出。主题与语言相互独立：四种组合都必须可用。

## 设计语言

界面遵循 `design-md/apple/DESIGN.md` 中的 Apple 风格体系：

- **操作蓝是唯一界面强调色。** 所有链接、胶囊按钮、选中态与焦点环均使用
  `primary`；警告与错误仅使用各自的状态色。
- **以表面层级建立秩序。** 亮色模式为羊皮纸底 `bg` 上的白色卡片；暗色模式为
  纯黑底上的近黑卡片。卡片仅用 1px 细线，**不使用阴影**。
- **字体安静而紧凑。** 展示文字为 600 字重并带负字距；正文 17px / 1.47。
  不使用 500 字重。
- **两套按钮语法。** 操作使用胶囊按钮，下载与示例使用 8px 紧凑工具按钮。
  按下状态统一为 `transform: scale(0.95)`。
- **全局仅保留一处产品阴影。** 界面组件不投射阴影，系统中只定义
  系统里唯一的投影就是 `--product-shadow`，只用于帮助浮层与产品图。
- **全局框架后退。** 48px 黑色全局导航、52px 毛玻璃子导航、扁平提示条与
  羊皮纸页脚共同框住工作台。

## 令牌

语义令牌定义在两处：`R/fct_theme.R`（绘图/导出）与 `www/css/app.css` 的 CSS 变量。
两者必须同步。

| 令牌 | 亮色 | 暗色 | 用途 |
|---|---|---|---|
| `bg` | `#F5F5F7` | `#000000` | 页面背景 |
| `surface` | `#FFFFFF` | `#1D1D1F` | 卡片、表格、面板 |
| `surface2` | `#FAFAFC` | `#272729` | 珍珠表面、次级表面 |
| `text` | `#1D1D1F` | `#F5F5F7` | 主文字 |
| `text_muted` | `#6E6E73` | `#A1A1A6` | 次级文字 |
| `primary` | `#0066CC` | `#2997FF` | 操作蓝：链接、按钮、主曲线 |
| `primary_soft` | `#E8F1FB` | `#0A2A45` | 选中态、提示背景 |
| `on_primary` | `#FFFFFF` | `#001D33` | 主按钮文字 |
| `accent` | `#B25000` | `#FFB340` | 警告与高亮 |
| `accent_ink` | `#7A3B00` | `#FFD9A0` | 警告文字 |
| `danger` | `#B3261E` | `#FF6961` | 错误 |
| `danger_soft` | `#FDECEA` | `#3A1210` | 错误提示背景 |
| `ok` | `#1D7A46` | `#5BD6A8` | 成功状态 |
| `border` | `#C9C9CF` | `#47474B` | 仅装饰性细线 |
| `border_strong` | `#86868B` | `#7C7C81` | 用于标识控件的边界；对 `surface` 达到 3:1 |
| `divider` | `#DEDEE3` | `#3A3A3F` | 分区分隔线 |
| `tile_1` | `#FAFAFC` | `#272729` | 卡片内的面板（空状态、指标块） |
| `tile_2` | `#F5F5F7` | `#2A2A2C` | 交替面板底色 |
| `tile_fg` | `#1D1D1F` | `#F5F5F7` | `tile_1` 上的正文；必须成对使用 |
| `tile_muted` | `#6E6E73` | `#CCCCCC` | `tile_1` 上的次要文字 |
| `focus` | `#0071E3` | `#2997FF` | 焦点环 |
| `plot_bg` | `#FFFFFF` | `#000000` | 图背景 |
| `plot_fg` | `#1D1D1F` | `#F5F5F7` | 图文字与坐标轴 |
| `plot_grid` | `#E0E0E0` | `#333336` | 网格线 |

图表系列使用受 Apple 系统色启发的数据色板（蓝、靛、橙、紫、绿），不属于界面
强调色。亮色主色为 `#0066CC`，白色按钮文字对比度 5.57:1；暗色主色为 `#2997FF`，
使用近黑文字（6.96:1），既保留明亮苹果蓝又满足 WCAG AA。

## 无闪烁初始化

`<head>` 中的内联脚本在页面绘制前运行：

1. 读取 `?theme=`、`localStorage["mcmc3r-bench-theme"]` 与
   `prefers-color-scheme`。
2. 设置 `<html data-bs-theme="light|dark">`、`theme-dark` 类与 `data-theme`。
3. 更新 `<meta name="theme-color">`（亮色 `#F5F5F7`，暗色 `#000000`）。

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

DT 被重绘为画廊式表格：透明背景、细线行分隔、小号弱化表头、无斑马纹，并使用
柔和的操作蓝悬停底色。暗色模式覆盖所有单元格、控件与空状态颜色，确保没有白色
单元格。

## 打印

`www/css/print.css` 必须重置**所有**在深色主题下取深色值的令牌，包括 `*_soft` 底色、`tile_*` 面板色与 `inverse` 文字色。漏掉任何一个，深色模式打印时就会出现“深底深字”而纸面不可读。新增令牌时必须同步打印样式表。

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
