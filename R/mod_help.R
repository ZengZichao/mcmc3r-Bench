# Help module --------------------------------------------------------------

help_markdown <- function(text, lang = "en") {
  lines <- strsplit(text, "\n", fixed = TRUE)[[1]]
  heading_lines <- grep("^#{2,3} ", lines, value = TRUE)
  levels <- ifelse(grepl("^### ", heading_lines), 3L, 2L)
  labels <- sub("^#{2,3} ", "", heading_lines)
  ids <- paste0("help-section-", seq_along(labels))

  html <- commonmark::markdown_html(text, extensions = TRUE)
  for (i in seq_along(labels)) {
    tag <- if (levels[i] == 2L) "h2" else "h3"
    old <- paste0("<", tag, ">", labels[i], "</", tag, ">")
    new <- paste0("<", tag, " id=\"", ids[i], "\">", labels[i], "</", tag, ">")
    html <- gsub(old, new, html, fixed = TRUE)
  }
  # Wide documentation tables get their own keyboard-scrollable container.
  html <- gsub(
    "<table>",
    paste0("<div class=\"table-scroll\" tabindex=\"0\"><table>"),
    html, fixed = TRUE
  )
  html <- gsub("</table>", "</table></div>", html, fixed = TRUE)
  scroll_note <- paste0(
    "<p class=\"table-scroll-note\" data-i18n=\"common.table_scroll\">",
    htmltools::htmlEscape(tr("common.table_scroll", lang)),
    "</p>"
  )
  html <- gsub("</table></div>", paste0("</table></div>", scroll_note), html,
               fixed = TRUE)
  html <- gsub("<pre>", "<pre tabindex=\"0\">", html, fixed = TRUE)

  toc <- lapply(which(levels == 2L), function(i) {
    shiny::tags$li(
      shiny::tags$a(href = paste0("#", ids[i]), labels[i])
    )
  })

  list(
    html = shiny::HTML(html),
    toc = shiny::tags$ol(toc),
    toc_label = tr("help.toc", lang)
  )
}

mod_help_ui <- function(id, lang = "en") {
  ns <- shiny::NS(id)
  shiny::tagList(
    page_header("help.title", "help.description", lang),
    shiny::uiOutput(ns("layout"))
  )
}

mod_help_server <- function(id, lang) {
  shiny::moduleServer(id, function(input, output, session) {
    output$layout <- shiny::renderUI({
      file <- if (identical(normalize_lang(lang()), "zh")) "help_zh.md" else "help_en.md"
      path <- app_path("i18n", file)
      if (!file.exists(path)) {
        return(shiny::tags$p(class = "note", tr("common.empty", lang())))
      }
      text <- paste(read_text_file(path), collapse = "\n")
      rendered <- help_markdown(text, lang())

      shiny::tags$div(
        class = "help-layout",
        shiny::tags$nav(
          class = "help-toc",
          `aria-label` = rendered$toc_label,
          shiny::tags$h2(class = "help-toc-title", rendered$toc_label),
          rendered$toc
        ),
        shiny::tags$details(
          class = "help-toc-mobile",
          shiny::tags$summary(rendered$toc_label),
          shiny::tags$nav(
            `aria-label` = rendered$toc_label,
            rendered$toc
          )
        ),
        shiny::tags$div(class = "prose-card", rendered$html)
      )
    })
  })
}
