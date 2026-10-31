# mcmc3r Bench

**mcmc3r R 包的独立、非官方双语 Shiny 图形界面。**

[English](README.md) | 中文

[![version](https://img.shields.io/badge/version-0.1.0-0066CC)](VERSION)
[![license](https://img.shields.io/badge/license-MIT-0066CC)](LICENSE)
[![docs](https://img.shields.io/badge/docs-EN%20%7C%20ZH-0066CC)](docs/README.md)
[![在线演示](https://img.shields.io/badge/live%20demo-Connect%20Cloud-0066CC)](https://zengzichao-mcmc3r-bench.share.connect.posit.cloud/)

mcmc3r 实验台把 `mcmc3r` 的三类工作流封装为网页界面：

- **校准分布探索**：L/B/U 密度、累积概率、分位数、MCMCtree 语法、PNG/PDF/CSV 导出。
- **MCMC 汇总**：MCMCtree `t_` 与 BPP `tau_` 输出、缺失值处理、CSV 导出。
- **边际似然**：步进采样与高斯–勒让德求积、ZIP 或单独链文件、logML/SE、
  总表/明细 CSV、图 PNG/PDF、可复现打包。

界面支持中英文与亮/暗主题，两者独立记忆。计算由上游包完成；图形界面负责校验、解释、
主题、错误码与文档。

![校准分布探索，英文亮色主题](docs/assets/screenshots/en-light/desktop.png)

## 在线演示

<https://zengzichao-mcmc3r-bench.share.connect.posit.cloud/>

应用托管在 Posit Connect Cloud。免费套餐提供公开内容与 1 GiB 打包上限；计算资源与用量
限制以账户套餐为准（见 <https://connect.posit.cloud/plans>）。若应用不可用或配额用尽，
请在本地运行。

> **公开应用：** 请勿上传机密、个人或受管制数据。

## 本地快速开始

```bash
cd mcmc3r-Bench
Rscript -e 'renv::restore()'
Rscript -e 'shiny::runApp(".")'
```

要求：R 4.6.1、可编译 R 包的工具链，以及可访问 CRAN 与 GitHub 的网络。上游 `mcmc3r`
必须按锁定 commit 从 GitHub 安装。离线开发时，可把本地上游快照安装到 `.Rlib`，并使用
项目 `.Rprofile`：

```bash
R CMD INSTALL --library=.Rlib ../mcmc3r-原始代码
Rscript -e 'shiny::runApp(".")'
```

详见 [QUICKSTART.md](docs/zh/QUICKSTART.md)。

## 功能

| 模块 | 要点 |
|---|---|
| 校准分布探索 | L/B/U 密度、CDF、分位数、MCMCtree 语法、打印/屏幕导出、150/300 dpi PNG、PDF |
| MCMC 汇总 | 自动/手动 `t_`/`tau_` 前缀、列预览、非有限行报告、CSV |
| 边际似然 | 步进采样、高斯–勒让德、ZIP 安全、各 beta 诊断、总表/明细 CSV、图 PNG/PDF、打包下载 |
| 帮助 / 关于 | 方法、格式、全部错误码、隐私、引用、许可、版本元数据 |
| 全局 | EN/中文、亮/暗、`?lang=`/`?theme=`、键盘支持、ARIA 标签、复制诊断 |

## 输入

- `mcmc.txt`：表头、空白/制表符/逗号分隔、至少两行、`t_`（MCMCtree）或
  `tau_`（BPP）。
- `beta.txt`：每行一个数值、严格递增、不含 1。
- 链 ZIP：`beta.txt` 加 `1/mcmc.txt` … `n/mcmc.txt`；允许外层再套一个目录。
- 单独链文件：每个 beta 点一个文件。

完整规范：[FILE_FORMATS.md](docs/zh/FILE_FORMATS.md)。

## 方法与引用

图形界面不引入统计方法。请引用所用工作流的方法论文、`mcmc3r` 包，并可选引用本软件：

- Yang & Rannala (2006), DOI 10.1093/molbev/msj024
- Inoue, Donoghue & Yang (2010), DOI 10.1093/sysbio/syp078
- dos Reis et al. (2018), DOI 10.1093/sysbio/syy001
- Rannala & Yang (2017), DOI 10.1093/sysbio/syw119
- dos Reis M, Alvarez-Carretero S. (2025). *mcmc3r*（版本 0.6.0）。

详见 [METHODS.md](docs/zh/METHODS.md) 与 [CITATION.cff](CITATION.cff)。

## 部署

应用是标准 Shiny 应用，使用 `renv.lock`，部署在 Posit Connect Cloud，不构建 R 包。
部署步骤、限制、回滚与故障排查见 [DEPLOYMENT.md](docs/zh/DEPLOYMENT.md)。CI 部署
工作流为手动触发，并使用 `production` environment。

## 仓库结构

```
app.R, global.R, VERSION
R/                 模块、service、i18n、错误、文件、绘图、主题
i18n/              translations.csv、help_en.md、help_zh.md
www/               CSS、JS、图片、Noto Sans SC
tests/             testthat、shinytest2、夹具
dev/               构建、检查、基准、截图、部署脚本
docs/              中英双语文档树与截图
.github/           CI、部署、issue/PR 模板
```

## 文档

- [文档索引](docs/README.md)
- [用户指南](docs/zh/USER_GUIDE.md)
- [文件格式](docs/zh/FILE_FORMATS.md)
- [方法](docs/zh/METHODS.md)
- [常见问题](docs/zh/FAQ.md)
- [隐私](docs/zh/PRIVACY.md)
- [技术架构](docs/zh/ARCHITECTURE.md)
- [测试](docs/zh/TESTING.md)

## 作者与贡献归属

**项目作者与维护者：** 曾子超（ZengZichao），`zengzichao@sjtu.edu.cn`，
ORCID [0000-0001-6553-970X](https://orcid.org/0000-0001-6553-970X)，
GitHub [@ZengZichao](https://github.com/ZengZichao)。

基于 Mario dos Reis、Sandra Alvarez-Carretero 及贡献者开发的 `mcmc3r`（MIT）。
mcmc3r 实验台是独立、非官方图形界面，与 `mcmc3r` 作者、MCMCtree、BPP 无隶属或
背书关系。上游作者未参与本图形界面的设计、实现或部署。

## 许可

- 代码：MIT（见 [LICENSE](LICENSE)）。
- 原创文档：CC BY 4.0（见 [docs/LICENSE](docs/LICENSE)）。
- 上游 `mcmc3r`：MIT，Copyright 2017 Mario dos Reis。
- Noto Sans SC：SIL Open Font License 1.1（见 [www/fonts/OFL.txt](www/fonts/OFL.txt)）。

完整声明见 [NOTICE](NOTICE) 与 [THIRD_PARTY_LICENSES.md](THIRD_PARTY_LICENSES.md)。

## 贡献、安全、行为准则

- [CONTRIBUTING.zh-CN.md](CONTRIBUTING.zh-CN.md)
- [SECURITY.zh-CN.md](SECURITY.zh-CN.md)
- [CODE_OF_CONDUCT.zh-CN.md](CODE_OF_CONDUCT.zh-CN.md)

## 免责声明

软件按“原样”提供，不提供担保。托管应用无 SLA；配额、冷启动或平台变更可能影响可用性。
用户对输入数据、参数选择与结果解释负责。本应用不替代 MCMCtree/BPP 的收敛诊断与模型
检查。
