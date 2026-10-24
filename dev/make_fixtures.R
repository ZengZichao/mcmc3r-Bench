#!/usr/bin/env Rscript
# Regenerate the small test fixtures. Fixtures are kept under 5 MB.

args <- commandArgs(trailingOnly = FALSE)
file_arg <- sub("^--file=", "", args[grepl("^--file=", args)])
root <- if (length(file_arg)) dirname(dirname(normalizePath(file_arg))) else normalizePath(".")
options(mcmc3r.app_dir = root)
lib <- file.path(root, ".Rlib")
if (dir.exists(lib)) .libPaths(c(lib, .libPaths()))

for (file in c(
  "app_meta.R", "fct_icons.R", "fct_i18n.R", "fct_errors.R", "fct_format.R",
  "utils_validation.R", "fct_theme.R", "fct_files.R", "fct_plots.R",
  "services_calibration.R", "services_mcmc.R", "services_marginal.R"
)) {
  source(file.path(root, "R", file), local = FALSE)
}
i18n_load(file.path(root, "i18n", "translations.csv"))

fixtures <- file.path(root, "tests", "fixtures")
dir.create(fixtures, recursive = TRUE, showWarnings = FALSE)

data("carnivores", package = "mcmc3r")
data("microcebus", package = "mcmc3r")
data("hominids", package = "mcmc3r")

mcmctree <- utils::head(carnivores$mcmc, 1000)
data.table::fwrite(mcmctree, file.path(fixtures, "mcmc_mcmctree.txt"),
                   sep = "\t", quote = FALSE)

bpp <- utils::head(microcebus$mcmc, 1000)
data.table::fwrite(bpp, file.path(fixtures, "mcmc_bpp.txt"),
                   sep = " ", quote = FALSE)

# No time columns.
no_time <- data.frame(
  Iteration = 1:20,
  lnL = -1000 - cumsum(stats::runif(20)),
  mu = stats::runif(20, 1, 2)
)
data.table::fwrite(no_time, file.path(fixtures, "mcmc_no_time.txt"),
                   sep = " ", quote = FALSE)

# One time column only.
single <- data.frame(
  Iteration = 1:50,
  lnL = -900 + stats::rnorm(50),
  t_1 = 10 + stats::rnorm(50, sd = 0.1)
)
data.table::fwrite(single, file.path(fixtures, "mcmc_single_time.txt"),
                   sep = " ", quote = FALSE)

# Missing and infinite values.
na_df <- data.frame(
  Iteration = 1:10,
  lnL = seq(-1000, -991),
  t_1 = c(10, 10.1, NA, 10.3, 10.4, NaN, Inf, 10.7, 10.8, 10.9),
  t_2 = seq(5, 5.9, by = 0.1)
)
data.table::fwrite(na_df, file.path(fixtures, "mcmc_na.txt"),
                   sep = " ", quote = FALSE, na = "NA")

# Header only.
writeLines("Iteration   lnL   t_1", file.path(fixtures, "mcmc_empty.txt"))

# Duplicate column names.
writeLines(
  c("Iteration lnL t_1 t_1",
    "1 -100 10 10",
    "2 -101 10.1 10.1"),
  file.path(fixtures, "mcmc_dupcols.txt")
)

# Marginal likelihood demo archive (synthetic, includes beta = 0).
session <- new_session_dir()
demo <- ml_demo_zip(session, n = 5, a = 5, rows = 200)
file.copy(demo, file.path(fixtures, "ml_demo.zip"), overwrite = TRUE)

# Beta count mismatch: copy the demo and replace beta.txt with 4 values.
tmp <- new_run_dir(session)
unzip(demo, exdir = tmp)
writeLines(format(c(0, 0.01, 0.1, 0.5), scientific = TRUE, digits = 17,
                   trim = TRUE),
           file.path(tmp, "beta.txt"))
old <- getwd()
setwd(tmp)
zip::zip(
  zipfile = file.path(fixtures, "ml_wrong_count.zip"),
  files = c("beta.txt", paste0(1:5, "/mcmc.txt")),
  mode = "mirror"
)
setwd(old)

# A beta file containing 1.
writeLines(c("0", "0.1", "0.5", "1"),
           file.path(fixtures, "beta_with_one.txt"))

# Gauss-Legendre beta and matching demo archive.
gauss_beta <- mcmc3r::make.beta(5, "gauss-quad")
writeLines(format(gauss_beta, scientific = TRUE, digits = 17, trim = TRUE),
           file.path(fixtures, "beta_gauss.txt"))
gdir <- new_run_dir(session)
writeLines(format(gauss_beta, scientific = TRUE, digits = 17, trim = TRUE),
           file.path(gdir, "beta.txt"))
set.seed(42)
for (i in 1:5) {
  dir.create(file.path(gdir, as.character(i)))
  data.table::fwrite(
    data.frame(
      Iteration = 1:150,
      lnL = -1200 + 600 * gauss_beta[i] + stats::rnorm(150, sd = 4)
    ),
    file.path(gdir, as.character(i), "mcmc.txt"),
    quote = FALSE
  )
}
old <- getwd()
setwd(gdir)
zip::zip(
  zipfile = file.path(fixtures, "ml_gauss_demo.zip"),
  files = c("beta.txt", paste0(1:5, "/mcmc.txt")),
  mode = "mirror"
)
setwd(old)

unlink(session, recursive = TRUE)
cat("Fixtures written to", fixtures, "\n")
