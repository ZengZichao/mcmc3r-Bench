#!/usr/bin/env Rscript
# Deploy to Posit Connect Cloud. Runs the release consistency check first.
#
# Interactive setup (once per machine):
#   rsconnect::connectCloudUser()
#
# Non-interactive setup (CI):
#   CONNECT_CLOUD_CLIENT_ID / CONNECT_CLOUD_CLIENT_SECRET / CONNECT_CLOUD_ACCOUNT
#
# Optional:
#   CONNECT_CLOUD_ACCOUNT_NAME  local rsconnect nickname (default: connect-cloud)
#   MCMC3R_APP_VISIBILITY       public (default), private, view_team_edit_private,
#                               view_team_edit_team, view_public_edit_team

args <- commandArgs(trailingOnly = FALSE)
file_arg <- sub("^--file=", "", args[grepl("^--file=", args)])
root <- if (length(file_arg)) dirname(dirname(normalizePath(file_arg))) else normalizePath(".")

status <- system2("Rscript", file.path(root, "dev", "check_release.R"))
if (!identical(status, 0L)) {
  stop("Release consistency check failed; aborting deployment.", call. = FALSE)
}

if (!requireNamespace("rsconnect", quietly = TRUE)) {
  stop("rsconnect is not installed. Install it with install.packages('rsconnect').",
       call. = FALSE)
}

client_id <- Sys.getenv("CONNECT_CLOUD_CLIENT_ID", "")
client_secret <- Sys.getenv("CONNECT_CLOUD_CLIENT_SECRET", "")
remote_account <- Sys.getenv("CONNECT_CLOUD_ACCOUNT", "")
local_name <- Sys.getenv("CONNECT_CLOUD_ACCOUNT_NAME", "connect-cloud")
visibility <- Sys.getenv("MCMC3R_APP_VISIBILITY", "public")
app_name <- Sys.getenv("MCMC3R_APP_NAME", "mcmc3r-bench")
valid_visibility <- c(
  "public", "private", "view_team_edit_private", "view_team_edit_team",
  "view_public_edit_team"
)
if (!visibility %in% valid_visibility) {
  stop("MCMC3R_APP_VISIBILITY must be one of: ",
       paste(valid_visibility, collapse = ", "), call. = FALSE)
}

if (nzchar(client_id) && nzchar(client_secret)) {
  if (!nzchar(remote_account)) {
    stop("CONNECT_CLOUD_ACCOUNT must be set with client credentials.",
         call. = FALSE)
  }
  rsconnect::connectCloudClientCredentials(
    clientId = client_id,
    clientSecret = client_secret,
    accountName = remote_account,
    name = local_name,
    quiet = TRUE
  )
  account <- local_name
} else {
  configured <- rsconnect::accounts()
  configured <- configured[
    configured$server == "connect.posit.cloud", , drop = FALSE
  ]
  if (nzchar(remote_account) && remote_account %in% configured$name) {
    account <- remote_account
  } else if (nrow(configured) == 1L) {
    account <- configured$name[[1]]
  } else if (nrow(configured) == 0L) {
    stop(
      "No Posit Connect Cloud account is configured. Run ",
      "rsconnect::connectCloudUser() once, or set CONNECT_CLOUD_CLIENT_ID, ",
      "CONNECT_CLOUD_CLIENT_SECRET, and CONNECT_CLOUD_ACCOUNT.",
      call. = FALSE
    )
  } else {
    stop(
      "Multiple Connect Cloud accounts are configured. Set ",
      "CONNECT_CLOUD_ACCOUNT to the local account name to use.",
      call. = FALSE
    )
  }
}

# A previous deploy that could not find its local record created a second
# Connect content item under a near-identical name, and rsconnect then picks a
# record by name. Refuse to guess which one is canonical.
existing <- tryCatch(rsconnect::deployments(root), error = function(e) NULL)
if (is.data.frame(existing) && nrow(existing) > 1L) {
  stop("Multiple deployment records exist for this directory (",
       paste(existing$name, collapse = ", "), "). rsconnect would pick one ",
       "by name and may publish to the wrong content. Delete the stale ",
       "record under rsconnect/ so only the intended app remains.",
       call. = FALSE)
}

message("Deploying ", app_name, " to Posit Connect Cloud as account '",
        account, "'...")
root_files <- c(
  "app.R", "global.R", "VERSION", "renv.lock",
  "LICENSE", "NOTICE", "CITATION.cff", "THIRD_PARTY_LICENSES.md"
)
deploy_files <- c(
  root_files,
  file.path("R", list.files(file.path(root, "R"))),
  file.path("i18n", list.files(file.path(root, "i18n"))),
  file.path("www", list.files(file.path(root, "www"), recursive = TRUE))
)
deploy_files <- deploy_files[file.exists(file.path(root, deploy_files))]
message("Bundling ", length(deploy_files), " runtime files.")

# Build a manifest that contains only the runtime dependency closure. The
# project renv.lock also records test and development packages; shipping those
# to Connect Cloud would slow the build and can pull optional system libraries.
lockfile <- jsonlite::fromJSON(file.path(root, "renv.lock"),
                             simplifyVector = FALSE)
manifest_path <- file.path(root, "manifest.json")
# Resolve from the installed library rather than renv.lock. The lockfile pins
# lattice and nlme at the versions of the R that produced it, which differ from
# the R bundled recommended packages here; rsconnect treats any such drift as a
# hard error even though neither package ships with the app. The version guard
# below re-checks every package that is actually bundled against renv.lock, so
# this cannot quietly publish unpinned versions.
rsconnect::writeManifest(root, appFiles = deploy_files,
                         dependencyResolution = "library", quiet = TRUE)
manifest <- jsonlite::fromJSON(manifest_path, simplifyVector = FALSE)

runtime_files <- c("app.R", "global.R",
                   list.files(file.path(root, "R"), pattern = "[.]R$",
                              full.names = TRUE))
deps <- renv::dependencies(runtime_files, root = root, progress = FALSE)
base_pkgs <- rownames(installed.packages(priority = "base"))
recommended <- rownames(installed.packages(priority = "recommended"))
skip <- unique(c(base_pkgs, recommended, "R"))

closure <- character()
queue <- setdiff(unique(deps$Package), skip)
while (length(queue)) {
  pkg <- queue[[1]]
  queue <- queue[-1]
  if (pkg %in% closure || pkg %in% skip) next
  desc <- suppressWarnings(packageDescription(pkg))
  if (is.null(desc)) {
    stop("Runtime package not installed: ", pkg, call. = FALSE)
  }
  closure <- c(closure, pkg)
  fields <- unlist(lapply(desc[c("Depends", "Imports", "LinkingTo")],
                          as.character))
  fields <- fields[!is.na(fields)]
  children <- unlist(strsplit(fields, ","))
  children <- trimws(sub("[[:space:]]*[(].*[)]", "", children))
  queue <- c(queue, setdiff(children[nzchar(children)], c(closure, skip)))
}

manifest_names <- vapply(
  manifest$packages,
  function(p) p$description$Package,
  character(1)
)
missing <- setdiff(closure, manifest_names)
if (length(missing)) {
  stop("Runtime packages missing from manifest: ",
       paste(missing, collapse = ", "), call. = FALSE)
}
manifest$packages <- manifest$packages[manifest_names %in% closure]
# Every package that actually ships must match the version pinned in renv.lock.
# Runs after pruning so packages outside the runtime closure cannot block a
# deployment they are not part of.
pinned <- vapply(lockfile$Packages, function(p) p$Version, character(1))
drifted <- character(0)
for (pkg in manifest$packages) {
  name <- pkg$description$Package
  got <- pkg$description$Version
  if (!is.na(pinned[[name]]) && !identical(got, pinned[[name]])) {
    drifted <- c(drifted, paste0(name, ": manifest ", got,
                                 " vs lockfile ", pinned[[name]]))
  }
}
if (length(drifted)) {
  stop("bundled packages disagree with renv.lock:\n  ",
       paste(drifted, collapse = "\n  "),
       "\nReconcile with renv::restore() before deploying.", call. = FALSE)
}

jsonlite::write_json(manifest, manifest_path, auto_unbox = TRUE,
                     pretty = TRUE, null = "null", digits = NA)

success <- FALSE
on.exit({
  if (success) unlink(manifest_path)
}, add = TRUE)

rsconnect::deployApp(
  appDir = root,
  manifestPath = manifest_path,
  appName = app_name,
  appTitle = "mcmc3r Bench",
  account = account,
  appVisibility = visibility,
  forceUpdate = TRUE,
  launch.browser = FALSE
)
success <- TRUE

record <- tryCatch(rsconnect::deployments(appDir = root), error = function(e) NULL)
if (is.data.frame(record) && nrow(record) && "url" %in% names(record)) {
  message("Content URL: ", record$url[[1]])
}
