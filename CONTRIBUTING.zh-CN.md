# 贡献指南

感谢帮助改进 mcmc3r 实验台。本项目是 MIT 许可 `mcmc3r` 包的独立、非官方
图形界面。参与贡献即表示你同意 [行为准则](CODE_OF_CONDUCT.zh-CN.md)，并同意代码贡献
按 MIT、文档贡献按 CC BY 4.0 授权。

## 开始之前

- 重大功能或行为变更请先提交 issue 讨论。
- 不要在本仓库修改上游 `mcmc3r`；它是锁定版本的依赖。
- 不要包含 secret、token 或私有数据。
- 保持改动聚焦，避免无关重构。

## 开发环境

```bash
cd mcmc3r-Bench
Rscript -e 'renv::restore()'
Rscript -e 'shiny::runApp(".")'
```

若无法访问上游 GitHub 仓库，可在开发时把本地快照安装到 `.Rlib`；部署构建必须使用
锁定的 GitHub 源。

## 架构规则

- UI 模块调用 service 函数，绝不直接调用 `mcmc3r::`。
- service 不接触 `input`、`output` 或 `session`。
- 上游调用包裹在 `withr::with_dir()` 中；绝不全局调用 `setwd()`。
- 文件只写入会话临时目录。
- 服务器端文案使用 `tr()`，静态界面文案使用 `data-i18n` key。
- 颜色使用主题令牌；不要硬编码亮色。
- 所有用户可见失败都抛出 `app_error`。
- 新增依赖必须有明确理由，并更新 `renv.lock`。

## 双语变更

- 在 `i18n/translations.csv` 中同时更新 `en` 与 `zh`。
- 运行 `Rscript dev/build_i18n.R`；不要手工编辑 `www/js/i18n.js`。
- 同时更新 `i18n/help_en.md` 与 `help_zh.md`。
- 在同一提交中更新 `docs/en/` 与 `docs/zh/` 的对应文件。
- 引入新术语前先更新 `docs/GLOSSARY.md`。

## 测试

```bash
Rscript tests/testthat.R
Rscript dev/i18n_check.R
Rscript dev/docs_check.R
Rscript dev/check_release.R
```

新增 service 行为需补测试；新增文件边界需补夹具。不要提交大数据；单个夹具须小于 5 MB。

## 提交与 PR

使用 Conventional Commits，例如：

```
feat(calibration): add quantile table
fix(marginal): reject beta values equal to 1
docs(i18n): update glossary
test(mcmc): cover tau_ prefix
```

PR 应说明变更内容、列出受影响的 i18n key 与文档对，UI 变更附截图（EN/ZH、亮/暗），
并确认测试通过。优先使用 squash merge。

## 报告问题

请附应用版本、模块、错误码、语言/主题、浏览器与复制的诊断信息。不要上传机密数据；
最小可复现输入非常有帮助。

## 安全

请按 [SECURITY.zh-CN.md](SECURITY.zh-CN.md) 私下报告漏洞，不要公开提交含利用细节的
issue。
