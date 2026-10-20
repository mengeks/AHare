# Usage: Rscript audit/compare_clean_results.R /path/to/clean/AHare
args <- commandArgs(trailingOnly=TRUE)
stopifnot(length(args)==1)
files <- list.files("results",pattern="[.]rds$",full.names=FALSE)
report <- lapply(files,function(name) {
  a <- readRDS(file.path("results",name))
  b <- readRDS(file.path(args[1],"results",name))
  stopifnot(identical(a$metadata$config_hash,b$metadata$config_hash))
  elapsed <- b$metadata$runtime_seconds
  a$metadata <- NULL; b$metadata <- NULL
  identical_results <- identical(a,b)
  if(!identical_results) stop(name,": independent replication differs: ",paste(all.equal(a,b),collapse="; "))
  data.frame(experiment=sub("[.]rds$","",name),identical_results=identical_results,
             clean_runtime_seconds=elapsed)
})
report <- do.call(rbind,report)
write.csv(report,"audit/clean_replication_results.csv",row.names=FALSE)
print(report)
cat("All seven result objects are exactly identical after excluding execution metadata.\n")
