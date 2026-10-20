#!/usr/bin/env Rscript
started <- Sys.time()
args <- commandArgs(trailingOnly = TRUE)
if ("--help" %in% args) {
  cat("Usage: Rscript run_all.R [--install-deps] [--force] [--only NAME]\n",
      "       Rscript run_all.R --check-deps\n", sep = "")
  quit(status = 0)
}
valid <- c("--install-deps", "--check-deps", "--force", "--only")
only <- NULL
if ("--only" %in% args) {
  i <- match("--only", args)
  if (i == length(args) || startsWith(args[[i + 1L]], "--"))
    stop("--only requires an experiment name")
  only <- args[[i + 1L]]
  valid <- c(valid, only)
}
if (any(!args %in% valid)) stop("Unknown argument: ", paste(args[!args %in% valid], collapse = ", "))
if (dir.exists(".library")) .libPaths(c(normalizePath(".library"), .libPaths()))
required <- c(yaml = "2.3.10", digest = "0.6.37", survival = "3.8.3",
              survRM2 = "1.0.4", survAH = "1.2.0", Matrix = "1.7.3",
              lattice = "0.22.7")
installed_version <- function(p) {
  tryCatch(as.character(packageVersion(p)), error = function(e) NA_character_)
}
versions <- vapply(names(required), installed_version, character(1))
needs_restore <- any(is.na(versions) | versions != required)
if (needs_restore && "--install-deps" %in% args) {
  local_library <- file.path(getwd(), ".library")
  dir.create(local_library, showWarnings = FALSE)
  .libPaths(c(local_library, .libPaths()))
  options(repos = c(CRAN = "https://cloud.r-project.org"))
  if (!requireNamespace("renv", quietly = TRUE))
    install.packages("renv", lib = local_library)
  renv::restore(project = getwd(), library = local_library,
                lockfile = "renv.lock", prompt = FALSE)
  versions <- vapply(names(required), installed_version, character(1))
  needs_restore <- any(is.na(versions) | versions != required)
}
if ("--check-deps" %in% args || needs_restore) {
  print(data.frame(package = names(required), expected = unname(required),
                   installed = unname(versions)))
}
if (needs_restore)
  stop("Package versions do not match renv.lock. Run Rscript run_all.R --install-deps.")
if ("--check-deps" %in% args) {
  message("All required package versions match renv.lock.")
  quit(status = 0)
}
source("R/utils_pipeline.R")
force <- "--force" %in% args

cfg <- read_pipeline_config()
experiments <- c("checkmate_observed", "main_ph", "main_nonph", "checkmate_sim",
                 "appendix_hr082", "appendix_tau10", "appendix_crossing")
if (!is.null(only)) {
  if (!only %in% experiments) stop("Unknown experiment: ", only)
  experiments <- only
}

for (name in experiments) {
  path <- file.path("results", paste0(name, ".rds"))
  if (!force && result_is_current(path, cfg)) {
    message("Current result exists; skipping ", name)
    next
  }
  source(file.path("experiments", paste0(name, ".R")))
  get(paste0("run_experiment_", name))(cfg)
}

all_results <- file.path("results", paste0(c("checkmate_observed", "main_ph",
  "main_nonph", "checkmate_sim", "appendix_hr082", "appendix_tau10",
  "appendix_crossing"), ".rds"))
if (all(vapply(all_results, result_is_current, logical(1), cfg = cfg))) {
  source("make_tables.R")
  source("make_figures.R")
  source("make_summary_figures.R")
  source("make_numbers.R")
  source("tests/test_package_methods.R")
  source("tests/test_consistency.R")
  writeLines(trimws(capture.output(sessionInfo()), which = "right"), "output/sessionInfo.txt")
} else {
  message("Partial run complete; run all experiments to build outputs from a single current config.")
}
dir.create("output", showWarnings = FALSE)
writeLines(c(paste0("Arguments:", if (length(args)) paste0(" ", paste(args, collapse = " ")) else ""),
             paste("Finished:", format(Sys.time(), tz = "UTC", usetz = TRUE)),
             sprintf("Total elapsed seconds: %.3f", as.numeric(difftime(Sys.time(), started, units = "secs"))),
             paste("Configured parallel processes:", cfg$project$workers),
             paste("R:", R.version.string)), "output/replication_runtime.txt")
