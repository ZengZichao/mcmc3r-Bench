test_that("formula injection is escaped for character columns only", {
  df <- data.frame(
    parameter = c("=cmd|' /C calc'!A0", "+1", "-2", "@SUM(A1)"),
    value = c(1, 2, 3, 4),
    stringsAsFactors = FALSE
  )
  out <- sanitize_csv_df(df)
  expect_true(all(startsWith(out$parameter, "'")))
  expect_identical(out$value, df$value)
})

test_that("natural order sorts numeric tokens", {
  x <- c("10_mcmc.txt", "2_mcmc.txt", "1_mcmc.txt", "beta.txt")
  expect_identical(x[natural_order(x)],
                   c("1_mcmc.txt", "2_mcmc.txt", "10_mcmc.txt", "beta.txt"))
})

test_that("download filenames follow the documented template", {
  name <- download_filename("mcmc-summary", "csv", "zh", "print",
                            as.POSIXct("2026-10-24 12:34:56", tz = "UTC"))
  expect_identical(name,
                   "mcmc3r-bench_mcmc-summary_20261024-123456_zh_print.csv")
  expect_true(grepl("^mcmc3r-bench_", download_filename("calibration", "png")))
})

test_that("number formatting is stable and compact", {
  expect_identical(fmt_num(10), "10")
  expect_identical(fmt_num(0.025), "0.025")
  expect_true(nzchar(fmt_num(1e-12)))
  expect_identical(fmt_int(1000), "1000")
  expect_identical(fmt_bytes(1024), "1.0 KB")
})

test_that("basenames are safe on both separators", {
  expect_identical(safe_basename("a/b/c.txt"), "c.txt")
  expect_identical(safe_basename("a\\b\\c.txt"), "c.txt")
})
