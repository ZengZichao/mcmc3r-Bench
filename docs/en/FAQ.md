# FAQ and troubleshooting

| Field | Value |
|---|---|
| lang | en |
| pair | ../zh/FAQ.md |
| applies_to | 0.1.0 |
| doc_version | 1.0 |
| last_reviewed | 2026-10-24 |
| canonical | true |
| status | current |

**Language:** English | [中文](../zh/FAQ.md)

## Is this an official mcmc3r application?

No. It is an independent, unofficial GUI by Zeng Zichao (曾子超). The upstream
authors did not participate in its design, implementation, or deployment, and
they do not endorse it. See [ATTRIBUTION.md](ATTRIBUTION.md).

## Does the app replace MCMCtree or BPP?

No. It does not run MCMCtree or BPP, does not execute arbitrary R code, and does
not perform Bayesian sampling. It prepares inputs, summarises existing output,
and estimates marginal likelihoods from existing power-posterior chains.

## Why is the app slow or unavailable?

The hosted instance runs on Posit Connect Cloud. The Free plan serves public
content with a 1 GiB bundle limit; compute and usage limits follow the account
plan. Usage credits are currently reported but not enforced, and platform
maintenance or an account limit can still make the app temporarily unavailable.
Check <https://connect.posit.cloud/plans>, or run locally for unlimited use.

## Is my data stored?

No. Files are copied to a temporary directory on the server for the current
session and deleted when the session ends. There is no account system, database,
or cross-session cache. The hosting provider may keep standard access logs. See
[PRIVACY.md](PRIVACY.md).

## Why was my file rejected?

Common causes:

- The file has only a header (MCMC-002).
- No `t_` or `tau_` column was found (MCMC-003).
- A time column contains text (MCMC-004).
- A column name is duplicated (MCMC-006).
- The file or row count exceeds a limit (MCMC-005).
- The ZIP has no `beta.txt`, non-contiguous numbered folders, or an unsafe path
  (FILE-002).
- The beta count does not match the chain count (ML-004).
- A chain lacks `lnL` (ML-005) or has non-finite values (ML-006).

The error panel shows the code, a bilingual explanation, and a suggested action.
Use **Copy diagnostics** when reporting an issue.

## Why is the x-axis on the calibration plot so wide?

The L calibration has a heavy Cauchy tail. The automatic maximum uses the 97.5%
quantile times 1.15. Enter a smaller *X-axis maximum* to zoom into the region of
interest; the density and quantiles are unchanged.

## Why does the CSV show blank density values?

At `x = 0`, some truncated distributions have infinite density. Those values
are represented as `NA` and written as empty strings. A CAL-011 warning explains
the clipping.

## Why does the SE say “unreliable”?

The upstream delta approximation flags `var(r_k)/r_k^2 > 0.1` for at least one
beta. This usually means the chains are short or the beta schedule is poor.
Use longer chains, more samples, or different beta values. The logML is still
reported.

## Why is Gauss–Legendre beta rejected?

The values must match `make.beta(n, "gauss-quad")` within `1e-6` and satisfy
`0 < beta < 1`. Generate them with `make.beta` and upload the exact values. The
GUI caps `n` at 100 to keep the free instance responsive; the upstream hard
limit is 256.

## Why do Chinese characters appear as boxes in exported plots?

The app bundles Noto Sans SC and registers it at startup. If you deploy a copy,
keep `www/fonts/NotoSansSC-Regular.ttf` and `www/fonts/OFL.txt`. On Linux, ensure
cairo support is available. The test suite and the release checklist include a
Chinese PNG/PDF check.

## Does switching language reset my inputs?

No for static labels and existing results. The language switch updates the
interface without reloading. Server-rendered tables and help text refresh after
the client notifies the server. Uploaded files remain in the session; a file
input cannot be repopulated by the browser, but the parsed data remain usable.

## Does switching theme recompute results?

No. Theme changes only affect colours and redraw plots/tables. Exports are
generated from the current result object and never recompute upstream code.

## Can I use the app offline?

The hosted app requires network access. The repository can be run locally with
R and `renv`; the upstream package and dependencies must be installed once. See
[QUICKSTART.md](QUICKSTART.md).

## How should I cite results?

Cite the underlying method paper(s), the `mcmc3r` package, and optionally the
GUI software entry. Do not cite the GUI as a methodological contribution. See
[CITATION.md](CITATION.md).

## How do I report a bug?

Open an issue at https://github.com/ZengZichao/mcmc3r-Bench/issues with the app
version, module, error code, language/theme, and the copied diagnostics. Do not
attach confidential data. Reduce the input to a minimal example if possible.

## Why does the app look different from the screenshots?

Screenshots are regenerated for each release from the running app. If the
layout differs, clear the browser cache or check that the deployment matches the
tagged version. Report persistent visual regressions with the browser name and
version.
