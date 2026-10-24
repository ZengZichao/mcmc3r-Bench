test_that("beta validation enforces method-specific ranges", {
  expect_silent(ml_beta_validate(mcmc3r::make.beta(5, "step-stones"), "step-stones"))
  expect_silent(ml_beta_validate(mcmc3r::make.beta(5, "gauss-quad"), "gauss-quad"))

  expect_app_error(ml_beta_validate(c(0, 0.5, 1), "step-stones"), "ML-002")
  expect_app_error(ml_beta_validate(c(0, 0.5), "gauss-quad"), "ML-002")
  expect_app_error(ml_beta_validate(c(0.5, 0.5), "step-stones"), "ML-003")
  expect_app_error(ml_beta_validate(c("a", "b"), "step-stones"), "ML-001")
})

test_that("Gauss-Legendre beta must match the n-point rule", {
  beta <- mcmc3r::make.beta(5, "gauss-quad")
  bad <- beta
  bad[3] <- bad[3] + 0.01
  expect_app_error(ml_beta_validate(bad, "gauss-quad"), "ML-009")
})

test_that("beta generation limits are enforced", {
  beta <- ml_beta_generate(5, "step-stones", 5)
  expect_length(beta, 5)
  expect_equal(beta, mcmc3r::make.beta(5, "step-stones", 5))
  expect_app_error(ml_beta_generate(51, "step-stones"), "ML-011")
  expect_app_error(ml_beta_generate(300, "gauss-quad"), "ML-008")
  expect_app_error(ml_beta_generate(5, "step-stones", a = -1), "ML-011")
})

test_that("ZIP structure is detected safely", {
  st <- zip_structure(fixture("ml_demo.zip"))
  expect_equal(st$n, 5L)
  expect_identical(st$root, "")
  expect_app_error(zip_structure(fixture("unsafe.zip")), "FILE-002")
})

test_that("beta count mismatch is rejected before calculation", {
  session <- new_session_dir()
  withr::defer(unlink(session, recursive = TRUE), envir = parent.frame())
  expect_app_error(
    ml_prepare_zip(fixture("ml_wrong_count.zip"), session, "step-stones"),
    "ML-004"
  )
})

test_that("stepping-stones demo matches the direct upstream call", {
  session <- new_session_dir()
  withr::defer(unlink(session, recursive = TRUE), envir = parent.frame())
  prep <- ml_prepare_zip(fixture("ml_demo.zip"), session, "step-stones")
  expect_equal(prep$n, 5L)
  expect_equal(prep$beta_converted, 1L)
  expect_true(all(prep$chain_rows == 200L))

  exec <- ml_execute(prep$run_dir, "step-stones")
  direct <- withr::with_dir(prep$run_dir, {
    suppressWarnings(mcmc3r::stepping.stones("mcmc.txt", "beta.txt", TRUE))
  })
  expect_equal(exec$logml, direct$logml, tolerance = 1e-10)
  expect_equal(exec$mean.logl, direct$mean.logl, tolerance = 1e-10)
  expect_true(is.finite(exec$se))

  result <- ml_result_object(prep, exec, "step-stones", "demo", "light")
  expect_equal(result$n_beta, 5L)
  expect_equal(result$model_name, "demo")
  expect_equal(result$app_version, "0.1.0")
  expect_true(sum(result$per_beta$se_warning) <= 1)
  if (any(result$per_beta$se_warning)) {
    expect_true(result$per_beta$beta[result$per_beta$se_warning][1] > 0.3)
  }
})

test_that("individual chain files work and match the direct upstream call", {
  session <- new_session_dir()
  withr::defer(unlink(session, recursive = TRUE), envir = parent.frame())
  tmp <- withr::local_tempdir()
  utils::unzip(fixture("ml_demo.zip"), exdir = tmp)
  paths <- file.path(tmp, paste0(1:5, "/mcmc.txt"))
  beta <- ml_beta_read_file(file.path(tmp, "beta.txt"))
  prep <- ml_prepare_files(paths, beta, session, "step-stones")
  expect_equal(prep$n, 5L)
  expect_true(all(file.exists(file.path(prep$run_dir, paste0(1:5, "/mcmc.txt")))))
  exec <- ml_execute(prep$run_dir, "step-stones")
  direct <- withr::with_dir(prep$run_dir, {
    suppressWarnings(mcmc3r::stepping.stones("mcmc.txt", "beta.txt", TRUE))
  })
  expect_equal(exec$logml, direct$logml, tolerance = 1e-10)
})

test_that("Gauss-Legendre demo matches the direct upstream call", {
  session <- new_session_dir()
  withr::defer(unlink(session, recursive = TRUE), envir = parent.frame())
  prep <- ml_prepare_zip(fixture("ml_gauss_demo.zip"), session, "gauss-quad")
  expect_equal(prep$n, 5L)
  exec <- ml_execute(prep$run_dir, "gauss-quad")
  direct <- withr::with_dir(prep$run_dir, {
    suppressWarnings(mcmc3r::gauss.quad("mcmc.txt", "beta.txt", TRUE))
  })
  expect_equal(exec$logml, direct$logml, tolerance = 1e-10)
  expect_true(is.finite(exec$logml))
})

test_that("lnL validation returns ML-005, ML-006, and ML-007", {
  tmp <- withr::local_tempdir()
  no_lnl <- file.path(tmp, "no_lnl.txt")
  writeLines(c("Iteration t_1", "1 10", "2 11"), no_lnl)
  expect_app_error(ml_read_lnl(no_lnl), "ML-005")

  with_na <- file.path(tmp, "with_na.txt")
  writeLines(c("lnL", "-1", "NA", "-2"), with_na)
  expect_app_error(ml_read_lnl(with_na), "ML-006")

  one_row <- file.path(tmp, "one_row.txt")
  writeLines(c("lnL", "-1"), one_row)
  expect_app_error(ml_read_lnl(one_row), "ML-007")
})

test_that("beta files are read strictly", {
  beta <- ml_beta_read_file(fixture("beta_with_one.txt"))
  expect_equal(beta, c(0, 0.1, 0.5, 1))
  expect_app_error(ml_beta_validate(beta, "step-stones"), "ML-002")

  tmp <- withr::local_tempdir()
  header <- file.path(tmp, "beta_header.txt")
  writeLines(c("beta", "0.1", "0.5"), header)
  expect_app_error(ml_beta_read_file(header), "ML-001")
})

test_that("method helpers map labels and limits", {
  expect_identical(ml_method_label_key("gauss-quad"), "ml.method.gq")
  expect_identical(ml_method_label_key("step-stones"), "ml.method.ss")
  expect_identical(ml_beta_limits("gauss-quad"), LIMITS$beta_max_gq)
  expect_identical(ml_beta_limits("step-stones"), LIMITS$beta_max_ss)

  beta <- ml_beta_generate(5, "gauss-quad")
  expect_length(beta, 5)
  expect_equal(beta, mcmc3r::make.beta(5, "gauss-quad"))
  expect_app_error(ml_beta_generate(0, "step-stones"), "ML-011")
  expect_app_error(ml_beta_generate(2.5, "step-stones"), "ML-011")
  expect_app_error(ml_beta_validate(seq(0.001, 0.999, length.out = 257),
                                    "gauss-quad"), "ML-008")
})

test_that("beta zero conversion is recorded when writing", {
  tmp <- withr::local_tempdir()
  converted <- ml_write_beta(tmp, c(0, 0.2, 1), "step-stones")
  expect_identical(converted, 1L)
  written <- as.numeric(readLines(file.path(tmp, "beta.txt")))
  expect_gt(written[1], 0)
  expect_lt(written[1], 1e-299)
  expect_equal(written[2:3], c(0.2, 1))

  gauss <- ml_write_beta(tmp, c(0.1, 0.5), "gauss-quad")
  expect_identical(gauss, 0L)
})

test_that("file chains require matching counts and a bounded number", {
  session <- new_session_dir()
  withr::defer(unlink(session, recursive = TRUE), envir = parent.frame())
  tmp <- withr::local_tempdir()
  paths <- file.path(tmp, paste0("chain-", 1:3, ".txt"))
  for (p in paths) writeLines(c("lnL", "-1", "-2"), p)

  expect_app_error(
    ml_prepare_files(paths[1:2], c(0.1, 0.5, 0.9), session, "step-stones"),
    "ML-004"
  )

  many <- file.path(tmp, paste0("chain-", 1:(LIMITS$chains_max + 1), ".txt"))
  expect_app_error(
    ml_prepare_files(
      many,
      mcmc3r::make.beta(length(many), "gauss-quad"),
      session, "gauss-quad"
    ),
    "FILE-004"
  )
})

test_that("upstream failures map to ML-010", {
  session <- new_session_dir()
  withr::defer(unlink(session, recursive = TRUE), envir = parent.frame())
  bad <- file.path(session, "does-not-exist")
  expect_app_error(ml_execute(bad, "step-stones"), "ML-010")
})

test_that("result object falls back to upstream beta values and flags warnings", {
  prep <- list(
    n = 2L,
    beta_original = c(0.1, 0.5, 0.9),
    beta_converted = 0L,
    source = "files",
    chain_rows = c(2L, 2L)
  )
  exec <- list(
    logml = -10,
    se = 0.2,
    mean.logl = c(-1, -2),
    b = c(0.1, 0.5),
    warnings = c("b = 0.5SE is unreliable", "b = 0.12 also mentioned"),
    elapsed_ms = 5
  )
  result <- ml_result_object(prep, exec, "step-stones", "demo", "dark", "zh")
  expect_equal(result$per_beta$beta, c(0.1, 0.5))
  expect_identical(result$per_beta$se_warning, c(FALSE, TRUE))
  expect_identical(result$screen_theme, "dark")
  expect_identical(result$lang, "zh")
  expect_false(result$se_reliable)
})

test_that("demo archive is deterministic and runnable", {
  session <- new_session_dir()
  withr::defer(unlink(session, recursive = TRUE), envir = parent.frame())
  zipfile <- ml_demo_zip(session, n = 3, rows = 40, seed = 42)
  expect_true(file.exists(zipfile))
  structure <- zip_structure(zipfile)
  expect_equal(structure$n, 3L)

  prep <- ml_prepare_zip(zipfile, session, "step-stones")
  expect_equal(prep$n, 3L)
  expect_true(all(prep$chain_rows == 40L))
  exec <- ml_execute(prep$run_dir, "step-stones")
  expect_true(is.finite(exec$logml))
})

test_that("a single outer ZIP folder is detected", {
  session <- new_session_dir()
  withr::defer(unlink(session, recursive = TRUE), envir = parent.frame())
  tmp <- withr::local_tempdir()
  utils::unzip(fixture("ml_demo.zip"), exdir = tmp)
  dir.create(file.path(tmp, "outer"))
  entries <- c("beta.txt", paste0(1:5, "/mcmc.txt"))
  for (entry in entries) {
    dest <- file.path(tmp, "outer", entry)
    dir.create(dirname(dest), recursive = TRUE, showWarnings = FALSE)
    file.rename(file.path(tmp, entry), dest)
  }
  zipfile <- file.path(tmp, "outer.zip")
  old <- getwd()
  on.exit(setwd(old), add = TRUE)
  setwd(tmp)
  zip::zip(zipfile, files = "outer", mode = "mirror")

  structure <- zip_structure(zipfile)
  expect_identical(structure$root, "outer")
  expect_equal(structure$n, 5L)
  prep <- ml_prepare_zip(zipfile, session, "step-stones")
  expect_equal(prep$zip_root, "outer")
  expect_true(all(prep$chain_rows == 200L))
})

