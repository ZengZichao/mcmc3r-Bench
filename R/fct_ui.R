# UI building blocks ------------------------------------------------------

help_tip <- function(key, lang = "en") {
  shiny::tags$span(
    class = "help-tip",
    tabindex = "0",
    role = "button",
    `aria-haspopup` = "true",
    `aria-expanded` = "false",
    `aria-label` = tr(key, lang),
    `data-i18n-aria-label` = key,
    "?"
  )
}

field_label <- function(key, lang = "en", help_key = NULL) {
  shiny::tagList(
    tr_span(key, lang),
    if (!is.null(help_key)) help_tip(help_key, lang)
  )
}

page_header <- function(title_key, desc_key, lang = "en") {
  shiny::tags$div(
    class = "page-hero",
    shiny::tags$div(
      class = "page-hero-inner",
      shiny::tags$h1(class = "page-title", tr_span(title_key, lang)),
      shiny::tags$p(class = "page-desc", tr_span(desc_key, lang))
    )
  )
}

control_panel <- function(..., title_key = NULL, lang = "en", footer = NULL) {
  title_id <- if (!is.null(title_key)) {
    paste0("panel-", gsub("[^A-Za-z0-9_-]", "-", title_key))
  } else {
    NULL
  }
  shiny::tags$section(
    class = "control-panel",
    `aria-labelledby` = title_id,
    if (!is.null(title_key)) {
      shiny::tags$h2(id = title_id, class = "panel-title",
                     tr_span(title_key, lang))
    },
    shiny::tags$div(
      class = "control-panel-card",
      ...,
      if (!is.null(footer)) shiny::tags$div(class = "panel-footer", footer)
    )
  )
}

result_panel <- function(..., title_key = NULL, lang = "en") {
  title_id <- if (!is.null(title_key)) {
    paste0("panel-", gsub("[^A-Za-z0-9_-]", "-", title_key))
  } else {
    NULL
  }
  shiny::tags$section(
    class = "result-panel",
    `aria-labelledby` = title_id,
    if (!is.null(title_key)) {
      shiny::tags$h2(id = title_id, class = "panel-title",
                     tr_span(title_key, lang))
    },
    shiny::tags$div(class = "result-panel-body", ...)
  )
}

empty_state <- function(title_key, body_key, lang = "en", icon = "chart",
                        extra = NULL) {
  shiny::tags$div(
    class = "empty-state",
    shiny::tags$div(class = "empty-icon", shiny::HTML(icon_svg(icon, size = 30))),
    shiny::tags$h2(class = "empty-title", tr_span(title_key, lang)),
    shiny::tags$p(class = "empty-body", tr_span(body_key, lang)),
    extra
  )
}

run_button <- function(id, label_key, lang = "en", icon = "play",
                       class = "btn btn-primary btn-run") {
  shiny::actionButton(
    id,
    label = shiny::tagList(
      shiny::HTML(icon_svg(icon, size = 18)),
      tr_span(label_key, lang)
    ),
    class = class
  )
}

reset_button <- function(id, lang = "en") {
  shiny::actionButton(
    id,
    label = shiny::tagList(
      shiny::HTML(icon_svg("reset", size = 16)),
      tr_span("common.reset", lang)
    ),
    class = "btn btn-ghost-pill btn-reset"
  )
}

# One notification channel. Shiny's showNotification() renders its own widget
# that is styled separately from the app's toast, so server-side feedback used
# to look and behave differently from client-side feedback.
notify <- function(session, message, type = "message") {
  kind <- switch(type, error = "error", warning = "warn", "")
  session$sendCustomMessage("toast", list(message = message, type = kind))
  invisible(NULL)
}

download_button <- function(id, label_key, lang = "en", icon = "download",
                            class = "btn btn-sm btn-utility") {
  # icon = NULL: Shiny otherwise injects <i class="fas fa-download"> next to
  # our own inline SVG, which renders two download glyphs and pulls in the
  # whole Font Awesome stylesheet for four icons.
  shiny::downloadButton(
    id,
    label = shiny::tagList(
      shiny::HTML(icon_svg(icon, size = 16)),
      tr_span(label_key, lang)
    ),
    class = class,
    icon = NULL
  )
}

copy_button <- function(target, lang = "en", label_key = "common.copy",
                        class = "btn btn-sm btn-utility copy-btn") {
  shiny::tags$button(
    type = "button",
    class = class,
    `data-copy-target` = target,
    shiny::HTML(icon_svg("copy", size = 15)),
    tr_span(label_key, lang)
  )
}

code_block <- function(id, text, lang = "en", label_key = "cal.copy_syntax") {
  shiny::tags$div(
    class = "code-block-wrap",
    shiny::tags$pre(id = id, class = "code-block", text),
    copy_button(paste0("#", id), lang, label_key)
  )
}

result_toolbar <- function(..., lang = "en") {
  shiny::tags$div(class = "result-toolbar", ...)
}

metric_box <- function(label_key, value, lang = "en", sub = NULL,
                       status = NULL, id = NULL, compact = FALSE) {
  shiny::tags$div(
    class = paste(
      "metric-box",
      if (!is.null(status)) paste0("metric-", status),
      if (isTRUE(compact)) "metric-compact"
    ),
    id = id,
    shiny::tags$div(class = "metric-label", tr_span(label_key, lang)),
    shiny::tags$div(class = "metric-value", value),
    if (!is.null(sub)) shiny::tags$div(class = "metric-sub", sub)
  )
}

alert_from_warnings <- function(warnings, lang = "en") {
  if (!length(warnings)) return(NULL)
  shiny::tagList(lapply(warnings, function(w) {
    app_warning_ui(w$code, lang, detail = w$detail, values = w$values %||% list())
  }))
}

diag_grid <- function(items) {
  shiny::tags$dl(
    class = "diag-grid",
    lapply(items, function(item) {
      shiny::tagList(
        shiny::tags$dt(item$label),
        shiny::tags$dd(item$value)
      )
    })
  )
}

section_card <- function(title_key, lang = "en", ..., class = "card-block",
                         toolbar = NULL) {
  shiny::tags$div(
    class = class,
    shiny::tags$div(
      class = "card-head",
      shiny::tags$h2(class = "card-title", tr_span(title_key, lang)),
      toolbar
    ),
    ...
  )
}

collapsible_advanced <- function(..., lang = "en", open = FALSE) {
  shiny::tags$details(
    class = "advanced-block",
    open = if (isTRUE(open)) NA else NULL,
    shiny::tags$summary(
      shiny::HTML(icon_svg("chevron", size = 15)),
      tr_span("common.advanced", lang)
    ),
    ...
  )
}

# Abstract syntax trees are not used; this call keeps htmltools honest.
.keep_htmltools <- function() invisible(htmltools::tags)
