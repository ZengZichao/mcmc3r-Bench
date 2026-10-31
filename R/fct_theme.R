# Theme tokens ------------------------------------------------------------
# Colours are defined once here and mirrored in www/css/app.css. Plot and
# export code uses these tokens; modules must never hard-code light colours.

THEME_TOKENS <- list(
  light = list(
    mode = "light",
    bg = "#F5F5F7",
    surface = "#FFFFFF",
    surface2 = "#FAFAFC",
    text = "#1D1D1F",
    text_muted = "#6E6E73",
    primary = "#0066CC",
    primary_soft = "#E8F1FB",
    on_primary = "#FFFFFF",
    accent = "#B25000",
    accent_ink = "#7A3B00",
    danger = "#B3261E",
    danger_soft = "#FDECEA",
    ok = "#1D7A46",
    border = "#C9C9CF",
    divider = "#DEDEE3",
    focus = "#0071E3",
    plot_bg = "#FFFFFF",
    plot_fg = "#1D1D1F",
    plot_grid = "#E0E0E0",
    series = c("#0071E3", "#5E5CE6", "#B25000", "#8944AB", "#1D7A46")
  ),
  dark = list(
    mode = "dark",
    bg = "#000000",
    surface = "#1D1D1F",
    surface2 = "#272729",
    text = "#F5F5F7",
    text_muted = "#A1A1A6",
    primary = "#2997FF",
    primary_soft = "#0A2A45",
    on_primary = "#001D33",
    accent = "#FFB340",
    accent_ink = "#FFD9A0",
    danger = "#FF6961",
    danger_soft = "#3A1210",
    ok = "#5BD6A8",
    border = "#47474B",
    divider = "#3A3A3F",
    focus = "#2997FF",
    plot_bg = "#000000",
    plot_fg = "#F5F5F7",
    plot_grid = "#333336",
    series = c("#2997FF", "#BF5AF2", "#FFB340", "#64D2FF", "#5BD6A8")
  )
)

theme_tokens <- function(theme = c("light", "dark"), export = FALSE) {
  theme <- match.arg(theme)
  # Exports default to the print (light) theme.
  if (isTRUE(export)) theme <- "light"
  THEME_TOKENS[[theme]]
}

app_font_stack <- paste(
  "SF Pro Text", "SF Pro Display", "system-ui", "-apple-system",
  "BlinkMacSystemFont", "Segoe UI", "PingFang SC", "Hiragino Sans GB",
  "Microsoft YaHei", "Noto Sans SC", "sans-serif", sep = ", "
)

app_bs_theme <- function() {
  bslib::bs_theme(
    version = 5,
    primary = THEME_TOKENS$light$primary,
    secondary = THEME_TOKENS$light$text_muted,
    success = THEME_TOKENS$light$ok,
    info = THEME_TOKENS$light$primary,
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
