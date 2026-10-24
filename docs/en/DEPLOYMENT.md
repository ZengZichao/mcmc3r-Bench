# Deployment

| Field | Value |
|---|---|
| lang | en |
| pair | ../zh/DEPLOYMENT.md |
| applies_to | 0.1.0 |
| doc_version | 1.1 |
| last_reviewed | 2026-10-24 |
| canonical | true |
| status | current |

**Language:** English | [中文](../zh/DEPLOYMENT.md)

## Target

Posit Connect Cloud, content name `mcmc3r-bench`, title `mcmc3r Bench`.

- Public URL: <https://zengzichao-mcmc3r-bench.share.connect.posit.cloud/>
- Admin dashboard: <https://connect.posit.cloud/zengzichao>

Connect Cloud derives the default public URL from the content ID:
`https://<content-id>.share.connect.posit.cloud/`. A custom name can be set in
the content settings; the URL then uses
`https://<account-name>-<custom-name>.share.connect.posit.cloud/`.

On the Free plan, public access is enabled and cannot be disabled. The bundle
limit is 1 GiB. CPU, memory, and usage credits depend on the account plan; see
<https://connect.posit.cloud/plans>. Usage credits are currently reported but
not enforced, so monitor the account Usage page rather than assuming a fixed
hour quota.

This project previously targeted shinyapps.io. Posit is migrating that service
to Connect Cloud; see <https://docs.posit.co/shinyapps.io/guide/migration/>. The
application is a standard Shiny app plus `renv`, so the move does not require
code changes.

## Prerequisites

- R 4.6.1 locally, matching `renv.lock`.
- `renv` restored from `renv.lock`.
- `mcmc3r` installed from the pinned GitHub commit. It must carry GitHub remote
  metadata in its `DESCRIPTION`, otherwise the deployment manifest cannot tell
  Connect Cloud where to download it. Confirm:

  ```r
  packageDescription("mcmc3r")$RemoteSha
  # "f6a8f78bc55a53b724118480b6fbfbc71d3b0897"
  ```

- A current `rsconnect` release with Connect Cloud support.
- All tests, i18n checks, and documentation checks pass.

## Local sanity check

```bash
Rscript -e 'renv::restore()'
Rscript -e 'shiny::runApp(".")'
Rscript tests/testthat.R
Rscript dev/i18n_check.R
Rscript dev/docs_check.R
Rscript dev/check_release.R
```

If GitHub is unreachable, install the bundled upstream snapshot from
`../mcmc3r-原始代码` into `.Rlib` for local development. Before deploying,
reinstall `mcmc3r` from GitHub so the manifest records `RemoteSha`; a local
`R CMD INSTALL` copy does not.

## Account setup

### Interactive

```r
rsconnect::connectCloudUser()
rsconnect::accounts()
```

`connectCloudUser()` opens the browser for authorization and stores the account
locally. The account name is shown at <https://connect.posit.cloud/whoami>.

### Non-interactive (CI)

Create an OAuth client credential at
<https://login.posit.cloud/identity/credentials>, then either:

```r
rsconnect::connectCloudClientCredentials(
  clientId     = Sys.getenv("CONNECT_CLOUD_CLIENT_ID"),
  clientSecret = Sys.getenv("CONNECT_CLOUD_CLIENT_SECRET"),
  accountName  = Sys.getenv("CONNECT_CLOUD_ACCOUNT"),
  name         = "connect-cloud"
)
```

or set the same three environment variables and let `dev/deploy.R` register the
account. Never commit the client secret.

GitHub Actions secrets:

- `CONNECT_CLOUD_CLIENT_ID`
- `CONNECT_CLOUD_CLIENT_SECRET`
- `CONNECT_CLOUD_ACCOUNT`

## Deployment command

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

No `server` argument is needed; the configured account records
`connect.posit.cloud`.

`dev/deploy.R` wraps this command and does four things:

1. Runs `dev/check_release.R` first.
2. Passes an explicit list of 43 runtime files, so `.Rlib`, `docs/`, `tests/`,
   `dev/`, and `.github/` are never uploaded. The bundle is about 6.5 MB.
3. Generates a deployment manifest and filters its package list to the runtime
   dependency closure. `renv.lock` also records test and development packages;
   uploading those would make the build slower and can require optional system
   libraries.
4. Deletes the temporary `manifest.json` after a successful deployment.

Optional environment variables:

- `CONNECT_CLOUD_ACCOUNT_NAME` — local rsconnect nickname (default
  `connect-cloud`).
- `MCMC3R_APP_NAME` — content name (default `mcmc3r-bench`); use a staging name to
  test a separate content item.
- `MCMC3R_APP_VISIBILITY` — defaults to `public`; other Connect Cloud values are
  accepted.

## Bundle contents

Included:

- `app.R`, `global.R`, `VERSION`, `.Rprofile`, `renv.lock`
- `R/`, `i18n/`, `www/` (including the bundled Noto Sans SC font)
- `LICENSE`, `NOTICE`, `CITATION.cff`, `THIRD_PARTY_LICENSES.md`

Excluded by the explicit file list in `dev/deploy.R`:

- `docs/`, `tests/`, `dev/`, `.github/`
- `.Rlib/`, `renv/` library, logs, screenshots, local fixtures

`.rscignore` documents the intended exclusions, but Connect Cloud deployments
should not rely on it: the explicit `appFiles` list is authoritative.

## Post-deployment smoke test

The v0.1.0 deployment was verified on 2026-10-24:

- Public URL returns HTTP 200 and the Shiny UI loads.
- Calibration default run produces `L(10, 0.1, 1, 0.025)` and result cards.
- Language switches to Chinese; theme switches to dark.
- MCMC Summary Carnivores example produces a table with `t_n20` and the other
  `t_` parameters.
- No console errors or visible error codes.

Repeat this checklist after each deployment:

- Open the public URL; cold start without a 5xx error.
- Calibration default run works; EN/ZH × light/dark all work.
- Upload the MCMC fixtures; summary table and CSV download work.
- Upload `ml_demo.zip`; estimate logML; download the bundle.
- Upload `unsafe.zip`; it is rejected with FILE-002.
- Chinese PNG/PDF exports have no missing glyphs.
- About shows v0.1.0, author, ORCID, upstream authors, SHA, and licence links.
- Mobile layout has no horizontal scroll; dark theme has no white blocks.
- Content logs contain no unexpected ERROR entries.

## CI workflow

`.github/workflows/deploy.yaml` is manual (`workflow_dispatch`) and uses the
`production` environment. It restores `renv`, installs `rsconnect`, and runs
`dev/deploy.R`. The script registers the service account from the three
`CONNECT_CLOUD_*` secrets, deploys, and reports the admin URL. The workflow
never runs on pull requests and never prints secrets. Third-party actions should
be pinned to commit SHAs.

## Rollback

1. Check out the previous stable tag.
2. `renv::restore()`.
3. Run `Rscript dev/deploy.R`.
4. Repeat the smoke test and record the reason in the release notes.

The content ID and public URL stay the same across redeployments. Connect Cloud
also keeps revision history, so the deployed source can be inspected or
downloaded from the content admin page.

## Troubleshooting

| Symptom | Cause | Action |
|---|---|---|
| `Download of the mcmc3r package has failed` | Installed `mcmc3r` lacks GitHub `RemoteSha` metadata | Reinstall from GitHub at the pinned commit, then redeploy |
| `dependency 'cpp11' is not available` / `websocket` fails | Test packages leaked into the manifest | Use `dev/deploy.R`, which filters to the runtime closure |
| Bundle is tens of MB | `.Rlib` or docs included | Pass the explicit runtime `appFiles` list |
| `Unsupported R version` | Platform does not support the lockfile R version | Check the build log and align `renv.lock` with a supported R |
| `PackageSourceError` | GitHub package metadata missing | Reinstall with `remotes::install_github` and check `RemoteSha` |
| `package 'mcmc3r' could not be loaded` | Dependency installation failed | Inspect the build log; restore `ape`, `corpcor`, `coda` |
| `cannot allocate vector` | Input too large | Lower limits; use the `lnL`-only optimisation |
| Chinese glyphs missing | Font not bundled or cairo unavailable | Keep `www/fonts`; check cairo |
| Dark theme flashes light | Inline theme script missing | Keep the `<head>` initialiser before CSS |
| Deployment asks for an account | No Connect Cloud account configured | Run `rsconnect::connectCloudUser()` or set client credentials |
| Content is not public | Plan or visibility setting | Set `appVisibility = "public"`; Free plan only supports public |
| App unavailable | Platform outage or usage limits | Check content logs and Admin → Usage; run locally |

## Monitoring

- Content admin page: live logs, revision history, usage, and compute settings.
- Admin → Usage and Admin → Metrics: credits, compute time, CPU/memory
  utilization, and connection counts.
- Structured logs: aggregate by `code=`.
- After release, check daily for seven days; review errors, cold start, memory,
  and usage credits.

## Migration note

The legacy shinyapps.io account may keep serving existing links until Posit’s
2027 migration waves, but this project now deploys only to Connect Cloud.
Do not configure old `RSCONNECT_USER`/`RSCONNECT_TOKEN`/`RSCONNECT_SECRET`
credentials; they target shinyapps.io, not Connect Cloud.
