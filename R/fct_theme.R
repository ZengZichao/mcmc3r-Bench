# Theme tokens ------------------------------------------------------------
# Colours are defined once here and mirrored in www/css/app.css. Plot and
# export code uses these tokens; modules must never hard-code light colours.
#
# Every value is a Radix UI Colors step and every role follows the published
# step guidance:
#   1  app background                 7  non-interactive component border
#   2  subtle surface (tiles, code)   8  interactive component border
#   3-5 component fills (hover)       9  solid fill, focus ring
#   6  separator hairline            11  high-contrast text
#                                   12  emphasis text and solid ink
# Where the guidance and WCAG 1.4.11 disagree, the step is named in a comment:
# a form control's boundary uses step 9 rather than 8 because step 8 sits at
# 1.9:1 on paper and would leave the control edge invisible to low-vision users.
#
# The interface is a duet of ink and paper; hue is reserved for links, status,
# focus, and plot annotation.

THEME_TOKENS <- list(
  light = list(
    mode = "light",
    bg = "#FCFCFC",          # gray 1
    surface = "#FCFCFC",     # gray 1, cards sit flush on the page
    surface2 = "#F0F0F0",    # gray 3, hover and recessed fills
    text = "#202020",        # gray 12
    text_muted = "#646464",  # gray 11
    primary = "#202020",     # gray 12 solid
    primary_soft = "#F4FAFF",# blue 2
    on_primary = "#FFFFFF",  # gray contrast
    accent = "#AB6400",      # amber 11
    accent_ink = "#4F3422",  # amber 12
    danger = "#CE2C31",      # red 11
    danger_soft = "#FEEBEC", # red 3
    ok = "#218358",          # green 11
    border = "#CECECE",      # gray 7
    divider = "#D9D9D9",     # gray 6
    border_strong = "#8D8D8D", # gray 9, control boundary (3.2:1)
    focus = "#0090FF",       # blue 9, focus ring (3.2:1)
    link = "#0D74CE",        # blue 11
    plot_bg = "#FCFCFC",     # gray 1
    plot_fg = "#202020",     # gray 12
    plot_grid = "#E0E0E0",   # gray 5, grid recedes behind marks
    tile_1 = "#F9F9F9",      # gray 2
    tile_fg = "#202020",     # gray 12
    tile_muted = "#646464",  # gray 11
    code_bg = "#F9F9F9",     # gray 2
    code_fg = "#202020",     # gray 12
    header_bg = "#FCFCFC",   # gray 1
    header_fg = "#202020",   # gray 12
    # Step 11 of each hue in both themes: the marks are hairline strokes on the
    # page, and step 11 is the only step that clears 3:1 against both surfaces.
    series = c("#0D74CE", "#AB6400", "#8145B5", "#218358", "#CE2C31")
  ),
  dark = list(
    mode = "dark",
    bg = "#111111",          # gray 1
    surface = "#111111",     # gray 1
    surface2 = "#222222",    # gray 3
    text = "#EEEEEE",        # gray 12
    text_muted = "#B4B4B4",  # gray 11
    primary = "#EEEEEE",     # gray 12 solid
    primary_soft = "#111927",# blue 2
    on_primary = "#111111",  # gray contrast
    accent = "#FFCA16",      # amber 11
    accent_ink = "#FFE7B3",  # amber 12
    danger = "#FF9592",      # red 11
    danger_soft = "#3B1219", # red 3
    ok = "#3DD68C",          # green 11
    border = "#484848",      # gray 7
    divider = "#3A3A3A",     # gray 6
    border_strong = "#6E6E6E", # gray 9, control boundary (3.7:1)
    focus = "#0090FF",       # blue 9, focus ring (5.8:1)
    link = "#70B8FF",        # blue 11
    plot_bg = "#111111",     # gray 1
    plot_fg = "#EEEEEE",     # gray 12
    plot_grid = "#313131",   # gray 5
    tile_1 = "#191919",      # gray 2
    tile_fg = "#EEEEEE",     # gray 12
    tile_muted = "#B4B4B4",  # gray 11
    code_bg = "#222222",     # gray 3
    code_fg = "#EEEEEE",     # gray 12
    header_bg = "#111111",   # gray 1
    header_fg = "#EEEEEE",   # gray 12
    series = c("#70B8FF", "#FFCA16", "#D19DFF", "#3DD68C", "#FF9592")
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
