# About module -------------------------------------------------------------

external_link <- function(href, label) {
  shiny::tags$a(
    href = href, target = "_blank", rel = "noopener noreferrer", label
  )
}

about_card <- function(title_key, lang = "en", ...) {
  shiny::tags$section(
    class = "card-block about-card",
    shiny::tags$h2(class = "card-title", tr_span(title_key, lang)),
    ...
  )
}

about_row <- function(label_key, value, lang = "en") {
  shiny::tags$div(
    class = "about-row",
    shiny::tags$span(class = "about-label", tr_span(label_key, lang)),
    shiny::tags$span(class = "about-value", value)
  )
}

mod_about_ui <- function(id, lang = "en") {
  ns <- shiny::NS(id)
  shiny::tagList(
    page_header("about.title", "about.description", lang),
    shiny::uiOutput(ns("content"))
  )
}

mod_about_server <- function(id, lang) {
  shiny::moduleServer(id, function(input, output, session) {
    output$content <- shiny::renderUI({
      l <- lang()
      version <- app_version()
      orcid_link <- external_link(
        "https://orcid.org/0000-0001-6553-970X",
        "0000-0001-6553-970X"
      )
      identity <- about_card(
        "about.attribution_heading", l,
        shiny::tags$p(class = "about-lede", tr("about.independent", l)),
        about_row("about.version", paste0("v", version), l),
        about_row("about.build", app_build_date(), l),
        about_row("about.doc_version", paste0("v", DOC_VERSION), l),
        about_row("about.author", APP_AUTHOR, l),
        about_row("about.email",
                  external_link(paste0("mailto:", APP_EMAIL), APP_EMAIL), l),
        about_row("about.orcid", orcid_link, l),
        about_row("about.repo",
                  external_link(APP_REPO,
                                sub("^https://github\\.com/", "", APP_REPO)), l),
        about_row("about.issue",
                  external_link(APP_ISSUES, tr("common.issues", l)), l),
        about_row("about.docs_en",
                  external_link(paste0(APP_REPO, "/blob/main/docs/en/USER_GUIDE.md"),
                                "docs/en/"), l),
        about_row("about.docs_zh",
                  external_link(paste0(APP_REPO, "/blob/main/docs/zh/USER_GUIDE.md"),
                                "docs/zh/"), l)
      )

      upstream <- about_card(
        "about.upstream", l,
        shiny::tags$p(class = "about-lede", tr("about.built_on", l)),
        about_row("about.upstream",
                  external_link(UPSTREAM_REPO, "dosreislab/mcmc3r"), l),
        about_row("about.upstream_authors", UPSTREAM_AUTHORS, l),
        about_row("about.upstream_version", UPSTREAM_VERSION, l),
        about_row("about.upstream_sha",
                  shiny::tags$code(substr(UPSTREAM_SHA, 1, 7)), l),
        shiny::tags$p(class = "note", tr("about.no_endorsement", l))
      )

      licences <- about_card(
        "about.license_heading", l,
        about_row("about.code_license",
                  external_link(paste0(APP_REPO, "/blob/main/LICENSE"), "MIT"), l),
        about_row("about.doc_license",
                  external_link(paste0(APP_REPO, "/blob/main/docs/LICENSE"),
                                "CC BY 4.0"), l),
        about_row("about.font_license", FONT_LICENSE, l),
        about_row("about.third_party",
                  external_link(paste0(APP_REPO, "/blob/main/THIRD_PARTY_LICENSES.md"),
                                "THIRD_PARTY_LICENSES.md"), l),
        about_row("about.notice",
                  external_link(paste0(APP_REPO, "/blob/main/NOTICE"), "NOTICE"), l)
      )

      citation <- about_card(
        "about.citation_heading", l,
        shiny::tags$blockquote(class = "citation-block",
                               tr("about.citation_text", l)),
        shiny::tags$p(class = "note", tr("about.methods_note", l)),
        about_row("about.citation",
                  external_link(paste0(APP_REPO, "/blob/main/CITATION.cff"),
                                "CITATION.cff"), l)
      )

      tech <- about_card(
        "about.tech_heading", l,
        about_row("about.framework", tr("about.framework_value", l), l),
        about_row("about.upstream",
                  paste0("mcmc3r ", UPSTREAM_VERSION, " @ ",
                         substr(UPSTREAM_SHA, 1, 7)), l),
        about_row("about.doc_version", paste0("v", DOC_VERSION), l)
      )

      disclaimer <- about_card(
        "about.disclaimer_heading", l,
        shiny::tags$p(class = "note", tr("about.disclaimer", l)),
        shiny::tags$p(class = "note", tr("about.data_note", l))
      )

      shiny::tags$div(
        class = "about-grid",
        identity,
        upstream,
        licences,
        citation,
        tech,
        disclaimer
      )
    })
  })
}
