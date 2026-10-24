# Security policy

## Supported versions

Only the current `0.1.x` line receives security fixes. Older development
snapshots are unsupported.

## Reporting a vulnerability

Please report vulnerabilities privately:

- Use GitHub's private vulnerability reporting for this repository, or
- Email `zengzichao@sjtu.edu.cn`.

Include the affected version, module, a minimal reproduction, and the impact.
Do not include confidential data or public exploit details. We aim to
acknowledge reports within a reasonable time; this is a best-effort project with
no SLA.

## Scope

In scope:

- Path traversal, ZIP bombs, or unsafe extraction.
- Formula injection in CSV exports.
- Script injection through user-controlled names or errors.
- Denial of service through oversized or malicious inputs.
- Exposure of uploaded data in logs, diagnostics, or responses.
- Dependency or deployment credential issues.

Out of scope:

- Vulnerabilities in Posit Connect Cloud or upstream R packages (report upstream).
- Findings that require modifying the user's browser or operating system.
- Social engineering or physical access.

## Security design

- Uploads are limited by extension, size, row count, and ZIP structure.
- ZIP entries are validated and copied only to sanitised destinations; absolute
  paths, `..` components, encrypted entries, and unusual compression ratios are
  rejected.
- No uploaded code is executed; no `source()`, `eval(parse())`, or arbitrary R
  evaluation.
- CSV exports escape formula-leading strings.
- HTML outputs use Shiny escaping; user input is not inserted as raw HTML.
- Logs contain event names, codes, counts, timings, versions, and a short
  session token; they do not contain file contents or full paths.
- Dependencies are pinned with `renv`; secrets are provided through environment
  variables or GitHub Secrets and are never committed.

## Public hosting note

The Connect Cloud Free plan serves public content. Anyone with the link can use
it. The app displays a public-data warning and does not provide authentication.
For private data, run the source locally.
