# File formats

| Field | Value |
|---|---|
| lang | en |
| pair | ../zh/FILE_FORMATS.md |
| applies_to | 0.1.0 |
| doc_version | 1.0 |
| last_reviewed | 2026-10-24 |
| canonical | true |
| status | current |

**Language:** English | [中文](../zh/FILE_FORMATS.md)

## mcmc.txt

### Requirements

- First line is a header.
- Whitespace, tab, or comma separators.
- At least two data rows.
- UTF-8 or ASCII; GBK is not supported and should be converted to UTF-8.
- Numeric columns contain no units.

MCMC Summary requires at least one time column (`t_` for MCMCtree, `tau_` for
BPP). Marginal Likelihood requires an `lnL` column and ignores other columns.
Extra columns such as `mu`, `sigma2`, or `r_g1_*` are allowed.

### Example: MCMCtree

```
Iteration   lnL        t_1       t_2       t_3
1           -12345.67  10.20     5.10      2.30
2           -12344.91  10.31     5.05      2.28
3           -12346.02  10.25     5.12      2.31
```

### Example: BPP

```
tau_1   tau_2   tau_3   lnL
10.20   5.10    2.30    -12345.67
10.31   5.05    2.28    -12344.91
10.25   5.12    2.31    -12346.02
```

### Edge cases

- A single time column is accepted.
- Rows with `NA`, `NaN`, `Inf`, or `-Inf` in any selected time column are
  removed and reported (MCMC-008).
- Duplicate column names are rejected (MCMC-006).
- A file with no time columns is rejected (MCMC-003), even if it has `lnL`.
- A file with only a header is rejected (MCMC-002).

## beta.txt

### Requirements

- One numeric beta per line, no header.
- Strictly increasing.
- Stepping stones: `0 ≤ beta < 1`. A zero is converted to `1e-300` when the
  temporary file is written. The value 1 is appended internally and must not be
  present.
- Gauss–Legendre: `0 < beta < 1`, and the values must match
  `make.beta(n, "gauss-quad")` within `1e-6`.

### Example

```
0.0000
0.0625
0.2500
0.5625
```

## Marginal-likelihood ZIP

### Structure

```
demo/
├── beta.txt
├── 1/mcmc.txt
├── 2/mcmc.txt
├── 3/mcmc.txt
└── 4/mcmc.txt
```

- `beta.txt` and the numbered folders may be at the archive root, or inside one
  optional outer folder.
- Folder names must be contiguous integers starting at 1.
- Each folder must contain `mcmc.txt` with an `lnL` column.
- Unrelated files are ignored but count toward the file limit.
- The number of beta values must equal the number of folders.

### Rejected archives

- Absolute paths, `..` components, or backslash separators.
- Encrypted archives.
- More than 500 files.
- Uncompressed size above 200 MB.
- Compression ratio above 100:1.

The application does not extract entries by their archive path. It validates the
entry list, copies only whitelisted members to sanitised destinations, and
never writes outside the session directory.

## Individual chain files

Select one `mcmc.txt` per beta point. Files are sorted by the first number in
the file name; for names without numbers, lexicographic order is used. Upload
`beta.txt` separately or generate beta values in the app. The count must match
the number of files.

## Newick trees (planned for v0.2.0)

Newick trees will be used by the densitree and multiPhylo modules. They must be
rooted and strictly bifurcating, and tip labels must match the names used by
the MCMC output. NEXUS is not supported.

## Output CSV

### Calibration

```
x,density,cdf
0.000000,NA,0.000000
0.973709,0.000123,0.025000
...
```

### MCMC summary

```
parameter,mean,median,ci025,ci975,n
t_1,10.25,10.24,9.80,10.70,8000
t_2,5.10,5.09,4.85,5.35,8000
```

### Marginal likelihood summary

```
model,method,logml,se,n_beta,se_reliable,beta_zero_converted,computed_at,app_version,upstream_version,upstream_sha
demo,step-stones,-1278.699,0.769756,5,FALSE,1,...
```

### CSV rules

- UTF-8, comma separated, header row.
- No thousands separators; missing values are empty strings.
- Stable English column names.
- User-provided strings are escaped against formula injection by prefixing a
  single quote when they start with `=`, `+`, `-`, or `@`.
- Metadata columns or a `metadata.json` companion record versions and themes.

## Size limits

| Item | Limit |
|---|---|
| Single upload | 50 MB |
| Total request | 100 MB |
| ZIP uncompressed | 200 MB |
| ZIP files | 500 |
| ZIP ratio | 100:1 |
| MCMC rows | 500,000 |
| Chain files | 50 |
| Beta points (stepping stones) | 50 |
| Beta points (Gauss–Legendre) | 100 (hard maximum 256) |
