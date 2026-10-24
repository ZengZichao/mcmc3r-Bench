# Translation status / 翻译状态

This matrix is updated whenever a document pair changes. `current` means both
languages exist, share the same structure, and were reviewed against the same
project version. `needs-review` is allowed only for P1 documents and must be
mentioned in release notes. `missing` blocks a release.

本表随文档变更同步更新。`current` 表示两种语言均存在、结构一致，并针对同一项目
版本审校；`needs-review` 仅允许用于 P1 文档，且必须在发布说明中注明；`missing`
会阻塞发布。

| Pair | English | 中文 | Status | Doc version | Applies to |
|---|---|---|---|---|---|
| Quick start | `docs/en/QUICKSTART.md` | `docs/zh/QUICKSTART.md` | current | 1.0 | 0.1.0 |
| User guide | `docs/en/USER_GUIDE.md` | `docs/zh/USER_GUIDE.md` | current | 1.0 | 0.1.0 |
| File formats | `docs/en/FILE_FORMATS.md` | `docs/zh/FILE_FORMATS.md` | current | 1.0 | 0.1.0 |
| Methods | `docs/en/METHODS.md` | `docs/zh/METHODS.md` | current | 1.0 | 0.1.0 |
| FAQ | `docs/en/FAQ.md` | `docs/zh/FAQ.md` | current | 1.0 | 0.1.0 |
| Privacy | `docs/en/PRIVACY.md` | `docs/zh/PRIVACY.md` | current | 1.0 | 0.1.0 |
| Architecture | `docs/en/ARCHITECTURE.md` | `docs/zh/ARCHITECTURE.md` | current | 1.0 | 0.1.0 |
| Deployment | `docs/en/DEPLOYMENT.md` | `docs/zh/DEPLOYMENT.md` | current | 1.0 | 0.1.0 |
| Testing | `docs/en/TESTING.md` | `docs/zh/TESTING.md` | current | 1.0 | 0.1.0 |
| i18n | `docs/en/I18N.md` | `docs/zh/I18N.md` | current | 1.0 | 0.1.0 |
| Theme | `docs/en/THEME.md` | `docs/zh/THEME.md` | current | 1.0 | 0.1.0 |
| Citation | `docs/en/CITATION.md` | `docs/zh/CITATION.md` | current | 1.0 | 0.1.0 |
| Attribution | `docs/en/ATTRIBUTION.md` | `docs/zh/ATTRIBUTION.md` | current | 1.0 | 0.1.0 |
| In-app help | `i18n/help_en.md` | `i18n/help_zh.md` | current | 1.0 | 0.1.0 |
| README | `README.md` | `README.zh-CN.md` | current | 1.0 | 0.1.0 |
| Contributing | `CONTRIBUTING.md` | `CONTRIBUTING.zh-CN.md` | current | 1.0 | 0.1.0 |
| Security | `SECURITY.md` | `SECURITY.zh-CN.md` | current | 1.0 | 0.1.0 |
| Code of conduct | `CODE_OF_CONDUCT.md` | `CODE_OF_CONDUCT.zh-CN.md` | current | 1.0 | 0.1.0 |
| Glossary | `docs/GLOSSARY.md` | `docs/GLOSSARY.md` (bilingual) | current | 1.0 | 0.1.0 |

## Review record / 审校记录

| Date | Scope | Reviewer | Result |
|---|---|---|---|
| 2026-10-24 | All pairs above | Maintainer | current |

## How to update / 如何更新

1. Edit the canonical document.
2. Update the mirror in the same change.
3. Update this table and both `last_reviewed` metadata fields.
4. Run `Rscript dev/docs_check.R`.
5. For high-risk pages (privacy, licence, citation, methods), request a domain
   review before release.

1. 修改基准文档。
2. 在同一提交中更新镜像文档。
3. 更新本表与两份文档的 `last_reviewed` 元数据。
4. 运行 `Rscript dev/docs_check.R`。
5. 隐私、许可、引用、方法等高风险页面，发布前需领域审校。
