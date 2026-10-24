# Methods and references

| Field | Value |
|---|---|
| lang | en |
| pair | ../zh/METHODS.md |
| applies_to | 0.1.0 |
| doc_version | 1.0 |
| last_reviewed | 2026-10-24 |
| canonical | true |
| status | current |

**Language:** English | [中文](../zh/METHODS.md)

This document describes the methods behind the three modules and the references
to cite. The GUI implements no new statistical method: all calculations are
performed by the upstream `mcmc3r` package.

## Calibration densities

### Minimum bound (L)

The L calibration is a truncated Cauchy distribution above `tL` (Inoue,
Donoghue & Yang 2010). It combines a power-law density below `tL` with a
right-shifted Cauchy tail above `tL`. The parameters are `p` (mode), `c` (tail
scale), and `pL` (lower-tail probability). The density is implemented in
`mcmc3r::dL`, the CDF in `pL`, and the quantile function in `qL`.

### Joint bounds (B)

The B calibration places soft lower and upper bounds at `tL` and `tU` (Yang &
Rannala 2006). A power-law tail enters at `tL`, a uniform density spans the
interval, and an exponential tail leaves `tU`. The tail masses are `pL` and
`pU`; `pL + pU` must be below 1. Implemented in `dB`, `pB`, `qB`.

### Maximum bound (U)

The U calibration is the limiting case of B with `tL = 0` and `pL = 0`: a
uniform density below `tU` and an exponential tail above it. Implemented in
`dU`, `pU`, `qU`.

### Numerical notes

- At `x = 0`, the power-law term can be infinite when the shape parameter is
  below 1. The GUI replaces non-finite values with `NA`, clips them in the plot,
  and leaves them blank in the CSV (CAL-011).
- Quantiles use `uniroot` upstream. Extreme parameters can fail; the GUI maps
  failures to CAL-010 and suggests adjusting the parameters.
- The automatic x maximum uses the 97.5% quantile multiplied by 1.15, with a
  minimum of 1.25 times `tL` or `tU`.

## MCMC summary

The GUI selects time columns using a strict prefix (`^t_` or `^tau_`), converts
them to numeric, removes rows with non-finite values, and computes the mean,
median, 2.5% and 97.5% quantiles for each column. This is equivalent to
`mcmc3r::mcmc.sum` for multi-column inputs. The implementation differs from the
upstream helper in three edge cases:

1. Single-column input: upstream `apply()` drops to a vector; the GUI summarises
   the column without dropping dimensions.
2. Non-finite values: upstream `median()` fails without `na.rm`; the GUI removes
   the affected rows and reports how many.
3. No time columns: upstream returns a zero-row data frame; the GUI raises
   MCMC-003.

The test suite compares the GUI summary with `mcmc3r::mcmc.sum` on the packaged
data and requires a tolerance of `1e-12`.

## Marginal likelihood

### Stepping stones

For `n` power-posterior chains sampled at beta values `b_1 < … < b_n` with
`b_n < 1`, stepping stones estimates

```
log Z ≈ Σ_k (b_{k+1} - b_k) log( mean( exp( (b_{k+1}-b_k) logL_k ) ) )
```

with `b_{n+1} = 1` appended internally. The standard error uses the delta
approximation of Xie et al. (2011), and the upstream function warns when
`var(r_k) / r_k^2 > 0.1`. See dos Reis et al. (2018).

### Gauss–Legendre quadrature

Thermodynamic integration with an `n`-point Gauss–Legendre rule estimates

```
log Z ≈ Σ_k w_k / 2 · mean(logL at beta_k)
```

where `(beta_k, w_k)` are the nodes and weights of the rule. See Rannala & Yang
(2017). The GUI checks that user-supplied beta values match
`make.beta(n, "gauss-quad")` within `1e-6`.

### Input handling

The upstream functions read `1/mcmc.txt` … `n/mcmc.txt` relative to the current
working directory. In a Shiny process the working directory is shared, so the
GUI:

1. Creates an isolated run directory under the session temporary directory.
2. Writes one `lnL`-only `mcmc.txt` per chain.
3. Calls the upstream function inside `withr::with_dir()`.
4. Never calls `setwd()` globally.

The GUI also validates beta ranges, strict monotonicity, counts, `lnL`
finiteness, and chain lengths before invoking the upstream code.

## What not to cite

The GUI is software infrastructure. It does not introduce calibration
distributions, stepping stones, Gauss–Legendre integration, or summary
statistics. Do not describe it as a methodological contribution. Cite the
underlying papers and the `mcmc3r` package when reporting results.

## References

- Yang Z, Rannala B. (2006). Bayesian estimation of species divergence times
  under a molecular clock using multiple fossil calibrations with soft bounds.
  *Molecular Biology and Evolution* 23: 212–226.
  DOI: 10.1093/molbev/msj024.
- Inoue J, Donoghue PCJ, Yang Z. (2010). The impact of the representation of
  fossil calibrations on Bayesian estimation of species divergence times.
  *Systematic Biology* 59: 74–89. DOI: 10.1093/sysbio/syp078.
- dos Reis M, Gunnarsson A, Thawornwattana Y, Angelis K, Tiley GP,
  Donoghue PCJ, Yang Z. (2018). Using phylogenomic data to explore the effects
  of relaxed clocks and calibration strategies on divergence time estimation:
  primates as a test case. *Systematic Biology* 67: 594–615.
  DOI: 10.1093/sysbio/syy001.
- Rannala B, Yang Z. (2017). Efficient Bayesian species tree inference under
  the multispecies coalescent. *Systematic Biology* 66: 823–842.
  DOI: 10.1093/sysbio/syw119.
- Xie W, Lewis PO, Fan Y, Kuo L, Chen MH. (2011). Improving marginal likelihood
  estimation for Bayesian phylogenetic model selection. *Systematic Biology*
  60: 150–160.
- dos Reis M, Alvarez-Carretero S. (2025). *mcmc3r: Tools to work with
  MCMCtree and BPP* (Version 0.6.0) [Computer software].
  https://github.com/dosreislab/mcmc3r
