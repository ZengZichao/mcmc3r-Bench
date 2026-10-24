# Test helper: locate the app root and load the application code.

find_app_root <- function() {
  candidates <- c(getwd(), file.path(getwd(), ".."), file.path(getwd(), "../.."))
  for (cand in candidates) {
    if (file.exists(file.path(cand, "app.R")) &&
        dir.exists(file.path(cand, "R")) &&
        file.exists(file.path(cand, "i18n", "translations.csv"))) {
      return(normalizePath(cand))
    }
  }
  stop("Could not locate the mcmc3r-Bench application root")
}

app_root <- find_app_root()
local_lib <- file.path(app_root, ".Rlib")
if (dir.exists(local_lib)) .libPaths(c(local_lib, .libPaths()))
Sys.setenv(MCMC3R_APP_DIR = app_root)
options(mcmc3r.app_dir = app_root)
source(file.path(app_root, "global.R"), local = FALSE)

expect_app_error <- function(expr, code) {
  result <- tryCatch(expr, app_error = function(e) e)
  testthat::expect_s3_class(result, "app_error")
  testthat::expect_identical(result$code, code)
  invisible(result)
}

fixture <- function(name) file.path(app_root, "tests", "fixtures", name)
