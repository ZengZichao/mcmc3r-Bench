# End-to-end smoke tests for the key workflows.

find_app_root <- function() {
  candidates <- c(getwd(), file.path(getwd(), ".."), file.path(getwd(), "../.."))
  for (cand in candidates) {
    if (file.exists(file.path(cand, "app.R")) &&
        dir.exists(file.path(cand, "R"))) {
      return(normalizePath(cand))
    }
  }
  stop("Could not locate app root")
}

app_root <- find_app_root()
lib <- file.path(app_root, ".Rlib")
if (dir.exists(lib)) .libPaths(c(lib, .libPaths()))
Sys.setenv(MCMC3R_APP_DIR = app_root)
fixture <- function(name) file.path(app_root, "tests", "fixtures", name)

test_that("key UI workflows work end to end", {
  app <- shinytest2::AppDriver$new(
    app_dir = app_root,
    load_timeout = 90000,
    timeout = 30000,
    name = "mcmc3r-bench"
  )
  on.exit(app$stop(), add = TRUE)

  app$wait_for_idle(timeout = 30000)
  # Normalise persisted preferences in the shared browser profile.
  app$run_js("if (document.documentElement.dataset.theme === 'dark') document.querySelector('#theme-toggle').click();")
  app$run_js("document.querySelector('.lang-btn[data-lang=zh]').click()")
  app$wait_for_idle(timeout = 10000)
  expect_match(app$get_text("#page-calibration h1"), "校准分布探索")

  # Calibration default run
  app$click("calibration-run")
  app$wait_for_idle(timeout = 30000)
  app$wait_for_js(
    "document.querySelector('#calibration-syntax') !== null",
    timeout = 30000
  )
  expect_match(app$get_text("#calibration-syntax"), "L\\(10, 0\\.1, 1, 0\\.025\\)")

  cal_csv <- app$get_download(output = "calibration-download_csv")
  cal_data <- read.csv(cal_csv, check.names = FALSE)
  expect_named(cal_data, c("x", "density", "cdf"))
  expect_equal(nrow(cal_data), 1000)
  cal_png <- app$get_download(output = "calibration-download_png")
  expect_gt(file.size(cal_png), 10000)
  cal_pdf <- app$get_download(output = "calibration-download_pdf")
  expect_gt(file.size(cal_pdf), 10000)
  expect_false(app$get_js("document.querySelector('#calibration-run').disabled"))

  # Language switch changes the static heading and the server-rendered table.
  app$run_js("document.querySelector('.lang-btn[data-lang=zh]').click()")
  app$wait_for_idle(timeout = 10000)
  expect_match(app$get_text("#page-calibration h1"), "校准分布探索")
  app$wait_for_js("document.querySelector('#calibration-syntax') !== null",
                  timeout = 20000)
  expect_match(app$get_text("#calibration-syntax"), "L\\(10, 0\\.1, 1, 0\\.025\\)")
  expect_equal(app$get_value(input = "calibration-tL"), 10)

  # Invalid input produces a stable error code, and the error survives a
  # language switch with translated text.
  app$set_inputs(`calibration-tL` = 0)
  app$click("calibration-run")
  app$wait_for_idle(timeout = 30000)
  app$wait_for_js(
    "document.querySelector('#calibration-result_area').innerText.includes('CAL-001')",
    timeout = 30000
  )
  expect_match(app$get_text("#calibration-result_area"),
               "最小年龄 tL 必须大于 0")
  app$run_js("document.querySelector('.lang-btn[data-lang=en]').click()")
  app$wait_for_idle(timeout = 10000)
  app$wait_for_js(
    "document.querySelector('#calibration-result_area').innerText.includes('The minimum age')",
    timeout = 20000
  )
  expect_match(app$get_text("#calibration-result_area"), "CAL-001")
  expect_match(app$get_text("#calibration-result_area"),
               "The minimum age tL must be greater than 0")
  app$run_js("document.querySelector('.lang-btn[data-lang=zh]').click()")
  app$wait_for_idle(timeout = 10000)

  # MCMC example and summary
  app$run_js("document.querySelector('.nav-btn[data-nav=mcmc]').click()")
  app$click("mcmc-ex_carnivores")
  app$wait_for_idle(timeout = 30000)
  app$click("mcmc-run")
  app$wait_for_idle(timeout = 30000)
  app$wait_for_js(
    "document.querySelector('#mcmc-result_area') && document.querySelector('#mcmc-result_area').innerText.includes('汇总统计')",
    timeout = 30000
  )
  expect_match(app$get_text("#mcmc-result_area"), "汇总统计")
  expect_match(app$get_text("#mcmc-result_area"), "t_n20")

  mcmc_csv <- app$get_download(output = "mcmc-download_csv")
  mcmc_data <- read.csv(mcmc_csv, check.names = FALSE)
  expect_equal(nrow(mcmc_data), 18)
  expect_true("t_n20" %in% mcmc_data$parameter)

  # Upload a BPP file through the real file input and summarise tau_ columns.
  app$upload_file(`mcmc-file` = fixture("mcmc_bpp.txt"))
  app$wait_for_idle(timeout = 30000)
  app$click("mcmc-run")
  app$wait_for_idle(timeout = 30000)
  app$wait_for_js(
    "document.querySelector('#mcmc-result_area') && document.querySelector('#mcmc-result_area').innerText.includes('tau_7OLMXRB')",
    timeout = 30000
  )
  expect_match(app$get_text("#mcmc-result_area"), "tau_7OLMXRB")

  # A file without time columns raises MCMC-003 in the UI.
  app$upload_file(`mcmc-file` = fixture("mcmc_no_time.txt"))
  app$wait_for_idle(timeout = 30000)
  app$click("mcmc-run")
  app$wait_for_idle(timeout = 30000)
  app$wait_for_js(
    "document.querySelector('#mcmc-result_area').innerText.includes('MCMC-003')",
    timeout = 30000
  )
  expect_match(app$get_text("#mcmc-result_area"), "MCMC-003")

  # Marginal likelihood demo
  app$run_js("document.querySelector('.nav-btn[data-nav=marginal]').click()")
  app$upload_file(`marginal-zip` = fixture("ml_wrong_count.zip"))
  app$wait_for_idle(timeout = 30000)
  app$click("marginal-run")
  app$wait_for_idle(timeout = 30000)
  app$wait_for_js(
    "document.querySelector('#marginal-result_area').innerText.includes('ML-004')",
    timeout = 30000
  )
  expect_match(app$get_text("#marginal-result_area"), "ML-004")
  app$click("marginal-demo")
  app$wait_for_idle(timeout = 30000)
  app$click("marginal-run")
  app$wait_for_idle(timeout = 60000)
  app$wait_for_js(
    "document.querySelector('#marginal-result_area') && document.querySelector('#marginal-result_area').innerText.includes('对数边际似然')",
    timeout = 60000
  )
  expect_match(app$get_text("#marginal-result_area"), "对数边际似然")
  expect_false(app$get_js("document.querySelector('#marginal-run').disabled"))

  ml_summary <- app$get_download(output = "marginal-download_summary")
  ml_summary_data <- read.csv(ml_summary, check.names = FALSE)
  expect_true(all(c("logml", "se", "n_beta") %in% names(ml_summary_data)))
  ml_detail <- app$get_download(output = "marginal-download_detail")
  ml_detail_data <- read.csv(ml_detail, check.names = FALSE)
  expect_equal(nrow(ml_detail_data), 5)
  ml_bundle <- app$get_download(output = "marginal-download_bundle")
  bundle_files <- unzip(ml_bundle, list = TRUE)$Name
  expect_true(all(c("marginal_summary.csv", "marginal_detail.csv",
                    "metadata.json") %in% bundle_files))
  ml_png <- app$get_download(output = "marginal-download_png")
  expect_gt(file.size(ml_png), 10000)
  ml_pdf <- app$get_download(output = "marginal-download_pdf")
  expect_gt(file.size(ml_pdf), 10000)

  # Export theme is recorded in the bundle metadata.
  app$set_inputs(`marginal-export_theme` = "screen")
  app$wait_for_idle(timeout = 10000)
  ml_screen_bundle <- app$get_download(output = "marginal-download_bundle")
  meta <- jsonlite::fromJSON(unzip(ml_screen_bundle, files = "metadata.json",
                                   exdir = tempfile()))
  expect_identical(meta$export_theme, "screen")
  expect_true(meta$screen_theme %in% c("light", "dark"))

  # Theme switch preserves the result and updates the html attribute.
  app$run_js("document.querySelector('#theme-toggle').click()")
  app$wait_for_idle(timeout = 10000)
  expect_identical(
    app$get_js("document.documentElement.getAttribute('data-bs-theme')"),
    "dark"
  )
  expect_match(app$get_text("#marginal-result_area"), "对数边际似然")
})

test_that("About page shows version, authorship, licences, and upstream", {
  app <- shinytest2::AppDriver$new(
    app_dir = app_root,
    load_timeout = 90000,
    timeout = 30000,
    name = "mcmc3r-about"
  )
  on.exit(app$stop(), add = TRUE)
  app$wait_for_idle(timeout = 30000)
  app$run_js("document.querySelector('.lang-btn[data-lang=zh]').click()")
  app$wait_for_idle(timeout = 10000)
  app$run_js("document.querySelector('.nav-btn[data-nav=about]').click()")
  app$wait_for_js(
    "document.querySelector('#page-about').innerText.includes('曾子超')",
    timeout = 30000
  )
  about <- app$get_text("#page-about")
  expect_match(about, "v0\\.1\\.0")
  expect_match(about, "0000-0001-6553-970X")
  expect_match(about, "MIT")
  expect_match(about, "CC BY 4\\.0")
  expect_match(about, "0\\.6\\.0")
  expect_match(about, "Mario dos Reis")
  expect_match(about, "非官方")
})

test_that("mobile viewport has no horizontal page overflow", {
  app <- shinytest2::AppDriver$new(
    app_dir = app_root,
    load_timeout = 90000,
    timeout = 30000,
    name = "mcmc3r-mobile"
  )
  on.exit(app$stop(), add = TRUE)
  app$set_window_size(375, 812)
  app$wait_for_idle(timeout = 30000)
  expect_lte(
    app$get_js("document.documentElement.scrollWidth"),
    app$get_js("window.innerWidth") + 1
  )
  app$run_js("document.querySelector('.nav-btn[data-nav=marginal]').click()")
  app$wait_for_idle(timeout = 10000)
  expect_lte(
    app$get_js("document.documentElement.scrollWidth"),
    app$get_js("window.innerWidth") + 1
  )
})

test_that("unsafe ZIP is rejected", {
  app <- shinytest2::AppDriver$new(
    app_dir = app_root,
    load_timeout = 90000,
    timeout = 30000,
    name = "mcmc3r-unsafe-zip"
  )
  on.exit(app$stop(), add = TRUE)
  app$run_js("document.querySelector('.nav-btn[data-nav=marginal]').click()")
  app$upload_file(`marginal-zip` = fixture("unsafe.zip"))
  app$wait_for_idle(timeout = 30000)
  app$click("marginal-run")
  app$wait_for_idle(timeout = 30000)
  app$wait_for_js(
    "document.querySelector('#marginal-result_area') && document.querySelector('#marginal-result_area').innerText.includes('FILE-002')",
    timeout = 30000
  )
  expect_match(app$get_text("#marginal-result_area"), "FILE-002")
})
