#!/usr/bin/env Rscript
# Verify English/Chinese documentation parity, metadata, links, and versions.

if (!requireNamespace("digest", quietly = TRUE)) {
  stop("digest is required to check screenshots.")
}
args <- commandArgs(trailingOnly = FALSE)
file_arg <- sub("^--file=", "", args[grepl("^--file=", args)])
root <- if (length(file_arg)) dirname(dirname(normalizePath(file_arg))) else normalizePath(".")

errors <- character()
add <- function(condition, message) {
  if (!isTRUE(condition)) errors <<- c(errors, message)
}

pairs <- c(
  "QUICKSTART.md", "USER_GUIDE.md", "FILE_FORMATS.md", "METHODS.md",
  "FAQ.md", "PRIVACY.md", "ARCHITECTURE.md",
  "DEPLOYMENT.md", "TESTING.md", "I18N.md", "THEME.md",
  "CITATION.md", "ATTRIBUTION.md"
)
for (file in pairs) {
  en <- file.path(root, "docs", "en", file)
  zh <- file.path(root, "docs", "zh", file)
  add(file.exists(en), paste0("missing English document: ", file))
  add(file.exists(zh), paste0("missing Chinese document: ", file))
}

root_pairs <- c(
  "README.md" = "README.zh-CN.md",
  "CONTRIBUTING.md" = "CONTRIBUTING.zh-CN.md",
  "SECURITY.md" = "SECURITY.zh-CN.md",
  "CODE_OF_CONDUCT.md" = "CODE_OF_CONDUCT.zh-CN.md"
)
for (en in names(root_pairs)) {
  add(file.exists(file.path(root, en)), paste0("missing root document: ", en))
  add(file.exists(file.path(root, root_pairs[[en]])),
      paste0("missing root document: ", root_pairs[[en]]))
}

version <- trimws(readLines(file.path(root, "VERSION"), warn = FALSE)[1])

parse_meta <- function(path) {
  lines <- utils::head(readLines(path, warn = FALSE), 20)
  fields <- c("lang", "pair", "applies_to", "doc_version", "last_reviewed",
              "canonical", "status")
  out <- list()
  for (line in lines) {
    if (!grepl("^\\|", line)) next
    parts <- trimws(strsplit(sub("^\\|", "", sub("\\|$", "", line)), "\\|")[[1]])
    if (length(parts) >= 2 && parts[1] %in% fields) out[[parts[1]]] <- parts[2]
  }
  out
}

check_doc <- function(path, expected_lang, canonical) {
  if (!file.exists(path)) return(invisible(NULL))
  meta <- parse_meta(path)
  label <- basename(path)
  for (field in c("lang", "pair", "applies_to", "doc_version", "last_reviewed",
                  "canonical", "status")) {
    add(!is.null(meta[[field]]), paste0(label, ": missing metadata field ", field))
  }
  if (is.null(meta$lang)) return(invisible(NULL))
  add(identical(meta$lang, expected_lang),
      paste0(label, ": lang should be ", expected_lang))
  add(identical(meta$applies_to, version),
      paste0(label, ": applies_to should be ", version))
  add(identical(meta$status, "current"), paste0(label, ": status is not current"))
  add(identical(meta$canonical, if (canonical) "true" else "false"),
      paste0(label, ": canonical flag is wrong"))
  add(grepl("^\\d{4}-\\d{2}-\\d{2}$", meta$last_reviewed %||% ""),
      paste0(label, ": invalid last_reviewed date"))
  pair_path <- normalizePath(file.path(dirname(path), meta$pair), mustWork = FALSE)
  add(file.exists(pair_path), paste0(label, ": pair target missing: ", meta$pair))
  invisible(meta)
}

`%||%` <- function(x, y) if (is.null(x)) y else x

for (file in pairs) {
  en_meta <- check_doc(file.path(root, "docs", "en", file), "en",
                       canonical = TRUE)
  zh_meta <- check_doc(file.path(root, "docs", "zh", file), "zh-CN",
                       canonical = FALSE)
  en_lines <- readLines(file.path(root, "docs", "en", file), warn = FALSE)
  zh_lines <- readLines(file.path(root, "docs", "zh", file), warn = FALSE)
  en_h2 <- sum(grepl("^## ", en_lines))
  zh_h2 <- sum(grepl("^## ", zh_lines))
  add(en_h2 == zh_h2,
      paste0(file, ": heading count differs (", en_h2, " vs ", zh_h2, ")"))
}

check_links <- function(path) {
  if (!file.exists(path)) return(invisible(NULL))
  lines <- readLines(path, warn = FALSE)
  text <- paste(lines, collapse = "\n")
  targets <- unlist(regmatches(text, gregexpr("\\]\\(([^)]+)\\)", text,
                                               perl = TRUE)))
  targets <- sub("^\\]\\(", "", targets)
  targets <- sub("\\)$", "", targets)
  for (target in targets) {
    target <- trimws(target)
    if (!nzchar(target) || grepl("^(https?://|mailto:|#)", target)) next
    target <- sub("#.*$", "", target)
    target <- sub("\\?.*$", "", target)
    if (!nzchar(target)) next
    resolved <- normalizePath(file.path(dirname(path), target), mustWork = FALSE)
    add(file.exists(resolved),
        paste0(basename(path), ": broken link -> ", target))
  }
}

doc_files <- list.files(file.path(root, "docs"), pattern = "\\.md$",
                        full.names = TRUE, recursive = TRUE)
for (file in doc_files) check_links(file)
check_links(file.path(root, "README.md"))
check_links(file.path(root, "README.zh-CN.md"))

screenshots <- c(
  "en-light/desktop.png", "en-light/mobile.png",
  "en-dark/desktop.png", "en-dark/mobile.png",
  "zh-light/desktop.png", "zh-light/mobile.png",
  "zh-dark/desktop.png", "zh-dark/mobile.png"
)
# Existence alone let eight Chrome "connection refused" pages ship as README
# artwork. Check the captures actually differ and look like the app.
shot_digests <- character(0)
for (shot in screenshots) {
  path <- file.path(root, "docs", "assets", "screenshots", shot)
  if (!file.exists(path)) {
    add(FALSE, paste0("missing screenshot: ", shot))
    next
  }
  add(file.size(path) > 20000,
      paste0("screenshot too small to be the app: ", shot, " (",
             file.size(path), " bytes)"))
  raw <- readBin(path, what = "raw", n = file.size(path))
  bytes <- as.integer(raw)
  dark <- sum(bytes > 0 & bytes < 90) / length(bytes)
  add(dark >= 0.02,
      paste0("screenshot has no dark UI pixels, likely a blank or browser ",
             "error page: ", shot))
  shot_digests[[shot]] <- digest::digest(raw, algo = "sha1",
                                         serialize = FALSE)
}
dup <- shot_digests[duplicated(shot_digests)]
add(length(dup) == 0,
    paste0("identical screenshots, the capture matrix did not vary: ",
           paste(names(dup), collapse = ", ")))

add(file.exists(file.path(root, "docs", "TRANSLATION_STATUS.md")),
    "missing docs/TRANSLATION_STATUS.md")
add(file.exists(file.path(root, "docs", "GLOSSARY.md")),
    "missing docs/GLOSSARY.md")
add(file.exists(file.path(root, "docs", "LICENSE")),
    "missing docs/LICENSE")
add(file.exists(file.path(root, "NOTICE")), "missing NOTICE")
add(file.exists(file.path(root, "THIRD_PARTY_LICENSES.md")),
    "missing THIRD_PARTY_LICENSES.md")
add(file.exists(file.path(root, "CITATION.cff")), "missing CITATION.cff")

help_en <- file.path(root, "i18n", "help_en.md")
help_zh <- file.path(root, "i18n", "help_zh.md")
add(file.exists(help_en), "missing i18n/help_en.md")
add(file.exists(help_zh), "missing i18n/help_zh.md")
if (file.exists(help_en) && file.exists(help_zh)) {
  en_lines <- readLines(help_en, warn = FALSE)
  zh_lines <- readLines(help_zh, warn = FALSE)
  add(sum(grepl("^## ", en_lines)) == sum(grepl("^## ", zh_lines)),
      "help_en.md and help_zh.md have different heading counts")
  add(sum(grepl("^### ", en_lines)) == sum(grepl("^### ", zh_lines)),
      "help_en.md and help_zh.md have different subheading counts")
}

if (length(errors)) {
  cat("docs check failed:\n")
  cat(paste0("  - ", errors, collapse = "\n"), "\n")
  quit(status = 1)
}
cat("docs check passed:", length(doc_files), "documents,", length(pairs),
    "pairs,", length(screenshots), "screenshots\n")
