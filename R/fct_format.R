# Formatting helpers ------------------------------------------------------

fmt_num <- function(x, digits = 6) {
  if (!length(x)) return(character())
  if (!is.numeric(x)) x <- suppressWarnings(as.numeric(x))
  out <- format(signif(x, digits), scientific = FALSE, trim = TRUE,
                drop0trailing = TRUE)
  out[is.na(x)] <- NA_character_
  out
}

fmt_sci <- function(x, digits = 4) {
  if (!length(x)) return(character())
  out <- formatC(x, format = "e", digits = digits)
  out[is.na(x)] <- NA_character_
  out
}

fmt_int <- function(x) {
  formatC(x, format = "d", big.mark = "")
}

fmt_pct <- function(x, digits = 1) {
  paste0(formatC(100 * x, format = "f", digits = digits), "%")
}

fmt_utc <- function(time = Sys.time()) {
  format(time, tz = "UTC", format = "%Y%m%d-%H%M%S")
}

fmt_display_time <- function(time = Sys.time()) {
  format(time, format = "%Y-%m-%d %H:%M:%S")
}

download_filename <- function(module, ext, lang = "en", export_theme = "print",
                              time = Sys.time()) {
  module <- gsub("[^A-Za-z0-9_-]+", "-", as.character(module))
  lang <- normalize_lang(lang)
  export_theme <- if (identical(export_theme, "screen")) "screen" else "print"
  paste0(
    "mcmc3r-bench_", module, "_", fmt_utc(time), "_",
    lang, "_", export_theme, ".", ext
  )
}

# Excel/CSV formula injection: prefix strings that begin with one of = + - @
# (and tab/CR) with a single quote. Numeric columns are left untouched.
escape_formula <- function(x) {
  if (!is.character(x)) return(x)
  x <- gsub("^([=+@\t\r-])", "'\\1", x)
  x
}

sanitize_csv_df <- function(df) {
  if (!is.data.frame(df)) return(df)
  for (nm in names(df)) {
    if (is.character(df[[nm]])) df[[nm]] <- escape_formula(df[[nm]])
  }
  df
}

write_csv_safe <- function(df, path, row.names = FALSE) {
  df <- sanitize_csv_df(df)
  utils::write.csv(
    df, file = path, row.names = row.names, na = "",
    fileEncoding = "UTF-8"
  )
  invisible(path)
}

read_csv_safe <- function(path, ...) {
  utils::read.csv(
    path, stringsAsFactors = FALSE, check.names = FALSE,
    fileEncoding = "UTF-8", ...
  )
}

safe_basename <- function(path) {
  if (is.null(path) || !length(path) || is.na(path)) return("")
  basename(gsub("\\\\", "/", as.character(path)))
}

# Friendly size string for diagnostics.
fmt_bytes <- function(bytes) {
  bytes <- as.numeric(bytes)
  if (!length(bytes) || is.na(bytes)) return("")
  units <- c("B", "KB", "MB", "GB")
  i <- 1
  while (bytes >= 1024 && i < length(units)) {
    bytes <- bytes / 1024
    i <- i + 1
  }
  paste0(formatC(bytes, format = "f", digits = if (i == 1) 0 else 1), " ", units[i])
}

# Natural sort for chain file names: numeric tokens are compared as numbers.
natural_order <- function(x) {
  key <- vapply(x, function(s) {
    parts <- regmatches(s, gregexpr("[0-9]+|[^0-9]+", s))[[1]]
    parts <- vapply(parts, function(p) {
      if (grepl("^[0-9]+$", p)) sprintf("%020d", as.numeric(p)) else p
    }, character(1))
    paste(parts, collapse = "")
  }, character(1))
  order(key, x)
}
