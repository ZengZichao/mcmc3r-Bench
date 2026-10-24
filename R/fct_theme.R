# Theme tokens ------------------------------------------------------------
# Colours are defined once here and mirrored in www/css/app.css. Plot and
# export code uses these tokens; modules must never hard-code light colours.

THEME_TOKENS <- list(
  light = list(
    mode = "light",
    bg = "#F7F9FB",
    surface = "#FFFFFF",
    surface2 = "#EEF3F7",
    text = "#10243E",
    text_muted = "#48617A",
    primary = "#0C7A7C",
    primary_soft = "#D9F0EF",
    accent = "#B87316",
    accent_ink = "#6B4300",
    danger = "#B23A2E",
    border = "#D5DFE8",
    focus = "#1F6FEB",
    plot_bg = "#FFFFFF",
    plot_fg = "#10243E",
    plot_grid = "#DCE4EC",
    series = c("#0C7A7C", "#2F6FB3", "#B87316", "#6B5CA5", "#B23A2E")
  ),
  dark = list(
    mode = "dark",
    bg = "#0B1220",
    surface = "#111A2B",
    surface2 = "#172236",
    text = "#E6EDF5",
    text_muted = "#A9B7C6",
    primary = "#3CC7C2",
    primary_soft = "#123B3A",
    accent = "#F2B45C",
    accent_ink = "#FFD79A",
    danger = "#FF7A6B",
    border = "#263445",
    focus = "#7CC4FF",
    plot_bg = "#0B1220",
    plot_fg = "#E6EDF5",
    plot_grid = "#263445",
    series = c("#3CC7C2", "#7CB8FF", "#F2B45C", "#B9A7FF", "#FF7A6B")
  )
)

theme_tokens <- function(theme = c("light", "dark"), export = FALSE) {
  theme <- match.arg(theme)
  # Exports default to the print (light) theme.
  if (isTRUE(export)) theme <- "light"
  THEME_TOKENS[[theme]]
}

app_font_stack <- paste(
  "system-ui", "-apple-system", "BlinkMacSystemFont", "Segoe UI",
  "PingFang SC", "Hiragino Sans GB", "Microsoft YaHei", "Noto Sans SC",
  "sans-serif", sep = ", "
)

app_bs_theme <- function() {
  bslib::bs_theme(
    version = 5,
    primary = THEME_TOKENS$light$primary,
    secondary = THEME_TOKENS$light$text_muted,
    success = THEME_TOKENS$light$primary,
    info = "#2F6FB3",
    warning = THEME_TOKENS$light$accent,
    danger = THEME_TOKENS$light$danger,
    base_font = app_font_stack,
    code_font = "SFMono-Regular, Menlo, Consolas, 'Liberation Mono', monospace",
    "enable-shadows" = FALSE,
    "enable-gradients" = FALSE,
    "navbar-bg" = THEME_TOKENS$light$surface
  )
}

# Relative luminance / contrast helpers used by tests and accessibility checks.
hex_to_rgb <- function(hex) {
  hex <- sub("^#", "", hex)
  if (nchar(hex) == 3) {
    hex <- paste0(substr(hex, 1, 1), substr(hex, 1, 1),
                  substr(hex, 2, 2), substr(hex, 2, 2),
                  substr(hex, 3, 3), substr(hex, 3, 3))
  }
  c(
    strtoi(substr(hex, 1, 2), 16L),
    strtoi(substr(hex, 3, 4), 16L),
    strtoi(substr(hex, 5, 6), 16L)
  ) / 255
}

relative_luminance <- function(hex) {
  rgb <- hex_to_rgb(hex)
  rgb <- ifelse(rgb <= 0.04045, rgb / 12.92, ((rgb + 0.055) / 1.055)^2.4)
  0.2126 * rgb[1] + 0.7152 * rgb[2] + 0.0722 * rgb[3]
}

contrast_ratio <- function(fg, bg) {
  l1 <- relative_luminance(fg)
  l2 <- relative_luminance(bg)
  (max(l1, l2) + 0.05) / (min(l1, l2) + 0.05)
}

# CSS variable block for the plot device (base graphics).
plot_colors <- function(theme = "light", export = FALSE) {
  tok <- theme_tokens(theme, export = export)
  list(
    bg = tok$plot_bg,
    fg = tok$plot_fg,
    muted = tok$text_muted,
    grid = tok$plot_grid,
    primary = tok$primary,
    accent = tok$accent,
    series = tok$series,
    mode = tok$mode
  )
}
