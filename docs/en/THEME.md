# Theme system

| Field | Value |
|---|---|
| lang | en |
| pair | ../zh/THEME.md |
| applies_to | 0.1.0 |
| doc_version | 1.1 |
| last_reviewed | 2026-10-25 |
| canonical | true |
| status | current |

**Language:** English | [中文](../zh/THEME.md)

## Scope

Light and dark themes cover the page, cards, forms, buttons, tables, code
blocks, alerts, modals, the file input, the footer, plots, and exports. Theme
and language are independent: any of the four combinations must work.

## Design language

The interface follows the Apple-inspired system in `design-md/apple/DESIGN.md`:

- **Action Blue is the only UI accent.** Every link, pill CTA, selected state,
  and focus ring uses `primary`; warnings and errors use their status hues only.
- **Surfaces create hierarchy.** White tiles sit on parchment `bg` in light mode;
  near-black tiles (`surface`) sit on true black in dark mode. Cards use a
  1px hairline and **no shadow**.
- **Type is quiet and tight.** Display text is weight 600 with negative
  tracking; body text runs at 17px / 1.47. Weight 500 is not used.
- **Two button grammars.** Pill CTAs for actions and compact 8px utility buttons
  for downloads and examples. Press state is `transform: scale(0.95)`.
- **One shadow, reserved for floating layers.** The interface chrome never
  carries a drop shadow; the only shadow in the system is `--product-shadow`,
  and it is applied to the help popover and to product imagery.
- **Global chrome recedes.** A 48px black global nav, a frosted 52px sub-nav,
  a flat notice strip, and a parchment footer frame the workbench.

## Tokens

The semantic tokens are defined twice: in `R/fct_theme.R` for plots/exports and
in `www/css/app.css` as CSS variables. Keep them in sync.

| Token | Light | Dark | Use |
|---|---|---|---|
| `bg` | `#F5F5F7` | `#000000` | Page background |
| `surface` | `#FFFFFF` | `#1D1D1F` | Cards, tables, panels |
| `surface2` | `#FAFAFC` | `#272729` | Pearl tiles, secondary surfaces |
| `text` | `#1D1D1F` | `#F5F5F7` | Primary text |
| `text_muted` | `#6E6E73` | `#A1A1A6` | Secondary text |
| `primary` | `#0066CC` | `#2997FF` | Action Blue: links, buttons, main curve |
| `primary_soft` | `#E8F1FB` | `#0A2A45` | Selected state, hints |
| `on_primary` | `#FFFFFF` | `#001D33` | Text on primary buttons |
| `accent` | `#B25000` | `#FFB340` | Warnings and highlights |
| `accent_ink` | `#7A3B00` | `#FFD9A0` | Warning text |
| `danger` | `#B3261E` | `#FF6961` | Errors |
| `danger_soft` | `#FDECEA` | `#3A1210` | Error alert surface |
| `ok` | `#1D7A46` | `#5BD6A8` | Success status |
| `border` | `#C9C9CF` | `#47474B` | Decorative hairlines only |
| `border_strong` | `#86868B` | `#7C7C81` | Boundaries that identify a control; 3:1 against `surface` |
| `divider` | `#DEDEE3` | `#3A3A3F` | Section dividers |
| `tile_1` | `#FAFAFC` | `#272729` | Panel inside a card (empty states, metric tiles) |
| `tile_2` | `#F5F5F7` | `#2A2A2C` | Alternate panel fill |
| `tile_fg` | `#1D1D1F` | `#F5F5F7` | Text on `tile_1`; always paired with it |
| `tile_muted` | `#6E6E73` | `#CCCCCC` | Secondary text on `tile_1` |
| `focus` | `#0071E3` | `#2997FF` | Focus ring |
| `plot_bg` | `#FFFFFF` | `#000000` | Plot background |
| `plot_fg` | `#1D1D1F` | `#F5F5F7` | Plot text and axes |
| `plot_grid` | `#E0E0E0` | `#333336` | Grid lines |

Chart series use an Apple system-inspired data palette (blue, indigo, orange,
purple, green) and are not UI accents. The light primary is `#0066CC`; white
button text reaches 5.57:1. The dark primary is `#2997FF` with near-black text
(6.96:1), keeping the bright Apple blue while still meeting WCAG AA.

## Initialisation (no flash)

An inline script in `<head>` runs before the page is painted:

1. Reads `?theme=`, `localStorage["mcmc3r-bench-theme"]`, and
   `prefers-color-scheme`.
2. Sets `<html data-bs-theme="light|dark">`, a `theme-dark` class, and
   `data-theme`.
3. Updates `<meta name="theme-color">` (`#F5F5F7` light, `#000000` dark).

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

DT is restyled as a gallery table: transparent background, hairline row rules,
small muted headers, no zebra stripes, and a soft Action Blue hover. Dark mode
overrides every cell, control, and empty-state colour so no white cells remain.

## Exports

| Context | Default | Option |
|---|---|---|
| Screen plot | Follows app theme | — |
| PNG/PDF | Print (light) theme | Match screen theme |
| CSV | No theme | — |

Exports are regenerated from the result object with the selected theme; the
screen bitmap is never reused. Metadata records `screen_theme` and
`export_theme`.

## Print

`www/css/print.css` must reset **every** token that carries a dark-mode value,
including the `*_soft` surfaces, `tile_*` fills and `inverse` text. A token left
unreset makes dark-mode printing paint dark text on a dark panel on paper.
`tests/testthat/test-frontend-design.R` guards the palette; the print sheet is
reviewed alongside any new token.

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
