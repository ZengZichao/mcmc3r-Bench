# MCMC summary service ----------------------------------------------------
# Upstream mcmc.sum() uses substring matching and fails for one-column or
# non-finite inputs. We implement the equivalent summary explicitly and verify
# equivalence in the test suite.

regex_escape <- function(x) {
  gsub("([][{}()+*^$|\\\\?.])", "\\\\\\1", x)
}

mcmc_detect_prefix <- function(names) {
  if (any(grepl("^tau_", names))) return("tau_")
  if (any(grepl("^t_", names))) return("t_")
  NULL
}

mcmc_time_columns <- function(names, prefix) {
  if (is.null(prefix) || !nzchar(prefix)) return(character())
  pattern <- paste0("^", regex_escape(prefix))
  names[grepl(pattern, names)]
}

mcmc_coerce_time <- function(df, cols, module = "mcmc") {
  out <- matrix(NA_real_, nrow = nrow(df), ncol = length(cols))
  colnames(out) <- cols
  non_numeric <- character()
  for (j in seq_along(cols)) {
    col <- cols[j]
    x <- df[[col]]
    if (is.factor(x)) x <- as.character(x)
    if (is.character(x)) {
      x_trim <- trimws(gsub("^[\"']|[\"']$", "", x))
      numeric_x <- suppressWarnings(as.numeric(x_trim))
      originally_missing <- is.na(x) | !nzchar(x_trim) |
        x_trim %in% c("NA", "NaN", "Inf", "-Inf", "inf", "-inf")
      if (any(is.na(numeric_x) & !originally_missing)) {
        non_numeric <- c(non_numeric, col)
        next
      }
      x <- numeric_x
    }
    if (!is.numeric(x)) {
      non_numeric <- c(non_numeric, col)
      next
    }
    out[, j] <- as.numeric(x)
  }
  if (length(non_numeric)) {
    stop_app(
      "input", "MCMC-004",
      detail = paste0("non-numeric columns=", paste(non_numeric, collapse = ",")),
      context = list(module = module, columns = length(non_numeric))
    )
  }
  out
}

mcmc_summarise <- function(df, prefix = "auto", module = "mcmc") {
  if (!is.data.frame(df)) {
    stop_app("input", "MCMC-001", detail = "not a data frame",
             context = list(module = module))
  }
  if (anyDuplicated(names(df))) {
    stop_app(
      "input", "MCMC-006",
      detail = paste0("duplicated=", paste(unique(names(df)[duplicated(names(df))]), collapse = ",")),
      context = list(module = module)
    )
  }
  if (nrow(df) < 2) {
    stop_app("input", "MCMC-002", detail = paste0("rows=", nrow(df)),
             context = list(module = module, rows = nrow(df)))
  }
  if (nrow(df) > LIMITS$mcmc_rows) {
    stop_app("input", "MCMC-005",
             detail = paste0("rows=", nrow(df), "; limit=", LIMITS$mcmc_rows),
             context = list(module = module, rows = nrow(df)))
  }

  requested <- prefix
  if (identical(prefix, "auto")) {
    prefix <- mcmc_detect_prefix(names(df))
    if (is.null(prefix)) {
      stop_app(
        "input", "MCMC-003",
        detail = paste0("columns=", paste(utils::head(names(df), 40), collapse = ",")),
        context = list(module = module, columns = ncol(df))
      )
    }
  } else {
    prefix <- trimws(prefix)
    if (!nzchar(prefix)) {
      stop_app("input", "MCMC-003", detail = "empty prefix",
               context = list(module = module))
    }
  }

  time_cols <- mcmc_time_columns(names(df), prefix)
  if (!length(time_cols)) {
    stop_app(
      "input", "MCMC-003",
      detail = paste0("prefix=", prefix, "; columns=",
                      paste(utils::head(names(df), 40), collapse = ",")),
      context = list(module = module, columns = ncol(df))
    )
  }

  mat <- mcmc_coerce_time(df, time_cols, module = module)
  finite <- is.finite(mat)
  rows_ok <- rowSums(!finite) == 0
  n_removed <- sum(!rows_ok)
  mat <- mat[rows_ok, , drop = FALSE]

  warnings <- list()
  if (n_removed > 0) {
    warnings[[length(warnings) + 1]] <- list(
      code = "MCMC-008",
      values = list(n = n_removed),
      detail = paste0("removed_rows=", n_removed)
    )
  }
  if (nrow(mat) < 2) {
    stop_app(
      "input", "MCMC-007",
      detail = paste0("rows_used=", nrow(mat), "; removed=", n_removed),
      context = list(module = module, rows = nrow(mat))
    )
  }

  n <- nrow(mat)
  table <- data.frame(
    parameter = colnames(mat),
    mean = vapply(seq_len(ncol(mat)), function(j) mean(mat[, j]), numeric(1)),
    median = vapply(seq_len(ncol(mat)), function(j) stats::median(mat[, j]), numeric(1)),
    ci025 = vapply(seq_len(ncol(mat)), function(j) {
      unname(stats::quantile(mat[, j], probs = 0.025))
    }, numeric(1)),
    ci975 = vapply(seq_len(ncol(mat)), function(j) {
      unname(stats::quantile(mat[, j], probs = 0.975))
    }, numeric(1)),
    n = rep(n, ncol(mat)),
    stringsAsFactors = FALSE
  )
  rownames(table) <- table$parameter

  list(
    table = table,
    time_cols = time_cols,
    prefix = prefix,
    requested_prefix = requested,
    warnings = warnings,
    diagnostics = list(
      rows_in = nrow(df),
      rows_used = n,
      rows_removed = n_removed,
      columns = ncol(df),
      time_columns = length(time_cols),
      non_finite = sum(!finite),
      names = names(df)
    )
  )
}

mcmc_read <- function(path, sep = "auto", module = "mcmc") {
  read_table_file(path, sep = sep, module = module)
}
