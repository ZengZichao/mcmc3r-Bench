#!/usr/bin/env Rscript
# Service-layer coverage gate. The plan requires at least 80% coverage for the
# services_* modules, which wrap every upstream call.

args <- commandArgs(trailingOnly = FALSE)
file_arg <- sub("^--file=", "", args[grepl("^--file=", args)])
root <- if (length(file_arg)) {
  normalizePath(file.path(dirname(normalizePath(file_arg)), ".."))
} else {
  normalizePath(".")
}
lib <- file.path(root, ".Rlib")
if (dir.exists(lib)) .libPaths(c(lib, .libPaths()))

if (!requireNamespace("covr", quietly = TRUE) ||
    !requireNamespace("testthat", quietly = TRUE)) {
  stop("covr and testthat are required to measure coverage", call. = FALSE)
}

source_files <- list.files(file.path(root, "R"), pattern = "^services_.*[.]R$",
                           full.names = TRUE)
test_files <- c(
  file.path(root, "tests", "testthat", "helper-setup.R"),
  list.files(file.path(root, "tests", "testthat"),
             pattern = "^test-.*[.]R$", full.names = TRUE)
)

old <- setwd(root)
on.exit(setwd(old), add = TRUE)
suppressPackageStartupMessages(library(testthat))
coverage <- covr::file_coverage(source_files, test_files)
pct <- covr::percent_coverage(coverage)
cat(sprintf("Service-layer coverage: %.2f%%\n", pct))
print(coverage)

if (pct < 80) {
  stop(sprintf("Service-layer coverage %.2f%% is below the 80%% gate", pct),
       call. = FALSE)
}
