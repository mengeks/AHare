# Compare the frozen pre-switch formula to package-backed RAH and ah2.
source("R/utils_pipeline.R")
reference <- new.env(parent = globalenv())
sys.source("audit/reference_methods_pre_package_switch.R", envir = reference)
cfg <- read_pipeline_config()
wb <- readRDS("results/checkmate_observed.rds")$weibull
rows <- lapply(seq_len(30), function(i) {
  set.seed(893000 + i)
  n <- c(150, 300, 400)[(i - 1L) %% 3L + 1L]
  arms <- lapply(wb, function(z)
    gen_weibull_arm(n, z[["shape"]], z[["scale"]], .005, c(6, 30)))
  dat <- data.frame(time = c(arms[[1]]$time, arms[[2]]$time),
                    status = c(arms[[1]]$status, arms[[2]]$status),
                    arm = rep(0:1, each = n))
  dat <- truncate_at_tau(dat, 24)
  shared <- reference$rah_components(dat, 24)
  package <- rah_components(dat, 24)
  stopifnot(abs(shared$stat - package$stat) < 1e-10,
            abs(shared$se^2 - package$se^2) < 1e-10)
  legacy <- suppressMessages(survAH::ah2(dat$time, dat$status, dat$arm, tau = 24))$rah
  old_stat <- log(legacy[1, "Est."])
  old_se <- (log(legacy[1, "Upper 0.95"]) - log(legacy[1, "Lower 0.95"])) / (2 * qnorm(.975))
  data.frame(seed = 893000 + i, n = n,
             stat_error = abs(shared$stat - old_stat),
             variance_error = abs(shared$se^2 - old_se^2),
             pvalue_error = abs(2 * pnorm(-abs(shared$stat / shared$se)) - legacy[1, "P-value"]))
})
out <- do.call(rbind, rows)
stopifnot(max(out$stat_error, out$variance_error, out$pvalue_error) < 1e-10)
write.csv(out, "audit/rah_same_data_equivalence.csv", row.names = FALSE)
print(vapply(out[c("stat_error", "variance_error", "pvalue_error")], max, numeric(1)))
