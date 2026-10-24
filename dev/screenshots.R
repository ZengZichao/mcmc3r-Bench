#!/usr/bin/env Rscript
# Capture the 2 language x 2 theme x 2 viewport screenshot matrix from a
# running local app. Start the app on port 3848 first.

args <- commandArgs(trailingOnly = FALSE)
file_arg <- sub("^--file=", "", args[grepl("^--file=", args)])
root <- if (length(file_arg)) dirname(dirname(normalizePath(file_arg))) else normalizePath(".")
lib <- file.path(root, ".Rlib")
if (dir.exists(lib)) .libPaths(c(lib, .libPaths()))

base_url <- Sys.getenv("MCMC3R_SCREENSHOT_URL", "http://127.0.0.1:3848/")
out_root <- file.path(root, "docs", "assets", "screenshots")

if (!requireNamespace("chromote", quietly = TRUE)) {
  stop("chromote is required to capture screenshots.")
}

capture_combo <- function(lang, theme, width, height, label) {
  dir <- file.path(out_root, paste0(lang, "-", theme))
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  session <- chromote::ChromoteSession$new()
  on.exit(session$close(), add = TRUE)
  session$Emulation$setDeviceMetricsOverride(
    width = width, height = height, deviceScaleFactor = 1,
    mobile = width <= 500
  )
  url <- paste0(base_url, "?lang=", lang, "&theme=", theme,
                "&screenshot=", label)
  session$Page$navigate(url)
  Sys.sleep(4)
  session$Runtime$evaluate(
    "document.querySelector('#calibration-run').click(); 'clicked'",
    returnByValue = TRUE
  )
  Sys.sleep(4)
  shot <- session$Page$captureScreenshot(
    format = "png", captureBeyondViewport = width > 500
  )
  path <- file.path(dir, paste0(label, ".png"))
  writeBin(base64enc::base64decode(shot$data), path)
  cat("Wrote", path, "\n")
  invisible(path)
}

for (lang in c("en", "zh")) {
  for (theme in c("light", "dark")) {
    capture_combo(lang, theme, 1440, 900, "desktop")
    capture_combo(lang, theme, 375, 812, "mobile")
  }
}
cat("Screenshot matrix complete.\n")
