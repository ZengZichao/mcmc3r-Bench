test_that("calibration densities match mcmc3r::dL/dB/dU", {
  p <- cal_defaults("L")
  res <- cal_compute(p)
  x <- res$table$x
  expected <- mcmc3r::dL(x, tL = 10, p = 0.1, c = 1, pL = 0.025)
  idx <- is.finite(expected)
  expect_equal(res$table$density[idx], expected[idx], tolerance = 1e-8)
  expect_equal(res$table$cdf, mcmc3r::pL(x, tL = 10, p = 0.1, c = 1,
                                          pL = 0.025), tolerance = 1e-8)

  pB <- cal_defaults("B")
  resB <- cal_compute(pB)
  xB <- resB$table$x
  expect_equal(resB$table$density,
               mcmc3r::dB(xB, tL = 10, tU = 20, pL = 0.025, pU = 0.025),
               tolerance = 1e-8)

  pU <- cal_defaults("U")
  resU <- cal_compute(pU)
  xU <- resU$table$x
  expect_equal(resU$table$density,
               mcmc3r::dU(xU, tU = 20, pU = 0.025),
               tolerance = 1e-8)
})

test_that("calibration quantiles match qL/qB/qU", {
  p <- cal_defaults("L")
  res <- cal_compute(p)
  expected <- mcmc3r::qL(c(0.025, 0.5, 0.975), tL = 10, p = 0.1, c = 1,
                         pL = 0.025)
  expect_equal(res$quantiles$quantile, as.numeric(expected), tolerance = 1e-6)

  pB <- cal_defaults("B")
  resB <- cal_compute(pB)
  expect_equal(resB$quantiles$quantile,
               as.numeric(mcmc3r::qB(c(0.025, 0.5, 0.975), tL = 10, tU = 20,
                                     pL = 0.025, pU = 0.025)),
               tolerance = 1e-6)

  pU <- cal_defaults("U")
  resU <- cal_compute(pU)
  expect_equal(resU$quantiles$quantile,
               as.numeric(mcmc3r::qU(c(0.025, 0.5, 0.975), tU = 20,
                                     pU = 0.025)),
               tolerance = 1e-6)
})

test_that("calibration syntax follows MCMCtree notation", {
  expect_identical(cal_compute(cal_defaults("L"))$syntax, "L(10, 0.1, 1, 0.025)")
  expect_identical(cal_compute(cal_defaults("B"))$syntax, "B(10, 20, 0.025, 0.025)")
  expect_identical(cal_compute(cal_defaults("U"))$syntax, "U(20, 0.025)")
})

test_that("validation codes are stable", {
  p <- cal_defaults("L"); p$tL <- 0
  expect_app_error(cal_compute(p), "CAL-001")

  p <- cal_defaults("L"); p$c <- 0
  expect_app_error(cal_compute(p), "CAL-002")

  p <- cal_defaults("L"); p$p <- -1
  expect_app_error(cal_compute(p), "CAL-003")

  p <- cal_defaults("L"); p$pL <- 1
  expect_app_error(cal_compute(p), "CAL-004")

  p <- cal_defaults("B"); p$tU <- 5
  expect_app_error(cal_compute(p), "CAL-005")

  p <- cal_defaults("B"); p$pL <- 0.6; p$pU <- 0.6
  expect_app_error(cal_compute(p), "CAL-006")

  p <- cal_defaults("L"); p$probs <- c(0.0001, 0.5)
  expect_app_error(cal_compute(p), "CAL-007")

  p <- cal_defaults("L"); p$xmax <- -1
  expect_app_error(cal_compute(p), "CAL-008")

  p <- cal_defaults("L"); p$points <- 50
  expect_app_error(cal_compute(p), "CAL-009")
})

test_that("infinite boundary density is clipped and reported (CAL-011)", {
  p <- cal_defaults("L")
  p$pL <- 0.9
  res <- cal_compute(p)
  expect_true(is.na(res$table$density[1]))
  expect_true(any(vapply(res$warnings, function(w) w$code == "CAL-011", logical(1))))
  expect_true(all(is.finite(res$table$density[-1])))
})

test_that("automatic x maximum is positive and finite", {
  res <- cal_compute(cal_defaults("L"))
  expect_true(is.finite(res$xmax))
  expect_true(res$xmax > 10)
  expect_true(res$xmax_auto)
})

test_that("calibration input parsing rejects malformed probabilities", {
  expect_app_error(parse_probs("a, b"), "CAL-007")
  expect_app_error(parse_probs(""), "CAL-007")
  expect_silent(parse_probs("0.025, 0.5, 0.975"))
  expect_app_error(parse_xmax("abc"), "CAL-008")
})
