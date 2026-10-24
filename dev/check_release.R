#!/usr/bin/env Rscript
# Verify version, author, licence, citation, documentation, and screenshot
# consistency before a release or deployment.

args <- commandArgs(trailingOnly = FALSE)
file_arg <- sub("^--file=", "", args[grepl("^--file=", args)])
root <- if (length(file_arg)) dirname(dirname(normalizePath(file_arg))) else normalizePath(".")

errors <- character()
add <- function(condition, message) {
  if (!isTRUE(condition)) errors <<- c(errors, message)
}

version <- trimws(readLines(file.path(root, "VERSION"), warn = FALSE)[1])
add(identical(version, "0.1.0"), "VERSION must be 0.1.0 for this release")

meta_text <- paste(readLines(file.path(root, "R", "app_meta.R"), warn = FALSE),
                   collapse = "\n")
add(grepl('APP_VERSION <- "0.1.0"', meta_text, fixed = TRUE),
    "R/app_meta.R APP_VERSION is not 0.1.0")
add(grepl("f6a8f78bc55a53b724118480b6fbfbc71d3b0897", meta_text, fixed = TRUE),
    "upstream SHA is not pinned in R/app_meta.R")
add(grepl("zengzichao@sjtu.edu.cn", meta_text, fixed = TRUE),
    "author email missing from R/app_meta.R")
add(grepl("0000-0001-6553-970X", meta_text, fixed = TRUE),
    "ORCID missing from R/app_meta.R")

citation <- paste(readLines(file.path(root, "CITATION.cff"), warn = FALSE),
                  collapse = "\n")
add(grepl(paste0("version: ", version), citation, fixed = TRUE),
    "CITATION.cff version does not match VERSION")
add(grepl("Zeng", citation, fixed = TRUE), "CITATION.cff author missing")
add(grepl("0000-0001-6553-970X", citation, fixed = TRUE),
    "CITATION.cff ORCID missing")

license <- paste(readLines(file.path(root, "LICENSE"), warn = FALSE), collapse = "\n")
add(grepl("MIT License", license, fixed = TRUE), "LICENSE is not MIT")
add(grepl("Zeng Zichao", license, fixed = TRUE), "LICENSE copyright holder missing")

notice <- paste(readLines(file.path(root, "NOTICE"), warn = FALSE), collapse = "\n")
for (needle in c("mcmc3r", "Mario dos Reis", "Sandra Alvarez-Carretero",
                 "unofficial", "CC BY 4.0")) {
  add(grepl(needle, notice, fixed = TRUE),
      paste0("NOTICE missing: ", needle))
}

third <- paste(readLines(file.path(root, "THIRD_PARTY_LICENSES.md"),
                         warn = FALSE), collapse = "\n")
for (needle in c("Copyright (c) 2017 Mario dos Reis", "SIL Open Font License",
                 "shiny")) {
  add(grepl(needle, third, fixed = TRUE),
      paste0("THIRD_PARTY_LICENSES.md missing: ", needle))
}

docs <- list.files(file.path(root, "docs", "en"), pattern = "\\.md$")
for (file in docs) {
  zh <- file.path(root, "docs", "zh", file)
  add(file.exists(zh), paste0("missing Chinese mirror for ", file))
  text <- paste(readLines(file.path(root, "docs", "en", file), warn = FALSE),
                collapse = "\n")
  add(grepl("| applies_to | 0.1.0 |", text, fixed = TRUE),
      paste0("English document applies_to is wrong: ", file))
  zh_text <- paste(readLines(zh, warn = FALSE), collapse = "\n")
  add(grepl("| applies_to | 0.1.0 |", zh_text, fixed = TRUE),
      paste0("Chinese document applies_to is wrong: ", file))
}

shots <- c(
  "en-light/desktop.png", "en-light/mobile.png",
  "en-dark/desktop.png", "en-dark/mobile.png",
  "zh-light/desktop.png", "zh-light/mobile.png",
  "zh-dark/desktop.png", "zh-dark/mobile.png"
)
for (shot in shots) {
  add(file.exists(file.path(root, "docs", "assets", "screenshots", shot)),
      paste0("missing screenshot: ", shot))
}

add(file.exists(file.path(root, "www", "fonts", "NotoSansSC-Regular.ttf")),
    "bundled font missing")
add(file.exists(file.path(root, "www", "fonts", "OFL.txt")),
    "font licence missing")
add(file.exists(file.path(root, "www", "js", "i18n.js")),
    "generated i18n dictionary missing")
add(file.exists(file.path(root, "renv.lock")),
    "renv.lock missing (run dev/make_lockfile.R)")

if (length(errors)) {
  cat("release check failed:\n")
  cat(paste0("  - ", errors, collapse = "\n"), "\n")
  quit(status = 1)
}
cat("release check passed for version", version, "\n")
