# Contributing

Thanks for helping improve mcmc3r Bench. This is an independent, unofficial
GUI for the MIT-licensed `mcmc3r` package. By contributing you agree to the
[Code of Conduct](CODE_OF_CONDUCT.md) and to license your code contribution
under MIT and documentation under CC BY 4.0.

## Before you start

- Open an issue for substantial features or behavioural changes.
- Do not modify upstream `mcmc3r` in this repository; it is a pinned dependency.
- Do not include secrets, tokens, or private data.
- Keep changes focused; avoid unrelated refactors.

## Development setup

```bash
cd mcmc3r-Bench
Rscript -e 'renv::restore()'
Rscript -e 'shiny::runApp(".")'
```

If the upstream GitHub repository is unreachable, install the local snapshot
into `.Rlib` for development only. Deployment builds must use the pinned GitHub
source.

## Architecture rules

- UI modules call service functions; they never call `mcmc3r::` directly.
- Services never touch `input`, `output`, or `session`.
- Wrap upstream calls in `withr::with_dir()`; never call `setwd()` globally.
- Write files only in session temporary directories.
- Use `tr()` for server-side text and `data-i18n` keys for static UI text.
- Use theme tokens for colours; do not hard-code light colours.
- Raise `app_error` for all user-facing failures.
- Add dependencies only with a clear reason and a `renv.lock` update.

## Bilingual changes

- Update `i18n/translations.csv` with both `en` and `zh` values.
- Run `Rscript dev/build_i18n.R`; do not edit `www/js/i18n.js` by hand.
- Update `i18n/help_en.md` and `help_zh.md` together.
- Update both `docs/en/` and `docs/zh/` files in the same change.
- Update `docs/GLOSSARY.md` before introducing a new term.

## Tests

```bash
Rscript tests/testthat.R
Rscript dev/i18n_check.R
Rscript dev/docs_check.R
Rscript dev/check_release.R
```

Add tests for new service behaviour and fixtures for new file edge cases. Do not
commit large data; fixtures must stay under 5 MB each.

## Commits and pull requests

Use Conventional Commits, for example:

```
feat(calibration): add quantile table
fix(marginal): reject beta values equal to 1
docs(i18n): update glossary
test(mcmc): cover tau_ prefix
```

Pull requests should describe the change, list affected i18n keys and
documentation pairs, include screenshots for UI changes (EN/ZH, light/dark), and
confirm that tests pass. Squash merges are preferred.

## Reporting issues

Include the app version, module, error code, language/theme, browser, and copied
diagnostics. Do not upload confidential data. A minimal reproducible input is
very helpful.

## Security

Report vulnerabilities privately as described in [SECURITY.md](SECURITY.md).
Do not open a public issue with exploit details.
