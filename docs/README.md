# Documentation / 文档

mcmc3r Bench keeps a complete English tree and a complete Chinese tree.
Each file pair is listed below. Technical documents use English as the
canonical version; the Chinese versions are full mirrors.

本项目的文档分为完整的英文树与中文树。技术文档以英文为基准，中文为完整镜像。

**Language / 语言:** [English](en/) | [中文](zh/)

## User documentation / 用户文档

| Document | English | 中文 | Status |
|---|---|---|---|
| Quick start | [QUICKSTART.md](en/QUICKSTART.md) | [QUICKSTART.md](zh/QUICKSTART.md) | current |
| User guide | [USER_GUIDE.md](en/USER_GUIDE.md) | [USER_GUIDE.md](zh/USER_GUIDE.md) | current |
| File formats | [FILE_FORMATS.md](en/FILE_FORMATS.md) | [FILE_FORMATS.md](zh/FILE_FORMATS.md) | current |
| Methods | [METHODS.md](en/METHODS.md) | [METHODS.md](zh/METHODS.md) | current |
| FAQ | [FAQ.md](en/FAQ.md) | [FAQ.md](zh/FAQ.md) | current |
| Privacy | [PRIVACY.md](en/PRIVACY.md) | [PRIVACY.md](zh/PRIVACY.md) | current |

## Developer and operations documentation / 开发与运维文档

| Document | English | 中文 | Status |
|---|---|---|---|
| Architecture | [ARCHITECTURE.md](en/ARCHITECTURE.md) | [ARCHITECTURE.md](zh/ARCHITECTURE.md) | current |
| Deployment | [DEPLOYMENT.md](en/DEPLOYMENT.md) | [DEPLOYMENT.md](zh/DEPLOYMENT.md) | current |
| Testing | [TESTING.md](en/TESTING.md) | [TESTING.md](zh/TESTING.md) | current |
| i18n | [I18N.md](en/I18N.md) | [I18N.md](zh/I18N.md) | current |
| Theme | [THEME.md](en/THEME.md) | [THEME.md](zh/THEME.md) | current |

## Academic and legal documentation / 学术与合规文档

| Document | English | 中文 | Status |
|---|---|---|---|
| Citation | [CITATION.md](en/CITATION.md) | [CITATION.md](zh/CITATION.md) | current |
| Attribution | [ATTRIBUTION.md](en/ATTRIBUTION.md) | [ATTRIBUTION.md](zh/ATTRIBUTION.md) | current |
| Glossary | [GLOSSARY.md](GLOSSARY.md) | [GLOSSARY.md](GLOSSARY.md) | current |
| Translation status | [TRANSLATION_STATUS.md](TRANSLATION_STATUS.md) | [TRANSLATION_STATUS.md](TRANSLATION_STATUS.md) | current |
| Benchmarks | [benchmarks.md](benchmarks.md) | [benchmarks.md](benchmarks.md) | current |
| Documentation licence | [LICENSE](LICENSE) | [LICENSE](LICENSE) | current |

## Screenshots / 截图

The screenshot matrix covers two languages, two themes, and two viewports:

- `assets/screenshots/en-light/desktop.png`, `mobile.png`
- `assets/screenshots/en-dark/desktop.png`, `mobile.png`
- `assets/screenshots/zh-light/desktop.png`, `mobile.png`
- `assets/screenshots/zh-dark/desktop.png`, `mobile.png`

Screenshots are produced from the running application by
`dev/screenshots.R`. Alt text is provided in the English and Chinese READMEs.

## Canonical and mirror policy / 基准与镜像规则

- Code and UI strings: English source keys, Chinese translations.
- Technical documentation: English canonical, Chinese full mirror.
- Any pull request that changes one language must update its pair in the same
  change; `dev/docs_check.R` enforces file, metadata, link, and version parity.

- 代码与界面文案：英文为源 key，中文为翻译值。
- 技术文档：英文为基准，中文为完整镜像。
- 任何只改一种语言的提交，必须在同一提交中更新对应语言；`dev/docs_check.R`
  会检查文件、元数据、链接与版本的一致性。
