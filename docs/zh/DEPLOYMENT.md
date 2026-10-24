# 部署

| Field | Value |
|---|---|
| lang | zh-CN |
| pair | ../en/DEPLOYMENT.md |
| applies_to | 0.1.0 |
| doc_version | 1.1 |
| last_reviewed | 2026-10-24 |
| canonical | false |
| status | current |

**语言：** [English](../en/DEPLOYMENT.md) | 中文

## 部署目标

Posit Connect Cloud，内容名 `mcmc3r-bench`，标题 `mcmc3r Bench`。

- 公开地址：<https://zengzichao-mcmc3r-bench.share.connect.posit.cloud/>
- 管理页：<https://connect.posit.cloud/zengzichao>

Connect Cloud 默认使用内容 ID 生成公开地址：
`https://<content-id>.share.connect.posit.cloud/`。在内容设置中设置自定义名称后，地址
变为 `https://<account-name>-<custom-name>.share.connect.posit.cloud/`。

免费套餐默认开启公开访问且不能关闭；打包上限为 1 GiB。CPU、内存与 usage credits 取决于
账户套餐，见 <https://connect.posit.cloud/plans>。当前 usage credits 只统计、不强制
中断，因此应按账户 Usage 页面监控，而不要假设固定的活跃小时配额。

本项目最初面向 shinyapps.io。Posit 正在将该服务迁移到 Connect Cloud，见
<https://docs.posit.co/shinyapps.io/guide/migration/>。应用是标准 Shiny + `renv`，
迁移不需要改代码。

## 前置条件

- 本地 R 4.6.1，与 `renv.lock` 一致。
- 已从 `renv.lock` 恢复 `renv`。
- `mcmc3r` 已从锁定 GitHub commit 安装，且 `DESCRIPTION` 中带有 GitHub remote 元数据；
  否则部署 manifest 无法告诉 Connect Cloud 从哪里下载。确认：

  ```r
  packageDescription("mcmc3r")$RemoteSha
  # "f6a8f78bc55a53b724118480b6fbfbc71d3b0897"
  ```

- 当前版本的 `rsconnect`，支持 Connect Cloud。
- 单元测试、i18n 检查与文档检查全部通过。

## 本地预检

```bash
Rscript -e 'renv::restore()'
Rscript -e 'shiny::runApp(".")'
Rscript tests/testthat.R
Rscript dev/i18n_check.R
Rscript dev/docs_check.R
Rscript dev/check_release.R
```

若 GitHub 不可达，可把 `../mcmc3r-原始代码` 中的上游快照安装到 `.Rlib` 供本地开发。
部署前必须重新从 GitHub 安装 `mcmc3r`，让 manifest 记录 `RemoteSha`；本地
`R CMD INSTALL` 的副本不带该元数据。

## 账户设置

### 交互式

```r
rsconnect::connectCloudUser()
rsconnect::accounts()
```

`connectCloudUser()` 会打开浏览器授权，并在本地保存账户。账户名可在
<https://connect.posit.cloud/whoami> 查看。

### 非交互式（CI）

在 <https://login.posit.cloud/identity/credentials> 创建 OAuth client credential，
然后二选一：

```r
rsconnect::connectCloudClientCredentials(
  clientId     = Sys.getenv("CONNECT_CLOUD_CLIENT_ID"),
  clientSecret = Sys.getenv("CONNECT_CLOUD_CLIENT_SECRET"),
  accountName  = Sys.getenv("CONNECT_CLOUD_ACCOUNT"),
  name         = "connect-cloud"
)
```

或设置同名环境变量，由 `dev/deploy.R` 自动注册。切勿提交 client secret。

GitHub Actions secrets：

- `CONNECT_CLOUD_CLIENT_ID`
- `CONNECT_CLOUD_CLIENT_SECRET`
- `CONNECT_CLOUD_ACCOUNT`

## 部署命令

```r
rsconnect::deployApp(
  appDir        = ".",
  appName       = "mcmc3r-bench",
  appTitle      = "mcmc3r Bench",
  account       = "<account>",
  appVisibility = "public",
  forceUpdate   = TRUE,
  launch.browser = FALSE
)
```

不需要 `server` 参数；已配置账户记录的是 `connect.posit.cloud`。

`dev/deploy.R` 封装了该命令，并完成四件事：

1. 先运行 `dev/check_release.R`。
2. 显式传入 43 个运行时文件，确保 `.Rlib`、`docs/`、`tests/`、`dev/`、`.github/`
   不会被上传；打包约 6.5 MB。
3. 生成部署 manifest，并把包列表过滤为运行时依赖闭包。`renv.lock` 还记录了测试与开发
   包；全部上传会拖慢构建，并可能引入可选系统库。
4. 部署成功后删除临时 `manifest.json`。

可选环境变量：

- `CONNECT_CLOUD_ACCOUNT_NAME`：本地 rsconnect 昵称，默认 `connect-cloud`。
- `MCMC3R_APP_NAME`：内容名，默认 `mcmc3r-bench`；可用 staging 名称测试独立内容。
- `MCMC3R_APP_VISIBILITY`：默认 `public`；可使用 Connect Cloud 支持的其他值。

## 打包内容

包含：

- `app.R`、`global.R`、`VERSION`、`.Rprofile`、`renv.lock`
- `R/`、`i18n/`、`www/`（含随包 Noto Sans SC 字体）
- `LICENSE`、`NOTICE`、`CITATION.cff`、`THIRD_PARTY_LICENSES.md`

由 `dev/deploy.R` 的显式文件列表排除：

- `docs/`、`tests/`、`dev/`、`.github/`
- `.Rlib/`、`renv/` 库、日志、截图、本地夹具

`.rscignore` 记录了预期排除项，但 Connect Cloud 部署不应依赖它：以显式 `appFiles`
列表为准。

## 部署后冒烟测试

v0.1.0 已于 2026-10-24 验证：

- 公开地址返回 HTTP 200，Shiny 界面正常加载。
- 校准默认运行生成 `L(10, 0.1, 1, 0.025)` 与结果卡片。
- 语言切换为中文；主题切换为暗色。
- MCMC 汇总 Carnivores 示例生成包含 `t_n20` 等 `t_` 参数的表格。
- 无控制台错误、无可见错误码。

每次部署后重复：

- 打开公开地址；冷启动无 5xx。
- 校准默认运行正常；EN/ZH × 亮/暗四种组合正常。
- 上传 MCMC 夹具；汇总表与 CSV 下载正常。
- 上传 `ml_demo.zip`；计算 logML；打包下载正常。
- 上传 `unsafe.zip`；以 FILE-002 拒绝。
- 中文 PNG/PDF 无缺字。
- 关于页显示 v0.1.0、作者、ORCID、上游作者、SHA 与许可链接。
- 移动端无横向滚动；暗色主题无白块。
- 内容日志无异常 ERROR。

## CI 工作流

`.github/workflows/deploy.yaml` 为手动触发（`workflow_dispatch`），使用
`production` environment。它恢复 `renv`、安装 `rsconnect`，并运行
`dev/deploy.R`。脚本用三个 `CONNECT_CLOUD_*` secrets 注册服务账户、部署并输出管理页
地址。工作流不在 PR 上运行，也不打印 secrets。第三方 action 应固定到 commit SHA。

## 回滚

1. 检出上一个稳定 tag。
2. `renv::restore()`。
3. 运行 `Rscript dev/deploy.R`。
4. 重复冒烟测试，并在发布说明中记录原因。

跨重新部署，内容 ID 与公开地址保持不变。Connect Cloud 还保留 revision history，可在
内容管理页查看或下载已部署源码。

## 故障排查

| 现象 | 原因 | 处理 |
|---|---|---|
| `Download of the mcmc3r package has failed` | 已安装 `mcmc3r` 缺少 GitHub `RemoteSha` 元数据 | 从锁定 commit 重新安装后部署 |
| `dependency 'cpp11' is not available` / `websocket` 失败 | 测试包进入 manifest | 使用 `dev/deploy.R` 过滤运行时闭包 |
| 打包有几十 MB | 包含了 `.Rlib` 或 docs | 传入显式运行时 `appFiles` 列表 |
| `Unsupported R version` | 平台不支持 lockfile 中的 R 版本 | 查看构建日志，并让 `renv.lock` 对齐受支持版本 |
| `PackageSourceError` | GitHub 包元数据缺失 | 用 `remotes::install_github` 重装并检查 `RemoteSha` |
| `package 'mcmc3r' could not be loaded` | 依赖安装失败 | 查看构建日志；恢复 `ape`、`corpcor`、`coda` |
| `cannot allocate vector` | 输入过大 | 降低上限；使用仅 `lnL` 的优化路径 |
| 中文缺字 | 字体未打包或 cairo 不可用 | 保留 `www/fonts`；检查 cairo |
| 暗色主题闪白 | 缺少内联主题脚本 | 保持 `<head>` 初始化脚本在 CSS 之前 |
| 部署时要求选择账户 | 未配置 Connect Cloud 账户 | 运行 `rsconnect::connectCloudUser()` 或设置 client credentials |
| 内容不是公开的 | 套餐或可见性设置 | 设置 `appVisibility = "public"`；免费套餐只支持公开 |
| 应用不可用 | 平台故障或用量限制 | 查看内容日志与 Admin → Usage；本地运行 |

## 监控

- 内容管理页：实时日志、revision history、usage 与计算设置。
- Admin → Usage 与 Admin → Metrics：credits、计算时间、CPU/内存利用率、连接数。
- 结构化日志：按 `code=` 聚合。
- 发布后连续七天每日检查：错误、冷启动、内存与 usage credits。

## 迁移说明

旧 shinyapps.io 账户在 Posit 2027 迁移波次前可能仍可服务旧链接，但本项目现在只部署到
Connect Cloud。不要再配置旧的 `RSCONNECT_USER`/`RSCONNECT_TOKEN`/`RSCONNECT_SECRET`；
它们指向 shinyapps.io，而不是 Connect Cloud。
