test_that("font registration and lookup return the bundled family", {
  expect_identical(register_app_font(), "NotoSansSC")
  expect_identical(plot_font(), "NotoSansSC")
})

test_that("calibration plots render all modes without errors", {
  params_l <- cal_defaults("L")
  res_l <- cal_compute(params_l)
  params_b <- cal_defaults("B")
  res_b <- cal_compute(params_b)
  params_u <- cal_defaults("U")
  res_u <- cal_compute(params_u)

  draw_all <- function() {
    draw_calibration(res_l, "en", "light")
    draw_calibration(res_l, "zh", "dark", show_density = FALSE, show_cdf = TRUE)
    draw_calibration(res_b, "en", "light", show_density = TRUE, show_cdf = TRUE)
    draw_calibration(res_u, "zh", "dark", show_density = TRUE, show_cdf = FALSE)
  }

  path <- tempfile(fileext = ".png")
  grDevices::png(path, width = 800, height = 600)
  on.exit({
    if (grDevices::dev.cur() > 1) grDevices::dev.off()
    unlink(path)
  }, add = TRUE)
  expect_silent(draw_all())
  grDevices::dev.off()
  expect_gt(file.size(path), 10000)
})

test_that("calibration plot skips quantile labels when asked", {
  res <- cal_compute(cal_defaults("L"))
  path <- tempfile(fileext = ".png")
  grDevices::png(path, width = 640, height = 480)
  on.exit({
    if (grDevices::dev.cur() > 1) grDevices::dev.off()
    unlink(path)
  }, add = TRUE)
  expect_silent(draw_calibration(res, "en", "light", quantile_note = FALSE))
  grDevices::dev.off()
  expect_gt(file.size(path), 5000)
})

test_that("marginal plots handle values and all-non-finite input", {
  result <- list(
    per_beta = data.frame(
      beta = c(0, 0.25, 0.5, 1),
      mean_logl = c(-1200, -900, -700, -650),
      se_warning = c(FALSE, TRUE, FALSE, FALSE),
      stringsAsFactors = FALSE
    ),
    method = "gauss-quad",
    model_name = "demo"
  )
  no_finite <- result
  no_finite$per_beta$mean_logl <- c(NA_real_, NaN, Inf, -Inf)

  path <- tempfile(fileext = ".png")
  grDevices::png(path, width = 800, height = 600)
  on.exit({
    if (grDevices::dev.cur() > 1) grDevices::dev.off()
    unlink(path)
  }, add = TRUE)
  expect_silent(draw_marginal(result, "en", "light"))
  expect_silent(draw_marginal(no_finite, "zh", "dark"))
  grDevices::dev.off()
  expect_gt(file.size(path), 5000)
})

test_that("PNG and PDF exports are non-empty in both themes", {
  res <- cal_compute(cal_defaults("L"))
  tmp <- withr::local_tempdir()

  for (theme in c("light", "dark")) {
    png <- file.path(tmp, paste0("cal-", theme, ".png"))
    save_plot_png(
      png,
      function(colors) draw_calibration(res, "zh", theme),
      theme = theme, width = 1600, height = 1200, res = 150
    )
    expect_true(file.exists(png))
    expect_gt(file.size(png), 10000)

    pdf <- file.path(tmp, paste0("cal-", theme, ".pdf"))
    save_plot_pdf(
      pdf,
      function(colors) draw_calibration(res, "zh", theme),
      theme = theme
    )
    expect_true(file.exists(pdf))
    expect_gt(file.size(pdf), 5000)
  }
})

test_that("export devices clean up graphics state", {
  res <- cal_compute(cal_defaults("U"))
  tmp <- withr::local_tempdir()
  before <- grDevices::dev.cur()
  save_plot_png(
    file.path(tmp, "state.png"),
    function(colors) draw_calibration(res, "en", "light"),
    width = 640, height = 480, res = 96
  )
  expect_identical(grDevices::dev.cur(), before)
})
