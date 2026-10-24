# 快速开始

| Field | Value |
|---|---|
| lang | zh-CN |
| pair | ../en/QUICKSTART.md |
| applies_to | 0.1.0 |
| doc_version | 1.0 |
| last_reviewed | 2026-10-24 |
| canonical | false |
| status | current |

**语言：** [English](../en/QUICKSTART.md) | 中文

## 使用托管版

1. 打开 Connect Cloud 地址：
   <https://zengzichao-mcmc3r-bench.share.connect.posit.cloud/>
2. 选择 **校准分布探索**、**MCMC 汇总** 或 **边际似然**。
3. 输入参数、上传文件，或载入示例数据。
4. 点击 **运行 / 汇总 / 计算**。
5. 查看表格与图，然后下载 CSV、PNG、PDF 或 ZIP 打包结果。

托管版为 Connect Cloud 免费套餐上的公开应用。计算与用量限制以账户套餐为准
（见 <https://connect.posit.cloud/plans>）；若应用不可用，请在本地运行。请勿上传
机密、个人或受管制数据。

## 本地运行

要求：R 4.6.1、可用的 C/C++ 工具链，以及可访问 CRAN 的网络。上游 `mcmc3r`
包从 GitHub 按 `R/app_meta.R` 中锁定的 commit 安装。

```bash
cd mcmc3r-Bench
Rscript -e 'renv::restore()'
Rscript -e 'shiny::runApp(".")'
```

若 `renv.lock` 无法访问 GitHub，可先安装本地上游快照：

```bash
R CMD INSTALL --library=.Rlib ../mcmc3r-原始代码
Rscript -e '.libPaths(c(".Rlib", .libPaths())); shiny::runApp(".")'
```

项目 `.Rprofile` 在 `.Rlib` 存在时会自动加入该库路径。

## 第一个任务

- 校准分布：保留默认值（`L`、`tL = 10`、`p = 0.1`、`c = 1`、`pL = 0.025`），
  点击 **运行**，即可看到密度、分位数与语法 `L(10, 0.1, 1, 0.025)`。
- MCMC 汇总：点击 **Carnivores（MCMCtree，t_）**，再点击 **汇总**。
- 边际似然：点击 **载入合成示例**，再点击 **计算**。

## 语言与主题

使用顶部的 **EN / 中文** 与太阳/月亮按钮切换。两种偏好都会保存在
`localStorage` 中。URL 参数 `?lang=zh` 与 `?theme=dark` 可覆盖已保存值。
导出默认使用打印（亮色）主题。

## 下一步

- [用户指南](USER_GUIDE.md)
- [文件格式](FILE_FORMATS.md)
- [方法与引用](METHODS.md)
- [常见问题](FAQ.md)
- [隐私说明](PRIVACY.md)
