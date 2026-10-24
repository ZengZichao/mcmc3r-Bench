#!/usr/bin/env Rscript
# Lightweight local benchmarks. Results are printed, not enforced.

args <- commandArgs(trailingOnly = FALSE)
file_arg <- sub("^--file=", "", args[grepl("^--file=", args)])
root <- if (length(file_arg)) dirname(dirname(normalizePath(file_arg))) else normalizePath(".")
lib <- file.path(root, ".Rlib")
if (dir.exists(lib)) .libPaths(c(lib, .libPaths()))
options(mcmc3r.app_dir = root)
Sys.setenv(MCMC3R_APP_DIR = root)
source(file.path(root, "global.R"), local = FALSE)

time_it <- function(label, expr) {
  gc()
  start <- Sys.time()
  result <- force(expr)
  elapsed <- as.numeric(difftime(Sys.time(), start, units = "secs")) * 1000
  cat(sprintf("%-42s %10.1f ms\n", label, elapsed))
  invisible(result)
}

cat("mcmc3r Bench local benchmark\n")
cat("R:", R.version.string, "\n")
cat("Platform:", R.version$platform, "\n\n")

invisible(cal_compute(cal_defaults("L")))
for (n in c(1000, 5000)) {
  p <- cal_defaults("L")
  p$points <- n
  time_it(paste0("calibration L, ", n, " points"), cal_compute(p))
}

n_rows <- 100000
set.seed(1)
big <- data.frame(
  Iteration = seq_len(n_rows),
  lnL = -1000 + stats::rnorm(n_rows),
  t_1 = 10 + stats::rnorm(n_rows, sd = 0.2),
  t_2 = 5 + stats::rnorm(n_rows, sd = 0.1),
  t_3 = 2 + stats::rnorm(n_rows, sd = 0.05)
)
time_it(paste0("MCMC summary, ", format(n_rows, big.mark = ","), " rows"),
        mcmc_summarise(big, "t_"))

n_rows_max <- 500000
big_max <- data.frame(
  Iteration = seq_len(n_rows_max),
  lnL = -1000 + stats::rnorm(n_rows_max),
  t_1 = 10 + stats::rnorm(n_rows_max, sd = 0.2),
  t_2 = 5 + stats::rnorm(n_rows_max, sd = 0.1),
  t_3 = 2 + stats::rnorm(n_rows_max, sd = 0.05)
)
time_it("MCMC summary, 500,000 rows",
        mcmc_summarise(big_max, "t_"))

session <- new_session_dir()
withr::defer(unlink(session, recursive = TRUE), envir = globalenv())
zip <- ml_demo_zip(session, n = 5, a = 5, rows = 20000)
prep <- time_it("marginal prepare, 5 x 20k", ml_prepare_zip(zip, session, "step-stones"))
exec <- time_it("marginal execute, 5 x 20k", ml_execute(prep$run_dir, "step-stones"))
cat(sprintf("%-42s %10.4f\n", "logML (5 x 20k)", exec$logml))

zip10 <- ml_demo_zip(session, n = 10, a = 5, rows = 20000)
prep10 <- time_it("marginal prepare, 10 x 20k",
                  ml_prepare_zip(zip10, session, "step-stones"))
exec10 <- time_it("marginal execute, 10 x 20k",
                  ml_execute(prep10$run_dir, "step-stones"))
cat(sprintf("%-42s %10.4f\n", "logML (10 x 20k)", exec10$logml))

# 30 x 15k = 450k rows, inside the 500k app limit; 30 x 50k would be rejected.
zip30 <- ml_demo_zip(session, n = 30, a = 5, rows = 15000)
prep30 <- time_it("marginal prepare, 30 x 15k",
                  ml_prepare_zip(zip30, session, "step-stones"))
exec30 <- time_it("marginal execute, 30 x 15k",
                  ml_execute(prep30$run_dir, "step-stones"))
cat(sprintf("%-42s %10.4f\n", "logML (30 x 15k)", exec30$logml))

cat("\nMemory used (approx): ",
    format(object.size(list(big = big, big_max = big_max, prep = prep,
                            prep10 = prep10, prep30 = prep30, exec = exec,
                            exec10 = exec10, exec30 = exec30)),
           units = "MB"), "\n", sep = "")
