# Plotting ----------------------------------------------------------------
# All plots use base graphics and receive a theme so that screen and export
# output follow the semantic colour tokens.

if (!exists(".plot_env", envir = globalenv(), inherits = FALSE)) {
  .plot_env <- new.env(parent = emptyenv())
  .plot_env$font_registered <- FALSE
  .plot_env$font_family <- ""
}

register_app_font <- function() {
  if (isTRUE(.plot_env$font_registered)) return(invisible(.plot_env$font_family))
  path <- app_path("www", "fonts", "NotoSansSC-Regular.ttf")
  if (file.exists(path) && requireNamespace("sysfonts", quietly = TRUE)) {
    ok <- tryCatch({
      sysfonts::font_add("NotoSansSC", regular = path)
      TRUE
    }, error = function(e) FALSE)
    if (ok && requireNamespace("showtext", quietly = TRUE)) {
      showtext::showtext_auto()
      showtext::showtext_opts(dpi = 96)
      .plot_env$font_family <- "NotoSansSC"
    }
  }
  .plot_env$font_registered <- TRUE
  options(shiny.usecairo = TRUE)
  invisible(.plot_env$font_family)
}

plot_font <- function() {
  register_app_font()
  if (nzchar(.plot_env$font_family)) .plot_env$font_family else ""
}

set_plot_par <- function(colors) {
  graphics::par(
    bg = colors$bg,
    fg = colors$fg,
    col.axis = colors$fg,
    col.lab = colors$fg,
    col.main = colors$fg,
    col.sub = colors$muted,
    family = plot_font(),
    las = 1,
    cex.axis = 0.85,
    cex.lab = 0.95,
    cex.main = 1.05,
    cex.sub = 0.78,
    mgp = c(2.4, 0.6, 0),
    bty = "n",
    tcl = -0.25
  )
}

plot_grid_lines <- function(colors, nx = 5, ny = 5) {
  graphics::abline(h = pretty(graphics::par("usr")[3:4], ny),
                   v = pretty(graphics::par("usr")[1:2], nx),
                   col = colors$grid, lwd = 0.6)
}

cal_parameter_note <- function(result, lang) {
  p <- result$params
  key <- paste0("plot.params.", result$type)
  switch(
    result$type,
    L = tr(key, lang, tL = fmt_num(p$tL), p = fmt_num(p$p),
           c = fmt_num(p$c), pL = fmt_num(p$pL)),
    B = tr(key, lang, tL = fmt_num(p$tL), tU = fmt_num(p$tU),
           pL = fmt_num(p$pL), pU = fmt_num(p$pU)),
    U = tr(key, lang, tU = fmt_num(p$tU), pU = fmt_num(p$pU))
  )
}

draw_calibration <- function(result, lang = "en", theme = "light",
                             show_density = TRUE, show_cdf = FALSE,
                             export = FALSE, quantile_note = TRUE) {
  colors <- plot_colors(theme, export = export)
  set_plot_par(colors)
  graphics::par(mar = c(5.0, 4.4, 4.4, if (show_density && show_cdf) 5.2 else 1.4))

  x <- result$table$x
  y <- result$table$density
  cdf <- result$table$cdf
  finite_y <- y[is.finite(y)]
  ymax <- if (length(finite_y)) max(finite_y) else 1
  if (!is.finite(ymax) || ymax <= 0) ymax <- 1

  type_label <- tr(paste0("cal.type.", result$type), lang)
  title <- tr(
    if (show_density && show_cdf) {
      "plot.title.calibration_both"
    } else if (show_cdf) {
      "plot.title.calibration_cdf"
    } else {
      "plot.title.calibration_density"
    },
    lang
  )
  xlab <- tr("plot.axis_time", lang)

  if (show_density && show_cdf) {
    graphics::plot(
      x, y,
      type = "n",
      xlab = xlab, ylab = tr("plot.axis_density", lang),
      ylim = c(0, ymax * 1.08), xaxs = "i", yaxs = "i",
      main = ""
    )
    plot_grid_lines(colors)
    graphics::lines(x, y, col = colors$primary, lwd = 2.2)
    graphics::par(new = TRUE)
    graphics::plot(
      x, cdf, type = "n",
      axes = FALSE, xlab = "", ylab = "", ylim = c(0, 1),
      xaxs = "i", yaxs = "i"
    )
    graphics::lines(x, cdf, col = colors$muted, lwd = 1.7, lty = 2)
    graphics::axis(4, col = colors$fg, col.axis = colors$fg, las = 1,
                   cex.axis = 0.78)
    graphics::mtext(tr("plot.axis_cdf", lang), side = 4, line = 1.5,
                    las = 0, col = colors$muted, cex = 0.78)
  } else if (show_cdf) {
    graphics::plot(
      x, cdf,
      type = "n",
      xlab = xlab, ylab = tr("plot.axis_cdf", lang),
      ylim = c(0, 1), xaxs = "i", yaxs = "i",
      main = ""
    )
    plot_grid_lines(colors)
    graphics::lines(x, cdf, col = colors$primary, lwd = 2.2)
  } else {
    graphics::plot(
      x, y,
      type = "n",
      xlab = xlab, ylab = tr("plot.axis_density", lang),
      ylim = c(0, ymax * 1.08), xaxs = "i", yaxs = "i",
      main = ""
    )
    plot_grid_lines(colors)
    graphics::lines(x, y, col = colors$primary, lwd = 2.2)
  }

  # The title owns the top row: quantile labels sit below it, so a narrow plot
  # never lets "50%" run into the heading.
  graphics::mtext(title, side = 3, line = 3.2, cex = 1.05, col = colors$fg,
                  font = graphics::par("font.main"), xpd = NA)

  if (isTRUE(quantile_note) && nrow(result$quantiles)) {
    probs <- result$quantiles$probability
    qs <- result$quantiles$quantile
    labels <- paste0(
      formatC(probs * 100, format = "fg", digits = 3, drop0trailing = TRUE), "%"
    )
    for (q in qs) {
      graphics::abline(v = q, col = colors$accent, lty = 3, lwd = 1.2)
    }
    # The default quantiles sit close together on a wide time axis, so two
    # labels can be wider than the gap between their lines and collide even
    # when they alternate rows. Measure each label and push neighbours apart.
    xlim <- graphics::par("usr")[1:2]
    half <- vapply(labels, function(lab)
      graphics::strwidth(lab, cex = 0.8, units = "user") / 2, numeric(1))
    gap <- half[1] * 0.25 + diff(xlim) * 0.002
    placed <- sort.int(qs, index.return = TRUE)$x
    order <- order(qs)
    for (k in seq_along(placed)[-1]) {
      i <- order[k]
      prev <- order[k - 1]
      need <- half[prev] + half[i] + gap
      if (placed[k] - placed[k - 1] < need) placed[k] <- placed[k - 1] + need
    }
    for (k in rev(seq_along(placed))[-1]) {
      i <- order[k]
      nxt <- order[k + 1]
      need <- half[i] + half[nxt] + gap
      if (placed[k + 1] - placed[k] < need) placed[k] <- placed[k + 1] - need
    }
    placed <- pmin(pmax(placed, xlim[1] + half[order]), xlim[2] - half[order])
    # Anchor labels to their own line unless nudging would run out of plot.
    # Neighbours that would touch move up one text row instead of overlapping.
    rows <- rep(1L, length(placed))
    if (length(placed) > 1) {
      for (k in seq_along(placed)[-1]) {
        need <- half[order[k - 1]] + half[order[k]] + gap * 2
        if (placed[k] - placed[k - 1] < need) rows[k] <- 2L
      }
    }
    for (k in seq_along(placed)) {
      i <- order[k]
      at <- if (abs(placed[k] - qs[i]) <= half[i] * 2.5) placed[k] else qs[i]
      graphics::mtext(
        labels[i], side = 3, at = at,
        line = if (rows[k] == 2L) 1.4 else 0.35, cex = 0.8,
        col = colors$accent, xpd = NA
      )
    }
  }
  graphics::mtext(
    cal_parameter_note(result, lang), side = 1, line = 3.9,
    cex = 0.8, col = colors$muted
  )
  invisible(colors)
}

draw_marginal <- function(result, lang = "en", theme = "light",
                          export = FALSE) {
  colors <- plot_colors(theme, export = export)
  set_plot_par(colors)
  graphics::par(mar = c(5.0, 4.4, 2.8, 1.4))

  beta <- result$per_beta$beta
  y <- result$per_beta$mean_logl
  ok <- is.finite(beta) & is.finite(y)
  if (!any(ok)) {
    graphics::plot.new()
    graphics::title(main = tr("plot.title.marginal", lang))
    return(invisible(colors))
  }
  rng <- range(y[ok])
  pad <- diff(rng) * 0.08
  if (!is.finite(pad) || pad == 0) pad <- max(abs(rng[1]) * 0.02, 1)

  graphics::plot(
    beta[ok], y[ok],
    type = "n",
    xlab = tr("plot.axis_beta", lang),
    ylab = tr("plot.axis_mean_logl", lang),
    ylim = c(rng[1] - pad, rng[2] + pad), xlim = c(0, 1),
    xaxs = "i", yaxs = "i",
    main = tr("plot.title.marginal", lang)
  )
  plot_grid_lines(colors)
  graphics::lines(beta[ok], y[ok], col = colors$primary, lwd = 2.2)
  graphics::points(beta[ok], y[ok], pch = 19, col = colors$primary,
                   cex = 0.75)
  if (any(result$per_beta$se_warning %in% TRUE)) {
    bad <- ok & result$per_beta$se_warning %in% TRUE
    graphics::points(beta[bad], y[bad], pch = 1, cex = 1.3,
                     col = colors$accent, lwd = 1.6)
  }
  graphics::mtext(
    paste0(
      tr(ml_method_label_key(result$method), lang),
      if (nzchar(result$model_name)) paste0(" \u2014 ", result$model_name) else ""
    ),
    side = 1, line = 3.9, cex = 0.8, col = colors$muted
  )
  invisible(colors)
}

with_showtext_dpi <- function(dpi, code) {
  old <- NULL
  if (requireNamespace("showtext", quietly = TRUE) &&
      isTRUE(.plot_env$font_registered)) {
    old <- tryCatch(showtext::showtext_opts(dpi = dpi), error = function(e) NULL)
  }
  on.exit({
    if (!is.null(old) && requireNamespace("showtext", quietly = TRUE)) {
      try(showtext::showtext_opts(old), silent = TRUE)
    }
  }, add = TRUE)
  force(code)
}

save_plot_png <- function(path, draw, theme = "light", width = 1600,
                          height = 1200, res = 150) {
  colors <- plot_colors(theme, export = FALSE)
  if (capabilities("cairo")) {
    grDevices::png(path, width = width, height = height, res = res,
                   type = "cairo", bg = colors$bg)
  } else {
    grDevices::png(path, width = width, height = height, res = res,
                   bg = colors$bg)
  }
  on.exit(grDevices::dev.off(), add = TRUE)
  with_showtext_dpi(res, draw(colors))
  invisible(path)
}

save_plot_pdf <- function(path, draw, theme = "light", width = 8.27,
                          height = 5.83) {
  colors <- plot_colors(theme, export = FALSE)
  if (capabilities("cairo")) {
    grDevices::cairo_pdf(path, width = width, height = height,
                         family = if (nzchar(plot_font())) "NotoSansSC" else "sans",
                         bg = colors$bg)
  } else {
    grDevices::pdf(path, width = width, height = height,
                   family = if (nzchar(plot_font())) "NotoSansSC" else "sans",
                   bg = colors$bg)
  }
  on.exit(grDevices::dev.off(), add = TRUE)
  with_showtext_dpi(72, draw(colors))
  invisible(path)
}
