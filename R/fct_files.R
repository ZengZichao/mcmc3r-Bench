# File handling -----------------------------------------------------------
# Uploaded files are untrusted input. We never extract ZIP archives by path;
# only explicitly whitelisted members are copied to sanitised destinations.

ZIP_ALLOWED_EXT <- c("txt", "tsv", "csv")

detect_separator <- function(path) {
  lines <- tryCatch(read_text_file(path), error = function(e) character())
  lines <- lines[nzchar(trimws(lines))]
  if (!length(lines)) return("")
  sample <- paste(lines[seq_len(min(5, length(lines)))], collapse = "\n")
  tabs <- lengths(regmatches(sample, gregexpr("\t", sample, fixed = TRUE)))
  commas <- lengths(regmatches(sample, gregexpr(",", sample, fixed = TRUE)))
  if (tabs > 0 && tabs >= commas) return("\t")
  if (commas > 0) return(",")
  ""
}

raw_header <- function(path, sep = "auto") {
  lines <- tryCatch(read_text_file(path), error = function(e) character())
  lines <- lines[nzchar(trimws(lines))]
  if (!length(lines)) return(character())
  header <- trimws(lines[1])
  if (identical(sep, "auto")) sep <- detect_separator(path)
  if (identical(sep, "")) {
    parts <- strsplit(header, "[[:space:]]+")[[1]]
  } else {
    parts <- strsplit(header, sep, fixed = TRUE)[[1]]
  }
  parts <- gsub("^[\"']|[\"']$", "", trimws(parts))
  parts[nzchar(parts)]
}

read_table_file <- function(path, sep = "auto", max_rows = LIMITS$mcmc_rows,
                            module = "mcmc", select = NULL) {
  assert_file_ext(path, ZIP_ALLOWED_EXT, module = module)
  assert_file_size(path, module = module)

  if (identical(sep, "auto")) sep <- detect_separator(path)
  header <- raw_header(path, sep)
  fread_sep <- if (identical(sep, "")) "auto" else sep
  if (length(header) && anyDuplicated(header)) {
    stop_app(
      "input", "MCMC-006",
      detail = paste0("duplicated=",
                      paste(unique(header[duplicated(header)]), collapse = ",")),
      context = list(module = module, columns = length(header))
    )
  }

  df <- tryCatch(
    data.table::fread(
      path,
      sep = fread_sep,
      data.table = FALSE,
      check.names = FALSE,
      header = TRUE,
      na.strings = c("NA", "NaN", "Inf", "-Inf"),
      encoding = "UTF-8",
      select = select,
      showProgress = FALSE
    ),
    error = function(e) e
  )
  if (inherits(df, "error")) {
    detail <- gsub(path, safe_basename(path), conditionMessage(df), fixed = TRUE)
    stop_app(
      "input", "MCMC-001",
      detail = detail,
      context = list(module = module, file = safe_basename(path))
    )
  }
  if (!nrow(df)) {
    stop_app(
      "input", "MCMC-002",
      detail = paste0("columns=", ncol(df)),
      context = list(module = module, rows = 0L)
    )
  }
  if (nrow(df) > max_rows) {
    stop_app(
      "input", "MCMC-005",
      detail = paste0("rows=", nrow(df), "; limit=", max_rows),
      context = list(module = module, rows = nrow(df))
    )
  }
  if (ncol(df) > 2000) {
    stop_app(
      "input", "FILE-001",
      detail = paste0("columns=", ncol(df)),
      context = list(module = module, columns = ncol(df))
    )
  }
  list(
    data = df,
    diagnostics = list(
      rows = nrow(df),
      columns = ncol(df),
      bytes = file.info(path)$size,
      separator = if (identical(sep, "")) "whitespace" else sep,
      names = names(df)
    )
  )
}

# ZIP safety --------------------------------------------------------------

validate_zip_entries <- function(zip_path, module = "marginal") {
  assert_file_ext(zip_path, "zip", module = module)
  assert_file_size(zip_path, max_mb = LIMITS$upload_mb, module = module)
  info <- tryCatch(
    zip::zip_list(zip_path),
    error = function(e) {
      detail <- gsub(zip_path, safe_basename(zip_path),
                     conditionMessage(e), fixed = TRUE)
      stop_app("input", "FILE-002",
               detail = detail,
               context = list(module = module, file = safe_basename(zip_path)))
    }
  )
  if (!nrow(info)) {
    stop_app("input", "FILE-002", detail = "empty zip",
             context = list(module = module))
  }
  if (!is.null(info$encryption) && any(info$encryption != "none")) {
    stop_app("input", "FILE-002", detail = "encrypted zip",
             context = list(module = module))
  }

  names <- info$filename
  bad <- !nzchar(names) |
    grepl("\\\\", names) |
    grepl("^/", names) |
    grepl("^[A-Za-z]:", names) |
    vapply(strsplit(names, "/", fixed = TRUE), function(parts) {
      any(parts %in% c("..", "."))
    }, logical(1))
  if (any(bad)) {
    stop_app(
      "input", "FILE-002",
      detail = paste0("unsafe entries=", paste(utils::head(names[bad], 5), collapse = ",")),
      context = list(module = module, files = sum(bad))
    )
  }

  is_dir <- grepl("/$", names) | identical(info$type, "directory")
  files <- info[!is_dir, , drop = FALSE]
  if (!nrow(files)) {
    stop_app("input", "FILE-002", detail = "no files in zip",
             context = list(module = module))
  }
  if (!is.null(files$permissions) &&
      any(grepl("^12", as.character(files$permissions)))) {
    stop_app("input", "FILE-002",
             detail = "symbolic link entry in zip",
             context = list(module = module))
  }
  if (nrow(files) > LIMITS$zip_files) {
    stop_app("input", "FILE-004",
             detail = paste0("files=", nrow(files), "; limit=", LIMITS$zip_files),
             context = list(module = module, files = nrow(files)))
  }
  total <- sum(files$uncompressed_size, na.rm = TRUE)
  if (total > LIMITS$zip_uncompressed_mb * 1024^2) {
    stop_app("input", "FILE-001",
             detail = paste0("uncompressed=", fmt_bytes(total)),
             context = list(module = module))
  }
  ratio <- total / max(file.info(zip_path)$size, 1)
  if (ratio > LIMITS$zip_ratio) {
    stop_app("input", "FILE-004",
             detail = paste0("ratio=", round(ratio, 1), ":1"),
             context = list(module = module))
  }
  files
}

# Inspect a marginal-likelihood ZIP without extracting it.
zip_structure <- function(zip_path, module = "marginal") {
  files <- validate_zip_entries(zip_path, module = module)
  names <- files$filename

  beta_matches <- grepl("(^|/)beta\\.txt$", names)
  if (!any(beta_matches)) {
    stop_app("input", "FILE-002",
             detail = "missing beta.txt",
             context = list(module = module, file = safe_basename(zip_path)))
  }
  roots <- unique(sub("(^|/)beta\\.txt$", "", names[beta_matches]))
  roots <- sub("/$", "", roots)
  if (length(roots) > 1) {
    stop_app("input", "FILE-002",
             detail = "multiple beta.txt entries",
             context = list(module = module))
  }
  root <- roots[1]
  prefix <- if (nzchar(root)) paste0("^", gsub("([][{}()+*^$|\\\\?.])", "\\\\\\1", root), "/") else "^"

  chain_pattern <- paste0(prefix, "([0-9]+)/mcmc\\.txt$")
  chain_matches <- grepl(chain_pattern, names)
  if (!any(chain_matches)) {
    stop_app("input", "FILE-002",
             detail = "no numbered chain directories found",
             context = list(module = module))
  }
  idx <- as.integer(sub(chain_pattern, "\\1", names[chain_matches]))
  if (anyDuplicated(idx)) {
    stop_app("input", "FILE-002", detail = "duplicate chain directories",
             context = list(module = module))
  }
  ord <- order(idx)
  idx <- idx[ord]
  entries <- names[chain_matches][ord]
  n <- length(idx)
  if (!identical(idx, seq_len(n))) {
    stop_app("input", "FILE-002",
             detail = paste0("non-contiguous chain directories: ",
                             paste(idx, collapse = ",")),
             context = list(module = module, chains = n))
  }
  if (n > LIMITS$chains_max) {
    stop_app("input", "FILE-004",
             detail = paste0("chains=", n, "; limit=", LIMITS$chains_max),
             context = list(module = module, chains = n))
  }
  list(
    root = root,
    n = n,
    beta_entry = names[beta_matches][1],
    chain_entries = entries,
    files = files
  )
}

zip_read_lines <- function(zip_path, entry, encoding = "UTF-8") {
  con <- unz(zip_path, entry, open = "r", encoding = encoding)
  on.exit(close(con), add = TRUE)
  readLines(con, warn = FALSE, encoding = encoding)
}

# Streaming extraction of a single whitelisted entry to a sanitised path.
zip_extract_entry <- function(zip_path, entry, dest, max_bytes = LIMITS$upload_mb * 1024^2) {
  ensure_dir(dirname(dest))
  con <- unz(zip_path, entry, open = "rb")
  on.exit(close(con), add = TRUE)
  out <- file(dest, open = "wb")
  on.exit(close(out), add = TRUE)
  total <- 0
  repeat {
    chunk <- readBin(con, what = "raw", n = 1024^2)
    if (!length(chunk)) break
    total <- total + length(chunk)
    if (total > max_bytes) {
      stop_app("input", "FILE-001", detail = "zip entry too large",
               context = list(module = "marginal"))
    }
    writeBin(chunk, out)
  }
  dest
}

zip_read_numeric_file <- function(zip_path, entry) {
  lines <- zip_read_lines(zip_path, entry)
  lines <- trimws(lines)
  lines <- lines[nzchar(lines)]
  values <- suppressWarnings(as.numeric(lines))
  if (!length(values) || any(is.na(values))) {
    stop_app("input", "ML-001",
             detail = paste0("lines=", length(lines)),
             context = list(module = "marginal", file = safe_basename(entry)))
  }
  values
}

# Preview helper used by DT.
preview_df <- function(df, max_cols = 20, max_rows = 10) {
  cols <- seq_len(min(ncol(df), max_cols))
  out <- df[seq_len(min(nrow(df), max_rows)), cols, drop = FALSE]
  out <- as.data.frame(lapply(out, function(x) {
    if (is.list(x)) {
      vapply(x, function(v) paste(v, collapse = ","), character(1))
    } else {
      as.character(x)
    }
  }), stringsAsFactors = FALSE, check.names = FALSE)
  out[] <- lapply(out, as.character)
  names(out) <- names(df)[cols]
  out
}
