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
    "  if (meta) meta.setAttribute('content', theme === 'dark' ? '#000000' : '#F5F5F7');",
    "  window.__MCMC3R_INITIAL = { theme: theme, lang: initialLang };",
    "})();",
    sep = "\n"
  )
}

# Static assets are cached aggressively by browsers; a content-derived query
# string makes a style or script edit reach users without a hard reload.
asset_url <- function(path) {
  full <- file.path(getOption("mcmc3r.app_dir"), "www", path)
  stamp <- tryCatch(
    format(file.mtime(full), "%Y%m%d%H%M%S"),
    error = function(e) NA_character_
  )
  if (is.na(stamp)) stamp <- app_version()
  paste0(path, "?v=", stamp)
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

app_header <- function(lang = "en", theme = "light") {
  shiny::tags$header(
    class = "app-header",
    shiny::tags$div(
      class = "app-header-inner",
      shiny::tags$a(
        class = "brand", href = "#calibration", `data-nav` = "calibration",
        shiny::HTML(brand_svg()),
        shiny::tags$span(
          class = "brand-text",
          shiny::tags$span(class = "brand-name", tr_span("app.name", lang))
        )
      ),
      shiny::tags$nav(
        id = "app-nav", class = "app-nav",
        `aria-label` = tr("nav.primary", lang),
        `data-i18n-aria-label` = "nav.primary",
        nav_button("calibration", "nav.calibration", lang, active = TRUE),
        nav_button("mcmc", "nav.mcmc", lang),
        nav_button("marginal", "nav.marginal", lang),
        nav_button("help", "nav.help", lang),
        nav_button("about", "nav.about", lang)
      ),
      shiny::tags$div(
        class = "app-controls",
        shiny::tags$button(
          id = "nav-toggle", type = "button", class = "nav-toggle",
          `aria-expanded` = "false", `aria-controls` = "app-nav",
          `aria-label` = tr("common.menu", lang),
          shiny::tags$span(
            class = "nav-icon-open", shiny::HTML(icon_svg("menu", 18))
          ),
          shiny::tags$span(
            class = "nav-icon-close", shiny::HTML(icon_svg("x", 18))
          )
        ),
        shiny::tags$div(
          class = "lang-switch",
          role = "group",
          `aria-label` = tr("common.language", lang),
          `data-i18n-aria-label` = "common.language",
          shiny::tags$button(
            type = "button",
            class = paste("lang-btn", if (identical(normalize_lang(lang), "en")) "active"),
            `data-lang` = "en",
            `aria-pressed` = if (identical(normalize_lang(lang), "en")) "true" else "false",
            "EN"
          ),
          shiny::tags$button(
            type = "button",
            class = paste("lang-btn", if (identical(normalize_lang(lang), "zh")) "active"),
            `data-lang` = "zh",
            `aria-pressed` = if (identical(normalize_lang(lang), "zh")) "true" else "false",
            "\u4e2d\u6587"
          )
        ),
        shiny::tags$button(
          id = "theme-toggle", type = "button", class = "theme-toggle",
          `aria-pressed` = if (theme == "dark") "true" else "false",
          `aria-label` = if (theme == "dark") tr("theme.switch_to_light", lang)
                         else tr("theme.switch_to_dark", lang),
          shiny::tags$span(class = "theme-icon icon-moon", shiny::HTML(icon_svg("moon", 16))),
          shiny::tags$span(class = "theme-icon icon-sun", shiny::HTML(icon_svg("sun", 16)))
        )
      )
    )
  )
}

app_subnav <- function(lang = "en", page = "calibration") {
  shiny::tags$nav(
    class = "sub-nav",
    `aria-label` = tr("nav.breadcrumb", lang),
    `data-i18n-aria-label` = "nav.breadcrumb",
    shiny::tags$div(
      class = "sub-nav-inner",
      shiny::tags$div(
        class = "sub-nav-context",
        shiny::tags$a(
          class = "sub-nav-home", href = "#calibration", `data-nav` = "calibration",
          tr_span("app.name", lang)
        ),
        shiny::tags$span(class = "sub-nav-sep", `aria-hidden` = "true", "\u203a"),
        # The row is labelled a breadcrumb but used to repeat the brand name on
        # all five pages; it now carries the current page, kept in step by
        # showPage().
        shiny::tags$span(
          id = "sub-nav-current", class = "sub-nav-current",
          `aria-current` = "page",
          tr(paste0("nav.", page), lang)
        )
      ),
      shiny::tags$div(
        class = "sub-nav-links",
        shiny::tags$a(
          href = paste0(APP_REPO, "/tree/main/docs"),
          target = "_blank", rel = "noopener noreferrer",
          tr_span("footer.docs", lang)
        ),
        shiny::tags$a(
          href = APP_REPO, target = "_blank", rel = "noopener noreferrer",
          tr_span("footer.github", lang)
        )
      )
    )
  )
}

footer_link <- function(href, key, lang, external = FALSE, nav = NULL) {
  shiny::tags$a(
    href = href,
    target = if (external) "_blank" else NULL,
    rel = if (external) "noopener noreferrer" else NULL,
    `data-nav` = nav,
    tr_span(key, lang)
  )
}

app_footer <- function(lang = "en") {
  shiny::tags$footer(
    class = "app-footer",
    shiny::tags$div(
      class = "app-footer-inner",
      shiny::tags$div(
        class = "footer-top",
        shiny::tags$div(
          class = "footer-brand-block",
          shiny::tags$span(class = "footer-brand", APP_NAME),
          shiny::tags$p(class = "footer-tagline", tr_span("app.tagline", lang)),
          shiny::tags$p(class = "footer-note", tr_span("about.no_endorsement", lang))
        ),
        shiny::tags$div(
          class = "footer-column",
          shiny::tags$h2(class = "footer-heading", tr_span("footer.explore", lang)),
          shiny::tags$nav(
            class = "footer-col-links",
            `aria-label` = tr("footer.explore", lang),
            `data-i18n-aria-label` = "footer.explore",
            footer_link("#calibration", "nav.calibration", lang, nav = "calibration"),
            footer_link("#mcmc", "nav.mcmc", lang, nav = "mcmc"),
            footer_link("#marginal", "nav.marginal", lang, nav = "marginal"),
            footer_link("#help", "nav.help", lang, nav = "help"),
            footer_link("#about", "nav.about", lang, nav = "about")
          )
        ),
        shiny::tags$div(
          class = "footer-column",
          shiny::tags$h2(class = "footer-heading", tr_span("footer.resources", lang)),
          shiny::tags$nav(
            class = "footer-col-links",
            `aria-label` = tr("footer.resources", lang),
            `data-i18n-aria-label` = "footer.resources",
            footer_link(APP_REPO, "footer.github", lang, external = TRUE),
            footer_link(paste0(APP_REPO, "/tree/main/docs/en"),
                        "common.docs_en", lang, external = TRUE),
            footer_link(paste0(APP_REPO, "/tree/main/docs/zh"),
                        "common.docs_zh", lang, external = TRUE)
          )
        ),
        shiny::tags$div(
          class = "footer-column",
          shiny::tags$h2(class = "footer-heading", tr_span("footer.legal", lang)),
          shiny::tags$nav(
            class = "footer-col-links",
            `aria-label` = tr("footer.legal", lang),
            `data-i18n-aria-label` = "footer.legal",
            footer_link(paste0(APP_REPO, "/blob/main/docs/PRIVACY.md"),
                            "footer.privacy", lang, external = TRUE),
            footer_link(paste0(APP_REPO, "/blob/main/LICENSE"),
                        "footer.license", lang, external = TRUE),
            footer_link(paste0(APP_REPO, "/blob/main/CITATION.cff"),
                        "footer.citation", lang, external = TRUE)
          )
        )
      ),
      shiny::tags$div(
        class = "footer-legal",
        shiny::tags$div(
          class = "footer-meta",
          shiny::tags$span(tr("footer.copyright", lang)),
          shiny::tags$span(class = "footer-sep", "\u00b7"),
          shiny::tags$span(class = "footer-version",
                           paste0("v", app_version())),
          shiny::tags$span(class = "footer-sep", "\u00b7"),
          shiny::tags$span(tr_span("footer.upstream", lang)),
          shiny::tags$span(paste0("mcmc3r ", UPSTREAM_VERSION))
        ),
        shiny::tags$a(
          href = APP_ISSUES, target = "_blank", rel = "noopener noreferrer",
          tr_span("common.issues", lang)
        )
      )
    )
  )
}

app_ui <- function(request) {
  query <- query_string_from_request(request)
  initial_lang <- lang_from_query(query) %||% "en"
  default_theme <- Sys.getenv("MCMC3R_DEFAULT_THEME", "auto")
  if (!default_theme %in% c("light", "dark", "auto")) default_theme <- "auto"
  # A ?theme= override makes the served document self-consistent: the lang
  # attribute, theme-color, aria-pressed and active pill all agree before JS.
  qp_theme <- query_param(query, "theme")
  initial_theme <- if (!is.null(qp_theme) && qp_theme %in% c("light", "dark")) {
    qp_theme
  } else if (default_theme %in% c("light", "dark")) {
    default_theme
  } else {
    "light"
  }

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
      shiny::tags$meta(name = "theme-color",
                       content = if (initial_theme == "dark") "#000000" else "#F5F5F7"),
      shiny::tags$meta(name = "mcmc3r-default-theme", content = default_theme),
      shiny::tags$meta(
        name = "description",
        content = tr("app.meta_description", initial_lang),
      ),
      shiny::tags$link(rel = "icon", type = "image/svg+xml",
                       href = "img/favicon.svg"),
      shiny::tags$script(shiny::HTML(theme_init_js())),
      shiny::tags$link(rel = "stylesheet", href = asset_url("css/app.css")),
      shiny::tags$link(rel = "stylesheet", href = asset_url("css/print.css"),
                       media = "print")
    ),
    shiny::tags$a(class = "skip-link", href = "#main",
                  tr_span("common.skip", initial_lang)),
    shiny::tags$noscript(
      shiny::tags$div(class = "noscript-banner",
                      tr_span("common.noscript", initial_lang))
    ),
    app_header(initial_lang, initial_theme),
    app_subnav(initial_lang),
    shiny::tags$main(
      id = "main", class = "app-main", tabindex = "-1",
      shiny::tags$div(
        class = "public-notice", role = "note",
        shiny::HTML(icon_svg("info", 15)),
        tr_span("common.public_notice", initial_lang)
      ),
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
    shiny::tags$script(src = asset_url("js/i18n.js")),
    shiny::tags$script(src = asset_url("js/app.js"))
  )
}
