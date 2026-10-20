# Run from the shared AHare repository; evidence stays in the private audit.
if (dir.exists(".library")) .libPaths(c(normalizePath(".library"), .libPaths()))
source("R/utils_pipeline.R")
cfg <- read_pipeline_config()
evidence <- "/Users/xmeng/Partners HealthCare Dropbox/Xiang Meng/Apps/Overleaf/AH-ARE/AHare/audit"
scale0 <- weibull_scale(.5, 40, .826)
obs <- readRDS("results/checkmate_observed.rds")
wb0 <- obs$weibull$control; wb1 <- obs$weibull$treatment
jobs <- list(
  ph_ere = list(tau = 40, power = FALSE, ct = "score", rt = "ah1",
    gen = function() gen_ph_dataset(400, .826, scale0, scale0/.7^(1/.826), .025, c(24,43))),
  appendix_power = list(tau = 40, power = TRUE, ct = "score", rt = "ah1",
    gen = function() gen_ph_dataset(400, .826, scale0, scale0/.82^(1/.826), .0006, c(24,43))),
  checkmate_power = list(tau = 24, power = TRUE, ct = "wald", rt = "ah2",
    gen = function() {
      d0 <- gen_weibull_arm(300, wb0[["shape"]], wb0[["scale"]], .005, c(6,30))
      d1 <- gen_weibull_arm(300, wb1[["shape"]], wb1[["scale"]], .005, c(6,30))
      data.frame(time=c(d0$time,d1$time),status=c(d0$status,d1$status),arm=rep(0:1,each=300))
    })
)
records <- list()
for (name in names(jobs)) {
  job <- jobs[[name]]
  invisible(simulate_methods(4, 7654321, job$gen, job$tau, progress=FALSE,
                             need_power=job$power, workers=1,
                             cox_power_test=job$ct, rah_power_method=job$rt))
  previous <- NULL
  for (trial in 1:2) for (workers in if(trial==1) c(1,4) else c(4,1)) {
    message("Pilot: ",name," trial=",trial," workers=",workers)
    elapsed <- system.time(value <- simulate_methods(300, 7654321, job$gen, job$tau,
      progress=FALSE, need_power=job$power, workers=workers,
      cox_power_test=job$ct, rah_power_method=job$rt))[["elapsed"]]
    if (!is.null(previous)) stopifnot(identical(value, previous))
    previous <- value
    records[[length(records)+1L]] <- data.frame(job=name,trial=trial,workers=workers,
                                               B=300,elapsed_seconds=elapsed)
  }
}
out <- do.call(rbind, records)
write.csv(out,file.path(evidence,"worker_pilot_legacy_restore.csv"),row.names=FALSE)
print(out,row.names=FALSE)
totals <- aggregate(elapsed_seconds~workers,out,sum)
print(totals,row.names=FALSE)
cat("Recommended workers:",totals$workers[which.min(totals$elapsed_seconds)],"\n")
