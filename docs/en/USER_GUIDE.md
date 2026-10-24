# User guide

| Field | Value |
|---|---|
| lang | en |
| pair | ../zh/USER_GUIDE.md |
| applies_to | 0.1.0 |
| doc_version | 1.0 |
| last_reviewed | 2026-10-24 |
| canonical | true |
| status | current |

**Language:** English | [中文](../zh/USER_GUIDE.md)

## Interface overview

The header contains the brand, five page buttons, the language switch, and the
light/dark toggle. A public-data notice appears below the header. Each page has
a control panel on the left and a result area on the right. On narrow screens
the panels stack vertically and the run buttons remain at the bottom of the
control panel.

The footer shows the application version, the upstream package version, links
to the repository and documentation, and the licence/privacy entries.

## Calibration Explorer

### Purpose

Explore the calibration densities used by MCMCtree before writing a control
file. The page computes densities, cumulative probabilities, quantiles, and
MCMCtree syntax from the same parameters.

### Controls

- **Calibration type**: `L` (minimum), `B` (joint), `U` (maximum).
- **`tL`**: minimum age in Ma; required for L and B.
- **`tU`**: maximum age in Ma; required for B and U.
- **`p`, `c`**: mode and tail-decay parameters of the truncated Cauchy (L).
- **`pL`, `pU`**: lower and upper tail probabilities.
- **X-axis maximum**: blank means automatic (97.5% quantile of the current
  distribution, extended by 15%).
- **Sample points**: 100–5000.
- **Show**: density and/or cumulative probability.
- **Advanced → quantile probabilities**: comma-separated probabilities.

Press **Run** after changing parameters. The results are not recomputed until
you press Run; toggling the *Show* checkboxes redraws the existing curve.

### Results

- Density and optional CDF plot, drawn with base graphics and the selected
  theme.
- Quantile table for the probabilities you entered.
- MCMCtree syntax with a copy button.
- Plot data table (first 500 rows) and a CSV download with all points.
- Export controls for print or screen theme, 150/300 dpi PNG, and PDF.

### Notes

At `x = 0`, some truncated distributions have infinite density. These values
are clipped in the plot and left blank in the CSV; a CAL-011 warning explains
this. The automatic x maximum is based on the 97.5% quantile and is wide for
heavy-tailed L calibrations; enter a smaller value for a tighter plot.

## MCMC Summary

### Purpose

Summarise node ages from an `mcmc.txt` produced by MCMCtree or BPP.

### Loading data

- Upload a `.txt`, `.tsv`, or `.csv` file (maximum 50 MB).
- Choose **Auto-detect**, whitespace, tab, or comma as the separator.
- Or click one of the example buttons: *Microcebus* and *Hominids* are BPP
  examples with `tau_` columns; *Carnivores* is an MCMCtree example with `t_`
  columns.

Parsing happens immediately. The diagnostics card reports the row/column count
and file size. **Show column preview** controls the first 20 columns and 10 rows;
deselect it for very wide tables.

### Choosing time columns

- **Auto-detect** prefers `tau_` if present, then `t_`.
- Explicit `t_` or `tau_` choices use a strict prefix.
- **Custom prefix** matches literally; regular-expression characters are
  escaped.

Only columns whose names start with the prefix are summarised. Columns such as
`theta_` or `mu_t_` are ignored.

### Results

- Mean, median, 2.5% and 97.5% quantiles, and sample count per parameter.
- Diagnostics: rows read/used/removed, non-finite cells, number of time
  columns, file size, and separator.
- CSV download with stable English column names.

Rows with `NA`, `NaN`, or infinite values in any selected time column are
removed before summarising; a MCMC-008 warning reports how many. If all rows
are removed, MCMC-007 is raised.

### Notes

The upstream `mcmc.sum()` has three edge cases that the GUI handles explicitly:
single-column inputs (where `apply()` would fail), non-finite values (where the
median fails), and no time columns (where the upstream helper returns zero
rows). The GUI computes an equivalent summary directly and verifies it against
`mcmc3r::mcmc.sum` in the test suite.

## Marginal Likelihood

### Purpose

Estimate the log marginal likelihood of one or more power-posterior chains with
stepping stones or Gauss–Legendre quadrature.

### Method

- **Stepping stones**: `beta.txt` contains `0 ≤ beta < 1`, strictly increasing;
  zero is written as `1e-300`; the function appends 1 internally.
- **Gauss–Legendre**: `0 < beta < 1`, strictly increasing, and matching
  `make.beta(n, "gauss-quad")` within `1e-6`; `n` up to 100 in the GUI (hard
  upstream limit 256).

### Chain input

- **ZIP archive** (recommended): `beta.txt` plus folders `1/mcmc.txt` …
  `n/mcmc.txt`. One optional outer folder is allowed. The beta values come from
  the ZIP.
- **Individual files**: select one `mcmc.txt` per beta point. Upload `beta.txt`
  separately or generate beta values in the app. Files are ordered naturally by
  the first number in the file name.

Each chain must contain `lnL` with at least two finite values. Other columns are
ignored. The app writes an `lnL`-only file in an isolated run directory and
calls the upstream function with a temporary working directory.

### Results

- Summary metrics: logML, SE (with reliability status), number of beta points,
  method, model name, timestamp.
- Plot of mean logL against beta, with print/screen PNG (150/300 dpi) and PDF
  exports.
- Per-beta table with beta, mean logL, chain rows, and SE warning flag.
- Summary CSV, per-beta CSV, and a ZIP bundle containing both plus
  `metadata.json`.

The app reports beta=0 conversions, upstream warnings, and the pinned upstream
commit. If the standard error is flagged as unreliable, the result is still
shown but marked with a warning.

### Limits

Up to 50 beta points for stepping stones, 100 for Gauss–Legendre (with a hard
maximum of 256 in the upstream function), and 50 chain files. The total
uploaded size is 100 MB, a single file is 50 MB, and an uncompressed ZIP is
limited to 200 MB with at most 500 files and a 100:1 compression ratio.

## Help and About

The Help page contains the full user-facing reference: quick start, methods,
file formats, limits, error codes, privacy, citation, licence, and
troubleshooting. It is rendered from `i18n/help_en.md` or `help_zh.md` and
follows the interface language.

The About page lists the application version, build date, author, contact
email, ORCID, repository, upstream authors and pinned commit, licences,
citation, and disclaimer. It also links to `NOTICE`, `THIRD_PARTY_LICENSES.md`,
and `CITATION.cff`.

## Downloads

File names follow:

```
mcmc3r-bench_<module>_<YYYYMMDD-HHMMSS>_<lang>_<theme>.csv|png|pdf|zip
```

CSV files are UTF-8, comma separated, use stable English column names, and are
protected against spreadsheet formula injection. PNG and PDF exports default to
the print theme; choose *Match screen theme* to export the dark palette. The
marginal bundle records the app/upstream versions and screen/export theme in
`metadata.json` for reproducibility.

## Language, theme, and accessibility

- The language switch updates all static labels instantly without reloading or
  losing inputs. Results rendered on the server are refreshed after the client
  notifies the server of the new language.
- The theme switch updates CSS variables and re-renders plots and tables
  without recomputing upstream results.
- Preferences are stored separately. `?lang=` and `?theme=` override stored
  values on first load.
- The app supports keyboard navigation, visible focus, ARIA labels, live
  announcements for page changes and toasts, and a skip link.
- Charts are accompanied by data tables; colour is not the only carrier of
  information.

## Resetting and session lifetime

Each module has a **Reset** button that clears that module only. Uploaded files
and results are kept in a server-side temporary directory for the duration of
the session and deleted when the session ends. Nothing is written to a
database.
