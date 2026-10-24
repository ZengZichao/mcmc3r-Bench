# Application UI ----------------------------------------------------------

theme_init_js <- function() {
  paste(
    "(function () {",
    "  var params = new URLSearchParams(window.location.search);",
    "  var qTheme = params.get('theme');",
    "  var stored = null;",
    "  try { stored = localStorage.getItem('mcmc3r-bench-theme'); } catch (e) {}",
    "  var systemDark = window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;",
    "  var metaDefault = document.querySelector('meta[name=\"mcmc3r-default-theme\"]');",
    "  var defaultTheme = metaDefault ? metaDefault.getAttribute('content') : 'auto';",
    "  var theme = (qTheme === 'light' || qTheme === 'dark') ? qTheme :",
    "    ((stored === 'light' || stored === 'dark') ? stored :",
    "    ((defaultTheme === 'light' || defaultTheme === 'dark') ? defaultTheme :",
    "    (systemDark ? 'dark' : 'light')));",
    "  document.documentElement.setAttribute('data-bs-theme', theme);",
    "  document.documentElement.dataset.theme = theme;",
    "  document.documentElement.classList.toggle('theme-dark', theme === 'dark');",
    "  var qLang = params.get('lang');",
    "  var storedLang = null;",
    "  try { storedLang = localStorage.getItem('mcmc3r-bench-lang'); } catch (e) {}",
    "  var navLang = (navigator.language || 'en').toLowerCase();",
    "  var initialLang = (qLang === 'zh' || qLang === 'zh-CN') ? 'zh' :",
    "    ((qLang === 'en') ? 'en' : ((storedLang === 'zh' || storedLang === 'en') ? storedLang :",
    "    (navLang.indexOf('zh') === 0 ? 'zh' : 'en')));",
    "  document.documentElement.lang = initialLang === 'zh' ? 'zh-CN' : 'en';",
    "  document.documentElement.dataset.lang = initialLang;",
    "  var meta = document.querySelector('meta[name=\"theme-color\"]');",
    "  if (meta) meta.setAttribute('content', theme === 'dark' ? '#0B1220' : '#F7F9FB');",
    "  window.__MCMC3R_INITIAL = { theme: theme, lang: initialLang };",
    "})();",
    sep = "\n"
  )
}

nav_button <- function(page, key, lang, active = FALSE) {
  shiny::tags$button(
    type = "button",
    class = paste("nav-btn", if (active) "active" else ""),
    `data-nav` = page,
    `data-i18n` = key,
    `aria-controls` = paste0("page-", page),
    `aria-current` = if (active) "page" else "false",
    tr(key, lang)
  )
}

app_header <- function(lang = "en") {
  shiny::tags$header(
    class = "app-header",
    shiny::tags$div(
      class = "app-header-inner",
      shiny::tags$a(
        class = "brand", href = "#calibration", `data-nav` = "calibration",
        shiny::HTML(brand_svg()),
        shiny::tags$span(
          class = "brand-text",
          shiny::tags$span(class = "brand-name", tr_span("app.name", lang)),
          shiny::tags$span(class = "brand-tagline", tr_span("app.tagline", lang))
        )
      ),
      shiny::tags$nav(
        class = "app-nav", `aria-label` = tr("nav.primary", lang),
        `data-i18n-aria-label` = "nav.primary",
        nav_button("calibration", "nav.calibration", lang, active = TRUE),
        nav_button("mcmc", "nav.mcmc", lang),
        nav_button("marginal", "nav.marginal", lang),
        nav_button("help", "nav.help", lang),
        nav_button("about", "nav.about", lang)
      ),
      shiny::tags$div(
        class = "app-controls",
        shiny::tags$div(
          class = "lang-switch",
          role = "group",
          `aria-label` = tr("common.language", lang),
          `data-i18n-aria-label` = "common.language",
          shiny::tags$button(
            type = "button", class = "lang-btn active", `data-lang` = "en",
            `aria-pressed` = "true", "EN"
          ),
          shiny::tags$button(
            type = "button", class = "lang-btn", `data-lang` = "zh",
            `aria-pressed` = "false", "\u4e2d\u6587"
          )
        ),
        shiny::tags$button(
          id = "theme-toggle", type = "button", class = "theme-toggle",
          `aria-label` = tr("theme.switch_to_dark", lang),
          shiny::tags$span(class = "theme-icon icon-moon", shiny::HTML(icon_svg("moon", 16))),
          shiny::tags$span(class = "theme-icon icon-sun", shiny::HTML(icon_svg("sun", 16))),
          shiny::tags$span(class = "theme-label", `data-i18n` = "theme.dark",
                           tr("theme.dark", lang))
        )
      )
    )
  )
}

app_footer <- function(lang = "en") {
  shiny::tags$footer(
    class = "app-footer",
    shiny::tags$div(
      class = "app-footer-inner",
      shiny::tags$div(
        class = "footer-meta",
        shiny::tags$span(class = "footer-brand", APP_NAME),
        shiny::tags$span(class = "footer-version",
                         paste0("v", app_version())),
        shiny::tags$span(class = "footer-sep", "\u00b7"),
        shiny::tags$span(tr_span("footer.upstream", lang)),
        shiny::tags$span(paste0("mcmc3r ", UPSTREAM_VERSION))
      ),
      shiny::tags$div(
        class = "footer-links",
        shiny::tags$a(href = APP_REPO, target = "_blank",
                      rel = "noopener noreferrer",
                      shiny::HTML(icon_svg("github", 15)),
                      tr_span("footer.github", lang)),
        shiny::tags$a(href = paste0(APP_REPO, "/tree/main/docs/en"),
                      target = "_blank", rel = "noopener noreferrer",
                      tr_span("common.docs_en", lang)),
        shiny::tags$a(href = paste0(APP_REPO, "/tree/main/docs/zh"),
                      target = "_blank", rel = "noopener noreferrer",
                      tr_span("common.docs_zh", lang)),
        shiny::tags$a(href = "#help", `data-nav` = "help",
                      tr_span("footer.privacy", lang)),
        shiny::tags$a(href = paste0(APP_REPO, "/blob/main/LICENSE"),
                      target = "_blank", rel = "noopener noreferrer",
                      tr_span("footer.license", lang)),
        shiny::tags$a(href = APP_ISSUES, target = "_blank",
                      rel = "noopener noreferrer",
                      tr_span("common.issues", lang))
      )
    )
  )
}

app_ui <- function(request) {
  query <- NULL
  if (is.list(request) && !is.null(request$QUERY_STRING)) {
    query <- request$QUERY_STRING
  }
  initial_lang <- lang_from_query(query %||% "") %||% "en"
  default_theme <- Sys.getenv("MCMC3R_DEFAULT_THEME", "auto")
  if (!default_theme %in% c("light", "dark", "auto")) default_theme <- "auto"

  bslib::page_fluid(
    theme = app_bs_theme(),
    lang = lang_tag(initial_lang),
    title = app_title(initial_lang),
    shiny::tags$head(
      shiny::tags$meta(charset = "utf-8"),
      shiny::tags$meta(
        name = "viewport",
        content = "width=device-width, initial-scale=1, viewport-fit=cover"
      ),
      shiny::tags$meta(name = "theme-color", content = "#F7F9FB"),
      shiny::tags$meta(name = "mcmc3r-default-theme", content = default_theme),
      shiny::tags$meta(
        name = "description",
        content = "mcmc3r Bench: an independent, unofficial bilingual Shiny GUI for mcmc3r calibrations, MCMC summaries, and marginal likelihoods."
      ),
      shiny::tags$link(rel = "icon", type = "image/svg+xml",
                       href = "img/favicon.svg"),
      shiny::tags$script(shiny::HTML(theme_init_js())),
      shiny::tags$link(rel = "stylesheet", href = "css/app.css"),
      shiny::tags$link(rel = "stylesheet", href = "css/print.css", media = "print")
    ),
    shiny::tags$a(class = "skip-link", href = "#main",
                  tr_span("common.skip", initial_lang)),
    shiny::tags$noscript(
      shiny::tags$div(class = "noscript-banner",
                      tr_span("common.noscript", initial_lang))
    ),
    app_header(initial_lang),
    shiny::tags$div(
      class = "public-notice", role = "note",
      shiny::HTML(icon_svg("info", 15)),
      tr_span("common.public_notice", initial_lang)
    ),
    shiny::tags$main(
      id = "main", class = "app-main",
      shiny::tags$section(
        id = "page-calibration", class = "page-section",
        `data-page` = "calibration",
        `aria-label` = tr("nav.calibration", initial_lang),
        `data-i18n-aria-label` = "nav.calibration",
        mod_calibration_ui("calibration", initial_lang)
      ),
      shiny::tags$section(
        id = "page-mcmc", class = "page-section", hidden = NA,
        `data-page` = "mcmc",
        `aria-label` = tr("nav.mcmc", initial_lang),
        `data-i18n-aria-label` = "nav.mcmc",
        mod_mcmc_summary_ui("mcmc", initial_lang)
      ),
      shiny::tags$section(
        id = "page-marginal", class = "page-section", hidden = NA,
        `data-page` = "marginal",
        `aria-label` = tr("nav.marginal", initial_lang),
        `data-i18n-aria-label` = "nav.marginal",
        mod_marginal_ui("marginal", initial_lang)
      ),
      shiny::tags$section(
        id = "page-help", class = "page-section", hidden = NA,
        `data-page` = "help",
        `aria-label` = tr("nav.help", initial_lang),
        `data-i18n-aria-label` = "nav.help",
        mod_help_ui("help", initial_lang)
      ),
      shiny::tags$section(
        id = "page-about", class = "page-section", hidden = NA,
        `data-page` = "about",
        `aria-label` = tr("nav.about", initial_lang),
        `data-i18n-aria-label` = "nav.about",
        mod_about_ui("about", initial_lang)
      )
    ),
    app_footer(initial_lang),
    shiny::tags$div(
      id = "toast-region", class = "toast-region",
      `aria-live` = "polite", `aria-atomic` = "true"
    ),
    shiny::tags$div(id = "page-live", class = "sr-only", `aria-live` = "polite"),
    shiny::tags$script(src = "js/i18n.js"),
    shiny::tags$script(src = "js/app.js")
  )
}
