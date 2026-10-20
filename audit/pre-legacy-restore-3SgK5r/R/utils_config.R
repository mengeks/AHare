suppressPackageStartupMessages({
  library(yaml)
  library(digest)
})

read_pipeline_config <- function(path = "config.yaml") {
  cfg <- yaml::read_yaml(path)
  stopifnot(cfg$simulation$tau == cfg$simulation$cox_tau)
  stopifnot(cfg$checkmate057$tau == cfg$checkmate057$cox_tau)
  stopifnot(cfg$appendix_tau10$tau == cfg$appendix_tau10$cox_tau)
  cfg
}

config_hash <- function(cfg) digest::digest(cfg, algo = "sha256")

scenario_seed <- function(cfg, id) {
  h <- digest::digest(id, algo = "xxhash32", serialize = FALSE)
  offset <- strtoi(substr(h, 1, 7), base = 16L)
  as.integer((as.double(cfg$project$base_seed) + offset) %% .Machine$integer.max)
}

git_hash <- function() {
  x <- tryCatch(system2("git", c("rev-parse", "--short", "HEAD"), stdout = TRUE),
                error = function(e) NA_character_)
  if (!length(x)) NA_character_ else x[[1]]
}

result_metadata <- function(cfg, experiment, seed, started_at) {
  list(
    experiment = experiment,
    config = cfg,
    config_hash = config_hash(cfg),
    seed = seed,
    git_hash = git_hash(),
    date = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"),
    runtime_seconds = unname(as.numeric(difftime(Sys.time(), started_at,
                                                 units = "secs")))
  )
}

result_is_current <- function(path, cfg) {
  if (!file.exists(path)) return(FALSE)
  x <- tryCatch(readRDS(path), error = function(e) NULL)
  !is.null(x$metadata$config_hash) &&
    identical(x$metadata$config_hash, config_hash(cfg))
}

