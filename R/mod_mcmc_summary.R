# MCMC Summary module -----------------------------------------------------

mcmc_prefix_choices <- function(lang = "en") {
  c(
    stats::setNames("auto", tr("mcmc.auto", lang)),
    stats::setNames("t_", tr("mcmc.prefix.t", lang)),
    stats::setNames("tau_", tr("mcmc.prefix.tau", lang)),
    stats::setNames("custom", tr("mcmc.prefix.custom", lang))
  )
}

mcmc_separator_choices <- function(lang = "en") {
  c(
    stats::setNames("auto", tr("mcmc.auto", lang)),
    stats::setNames("space", tr("mcmc.sep_space", lang)),
    stats::setNames("tab", tr("mcmc.sep_tab", lang)),
    stats::setNames("comma", tr("mcmc.sep_comma", lang))
  )
}

mcmc_separator_value <- function(choice) {
  switch(
    as.character(choice %||% "auto")[1],
    space = "",
    tab = "\t",
    comma = ",",
    "auto"
  )
}

mcmc_example_names <- c("microcebus", "hominids", "carnivores")

load_mcmc_example <- function(name, module = "mcmc") {
  if (!name %in% mcmc_example_names) {
    stop_app("input", "MCMC-001", detail = paste0("unknown example=", name),
             context = list(module = module))
  }
  env <- new.env(parent = emptyenv())
  utils::data(list = name, package = "mcmc3r", envir = env)
  obj <- get(name, envir = env)
  df <- obj$mcmc
  if (!is.data.frame(df)) {
    stop_app("input", "MCMC-001", detail = "example has no mcmc table",
             context = list(module = module))
  }
  list(
    data = df,
    name = name,
    diagnostics = list(
      rows = nrow(df),
      columns = ncol(df),
      bytes = as.numeric(object.size(df)),
      separator = "in-memory",
      names = names(df)
    )
  )
}

mcmc_example_label <- function(name, lang = "en") {
  switch(
    name,
    microcebus = tr("mcmc.example.microcebus", lang),
    hominids = tr("mcmc.example.hominids", lang),
    carnivores = tr("mcmc.example.carnivores", lang),
    name
  )
}

mcmc_separator_label <- function(sep, lang = "en") {
  if (is.null(sep) || is.na(sep)) return("")
  if (identical(sep, "\t")) return(tr("mcmc.sep_tab", lang))
  if (identical(sep, ",")) return(tr("mcmc.sep_comma", lang))
  if (identical(sep, "in-memory")) return(tr("mcmc.in_memory", lang))
  tr("mcmc.sep_space", lang)
}

mod_mcmc_summary_ui <- function(id, lang = "en") {
  ns <- shiny::NS(id)
  shiny::tagList(
    page_header("mcmc.title", "mcmc.description", lang, icon = "file"),
    shiny::tags$div(
      class = "workbench-grid",
      control_panel(
        title_key = "mcmc.controls",
        lang = lang,
        shiny::fileInput(
          ns("file"),
          label = field_label("mcmc.upload", lang),
          accept = c(".txt", ".tsv", ".csv"),
          buttonLabel = tr("common.browse", lang),
          placeholder = tr("common.no_file", lang),
          width = "100%"
        ),
        shiny::tags$p(class = "field-note", tr_span("mcmc.upload_help", lang)),
        shiny::selectInput(
          ns("sep_choice"),
          label = field_label("mcmc.separator", lang, "mcmc.separator_help"),
          choices = mcmc_separator_choices(lang),
          selected = "auto",
          width = "100%"
        ),
        shiny::tags$div(
          class = "example-block",
          shiny::tags$span(class = "control-label", tr_span("mcmc.example", lang)),
          shiny::tags$div(
            class = "example-buttons",
            shiny::actionButton(ns("ex_microcebus"),
                                tr_span("mcmc.example.microcebus", lang),
                                class = "btn btn-sm btn-outline-secondary"),
            shiny::actionButton(ns("ex_hominids"),
                                tr_span("mcmc.example.hominids", lang),
                                class = "btn btn-sm btn-outline-secondary"),
            shiny::actionButton(ns("ex_carnivores"),
                                tr_span("mcmc.example.carnivores", lang),
                                class = "btn btn-sm btn-outline-secondary")
          ),
          shiny::tags$p(class = "field-note", tr_span("mcmc.example_note", lang))
        ),
        shiny::selectInput(
          ns("prefix"),
          label = field_label("mcmc.time_prefix", lang, "mcmc.prefix_help"),
          choices = mcmc_prefix_choices(lang),
          selected = "auto",
          width = "100%"
        ),
        shiny::conditionalPanel(
          condition = sprintf("input['%s'] == 'custom'", ns("prefix")),
          shiny::textInput(
            ns("custom_prefix"),
            label = field_label("mcmc.custom_prefix", lang, "mcmc.custom_prefix_help"),
            value = "",
            width = "100%"
          )
        ),
        shiny::checkboxInput(
          ns("show_preview"),
          label = tr_span("mcmc.show_preview", lang),
          value = TRUE
        ),
        shiny::tags$div(
          class = "run-row",
          run_button(ns("run"), "mcmc.run", lang),
          reset_button(ns("reset"), lang)
        ),
        footer = shiny::tags$p(class = "panel-hint", tr_span("mcmc.run_hint", lang))
      ),
      result_panel(
        title_key = "mcmc.results",
        lang = lang,
        shiny::uiOutput(ns("result_area"))
      )
    )
  )
}

mod_mcmc_summary_server <- function(id, lang, theme, active, session_dir,
                                    session_id = NULL) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns
    state <- shiny::reactiveValues(
      data = NULL, diagnostics = NULL, file_label = NULL,
      result = NULL, error = NULL, example = NULL
    )

    set_data <- function(df, label, diagnostics = NULL, example = NULL) {
      state$data <- df
      state$file_label <- label
      state$diagnostics <- diagnostics
      state$example <- example
      state$result <- NULL
      state$error <- NULL
      log_event("INFO", "mcmc", "file_loaded", session_id = session_id,
                rows = nrow(df), columns = ncol(df), example = example)
    }

    shiny::observeEvent(input$file, {
      file <- input$file
      if (is.null(file) || !nrow(file)) return()
      shiny::withProgress(message = tr("mcmc.uploading", lang()), value = 0.2, {
        tryCatch(
          {
            path <- stash_upload(file$datapath[[1]], file$name[[1]],
                                 session_dir, prefix = "mcmc")
            parsed <- mcmc_read(path, sep = mcmc_separator_value(input$sep_choice))
            set_data(parsed$data,
                     label = safe_basename(file$name[[1]]),
                     diagnostics = parsed$diagnostics)
            shiny::showNotification(tr("mcmc.parsed", lang()), type = "message")
          },
          app_error = function(e) {
            state$data <- NULL
            state$result <- NULL
            state$error <- e
            log_event("WARN", "mcmc", "file_failed", session_id = session_id,
                      code = e$code)
          },
          error = function(e) {
            state$data <- NULL
            state$result <- NULL
            state$error <- as_app_error(e, "mcmc")
            log_event("ERROR", "mcmc", "file_failed", session_id = session_id,
                      code = state$error$code)
          }
        )
      })
    })

    load_example <- function(name) {
      tryCatch(
        {
          ex <- load_mcmc_example(name)
          set_data(ex$data, label = tr("mcmc.example_loaded", lang(),
                                        name = mcmc_example_label(name, lang())),
                   diagnostics = ex$diagnostics,
                   example = name)
          shiny::showNotification(
            tr("mcmc.example_loaded", lang(), name = mcmc_example_label(name, lang())),
            type = "message"
          )
        },
        app_error = function(e) {
          state$error <- e
        },
        error = function(e) {
          state$error <- as_app_error(e, "mcmc")
        }
      )
    }

    shiny::observeEvent(input$ex_microcebus, load_example("microcebus"))
    shiny::observeEvent(input$ex_hominids, load_example("hominids"))
    shiny::observeEvent(input$ex_carnivores, load_example("carnivores"))

    shiny::observeEvent(input$run, {
      state$error <- NULL
      if (is.null(state$data)) {
        shiny::showNotification(tr("mcmc.no_data", lang()), type = "warning")
        return()
      }
      session$sendCustomMessage("run-state",
                                list(id = ns("run"), running = TRUE))
      on.exit(session$sendCustomMessage(
        "run-state", list(id = ns("run"), running = FALSE)
      ), add = TRUE)
      prefix <- input$prefix %||% "auto"
      if (identical(prefix, "custom")) prefix <- trimws(input$custom_prefix %||% "")
      start <- Sys.time()
      log_event("INFO", "mcmc", "run_start", session_id = session_id,
                prefix = prefix, rows = nrow(state$data))
      tryCatch(
        {
          result <- mcmc_summarise(state$data, prefix = prefix)
          elapsed_ms <- as.numeric(difftime(Sys.time(), start, units = "secs")) * 1000
          result$warnings <- append_slow_warning(result$warnings, elapsed_ms)
          state$result <- result
          log_event("INFO", "mcmc", "run_done", session_id = session_id,
                    rows_used = result$diagnostics$rows_used,
                    time_columns = result$diagnostics$time_columns,
                    elapsed_ms = round(elapsed_ms))
        },
        app_error = function(e) {
          state$result <- NULL
          state$error <- e
          log_event("WARN", "mcmc", "run_failed", session_id = session_id,
                    code = e$code)
        },
        error = function(e) {
          state$result <- NULL
          state$error <- as_app_error(e, "mcmc")
          log_event("ERROR", "mcmc", "run_failed", session_id = session_id,
                    code = state$error$code)
        }
      )
    })

    shiny::observeEvent(lang(), {
      shiny::updateSelectInput(
        session, "prefix",
        choices = mcmc_prefix_choices(lang()),
        selected = input$prefix %||% "auto"
      )
      shiny::updateSelectInput(
        session, "sep_choice",
        choices = mcmc_separator_choices(lang()),
        selected = input$sep_choice %||% "auto"
      )
    }, ignoreInit = FALSE)

    shiny::observeEvent(input$reset, {
      state$data <- NULL
      state$diagnostics <- NULL
      state$file_label <- NULL
      state$result <- NULL
      state$error <- NULL
      state$example <- NULL
      shiny::updateSelectInput(session, "prefix", selected = "auto")
      shiny::updateTextInput(session, "custom_prefix", value = "")
      shiny::updateSelectInput(session, "sep_choice", selected = "auto")
      shiny::updateCheckboxInput(session, "show_preview", value = TRUE)
      session$sendCustomMessage("reset-input", ns("file"))
      shiny::showNotification(tr("mcmc.reset_done", lang()), type = "message")
    })

    output$result_area <- shiny::renderUI({
      if (!is.null(state$error)) {
        return(app_error_ui(state$error, lang(), module = "mcmc"))
      }
      if (is.null(state$data)) {
        return(shiny::tagList(
          empty_state("mcmc.empty_title", "mcmc.empty_body", lang(), icon = "file"),
          shiny::tags$p(class = "hint-text", tr_span("mcmc.run_hint", lang()))
        ))
      }

      file_label <- if (!is.null(state$example)) {
        tr("mcmc.example_loaded", lang(), name = mcmc_example_label(state$example, lang()))
      } else {
        state$file_label
      }
      diagnostics_card <- shiny::tags$div(
        class = "card-block",
        shiny::tags$div(
          class = "card-head",
          shiny::tags$h2(class = "card-title", tr_span("mcmc.diagnostics", lang()))
        ),
        diag_grid(list(
          list(label = tr("mcmc.file", lang()), value = file_label),
          list(label = tr("mcmc.rows_in", lang()),
               value = fmt_int(nrow(state$data))),
          list(label = tr("mcmc.columns", lang()),
               value = fmt_int(ncol(state$data))),
          list(label = tr("mcmc.file_size", lang()),
               value = fmt_bytes(state$diagnostics$bytes))
        ))
      )

      preview_card <- if (isTRUE(input$show_preview)) {
        shiny::tags$div(
          class = "card-block",
          shiny::tags$div(
            class = "card-head",
            shiny::tags$h2(class = "card-title", tr_span("mcmc.preview", lang()))
          ),
          shiny::tags$p(class = "note",
                        tr("mcmc.preview_note", lang(),
                           cols = min(ncol(state$data), 20),
                           rows = min(nrow(state$data), 10))),
          DT::DTOutput(ns("preview_table"))
        )
      } else {
        NULL
      }

      if (is.null(state$result)) {
        return(shiny::tagList(
          diagnostics_card,
          preview_card,
          shiny::tags$p(class = "hint-text", tr_span("mcmc.run_hint", lang()))
        ))
      }

      res <- state$result
      diag <- res$diagnostics
      summary_card <- shiny::tags$div(
        class = "card-block",
        shiny::tags$div(
          class = "card-head",
          shiny::tags$h2(class = "card-title", tr_span("mcmc.summary", lang())),
          download_button(ns("download_csv"), "common.download_csv", lang())
        ),
        DT::DTOutput(ns("summary_table")),
        shiny::tags$p(class = "note", tr("mcmc.download_note", lang()))
      )
      run_diagnostics <- shiny::tags$div(
        class = "card-block",
        shiny::tags$div(
          class = "card-head",
          shiny::tags$h2(class = "card-title", tr_span("mcmc.diagnostics", lang()))
        ),
        diag_grid(list(
          list(label = tr("mcmc.rows_in", lang()), value = fmt_int(diag$rows_in)),
          list(label = tr("mcmc.rows_used", lang()), value = fmt_int(diag$rows_used)),
          list(label = tr("mcmc.rows_removed", lang()), value = fmt_int(diag$rows_removed)),
          list(label = tr("mcmc.time_columns", lang()), value = fmt_int(diag$time_columns)),
          list(label = tr("mcmc.columns", lang()), value = fmt_int(diag$columns)),
          list(label = tr("mcmc.non_finite", lang()), value = fmt_int(diag$non_finite)),
          list(label = tr("mcmc.file_size", lang()),
               value = fmt_bytes(state$diagnostics$bytes)),
          list(label = tr("mcmc.separator", lang()),
               value = mcmc_separator_label(state$diagnostics$separator, lang()))
        ))
      )

      shiny::tagList(
        alert_from_warnings(res$warnings, lang()),
        summary_card,
        run_diagnostics,
        preview_card,
        shiny::tags$p(class = "note", tr("mcmc.summary_note", lang()))
      )
    })

    output$preview_table <- DT::renderDT({
      shiny::req(state$data)
      shiny::req(active())
      df <- preview_df(state$data, max_cols = 20, max_rows = 10)
      DT::datatable(
        df,
        rownames = FALSE,
        options = list(
          dom = "t", paging = FALSE, scrollX = TRUE, scrollY = "280px",
          language = list(emptyTable = tr("dt.empty", lang()),
                          zeroRecords = tr("dt.no_records", lang()))
        ),
        class = "compact stripe"
      )
    })

    output$summary_table <- DT::renderDT({
      shiny::req(state$result)
      shiny::req(active())
      df <- state$result$table
      df <- df[, c("parameter", "mean", "median", "ci025", "ci975", "n")]
      names(df) <- c(
        tr("mcmc.parameter", lang()),
        tr("mcmc.mean", lang()),
        tr("mcmc.median", lang()),
        tr("mcmc.ci_low", lang()),
        tr("mcmc.ci_high", lang()),
        tr("mcmc.n", lang())
      )
      opts <- list(
        dom = "ltp", pageLength = 10, scrollX = TRUE,
        language = list(emptyTable = tr("dt.empty", lang()),
                        zeroRecords = tr("dt.no_records", lang()))
      )
      if (nrow(df) <= 10) {
        opts$dom <- "t"
        opts$paging <- FALSE
      }
      DT::datatable(
        df,
        rownames = FALSE,
        options = opts,
        class = "compact stripe"
      ) |>
        DT::formatRound(columns = 2:5, digits = 6)
    })

    output$download_csv <- shiny::downloadHandler(
      filename = function() {
        download_filename("mcmc-summary", "csv", lang(), "print")
      },
      content = function(file) {
        shiny::req(state$result)
        export_csv(mcmc_export_df(state$result), file)
      }
    )
  })
}
