# Server -------------------------------------------------------------------

app_server <- function(input, output, session) {
  session_dir <- new_session_dir()
  session_id <- substr(session$token, 1, 8)

  session$onSessionEnded(function() {
    log_event("INFO", "app", "session_end", session_id = session_id)
    unlink(session_dir, recursive = TRUE, force = TRUE)
  })

  query <- tryCatch(session$clientData$url_search, error = function(e) "")
  initial_lang <- lang_from_query(query %||% "") %||% "en"
  lang <- shiny::reactiveVal(initial_lang)
  env_theme <- Sys.getenv("MCMC3R_DEFAULT_THEME", "auto")
  theme <- shiny::reactiveVal(
    if (env_theme %in% c("light", "dark")) env_theme else "light"
  )
  active_tab <- shiny::reactiveVal("calibration")

  # URL parameters are authoritative on first load. clientData may arrive after
  # the server function starts, so this observer also covers that case.
  shiny::observeEvent(session$clientData$url_search, {
    query <- session$clientData$url_search %||% ""
    qlang <- lang_from_query(query)
    if (!is.null(qlang)) lang(qlang)
    parsed <- tryCatch(shiny::parseQueryString(query, nested = FALSE),
                       error = function(e) list())
    if (!is.null(parsed$theme) && parsed$theme %in% c("light", "dark")) {
      theme(parsed$theme)
    }
  }, ignoreInit = FALSE)

  shiny::observeEvent(input$lang, {
    value <- normalize_lang(input$lang)
    if (!identical(value, lang())) {
      lang(value)
      log_event("INFO", "app", "lang_switch", session_id = session_id,
                lang = value)
    }
  }, ignoreNULL = TRUE)

  shiny::observeEvent(input$theme, {
    value <- if (identical(input$theme, "dark")) "dark" else "light"
    if (!identical(value, theme())) {
      theme(value)
      log_event("INFO", "app", "theme_switch", session_id = session_id,
                theme = value)
    }
  }, ignoreNULL = TRUE)

  shiny::observeEvent(input$active_tab, {
    value <- as.character(input$active_tab)[1]
    if (value %in% c("calibration", "mcmc", "marginal", "help", "about")) {
      active_tab(value)
    }
  }, ignoreNULL = TRUE)

  calibration_active <- shiny::reactive(identical(active_tab(), "calibration"))
  mcmc_active <- shiny::reactive(identical(active_tab(), "mcmc"))
  marginal_active <- shiny::reactive(identical(active_tab(), "marginal"))

  mod_calibration_server("calibration", lang, theme, calibration_active,
                         session_dir, session_id)
  mod_mcmc_summary_server("mcmc", lang, theme, mcmc_active,
                          session_dir, session_id)
  mod_marginal_server("marginal", lang, theme, marginal_active,
                      session_dir, session_id)
  mod_help_server("help", lang)
  mod_about_server("about", lang)

  log_event("INFO", "app", "session_start", session_id = session_id,
            lang = initial_lang)
}
