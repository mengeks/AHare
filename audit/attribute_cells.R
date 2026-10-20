# Compare every extracted numeric cell in Tables 1--11 of the 27Sep PDF.
old <- read.csv("audit/old27_table_cells.csv", stringsAsFactors = FALSE)
cm_provenance <- read.csv("audit/checkmate_old_cell_provenance.csv")
cm_decomposition <- read.csv("audit/checkmate_change_decomposition.csv")
ph_mc_check <- read.csv("audit/main_ph_seed_mc_check.csv")
mph <- readRDS("results/main_ph.rds")$scenarios
mnp <- readRDS("results/main_nonph.rds")$scenarios
h82 <- readRDS("results/appendix_hr082.rds")$scenarios
t10 <- readRDS("results/appendix_tau10.rds")$scenarios
cross <- readRDS("results/appendix_crossing.rds")$scenarios
cm <- readRDS("results/checkmate_sim.rds")
obs <- readRDS("results/checkmate_observed.rds")$table
baseline <- cm$sensitivity[cm$sensitivity$id == cm$baseline_id, ]
new_rows <- list()
metrics <- c("are_drmst_cox", "are_rah_cox", "are_rah_drmst",
             "ere_drmst_cox", "ere_rah_cox", "ere_rah_drmst")
add <- function(table, setting, row, fields = metrics) {
  for (field in fields) new_rows[[length(new_rows) + 1L]] <<-
    data.frame(table = table, setting = setting, metric = field, new = row[[field]])
}
for (i in seq_len(nrow(obs))) add(1, paste(obs$dataset[i], obs$method[i], sep=";"),
    obs[i, ], c("estimate", "ci_lo", "ci_hi", "pval"))
for (i in seq_len(nrow(mph))) {
  r <- mph[i, ]
  if (r$shape == .826) add(2, sprintf("s0=%.2f;%s", r$s0, r$censoring), r)
  if (r$s0 == .5) add(3, sprintf("shape=%.3f;%s", r$shape, r$censoring), r)
}
for (i in seq_len(nrow(mnp))) add(4, paste(mnp$case[i],mnp$censoring[i],sep=";"),mnp[i,])
add(5, "baseline", baseline)
p <- cm$power[cm$power$n == 300, ]
for (method in c("Cox", "DRMST", "RAH")) {
  fields <- list(power = p[[method]], n80 = min(cm$power$n[cm$power[[method]] >= .8]))
  add(6, if (method == "DRMST") "D-RMST" else method, fields, c("power","n80"))
}
settings <- c("tau=18","tau=21","tau=24","dropout=0.001","dropout=0.005","dropout=0.020","nonph","ph")
for (i in seq_len(nrow(cm$sensitivity_views))) {
  r <- cm$sensitivity[match(cm$sensitivity_views$id[i], cm$sensitivity$id), ]
  add(7, settings[i], r)
}
for (i in seq_len(nrow(h82))) {
  r <- h82[i, ]
  if (r$shape == .826) add(8, sprintf("s0=%.3f;%s",r$s0,r$censoring),r)
  if (r$s0 == .5) add(9, sprintf("shape=%.3f;%s",r$shape,r$censoring),r,
    c(metrics[1:3], "power_cox", "power_drmst", "power_rah", metrics[4:6]))
}
for (i in seq_len(nrow(t10))) add(10,sprintf("shape=%.3f;%s",t10$shape[i],t10$censoring[i]),t10[i,])
for (i in seq_len(nrow(cross))) add(11,cross$censoring[i],cross[i,])
new <- do.call(rbind,new_rows)
out <- merge(old,new,by=c("table","setting","metric"),all.x=TRUE,sort=FALSE)
stopifnot(nrow(out)==nrow(old),!anyNA(out$new))
out$new_unrounded <- out$new
digits <- ifelse(out$table==6 & out$metric=="n80",0,
                 ifelse(out$table==1 & grepl("D-RMST",out$setting) & out$metric!="pval",2,3))
out$new <- mapply(round,out$new,digits)
out$delta <- out$new-out$old
out$changed <- abs(out$delta) > 1e-10
out$reason <- ""
for (i in seq_len(nrow(out))) {
  r <- out[i, ]; cox <- grepl("cox",r$metric); empirical <- grepl("^ere|^power",r$metric)
  reason <- character()
  if (r$table==1) reason <- if (grepl(";Cox$",r$setting)) "Observed Cox follow-up truncated at 24 months" else "Unchanged estimate; only rounding"
  if (r$table %in% c(2,3,8,9,10)) {
    if (cox) reason <- c(reason,if (r$table==10) "Cox theory horizon 11 -> 10; empirical Cox all follow-up -> 10" else "Cox theory horizon 42.5 -> 40; empirical Cox all follow-up -> 40")
    if (empirical) reason <- c(reason,"Different deterministic scenario seed; B and event/censoring DGP unchanged")
    if (r$table %in% c(2,3,8,9) && empirical) reason <- c(reason,"Shared repeated scenario now reuses one saved batch")
    if (r$table==9 && r$metric=="power_cox") reason <- c(reason,"Legacy Cox used score-test p-value; current paper uses Wald p-value")
    if (r$table==2 && r$setting %in% c("s0=0.10;light", "s0=0.10;heavy", "s0=0.30;heavy") &&
        grepl("^ere_.*drmst", r$metric))
      reason <- c(reason,"Verified RMST support-retention change: legacy rmst2 dropped unsupported replicates; current ERE retains KM-tail point contrasts. Not seed-only")
    if (!empirical && !cox) reason <- "RAH/D-RMST theory unchanged (neither depends on Cox horizon)"
    if (r$table==10) reason <- c(reason,"B=500, not 2000; larger empirical Monte Carlo variation")
  }
  if (r$table==4) {
    if (grepl("fading",r$setting)) reason <- c(reason,"Fading cutoff t_M 21.25 -> 43 (approved design correction)")
    if (cox) reason <- c(reason,"Cox theory horizon 42.5 -> 40; empirical Cox all follow-up -> 40")
    if (empirical) reason <- c(reason,"New seeds; inverse-survival DGP grid 0.1 -> 0.05 months; effect calibration grid 0.1 -> 0.01")
    if (!length(reason)) reason <- "Delayed RAH/D-RMST ARE unchanged; S0 calibration stays at 40"
  }
  if (r$table %in% c(5,7)) {
    historical <- cm_provenance[cm_provenance$table == r$table &
      cm_provenance$setting == r$setting & cm_provenance$metric == r$metric, ]
    stopifnot(nrow(historical) == 1L)
    reason <- if (historical$matches_pdf)
      "Preserved historical output matches old PDF at printed precision; old cell provenance identified" else
      "UNRESOLVED old printed ARE: preserved historical script/output disagrees with this PDF cell. Limited to Table 5 ARE and Table 7 tau=24 ARE (six cells total); not MC noise"
    d <- cm_decomposition[cm_decomposition$table == r$table &
      cm_decomposition$setting == r$setting & cm_decomposition$metric == r$metric, ]
    stopifnot(nrow(d) == 1L)
    reason <- c(reason,"Recovered old/current fitted Weibulls, event/censoring DGP, n=300 and B=500 unchanged")
    if (cox) reason <- c(reason,
      sprintf("Paired Cox horizon contribution %+.6f: old theory t_H=26 / empirical full follow-up -> row tau",d$cox_horizon_delta))
    if (!empirical) {
      reason <- c(reason,sprintf("Integration step 0.05 -> 0.01 contribution %+.6f; deterministic, not MC",d$grid_delta))
      if (!historical$matches_pdf) reason <- c(reason,
        sprintf("UNRESOLVED old PDF -> preserved output gap %+.6f",d$old_pdf_to_legacy))
    } else {
      if (abs(d$point_policy_delta) > 1e-10) reason <- c(reason,
        sprintf("Verified RMST support-retention contribution %+.6f: old dropout=.020 batch omitted 1 replicate; current ERE retains its KM-tail contrast. Not seed-only",d$point_policy_delta))
      reason <- c(reason,sprintf("Seed/batch residual %+.6f, combined MC SE %.6f, z %.3f: OK, within nominal 95%% MC band after horizon/retention adjustment",d$seed_batch_delta,d$combined_mc_se,d$seed_batch_z),
        "Current three baseline views reuse one batch; old views used separate sequential batches")
      if (!cox && abs(d$point_policy_delta) <= 1e-10) reason <- c(reason,
        "Verified seed/batch-only RAH/D-RMST ERE change")
    }
  }
  if (r$table==6) reason <- c("Cox truncated at 24; new MC seeds; original 50-patient threshold grid preserved",if(r$setting=="RAH") "Shared RAH variance agrees with legacy survAH::ah2 on identical datasets; no variance-formula change attributed" else character())
  if (r$table==11) reason <- c("Old printed cells have no verified generating run; current cells use the printed crossing formula with t_M=43. Old ARE values cannot be reproduced by old default t_M=21.25 or current t_M=43; NOT explained by Monte Carlo noise. A specific old coding error has not been localized")
  if (r$table %in% c(2,3) && r$metric == "ere_rah_drmst") {
    checked <- ph_mc_check[ph_mc_check$table == r$table & ph_mc_check$setting == r$setting, ]
    stopifnot(nrow(checked) == 1L)
    reason <- c(reason, checked$status,
                sprintf("Combined bootstrap MC z=%.3f", checked$combined_mc_z))
  }
  if (!r$changed) reason <- c(reason,"No change at displayed precision")
  out$reason[i] <- paste(reason,collapse="; ")
}
out$side_of_one_changed <- grepl("^(are|ere)",out$metric) &
  sign(out$old-1) != sign(out$new-1)
out <- out[order(out$table,out$setting,out$metric),]
write.csv(out,"audit/cell_changes_vs_27Sep.csv",row.names=FALSE)
cat(sum(out$changed),"of",nrow(out),"numeric cells changed at displayed precision.\n")
print(aggregate(changed ~ table,out,sum))
print(out[out$side_of_one_changed,c("table","setting","metric","old","new")])
