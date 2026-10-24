test_that("unsafe ZIP entries are rejected before extraction", {
  expect_app_error(zip_structure(fixture("unsafe.zip")), "FILE-002")
  expect_app_error(validate_zip_entries(fixture("unsafe.zip")), "FILE-002")
})

test_that("ZIP structure accepts one optional outer directory", {
  tmp <- withr::local_tempdir()
  dir.create(file.path(tmp, "demo"))
  dir.create(file.path(tmp, "demo", "1"))
  writeLines(c("0", "0.5"), file.path(tmp, "demo", "beta.txt"))
  writeLines(c("lnL", "-1", "-2"), file.path(tmp, "demo", "1", "mcmc.txt"))
  z <- file.path(tmp, "outer.zip")
  withr::with_dir(tmp, zip::zip(zipfile = z, files = c("demo/beta.txt", "demo/1/mcmc.txt"), mode = "mirror"))
  st <- zip_structure(z)
  expect_identical(st$root, "demo")
  expect_equal(st$n, 1L)
})

test_that("ZIP with too many files is rejected", {
  tmp <- withr::local_tempdir()
  dir.create(file.path(tmp, "many"))
  for (i in seq_len(LIMITS$zip_files + 1)) {
    writeLines("x", file.path(tmp, "many", sprintf("f%04d.txt", i)))
  }
  z <- file.path(tmp, "many.zip")
  withr::with_dir(tmp, zip::zip(zipfile = z, files = "many", mode = "mirror"))
  expect_app_error(validate_zip_entries(z), "FILE-004")
})

test_that("highly compressible ZIP is rejected as a bomb", {
  tmp <- withr::local_tempdir()
  big <- file.path(tmp, "zeros.txt")
  writeBin(rep(as.raw(0), 3 * 1024 * 1024), big)
  z <- file.path(tmp, "bomb.zip")
  withr::with_dir(tmp, zip::zip(zipfile = z, files = "zeros.txt", mode = "mirror"))
  expect_app_error(validate_zip_entries(z), "FILE-004")
})

test_that("table parsing detects separators and rejects duplicates", {
  expect_identical(detect_separator(fixture("mcmc_mcmctree.txt")), "\t")
  expect_identical(detect_separator(fixture("mcmc_no_time.txt")), "")
  parsed <- mcmc_read(fixture("mcmc_bpp.txt"))
  expect_true(is.data.frame(parsed$data))
  expect_gt(nrow(parsed$data), 0)
  expect_app_error(mcmc_read(fixture("mcmc_dupcols.txt")), "MCMC-006")
  expect_app_error(mcmc_read(fixture("mcmc_empty.txt")), "MCMC-002")
})

test_that("preview data frames are safe for DT", {
  df <- data.frame(a = 1:5, b = letters[1:5])
  p <- preview_df(df, max_cols = 1, max_rows = 3)
  expect_equal(dim(p), c(3L, 1L))
  expect_true(all(vapply(p, is.character, logical(1))))
})

test_that("uploaded files are copied to sanitised session paths", {
  session <- new_session_dir()
  withr::defer(unlink(session, recursive = TRUE), envir = parent.frame())
  src <- fixture("mcmc_no_time.txt")
  dest <- stash_upload(src, "../../unsafe name.txt", session, prefix = "test")
  expect_true(file.exists(dest))
  expect_false(grepl("unsafe name", dest, fixed = TRUE))
  expect_true(startsWith(dest, session))
})
