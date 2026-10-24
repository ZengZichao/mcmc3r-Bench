# Third-party licences and notices

This file reproduces the licences of third-party software distributed with, or
required by, **mcmc3r Bench**. The application itself is licensed under the
MIT License (see `LICENSE`); original documentation is licensed under CC BY 4.0
(see `docs/LICENSE`).

## mcmc3r (upstream package)

- Project: `mcmc3r: Tools to work with MCMCtree and BPP`
- Authors: Mario dos Reis, Sandra Alvarez-Carretero, and contributors
- Source: https://github.com/dosreislab/mcmc3r
- Licence: MIT
- Copyright: Copyright (c) 2017 Mario dos Reis

The package is used as a dependency and is not modified by this project. The
upstream MIT text is reproduced below.

```
MIT License

Copyright (c) 2017 Mario dos Reis

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## R packages

The following packages are required at runtime. Licence names follow the
metadata published on CRAN or the package repository. Consult each package for
the complete licence text.

| Package | Version (lockfile) | Licence | Role |
|---|---|---|---|
| shiny | CRAN | GPL-3 | Web application framework |
| bslib | CRAN | MIT | Bootstrap 5 theming and layout |
| htmltools | CRAN | GPL-3 | HTML generation (Shiny dependency) |
| DT | CRAN | GPL-3 | Data tables |
| data.table | CRAN | MPL-2.0 | Fast table input/output |
| withr | CRAN | MIT | Temporary working-directory isolation |
| zip | CRAN | MIT | ZIP listing and creation |
| jsonlite | CRAN | MIT | JSON metadata |
| commonmark | CRAN | MIT | Help-page Markdown rendering |
| showtext | CRAN | GPL-2 | Text rendering with bundled fonts |
| sysfonts | CRAN | GPL-2 | Font registration |
| systemfonts | CRAN | MIT | Font discovery |
| ragg | CRAN | MIT | Raster graphics device |
| logger | CRAN | MIT | Structured logging |
| mcmc3r | GitHub (pinned SHA) | MIT | Calibration, MCMC summary, marginal likelihood |
| ape | CRAN | GPL-2 \| GPL-3 | Upstream dependency |
| corpcor | CRAN | GPL-2 \| GPL-3 | Upstream dependency |
| coda | CRAN | GPL-2 \| GPL-3 | Upstream dependency |

Development-only packages (`testthat`, `shinytest2`, `chromote`, `renv`,
`rsconnect`, `lintr`) are not distributed with the application bundle.

## Fonts

**Noto Sans SC** is bundled under `www/fonts/` for Chinese text in plots and
exports.

- Copyright 2014–2026 The Noto Project Authors
- Licence: SIL Open Font License, Version 1.1
- Full licence: `www/fonts/OFL.txt`
- Source: https://fonts.google.com/noto/specimen/Noto+Sans+SC

The font is redistributed unchanged except for optional subsetting, which does
not alter the licence or the reserved font name.

## Documentation

Original documentation in this repository is licensed under Creative Commons
Attribution 4.0 International (CC BY 4.0). The full text is in `docs/LICENSE`.
Upstream documentation and papers quoted or referenced here remain under their
original licences and copyright.

## Icons and brand assets

The interface icons and the "tree + curve" brand mark in `www/img/` were drawn
for this project and are distributed under the same MIT licence as the code.
No logos or portraits of the upstream authors or institutions are used.

## No endorsement

None of the third-party authors or projects listed above endorses this GUI.
mcmc3r Bench is an independent, unofficial project.
