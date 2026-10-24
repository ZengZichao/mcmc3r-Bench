# End-to-end theme and language persistence tests.
# These use a fresh Chromote tab because a URL change creates a new Shiny
# session, which AppDriver does not follow.

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

test_that("URL parameters and localStorage control language and theme", {
  app <- shinytest2::AppDriver$new(
    app_dir = app_root,
    load_timeout = 90000,
    timeout = 30000,
    name = "mcmc3r-theme"
  )
  on.exit(app$stop(), add = TRUE)
  app$wait_for_idle(timeout = 30000)
  base <- app$get_url()

  browser <- chromote::ChromoteSession$new()
  on.exit(browser$close(), add = TRUE, after = FALSE)

  js <- function(expr) {
    res <- browser$Runtime$evaluate(expr, returnByValue = TRUE)
    if (!is.null(res$exceptionDetails)) {
      stop("JavaScript error: ", res$exceptionDetails$text)
    }
    res$result$value
  }
  wait_js <- function(expr, timeout = 45) {
    deadline <- Sys.time() + timeout
    repeat {
      value <- tryCatch(js(expr), error = function(e) NULL)
      if (isTRUE(value)) return(invisible(TRUE))
      if (Sys.time() > deadline) stop("Timed out waiting for: ", expr)
      Sys.sleep(0.25)
    }
  }
  open_page <- function(query = "") {
    browser$Page$navigate(paste0(base, query))
    wait_js("document.readyState === 'complete'")
    wait_js("window.Shiny && Shiny.shinyapp && Shiny.shinyapp.isConnected()")
  }

  # Query parameters win over stored values and apply on first render.
  open_page("?lang=zh&theme=dark")
  expect_identical(js("document.documentElement.dataset.theme"), "dark")
  expect_identical(js("document.documentElement.getAttribute('data-bs-theme')"), "dark")
  expect_identical(js("document.documentElement.dataset.lang"), "zh")
  expect_match(js("document.querySelector('#page-calibration h1').innerText"),
               "校准分布探索")

  # Server-rendered results follow the initial language.
  js("document.querySelector('#calibration-run').click()")
  wait_js("document.querySelector('#calibration-syntax') !== null", timeout = 60)
  expect_match(js("document.querySelector('#calibration-syntax').innerText"),
               "L\\(10, 0\\.1, 1, 0\\.025\\)")

  # Change both preferences; they are persisted to localStorage.
  js("document.querySelector('#theme-toggle').click()")
  wait_js("document.documentElement.dataset.theme === 'light'")
  js("document.querySelector('.lang-btn[data-lang=en]').click()")
  wait_js("document.documentElement.dataset.lang === 'en'")
  expect_match(js("document.querySelector('#page-calibration h1').innerText"),
               "Calibration")
  expect_match(js("document.querySelector('#calibration-syntax').innerText"),
               "L\\(10, 0\\.1, 1, 0\\.025\\)")

  # Reloading without query parameters restores the stored preferences.
  open_page()
  expect_identical(js("document.documentElement.dataset.theme"), "light")
  expect_identical(js("document.documentElement.dataset.lang"), "en")
  expect_match(js("document.querySelector('#page-calibration h1').innerText"),
               "Calibration")

  # Explicit parameters override stored preferences without changing them.
  open_page("?theme=dark&lang=zh")
  expect_identical(js("document.documentElement.dataset.theme"), "dark")
  expect_identical(js("document.documentElement.dataset.lang"), "zh")
  open_page()
  expect_identical(js("document.documentElement.dataset.theme"), "light")
  expect_identical(js("document.documentElement.dataset.lang"), "en")

  # Every language/theme combination can complete a calibration run.
  headings <- c(en = "Calibration", zh = "\u6821\u51c6\u5206\u5e03\u63a2\u7d22")
  for (lang in c("en", "zh")) {
    for (theme in c("light", "dark")) {
      open_page(paste0("?lang=", lang, "&theme=", theme))
      expect_identical(js("document.documentElement.dataset.theme"), theme)
      expect_identical(js("document.documentElement.dataset.lang"), lang)
      expect_match(js("document.querySelector('#page-calibration h1').innerText"),
                   headings[[lang]])
      expect_lte(js("document.documentElement.scrollWidth"),
                 js("window.innerWidth") + 1)
      expect_identical(
        js("document.querySelector('.skip-link').getAttribute('href')"),
        "#main"
      )
      expect_true(js("!!document.querySelector('#main')"))
      if (identical(lang, "en") && identical(theme, "light")) {
        # Keyboard activation: focus the run button and press Enter.
        js("document.querySelector('#calibration-run').focus()")
        browser$Input$dispatchKeyEvent(
          type = "rawKeyDown", key = "Enter", code = "Enter",
          windowsVirtualKeyCode = 13, nativeVirtualKeyCode = 13
        )
        browser$Input$dispatchKeyEvent(
          type = "char", key = "Enter", code = "Enter", text = "\r",
          unmodifiedText = "\r", windowsVirtualKeyCode = 13,
          nativeVirtualKeyCode = 13
        )
        browser$Input$dispatchKeyEvent(
          type = "keyUp", key = "Enter", code = "Enter",
          windowsVirtualKeyCode = 13, nativeVirtualKeyCode = 13
        )
      } else {
        js("document.querySelector('#calibration-run').click()")
      }
      wait_js("document.querySelector('#calibration-syntax') !== null",
              timeout = 60)
      expect_match(js("document.querySelector('#calibration-syntax').innerText"),
                   "L\\(10, 0\\.1, 1, 0\\.025\\)")
    }
  }
})
