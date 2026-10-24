# Export service ----------------------------------------------------------

result_metadata <- function(module, lang = "en", screen_theme = "light",
                            export_theme = "print", extra = list()) {
  meta <- list(
    app = APP_NAME,
    app_version = app_version(),
    doc_version = DOC_VERSION,
    module = module,
    lang = normalize_lang(lang),
    screen_theme = screen_theme,
    export_theme = export_theme,
    upstream_version = UPSTREAM_VERSION,
    upstream_sha = UPSTREAM_SHA,
    computed_at_utc = format(Sys.time(), tz = "UTC", "%Y-%m-%dT%H:%M:%SZ")
  )
  if (length(extra)) meta <- c(meta, extra)
  meta
}

export_csv <- function(df, path) {
  write_csv_safe(df, path)
  path
}

export_metadata_json <- function(meta, path) {
  jsonlite::write_json(meta, path, auto_unbox = TRUE, pretty = TRUE,
                       null = "null")
  path
}

export_bundle_zip <- function(files, zipfile) {
  if (!length(files)) stop("No files to bundle", call. = FALSE)
  root <- dirname(files[[1]])
  zipfile <- normalizePath(zipfile, mustWork = FALSE)
  withr::with_dir(
    root,
    zip::zip(zipfile = zipfile, files = basename(files), mode = "mirror")
  )
  zipfile
}

# Build the downloadable calibration data with a stable English column order.
calibration_export_df <- function(result) {
  data.frame(
    x = result$table$x,
    density = result$table$density,
    cdf = result$table$cdf,
    stringsAsFactors = FALSE
  )
}

mcmc_export_df <- function(result) {
  out <- result$table
  rownames(out) <- NULL
  out[, c("parameter", "mean", "median", "ci025", "ci975", "n"), drop = FALSE]
}

ml_summary_export_df <- function(result) {
  data.frame(
    model = result$model_name,
    method = result$method,
    logml = result$logml,
    se = result$se,
    n_beta = result$n_beta,
    se_reliable = result$se_reliable,
    beta_zero_converted = result$beta_converted,
    computed_at = result$computed_at,
    app_version = result$app_version,
    upstream_version = result$upstream_version,
    upstream_sha = result$upstream_sha,
    stringsAsFactors = FALSE
  )
}

ml_detail_export_df <- function(result) {
  out <- result$per_beta
  out$method <- result$method
  out$model <- result$model_name
  rownames(out) <- NULL
  out
}
