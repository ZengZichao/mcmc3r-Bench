# Calibration Explorer module ---------------------------------------------

cal_type_choices <- function(lang = "en") {
  c(
    stats::setNames("L", tr("cal.type.L", lang)),
    stats::setNames("B", tr("cal.type.B", lang)),
    stats::setNames("U", tr("cal.type.U", lang))
  )
}

parse_probs <- function(text, module = "calibration") {
  parts <- unlist(strsplit(as.character(text %||% ""), "[,;[:space:]]+"))
  parts <- parts[nzchar(parts)]
  values <- suppressWarnings(as.numeric(parts))
  if (!length(values) || any(is.na(values)) || length(values) > 10) {
    stop_app("validation", "CAL-007", detail = paste0("probs=", text),
             context = list(module = module))
  }
  values
}

parse_xmax <- function(text, module = "calibration") {
  text <- trimws(as.character(text %||% ""))
  if (!nzchar(text)) return(NA_real_)
  value <- suppressWarnings(as.numeric(text))
  if (is.na(value)) {
    stop_app("validation", "CAL-008", detail = paste0("xmax=", text),
             context = list(module = module))
  }
  value
}

mod_calibration_ui <- function(id, lang = "en") {
  ns <- shiny::NS(id)
  shiny::tagList(
    page_header("cal.title", "cal.description", lang, icon = "sliders"),
    shiny::tags$div(
      class = "workbench-grid",
      control_panel(
        title_key = "cal.controls",
        lang = lang,
        shiny::selectInput(
          ns("type"),
          label = field_label("cal.type", lang, "cal.help.type"),
          choices = cal_type_choices(lang),
          selected = "L",
          width = "100%"
        ),
        shiny::conditionalPanel(
          condition = sprintf("input['%s'] != 'U'", ns("type")),
          shiny::numericInput(
            ns("tL"),
            label = field_label("cal.tL", lang, "cal.help.tL"),
            value = 10, min = 0, step = 0.1, width = "100%"
          )
        ),
        shiny::conditionalPanel(
          condition = sprintf("input['%s'] == 'B' || input['%s'] == 'U'",
                              ns("type"), ns("type")),
          shiny::numericInput(
            ns("tU"),
            label = field_label("cal.tU", lang, "cal.help.tU"),
            value = 20, min = 0, step = 0.1, width = "100%"
          )
        ),
        shiny::conditionalPanel(
          condition = sprintf("input['%s'] == 'L'", ns("type")),
          shiny::numericInput(
            ns("p"),
            label = field_label("cal.p", lang, "cal.help.p"),
            value = 0.1, min = 0, step = 0.05, width = "100%"
          ),
          shiny::numericInput(
            ns("c"),
            label = field_label("cal.c", lang, "cal.help.c"),
            value = 1, min = 0, step = 0.1, width = "100%"
          )
        ),
        shiny::conditionalPanel(
          condition = sprintf("input['%s'] == 'L' || input['%s'] == 'B'",
                              ns("type"), ns("type")),
          shiny::numericInput(
            ns("pL"),
            label = field_label("cal.pL", lang, "cal.help.pL"),
            value = 0.025, min = 0, max = 1, step = 0.005, width = "100%"
          )
        ),
        shiny::conditionalPanel(
          condition = sprintf("input['%s'] == 'B' || input['%s'] == 'U'",
                              ns("type"), ns("type")),
          shiny::numericInput(
            ns("pU"),
            label = field_label("cal.pU", lang, "cal.help.pU"),
            value = 0.025, min = 0, max = 1, step = 0.005, width = "100%"
          )
        ),
        shiny::tags$div(
          class = "form-field",
          `data-i18n-placeholder` = "cal.xmax.auto",
          shiny::textInput(
            ns("xmax"),
            label = field_label("cal.xmax", lang, "cal.help.xmax"),
            value = "",
            placeholder = tr("cal.xmax.auto", lang),
            width = "100%"
          )
        ),
        shiny::numericInput(
          ns("points"),
          label = field_label("cal.points", lang, "cal.help.points"),
          value = 1000, min = LIMITS$calibration_points_min,
          max = LIMITS$calibration_points_max, step = 100, width = "100%"
        ),
        shiny::tags$div(
          class = "form-field",
          shiny::tags$span(class = "control-label", tr_span("cal.show_options", lang)),
          shiny::checkboxInput(
            ns("show_density"),
            label = tr_span("cal.show_density", lang),
            value = TRUE
          ),
          shiny::checkboxInput(
            ns("show_cdf"),
            label = tr_span("cal.show_cdf", lang),
            value = FALSE
          )
        ),
        collapsible_advanced(
          lang = lang,
          shiny::textInput(
            ns("probs"),
            label = field_label("cal.probs", lang, "cal.probs.help"),
            value = "0.025, 0.5, 0.975",
            width = "100%"
          )
        ),
        shiny::tags$div(
          class = "run-row",
          run_button(ns("run"), "common.run", lang),
          reset_button(ns("reset"), lang)
        ),
        footer = shiny::tags$p(class = "panel-hint", tr_span("cal.run_hint", lang))
      ),
      result_panel(
        title_key = "cal.results",
        lang = lang,
        shiny::uiOutput(ns("result_area"))
      )
    )
  )
}

mod_calibration_server <- function(id, lang, theme, active, session_dir,
                                   session_id = NULL) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns
    state <- shiny::reactiveValues(result = NULL, error = NULL, running = FALSE)

    current_params <- function() {
      list(
        type = input$type %||% "L",
        tL = suppressWarnings(as.numeric(input$tL)),
        tU = suppressWarnings(as.numeric(input$tU)),
        p = suppressWarnings(as.numeric(input$p)),
        c = suppressWarnings(as.numeric(input$c)),
        pL = suppressWarnings(as.numeric(input$pL)),
        pU = suppressWarnings(as.numeric(input$pU)),
        xmax = parse_xmax(input$xmax),
        points = suppressWarnings(as.numeric(input$points)),
        probs = parse_probs(input$probs)
      )
    }

    shiny::observeEvent(input$run, {
      state$error <- NULL
      state$running <- TRUE
      session$sendCustomMessage("run-state",
                                list(id = ns("run"), running = TRUE))
      on.exit({
        state$running <- FALSE
        session$sendCustomMessage("run-state",
                                  list(id = ns("run"), running = FALSE))
      }, add = TRUE)
      start <- Sys.time()
      log_event("INFO", "calibration", "run_start", session_id = session_id,
                type = input$type, points = input$points)
      shiny::withProgress(
        message = tr("cal.running", lang()), value = 0.15,
        {
          tryCatch(
            {
              if (!isTRUE(input$show_density) && !isTRUE(input$show_cdf)) {
                stop_app("validation", "CAL-012",
                         context = list(module = "calibration"))
              }
              params <- current_params()
              shiny::incProgress(0.35, detail = tr("common.loading", lang()))
              result <- cal_compute(params)
              elapsed_ms <- as.numeric(difftime(Sys.time(), start, units = "secs")) * 1000
              result$warnings <- append_slow_warning(result$warnings, elapsed_ms)
              shiny::incProgress(0.4, detail = tr("common.loading", lang()))
              state$result <- result
              state$error <- NULL
              log_event("INFO", "calibration", "run_done", session_id = session_id,
                        type = result$type, elapsed_ms = round(elapsed_ms))
            },
            app_error = function(e) {
              state$result <- NULL
              state$error <- e
              log_event("WARN", "calibration", "run_failed",
                        session_id = session_id, code = e$code)
            },
            error = function(e) {
              state$result <- NULL
              state$error <- as_app_error(e, "calibration")
              log_event("ERROR", "calibration", "run_failed",
                        session_id = session_id, code = state$error$code)
            }
          )
        }
      )
    })

    shiny::observeEvent(lang(), {
      shiny::updateSelectInput(
        session, "type",
        choices = cal_type_choices(lang()),
        selected = input$type %||% "L"
      )
    }, ignoreInit = FALSE)

    shiny::observeEvent(input$reset, {
      state$result <- NULL
      state$error <- NULL
      shiny::updateSelectInput(session, "type", selected = "L")
      shiny::updateNumericInput(session, "tL", value = 10)
      shiny::updateNumericInput(session, "tU", value = 20)
      shiny::updateNumericInput(session, "p", value = 0.1)
      shiny::updateNumericInput(session, "c", value = 1)
      shiny::updateNumericInput(session, "pL", value = 0.025)
      shiny::updateNumericInput(session, "pU", value = 0.025)
      shiny::updateTextInput(session, "xmax", value = "")
      shiny::updateNumericInput(session, "points", value = 1000)
      shiny::updateCheckboxInput(session, "show_density", value = TRUE)
      shiny::updateCheckboxInput(session, "show_cdf", value = FALSE)
      shiny::updateTextInput(session, "probs", value = "0.025, 0.5, 0.975")
      shiny::showNotification(tr("cal.reset_done", lang()), type = "message")
    })

    show_density <- shiny::reactive(isTRUE(input$show_density))
    show_cdf <- shiny::reactive(isTRUE(input$show_cdf))
    export_theme <- shiny::reactive(input$export_theme %||% "print")
    export_dpi <- shiny::reactive(as.numeric(input$dpi %||% 150))

    output$result_area <- shiny::renderUI({
      if (!is.null(state$error)) {
        return(app_error_ui(state$error, lang(), module = "calibration"))
      }
      if (is.null(state$result)) {
        return(shiny::tagList(
          empty_state("cal.empty_title", "cal.empty_body", lang(), icon = "chart"),
          shiny::tags$p(class = "hint-text", tr_span("cal.run_hint", lang()))
        ))
      }
      res <- state$result
      shiny::tagList(
        alert_from_warnings(res$warnings, lang()),
        shiny::tags$div(
          class = "result-card",
          result_toolbar(
            lang = lang(),
            shiny::tags$div(
              class = "export-controls",
              shiny::radioButtons(
                ns("export_theme"),
                label = tr_span("common.export_theme", lang()),
                choices = export_theme_choices(lang()),
                selected = "print",
                inline = TRUE
              ),
              shiny::selectInput(
                ns("dpi"),
                label = tr_span("common.dpi", lang()),
                choices = c("150" = 150, "300" = 300),
                selected = 150,
                width = "110px"
              )
            ),
            shiny::tags$div(
              class = "download-group",
              download_button(ns("download_csv"), "common.download_csv", lang()),
              download_button(ns("download_png"), "common.download_png", lang()),
              download_button(ns("download_pdf"), "common.download_pdf", lang())
            )
          ),
          shiny::tags$div(class = "plot-wrap", shiny::plotOutput(ns("plot"), height = "420px")),
          section_card(
            "cal.quantiles_title", lang(),
            DT::DTOutput(ns("quantile_table"))
          ),
          section_card(
            "cal.syntax_title", lang(),
            shiny::tags$p(class = "note", tr("cal.syntax_note", lang())),
            code_block(ns("syntax"), res$syntax, lang(), "cal.copy_syntax")
          ),
          section_card(
            "cal.data_title", lang(),
            shiny::tags$p(class = "note", tr("cal.data_note", lang())),
            DT::DTOutput(ns("data_table")),
            shiny::tags$p(
              class = "note",
              tr("cal.data_preview_note", lang(), n = min(nrow(res$table), 500))
            )
          ),
          shiny::tags$p(
            class = "note",
            tr("cal.summary_note", lang()),
            if (isTRUE(res$xmax_auto)) {
              paste0(" ", tr("cal.xmax.auto", lang()), ": ", fmt_num(res$xmax), " Ma.")
            } else {
              NULL
            }
          )
        )
      )
    })

    output$plot <- shiny::renderPlot({
      shiny::req(state$result)
      shiny::req(active())
      draw_calibration(
        state$result,
        lang = lang(),
        theme = theme(),
        show_density = if (show_density() || !show_cdf()) TRUE else FALSE,
        show_cdf = show_cdf()
      )
    }, res = 96, bg = "transparent")

    output$quantile_table <- DT::renderDT({
      shiny::req(state$result)
      shiny::req(active())
      df <- state$result$quantiles
      names(df) <- c(tr("cal.quantile_prob", lang()), tr("cal.quantile_value", lang()))
      DT::datatable(
        df,
        rownames = FALSE,
        options = list(
          dom = "t", paging = FALSE, ordering = FALSE,
          language = list(emptyTable = tr("dt.empty", lang()),
                          zeroRecords = tr("dt.no_records", lang()))
        ),
        class = "compact stripe"
      ) |>
        DT::formatRound(columns = seq_len(ncol(df)), digits = 6)
    })

    output$data_table <- DT::renderDT({
      shiny::req(state$result)
      shiny::req(active())
      df <- utils::head(state$result$table, 500)
      names(df) <- c(tr("plot.axis_time", lang()),
                     tr("plot.axis_density", lang()),
                     tr("plot.axis_cdf", lang()))
      DT::datatable(
        df,
        rownames = FALSE,
        options = list(
          dom = "ltp", pageLength = 10, scrollX = TRUE,
          language = list(emptyTable = tr("dt.empty", lang()),
                          zeroRecords = tr("dt.no_records", lang()))
        ),
        class = "compact stripe"
      ) |>
        DT::formatSignif(columns = 2:3, digits = 6)
    })

    output$download_csv <- shiny::downloadHandler(
      filename = function() {
        download_filename("calibration", "csv", lang(), export_theme())
      },
      content = function(file) {
        shiny::req(state$result)
        export_csv(calibration_export_df(state$result), file)
      }
    )

    output$download_png <- shiny::downloadHandler(
      filename = function() {
        download_filename("calibration", "png", lang(), export_theme())
      },
      content = function(file) {
        shiny::req(state$result)
        res <- state$result
        plot_theme <- if (identical(export_theme(), "print")) "light" else theme()
        dpi <- if (export_dpi() >= 300) 300 else 150
        width <- if (dpi == 300) 3200 else 1600
        height <- if (dpi == 300) 2400 else 1200
        save_plot_png(
          file,
          draw = function(colors) draw_calibration(
            res, lang = lang(), theme = plot_theme,
            show_density = if (show_density() || !show_cdf()) TRUE else FALSE,
            show_cdf = show_cdf()
          ),
          theme = plot_theme, width = width, height = height, res = dpi
        )
      }
    )

    output$download_pdf <- shiny::downloadHandler(
      filename = function() {
        download_filename("calibration", "pdf", lang(), export_theme())
      },
      content = function(file) {
        shiny::req(state$result)
        res <- state$result
        plot_theme <- if (identical(export_theme(), "print")) "light" else theme()
        save_plot_pdf(
          file,
          draw = function(colors) draw_calibration(
            res, lang = lang(), theme = plot_theme,
            show_density = if (show_density() || !show_cdf()) TRUE else FALSE,
            show_cdf = show_cdf()
          ),
          theme = plot_theme
        )
      }
    )
  })
}
