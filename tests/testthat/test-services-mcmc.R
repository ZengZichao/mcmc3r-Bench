test_that("MCMCtree fixture summary matches mcmc3r::mcmc.sum", {
  parsed <- mcmc_read(fixture("mcmc_mcmctree.txt"))
  res <- mcmc_summarise(parsed$data, "auto")
  expect_identical(res$prefix, "t_")
  upstream <- mcmc3r::mcmc.sum(parsed$data)
  expect_equal(res$table$mean, as.numeric(upstream$mean), tolerance = 1e-12)
  expect_equal(res$table$median, as.numeric(upstream$median), tolerance = 1e-12)
  expect_equal(res$table$ci025, as.numeric(upstream$ci025), tolerance = 1e-12)
  expect_equal(res$table$ci975, as.numeric(upstream$ci975), tolerance = 1e-12)
})

test_that("BPP fixture auto-detects tau_ and keeps original names", {
  parsed <- mcmc_read(fixture("mcmc_bpp.txt"))
  res <- mcmc_summarise(parsed$data, "auto")
  expect_identical(res$prefix, "tau_")
  expect_true(all(grepl("^tau_", res$table$parameter)))
  expect_identical(res$diagnostics$time_columns, 5L)
})

test_that("single time column is handled without drop = FALSE errors", {
  parsed <- mcmc_read(fixture("mcmc_single_time.txt"))
  res <- mcmc_summarise(parsed$data, "t_")
  expect_equal(nrow(res$table), 1L)
  expect_true(is.finite(res$table$mean))
  expect_equal(res$table$n, nrow(parsed$data))
})

test_that("non-finite rows are removed and reported as MCMC-008", {
  parsed <- mcmc_read(fixture("mcmc_na.txt"))
  res <- mcmc_summarise(parsed$data, "t_")
  expect_equal(res$diagnostics$rows_in, 10L)
  expect_equal(res$diagnostics$rows_removed, 3L)
  expect_equal(res$diagnostics$rows_used, 7L)
  expect_true(any(vapply(res$warnings, function(w) w$code == "MCMC-008", logical(1))))
})

test_that("missing time columns return MCMC-003", {
  parsed <- mcmc_read(fixture("mcmc_no_time.txt"))
  expect_app_error(mcmc_summarise(parsed$data, "auto"), "MCMC-003")
})

test_that("empty file returns MCMC-002", {
  expect_app_error(mcmc_read(fixture("mcmc_empty.txt")), "MCMC-002")
})

test_that("duplicate column names return MCMC-006", {
  expect_app_error(mcmc_read(fixture("mcmc_dupcols.txt")), "MCMC-006")
})

test_that("strict prefix excludes theta_ and mu_t_ columns", {
  df <- data.frame(t_1 = 1:5, mu_t_1 = 6:10, theta_1 = 11:15)
  cols <- mcmc_time_columns(names(df), "t_")
  expect_identical(cols, "t_1")
})

test_that("non-numeric time columns return MCMC-004", {
  df <- data.frame(Iteration = 1:5, t_1 = letters[1:5])
  expect_app_error(mcmc_summarise(df, "t_"), "MCMC-004")
})

test_that("all non-finite rows return MCMC-007", {
  df <- data.frame(Iteration = 1:5, t_1 = c(NA, NaN, Inf, -Inf, NA))
  expect_app_error(mcmc_summarise(df, "t_"), "MCMC-007")
})

test_that("row limit returns MCMC-005", {
  df <- data.frame(Iteration = seq_len(500001), t_1 = 1)
  expect_app_error(mcmc_summarise(df, "t_"), "MCMC-005")
})

test_that("custom prefix is escaped and matched literally", {
  df <- data.frame(a.b = 1:5, axb = 6:10, t_1 = 11:15)
  res <- mcmc_summarise(df, "a.b")
  expect_identical(res$table$parameter, "a.b")
})

test_that("explicit separators are honoured", {
  tmp <- withr::local_tempdir()
  comma <- file.path(tmp, "comma.csv")
  writeLines(c("Iteration,t_1,t_2", "1,10,11", "2,12,13"), comma)
  parsed <- mcmc_read(comma, sep = ",")
  expect_identical(names(parsed$data), c("Iteration", "t_1", "t_2"))
  expect_identical(parsed$diagnostics$separator, ",")

  space <- file.path(tmp, "space.txt")
  writeLines(c("Iteration t_1 t_2", "1 10 11", "2 12 13"), space)
  parsed <- mcmc_read(space, sep = "")
  expect_identical(names(parsed$data), c("Iteration", "t_1", "t_2"))
  expect_identical(parsed$diagnostics$separator, "whitespace")

  tab <- file.path(tmp, "tab.tsv")
  writeLines(c("Iteration\tt_1\tt_2", "1\t10\t11", "2\t12\t13"), tab)
  parsed <- mcmc_read(tab, sep = "\t")
  expect_identical(names(parsed$data), c("Iteration", "t_1", "t_2"))
  expect_identical(parsed$diagnostics$separator, "\t")

  expect_identical(mcmc_separator_value("auto"), "auto")
  expect_identical(mcmc_separator_value("space"), "")
  expect_identical(mcmc_separator_value("tab"), "\t")
  expect_identical(mcmc_separator_value("comma"), ",")
})
