# Marginal Likelihood module ----------------------------------------------

ml_method_choices <- function(lang = "en") {
  c(
    stats::setNames("step-stones", tr("ml.method.ss", lang)),
    stats::setNames("gauss-quad", tr("ml.method.gq", lang))
  )
}

ml_chain_source_choices <- function(lang = "en") {
  c(
    stats::setNames("zip", tr("ml.chain_zip", lang)),
    stats::setNames("files", tr("ml.chain_files", lang))
  )
}

ml_beta_source_choices <- function(lang = "en") {
  c(
    stats::setNames("upload", tr("ml.beta_upload", lang)),
    stats::setNames("generate", tr("ml.beta_generate", lang))
  )
}

mod_marginal_ui <- function(id, lang = "en") {
  ns <- shiny::NS(id)
  shiny::tagList(
    page_header("ml.title", "ml.description", lang, icon = "tree"),
    shiny::tags$div(
      class = "workbench-grid",
      control_panel(
        title_key = "ml.controls",
        lang = lang,
        shiny::selectInput(
          ns("method"),
          label = field_label("ml.method", lang, "ml.method_help"),
          choices = ml_method_choices(lang),
          selected = "step-stones",
          width = "100%"
        ),
        shiny::conditionalPanel(
          condition = sprintf("input['%s'] == 'step-stones'", ns("method")),
          shiny::tags$p(class = "field-note", tr_span("ml.method_ss_help", lang))
        ),
        shiny::conditionalPanel(
          condition = sprintf("input['%s'] == 'gauss-quad'", ns("method")),
          shiny::tags$p(class = "field-note", tr_span("ml.method_gq_help", lang))
        ),
        shiny::textInput(
          ns("model_name"),
          label = field_label("ml.model", lang),
          value = "",
          placeholder = tr("ml.model_placeholder", lang),
          width = "100%"
        ),
        shiny::tags$div(class = "control-section-title", tr_span("ml.chains", lang)),
        shiny::radioButtons(
          ns("chain_source"),
          label = field_label("ml.chain_source", lang),
          choices = ml_chain_source_choices(lang),
          selected = "zip"
        ),
        shiny::conditionalPanel(
          condition = sprintf("input['%s'] == 'zip'", ns("chain_source")),
          shiny::fileInput(
            ns("zip"),
            label = field_label("ml.upload_zip", lang),
            accept = ".zip",
            buttonLabel = tr("common.browse", lang),
            placeholder = tr("common.no_file", lang),
            width = "100%"
          ),
          shiny::tags$p(class = "field-note", tr_span("ml.zip_structure_help", lang))
        ),
        shiny::conditionalPanel(
          condition = sprintf("input['%s'] == 'files'", ns("chain_source")),
          shiny::fileInput(
            ns("files"),
            label = field_label("ml.upload_files", lang),
            accept = c(".txt", ".tsv", ".csv"),
            multiple = TRUE,
            buttonLabel = tr("common.browse", lang),
            placeholder = tr("common.no_file", lang),
            width = "100%"
          ),
          shiny::tags$p(class = "field-note", tr_span("ml.chain_selection_note", lang)),
          shiny::radioButtons(
            ns("beta_source"),
            label = field_label("ml.beta_source", lang),
            choices = ml_beta_source_choices(lang),
            selected = "upload"
          ),
          shiny::conditionalPanel(
            condition = sprintf("input['%s'] == 'upload'", ns("beta_source")),
            shiny::fileInput(
              ns("beta_file"),
              label = field_label("ml.beta_file", lang),
              accept = c(".txt", ".tsv", ".csv"),
              buttonLabel = tr("common.browse", lang),
              placeholder = tr("common.no_file", lang),
              width = "100%"
            ),
            shiny::tags$p(class = "field-note", tr_span("ml.beta_upload_help", lang))
          )
        ),
        collapsible_advanced(
          lang = lang,
          open = TRUE,
          shiny::tags$p(class = "field-note", tr_span("ml.beta_note", lang)),
          shiny::conditionalPanel(
            condition = sprintf("input['%s'] == 'zip'", ns("chain_source")),
            shiny::tags$p(class = "field-note", tr_span("ml.generated_for_download", lang))
          ),
          shiny::numericInput(
            ns("beta_n"),
            label = field_label("ml.beta_n", lang),
            value = 5, min = 1, max = 100, step = 1, width = "100%"
          ),
          shiny::conditionalPanel(
            condition = sprintf("input['%s'] == 'step-stones'", ns("method")),
            shiny::numericInput(
              ns("beta_a"),
              label = field_label("ml.beta_a", lang, "ml.beta_a_help"),
              value = 5, min = 0.1, step = 0.5, width = "100%"
            )
          ),
          shiny::tags$div(
            class = "run-row",
            shiny::actionButton(
              ns("generate"),
              label = shiny::tagList(shiny::HTML(icon_svg("sliders", 16)),
                                     tr_span("ml.generate", lang)),
              class = "btn btn-sm btn-outline-secondary"
            ),
            download_button(ns("download_beta"), "ml.beta_download", lang)
          ),
          shiny::uiOutput(ns("beta_preview_area"))
        ),
        shiny::tags$div(
          class = "example-block",
          shiny::actionButton(
            ns("demo"),
            label = shiny::tagList(shiny::HTML(icon_svg("chart", 16)),
                                   tr_span("ml.demo", lang)),
            class = "btn btn-sm btn-outline-secondary"
          ),
          shiny::tags$p(class = "field-note", tr_span("ml.example_zip_note", lang))
        ),
        shiny::tags$div(
          class = "run-row",
          run_button(ns("run"), "ml.run", lang),
          reset_button(ns("reset"), lang)
        ),
        footer = shiny::tags$div(
          shiny::tags$p(class = "panel-hint", tr_span("ml.run_hint", lang)),
          shiny::tags$p(class = "panel-hint small",
                        tr("ml.limits", lang,
                           ss = LIMITS$beta_max_ss,
                           gq = LIMITS$beta_max_gq,
                           gauss = LIMITS$gauss_max,
                           chains = LIMITS$chains_max))
        )
      ),
      result_panel(
        title_key = "ml.results",
        lang = lang,
        shiny::uiOutput(ns("result_area"))
      )
    )
  )
}

mod_marginal_server <- function(id, lang, theme, active, session_dir,
                                session_id = NULL) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns
    state <- shiny::reactiveValues(
      result = NULL, error = NULL, generated_beta = NULL,
      generated_method = NULL, demo_path = NULL
    )

    shiny::observeEvent(input$method, {
      state$result <- NULL
      state$generated_beta <- NULL
      state$generated_method <- NULL
    }, ignoreInit = TRUE)

    shiny::observeEvent(input$chain_source, {
      state$result <- NULL
      state$error <- NULL
    }, ignoreInit = TRUE)

    shiny::observeEvent(input$beta_source, {
      state$result <- NULL
      state$error <- NULL
    }, ignoreInit = TRUE)

    shiny::observeEvent(input$zip, {
      if (!is.null(input$zip) && nrow(input$zip)) {
        state$demo_path <- NULL
        state$result <- NULL
        state$error <- NULL
      }
    }, ignoreInit = TRUE)

    shiny::observeEvent(input$files, {
      state$result <- NULL
      state$error <- NULL
    }, ignoreInit = TRUE)

    shiny::observeEvent(input$beta_file, {
      state$result <- NULL
      state$error <- NULL
    }, ignoreInit = TRUE)

    shiny::observeEvent(lang(), {
      shiny::updateSelectInput(
        session, "method",
        choices = ml_method_choices(lang()),
        selected = input$method %||% "step-stones"
      )
      shiny::updateRadioButtons(
        session, "chain_source",
        choices = ml_chain_source_choices(lang()),
        selected = input$chain_source %||% "zip"
      )
      shiny::updateRadioButtons(
        session, "beta_source",
        choices = ml_beta_source_choices(lang()),
        selected = input$beta_source %||% "upload"
      )
    }, ignoreInit = FALSE)

    shiny::observeEvent(input$generate, {
      tryCatch(
        {
          beta <- ml_beta_generate(
            n = suppressWarnings(as.numeric(input$beta_n)),
            method = input$method %||% "step-stones",
            a = suppressWarnings(as.numeric(input$beta_a %||% 5))
          )
          state$generated_beta <- beta
          state$generated_method <- input$method
          state$error <- NULL
          shiny::showNotification(
            tr("ml.beta_generated_note", lang(),
               n = length(beta),
               method = tr(ml_method_label_key(input$method), lang())),
            type = "message"
          )
        },
        app_error = function(e) state$error <- e,
        error = function(e) state$error <- as_app_error(e, "marginal")
      )
    })

    shiny::observeEvent(input$demo, {
      tryCatch(
        {
          path <- ml_demo_zip(session_dir)
          state$demo_path <- path
          state$result <- NULL
          state$error <- NULL
          shiny::updateRadioButtons(session, "chain_source", selected = "zip")
          session$sendCustomMessage("reset-input", ns("zip"))
          shiny::showNotification(tr("ml.demo_loaded", lang()), type = "message")
        },
        app_error = function(e) state$error <- e,
        error = function(e) state$error <- as_app_error(e, "marginal")
      )
    })

    shiny::observeEvent(input$run, {
      state$error <- NULL
      session$sendCustomMessage("run-state",
                                list(id = ns("run"), running = TRUE))
      on.exit(session$sendCustomMessage(
        "run-state", list(id = ns("run"), running = FALSE)
      ), add = TRUE)
      method <- input$method %||% "step-stones"
      chain_source <- input$chain_source %||% "zip"
      model_name <- trimws(input$model_name %||% "")
      model_name <- gsub("[\r\n\t]+", " ", model_name)
      if (nchar(model_name) > 80) model_name <- substr(model_name, 1, 80)
      if (!nzchar(model_name)) model_name <- tr("ml.model_name_default", lang())

      start <- Sys.time()
      log_event("INFO", "marginal", "run_start", session_id = session_id,
                method = method, source = chain_source)

      shiny::withProgress(
        message = tr("common.loading", lang()), value = 0.1,
        {
          tryCatch(
            {
              if (identical(chain_source, "zip")) {
                zip_input <- input$zip
                zip_path <- NULL
                if (!is.null(zip_input) && nrow(zip_input)) {
                  zip_path <- stash_upload(zip_input$datapath[[1]],
                                           zip_input$name[[1]], session_dir,
                                           prefix = "ml-zip")
                } else if (!is.null(state$demo_path)) {
                  zip_path <- state$demo_path
                }
                if (is.null(zip_path)) {
                  shiny::showNotification(tr("ml.chain_required", lang()),
                                          type = "warning")
                  return()
                }
                shiny::incProgress(0.15, detail = tr("common.loading", lang()))
                prep <- ml_prepare_zip(zip_path, session_dir, method)
              } else {
                files <- input$files
                if (is.null(files) || !nrow(files)) {
                  shiny::showNotification(tr("ml.chain_required", lang()),
                                          type = "warning")
                  return()
                }
                paths <- vapply(seq_len(nrow(files)), function(i) {
                  stash_upload(files$datapath[[i]], files$name[[i]], session_dir,
                               prefix = "ml-chain")
                }, character(1))
                beta_source <- input$beta_source %||% "upload"
                if (identical(beta_source, "generate")) {
                  beta <- state$generated_beta
                  if (is.null(beta) || !identical(state$generated_method, method)) {
                    beta <- ml_beta_generate(
                      n = suppressWarnings(as.numeric(input$beta_n)),
                      method = method,
                      a = suppressWarnings(as.numeric(input$beta_a %||% 5))
                    )
                    state$generated_beta <- beta
                    state$generated_method <- method
                  }
                } else {
                  beta_input <- input$beta_file
                  if (is.null(beta_input) || !nrow(beta_input)) {
                    shiny::showNotification(tr("ml.beta_required", lang()),
                                            type = "warning")
                    return()
                  }
                  beta_path <- stash_upload(beta_input$datapath[[1]],
                                            beta_input$name[[1]], session_dir,
                                            prefix = "ml-beta")
                  beta <- ml_beta_read_file(beta_path)
                }
                shiny::incProgress(0.15, detail = tr("common.loading", lang()))
                prep <- ml_prepare_files(paths, beta, session_dir, method)
              }

              shiny::incProgress(0.3, detail = tr("common.loading", lang()))
              exec <- ml_execute(prep$run_dir, method)
              shiny::incProgress(0.35, detail = tr("common.loading", lang()))
              result <- ml_result_object(
                prep, exec, method, model_name = model_name,
                screen_theme = theme(), lang = lang()
              )
              elapsed_ms <- as.numeric(difftime(Sys.time(), start, units = "secs")) * 1000
              result$warnings <- append_slow_warning(result$warnings, elapsed_ms)
              state$result <- result
              state$error <- NULL
              log_event("INFO", "marginal", "run_done", session_id = session_id,
                        method = method, n_beta = result$n_beta,
                        logml = round(result$logml, 4),
                        elapsed_ms = round(elapsed_ms))
            },
            app_error = function(e) {
              state$result <- NULL
              state$error <- e
              log_event("WARN", "marginal", "run_failed", session_id = session_id,
                        code = e$code)
            },
            error = function(e) {
              state$result <- NULL
              state$error <- as_app_error(e, "marginal")
              log_event("ERROR", "marginal", "run_failed", session_id = session_id,
                        code = state$error$code)
            }
          )
        }
      )
    })

    shiny::observeEvent(input$reset, {
      state$result <- NULL
      state$error <- NULL
      state$generated_beta <- NULL
      state$generated_method <- NULL
      state$demo_path <- NULL
      shiny::updateSelectInput(session, "method", selected = "step-stones")
      shiny::updateRadioButtons(session, "chain_source", selected = "zip")
      shiny::updateRadioButtons(session, "beta_source", selected = "upload")
      shiny::updateNumericInput(session, "beta_n", value = 5)
      shiny::updateNumericInput(session, "beta_a", value = 5)
      shiny::updateTextInput(session, "model_name", value = "")
      session$sendCustomMessage("reset-input", ns("zip"))
      session$sendCustomMessage("reset-input", ns("files"))
      session$sendCustomMessage("reset-input", ns("beta_file"))
      shiny::showNotification(tr("ml.reset_done", lang()), type = "message")
    })

    output$beta_preview_area <- shiny::renderUI({
      beta <- state$generated_beta
      if (is.null(beta)) return(NULL)
      shiny::tagList(
        shiny::tags$p(
          class = "field-note",
          tr("ml.beta_generated_note", lang(), n = length(beta),
             method = tr(ml_method_label_key(state$generated_method), lang()))
        ),
        DT::DTOutput(ns("beta_preview"))
      )
    })

    output$beta_preview <- DT::renderDT({
      shiny::req(state$generated_beta)
      df <- data.frame(beta = state$generated_beta)
      names(df) <- tr("ml.beta_col", lang())
      DT::datatable(
        df,
        rownames = FALSE,
        options = list(
          dom = "t", paging = FALSE, scrollY = "180px",
          language = list(emptyTable = tr("dt.empty", lang()),
                          zeroRecords = tr("dt.no_records", lang()))
        ),
        class = "compact stripe"
      ) |>
        DT::formatSignif(columns = 1, digits = 8)
    })

    export_theme <- shiny::reactive(input$export_theme %||% "print")
    export_dpi <- shiny::reactive(as.numeric(input$dpi %||% 150))

    output$result_area <- shiny::renderUI({
      if (!is.null(state$error)) {
        return(app_error_ui(state$error, lang(), module = "marginal"))
      }

      demo_alert <- if (!is.null(state$demo_path)) {
        shiny::tags$div(
          class = "app-alert app-alert-info",
          role = "status",
          shiny::tags$div(class = "app-alert-icon", shiny::HTML(icon_svg("info"))),
          shiny::tags$div(
            class = "app-alert-body",
            shiny::tags$div(class = "app-alert-head",
                            shiny::tags$span(class = "app-alert-title",
                                             tr("ml.demo", lang()))),
            shiny::tags$p(class = "app-alert-message",
                          tr("ml.demo_synthetic_note", lang()))
          )
        )
      } else {
        NULL
      }

      if (is.null(state$result)) {
        return(shiny::tagList(
          demo_alert,
          empty_state("ml.empty_title", "ml.empty_body", lang(), icon = "tree"),
          shiny::tags$p(class = "hint-text", tr_span("ml.run_hint", lang()))
        ))
      }

      res <- state$result
      se_alert <- if (!isTRUE(res$se_reliable)) {
        shiny::tags$div(
          class = "app-alert app-alert-warning",
          role = "status",
          shiny::tags$div(class = "app-alert-icon", shiny::HTML(icon_svg("alert"))),
          shiny::tags$div(
            class = "app-alert-body",
            shiny::tags$div(
              class = "app-alert-head",
              shiny::tags$span(class = "app-alert-title", tr("ml.warning_se", lang())),
              shiny::tags$code(class = "error-code", "SE")
            ),
            shiny::tags$p(class = "app-alert-message",
                          tr("ml.warning_se_detail", lang())),
            if (length(res$warnings)) {
              shiny::tags$details(
                class = "alert-details",
                shiny::tags$summary(tr("common.details", lang())),
                shiny::tags$pre(class = "detail-pre",
                                paste(res$warnings, collapse = "\n"))
              )
            }
          )
        )
      } else {
        NULL
      }

      zero_note <- if (res$beta_converted > 0) {
        shiny::tags$p(class = "note",
                      tr("ml.beta_zero_note", lang(), n = res$beta_converted))
      } else {
        NULL
      }

      metrics <- shiny::tags$div(
        class = "metric-grid",
        metric_box("ml.logml", fmt_num(res$logml, 8), lang()),
        metric_box(
          "ml.se",
          if (is.na(res$se)) "NA" else fmt_num(res$se, 6),
          lang(),
          status = if (isTRUE(res$se_reliable)) "ok" else "warn",
          sub = if (isTRUE(res$se_reliable)) {
            tr("ml.status_se_reliable", lang())
          } else {
            tr("ml.status_se_unreliable", lang())
          }
        ),
        metric_box("ml.n_beta", fmt_int(res$n_beta), lang()),
        metric_box("ml.method_label", tr(ml_method_label_key(res$method), lang()), lang()),
        metric_box("ml.model", res$model_name, lang()),
        metric_box("ml.computed_at", res$computed_at, lang())
      )

      shiny::tagList(
        demo_alert,
        se_alert,
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
              download_button(ns("download_summary"), "ml.summary_download", lang()),
              download_button(ns("download_detail"), "ml.detail_download", lang()),
              download_button(ns("download_png"), "common.download_png", lang()),
              download_button(ns("download_pdf"), "common.download_pdf", lang()),
              download_button(ns("download_bundle"), "ml.bundle_download", lang(),
                              icon = "download")
            )
          ),
          metrics,
          section_card(
            "ml.plot_title", lang(),
            shiny::tags$div(class = "plot-wrap",
                            shiny::plotOutput(ns("plot"), height = "340px"))
          ),
          section_card(
            "ml.detail_title", lang(),
            DT::DTOutput(ns("detail_table")),
            zero_note
          ),
          shiny::tags$p(
            class = "note",
            tr("ml.result_note", lang()), " ",
            tr("ml.summary_note", lang())
          ),
          shiny::tags$p(
            class = "note",
            paste0(tr("ml.upstream", lang()), ": mcmc3r ", res$upstream_version,
                   " (", substr(res$upstream_sha, 1, 7), ") \u00b7 ",
                   tr("ml.app_label", lang()), " ", res$app_version)
          ),
          shiny::tags$p(class = "note", tr("ml.meta_note", lang()))
        )
      )
    })

    output$plot <- shiny::renderPlot({
      shiny::req(state$result)
      shiny::req(active())
      draw_marginal(state$result, lang = lang(), theme = theme())
    }, res = 96, bg = "transparent")

    output$detail_table <- DT::renderDT({
      shiny::req(state$result)
      shiny::req(active())
      df <- state$result$per_beta
      df$se_warning <- ifelse(df$se_warning, tr("common.yes", lang()),
                              tr("common.no", lang()))
      names(df) <- c(
        tr("ml.beta_col", lang()),
        tr("ml.mean_logl", lang()),
        tr("ml.n_rows", lang()),
        tr("ml.se_warning", lang())
      )
      opts <- list(
        dom = "ltp", pageLength = 8, scrollX = TRUE,
        language = list(emptyTable = tr("dt.empty", lang()),
                        zeroRecords = tr("dt.no_records", lang()))
      )
      if (nrow(df) <= 8) {
        opts$dom <- "t"
        opts$paging <- FALSE
      }
      DT::datatable(
        df,
        rownames = FALSE,
        options = opts,
        class = "compact stripe"
      ) |>
        DT::formatSignif(columns = c(1, 2), digits = 6)
    })

    output$download_beta <- shiny::downloadHandler(
      filename = function() download_filename("beta", "txt", lang(), "print"),
      content = function(file) {
        shiny::req(state$generated_beta)
        b <- state$generated_beta
        if (!identical(state$generated_method, "gauss-quad")) b[b == 0] <- 1e-300
        writeLines(format(b, scientific = TRUE, digits = 17, trim = TRUE), file)
      }
    )

    output$download_summary <- shiny::downloadHandler(
      filename = function() {
        download_filename("marginal-summary", "csv", lang(), export_theme())
      },
      content = function(file) {
        shiny::req(state$result)
        export_csv(ml_summary_export_df(state$result), file)
      }
    )

    output$download_detail <- shiny::downloadHandler(
      filename = function() {
        download_filename("marginal-detail", "csv", lang(), export_theme())
      },
      content = function(file) {
        shiny::req(state$result)
        export_csv(ml_detail_export_df(state$result), file)
      }
    )

    output$download_png <- shiny::downloadHandler(
      filename = function() {
        download_filename("marginal", "png", lang(), export_theme())
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
          draw = function(colors) draw_marginal(res, lang = lang(), theme = plot_theme),
          theme = plot_theme, width = width, height = height, res = dpi
        )
      }
    )

    output$download_pdf <- shiny::downloadHandler(
      filename = function() {
        download_filename("marginal", "pdf", lang(), export_theme())
      },
      content = function(file) {
        shiny::req(state$result)
        res <- state$result
        plot_theme <- if (identical(export_theme(), "print")) "light" else theme()
        save_plot_pdf(
          file,
          draw = function(colors) draw_marginal(res, lang = lang(), theme = plot_theme),
          theme = plot_theme
        )
      }
    )

    output$download_bundle <- shiny::downloadHandler(
      filename = function() {
        download_filename("marginal", "zip", lang(), export_theme())
      },
      content = function(file) {
        shiny::req(state$result)
        res <- state$result
        dir <- ensure_dir(tempfile("bundle-", tmpdir = file.path(session_dir, "exports")))
        summary_path <- file.path(dir, "marginal_summary.csv")
        detail_path <- file.path(dir, "marginal_detail.csv")
        meta_path <- file.path(dir, "metadata.json")
        export_csv(ml_summary_export_df(res), summary_path)
        export_csv(ml_detail_export_df(res), detail_path)
        export_metadata_json(
          result_metadata(
            "marginal", lang = lang(), screen_theme = res$screen_theme,
            export_theme = export_theme(),
            extra = list(
              method = res$method,
              model = res$model_name,
              logml = res$logml,
              se = res$se,
              n_beta = res$n_beta,
              se_reliable = res$se_reliable,
              warnings = res$warnings
            )
          ),
          meta_path
        )
        withr::with_dir(
          dir,
          zip::zip(
            zipfile = normalizePath(file, mustWork = FALSE),
            files = c("marginal_summary.csv", "marginal_detail.csv", "metadata.json"),
            mode = "mirror"
          )
        )
      }
    )
  })
}
