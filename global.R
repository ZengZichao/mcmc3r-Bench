# Global setup ------------------------------------------------------------
# This file is sourced once when the Shiny app starts. It loads dependencies,
# initialises i18n, registers the bundled Chinese font, and sources the
# application modules in dependency order.

app_root <- normalizePath(getwd(), mustWork = TRUE)
if (!file.exists(file.path(app_root, "app.R"))) {
  alt <- Sys.getenv("MCMC3R_APP_DIR", "")
  if (nzchar(alt) && dir.exists(alt)) {
    app_root <- normalizePath(alt, mustWork = TRUE)
  }
}
options(mcmc3r.app_dir = app_root)

required_packages <- c(
  "shiny", "bslib", "DT", "data.table", "withr", "zip", "jsonlite",
  "commonmark", "showtext", "sysfonts", "systemfonts"
)
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]
if (length(missing_packages)) {
  stop(
    "Missing required R packages: ", paste(missing_packages, collapse = ", "),
    ". Restore the project library with renv::restore() or install them from CRAN.",
    call. = FALSE
  )
}
if (!requireNamespace("mcmc3r", quietly = TRUE)) {
  stop(
    "The upstream package mcmc3r is not installed. Install it from ",
    "https://github.com/dosreislab/mcmc3r at the pinned commit recorded in ",
    "R/app_meta.R, then restart the app.",
    call. = FALSE
  )
}

options(shiny.usecairo = TRUE)
if (requireNamespace("logger", quietly = TRUE)) {
  try(logger::log_threshold(Sys.getenv("MCMC3R_LOG_LEVEL", "INFO")), silent = TRUE)
}

source(file.path(app_root, "R", "app_meta.R"), local = FALSE)
source(file.path(app_root, "R", "fct_icons.R"), local = FALSE)
source(file.path(app_root, "R", "fct_i18n.R"), local = FALSE)
source(file.path(app_root, "R", "fct_errors.R"), local = FALSE)
source(file.path(app_root, "R", "fct_format.R"), local = FALSE)
source(file.path(app_root, "R", "utils_validation.R"), local = FALSE)
source(file.path(app_root, "R", "fct_theme.R"), local = FALSE)
source(file.path(app_root, "R", "fct_files.R"), local = FALSE)
source(file.path(app_root, "R", "fct_plots.R"), local = FALSE)
source(file.path(app_root, "R", "fct_ui.R"), local = FALSE)
source(file.path(app_root, "R", "services_calibration.R"), local = FALSE)
source(file.path(app_root, "R", "services_mcmc.R"), local = FALSE)
source(file.path(app_root, "R", "services_marginal.R"), local = FALSE)
source(file.path(app_root, "R", "services_export.R"), local = FALSE)
source(file.path(app_root, "R", "mod_calibration.R"), local = FALSE)
source(file.path(app_root, "R", "mod_mcmc_summary.R"), local = FALSE)
source(file.path(app_root, "R", "mod_marginal.R"), local = FALSE)
source(file.path(app_root, "R", "mod_help.R"), local = FALSE)
source(file.path(app_root, "R", "mod_about.R"), local = FALSE)
source(file.path(app_root, "R", "app_ui.R"), local = FALSE)
source(file.path(app_root, "R", "app_server.R"), local = FALSE)

options(shiny.maxRequestSize = LIMITS$upload_total_mb * 1024^2)
i18n_load(file.path(app_root, "i18n", "translations.csv"))
register_app_font()
options(mcmc3r.font.ready = TRUE)

log_event("INFO", "app", "startup", session_id = NULL)
