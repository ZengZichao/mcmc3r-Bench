# Privacy and data handling

| Field | Value |
|---|---|
| lang | en |
| pair | ../zh/PRIVACY.md |
| applies_to | 0.1.0 |
| doc_version | 1.0 |
| last_reviewed | 2026-10-24 |
| canonical | true |
| status | current |

**Language:** English | [中文](../zh/PRIVACY.md)

## Summary

The hosted app processes uploaded files only for the current session. Files are
kept in a temporary directory on the server and deleted when the session ends.
The app does not create accounts, sell data, or use uploaded data for analytics
or model training. It is a public app: anyone with the link can use it. Do not
upload confidential, personal, or regulated data. If your data are sensitive,
run the source locally.

## What is collected

- Uploaded files: copied to a session-specific temporary directory for
  validation and calculation.
- In-memory state: parsed tables, parameters, and results, held only for the
  lifetime of the Shiny session.
- Access logs: the hosting provider (Posit Connect Cloud) may record standard
  server logs such as IP address, timestamps, request paths, and error messages.

## What is not collected

- No account, email, name, or institution.
- No third-party analytics, advertising, or tracking scripts.
- No cookies for tracking; `localStorage` is used only for language and theme
  preferences and never sent to the server as personal data.
- No persistent database or cross-session cache.
- No uploaded file content in application logs. Logs contain event names, error
  codes, counts, timings, versions, and a short session token.

## Retention

- Temporary files: deleted when the Shiny session ends (`session$onSessionEnded`)
  or when the server process is recycled. A session may end by closing the tab,
  by an inactivity timeout imposed by the platform, or by a redeployment.
- Logs: retained by the hosting provider according to its policy.
- Repository: contains no user data.

## Security measures

- Uploads are limited by extension, size, row count, and ZIP structure.
- ZIP entries are validated and copied only to sanitised destinations; absolute
  paths, `..` components, encrypted entries, and unusual compression ratios are
  rejected.
- User text is escaped in CSV exports against formula injection and in HTML
  outputs against script injection.
- Dependencies are pinned with `renv`; workflows use least-privilege tokens.
- Diagnostics exclude file contents and full paths.

## International transfer

The hosted service runs on infrastructure operated by Posit (Connect Cloud),
which may be located outside your country. If you are subject to data export or
data-localisation rules, evaluate whether uploading data is permitted, or run
the application locally.

## Your responsibilities

- Do not upload confidential, personal, or regulated data to the public app.
- Do not upload data you are not authorised to process.
- Do not attempt to bypass limits, attack the service, or occupy the quota
  deliberately.
- Cite methods and the upstream package appropriately when publishing results.

## Changes

Material changes to this policy will be reflected in the application's Help page.
The date at the top of this document indicates the last review.

## Contact

Questions about privacy: `zengzichao@sjtu.edu.cn`.
