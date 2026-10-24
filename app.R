# Application entry point -------------------------------------------------
# The UI is a function so that ?lang=zh / ?lang=en is honoured on first render.
# Theme initialisation happens in an inline <head> script to avoid flashes.
#
# Initialisation is performed here as well as in global.R so that the app works
# regardless of whether the hosting environment sources global.R before app.R.

app_root <- normalizePath(getwd(), mustWork = TRUE)
if (!file.exists(file.path(app_root, "app.R"))) {
  alt <- Sys.getenv("MCMC3R_APP_DIR", "")
  if (nzchar(alt) && dir.exists(alt)) app_root <- normalizePath(alt, mustWork = TRUE)
}
options(mcmc3r.app_dir = app_root)
options(shiny.usecairo = TRUE)

if (!is.function(get0("i18n_load", mode = "function"))) {
  for (file in c(
    "app_meta.R", "fct_icons.R", "fct_i18n.R", "fct_errors.R", "fct_format.R",
    "utils_validation.R", "fct_theme.R", "fct_files.R", "fct_plots.R",
    "fct_ui.R", "services_calibration.R", "services_mcmc.R",
    "services_marginal.R", "services_export.R", "mod_calibration.R",
    "mod_mcmc_summary.R", "mod_marginal.R", "mod_help.R", "mod_about.R",
    "app_ui.R", "app_server.R"
  )) {
    source(file.path(app_root, "R", file), local = FALSE)
  }
}

options(shiny.maxRequestSize = LIMITS$upload_total_mb * 1024^2)
if (is.null(getOption("mcmc3r.i18n.table"))) {
  i18n_load(file.path(app_root, "i18n", "translations.csv"))
}
if (!isTRUE(getOption("mcmc3r.font.ready"))) {
  register_app_font()
  options(mcmc3r.font.ready = TRUE)
}

shiny::shinyApp(ui = app_ui, server = app_server)
