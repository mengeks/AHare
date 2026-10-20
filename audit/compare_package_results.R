# Compare a full package-backed rerun to committed pre-switch results.
# Usage (from AHare/): Rscript audit/compare_package_results.R /path/to/rerun/AHare
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 1L)
numeric_error <- function(a, b) {
  if (is.numeric(a)) {
    stopifnot(identical(is.na(a), is.na(b)),
              identical(is.infinite(a), is.infinite(b)))
    finite <- is.finite(a)
    return(if (any(finite)) max(abs(a[finite] - b[finite])) else 0)
  }
  if (is.list(a)) return(max(c(0, unlist(Map(numeric_error, a, b), use.names = FALSE))))
  0
}
files <- list.files("results", pattern = "[.]rds$", full.names = FALSE)
report <- do.call(rbind, lapply(files, function(name) {
  old <- readRDS(file.path("results", name))
  new <- readRDS(file.path(args[1], "results", name))
  stopifnot(identical(old$metadata$config_hash, new$metadata$config_hash))
  runtime <- new$metadata$runtime_seconds
  old$metadata <- NULL
  new$metadata <- NULL
  comparison <- all.equal(old, new, tolerance = 1e-10, check.attributes = TRUE)
  if (!isTRUE(comparison)) stop(name, ": ", paste(comparison, collapse = "; "))
  err <- numeric_error(old, new)
  stopifnot(err < 1e-10)
  data.frame(experiment = sub("[.]rds$", "", name),
             exactly_identical = identical(old, new),
             max_absolute_error = err, runtime_seconds = runtime)
}))
tables <- file.path("output/tables", list.files("output/tables", pattern = "[.]tex$"))
inputs <- c(tables, "output/numbers.tex")
stopifnot(length(tables) == 11L)
for (path in inputs) {
  stopifnot(identical(readBin(path, "raw", n = file.info(path)$size),
                     readBin(file.path(args[1], path), "raw",
                             n = file.info(file.path(args[1], path))$size)))
}
write.csv(report, "audit/package_method_comparison.csv", row.names = FALSE)
print(report)
cat("All seven results agree within 1e-10; all 11 tables and numbers.tex are byte-identical.\n")
