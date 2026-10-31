# Application metadata -----------------------------------------------------
#
# Single source of truth for version information is the VERSION file at the
# repository root. The constants below are checked by dev/check_release.R.

APP_NAME <- "mcmc3r Bench"
APP_VERSION <- "0.1.0"
APP_BUILD_DATE <- "2026-10-24"
APP_AUTHOR <- "Zeng Zichao (\u66fe\u5b50\u8d85)"
APP_AUTHOR_EN <- "Zeng Zichao"
APP_EMAIL <- "zengzichao@sjtu.edu.cn"
APP_ORCID <- "0000-0001-6553-970X"
APP_REPO <- "https://github.com/ZengZichao/mcmc3r-Bench"
APP_ISSUES <- "https://github.com/ZengZichao/mcmc3r-Bench/issues"
APP_URL <- "https://zengzichao-mcmc3r-bench.share.connect.posit.cloud/"

UPSTREAM_REPO <- "https://github.com/dosreislab/mcmc3r"
UPSTREAM_AUTHORS <- "Mario dos Reis, Sandra Alvarez-Carretero, and contributors"
UPSTREAM_VERSION <- "0.6.0"
UPSTREAM_SHA <- "f6a8f78bc55a53b724118480b6fbfbc71d3b0897"

DOC_VERSION <- "0.2.0"
DOC_LANGUAGES <- c("en", "zh")

APP_CODE_LICENSE <- "MIT"
APP_DOC_LICENSE <- "CC BY 4.0"
FONT_LICENSE <- "OFL-1.1"

# Hard resource limits (see docs/en/ARCHITECTURE.md, section "Limits").
.env_upload_mb <- suppressWarnings(as.numeric(Sys.getenv("MCMC3R_MAX_UPLOAD_MB", "50")))
if (!is.finite(.env_upload_mb) || .env_upload_mb < 1 || .env_upload_mb > 500) {
  .env_upload_mb <- 50
}

LIMITS <- list(
  upload_mb = .env_upload_mb,
  upload_total_mb = max(100, 2 * .env_upload_mb),
  zip_uncompressed_mb = 200,
  zip_files = 500,
  zip_ratio = 100,
  mcmc_rows = 500000,
  calibration_points_max = 5000,
  calibration_points_min = 100,
  beta_max_ss = 50,
  beta_max_gq = 100,
  gauss_max = 256,
  chains_max = 50
)

# Effective version. MCMC3R_APP_VERSION is used by CI to check parity.
app_version <- function() {
  env <- Sys.getenv("MCMC3R_APP_VERSION", "")
  if (nzchar(env)) env else APP_VERSION
}

app_build_date <- function() {
  APP_BUILD_DATE
}

upstream_remote_sha <- function() {
  UPSTREAM_SHA
}

# The title comes from the translation table. It used to be assembled here from
# APP_NAME_ZH, a second copy of the app name that had drifted to a Japanese
# variant of 实 (U+5B9F) instead of the simplified Chinese U+5B9E.
app_title <- function(lang = "en") {
  tr("app.title", lang)
}
