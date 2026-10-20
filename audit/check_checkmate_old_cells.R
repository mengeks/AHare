# Read-only historical calculations; writes audit evidence, not paper inputs.
# Run from AHare/: Rscript audit/check_checkmate_old_cells.R
if (dir.exists(".library")) .libPaths(c(normalizePath(".library"), .libPaths()))
old_pdf <- read.csv("audit/old27_table_cells.csv")
tab5 <- read.csv("output/checkmate057/paper/table-cm057-are-ere.csv")
tab7 <- read.csv("output/checkmate057/paper/table-cm057-sens-are.csv")
ratios <- c("drmst_cox", "rah_cox", "rah_drmst")
legacy_ratios <- c("rmst_cox", "rah_cox", "rah_rmst")
settings <- c("tau=18", "tau=21", "tau=24", "dropout=0.001",
              "dropout=0.005", "dropout=0.020", "nonph", "ph")
out <- list()
add <- function(table, setting, metric, legacy) {
  pdf <- old_pdf$old[old_pdf$table == table & old_pdf$setting == setting &
                      old_pdf$metric == metric]
  stopifnot(length(pdf) == 1L)
  out[[length(out) + 1L]] <<- data.frame(table = table, setting = setting,
    metric = metric, old_pdf = pdf, preserved_output = legacy,
    matches_pdf = round(legacy, 3) == pdf)
}
for (j in seq_along(ratios)) {
  add(5, "baseline", paste0("are_", ratios[j]), tab5$ARE[j])
  add(5, "baseline", paste0("ere_", ratios[j]), tab5$ERE[j])
}
for (i in seq_along(settings)) for (j in seq_along(ratios)) {
  add(7, settings[i], paste0("are_", ratios[j]),
      tab7[[paste0("are_", legacy_ratios[j])]][i])
  add(7, settings[i], paste0("ere_", ratios[j]),
      tab7[[paste0("ere_", legacy_ratios[j])]][i])
}
out <- do.call(rbind, out)
stopifnot(sum(!out$matches_pdf) == 6L,
          all(grepl("^are_", out$metric[!out$matches_pdf])),
          all(out$matches_pdf[out$table == 7 & out$setting != "tau=24"]))

# Execute only the old script's theory prefix, never its MC or output writers.
expressions <- parse("scripts/checkmate057/table-cm057-are-ere.R")
env <- new.env(parent = globalenv())
for (expr in expressions) {
  if (is.call(expr) && identical(expr[[1]], as.name("<-")) &&
      identical(expr[[2]], as.name(".eff"))) break
  eval(expr, envir = env)
}
error <- max(abs(unname(env$are) - tab5$ARE))
stopifnot(error < 1e-12)
write.csv(out, "audit/checkmate_old_cell_provenance.csv", row.names = FALSE)
cat("Old theory replay maximum error:", format(error), "\n")
print(aggregate(matches_pdf ~ table, out, sum))
print(out[!out$matches_pdf, ], row.names = FALSE)
