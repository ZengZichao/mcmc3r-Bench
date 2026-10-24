# Calibration service -----------------------------------------------------
# Validates parameters and computes density/CDF/quantiles through the exported
# mcmc3r API. All upstream calls happen here; UI modules never call mcmc3r.

cal_defaults <- function(type = "L") {
  list(
    type = type,
    tL = 10,
    tU = 20,
    p = 0.1,
    c = 1,
    pL = 0.025,
    pU = 0.025,
    xmax = NA_real_,
    points = 1000,
    probs = c(0.025, 0.5, 0.975)
  )
}

cal_validate <- function(params, module = "calibration") {
  type <- params$type %||% "L"
  if (!type %in% c("L", "B", "U")) {
    stop_app("validation", "CAL-001", detail = paste0("type=", type),
             context = list(module = module))
  }

  if (type %in% c("L", "B")) {
    assert_scalar_number(params$tL, "CAL-001", module, "tL",
                         min = 0, open_min = TRUE)
  }
  if (type %in% c("L", "B")) {
    assert_scalar_number(params$c, "CAL-002", module, "c",
                         min = 0, open_min = TRUE)
    assert_scalar_number(params$p, "CAL-003", module, "p", min = 0)
  }
  if (type %in% c("L", "B")) {
    assert_scalar_number(params$pL, "CAL-004", module, "pL",
                         min = 0, max = 1, open_min = TRUE, open_max = TRUE)
  }

  if (identical(type, "B")) {
    if (!is_scalar_number(params$tU) || params$tU <= params$tL) {
      stop_app("validation", "CAL-005",
               detail = paste0("tL=", params$tL, "; tU=", params$tU),
               context = list(module = module))
    }
    if (!is_scalar_number(params$pU) ||
        params$pU <= 0 || params$pU >= 1 ||
        params$pL + params$pU >= 1) {
      stop_app("validation", "CAL-006",
               detail = paste0("pL=", params$pL, "; pU=", params$pU),
               context = list(module = module))
    }
  }

  if (identical(type, "U")) {
    if (!is_scalar_number(params$pU) || params$pU <= 0 || params$pU >= 1) {
      stop_app("validation", "CAL-006",
               detail = paste0("pU=", params$pU),
               context = list(module = module))
    }
  }

  probs <- params$probs
  if (!is.numeric(probs) || !length(probs) || length(probs) > 10 ||
      any(!is.finite(probs)) || any(probs <= 0.001) || any(probs >= 0.999)) {
    stop_app("validation", "CAL-007",
             detail = paste0("probs=", paste(probs, collapse = ",")),
             context = list(module = module))
  }

  pts <- params$points
  if (!is_whole_number(pts) ||
      pts < LIMITS$calibration_points_min ||
      pts > LIMITS$calibration_points_max) {
    stop_app("validation", "CAL-009",
             detail = paste0("points=", pts),
             context = list(module = module))
  }

  if (!is.null(params$xmax) && !is.na(params$xmax)) {
    assert_scalar_number(params$xmax, "CAL-008", module, "xmax",
                         min = 0, open_min = TRUE)
  }
  invisible(TRUE)
}

cal_quantile_fun <- function(type) {
  switch(
    type,
    L = mcmc3r::qL,
    B = mcmc3r::qB,
    U = mcmc3r::qU,
    stop("unknown type")
  )
}

cal_quantile_args <- function(params) {
  type <- params$type
  switch(
    type,
    L = list(tL = params$tL, p = params$p, c = params$c, pL = params$pL),
    B = list(tL = params$tL, tU = params$tU, pL = params$pL, pU = params$pU),
    U = list(tU = params$tU, pU = params$pU)
  )
}

cal_auto_xmax <- function(params) {
  qfun <- cal_quantile_fun(params$type)
  args <- cal_quantile_args(params)
  q975 <- tryCatch(
    do.call(qfun, c(list(prob = 0.975), args)),
    error = function(e) NA_real_
  )
  base <- switch(
    params$type,
    L = params$tL,
    B = params$tU,
    U = params$tU
  )
  if (!is_scalar_number(q975) || q975 <= 0) q975 <- base * 3
  # Keep a visible tail and avoid absurd axes.
  round(max(q975 * 1.15, base * 1.25), 3)
}

cal_density_value <- function(type, x, params) {
  switch(
    type,
    L = mcmc3r::dL(x, tL = params$tL, p = params$p, c = params$c,
                   pL = params$pL),
    B = mcmc3r::dB(x, tL = params$tL, tU = params$tU, pL = params$pL,
                   pU = params$pU),
    U = mcmc3r::dU(x, tU = params$tU, pU = params$pU)
  )
}

cal_cdf_value <- function(type, x, params) {
  switch(
    type,
    L = mcmc3r::pL(x, tL = params$tL, p = params$p, c = params$c,
                   pL = params$pL),
    B = mcmc3r::pB(x, tL = params$tL, tU = params$tU, pL = params$pL,
                   pU = params$pU),
    U = mcmc3r::pU(x, tU = params$tU, pU = params$pU)
  )
}

cal_syntax <- function(params) {
  type <- params$type
  switch(
    type,
    L = sprintf("L(%s, %s, %s, %s)",
                fmt_num(params$tL), fmt_num(params$p),
                fmt_num(params$c), fmt_num(params$pL)),
    B = sprintf("B(%s, %s, %s, %s)",
                fmt_num(params$tL), fmt_num(params$tU),
                fmt_num(params$pL), fmt_num(params$pU)),
    U = sprintf("U(%s, %s)",
                fmt_num(params$tU), fmt_num(params$pU))
  )
}

cal_compute <- function(params, module = "calibration") {
  cal_validate(params, module = module)
  xmax <- params$xmax
  if (is.null(xmax) || is.na(xmax)) xmax <- cal_auto_xmax(params)

  n <- as.integer(round(params$points))
  x <- seq(0, xmax, length.out = n)

  density <- cal_density_value(params$type, x, params)
  cdf <- cal_cdf_value(params$type, x, params)

  bad_density <- !is.finite(density)
  bad_cdf <- !is.finite(cdf)
  warnings <- list()
  if (any(bad_density) || any(bad_cdf)) {
    warnings[[length(warnings) + 1]] <- list(
      code = "CAL-011",
      detail = paste0(
        "non-finite density=", sum(bad_density),
        "; non-finite cdf=", sum(bad_cdf),
        "; x=", paste(utils::head(x[bad_density | bad_cdf], 5), collapse = ",")
      )
    )
  }
  density[bad_density] <- NA_real_
  cdf[bad_cdf] <- NA_real_

  qfun <- cal_quantile_fun(params$type)
  qargs <- cal_quantile_args(params)
  qvals <- tryCatch(
    do.call(qfun, c(list(prob = params$probs), qargs)),
    error = function(e) {
      stop_app("validation", "CAL-010",
               detail = conditionMessage(e),
               context = list(module = module, type = params$type))
    }
  )
  if (any(!is.finite(qvals)) || any(qvals < 0)) {
    stop_app("validation", "CAL-010",
             detail = paste0("quantiles=", paste(qvals, collapse = ",")),
             context = list(module = module, type = params$type))
  }

  table <- data.frame(
    x = x,
    density = density,
    cdf = cdf,
    stringsAsFactors = FALSE
  )
  quantiles <- data.frame(
    probability = params$probs,
    quantile = as.numeric(qvals),
    stringsAsFactors = FALSE
  )

  list(
    table = table,
    quantiles = quantiles,
    syntax = cal_syntax(params),
    warnings = warnings,
    xmax = xmax,
    xmax_auto = is.null(params$xmax) || is.na(params$xmax),
    type = params$type,
    params = params,
    n_infinite = sum(bad_density) + sum(bad_cdf)
  )
}

# Density values exposed for tests and CSV export.
cal_density <- function(x, params) {
  cal_density_value(params$type, x, params)
}
