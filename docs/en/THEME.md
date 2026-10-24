# Theme system

| Field | Value |
|---|---|
| lang | en |
| pair | ../zh/THEME.md |
| applies_to | 0.1.0 |
| doc_version | 1.0 |
| last_reviewed | 2026-10-24 |
| canonical | true |
| status | current |

**Language:** English | [中文](../zh/THEME.md)

## Scope

Light and dark themes cover the page, cards, forms, buttons, tables, code
blocks, alerts, modals, the file input, the footer, plots, and exports. Theme
and language are independent: any of the four combinations must work.

## Tokens

The semantic tokens are defined twice: in `R/fct_theme.R` for plots/exports and
in `www/css/app.css` as CSS variables. Keep them in sync.

| Token | Light | Dark | Use |
|---|---|---|---|
| `bg` | `#F7F9FB` | `#0B1220` | Page background |
| `surface` | `#FFFFFF` | `#111A2B` | Cards and tables |
| `surface2` | `#EEF3F7` | `#172236` | Secondary surfaces |
| `text` | `#10243E` | `#E6EDF5` | Primary text |
| `text_muted` | `#48617A` | `#A9B7C6` | Secondary text |
| `primary` | `#0C7A7C` | `#3CC7C2` | Buttons, links, main curve |
| `primary_soft` | `#D9F0EF` | `#123B3A` | Selected state, hints |
| `accent` | `#B87316` | `#F2B45C` | Warnings and highlights |
| `accent_ink` | `#6B4300` | `#FFD79A` | Warning text |
| `danger` | `#B23A2E` | `#FF7A6B` | Errors |
| `border` | `#D5DFE8` | `#263445` | Borders and dividers |
| `focus` | `#1F6FEB` | `#7CC4FF` | Focus ring |
| `plot_bg` | `#FFFFFF` | `#0B1220` | Plot background |
| `plot_fg` | `#10243E` | `#E6EDF5` | Plot text and axes |
| `plot_grid` | `#DCE4EC` | `#263445` | Grid lines |

The light primary is `#0C7A7C` rather than a lighter teal so that white button
text reaches a contrast ratio of at least 4.5:1.

## Initialisation (no flash)

An inline script in `<head>` runs before the page is painted:

1. Reads `?theme=`, `localStorage["mcmc3r-bench-theme"]`, and
   `prefers-color-scheme`.
2. Sets `<html data-bs-theme="light|dark">`, a `theme-dark` class, and
   `data-theme`.
3. Updates `<meta name="theme-color">`.

Server-rendered HTML does not hard-code light backgrounds or text colours.

Priority: URL parameter > stored preference > system preference > light.

## Switching

The header toggle updates the attributes, stores the preference, updates its
label and `aria-label`, and sends `Shiny.setInputValue("theme", value)`. The
server keeps a `reactiveVal` used by plot and export code. Switching does not
reload the page, reset inputs, or recompute upstream results.

## Plots

`fct_plots` receives `theme` and uses `plot_colors()`. Base graphics sets
`par(bg, fg, col.axis, col.lab, col.main, col.sub)` and draws grid lines with
`--plot-grid`. The `plotOutput` container has no fixed white background.

When the theme changes, plots and tables re-render from in-memory results. The
font is registered once with `sysfonts` and `showtext`; PNG uses a cairo device
and PDF uses cairo_pdf, with the DPI adjusted per export.

## Tables

DT uses Bootstrap 5 styling. Dark mode overrides the table background, header,
striped rows, hover, links, and empty-state text so no white cells remain.

## Exports

| Context | Default | Option |
|---|---|---|
| Screen plot | Follows app theme | — |
| PNG/PDF | Print (light) theme | Match screen theme |
| CSV | No theme | — |

Exports are regenerated from the result object with the selected theme; the
screen bitmap is never reused. Metadata records `screen_theme` and
`export_theme`.

## Accessibility

- Body text contrast ≥ 4.5:1 (target ≥ 7:1 for primary text).
- Focus rings visible on both backgrounds.
- Status uses icon + text, not colour alone.
- `prefers-reduced-motion` is respected.
- The toggle has an accessible name and `aria-pressed`.
- Both themes are checked with the same keyboard and screen-reader walkthrough.

## QA matrix

Two languages × two themes × two viewports (desktop 1440×900, mobile 375×812)
= 8 screenshots in `docs/assets/screenshots/`. Check empty, loading, success,
warning, and error states, plus tables, code blocks, alerts, modals, and
downloads.
