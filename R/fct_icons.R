# Inline icons ------------------------------------------------------------
# Small, self-drawn line icons (24x24, currentColor) used across the UI.

icon_svg <- function(name, size = 18, class = "icon") {
  body <- switch(
    name,
    "play" = '<polygon points="6 4 20 12 6 20 6 4"/>',
    "reset" = '<path d="M3 12a9 9 0 1 0 3-6.7"/><polyline points="3 3 3 9 9 9"/>',
    "download" = '<path d="M12 3v12"/><polyline points="7 10 12 15 17 10"/><path d="M5 21h14"/>',
    "copy" = '<rect x="9" y="9" width="11" height="11" rx="2"/><path d="M5 15V5a2 2 0 0 1 2-2h10"/>',
    "alert-triangle" = '<path d="M12 3 2.5 20h19L12 3z"/><path d="M12 9v5"/><circle cx="12" cy="17.2" r="0.8"/>',
    "alert" = '<circle cx="12" cy="12" r="9"/><path d="M12 8v5"/><circle cx="12" cy="16.5" r="0.8"/>',
    "info" = '<circle cx="12" cy="12" r="9"/><path d="M12 11v6"/><circle cx="12" cy="7.5" r="0.8"/>',
    "help" = '<circle cx="12" cy="12" r="9"/><path d="M9.6 9.2a2.5 2.5 0 1 1 4.2 1.9c-.8.7-1.5 1.2-1.5 2.4"/><circle cx="12" cy="17" r="0.8"/>',
    "sun" = '<circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4"/>',
    "moon" = '<path d="M20.5 14.5A8.5 8.5 0 1 1 9.5 3.5a7 7 0 0 0 11 11z"/>',
    "tree" = '<path d="M12 21V9"/><path d="M12 9 7 5"/><path d="M12 9l5-4"/><path d="M12 15l-4-3"/><path d="M12 15l4-3"/><circle cx="7" cy="5" r="1.6"/><circle cx="17" cy="5" r="1.6"/><circle cx="8" cy="12" r="1.4"/><circle cx="16" cy="12" r="1.4"/>',
    "file" = '<path d="M6 3h8l4 4v14H6z"/><path d="M14 3v5h4"/><path d="M9 13h6M9 17h6"/>',
    "upload" = '<path d="M12 16V4"/><polyline points="7 9 12 4 17 9"/><path d="M5 20h14"/>',
    "check" = '<path d="M4 12.5 9.5 18 20 6.5"/>',
    "x" = '<path d="M6 6l12 12M18 6 6 18"/>',
    "chevron" = '<polyline points="6 9 12 15 18 9"/>',
    "github" = '<path d="M9 19c-4 1.5-4-2.5-6-3m12 6v-3.5c0-1 .1-1.4-.5-2 2.8-.3 4.5-1.4 4.5-5a3.9 3.9 0 0 0-1.1-2.7 3.6 3.6 0 0 0-.1-2.7s-1.1-.3-3.5 1.3a12.3 12.3 0 0 0-6.6 0C5.3 2.8 4.2 3.1 4.2 3.1a3.6 3.6 0 0 0-.1 2.7A3.9 3.9 0 0 0 3 8.5c0 3.6 1.7 4.7 4.5 5-.6.6-.6 1.2-.5 2V22"/>',
    "chart" = '<path d="M4 20V9"/><path d="M10 20V4"/><path d="M16 20v-7"/><path d="M22 20H2"/>',
    "sliders" = '<path d="M4 6h16M4 12h16M4 18h16"/><circle cx="8" cy="6" r="2"/><circle cx="15" cy="12" r="2"/><circle cx="10" cy="18" r="2"/>',
    NULL
  )
  if (is.null(body)) return("")
  paste0(
    '<svg class="', class, '" width="', size, '" height="', size,
    '" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" ',
    'stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false">',
    body, "</svg>"
  )
}

brand_svg <- function() {
  paste0(
    '<svg class="brand-mark" viewBox="0 0 48 48" fill="none" aria-hidden="true" focusable="false">',
    '<path d="M24 40V22" stroke="currentColor" stroke-width="2.4" stroke-linecap="round"/>',
    '<path d="M24 24 14 15M24 24l10-9M24 32l-7-6M24 32l7-6" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>',
    '<circle cx="14" cy="15" r="3.2" fill="currentColor"/>',
    '<circle cx="34" cy="15" r="3.2" fill="currentColor"/>',
    '<circle cx="17" cy="26" r="2.6" fill="currentColor"/>',
    '<circle cx="31" cy="26" r="2.6" fill="currentColor"/>',
    '<path d="M8 40c4-6 9-8 16-8s12 2 16 8" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-dasharray="2 4"/>',
    '</svg>'
  )
}
