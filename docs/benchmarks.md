# Benchmarks / 性能基准

Local measurements for v0.1.0. These are indicative, not platform guarantees.
本地测量结果，供参考；不是平台承诺。

- Date / 日期: 2026-10-24
- R: 4.6.1 (aarch64-apple-darwin)
- Command / 命令: `Rscript dev/benchmark.R`

| Scenario / 场景 | Target / 目标 | Measured / 实测 |
|---|---|---|
| Calibration L, 1,000 points / 1,000 点 | < 300 ms | 3.7 ms |
| Calibration L, 5,000 points / 5,000 点 | < 800 ms | 0.7 ms |
| MCMC summary, 100,000 rows / 10 万行 | < 2 s | 26.7 ms |
| MCMC summary, 500,000 rows / 50 万行 | < 8 s | 66.8 ms |
| Marginal prepare, 5 × 20,000 / 5 × 2 万 | — | 128.5 ms |
| Marginal execute, 5 × 20,000 / 5 × 2 万 | < 5 s | 45.1 ms |
| Marginal prepare, 10 × 20,000 / 10 × 2 万 | — | 179.1 ms |
| Marginal execute, 10 × 20,000 / 10 × 2 万 | < 5 s | 63.7 ms |
| Marginal prepare, 30 × 15,000 / 30 × 1.5 万 | — | 391.3 ms |
| Marginal execute, 30 × 15,000 / 30 × 1.5 万 | < 5 s | 185.4 ms |
| Approximate memory / 近似内存 | < 700 MB | 20.6 MB (objects only / 仅对象) |

Notes / 说明:

- The 5,000-point measurement is lower than the 1,000-point one because of
  warm-up and timer resolution; both are far below budget.
  5,000 点低于 1,000 点是因为预热与计时分辨率；两者都远低于预算。
- 30 × 50,000 would be 1.5 million rows, above the 500,000-row app limit, so
  the largest valid 30-chain case (30 × 15,000) is reported instead.
  30 × 50,000 共 150 万行，超过应用 50 万行上限；因此报告 30 链的最大合法情形
  （30 × 15,000）。
- Upload, parse, and render time in the browser add overhead; measure those after
  deployment with the real network.
  浏览器中的上传、解析与渲染会增加开销；部署后请在真实网络中测量。
- Cold start, memory peak, and p95 latency must be recorded from Posit Connect
  Cloud content metrics after the first deployment.
  冷启动、内存峰值与 p95 延迟需在首次部署后从 Posit Connect Cloud 内容指标记录。
