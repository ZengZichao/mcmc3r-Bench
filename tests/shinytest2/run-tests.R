#!/usr/bin/env Rscript
# Run the shinytest2 end-to-end suite explicitly.
Sys.setenv(NOT_CRAN = "true")

args <- commandArgs(trailingOnly = FALSE)
file_arg <- sub("^--file=", "", args[grepl("^--file=", args)])
root <- if (length(file_arg)) {
  normalizePath(file.path(dirname(normalizePath(file_arg)), "..", ".."))
} else {
  normalizePath(".")
}
lib <- file.path(root, ".Rlib")
if (dir.exists(lib)) .libPaths(c(lib, .libPaths()))

library(testthat)
library(shinytest2)
for (file in c("test-app.R", "test-theme.R")) {
  test_file(file.path(root, "tests", "shinytest2", file),
            reporter = "summary")
}
