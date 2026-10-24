# 方法与引用

| Field | Value |
|---|---|
| lang | zh-CN |
| pair | ../en/METHODS.md |
| applies_to | 0.1.0 |
| doc_version | 1.0 |
| last_reviewed | 2026-10-24 |
| canonical | false |
| status | current |

**语言：** [English](../en/METHODS.md) | 中文

本文说明三个模块背后的方法以及应引用的文献。图形界面不实现新的统计方法：所有计算
均由上游 `mcmc3r` 包完成。

## 校准分布

### 最小边界（L）

L 校准是位于 `tL` 以上的截断柯西分布（Inoue, Donoghue & Yang 2010）。它由 `tL`
以下的幂律密度与 `tL` 以上右移的柯西尾部组成。参数为 `p`（众数）、`c`（尾部尺度）
与 `pL`（下尾概率）。密度由 `mcmc3r::dL` 实现，累积概率由 `pL`，分位数由 `qL`。

### 联合边界（B）

B 校准在 `tL` 与 `tU` 处设置软下界与软上界（Yang & Rannala 2006）。幂律尾部从
`tL` 进入，区间内为均匀密度，指数尾部从 `tU` 离开。尾部概率为 `pL` 与 `pU`，
且二者之和必须小于 1。由 `dB`、`pB`、`qB` 实现。

### 最大边界（U）

U 校准是 B 在 `tL = 0`、`pL = 0` 时的极限：`tU` 以下为均匀密度，以上为指数尾部。
由 `dU`、`pU`、`qU` 实现。

### 数值说明

- 在 `x = 0` 处，当形状参数小于 1 时幂律项可能为无穷大。图形界面将非有限值替换为
  `NA`，图中裁剪，CSV 留空（CAL-011）。
- 分位数由上游 `uniroot` 求解。极端参数可能失败；图形界面映射为 CAL-010，并建议
  调整参数。
- 自动 X 轴上限为 97.5% 分位数乘以 1.15，且不小于 `tL` 或 `tU` 的 1.25 倍。

## MCMC 汇总

图形界面使用严格前缀（`^t_` 或 `^tau_`）选择时间列，转换为数值，删除含非有限值的行，
并逐列计算均值、中位数、2.5% 与 97.5% 分位数。对多列输入，这与
`mcmc3r::mcmc.sum` 等价。实现与上游辅助函数在三个边界情形上不同：

1. 单列输入：上游 `apply()` 降维为向量；图形界面不降维地汇总该列。
2. 非有限值：上游 `median()` 在未设置 `na.rm` 时报错；图形界面删除受影响行并报告数量。
3. 无时间列：上游返回 0 行数据框；图形界面抛出 MCMC-003。

测试套件在包内置数据上将图形界面汇总与 `mcmc3r::mcmc.sum` 对比，容差为 `1e-12`。

## 边际似然

### 步进采样法

对于在 beta 值 `b_1 < … < b_n`（`b_n < 1`）处采样的 `n` 条功率后验链，步进采样
估计

```
log Z ≈ Σ_k (b_{k+1} - b_k) log( mean( exp( (b_{k+1}-b_k) logL_k ) ) )
```

并在内部追加 `b_{n+1} = 1`。标准误使用 Xie et al. (2011) 的 delta 近似；当
`var(r_k) / r_k^2 > 0.1` 时上游给出警告。见 dos Reis et al. (2018)。

### 高斯–勒让德求积

使用 `n` 点高斯–勒让德规则的热力学积分估计

```
log Z ≈ Σ_k w_k / 2 · mean(logL at beta_k)
```

其中 `(beta_k, w_k)` 为该规则的节点与权重。见 Rannala & Yang (2017)。图形界面会
检查用户提供的 beta 是否与 `make.beta(n, "gauss-quad")` 在 `1e-6` 内一致。

### 输入处理

上游函数从当前工作目录读取 `1/mcmc.txt` … `n/mcmc.txt`。Shiny 进程的工作目录是
共享的，因此图形界面会：

1. 在会话临时目录下创建隔离的运行目录。
2. 为每条链写入仅含 `lnL` 的 `mcmc.txt`。
3. 在 `withr::with_dir()` 内调用上游函数。
4. 绝不在全局调用 `setwd()`。

图形界面还会在调用上游代码前校验 beta 范围、严格递增、数量、`lnL` 有限性与链长度。

## 不应引用为方法贡献

图形界面是软件基础设施，不引入校准分布、步进采样、高斯–勒让德积分或汇总统计量。
不要将它描述为方法贡献。报告结果时请引用原始论文与 `mcmc3r` 包。

## 参考文献

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
