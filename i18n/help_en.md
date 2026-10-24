## Help and documentation

mcmc3r Bench is an independent, unofficial GUI for the **mcmc3r** R package. It wraps three workflows: calibration-density exploration, MCMC output summaries, and marginal-likelihood estimation. Calculations are performed by `mcmc3r` on the server; the GUI adds validation, bilingual text, themes, and reproducible exports.

## Quick start

1. Choose a module in the top navigation.
2. Provide parameters or upload a file. Example data are available for each data module.
3. Press **Run**, inspect the result, then download CSV, PNG, PDF, or a ZIP bundle.

The app is public and hosted on Posit Connect Cloud. The Free plan serves public content with a 1 GiB bundle limit; compute and usage limits follow the account plan, and usage credits are currently reported but not enforced. The app may cold-start slowly after a period of inactivity. Do not upload confidential, personal, or regulated data; run the source code locally for sensitive work.

## Calibration Explorer

The Calibration Explorer evaluates the calibration densities used by MCMCtree:

- **L (minimum bound)**: a truncated Cauchy distribution above `tL`.
- **B (joint bounds)**: lower and upper soft bounds between `tL` and `tU`.
- **U (maximum bound)**: a soft upper bound at `tU`.

Parameters:

| Parameter | Meaning | Range |
|---|---|---|
| `tL` | Minimum age (Ma) | > 0 |
| `tU` | Maximum age (Ma), B only | > `tL` |
| `p` | Mode parameter of the truncated Cauchy | ≥ 0 |
| `c` | Tail decay of the truncated Cauchy | > 0 |
| `pL` | Lower-tail probability mass | 0 < `pL` < 1 |
| `pU` | Upper-tail probability mass, B and U | 0 < `pU` < 1, `pL + pU` < 1 |
| x-axis maximum | Plot window (Ma) | blank = automatic (97.5% quantile, extended by 15%) |
| Sample points | Curve resolution | 100–5000 |
| Quantile probabilities | Probabilities shown in the table | 0.001–0.999 |

The density and CDF are computed with `mcmc3r::dL`, `dB`, `dU`, `pL`, `pB`, and `pU`. Quantiles use `qL`, `qB`, and `qU`. At `x = 0`, a truncated distribution can have infinite density when its shape parameter is below 1; such values are clipped in the plot and left blank in the CSV. The MCMCtree syntax is produced with the same numbers shown in the form, for example `L(10, 0.1, 1, 0.025)`.

## MCMC Summary

Upload an `mcmc.txt` file produced by MCMCtree or BPP. The separator is auto-detected by default; choose whitespace, tab, or comma if a file is parsed incorrectly. The column preview can be hidden for wide tables. The app detects time columns with a strict prefix:

- MCMCtree: `t_`
- BPP: `tau_`

Only columns whose names start with the prefix are summarised. This avoids accidental matches such as `theta_` or `mu_t_`. Rows containing `NA`, `NaN`, or infinite values in any selected time column are removed and reported. The summary reports the mean, median, 2.5% and 97.5% quantiles, and the number of samples for each parameter.

The calculation is equivalent to `mcmc3r::mcmc.sum` for multi-column inputs, but it also handles the single-column, missing-value, and no-time-column cases that make the upstream helper fail or return an empty table. Parameter names are kept exactly as they appear in the file.

## Marginal Likelihood

Two methods are available:

- **Stepping stones** (`stepping.stones`): beta values must satisfy `0 ≤ beta < 1`, be strictly increasing, and exclude 1. A beta value of 0 is written as `1e-300`, matching the upstream `make.bfctlf` convention. The value 1 is appended internally by the function.
- **Gauss–Legendre quadrature** (`gauss.quad`): beta values must satisfy `0 < beta < 1`, be strictly increasing, and match `make.beta(n, "gauss-quad")` within `1e-6`.

Two input layouts are supported:

- **ZIP archive** (recommended): `beta.txt` at the root plus numbered folders `1/mcmc.txt` … `n/mcmc.txt`. One optional outer folder is allowed, for example `demo/beta.txt` and `demo/1/mcmc.txt`.
- **Individual files**: select the chain files and, unless you use generated beta values, upload `beta.txt` separately. Chain files are ordered naturally by the first number in their file name.

Every chain file must contain an `lnL` column with at least two finite values. The GUI writes a single `lnL` column to an isolated run directory and calls the upstream function inside `withr::with_dir()`. The upstream functions use relative paths, so this isolation is required for correctness in a shared Shiny process. The reported log marginal likelihood and standard error come directly from `mcmc3r`.

If the upstream approximation flags `var(r_k)/r_k² > 0.1`, the SE is marked as unreliable. This is a warning, not a failure. Consider longer chains or a different beta schedule.

## File formats

### mcmc.txt

The first line is a header. Whitespace, tab, or comma separators are accepted. At least two data rows are required. Extra columns are allowed. UTF-8 or ASCII is expected.

```
Iteration   lnL        t_1       t_2
1           -12345.6   10.20     5.10
2           -12344.9   10.31     5.05
```

BPP output typically uses `tau_` instead of `t_`, and may not have an iteration column.

### beta.txt

One numeric value per line, no header, strictly increasing, no value equal to 1.

```
0.0000
0.0625
0.2500
0.5625
```

### Chain ZIP

```
demo/
├── beta.txt
├── 1/mcmc.txt
├── 2/mcmc.txt
├── 3/mcmc.txt
└── 4/mcmc.txt
```

Absolute paths, `..` components, encrypted archives, excessive file counts, and unusual compression ratios are rejected. Entries are never extracted by their archive path; only whitelisted members are copied to sanitised destinations.

## Limits

| Resource | Limit |
|---|---|
| Single upload | 50 MB |
| Total request | 100 MB |
| ZIP uncompressed size | 200 MB |
| ZIP file count | 500 |
| ZIP compression ratio | 100:1 |
| MCMC rows | 500,000 |
| Calibration points | 5,000 |
| Beta points (stepping stones) | 50 |
| Beta points (Gauss–Legendre) | 100 (hard maximum 256) |
| Chain files | 50 |

These limits protect the single free-plan worker. Split large jobs into smaller runs.

## Error codes

Errors and warnings use stable codes. Every code has a bilingual message and a suggested action.

| Code | Meaning | What to do |
|---|---|---|
| CAL-001 | `tL ≤ 0` | Enter a positive minimum age |
| CAL-002 | `c ≤ 0` | Enter a positive tail decay |
| CAL-003 | `p < 0` | Enter a non-negative mode parameter |
| CAL-004 | `pL` outside (0,1) | Use a probability such as 0.025 |
| CAL-005 | `tU ≤ tL` | Increase `tU` or decrease `tL` |
| CAL-006 | `pU` invalid or `pL + pU ≥ 1` | Keep both tail probabilities valid and their sum below 1 |
| CAL-007 | Quantile probability too extreme | Use probabilities between 0.001 and 0.999 |
| CAL-008 | Invalid x-axis maximum | Enter a positive number or leave blank |
| CAL-009 | Sample points outside 100–5000 | Adjust the slider |
| CAL-010 | Numerical quantile solving failed | Adjust parameters or probabilities |
| CAL-011 | Infinite density/CDF at a boundary | Expected in some cases; values are clipped/blank |
| CAL-012 | Neither density nor CDF selected | Tick at least one |
| MCMC-001 | File cannot be parsed | Check delimiter and header |
| MCMC-002 | Empty file or header only | Provide at least two rows |
| MCMC-003 | No time columns | Use `t_`/`tau_` or a custom prefix |
| MCMC-004 | Time column non-numeric | Clean the data |
| MCMC-005 | File too large or too many rows | Thin or split the file |
| MCMC-006 | Duplicate column names | Make the header unique |
| MCMC-007 | Too many non-finite values | Check the chain |
| MCMC-008 | Rows with NA/NaN/Inf removed | Informational warning |
| ML-001 | beta.txt is not numeric | Provide one value per line |
| ML-002 | beta out of range or contains 1 | Follow the method-specific range |
| ML-003 | beta not strictly increasing | Sort or regenerate |
| ML-004 | beta count ≠ chain count | Align files and beta |
| ML-005 | Missing `lnL` column | Use MCMCtree/BPP output |
| ML-006 | `lnL` contains non-finite values | Check the chain |
| ML-007 | Chain has fewer than two samples | Provide a non-empty chain |
| ML-008 | Gauss–Legendre n > 256 | Reduce beta points |
| ML-009 | beta does not match the Gauss–Legendre rule | Use `make.beta` |
| ML-010 | Upstream calculation failed | Check details and report the code |
| ML-011 | Beta point count or parameter outside the supported range | Reduce points / use a positive exponent |
| FILE-001 | File or archive too large | Reduce the input |
| FILE-002 | Unsafe or incomplete ZIP | Repackage as specified |
| FILE-003 | Unsupported extension | Use `.txt`, `.tsv`, `.csv`, or `.zip` |
| FILE-004 | Too many ZIP files or unusual compression ratio | Repackage with only required files |
| SYS-001 | Unexpected error | Copy diagnostics and open an issue |
| SYS-002 | Memory or resources exhausted | Reduce the input |
| SYS-003 | Calculation timeout | Split the task |

Copy diagnostics contains the code, module, a short message, technical detail, app version, and upstream commit. It never contains file contents or full paths.

## Privacy

Files are processed only within the current session. They are copied to a temporary directory on the server, used for validation and calculation, and deleted when the session ends. The app does not create accounts, does not retain results, does not use third-party analytics, and does not sell data. The hosting provider may record standard access logs such as IP address, timestamp, and errors.

The hosted app is public. Anyone with the link can use it. Do not upload confidential, personal, or regulated data. For sensitive work, install the source locally and run `shiny::runApp()`.

## Citation and attribution

If you use results in a publication, cite the underlying methods and the `mcmc3r` package; cite this GUI only as software.

- Zeng Z. (2026). *mcmc3r Bench* (Version 0.1.0) [Computer software]. https://github.com/ZengZichao/mcmc3r-Bench
- dos Reis M, Alvarez-Carretero S. (2025). *mcmc3r: Tools to work with MCMCtree and BPP* (Version 0.6.0) [Computer software]. https://github.com/dosreislab/mcmc3r

Method references depend on the workflow:

- Calibration densities: Yang & Rannala (2006), *Mol. Biol. Evol.* 23: 212–226, DOI 10.1093/molbev/msj024; Inoue, Donoghue & Yang (2010), *Syst. Biol.* 59: 74–89, DOI 10.1093/sysbio/syp078.
- Stepping stones: dos Reis et al. (2018), *Syst. Biol.* 67: 594–615, DOI 10.1093/sysbio/syy001.
- Gauss–Legendre: Rannala & Yang (2017), *Syst. Biol.* 66: 823–842, DOI 10.1093/sysbio/syw119.

`mcmc3r` is MIT licensed, Copyright 2017 Mario dos Reis. This GUI is an independent, unofficial project by Zeng Zichao (曾子超). It is not affiliated with or endorsed by the `mcmc3r` authors, MCMCtree, or BPP. The upstream authors did not participate in the design, implementation, or deployment of this GUI.

## Licence and third-party notices

- Application code: MIT (see `LICENSE`).
- Original documentation: CC BY 4.0 (see `docs/LICENSE`).
- Upstream `mcmc3r` code and documentation: MIT, Copyright 2017 Mario dos Reis.
- Bundled Noto Sans SC font: SIL Open Font License 1.1 (see `www/fonts/OFL.txt`).

See `NOTICE` and `THIRD_PARTY_LICENSES.md` for the complete notices.

## Language, theme, and accessibility

- Use **EN / 中文** in the header to switch language. The choice is saved in `localStorage`; `?lang=zh` or `?lang=en` overrides it.
- Use the sun/moon button to switch light/dark theme. The first visit follows the system preference; later visits use the saved choice; `?theme=dark` or `?theme=light` overrides it.
- Language and theme are independent. Switching one does not change the other.
- Plots and tables are redrawn in the selected theme. Exports default to the print (light) theme; choose “Match screen theme” to export the dark palette.
- The app supports keyboard navigation, visible focus, ARIA labels, status announcements, and a skip link. Charts are accompanied by data tables. Colour is never the only carrier of information.

## Troubleshooting

- **The app is slow or unavailable**: Connect Cloud runs the app on a single instance, so the first request after a period of inactivity may cold-start. Compute and usage limits follow the account plan. Try again later or run locally.
- **A Chinese export shows empty boxes**: the bundled font is loaded at startup; if a custom deployment removes `www/fonts`, reinstall the font and restart.
- **The ZIP is rejected**: check for `beta.txt`, contiguous numbered folders, `mcmc.txt` in each folder, and no absolute or `..` paths.
- **The result differs from a direct R call**: confirm that the beta values and chain order match, and that `lnL` is the only column used by the marginal-likelihood functions.
- **The SE is marked unreliable**: the upstream delta approximation flagged a large variance ratio. Use longer chains or more beta points.
