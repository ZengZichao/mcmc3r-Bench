test_that("result metadata records reproducibility fields", {
  meta <- result_metadata("calibration", lang = "zh", screen_theme = "dark",
                          export_theme = "print",
                          extra = list(type = "L"))
  expect_identical(meta$app, APP_NAME)
  expect_identical(meta$app_version, "0.1.0")
  expect_identical(meta$module, "calibration")
  expect_identical(meta$lang, "zh")
  expect_identical(meta$screen_theme, "dark")
  expect_identical(meta$export_theme, "print")
  expect_identical(meta$upstream_sha, UPSTREAM_SHA)
  expect_identical(meta$type, "L")
  expect_match(meta$computed_at_utc, "^\\d{4}-\\d{2}-\\d{2}T")
})

test_that("CSV export is UTF-8, escapes formulas, and preserves NA", {
  tmp <- withr::local_tempdir()
  df <- data.frame(
    label = c("=cmd|' /C calc'!A0", "-1", "+2", "@SUM(A1)", "normal", NA),
    value = c(1, 2, 3, 4, 5, NA),
    stringsAsFactors = FALSE
  )
  path <- file.path(tmp, "out.csv")
  export_csv(df, path)
  expect_true(file.exists(path))

  back <- read_csv_safe(path, na.strings = c("", "NA"))
  expect_identical(back$label[1], "'=cmd|' /C calc'!A0")
  expect_identical(back$label[2], "'-1")
  expect_identical(back$label[3], "'+2")
  expect_identical(back$label[4], "'@SUM(A1)")
  expect_identical(back$label[5], "normal")
  expect_true(is.na(back$label[6]))
  expect_identical(back$value, c(1L, 2L, 3L, 4L, 5L, NA_integer_))
})

test_that("metadata JSON is written with scalar fields unboxed", {
  tmp <- withr::local_tempdir()
  path <- file.path(tmp, "metadata.json")
  export_metadata_json(
    result_metadata("marginal", lang = "en", screen_theme = "light",
                    extra = list(n_beta = 5L, warnings = character())),
    path
  )
  parsed <- jsonlite::fromJSON(path)
  expect_identical(parsed$module, "marginal")
  expect_identical(parsed$n_beta, 5L)
  expect_length(parsed$warnings, 0)
})

test_that("bundle ZIP contains the requested files", {
  tmp <- withr::local_tempdir()
  a <- file.path(tmp, "a.csv")
  b <- file.path(tmp, "b.json")
  writeLines("x", a)
  writeLines("{}", b)
  zipfile <- file.path(tmp, "bundle.zip")
  export_bundle_zip(c(a, b), zipfile)
  expect_true(file.exists(zipfile))
  expect_setequal(unzip(zipfile, list = TRUE)$Name, c("a.csv", "b.json"))

  expect_error(export_bundle_zip(character(), zipfile), "No files")
})

test_that("module data frames are stable for export", {
  cal <- list(table = data.frame(
    x = c(0, 1), density = c(0.1, 0.2), cdf = c(0, 1),
    stringsAsFactors = FALSE
  ))
  cal_df <- calibration_export_df(cal)
  expect_named(cal_df, c("x", "density", "cdf"))
  expect_equal(nrow(cal_df), 2)

  mcmc <- list(table = data.frame(
    parameter = "t_n20", mean = 1, median = 1, ci025 = 0.5, ci975 = 1.5,
    n = 100, extra = "drop", stringsAsFactors = FALSE
  ))
  mcmc_df <- mcmc_export_df(mcmc)
  expect_named(mcmc_df, c("parameter", "mean", "median", "ci025", "ci975", "n"))
  expect_identical(rownames(mcmc_df), "1")

  ml <- list(
    model_name = "demo", method = "step-stones", logml = -100, se = 1,
    n_beta = 2, se_reliable = TRUE, beta_converted = 0,
    computed_at = "2026-10-24 00:00:00", app_version = "0.1.0",
    upstream_version = UPSTREAM_VERSION, upstream_sha = UPSTREAM_SHA,
    per_beta = data.frame(
      beta = c(0, 0.5), mean_logl = c(-1, -2), n_rows = c(10L, 10L),
      se_warning = c(FALSE, TRUE), stringsAsFactors = FALSE
    )
  )
  summary_df <- ml_summary_export_df(ml)
  expect_named(
    summary_df,
    c("model", "method", "logml", "se", "n_beta", "se_reliable",
      "beta_zero_converted", "computed_at", "app_version",
      "upstream_version", "upstream_sha")
  )
  expect_identical(summary_df$model, "demo")
  detail_df <- ml_detail_export_df(ml)
  expect_named(detail_df,
               c("beta", "mean_logl", "n_rows", "se_warning", "method", "model"))
  expect_equal(nrow(detail_df), 2)
})
