#!/usr/bin/env Rscript
# Build renv.lock from the project-local .Rlib and the pinned upstream record.
# This is a deterministic helper for offline development; renv::snapshot() is
# preferred in a fully networked environment.

args <- commandArgs(trailingOnly = FALSE)
file_arg <- sub("^--file=", "", args[grepl("^--file=", args)])
root <- if (length(file_arg)) dirname(dirname(normalizePath(file_arg))) else normalizePath(".")
lib <- file.path(root, ".Rlib")
if (!dir.exists(lib)) {
  stop("Project library .Rlib does not exist.", call. = FALSE)
}

base_pkgs <- rownames(installed.packages(priority = "base"))
ip <- installed.packages(lib.loc = lib)
records <- list()

parse_requirements <- function(desc) {
  fields <- c("Depends", "Imports", "LinkingTo")
  values <- unlist(lapply(fields, function(field) {
    if (is.null(desc[[field]])) return(character())
    strsplit(desc[[field]], ",", fixed = TRUE)[[1]]
  }))
  values <- trimws(values)
  values <- sub("\\s*\\(.*$", "", values)
  values <- values[nzchar(values) & values != "R"]
  values <- setdiff(values, base_pkgs)
  sort(unique(values))
}

for (pkg in ip[, "Package"]) {
  desc <- packageDescription(pkg, lib.loc = lib)
  record <- list(
    Package = pkg,
    Version = desc$Version,
    Source = "Repository",
    Repository = "CRAN",
    Requirements = I(parse_requirements(desc))
  )
  records[[pkg]] <- record
}

records[["mcmc3r"]] <- list(
  Package = "mcmc3r",
  Version = "0.6.0",
  Source = "GitHub",
  RemoteType = "github",
  RemoteHost = "api.github.com",
  RemoteUsername = "dosreislab",
  RemoteRepo = "mcmc3r",
  RemoteRef = "f6a8f78bc55a53b724118480b6fbfbc71d3b0897",
  RemoteSha = "f6a8f78bc55a53b724118480b6fbfbc71d3b0897",
  Requirements = I(c("ape", "corpcor", "coda"))
)

records <- records[sort(names(records))]
lock <- list(
  R = list(
    Version = paste(R.version$major, R.version$minor, sep = "."),
    Repositories = list(list(Name = "CRAN",
                             URL = "https://cloud.r-project.org"))
  ),
  Packages = records
)

json <- jsonlite::toJSON(lock, auto_unbox = TRUE, pretty = TRUE,
                         null = "null", digits = NA)
writeLines(json, file.path(root, "renv.lock"), useBytes = TRUE)
cat("Wrote renv.lock with", length(records), "packages\n")
