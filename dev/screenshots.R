#!/usr/bin/env Rscript
# Capture the 2 language x 2 theme x 2 viewport screenshot matrix from a
# running local app. Start the app on port 3848 first, or point
# MCMC3R_SCREENSHOT_URL at wherever it actually runs.
#
# Every capture is verified before it is written. An earlier version navigated
# to a port that was not serving, screenshotted Chrome's "connection refused"
# page eight times, reported success, and the results shipped in the README.

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

probe_value <- function(session, expr) {
  res <- session$Runtime$evaluate(expr, returnByValue = TRUE)
  if (!is.null(res$exceptionDetails)) {
    stop("page probe failed: ", res$exceptionDetails$text, call. = FALSE)
  }
  res$result$value
}

# Wait for the app rather than sleeping a fixed number of seconds.
wait_for_app <- function(session, url, timeout = 60) {
  session$Page$navigate(url)
  deadline <- Sys.time() + timeout
  repeat {
    ready <- tryCatch(
      probe_value(session, paste0(
        "(function(){var b=document.querySelector('#calibration-run');",
        "return b ? document.title : '';})()"
      )),
      error = function(e) ""
    )
    if (length(ready) == 1 && nzchar(ready) &&
        grepl("mcmc3r", ready, ignore.case = TRUE)) return(invisible(TRUE))
    if (Sys.time() > deadline) {
      stop("no mcmc3r Bench page at ", url,
           " within ", timeout, "s - is the app running and is ",
           "MCMC3R_SCREENSHOT_URL pointing at it?", call. = FALSE)
    }
    Sys.sleep(0.5)
  }
}

assert_rendered_plot <- function(session, timeout = 60) {
  deadline <- Sys.time() + timeout
  repeat {
    state <- probe_value(session, paste0(
      "(function(){var i=document.querySelector('#calibration-plot img');",
      "if(!i) return 'pending';",
      "return (i.naturalWidth>100 && i.src.indexOf('data:image/')===0)",
      "  ? 'ok' : 'pending';})()"
    ))
    if (identical(state, "ok")) return(invisible(TRUE))
    if (Sys.time() > deadline) {
      stop("the calibration plot never rendered (last state: ", state, ")",
           call. = FALSE)
    }
    Sys.sleep(0.5)
  }
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
  wait_for_app(session, url)

  # The README shot is meant to show results, not the empty state.
  probe_value(session,
    "document.querySelector('#calibration-run').click(); 'clicked'"
  )
  assert_rendered_plot(session)

  shot <- session$Page$captureScreenshot(
    format = "png", captureBeyondViewport = width > 500
  )
  path <- file.path(dir, paste0(label, ".png"))
  raw <- base64enc::base64decode(shot$data)
  writeBin(raw, path)

  # A browser error page is a valid PNG too, so check it is not one: the app's
  # own chrome is dark, and the error page is almost pure white.
  bytes <- as.integer(raw)
  dark <- sum(bytes > 0 & bytes < 90) / length(bytes)
  if (file.size(path) < 20000 || dark < 0.02) {
    stop("screenshot for ", lang, "/", theme, " (", label, ") looks like a ",
         "blank or error page: ", file.size(path), " bytes, ",
         round(dark * 100, 2), "% dark pixels", call. = FALSE)
  }
  cat(sprintf("Wrote %s (%d bytes, %.1f%% dark)\n", path, file.size(path),
              dark * 100))
  invisible(path)
}

written <- character(0)
for (lang in c("en", "zh")) {
  for (theme in c("light", "dark")) {
    written <- c(written,
                 capture_combo(lang, theme, 1440, 900, "desktop"),
                 capture_combo(lang, theme, 375, 812, "mobile"))
  }
}

# The eight shots differ in language, theme and viewport. Identical files mean
# the harness captured the same fallback page every time.
digests <- vapply(written, function(p)
  digest::digest(readBin(p, what = "raw", n = file.size(p)), algo = "sha1",
                 serialize = FALSE),
  character(1), USE.NAMES = FALSE)
if (any(duplicated(digests))) {
  stop("duplicate screenshots: ",
       paste(basename(dirname(written[duplicated(digests)])), collapse = ", "),
       " - the matrix did not vary, so something is not rendering",
       call. = FALSE)
}
cat("Screenshot matrix complete: ", length(written), " distinct captures.\n",
    sep = "")
