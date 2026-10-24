library(testthat)
library(shiny)

test_dir(
  "tests/testthat",
  reporter = "summary",
  stop_on_failure = TRUE
)
