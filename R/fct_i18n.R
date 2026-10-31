# i18n --------------------------------------------------------------------
#
# A deliberately small, key-based translation layer. The translation table is
# a CSV with the columns `key,en,zh`. UI strings are addressed by stable keys
# (never by source text) so that copy edits do not break translations.

# Translations are stored in R options so that Shiny's automatic re-sourcing
# of R/ files (which happens after global.R) cannot discard the loaded table.

normalize_lang <- function(lang) {
  lang <- as.character(lang)[1]
  if (is.na(lang) || !nzchar(lang)) return("en")
  lang <- tolower(lang)
  if (lang %in% c("zh", "zh-cn", "zh_cn", "cn", "chinese")) return("zh")
  "en"
}

lang_tag <- function(lang) {
  if (identical(normalize_lang(lang), "zh")) "zh-CN" else "en"
}

i18n_load <- function(path) {
  if (!file.exists(path)) {
    stop("Translation file not found: ", path, call. = FALSE)
  }
  tab <- utils::read.csv(
    path,
    stringsAsFactors = FALSE,
    check.names = FALSE,
    encoding = "UTF-8",
    na.strings = character()
  )
  required <- c("key", "en", "zh")
  if (!all(required %in% names(tab))) {
    stop("Translation file must contain columns: key, en, zh", call. = FALSE)
  }
  tab <- tab[, required, drop = FALSE]
  if (anyDuplicated(tab$key)) {
    stop("Duplicate translation keys: ",
         paste(unique(tab$key[duplicated(tab$key)]), collapse = ", "),
         call. = FALSE)
  }
  if (any(!nzchar(tab$en)) || any(!nzchar(tab$zh))) {
    stop("Translation table contains empty en/zh values", call. = FALSE)
  }
  options(mcmc3r.i18n.table = tab)
  options(mcmc3r.i18n.keys = tab$key)
  invisible(tab)
}

i18n_table <- function() {
  tab <- getOption("mcmc3r.i18n.table")
  if (is.null(tab)) {
    stop("i18n has not been initialised", call. = FALSE)
  }
  tab
}

i18n_keys <- function() {
  keys <- getOption("mcmc3r.i18n.keys")
  if (is.null(keys)) {
    stop("i18n has not been initialised", call. = FALSE)
  }
  keys
}

i18n_has_key <- function(key) {
  key %in% i18n_keys()
}

#' Translate a key.
#'
#' Named arguments are interpolated into `{placeholders}` in the translated
#' string. Missing keys fall back to English, then to the key itself.
tr <- function(key, lang = "en", ...) {
  lang <- normalize_lang(lang)
  tab <- i18n_table()
  i <- match(key, tab$key)
  if (is.na(i)) {
    warning("Missing translation key: ", key, call. = FALSE)
    return(key)
  }
  text <- if (identical(lang, "zh")) tab$zh[i] else tab$en[i]
  if (!nzchar(text)) text <- tab$en[i]
  values <- list(...)
  if (length(values)) {
    nms <- names(values)
    if (is.null(nms) || any(!nzchar(nms))) {
      stop("Interpolation values must be named", call. = FALSE)
    }
    for (nm in nms) {
      text <- gsub(paste0("{", nm, "}"), as.character(values[[nm]]),
                   text, fixed = TRUE)
    }
  }
  text
}

# Span carrying a data-i18n attribute. The client-side dictionary updates the
# text instantly when the user switches language without a server round trip.
tr_span <- function(key, lang = "en", class = NULL, tag = "span", ...) {
  values <- list(...)
  args <- list(`data-i18n` = key, tr(key, lang, ...))
  if (length(values)) {
    args$`data-i18n-params` <- jsonlite::toJSON(values, auto_unbox = TRUE)
  }
  if (!is.null(class)) args$class <- class
  do.call(shiny::tags[[tag]], args)
}

# Shiny hands the UI function a rook request *environment*, not a list, so an
# is.list() guard silently discards the query string.
query_string_from_request <- function(request) {
  if (is.null(request)) return("")
  qs <- tryCatch(request$QUERY_STRING, error = function(e) NULL)
  if (is.null(qs) && is.list(request)) qs <- request$QUERY_STRING
  if (is.null(qs)) return("")
  sub("^\\?", "", as.character(qs)[1])
}

query_param <- function(query, name) {
  parsed <- tryCatch(
    shiny::parseQueryString(if (is.null(query)) "" else query, nested = FALSE),
    error = function(e) list()
  )
  parsed[[name]]
}

# A translation dictionary for the browser, used by dev/build_i18n.R.
i18n_dict <- function() {
  tab <- i18n_table()
  list(
    en = stats::setNames(as.list(tab$en), tab$key),
    zh = stats::setNames(as.list(tab$zh), tab$key)
  )
}

# Detect an initial language from a URL query string.
lang_from_query <- function(query) {
  if (is.null(query) || !nzchar(query)) return(NULL)
  parsed <- tryCatch(
    shiny::parseQueryString(query, nested = FALSE),
    error = function(e) NULL
  )
  if (is.null(parsed) || is.null(parsed$lang)) return(NULL)
  value <- parsed$lang
  if (!value %in% c("en", "zh", "zh-CN", "zh-cn")) return(NULL)
  normalize_lang(value)
}

theme_choices <- function(lang = "en") {
  c(
    stats::setNames("light", tr("theme.light", lang)),
    stats::setNames("dark", tr("theme.dark", lang))
  )
}

export_theme_choices <- function(lang = "en") {
  c(
    stats::setNames("print", tr("theme.print", lang)),
    stats::setNames("screen", tr("theme.screen", lang))
  )
}
