# Shared utilities --------------------------------------------------------

app_path <- function(...) {
  root <- getOption("mcmc3r.app_dir", getwd())
  file.path(root, ...)
}

is_scalar_number <- function(x) {
  is.numeric(x) && length(x) == 1L && is.finite(x)
}

is_whole_number <- function(x, tol = 1e-8) {
  is_scalar_number(x) && abs(x - round(x)) < tol
}

check_range <- function(x, min = -Inf, max = Inf, open_min = FALSE,
                        open_max = FALSE) {
  if (!is_scalar_number(x)) return(FALSE)
  lower_ok <- if (open_min) x > min else x >= min
  upper_ok <- if (open_max) x < max else x <= max
  lower_ok && upper_ok
}

assert_scalar_number <- function(x, code, module, field = NULL,
                                 min = -Inf, max = Inf,
                                 open_min = FALSE, open_max = FALSE,
                                 detail = NULL) {
  ok <- is_scalar_number(x) && check_range(x, min, max, open_min, open_max)
  if (!ok) {
    stop_app(
      "validation", code,
      detail = detail %||% paste0(field %||% "value", "=", paste(x, collapse = ",")),
      context = list(module = module, field = field)
    )
  }
  invisible(TRUE)
}

assert_file_ext <- function(path, allowed, module = "files") {
  ext <- tolower(tools::file_ext(path))
  if (!ext %in% allowed) {
    stop_app(
      "input", "FILE-003",
      detail = paste0("extension=", ext, "; allowed=", paste(allowed, collapse = ",")),
      context = list(module = module, file = safe_basename(path))
    )
  }
  invisible(TRUE)
}

assert_file_size <- function(path, max_mb = LIMITS$upload_mb, module = "files") {
  size <- file.info(path)$size
  if (is.na(size)) {
    stop_app("input", "FILE-001",
             detail = "file is not readable",
             context = list(module = module, file = safe_basename(path)))
  }
  if (size > max_mb * 1024^2) {
    stop_app(
      "input", "FILE-001",
      detail = paste0("size=", fmt_bytes(size), "; limit=", max_mb, " MB"),
      context = list(module = module, file = safe_basename(path))
    )
  }
  invisible(TRUE)
}

ensure_dir <- function(path) {
  if (!dir.exists(path)) dir.create(path, recursive = TRUE, showWarnings = FALSE)
  if (!dir.exists(path)) stop("Could not create directory: ", path, call. = FALSE)
  path
}

new_session_dir <- function() {
  root <- file.path(tempdir(), "mcmc3r-bench")
  ensure_dir(root)
  dir <- tempfile("session-", tmpdir = root)
  ensure_dir(dir)
  try(Sys.chmod(dir, mode = "0700"), silent = TRUE)
  ensure_dir(file.path(dir, "uploads"))
  ensure_dir(file.path(dir, "runs"))
  ensure_dir(file.path(dir, "exports"))
  dir
}

new_run_dir <- function(session_dir) {
  dir <- tempfile(
    paste0("run-", fmt_utc(), "-"),
    tmpdir = ensure_dir(file.path(session_dir, "runs"))
  )
  ensure_dir(dir)
  dir
}

# Copy an uploaded file into the session directory under a safe name.
stash_upload <- function(datapath, original_name, session_dir,
                         prefix = "upload") {
  safe <- gsub("[^A-Za-z0-9._-]+", "_", safe_basename(original_name))
  if (!nzchar(safe)) safe <- paste0(prefix, ".txt")
  dest <- file.path(session_dir, "uploads",
                    paste0(prefix, "-", fmt_utc(), "-", safe))
  if (!file.copy(datapath, dest, overwrite = TRUE)) {
    stop_app("system", "SYS-001",
             detail = "could not copy uploaded file",
             context = list(module = "files"))
  }
  dest
}

read_text_file <- function(path, warn = FALSE) {
  con <- file(path, open = "r", encoding = "UTF-8")
  on.exit(close(con), add = TRUE)
  readLines(con, warn = warn)
}

write_text_file <- function(lines, path) {
  con <- file(path, open = "w", encoding = "UTF-8")
  on.exit(close(con), add = TRUE)
  writeLines(lines, con, useBytes = TRUE)
  invisible(path)
}
