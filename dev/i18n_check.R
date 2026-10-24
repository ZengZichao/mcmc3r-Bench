#!/usr/bin/env Rscript
# Check translation completeness and browser-dictionary consistency.

args <- commandArgs(trailingOnly = FALSE)
file_arg <- sub("^--file=", "", args[grepl("^--file=", args)])
root <- if (length(file_arg)) dirname(dirname(normalizePath(file_arg))) else normalizePath(".")
lib <- file.path(root, ".Rlib")
if (dir.exists(lib)) .libPaths(c(lib, .libPaths()))

source(file.path(root, "R", "app_meta.R"), local = FALSE)
source(file.path(root, "R", "fct_i18n.R"), local = FALSE)

errors <- character()
note <- function(condition, message) {
  if (!isTRUE(condition)) errors <<- c(errors, message)
}

csv <- file.path(root, "i18n", "translations.csv")
tab <- utils::read.csv(csv, stringsAsFactors = FALSE, check.names = FALSE,
                       encoding = "UTF-8", na.strings = character())
note(identical(names(tab), c("key", "en", "zh")),
     "translation columns must be exactly key,en,zh")
note(!anyDuplicated(tab$key) > 0, "duplicate translation keys")
note(all(nzchar(tab$en)), "empty English translations")
note(all(nzchar(tab$zh)), "empty Chinese translations")
note(all(tab$key == trimws(tab$key)), "keys must not have surrounding whitespace")
note(all(grepl("^[A-Za-z0-9_-]+(\\.[A-Za-z0-9_-]+)*$", tab$key)),
     "keys contain invalid characters")

codes <- c(
  "CAL-001", "CAL-002", "CAL-003", "CAL-004", "CAL-005", "CAL-006",
  "CAL-007", "CAL-008", "CAL-009", "CAL-010", "CAL-011", "CAL-012",
  "MCMC-001", "MCMC-002", "MCMC-003", "MCMC-004", "MCMC-005", "MCMC-006",
  "MCMC-007", "MCMC-008",
  "ML-001", "ML-002", "ML-003", "ML-004", "ML-005", "ML-006", "ML-007",
  "ML-008", "ML-009", "ML-010", "ML-011",
  "FILE-001", "FILE-002", "FILE-003", "FILE-004",
  "SYS-001", "SYS-002", "SYS-003"
)
for (code in codes) {
  note(paste0("err.", code) %in% tab$key, paste0("missing message for ", code))
  note(paste0("hint.", code) %in% tab$key, paste0("missing hint for ", code))
}

placeholders <- function(x) {
  matches <- regmatches(x, gregexpr("\\{[A-Za-z0-9_]+\\}", x, perl = TRUE))[[1]]
  sort(unique(matches))
}
for (i in seq_len(nrow(tab))) {
  if (!identical(placeholders(tab$en[i]), placeholders(tab$zh[i]))) {
    errors <- c(errors, paste0("placeholder mismatch for ", tab$key[i]))
  }
}

r_files <- list.files(file.path(root, "R"), pattern = "\\.R$", full.names = TRUE)
r_text <- paste(vapply(r_files, function(f) paste(readLines(f, warn = FALSE),
                                                   collapse = "\n"), character(1)),
                collapse = "\n")
tr_matches <- regmatches(
  r_text,
  gregexpr('tr(?:_span|_vec)?\\(\\s*"([^"]+)"', r_text, perl = TRUE)
)[[1]]
tr_keys <- unique(sub('^tr(?:_span|_vec)?\\(\\s*"', "", tr_matches))
tr_keys <- sub('"$', "", tr_keys)
missing_tr <- setdiff(tr_keys, tab$key)
note(!length(missing_tr),
     paste0("tr() keys missing from CSV: ", paste(missing_tr, collapse = ", ")))

i18n_attrs <- unique(unlist(regmatches(
  r_text,
  gregexpr('`data-i18n(?:-placeholder|-title|-aria-label)?`\\s*=\\s*"([^"]+)"',
           r_text, perl = TRUE)
)))
i18n_keys <- unique(sub('^`data-i18n(?:-placeholder|-title|-aria-label)?`\\s*=\\s*"', "",
                        i18n_attrs))
i18n_keys <- sub('"$', "", i18n_keys)
missing_attrs <- setdiff(i18n_keys, tab$key)
note(!length(missing_attrs),
     paste0("data-i18n keys missing from CSV: ", paste(missing_attrs, collapse = ", ")))

js_path <- file.path(root, "www", "js", "i18n.js")
note(file.exists(js_path), "www/js/i18n.js is missing (run dev/build_i18n.R)")
if (file.exists(js_path)) {
  js <- paste(readLines(js_path, warn = FALSE), collapse = "\n")
  start <- regexpr("window.MCMC3R_I18N\\s*=\\s*", js, perl = TRUE)
  if (start < 0) {
    errors <- c(errors, "i18n.js does not define window.MCMC3R_I18N")
  } else {
    json_text <- substring(js, start + attr(start, "match.length"))
    json_text <- sub(";\\s*window\\.MCMC3R_I18N_META.*$", "", json_text, perl = TRUE)
    dict <- tryCatch(jsonlite::fromJSON(json_text, simplifyVector = FALSE),
                     error = function(e) NULL)
    if (is.null(dict)) {
      errors <- c(errors, "i18n.js JSON could not be parsed")
    } else {
      for (lang in c("en", "zh")) {
        note(length(dict[[lang]]) == nrow(tab),
             paste0("i18n.js has a different number of ", lang, " keys"))
        for (i in seq_len(nrow(tab))) {
          key <- tab$key[i]
          value <- dict[[lang]][[key]]
          expected <- if (lang == "en") tab$en[i] else tab$zh[i]
          if (is.null(value) || !identical(value, expected)) {
            errors <- c(errors, paste0("i18n.js mismatch for ", lang, ":", key))
            break
          }
        }
      }
    }
  }
}

if (length(errors)) {
  cat("i18n check failed:\n")
  cat(paste0("  - ", errors, collapse = "\n"), "\n")
  quit(status = 1)
}
cat("i18n check passed:", nrow(tab), "keys,", length(codes), "error codes\n")
