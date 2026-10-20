# Read the completed restored shared results; preserve private historical results.
shared <- "/Users/xmeng/Partners HealthCare Dropbox/Xiang Meng/Apps/Overleaf/Efficient and Debiased Learning of Average Hazard Under Non-Proportional Hazards (1)/AHare"
private <- "/Users/xmeng/Partners HealthCare Dropbox/Xiang Meng/Apps/Overleaf/AH-ARE/AHare"
setwd(shared)
if (dir.exists(".library")) .libPaths(c(normalizePath(".library"), .libPaths()))
source("R/utils_pipeline.R")
cfg <- read_pipeline_config()
legacy <- new.env(parent = globalenv())
sys.source(file.path(private, "R/dgp-tian2017.R"), envir = legacy)
sys.source(file.path(private, "R/main-sim-paper-helpers.R"), envir = legacy)
records <- list()
compare <- function(experiment, row, fn, legacy_cox_tau) {
  legacy$TAU <- row$tau
  legacy$TAU_H <- legacy_cox_tau
  old <- unlist(legacy$compute_are_triple(row$shape, row$scale0, fn,
    row$lambda_c, cfg$simulation$censoring_uniform[[1]],
    cfg$simulation$censoring_uniform[[2]]))
  legacy$TAU_H <- row$tau
  paired <- unlist(legacy$compute_are_triple(row$shape, row$scale0, fn,
    row$lambda_c, cfg$simulation$censoring_uniform[[1]],
    cfg$simulation$censoring_uniform[[2]]))
  current <- as.numeric(row[c("are_drmst_cox", "are_rah_cox", "are_rah_drmst")])
  stopifnot(max(abs(paired-current)) < 1e-12,
            abs(old[[3]]-current[[3]]) < 1e-12)
  records[[length(records)+1L]] <<- data.frame(experiment=experiment,id=row$id,
    max_same_design_error=max(abs(paired-current)),
    legacy_same_design_rah_drmst=old[[3]],restored_rah_drmst=current[[3]])
}
for (experiment in c("main_ph", "appendix_hr082", "appendix_tau10")) {
  rows <- readRDS(file.path("results", paste0(experiment,".rds")))$scenarios
  for (i in seq_len(nrow(rows))) {
    row <- rows[i,]
    legacy$TAU_L <- if(experiment=="appendix_tau10") 8 else 24
    legacy$TAU_U <- if(experiment=="appendix_tau10") 12 else 43
    old_range <- cfg$simulation$censoring_uniform
    if(experiment=="appendix_tau10") cfg$simulation$censoring_uniform <- c(8,12)
    compare(experiment,row,alpha_ph(row$hr),if(experiment=="appendix_tau10") 11 else 42.5)
    cfg$simulation$censoring_uniform <- old_range
  }
}
rows <- readRDS("results/main_nonph.rds")$scenarios
for (i in seq_len(nrow(rows))) {
  row <- rows[i,]
  legacy$TAU <- row$tau
  fn <- if(row$case=="fading") legacy$make_alpha_case2(1,t_m=43) else
    legacy$make_alpha_case3(1)
  compare("main_nonph",row,fn,42.5)
}
cm <- readRDS("results/checkmate_sim.rds")
old7 <- read.csv(file.path(private,"output/checkmate057/paper/table-cm057-sens-are.csv"))
for(i in seq_len(nrow(cm$sensitivity_views))) {
  row <- cm$sensitivity[cm$sensitivity$id==cm$sensitivity_views$id[i],]
  stopifnot(abs(row$are_rah_drmst-old7$are_rah_rmst[i])<1e-12)
  records[[length(records)+1L]] <- data.frame(experiment="checkmate_sim",id=row$id,
    max_same_design_error=abs(row$are_rah_drmst-old7$are_rah_rmst[i]),
    legacy_same_design_rah_drmst=old7$are_rah_rmst[i],restored_rah_drmst=row$are_rah_drmst)
}
out <- do.call(rbind,records)
write.csv(out,file.path(private,"audit/restored_theory_equivalence.csv"),row.names=FALSE)
cat(nrow(out),"legacy/current theoretical comparisons passed; max error",
    max(out$max_same_design_error),"\n")
