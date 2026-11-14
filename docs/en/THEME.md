# Theme system

| Field | Value |
|---|---|
| lang | en |
| pair | ../zh/THEME.md |
| applies_to | 0.1.0 |
| doc_version | 2.1 |
| last_reviewed | 2026-11-14 |
| canonical | true |
| status | current |

**Language:** English | [中文](../zh/THEME.md)

## Scope

Light and dark themes cover the page, header, cards, forms, buttons, tables,
code blocks, alerts, modals, the file input, the footer, plots, and exports.
Theme and language are independent: any of the four combinations must work.

## Design language

The interface follows the Wired editorial system in
`design-md/wired/DESIGN.md`:

- **Paper and ink.** Light mode is `gray 1` paper (`#FCFCFC`) under `gray 12`
  ink (`#202020`); dark mode is `gray 1` (`#111111`) under `gray 12`
  (`#EEEEEE`). Colour annotates, it does not decorate: blue marks links and
  focus, red, amber, and green mark status.
- **Action colour is ink.** `primary` is `#202020` in light mode and `#EEEEEE`
  in dark mode. It fills the run buttons and draws the main calibration curve.
  Blue is reserved for links, focus rings, and plot series.
- **Hairlines and zero radius.** Every border, rule, table line, and divider is
  0.5px. There are no rounded corners, no drop shadows, and no coloured card
  edges.
- **Three typefaces, four sizes.** A display serif for page titles, a prose
  serif for running text, and a UI sans for controls and data. The scale is
  40 / 22 / 15 / 12 px; hierarchy comes from face, weight, colour, and spacing
  rather than from extra sizes.
- **Sentence case for actions, uppercase only for structure.** Buttons, field
  labels, section rules, tables, and messages are set in sentence case with no
  tracking. Only the top navigation and the footer column rubrics are 12px
  uppercase. Identifiers keep their written case so `tL`, `pL`, `t_` and
  `tau_` stay recognisable.
- **Copy is not decoration.** No `·` separators, no sentence restating what the
  control already shows, and no implementation notes on the workbench. A note
  survives only when it states a rule the user cannot infer from the control.
- **Motion is colour only.** Transitions are 250ms ease-out on colour and
  border. Nothing scales, slides, or fades, and page changes jump. The single
  exception is the spinner inside the running button, which reports state.

## Tokens

The semantic tokens are defined in `R/fct_theme.R` for plots and exports and
mirrored in `www/css/app.css` as CSS variables. Keep them in sync; the CSS
values are part of the test suite. The footer pair (`--footer-bg`,
`--footer-fg`) lives only in CSS, since no plot or export paints a footer.

The palette is Radix UI Colors, used by step role: 1–2 page and surface fills,
3–5 component fills, 6–8 borders, 9–10 solid fills, 11–12 high-contrast text.
Only the steps a component actually needs are imported. Two departures are
deliberate: `border_strong` takes step 9, because step 8 measures 1.9:1 against
the surface and control boundaries need 3:1 (WCAG 1.4.11); `divider` takes
step 6, the Radix divider role, which leaves step 7 for borders.

| Token | Light | Dark | Use |
|---|---|---|---|
| `bg` | `#FCFCFC` | `#111111` | Page background (gray 1) |
| `surface` | `#FCFCFC` | `#111111` | Cards, tables, panels (gray 1) |
| `surface2` | `#F0F0F0` | `#222222` | Recessed tiles and hover fills (gray 3) |
| `text` | `#202020` | `#EEEEEE` | Primary text (gray 12) |
| `text_muted` | `#646464` | `#B4B4B4` | Secondary text (gray 11) |
| `primary` | `#202020` | `#EEEEEE` | Run buttons, main curve (gray 12) |
| `primary_soft` | `#F4FAFF` | `#111927` | Selected state, hints (blue 2) |
| `on_primary` | `#FFFFFF` | `#111111` | Text on `primary` (gray contrast) |
| `link` | `#0D74CE` | `#70B8FF` | Links (blue 11) |
| `accent` | `#AB6400` | `#FFCA16` | Warnings, plot annotation (amber 11) |
| `accent_ink` | `#4F3422` | `#FFE7B3` | Warning text (amber 12) |
| `danger` | `#CE2C31` | `#FF9592` | Errors (red 11) |
| `danger_soft` | `#FEEBEC` | `#3B1219` | Error alert surface (red 3) |
| `ok` | `#218358` | `#3DD68C` | Success status (green 11) |
| `border` | `#CECECE` | `#484848` | Component borders (gray 7) |
| `divider` | `#D9D9D9` | `#3A3A3A` | Section and row rules (gray 6) |
| `border_strong` | `#8D8D8D` | `#6E6E6E` | Boundaries that identify a control (gray 9) |
| `focus` | `#0090FF` | `#0090FF` | Focus ring (blue 9) |
| `tile_1` | `#F9F9F9` | `#191919` | Panel inside a card: empty states, metrics (gray 2) |
| `tile_fg` | `#202020` | `#EEEEEE` | Text on `tile_1`; always paired with it |
| `tile_muted` | `#646464` | `#B4B4B4` | Secondary text on `tile_1` |
| `code_bg` | `#F9F9F9` | `#222222` | Syntax block fill (gray 2 / gray 3) |
| `code_fg` | `#202020` | `#EEEEEE` | Syntax text |
| `header_bg` | `#FCFCFC` | `#111111` | Header band (gray 1) |
| `header_fg` | `#202020` | `#EEEEEE` | Header text (gray 12) |
| `plot_bg` | `#FCFCFC` | `#111111` | Plot background (gray 1) |
| `plot_fg` | `#202020` | `#EEEEEE` | Plot text and axes (gray 12) |
| `plot_grid` | `#E0E0E0` | `#313131` | Grid lines (gray 5) |
| `footer_bg` | `#202020` | `#191919` | Footer band (gray 12 / gray 2) |
| `footer_fg` | `#FFFFFF` | `#EEEEEE` | Footer text (gray contrast / gray 12) |

Plot series are step 11 in both themes: light `#0D74CE`, `#AB6400`, `#8145B5`,
`#218358`, `#CE2C31`; dark `#70B8FF`, `#FFCA16`, `#D19DFF`, `#3DD68C`,
`#FF9592`. Plot marks are hairlines rather than fills, and step 11 is the only
step that clears 3:1 against both page backgrounds.

Measured contrast: light `text/bg` 15.9:1, `text_muted/bg` 5.8:1,
`on_primary/primary` 16.3:1, `border_strong/surface` 3.2:1, `focus/bg` 3.2:1,
`link/bg` 4.7:1, `danger/danger_soft` 4.5:1, `accent/bg` 4.5:1; dark 16.3:1,
9.1:1, 16.3:1, 3.7:1, 5.8:1, 9.0:1, 7.8:1, and 12.3:1.

## Type scale

| Role | Size | Face | Use |
|---|---|---|---|
| Display | 40px | Display serif | Page title (`h1`) only |
| Title | 22px | Display serif | Panel titles, about cards |
| Body | 15px | Prose serif in prose, UI sans in controls | Running text, results |
| Label | 12px | UI sans; uppercase only in navigation and footer rubrics | Nav, buttons, field labels, column heads, notes |

Nothing smaller than 12px ships. Where a distinction is needed below 15px, use
weight (400/500/600), `text_muted`, or letter spacing instead of a new size.

## Layout and alignment

- **One shell.** `--shell: 1240px` and `--gutter: 32px` place the header, the
  page title, the workbench, and the footer on the same left edge. No component
  defines its own page width.
- **Two columns, one rule.** The workbench is `348px` for controls, a `64px`
  gutter, and a fluid result column. The vertical rule is a 0.5px
  `::after` border centred in the gutter, so neither column claims it.
- **Optical alignment.** Control text starts at the shell edge, and the rule
  sits half a gutter away; the run row is sticky at `--header-height + 10px`, so
  the primary action never hides under the header.
- **Nested blocks align inward in one step.** With zero radius there is no
  concentric radius to compute; nested panels inset their content by
  `--space-2` so edges line up with the surrounding container.
- **One measure.** Running text stops at `36em` of the 15px body size
  (540px, about 70 characters). Section rules, lists and tables share that
  measure, so every block on the help page ends on the same right edge.
- **Grouped controls share one frame.** File inputs, checkboxes and segmented
  switches draw a single 0.5px frame around the whole group; internal
  separators are 0.5px and never double up with the outer border.
- **Help contents.** The in-page contents list is numbered with a hanging
  indent, so wrapped entries align under the word rather than under the number;
  on mobile it collapses into a disclosure with a chevron.

## Initialisation (no flash)

An inline script in `<head>` runs before the page is painted:

1. Reads `?theme=`, `localStorage["mcmc3r-bench-theme"]`, and
   `prefers-color-scheme`.
2. Sets `<html data-bs-theme="light|dark">`, a `theme-dark` class, and
   `data-theme`.
3. Updates `<meta name="theme-color">` (`#FCFCFC` light, `#111111` dark).

Server-rendered HTML does not hard-code light backgrounds or text colours.

Priority: URL parameter > stored preference > system preference > light.

## Switching

The header toggle updates the attributes, stores the preference, refreshes its
`aria-label` and `aria-pressed`, and sends
`Shiny.setInputValue("theme", value)`. The icon and the page repaint are the
feedback, so switching shows no toast. The server keeps a `reactiveVal` used by
plot and export code. Switching does not reload the page, reset inputs, or
recompute upstream results.

## Plots

`fct_plots` receives `theme` and uses `plot_colors()`. Base graphics sets
`par(bg, fg, col.axis, col.lab, col.main, col.sub)` and draws grid lines with
`--plot-grid`. The plot is drawn on the page colour with no white card behind
it, and the `plotOutput` container has no fixed background.

- **Annotations sit outside the data area.** Quantile percentages are drawn in
  the top margin, aligned with their dotted rules; a second label moves up one
  text row when two values sit closer than their type. The heading owns the
  row above them, so nothing is drawn over the curve, the grid, or the title.
- **One series, one voice.** A density curve is solid ink; when density and CDF
  share a panel the CDF becomes a dashed muted line on a rotated right axis,
  and the title changes to *Calibration distribution*. There is no legend:
  the axis titles name each series.
- **Titles follow what is drawn.** *Calibration density*, *Cumulative
  distribution*, or *Calibration distribution*.

When the theme changes, plots and tables re-render from in-memory results. The
font is registered once with `sysfonts` and `showtext`; PNG uses a cairo device
and PDF uses cairo_pdf, with the DPI adjusted per export.

## Tables

DT is restyled as a data table: transparent background, 0.5px row rules, no
zebra stripes, 12px muted column heads set in their original case, and a `surface2` hover.
Rows are `8px 12px`, so a ten-row preview reads as one block rather than ten
cards. Numbers are right-aligned and the column head shares the same right
edge; the sort caret waits for hover instead of printing three triangles. The
page-length picker is a 32px field with the same hairline as every other
control. Paging is set as text, with the current page underlined, rather than
as a row of bordered boxes. A table wider than its column keeps its own
horizontal scroll (head and body in step) and the page never scrolls sideways.
Dark mode overrides every cell, control, and empty-state colour so no white
cells remain.

## Exports

| Context | Default | Option |
|---|---|---|
| Screen plot | Follows app theme | — |
| PNG/PDF | Print (light) theme | Match screen theme |
| CSV | No theme | — |

Theme and resolution live in an `Export options` disclosure under the export
buttons, because the defaults cover almost every run. Exports are regenerated
from the result object with the selected theme; the screen bitmap is never
reused. Metadata records `screen_theme` and `export_theme`.

## Print

`www/css/print.css` must reset **every** token that carries a dark-mode value,
including the `*_soft` surfaces, `tile_*` fills and the CSS-only footer pair. A token left
unreset makes dark-mode printing paint dark text on a dark panel on paper.
`tests/testthat/test-frontend-design.R` guards the palette; the print sheet is
reviewed alongside any new token.

## Accessibility

- Body text contrast ≥ 4.5:1 (target ≥ 7:1 for primary text).
- Focus rings are visible on both backgrounds and never removed.
- Status uses a glyph and a word, not colour alone.
- `prefers-reduced-motion` needs no special case: the only transitions are
  colour and border.
- The toggle has an accessible name and `aria-pressed`.
- Both themes are checked with the same keyboard and screen-reader walkthrough.

## QA matrix

Two languages × two themes × two viewports (desktop 1440×900, mobile 375×812)
= 8 screenshots in `docs/assets/screenshots/`. Check empty, loading, success,
warning, and error states, plus tables, code blocks, alerts, modals, and
downloads.
