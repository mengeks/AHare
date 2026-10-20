# Audit only: no changes to results/, paper inputs, or shared checkout.
# Run from AHare/: Rscript audit/decompose_checkmate_changes.R
if (dir.exists(".library")) .libPaths(c(normalizePath(".library"), .libPaths()))
source("R/utils_pipeline.R")
source("scripts/checkmate057/checkmate057-common.R")
cfg <- read_pipeline_config()
saved <- readRDS("results/checkmate_sim.rds")
pdf <- read.csv("audit/old27_table_cells.csv")
legacy5 <- read.csv("output/checkmate057/paper/table-cm057-are-ere.csv")
legacy7 <- read.csv("output/checkmate057/paper/table-cm057-sens-are.csv")
wb <- cm057_weibull_params()
obs <- readRDS("results/checkmate_observed.rds")
stopifnot(max(abs(c(wb$shape0, wb$scale0, wb$shape1, wb$scale1) -
                    c(obs$weibull$control, obs$weibull$treatment))) < 1e-10)
scenarios <- data.frame(
  table=c(5, rep(7, 8)),
  setting=c("baseline", "tau=18", "tau=21", "tau=24", "dropout=0.001",
            "dropout=0.005", "dropout=0.020", "nonph", "ph"),
  tau=c(24,18,21,24,24,24,24,24,24),
  lc=c(.005,.005,.005,.005,.001,.005,.020,.005,.005),
  id=c("cm_nonph_tau_24_lc_005", "cm_nonph_tau_18_lc_005",
       "cm_nonph_tau_21_lc_005", "cm_nonph_tau_24_lc_005",
       "cm_nonph_tau_24_lc_001", "cm_nonph_tau_24_lc_005",
       "cm_nonph_tau_24_lc_020", "cm_nonph_tau_24_lc_005",
       "cm_ph_tau_24_lc_005"), stringsAsFactors=FALSE)
ratios <- c("drmst_cox", "rah_cox", "rah_drmst")
legacy_ratios <- c("rmst_cox", "rah_cox", "rah_rmst")
ere <- function(m) {
  e <- apply(m, 2, efficacy)
  c(drmst_cox=e[2]/e[1], rah_cox=e[3]/e[1], rah_drmst=e[3]/e[2])
}
boot_se <- function(m, seed) {
  set.seed(seed)
  b <- replicate(4000L, ere(m[sample.int(nrow(m), replace=TRUE),,drop=FALSE]))
  apply(b, 1, sd)
}
theory <- function(s, step, cox_tau) {
  af <- if(s$setting=="ph") alpha_ph(.75) else
    weibull_alpha(wb$shape0,wb$scale0,wb$shape1,wb$scale1)
  a <- theory_result(wb$shape0,wb$scale0,af,s$tau,s$lc,c(6,30),step)
  cox <- theory_result(wb$shape0,wb$scale0,af,cox_tau,s$lc,c(6,30),step)
  c(drmst_cox=a$efficiency[["RMST"]]/cox$efficiency[["Cox"]],
    rah_cox=a$efficiency[["AHSW"]]/cox$efficiency[["Cox"]],
    rah_drmst=a$efficiency[["AHSW"]]/a$efficiency[["RMST"]])
}
make_gen <- function(s) {
  shape1 <- if(s$setting=="ph") wb$shape0 else wb$shape1
  scale1 <- if(s$setting=="ph") wb$scale0/.75^(1/wb$shape0) else wb$scale1
  function() cm057_gen(300L,300L,wb,shape1=shape1,scale1=scale1,lambda_c=s$lc)
}
replay <- list()
new_batches <- list()
checkpoint <- "audit/checkmate_decomposition_raw.rds"
summarize_only <- "--summarize-only" %in% commandArgs(trailingOnly=TRUE)
if (summarize_only) {
  raw <- readRDS(checkpoint)
  stopifnot(identical(raw$scenarios,scenarios),identical(raw$config,cfg))
  replay <- raw$old_batches
  new_batches <- raw$new_batches
} else {
set.seed(2024)
for(i in seq_len(nrow(scenarios))) {
  s <- scenarios[i,]
  if(i==2L) set.seed(2024) # sensitivity script starts its own sequential stream
  message("Replaying old batch: Table ",s$table," ",s$setting)
  gen <- make_gen(s)
  stats <- t(replicate(500L, {
    d <- gen()
    old <- c(cm057_stat_cox(d),cm057_stat_rmst(d,s$tau),cm057_stat_rah(d,s$tau))
    new <- test_statistics(d,s$tau)
    c(old,new)
  }))
  replay[[i]] <- stats
}
for(id in unique(scenarios$id)) {
  s <- scenarios[match(id,scenarios$id),]
  message("Replaying new batch: ",id)
  gen <- make_gen(s)
  seed <- scenario_seed(cfg,id)
  new_batches[[id]] <- do.call(rbind,parallel::mclapply(seq_len(500L),function(i) {
    set.seed(seed+i-1L)
    test_statistics(gen(),s$tau)
  },mc.cores=4L,mc.preschedule=TRUE))
}
saveRDS(list(old_batches=replay,new_batches=new_batches,scenarios=scenarios,
             config=cfg),checkpoint)
}
# Recover the one old unsupported RMST sample without statistical reruns.
set.seed(2024)
for(i in 2:7) {
  gen <- make_gen(scenarios[i,])
  for(b in seq_len(if(i==7L) 100L else 500L)) support_dat <- gen()
}
support_error <- tryCatch({
  survRM2::rmst2(support_dat$time,support_dat$status,support_dat$arm,tau=24)
  ""
},error=function(e) conditionMessage(e))
support_stats <- test_statistics(support_dat,24)
stopifnot(nzchar(support_error),
          max(abs(support_stats-replay[[7]][100,4:6]))<1e-10)
write.csv(data.frame(table=7,setting="dropout=0.020",old_replication=100,
                    tau=24,max_time_arm0=max(support_dat$time[support_dat$arm==0]),
                    max_time_arm1=max(support_dat$time[support_dat$arm==1]),
                    old_rmst_error=support_error,new_drmst=support_stats[[2]]),
          "audit/checkmate_rmst_support_exception.csv",row.names=FALSE)
out <- list()
diagnostics <- list()
for(i in seq_len(nrow(scenarios))) {
  s <- scenarios[i,]
  m <- replay[[i]]
  old <- m[,1:3,drop=FALSE]
  paired <- m[,4:6,drop=FALSE]
  new <- new_batches[[s$id]]
  se_old <- boot_se(paired,87000L+i)
  se_new <- boot_se(new,88000L+match(s$id,unique(scenarios$id)))
  cox_only <- old
  cox_only[,1] <- paired[,1]
  er0 <- ere(old); er1 <- ere(cox_only)
  er_policy <- ere(paired); er2 <- ere(new)
  ar0 <- theory(s,.05,26); ar1 <- theory(s,.05,s$tau); ar2 <- theory(s,.01,s$tau)
  legacy_er <- if(i==1) legacy5$ERE else
    as.numeric(legacy7[i-1,paste0("ere_",legacy_ratios)])
  legacy_ar <- if(i==1) legacy5$ARE else
    as.numeric(legacy7[i-1,paste0("are_",legacy_ratios)])
  current <- saved$sensitivity[saved$sensitivity$id==s$id,]
  stopifnot(max(abs(er0-legacy_er))<1e-10,
            max(abs(ar0-legacy_ar))<1e-10,
            max(abs(er2-as.numeric(current[paste0("ere_",ratios)])))<1e-10,
            max(abs(ar2-as.numeric(current[paste0("are_",ratios)])))<1e-10)
  same_finite <- identical(unname(is.finite(old[,2:3])),
                           unname(is.finite(paired[,2:3])))
  max_contrast <- max(abs(old[,2:3]-paired[,2:3]),na.rm=TRUE)
  diagnostics[[i]] <- data.frame(table=s$table,setting=s$setting,
    old_valid_cox=sum(is.finite(old[,1])),old_valid_drmst=sum(is.finite(old[,2])),
    old_valid_rah=sum(is.finite(old[,3])),new_valid_cox=sum(is.finite(new[,1])),
    new_valid_drmst=sum(is.finite(new[,2])),new_valid_rah=sum(is.finite(new[,3])),
    paired_dr_finite_masks_equal=same_finite,paired_dr_max_abs_error=max_contrast)
  stopifnot(max_contrast<1e-10)
  if (!same_finite) {
    stopifnot(s$setting=="dropout=0.020",
              sum(!is.finite(old[,2]))==1L,all(is.finite(paired)),
              all(is.finite(old[,c(1,3)])))
  }
  for(metric in c("are","ere")) for(j in seq_along(ratios)) {
    name <- paste0(metric,"_",ratios[j])
    old_pdf <- pdf$old[pdf$table==s$table & pdf$setting==s$setting & pdf$metric==name]
    v <- if(metric=="are") c(ar0[j],ar1[j],ar2[j]) else c(er0[j],er1[j],er2[j])
    combined <- if(metric=="ere") sqrt(se_old[j]^2+se_new[j]^2) else NA_real_
    residual <- if(metric=="ere") er2[j]-er_policy[j] else NA_real_
    out[[length(out)+1L]] <- data.frame(table=s$table,setting=s$setting,
      metric=name,old_pdf=old_pdf,legacy_replay=v[1],after_cox_horizon=v[2],
      current=v[3],total_delta=v[3]-old_pdf,
      old_pdf_to_legacy=v[1]-old_pdf,cox_horizon_delta=v[2]-v[1],
      grid_delta=if(metric=="are") v[3]-v[2] else NA_real_,
      after_point_policy=if(metric=="ere") er_policy[j] else NA_real_,
      point_policy_delta=if(metric=="ere") er_policy[j]-er1[j] else NA_real_,
      seed_batch_delta=residual,combined_mc_se=combined,
      seed_batch_z=if(metric=="ere") residual/combined else NA_real_,
      seed_within_95pct=if(metric=="ere") abs(residual)<=1.96*combined else NA,
      historical_pdf_matches=abs(v[1]-old_pdf)<.0005001,
      old_seed=2024L,new_seed=scenario_seed(cfg,s$id))
  }
}
  out <- do.call(rbind,out)
diagnostics <- do.call(rbind,diagnostics)
write.csv(out,"audit/checkmate_change_decomposition.csv",row.names=FALSE)
write.csv(diagnostics,"audit/checkmate_replay_diagnostics.csv",row.names=FALSE)
saveRDS(list(old_batches=replay,new_batches=new_batches,scenarios=scenarios,
             decomposition=out,diagnostics=diagnostics),
        "audit/checkmate_change_decomposition.rds")
print(out[,c("table","setting","metric","old_pdf","after_cox_horizon",
             "current","cox_horizon_delta","grid_delta","seed_batch_delta",
             "seed_batch_z","seed_within_95pct")],row.names=FALSE)
print(diagnostics,row.names=FALSE)
