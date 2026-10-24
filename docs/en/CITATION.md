# Citation

| Field | Value |
|---|---|
| lang | en |
| pair | ../zh/CITATION.md |
| applies_to | 0.1.0 |
| doc_version | 1.0 |
| last_reviewed | 2026-10-24 |
| canonical | true |
| status | current |

**Language:** English | [中文](../zh/CITATION.md)

## Software citation

If you use this GUI, cite the software entry:

> Zeng Z. (2026). *mcmc3r Bench* (Version 0.1.0) [Computer software].
> https://github.com/ZengZichao/mcmc3r-Bench

BibTeX:

```bibtex
@software{zeng_mcmc3r_bench_2026,
  author  = {Zeng, Zichao},
  title   = {{mcmc3r Bench}: an independent bilingual GUI for mcmc3r},
  year    = {2026},
  version = {0.1.0},
  url     = {https://github.com/ZengZichao/mcmc3r-Bench},
  orcid   = {0000-0001-6553-970X},
  note    = {Computer software}
}
```

## Upstream package

The GUI depends on `mcmc3r`, maintained by Mario dos Reis and Sandra
Alvarez-Carretero:

> dos Reis M, Alvarez-Carretero S. (2025). *mcmc3r: Tools to work with MCMCtree
> and BPP* (Version 0.6.0) [Computer software].
> https://github.com/dosreislab/mcmc3r

```bibtex
@software{dosreis_mcmc3r_2025,
  author  = {dos Reis, Mario and Alvarez-Carretero, Sandra},
  title   = {mcmc3r: Tools to work with MCMCtree and BPP},
  year    = {2025},
  version = {0.6.0},
  url     = {https://github.com/dosreislab/mcmc3r},
  note    = {R package}
}
```

## Method references

Cite the method paper(s) that match the workflow you used, plus the package and
the GUI software entry.

| Workflow | Reference | DOI |
|---|---|---|
| Calibration densities (L, B, U) | Yang & Rannala (2006), *Mol. Biol. Evol.* 23: 212–226 | 10.1093/molbev/msj024 |
| Truncated Cauchy calibration | Inoue, Donoghue & Yang (2010), *Syst. Biol.* 59: 74–89 | 10.1093/sysbio/syp078 |
| Stepping stones | dos Reis et al. (2018), *Syst. Biol.* 67: 594–615 | 10.1093/sysbio/syy001 |
| Gauss–Legendre quadrature | Rannala & Yang (2017), *Syst. Biol.* 66: 823–842 | 10.1093/sysbio/syw119 |
| Block bootstrap (future) | Álvarez-Carretero et al. (2022), *Nature* 602: 263–267 | 10.1038/s41586-021-04341-1 |
| Continuous morphology (future) | Álvarez-Carretero et al. (2019), *Syst. Biol.* 68: 967–986 | 10.1093/sysbio/syz015 |
| Ancestral reconstruction (future) | Felsenstein (1973), *Am. J. Hum. Genet.* 25: 471–492 | no DOI |

## How to cite in a paper

1. Cite the method paper(s) for the statistics you used.
2. Cite `mcmc3r` because it computes the results.
3. Optionally cite the GUI as software.
4. Do not describe the GUI as a methodological contribution.

## Machine-readable metadata

`CITATION.cff` at the repository root contains the software entry, author,
ORCID, version, repository URL, and key method references. The public Connect
Cloud URL is recorded in `README.md` and `DEPLOYMENT.md`; the citation file
keeps the repository URL so it stays valid if the content URL changes.

## Zenodo DOI

A DOI can be registered after a public release. Until then, no DOI is claimed.
When a DOI exists, add it to `CITATION.cff` and this page.
