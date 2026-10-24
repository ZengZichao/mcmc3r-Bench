test_that("app errors carry stable codes and message keys", {
  err <- app_error("validation", "CAL-001", detail = "tL=0",
                   context = list(module = "calibration"))
  expect_s3_class(err, "app_error")
  expect_s3_class(err, "error")
  expect_identical(err$code, "CAL-001")
  expect_identical(err$message_key, "err.CAL-001")
  expect_identical(err$hint_key, "hint.CAL-001")
  expect_identical(app_error_message(err, "en"),
                   "The minimum age tL must be greater than 0.")
  expect_identical(app_error_message(err, "zh"),
                   "最小年龄 tL 必须大于 0。")
})

test_that("unknown errors map to system codes", {
  expect_identical(as_app_error(simpleError("boom"))$code, "SYS-001")
  expect_identical(
    as_app_error(simpleError("cannot allocate vector of size 2 Gb"))$code,
    "SYS-002"
  )
  expect_identical(
    as_app_error(simpleError("time limit reached"))$code,
    "SYS-003"
  )
})

test_that("diagnostics are sanitised and exclude file contents", {
  err <- app_error("input", "MCMC-003",
                   detail = paste0("columns=a,b\nsecond line\twith tab"),
                   context = list(module = "mcmc", rows = 10))
  diag <- app_error_diagnostics(err, module = "mcmc")
  expect_false(grepl("\n", diag))
  expect_false(grepl("\t", diag))
  expect_match(diag, "code=MCMC-003")
  expect_match(diag, "module=mcmc")
  expect_match(diag, "app_version=0.1.0")
})

test_that("error UI contains the code, message, hint, and copy button", {
  err <- app_error("validation", "CAL-005")
  html <- as.character(app_error_ui(err, "en", module = "calibration"))
  expect_match(html, "CAL-005")
  expect_match(html, "data-copy-text")
  expect_match(html, "Open help")
  expect_match(html, "github.com/ZengZichao/mcmc3r-Bench/issues")
})

test_that("stop_app raises a catchable app_error", {
  caught <- tryCatch(
    stop_app("validation", "CAL-009"),
    app_error = function(e) e
  )
  expect_s3_class(caught, "app_error")
  expect_identical(caught$code, "CAL-009")
})

test_that("slow runs keep their result and gain a SYS-003 warning", {
  warnings <- list(list(code = "CAL-011"))
  expect_identical(append_slow_warning(warnings, 1000), warnings)
  slow <- append_slow_warning(warnings, 90000)
  expect_length(slow, 2)
  expect_identical(slow[[2]]$code, "SYS-003")
  expect_match(slow[[2]]$detail, "soft_limit_ms=60000")
  expect_identical(append_slow_warning(list(), NA_real_), list())
})
