# Marginal likelihood service ---------------------------------------------
# Handles beta validation, safe ZIP reading, temporary directory construction
# and the upstream stepping.stones()/gauss.quad() calls. Upstream functions use
# relative paths, so every call is wrapped in withr::with_dir().

ml_method_label_key <- function(method) {
  if (identical(method, "gauss-quad")) "ml.method.gq" else "ml.method.ss"
}

ml_beta_limits <- function(method) {
  if (identical(method, "gauss-quad")) LIMITS$beta_max_gq else LIMITS$beta_max_ss
}

ml_beta_validate <- function(beta, method, module = "marginal") {
  if (!is.numeric(beta) || !length(beta) || any(!is.finite(beta))) {
    stop_app("input", "ML-001", detail = "beta must be a finite numeric vector",
             context = list(module = module))
  }
  if (identical(method, "gauss-quad")) {
    bad <- beta <= 0 | beta >= 1
  } else {
    bad <- beta < 0 | beta >= 1
  }
  if (any(bad)) {
    stop_app(
      "input", "ML-002",
      detail = paste0("invalid beta=", paste(utils::head(beta[bad], 5), collapse = ",")),
      context = list(module = module, method = method)
    )
  }
  if (length(beta) > 1 && any(diff(beta) <= 0)) {
    stop_app("input", "ML-003",
             detail = "beta is not strictly increasing",
             context = list(module = module))
  }
  if (identical(method, "gauss-quad")) {
    if (length(beta) > LIMITS$gauss_max) {
      stop_app("input", "ML-008",
               detail = paste0("n=", length(beta), "; max=", LIMITS$gauss_max),
               context = list(module = module))
    }
    if (length(beta) > LIMITS$beta_max_gq) {
      stop_app("input", "ML-011",
               detail = paste0("n=", length(beta), "; limit=", LIMITS$beta_max_gq),
               context = list(module = module))
    }
    if (length(beta) > 1) {
      ref <- tryCatch(
        mcmc3r::make.beta(length(beta), "gauss-quad"),
        error = function(e) NULL
      )
      if (is.null(ref) || any(abs(beta - ref) > 1e-6)) {
        stop_app("input", "ML-009",
                 detail = "beta does not match the Gauss-Legendre rule",
                 context = list(module = module, method = method))
      }
    }
  } else if (length(beta) > LIMITS$beta_max_ss) {
    stop_app("input", "ML-011",
             detail = paste0("n=", length(beta), "; limit=", LIMITS$beta_max_ss),
             context = list(module = module))
  }
  invisible(TRUE)
}

ml_beta_read_file <- function(path, module = "marginal") {
  assert_file_ext(path, c("txt", "tsv", "csv"), module = module)
  lines <- read_text_file(path)
  lines <- trimws(lines)
  lines <- lines[nzchar(lines)]
  values <- suppressWarnings(as.numeric(lines))
  if (!length(values) || any(is.na(values))) {
    stop_app("input", "ML-001",
             detail = paste0("lines=", length(lines)),
             context = list(module = module, file = safe_basename(path)))
  }
  values
}

ml_beta_generate <- function(n, method, a = 5, module = "marginal") {
  if (!is_whole_number(n) || n < 1) {
    stop_app("input", "ML-011", detail = paste0("n=", n),
             context = list(module = module))
  }
  n <- as.integer(round(n))
  if (identical(method, "gauss-quad") && n > LIMITS$gauss_max) {
    stop_app("input", "ML-008",
             detail = paste0("n=", n, "; max=", LIMITS$gauss_max),
             context = list(module = module))
  }
  if (n > ml_beta_limits(method)) {
    stop_app("input", "ML-011",
             detail = paste0("n=", n, "; limit=", ml_beta_limits(method)),
             context = list(module = module))
  }
  if (identical(method, "gauss-quad")) {
    return(mcmc3r::make.beta(n, "gauss-quad"))
  }
  if (!is_scalar_number(a) || a <= 0) {
    stop_app("input", "ML-011", detail = paste0("a=", a),
             context = list(module = module))
  }
  mcmc3r::make.beta(n, "step-stones", a)
}

ml_write_beta <- function(run_dir, beta, method) {
  b <- beta
  converted <- 0L
  if (!identical(method, "gauss-quad")) {
    converted <- sum(b == 0)
    b[b == 0] <- 1e-300
  }
  lines <- format(b, scientific = TRUE, digits = 17, trim = TRUE)
  write_text_file(lines, file.path(run_dir, "beta.txt"))
  converted
}

ml_read_lnl <- function(path, module = "marginal") {
  header <- raw_header(path)
  if (!"lnL" %in% header) {
    stop_app(
      "input", "ML-005",
      detail = paste0("columns=", paste(utils::head(header, 20), collapse = ",")),
      context = list(module = module, file = safe_basename(path))
    )
  }
  df <- tryCatch(
    data.table::fread(
      path, sep = "auto", header = TRUE, data.table = FALSE,
      check.names = FALSE, select = "lnL", showProgress = FALSE,
      na.strings = c("NA", "NaN", "Inf", "-Inf")
    ),
    error = function(e) e
  )
  if (inherits(df, "error") || !"lnL" %in% names(df)) {
    detail <- if (inherits(df, "error")) {
      gsub(path, safe_basename(path), conditionMessage(df), fixed = TRUE)
    } else {
      "lnL missing"
    }
    stop_app("input", "ML-005",
             detail = detail,
             context = list(module = module, file = safe_basename(path)))
  }
  lnl <- suppressWarnings(as.numeric(df$lnL))
  if (length(lnl) < 2) {
    stop_app("input", "ML-007",
             detail = paste0("rows=", length(lnl)),
             context = list(module = module, file = safe_basename(path)))
  }
  bad <- !is.finite(lnl)
  if (any(bad)) {
    stop_app(
      "input", "ML-006",
      detail = paste0("non-finite=", sum(bad), "; rows=", length(lnl)),
      context = list(module = module, file = safe_basename(path))
    )
  }
  lnl
}

ml_write_chain <- function(lnl, run_dir, i) {
  dir <- ensure_dir(file.path(run_dir, as.character(i)))
  data.table::fwrite(
    data.frame(lnL = lnl),
    file = file.path(dir, "mcmc.txt"),
    quote = FALSE
  )
  invisible(dir)
}

ml_prepare_zip <- function(zip_path, session_dir, method, module = "marginal") {
  structure <- zip_structure(zip_path, module = module)
  beta <- zip_read_numeric_file(zip_path, structure$beta_entry)
  ml_beta_validate(beta, method, module = module)
  if (length(beta) != structure$n) {
    stop_app(
      "input", "ML-004",
      detail = paste0("beta=", length(beta), "; chains=", structure$n),
      context = list(module = module, beta = length(beta), chains = structure$n)
    )
  }

  run_dir <- new_run_dir(session_dir)
  converted <- ml_write_beta(run_dir, beta, method)

  chain_rows <- integer(structure$n)
  tmp <- file.path(run_dir, "chain-entry.tmp")
  for (i in seq_len(structure$n)) {
    zip_extract_entry(zip_path, structure$chain_entries[[i]], tmp)
    lnl <- ml_read_lnl(tmp, module = module)
    chain_rows[i] <- length(lnl)
    ml_write_chain(lnl, run_dir, i)
    unlink(tmp)
  }
  if (sum(chain_rows) > LIMITS$mcmc_rows) {
    stop_app("input", "MCMC-005",
             detail = paste0("rows=", sum(chain_rows)),
             context = list(module = module))
  }
  unlink(tmp)

  list(
    run_dir = run_dir,
    beta_original = beta,
    beta_converted = converted,
    n = structure$n,
    chain_rows = chain_rows,
    source = "zip",
    zip_root = structure$root
  )
}

ml_prepare_files <- function(paths, beta, session_dir, method,
                             module = "marginal") {
  ml_beta_validate(beta, method, module = module)
  if (length(paths) != length(beta)) {
    stop_app(
      "input", "ML-004",
      detail = paste0("beta=", length(beta), "; files=", length(paths)),
      context = list(module = module, beta = length(beta), chains = length(paths))
    )
  }
  if (length(paths) > LIMITS$chains_max) {
    stop_app("input", "FILE-004",
             detail = paste0("files=", length(paths)),
             context = list(module = module))
  }
  ord <- natural_order(basename(paths))
  paths <- paths[ord]

  run_dir <- new_run_dir(session_dir)
  converted <- ml_write_beta(run_dir, beta, method)
  chain_rows <- integer(length(paths))
  for (i in seq_along(paths)) {
    lnl <- ml_read_lnl(paths[[i]], module = module)
    chain_rows[i] <- length(lnl)
    ml_write_chain(lnl, run_dir, i)
  }
  if (sum(chain_rows) > LIMITS$mcmc_rows) {
    stop_app("input", "MCMC-005",
             detail = paste0("rows=", sum(chain_rows)),
             context = list(module = module))
  }
  list(
    run_dir = run_dir,
    beta_original = beta,
    beta_converted = converted,
    n = length(paths),
    chain_rows = chain_rows,
    source = "files",
    zip_root = NULL
  )
}

ml_execute <- function(run_dir, method, module = "marginal") {
  warnings <- character()
  start <- Sys.time()
  res <- NULL
  tryCatch(
    utils::capture.output(
      res <- withr::with_dir(run_dir, {
        withCallingHandlers(
          {
            if (identical(method, "gauss-quad")) {
              mcmc3r::gauss.quad(mcmcf = "mcmc.txt", betaf = "beta.txt", se = TRUE)
            } else {
              mcmc3r::stepping.stones(mcmcf = "mcmc.txt", betaf = "beta.txt", se = TRUE)
            }
          },
          warning = function(w) {
            warnings <<- c(warnings, conditionMessage(w))
            invokeRestart("muffleWarning")
          }
        )
      }),
      type = "output"
    ),
    error = function(e) {
      stop_app("upstream", "ML-010",
               detail = conditionMessage(e),
               context = list(module = module, method = method))
    }
  )
  elapsed <- as.numeric(difftime(Sys.time(), start, units = "secs")) * 1000

  if (!is_scalar_number(res$logml) || !is.numeric(res$mean.logl)) {
    stop_app("upstream", "ML-010", detail = "non-finite upstream result",
             context = list(module = module))
  }
  list(
    logml = res$logml,
    se = if (is_scalar_number(res$se)) res$se else NA_real_,
    mean.logl = as.numeric(res$mean.logl),
    b = as.numeric(res$b),
    warnings = unique(warnings),
    elapsed_ms = round(elapsed)
  )
}

ml_result_object <- function(prep, exec, method, model_name = "",
                             screen_theme = "light", lang = "en") {
  n <- prep$n
  beta_display <- prep$beta_original
  if (length(beta_display) != length(exec$mean.logl)) {
    beta_display <- exec$b
  }
  se_warning <- rep(FALSE, n)
  if (length(exec$warnings)) {
    for (i in seq_len(n)) {
      needle <- paste0("b = ", format(beta_display[i], trim = TRUE))
      se_warning[i] <- any(vapply(exec$warnings, function(w) {
        pos <- regexpr(needle, w, fixed = TRUE)
        if (pos < 0) return(FALSE)
        after <- substr(w, pos + nchar(needle),
                        pos + nchar(needle))
        !grepl("^[0-9.]", after)
      }, logical(1)))
    }
  }
  per_beta <- data.frame(
    beta = beta_display,
    mean_logl = exec$mean.logl,
    n_rows = as.integer(prep$chain_rows),
    se_warning = se_warning,
    stringsAsFactors = FALSE
  )
  se_reliable <- !length(exec$warnings)
  list(
    logml = exec$logml,
    se = exec$se,
    n_beta = n,
    method = method,
    model_name = model_name,
    per_beta = per_beta,
    warnings = exec$warnings,
    se_reliable = se_reliable,
    beta_converted = prep$beta_converted,
    beta_source = prep$source,
    computed_at = fmt_display_time(),
    elapsed_ms = exec$elapsed_ms,
    app_version = app_version(),
    upstream_version = UPSTREAM_VERSION,
    upstream_sha = UPSTREAM_SHA,
    screen_theme = screen_theme,
    lang = normalize_lang(lang)
  )
}

# Create a deterministic synthetic power-posterior archive for the in-app demo
# and for end-to-end tests. It is labelled as synthetic in the UI.
ml_demo_zip <- function(session_dir, n = 5, a = 5, rows = 200, seed = 20261024) {
  dir <- new_run_dir(session_dir)
  beta <- mcmc3r::make.beta(n, "step-stones", a)
  set.seed(seed)
  write_text_file(
    format(beta, scientific = TRUE, digits = 17, trim = TRUE),
    file.path(dir, "beta.txt")
  )
  for (i in seq_len(n)) {
    dir.create(file.path(dir, as.character(i)))
    lnl <- -1500 + 900 * max(beta[i], 1e-300) +
      stats::rnorm(rows, mean = 0, sd = 4)
    data.table::fwrite(
      data.frame(
        Iteration = seq_len(rows),
        lnL = round(lnl, 4)
      ),
      file = file.path(dir, as.character(i), "mcmc.txt"),
      quote = FALSE
    )
  }
  zipfile <- file.path(dir, "ml_demo.zip")
  withr::with_dir(
    dir,
    zip::zip(
      zipfile = zipfile,
      files = c("beta.txt", paste0(seq_len(n), "/mcmc.txt")),
      mode = "mirror"
    )
  )
  zipfile
}
