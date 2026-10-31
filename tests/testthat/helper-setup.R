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

# Plot assertions ---------------------------------------------------------
# Compressed byte size depends on the PNG encoder, the font stack and the
# device backend, so a magic-number floor passes on one machine and fails on
# another while saying nothing about the picture. These helpers check what an
# export is supposed to guarantee: a valid file of the requested geometry that
# carries content.

expect_plot_png <- function(path, width = NA_integer_, height = NA_integer_) {
  testthat::expect_true(file.exists(path), info = path)
  bytes <- as.integer(readBin(path, what = "raw", n = 24L))
  testthat::expect_identical(
    bytes[1:8], c(137L, 80L, 78L, 71L, 13L, 10L, 26L, 10L),
    info = paste(path, "is not a PNG")
  )
  # IHDR: 4-byte length, "IHDR", then big-endian width and height.
  be32 <- function(v) sum(v * c(2^24, 2^16, 2^8, 1))
  testthat::expect_identical(
    intToUtf8(bytes[13:16]), "IHDR", info = paste(path, "has no IHDR chunk")
  )
  dims <- as.integer(c(be32(bytes[17:20]), be32(bytes[21:24])))
  if (!is.na(width)) testthat::expect_identical(dims[1], as.integer(width))
  if (!is.na(height)) testthat::expect_identical(dims[2], as.integer(height))
  # Any rendered chart clears this; an empty or truncated file does not.
  testthat::expect_true(file.size(path) > 1000, info = path)
  invisible(dims)
}

expect_plot_pdf <- function(path) {
  testthat::expect_true(file.exists(path), info = path)
  testthat::expect_identical(readChar(path, 5, useBytes = TRUE), "%PDF-",
                             info = paste(path, "is not a PDF"))
  testthat::expect_true(file.size(path) > 1000, info = path)
  invisible(TRUE)
}
