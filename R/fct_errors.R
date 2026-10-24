# Error model -------------------------------------------------------------
#
# Every user-facing failure is represented by an `app_error` condition with a
# stable code, a translation key for the message, a translation key for the
# suggested action, and a technical detail that is only shown in a collapsed
# panel and in logs.

new_app_error <- function(type = "system", code = "SYS-001",
                          message_key = "err.SYS-001",
                          hint_key = NULL, detail = NULL,
                          context = list()) {
  structure(
    class = c("app_error", "error", "condition"),
    list(
      message = code,
      type = type,
      code = code,
      message_key = message_key,
      hint_key = hint_key,
      detail = detail,
      context = context
    )
  )
}

is_app_error <- function(x) inherits(x, "app_error")

app_error <- function(type, code, message_key = NULL, hint_key = NULL,
                      detail = NULL, context = list()) {
  if (is.null(message_key)) message_key <- paste0("err.", code)
  if (is.null(hint_key)) hint_key <- paste0("hint.", code)
  new_app_error(type, code, message_key, hint_key, detail, context)
}

stop_app <- function(type, code, message_key = NULL, hint_key = NULL,
                     detail = NULL, context = list()) {
  stop(app_error(type, code, message_key, hint_key, detail, context))
}

as_app_error <- function(e, module = NULL, code = "SYS-001") {
  if (is_app_error(e)) return(e)
  msg <- conditionMessage(e)
  mapped <- code
  if (grepl("cannot allocate vector|out of memory|memory exhausted",
            msg, ignore.case = TRUE)) {
    mapped <- "SYS-002"
  } else if (grepl("timeout|timed out|time limit", msg, ignore.case = TRUE)) {
    mapped <- "SYS-003"
  }
  app_error(
    type = "system",
    code = mapped,
    detail = msg,
    context = list(module = module %||% "unknown")
  )
}

app_error_message <- function(err, lang = "en") {
  if (!is_app_error(err)) return(as.character(err))
  tr(err$message_key, lang)
}

app_error_hint <- function(err, lang = "en") {
  if (!is_app_error(err) || is.null(err$hint_key)) return(NULL)
  if (!i18n_has_key(err$hint_key)) return(NULL)
  tr(err$hint_key, lang)
}

# Keep diagnostics free of paths and user content.
sanitize_diagnostic <- function(x, max_chars = 2000) {
  if (is.null(x) || !length(x)) return(NULL)
  x <- paste(as.character(x), collapse = " ")
  x <- gsub("[\r\n\t]+", " ", x)
  x <- gsub("[[:cntrl:]]", "", x)
  tmp <- tryCatch(normalizePath(tempdir(), mustWork = FALSE),
                  error = function(e) "")
  if (nzchar(tmp)) x <- gsub(tmp, "<tmp>", x, fixed = TRUE)
  if (nchar(x) > max_chars) x <- paste0(substr(x, 1, max_chars), "...")
  x
}

app_error_diagnostics <- function(err, module = NULL, lang = "en") {
  if (!is_app_error(err)) err <- as_app_error(err, module = module)
  ctx <- err$context
  if (length(ctx)) {
    ctx <- vapply(ctx, function(v) sanitize_diagnostic(v, 300), character(1))
  }
  paste(
    c(
      paste0("code=", err$code),
      paste0("type=", err$type),
      if (!is.null(module) || !is.null(ctx$module)) {
        paste0("module=", module %||% ctx$module)
      },
      paste0("message=", sanitize_diagnostic(app_error_message(err, "en"), 500)),
      if (!is.null(err$detail)) paste0("detail=", sanitize_diagnostic(err$detail)),
      paste0("app_version=", app_version()),
      paste0("upstream_version=", UPSTREAM_VERSION),
      paste0("upstream_sha=", UPSTREAM_SHA)
    ),
    collapse = "; "
  )
}

app_error_ui <- function(err, lang = "en", module = NULL, id = NULL) {
  err <- as_app_error(err, module = module)
  code <- err$code
  msg <- app_error_message(err, lang)
  hint <- app_error_hint(err, lang)
  diag <- app_error_diagnostics(err, module = module, lang = lang)
  heading <- tr("common.error", lang)
  detail_label <- tr("common.details", lang)
  copy_label <- tr("err.copy_diag", lang)
  help_label <- tr("err.open_help", lang)

  detail_block <- NULL
  if (!is.null(err$detail) && nzchar(as.character(err$detail))) {
    detail_block <- shiny::tags$details(
      class = "alert-details",
      shiny::tags$summary(detail_label),
      shiny::tags$pre(class = "detail-pre", sanitize_diagnostic(err$detail))
    )
  }

  shiny::tags$div(
    id = id,
    class = "app-alert app-alert-error",
    role = "alert",
    `aria-live` = "assertive",
    shiny::tags$div(
      class = "app-alert-icon",
      shiny::HTML(icon_svg("alert-triangle"))
    ),
    shiny::tags$div(
      class = "app-alert-body",
      shiny::tags$div(
        class = "app-alert-head",
        shiny::tags$span(class = "app-alert-title", heading),
        shiny::tags$code(class = "error-code", code)
      ),
      shiny::tags$p(class = "app-alert-message", msg),
      if (!is.null(hint)) {
        shiny::tags$p(
          class = "app-alert-hint",
          shiny::tags$strong(paste0(tr("common.hint", lang), ": ")),
          hint
        )
      },
      detail_block,
      shiny::tags$div(
        class = "app-alert-actions",
        shiny::tags$button(
          type = "button",
          class = "btn btn-sm btn-outline-secondary",
          `data-copy-text` = diag,
          shiny::HTML(icon_svg("copy")),
          shiny::tags$span(copy_label)
        ),
        shiny::tags$button(
          type = "button",
          class = "btn btn-sm btn-outline-secondary",
          `data-nav` = "help",
          shiny::HTML(icon_svg("help")),
          shiny::tags$span(help_label)
        ),
        shiny::tags$a(
          href = APP_ISSUES, target = "_blank", rel = "noopener noreferrer",
          class = "btn btn-sm btn-outline-secondary",
          shiny::HTML(icon_svg("github")),
          shiny::tags$span(tr("about.issue", lang))
        )
      )
    )
  )
}

# Soft runtime limit: keep the result but tell the user that splitting the task
# would be faster on a shared worker.
append_slow_warning <- function(warnings, elapsed_ms, limit_ms = 60000) {
  if (!is_scalar_number(elapsed_ms) || elapsed_ms <= limit_ms) return(warnings)
  c(warnings, list(list(
    code = "SYS-003",
    detail = paste0("elapsed_ms=", round(elapsed_ms), "; soft_limit_ms=", limit_ms)
  )))
}

app_warning_ui <- function(code, lang = "en", detail = NULL, values = list()) {
  msg_key <- paste0("err.", code)
  hint_key <- paste0("hint.", code)
  msg <- if (i18n_has_key(msg_key)) do.call(tr, c(list(msg_key, lang), values)) else code
  hint <- if (i18n_has_key(hint_key)) tr(hint_key, lang) else NULL
  shiny::tags$div(
    class = "app-alert app-alert-warning",
    role = "status",
    `aria-live` = "polite",
    shiny::tags$div(class = "app-alert-icon", shiny::HTML(icon_svg("alert"))),
    shiny::tags$div(
      class = "app-alert-body",
      shiny::tags$div(
        class = "app-alert-head",
        shiny::tags$span(class = "app-alert-title", tr("common.warning", lang)),
        shiny::tags$code(class = "error-code", code)
      ),
      shiny::tags$p(class = "app-alert-message", msg),
      if (!is.null(hint)) shiny::tags$p(class = "app-alert-hint", hint),
      if (!is.null(detail)) {
        shiny::tags$details(
          class = "alert-details",
          shiny::tags$summary(tr("common.details", lang)),
          shiny::tags$pre(class = "detail-pre", sanitize_diagnostic(detail))
        )
      }
    )
  )
}

app_info_ui <- function(code, lang = "en", values = list()) {
  msg_key <- paste0("err.", code)
  msg <- if (i18n_has_key(msg_key)) do.call(tr, c(list(msg_key, lang), values)) else code
  shiny::tags$div(
    class = "app-alert app-alert-info",
    role = "status",
    shiny::tags$div(class = "app-alert-icon", shiny::HTML(icon_svg("info"))),
    shiny::tags$div(
      class = "app-alert-body",
      shiny::tags$p(class = "app-alert-message", msg)
    )
  )
}

# Structured logging ------------------------------------------------------

log_event <- function(level = "INFO", module = "app", event = "event",
                      session_id = NULL, ...) {
  fields <- list(...)
  fields <- fields[!vapply(fields, is.null, logical(1))]
  if (length(fields)) {
    vals <- vapply(fields, function(v) {
      v <- paste(as.character(v), collapse = ",")
      gsub("[\r\n\t]+", " ", v)
    }, character(1))
    extra <- paste(names(vals), vals, sep = "=", collapse = " ")
  } else {
    extra <- ""
  }
  msg <- paste(
    paste0("level=", level),
    if (!is.null(session_id)) paste0("session=", session_id),
    paste0("module=", module),
    paste0("event=", event),
    extra,
    paste0("app_version=", app_version()),
    paste0("upstream_sha=", UPSTREAM_SHA)
  )
  msg <- trimws(gsub("[[:space:]]+", " ", msg))
  level <- toupper(level)
  if (requireNamespace("logger", quietly = TRUE)) {
    if (level == "ERROR") logger::log_error(msg)
    else if (level == "WARN") logger::log_warn(msg)
    else if (level == "DEBUG") logger::log_debug(msg)
    else logger::log_info(msg)
  } else {
    message(msg)
  }
  invisible(msg)
}

`%||%` <- function(x, y) if (is.null(x)) y else x
