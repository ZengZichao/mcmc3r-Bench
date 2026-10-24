# Architecture

| Field | Value |
|---|---|
| lang | en |
| pair | ../zh/ARCHITECTURE.md |
| applies_to | 0.1.0 |
| doc_version | 1.0 |
| last_reviewed | 2026-10-24 |
| canonical | true |
| status | current |

**Language:** English | [中文](../zh/ARCHITECTURE.md)

## Overview

```
UI (Shiny modules + bslib)
  mod_calibration / mod_mcmc_summary / mod_marginal / mod_help / mod_about
        │  calls only service functions
Service layer
  services_calibration / services_mcmc / services_marginal / services_export
        │  validates, isolates the working directory, calls exported API
Upstream layer
  mcmc3r (pinned SHA) + ape + corpcor + coda
Cross-cutting: i18n, theme, error catalogue, logging, file safety, plots,
session temp directories, version metadata, bilingual documentation.
```

## Loading order

`app.R` initialises the app directory, request-size options, the i18n table, and
the bundled font. `global.R` performs the same initialisation for environments
that source it first. Shiny may source `R/` files more than once; state that
must survive re-sourcing is stored in R options (i18n table and font flags) or
in environments that are only created if absent.

`R/app_ui.R` builds the complete page once. Navigation is client-side: all page
sections exist in the DOM and are shown or hidden. This preserves input values
and uploaded data when switching pages or languages. Server-side outputs render
only when their page is active, which avoids zero-width plot devices.

## Layers and rules

- UI modules never call `mcmc3r::` directly.
- Service functions never touch `input`, `output`, or `session`.
- Every upstream call is wrapped in `withr::with_dir()`.
- Every file write goes to a session temporary directory.
- Every user-visible string goes through `tr()` or carries a `data-i18n` key.
- Every colour comes from a theme token; modules do not hard-code light values.
- Every error is an `app_error` with a stable code, a message key, and a hint key.

## State

`app_server` owns:

- `lang`: `reactiveVal`, initialised from the URL query and updated by the
  client.
- `theme`: `reactiveVal`, initialised from the URL query and updated by the
  client after reading `localStorage` and the system preference.
- `active_tab`: `reactiveVal`, updated by the navigation buttons.
- `session_dir`: a unique temporary directory created at session start.

Module servers own their own `reactiveValues` for uploaded data, parameters,
results, and errors. They never share mutable state across sessions.

## Temporary directory layout

```
tempdir()/mcmc3r-bench/<session-token>/
├── uploads/                 # sanitised copies of uploaded files
├── runs/
│   └── run-<timestamp>-<random>/
│       ├── beta.txt
│       ├── 1/mcmc.txt
│       └── ...
└── exports/                 # temporary download bundles
```

`session$onSessionEnded()` deletes the whole session directory. Uploaded files
are copied with `basename()` and a safe replacement of special characters. ZIP
members are never extracted by their archive path; selected entries are streamed
into sanitised destinations.

## Data flow

### Calibration

```
inputs → cal_validate() → x grid → mcmc3r::dL/dB/dU and pL/pB/pU
       → data.frame(x, density, cdf) → plot / tables / CSV / PNG / PDF
```

Quantiles use `qL/qB/qU` with `tryCatch`; failures map to CAL-010. Non-finite
boundary values are replaced with `NA` and reported as CAL-011.

### MCMC summary

```
upload → data.table::fread → strict prefix selection → numeric coercion
       → drop non-finite rows → mean/median/quantiles → table / CSV
```

The upstream `mcmc.sum()` is not called because it fails on single-column and
non-finite inputs; the equivalent summary is implemented explicitly and tested
against the upstream function.

### Marginal likelihood

```
ZIP / files → ZIP validation → beta validation → run directory
            → lnL-only chain files → withr::with_dir(upstream call)
            → logML/SE/mean.logl → plot / tables / CSV / ZIP bundle
```

For a ZIP, beta values are read from the archive. For individual files, beta
values come from an uploaded file or from `make.beta()`. The run directory is
unique per request.

## Errors and logging

`app_error` carries `type`, `code`, `message_key`, `hint_key`, `detail`, and
`context`. The UI shows a bilingual message, a hint, and a collapsed technical
detail. Diagnostics contain versions and structural counts but no file contents
or full paths. Logs are structured key=value lines at INFO/WARN/ERROR; uploaded
file names and values are not logged.

## Limits

| Resource | Limit |
|---|---|
| Single upload | 50 MB |
| Total request | 100 MB |
| ZIP uncompressed | 200 MB |
| ZIP files | 500 |
| ZIP ratio | 100:1 |
| MCMC rows | 500,000 |
| Calibration points | 5,000 |
| Beta points (stepping stones) | 50 |
| Beta points (Gauss–Legendre) | 100 (hard 256) |
| Chains | 50 |

`options(shiny.maxRequestSize = LIMITS$upload_total_mb * 1024^2)` is the
transport limit; business validation runs per file.

## Configuration

| Variable | Purpose | Default |
|---|---|---|
| `MCMC3R_APP_VERSION` | Override the displayed version (CI checks) | `VERSION` |
| `MCMC3R_LOG_LEVEL` | Logger threshold | `INFO` |
| `MCMC3R_MAX_UPLOAD_MB` | Per-file upload limit in MB (1–500) | `50` |
| `MCMC3R_DEFAULT_THEME` | Self-hosted default theme (`light`, `dark`, `auto`) | `auto` |
| `MCMC3R_APP_DIR` | App root for scripts and tests | current directory |
| `CONNECT_CLOUD_CLIENT_ID` / `CONNECT_CLOUD_CLIENT_SECRET` / `CONNECT_CLOUD_ACCOUNT` | CI deployment authentication | unset |
| `MCMC3R_ENABLE_MORPHO` | Reserved for the 0.3.0 morphology module | `false` |

Secrets are never read by the running application and never logged.

## Concurrency

Connect Cloud runs each application on one instance; CPU and memory depend on the
plan. All calculations are synchronous, the Run button is disabled while a
calculation is in progress (Shiny prevents duplicate events), and long tasks are
bounded by the input limits. No background queue, database, or cross-session
cache is used.

## Caching

v0.1.0 does not cache calibration results or user data. Plot and table outputs
are re-rendered from in-memory results when the theme or language changes.
Caching may be added only for pure calibration data, with the theme in the key.

## Deployment shape

The app is a standard Shiny application (no `DESCRIPTION`, no package build).
`renv.lock` records CRAN packages and the pinned GitHub upstream. The deployment
script passes an explicit runtime file list and filters the generated manifest
to the runtime dependency closure, so documentation, tests, development scripts,
and the local library are not uploaded.
