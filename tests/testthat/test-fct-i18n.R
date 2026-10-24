test_that("translation table is complete and unique", {
  tab <- i18n_table()
  expect_identical(names(tab), c("key", "en", "zh"))
  expect_false(anyDuplicated(tab$key) > 0)
  expect_true(all(nzchar(tab$en)))
  expect_true(all(nzchar(tab$zh)))
  expect_gt(nrow(tab), 200)
})

test_that("translation lookup, fallback, and interpolation work", {
  expect_identical(tr("common.run", "en"), "Run")
  expect_identical(tr("common.run", "zh"), "运行")
  expect_identical(tr("common.run", "zh-CN"), "运行")
  expect_identical(tr("mcmc.example_loaded", "zh", name = "X"),
                   "已载入示例：X")
  expect_warning(tr("no.such.key", "en"), "Missing translation key")
})

test_that("every documented error code has a bilingual message and hint", {
  codes <- c(
    "CAL-001", "CAL-002", "CAL-003", "CAL-004", "CAL-005", "CAL-006",
    "CAL-007", "CAL-008", "CAL-009", "CAL-010", "CAL-011", "CAL-012",
    "MCMC-001", "MCMC-002", "MCMC-003", "MCMC-004", "MCMC-005",
    "MCMC-006", "MCMC-007", "MCMC-008",
    "ML-001", "ML-002", "ML-003", "ML-004", "ML-005", "ML-006",
    "ML-007", "ML-008", "ML-009", "ML-010", "ML-011",
    "FILE-001", "FILE-002", "FILE-003", "FILE-004",
    "SYS-001", "SYS-002", "SYS-003"
  )
  keys <- i18n_keys()
  for (code in codes) {
    expect_true(paste0("err.", code) %in% keys, info = code)
    expect_true(paste0("hint.", code) %in% keys, info = code)
  }
})

test_that("every tr() key used in R/ exists in the table", {
  files <- list.files(file.path(app_root, "R"), pattern = "\\.R$",
                      full.names = TRUE)
  text <- paste(vapply(files, function(f) paste(readLines(f), collapse = "\n"),
                       character(1)), collapse = "\n")
  keys <- unique(unlist(regmatches(
    text,
    gregexpr('tr(?:_span|_vec)?\\("([^"]+)"', text, perl = TRUE)
  )))
  keys <- sub('^tr(?:_span|_vec)?\\("', "", keys)
  keys <- sub('"$', "", keys)
  missing <- setdiff(keys, i18n_keys())
  expect_identical(missing, character())
})

test_that("the browser dictionary is generated from the same table", {
  path <- file.path(app_root, "www", "js", "i18n.js")
  expect_true(file.exists(path))
  js <- paste(readLines(path, warn = FALSE), collapse = "\n")
  missing <- i18n_keys()[!vapply(i18n_keys(), function(k) {
    grepl(paste0('"', k, '"'), js, fixed = TRUE)
  }, logical(1))]
  expect_identical(missing, character())
})

test_that("language parsing is tolerant and defaults to English", {
  expect_identical(normalize_lang("zh-CN"), "zh")
  expect_identical(normalize_lang("ZH"), "zh")
  expect_identical(normalize_lang("fr"), "en")
  expect_identical(normalize_lang(NA_character_), "en")
  expect_identical(lang_from_query("?lang=zh&theme=dark"), "zh")
  expect_null(lang_from_query("?theme=dark"))
  expect_null(lang_from_query("?lang=fr"))
})
