# 测试

| Field | Value |
|---|---|
| lang | zh-CN |
| pair | ../en/TESTING.md |
| applies_to | 0.1.0 |
| doc_version | 1.0 |
| last_reviewed | 2026-10-24 |
| canonical | false |
| status | current |

**语言：** [English](../en/TESTING.md) | 中文

## 测试金字塔

```
E2E / shinytest2      关键路径、语言/主题组合
集成                  模块 + 夹具 + 下载
单元                  service、校验、格式化、i18n、主题、文件
```

## 运行测试

```bash
Rscript tests/testthat.R
Rscript dev/coverage.R
Rscript tests/shinytest2/run-tests.R
Rscript dev/i18n_check.R
Rscript dev/docs_check.R
Rscript dev/check_release.R
Rscript dev/benchmark.R
```

`dev/coverage.R` 统计四个 `services_*` 文件，低于 80% 发布门禁会失败。最近一次本地
运行（2026-10-24）的 service 层覆盖率为 **90.89%**：校准 91.41%、边际似然 92.62%、
MCMC 81.82%、导出 100%。

测试 helper 会定位应用根目录、在存在时加入 `.Rlib`，并加载 `global.R`。夹具由
`dev/make_fixtures.R` 生成，存放在 `tests/fixtures/`（小于 5 MB）。

## 单元测试覆盖

### 校准

- 密度与累积概率与 `mcmc3r::dL/dB/dU/pL/pB/pU` 在 `1e-8` 内一致。
- 分位数与 `qL/qB/qU` 在 `1e-6` 内一致。
- 语法字符串符合 MCMCtree 记法。
- CAL-001 … CAL-009 校验错误码。
- 边界无穷密度 CAL-011。
- 自动 X 轴上限有限且为正。
- 非法概率与 X 轴上限输入。

### MCMC 汇总

- MCMCtree 夹具与 `mcmc3r::mcmc.sum` 在 `1e-12` 内一致。
- BPP 夹具自动识别 `tau_` 并保留原始名称。
- 单时间列可用。
- 删除并报告非有限行（MCMC-008）。
- 无时间列（MCMC-003）、空文件（MCMC-002）、重复列名（MCMC-006）、非数值列
  （MCMC-004）、全部非有限（MCMC-007）、行数上限（MCMC-005）。
- 自定义前缀按字面转义并匹配。

### 边际似然

- beta 范围、严格递增、数值可读性与方法上限。
- 高斯–勒让德值与 n 点规则一致。
- ZIP 结构与不安全路径（FILE-002）。
- beta 数量不匹配（ML-004）。
- 步进采样结果与直接上游调用在 `1e-10` 内一致。
- 高斯–勒让德结果与直接上游调用在 `1e-10` 内一致。
- `lnL` 校验（ML-005、ML-006、ML-007）。
- beta=0 转换与 SE 警告标记。

### 横切

- 公式注入转义、自然排序、文件名模板、数值格式化、basename 安全。
- i18n key 唯一、非空值、错误码覆盖、`R/` 中所有 `tr()` key、浏览器字典完整性、
  语言解析。
- 主题对比度（正文 ≥ 7:1，次级文字与按钮 ≥ 4.5:1）、亮暗令牌区分、绘图颜色。
- 校准三种模式的绘图、边际似然图、两种主题下的 PNG/PDF 设备与图形状态清理。
- CSV/JSON/打包导出、元数据字段与稳定的模块数据框。
- ZIP 安全（路径穿越、符号链接、文件数、压缩比）、表格解析、预览转换、上传路径清理。

## 端到端测试

`tests/shinytest2/test-app.R` 启动应用并检查：

1. 导航与中英文切换。
2. 校准默认值生成语法、CSV、PNG 与 PDF 下载。
3. 非法 `tL = 0` 显示 CAL-001，切换语言后错误被翻译且不丢失状态。
4. MCMC 示例汇总、CSV 下载、真实 BPP 文件上传，以及无时间列文件的 MCMC-003。
5. beta 数量不匹配（ML-004）后的边际似然示例计算，以及总表、明细、PNG、PDF 与
   打包下载。
6. 打包元数据记录所选的 `screen` 导出主题。
7. 不安全的 ZIP 以 FILE-002 拒绝。
8. 主题切换保留结果并更新 `data-bs-theme`。
9. 375 px 视口无横向溢出。
10. 关于页显示 v0.1.0、作者与 ORCID、MIT/CC BY 4.0、上游 0.6.0 与非官方声明。

`tests/shinytest2/test-theme.R` 使用新的 Chromote 标签页验证：

1. `?lang=zh&theme=dark` 在首次渲染生效，包括服务端渲染结果。
2. 切换语言与主题后写入 `localStorage`，刷新后保持。
3. URL 参数覆盖已保存偏好。
4. 四种语言 × 主题组合均可完成校准且无横向溢出。
5. 跳转链接指向 `#main`；运行按钮可通过键盘（Enter）完成一次计算。

`tests/shinytest2/run-tests.R` 依次运行两个文件。

不为每个状态提交截图基线；发布清单使用八组合矩阵检查。

## 视觉与响应式检查

视口：1440×900、1024×768、768×1024、375×812。组合：2 语言 × 2 主题 × 桌面/移动
= 8 组。检查空、加载、成功、警告、错误状态；表格可横向滚动；按钮不溢出；暗色无白块；
中文不截断。

## 可访问性检查

- 键盘：Tab 顺序、Enter/Space 触发、可见焦点、跳转链接。
- 屏幕阅读器：表单标签、带 `role="alert"` 的错误提示、页面切换与提示的实时区域。
- 对比度：两种主题下的正文、按钮、错误、警告、表格、焦点环。
- 图表提供数据表替代；颜色不是唯一编码。
- 切换时更新 `<html lang>` 与 `data-bs-theme`。

## 安全检查

- ZIP：`../`、绝对路径、符号链接、压缩炸弹、超多文件、超大解压。
- 文件：空、只有表头、二进制伪装文本、超大、非 UTF-8、重复表头。
- 文本：`<script>`、`=cmd|' /C calc'!A0`、超长模型名。
- 诊断信息不含文件内容或完整路径；日志不含数据。
- `renv.lock` 一致；部署中无本地源包。
- 许可、NOTICE、第三方声明、CITATION、VERSION 一致。

## 性能检查

`dev/benchmark.R` 生成合成表格，记录读取、校验、计算与渲染时间。预算：

| 场景 | 目标 | 上限 |
|---|---|---|
| 校准 1,000 点 | < 300 ms | 1 s |
| 校准 5,000 点 | < 800 ms | 2 s |
| MCMC 汇总 10 万行 | < 2 s | 5 s |
| MCMC 汇总 50 万行 | < 8 s | 15 s |
| 边际似然 10 beta × 2 万行 | < 5 s | 15 s |
| 冷启动（部署后） | < 30 s | 60 s |
| 内存峰值（50 MB 上传） | < 700 MB | 900 MB |

## 发布门禁

- 单元测试全绿；service 覆盖率 ≥ 80%。
- E2E 关键路径全绿；四种语言/主题组合通过。
- i18n 覆盖 100%；无硬编码界面文案。
- 文档 parity 与发布检查通过。
- 安全、可访问性、性能检查有记录。
- staging 与生产冒烟测试有记录；回滚演练过。
