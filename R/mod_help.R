# Help module --------------------------------------------------------------

mod_help_ui <- function(id, lang = "en") {
  ns <- shiny::NS(id)
  shiny::tagList(
    page_header("help.title", "help.description", lang, icon = "help"),
    shiny::tags$div(class = "prose-card", shiny::uiOutput(ns("content")))
  )
}

mod_help_server <- function(id, lang) {
  shiny::moduleServer(id, function(input, output, session) {
    output$content <- shiny::renderUI({
      file <- if (identical(normalize_lang(lang()), "zh")) "help_zh.md" else "help_en.md"
      path <- app_path("i18n", file)
      if (!file.exists(path)) {
        return(shiny::tags$p(class = "note", tr("common.empty", lang())))
      }
      text <- paste(read_text_file(path), collapse = "\n")
      html <- commonmark::markdown_html(text, extensions = TRUE)
      shiny::HTML(html)
    })
  })
}
