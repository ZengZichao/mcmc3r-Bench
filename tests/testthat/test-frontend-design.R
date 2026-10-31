# Frontend design gates ---------------------------------------------------
# These assertions exist because the R-side unit tests never read www/css, so
# every layout, token and breakpoint regression used to ship green.

chrome_available <- function() {
  tryCatch({
    chromote::find_chrome()
    TRUE
  }, error = function(e) FALSE)
}

# K1: the sticky run row must stay clickable across the whole desktop range.
test_that("the run button is reachable at every desktop width", {
  skip_if_not(chrome_available(), "Chrome not available")

  app <- shinytest2::AppDriver$new(
    app_dir = testthat::test_path(".", "..", ".."),
    name = "frontend-widths",
    load_timeout = 90 * 1000,
    timeout = 90 * 1000
  )
  on.exit(app$stop(), add = TRUE, after = FALSE)
  app$wait_for_idle(timeout = 60000)
  base <- app$get_url()

  browser <- chromote::ChromoteSession$new()
  on.exit(try(browser$close(), silent = TRUE), add = TRUE, after = FALSE)

  js <- function(expr) {
    res <- browser$Runtime$evaluate(expr, returnByValue = TRUE)
    if (!is.null(res$exceptionDetails)) {
      stop("JavaScript error: ", res$exceptionDetails$text)
    }
    res$result$value
  }

  # 901-1068px is where the sub-nav stays visible while the run row used to be
  # pinned using the sub-nav-hidden offset, which hid the primary action.
  probe <- paste(
    "(function(){",
    "window.scrollTo(0, 900);",
    "var page = document.querySelector('.page-section:not([hidden])');",
    "var rr = page && page.querySelector('.run-row');",
    "if (!rr) return JSON.stringify({ skip: true });",
    "var sn = document.querySelector('.sub-nav');",
    "var btn = rr.querySelector('button');",
    "var b = btn.getBoundingClientRect();",
    "var hit = document.elementFromPoint(Math.round(b.left + b.width / 2),",
    "                                    Math.round(b.top + b.height / 2));",
    "return JSON.stringify({",
    "  width: window.innerWidth,",
    "  subnavBottom: sn.getBoundingClientRect().bottom,",
    "  runRowTop: rr.getBoundingClientRect().top,",
    "  clickable: !!(hit && (hit === btn || btn.contains(hit)))",
    "});})()"
  )

  for (width in c(901, 950, 1000, 1068, 1200, 1440)) {
    browser$Emulation$setDeviceMetricsOverride(
      width = width, height = 900, deviceScaleFactor = 1, mobile = FALSE
    )
    browser$Page$navigate(paste0(base, "?lang=zh&theme=light"))
    Sys.sleep(3)
    raw <- jsonlite::fromJSON(js(probe))
    if (isTRUE(raw$skip)) next
    expect_gte(as.numeric(raw$runRowTop), as.numeric(raw$subnavBottom))
    expect_true(isTRUE(raw$clickable), info = paste("width", width))
  }
})

# K2: the CSS palette and the R palette must not drift, and the pairs the
# interface actually renders must clear contrast. R/fct_theme.R is the source of
# truth; app.css is checked to carry the same value in the same theme block.
test_that("app.css tokens match R/fct_theme.R and meet contrast", {
  root <- testthat::test_path(".", "..", "..")
  source(file.path(root, "R", "fct_theme.R"))
  css <- paste(readLines(file.path(root, "www", "css", "app.css"),
                         encoding = "UTF-8", warn = FALSE), collapse = "\n")

  dark_at <- regexpr('[data-bs-theme="dark"]', css, fixed = TRUE)
  light_block <- substring(css, 1, dark_at - 1)
  dark_block <- substring(css, dark_at)

  hex_rgb <- function(x) {
    x <- tolower(sub("^#", "", x))
    strtoi(substring(x, c(1, 3, 5), c(2, 4, 6)), 16L) / 255
  }
  lum <- function(v) sum(c(0.2126, 0.7152, 0.0722) *
                           ifelse(v <= 0.03928, v / 12.92,
                                  ((v + 0.055) / 1.055)^2.4))
  ratio <- function(a, b) {
    la <- lum(hex_rgb(a))
    lb <- lum(hex_rgb(b))
    (max(la, lb) + 0.05) / (min(la, lb) + 0.05)
  }
  declared_in <- function(block, token, value) {
    grepl(paste0("--", token, ":", "[[:space:]]*", value, ";"),
          block, ignore.case = TRUE)
  }
  token_value <- function(block, token) {
    m <- regexpr(paste0("--", token, ":[[:space:]]*#[0-9a-fA-F]{3,8}"), block)
    if (m < 0) return(NA_character_)
    sub("^.*:[[:space:]]*", "", regmatches(block, m))
  }

  # R/fct_theme.R names -> the CSS custom property that carries them.
  pairs <- list(
    bg = "bg", surface = "surface", surface2 = "surface-2", text = "text",
    text_muted = "text-muted", primary = "primary",
    primary_soft = "primary-soft", on_primary = "on-primary",
    danger = "danger", danger_soft = "danger-soft", ok = "ok",
    accent = "accent", accent_ink = "accent-ink", border = "border",
    divider = "divider", focus = "focus"
  )

  for (mode in c("light", "dark")) {
    tk <- theme_tokens(mode)
    block <- if (mode == "light") light_block else dark_block
    for (name in names(pairs)) {
      expect_true(declared_in(block, pairs[[name]], tk[[name]]),
                  info = paste(mode, name, tk[[name]], pairs[[name]]))
    }
    expect_gte(ratio(tk$text, tk$surface), 7)
    expect_gte(ratio(tk$text_muted, tk$surface), 4.5)
    expect_gte(ratio(tk$text, tk$primary_soft), 4.5)
    expect_gte(ratio(tk$text, tk$danger_soft), 4.5)
    expect_gte(ratio(tk$on_primary, tk$primary), 4.5)
  }

  # Light panels must not borrow the dark theme's fill: that is what turned
  # every empty state into a black card on a white page.
  tile_light <- token_value(light_block, "tile-1")
  expect_false(is.na(tile_light), info = "light --tile-1 missing")
  expect_gte(ratio(tile_light, "#000000"), 15)

  # Boundaries that identify a control need 3:1 against their surface.
  lt <- theme_tokens("light")
  dk <- theme_tokens("dark")
  bs_light <- token_value(light_block, "border-strong")
  bs_dark <- token_value(dark_block, "border-strong")
  expect_false(is.na(bs_light), info = "light --border-strong missing")
  expect_gte(ratio(bs_light, lt$surface), 3)
  expect_gte(ratio(bs_dark, dk$surface), 3)

  # Tile text has to be readable on the tile, in both themes.
  expect_gte(ratio(token_value(light_block, "tile-fg"), tile_light), 4.5)
  expect_gte(ratio(token_value(dark_block, "tile-fg"),
                   token_value(dark_block, "tile-1")), 4.5)
})

# K3: no translation key may go unreferenced.
test_that("translation table has no unreferenced keys", {
  root <- testthat::test_path(".", "..", "..")
  rows <- read.csv(file.path(root, "i18n", "translations.csv"),
                   stringsAsFactors = FALSE, encoding = "UTF-8")
  sources <- c(
    list.files(file.path(root, "R"), full.names = TRUE, pattern = "[.]R$"),
    file.path(root, "www", "js", "app.js"),
    list.files(file.path(root, "dev"), full.names = TRUE, pattern = "[.]R$"),
    list.files(testthat::test_path("."), full.names = TRUE, pattern = "[.]R$"),
    file.path(root, "app.R"), file.path(root, "global.R")
  )
  blob <- paste(vapply(sources, function(f)
    paste(readLines(f, encoding = "UTF-8", warn = FALSE), collapse = "\n"),
    character(1)), collapse = "\n")

  # These families are assembled at runtime, e.g. paste0("err.", code).
  dynamic_prefixes <- c("err.", "hint.", "cal.type.", "plot.params.", "nav.")
  referenced <- vapply(rows$key, function(k) {
    if (any(startsWith(k, dynamic_prefixes))) return(TRUE)
    grepl(paste0('"', k, '"'), blob, fixed = TRUE) ||
      grepl(paste0("'", k, "'"), blob, fixed = TRUE)
  }, logical(1))
  expect_true(all(referenced),
              info = paste("unreferenced:",
                           paste(rows$key[!referenced], collapse = ", ")))
})

# K4: a declared design token must actually be consumed. Tokens that exist only
# in the stylesheet are how the palette and the implementation drift apart.
test_that("app.css declares no unreferenced design tokens", {
  root <- testthat::test_path(".", "..", "..")
  read_all <- function(f) paste(readLines(f, encoding = "UTF-8", warn = FALSE),
                                collapse = "\n")
  css <- read_all(file.path(root, "www", "css", "app.css"))
  consumers <- c(
    file.path(root, "www", "css", "print.css"),
    file.path(root, "www", "js", "app.js"),
    list.files(file.path(root, "R"), full.names = TRUE, pattern = "[.]R$")
  )
  blob <- paste(vapply(consumers, read_all, character(1)), collapse = "\n")

  declared <- unique(regmatches(css, gregexpr("--[a-zA-Z0-9-]+(?=:[[:space:]])",
                                               css, perl = TRUE))[[1]])
  used <- unique(regmatches(css, gregexpr("var\\(([[:space:]]*--[a-zA-Z0-9-]+)",
                                          css))[[1]])
  used <- sub("^var\\([[:space:]]*", "", used)
  # --bs-* tokens are consumed by Bootstrap/bslib, not by this stylesheet.
  orphans <- setdiff(declared, used)
  orphans <- orphans[!startsWith(orphans, "--bs-")]
  # --plot-grid is a chart gridline colour: it is consumed by ggplot through
  # theme_tokens(), never by a CSS rule, so it cannot appear in a var().
  orphans <- setdiff(orphans, "--plot-grid")
  expect_equal(orphans, character())
})

# K5: !important is reserved for overriding third-party stylesheets (DT,
# Bootstrap, bslib). The current figure was established by removing every
# DataTables-layer !important and re-measuring computed styles; only the two
# declarations that actually regress are kept forced. Do not let this grow.
test_that("the !important budget does not regress", {
  ceiling <- 70
  css <- paste(readLines(file.path(testthat::test_path(".", "..", ".."),
                                   "www", "css", "app.css"),
                         encoding = "UTF-8", warn = FALSE), collapse = "\n")
  n <- length(regmatches(css, gregexpr("!important", css))[[1]])
  expect_lte(n, ceiling)
})
