# 引用

| Field | Value |
|---|---|
| lang | zh-CN |
| pair | ../en/CITATION.md |
| applies_to | 0.1.0 |
| doc_version | 1.0 |
| last_reviewed | 2026-10-24 |
| canonical | false |
| status | current |

**语言：** [English](../en/CITATION.md) | 中文

## 软件引用

若使用本图形界面，请引用软件条目：

> 曾子超. (2026). *mcmc3r Bench*（版本 0.1.0）[计算机软件].
> https://github.com/ZengZichao/mcmc3r-Bench

BibTeX：

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

## 上游包

本图形界面依赖 Mario dos Reis 与 Sandra Alvarez-Carretero 维护的 `mcmc3r`：

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

## 方法引用

请引用与所用工作流对应的方法论文，加上上游包与本图形界面软件条目。

| 工作流 | 引用 | DOI |
|---|---|---|
| 校准密度（L、B、U） | Yang & Rannala (2006), *Mol. Biol. Evol.* 23: 212–226 | 10.1093/molbev/msj024 |
| 截断柯西校准 | Inoue, Donoghue & Yang (2010), *Syst. Biol.* 59: 74–89 | 10.1093/sysbio/syp078 |
| 步进采样 | dos Reis et al. (2018), *Syst. Biol.* 67: 594–615 | 10.1093/sysbio/syy001 |
| 高斯–勒让德求积 | Rannala & Yang (2017), *Syst. Biol.* 66: 823–842 | 10.1093/sysbio/syw119 |
| 块自举（未来） | Álvarez-Carretero et al. (2022), *Nature* 602: 263–267 | 10.1038/s41586-021-04341-1 |
| 连续形态学（未来） | Álvarez-Carretero et al. (2019), *Syst. Biol.* 68: 967–986 | 10.1093/sysbio/syz015 |
| 祖先重建（未来） | Felsenstein (1973), *Am. J. Hum. Genet.* 25: 471–492 | 无 DOI |

## 论文中的引用方式

1. 引用所用统计方法的方法论文。
2. 引用 `mcmc3r`，因为结果由它计算。
3. 可选引用本图形界面软件条目。
4. 不要将图形界面描述为方法贡献。

## 机器可读元数据

仓库根目录的 `CITATION.cff` 包含软件条目、作者、ORCID、版本、仓库 URL 与关键方法
引用。Connect Cloud 公开地址记录在 `README.md` 与 `DEPLOYMENT.md`；引用文件保留
仓库 URL，以便内容地址变化时仍然有效。

## Zenodo DOI

公开释放后可注册 DOI。在此之前不声明 DOI。获得 DOI 后，请更新 `CITATION.cff` 与
本页。
