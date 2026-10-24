# Quick start

| Field | Value |
|---|---|
| lang | en |
| pair | ../zh/QUICKSTART.md |
| applies_to | 0.1.0 |
| doc_version | 1.0 |
| last_reviewed | 2026-10-24 |
| canonical | true |
| status | current |

**Language:** English | [中文](../zh/QUICKSTART.md)

## Use the hosted app

1. Open the Connect Cloud URL:
   <https://zengzichao-mcmc3r-bench.share.connect.posit.cloud/>
2. Choose **Calibration Explorer**, **MCMC Summary**, or **Marginal Likelihood**.
3. Enter parameters, upload a file, or load an example.
4. Press **Run** / **Summarise** / **Estimate**.
5. Inspect the table and plot, then download CSV, PNG, PDF, or a ZIP bundle.

The hosted app is public on the Connect Cloud Free plan. Compute and usage
limits follow the account plan (see <https://connect.posit.cloud/plans>); if
the app is unavailable, run locally. Do not upload confidential, personal, or
regulated data.

## Run locally

Requirements: R 4.6.1, a working C/C++ toolchain, and network access to CRAN.
The upstream `mcmc3r` package is installed from GitHub at the commit pinned in
`R/app_meta.R`.

```bash
cd mcmc3r-Bench
Rscript -e 'renv::restore()'
Rscript -e 'shiny::runApp(".")'
```

If `renv.lock` cannot reach GitHub, install the local upstream snapshot once:

```bash
R CMD INSTALL --library=.Rlib ../mcmc3r-原始代码
Rscript -e '.libPaths(c(".Rlib", .libPaths())); shiny::runApp(".")'
```

The project `.Rprofile` adds `.Rlib` automatically when it exists.

## First tasks

- Calibration: keep the defaults (`L`, `tL = 10`, `p = 0.1`, `c = 1`,
  `pL = 0.025`) and press **Run** to see a density, quantiles, and the syntax
  `L(10, 0.1, 1, 0.025)`.
- MCMC Summary: click **Carnivores (MCMCtree, t_)**, then **Summarise**.
- Marginal Likelihood: click **Load synthetic demo**, then **Estimate**.

## Language and theme

Use **EN / 中文** and the sun/moon button in the header. Both preferences are
remembered in `localStorage`. URL parameters `?lang=zh` and `?theme=dark`
override stored values. Exports default to the print (light) theme.

## Where to go next

- [User guide](USER_GUIDE.md)
- [File formats](FILE_FORMATS.md)
- [Methods and citation](METHODS.md)
- [FAQ](FAQ.md)
- [Privacy](PRIVACY.md)
