# Controlled replay of the Table 3 Light, kappa=.826 ERE discrepancy.
# Run from AHare/: Rscript audit/check_legacy_ere.R
source("R/utils_pipeline.R")
reference <- new.env(parent = globalenv())
sys.source("audit/reference_methods_pre_package_switch.R", envir = reference)
rmst_from_km <- reference$rmst_from_km
cfg <- read_pipeline_config()
old_path <- "output/main-sim-paper/20260629_170854/mc/table-main-sim-ph-hr070-kappa-050-200-light-heavy/ph_hr070_kappa_0826_light.csv"
if (!file.exists(old_path)) stop("Legacy raw replicates are required: ", old_path)
old <- read.csv(old_path)
row <- subset(readRDS("results/main_ph.rds")$scenarios,
              shape == .826 & s0 == .5 & censoring == "light")
stopifnot(nrow(old) == 2000, nrow(row) == 1)

# Fit only the contrasts needed for ERE; SE computation is unnecessary here.
contrasts <- function(dat, tau, truncate = TRUE) {
  if (truncate) dat <- truncate_at_tau(dat, tau)
  km0 <- survfit(Surv(time, status) ~ 1, data = subset(dat, arm == 0))
  km1 <- survfit(Surv(time, status) ~ 1, data = subset(dat, arm == 1))
  r0 <- rmst_from_km(km0, tau); r1 <- rmst_from_km(km1, tau)
  f0 <- 1 - summary(km0, times = tau, extend = TRUE)$surv
  f1 <- 1 - summary(km1, times = tau, extend = TRUE)$surv
  c(u_cox = unname(coef(coxph(Surv(time, status) ~ arm, data = dat))[1]),
    u_drmst = r1 - r0, u_rah = log(f1/r1) - log(f0/r0))
}
generate <- function(seed) {
  set.seed(seed)
  gen_ph_dataset(row$n, row$shape, row$scale0, row$scale1,
                 row$lambda_c, cfg$simulation$censoring_uniform)
}

# Old seeds + new code: D-RMST and RAH must match the saved old contrasts.
paired <- do.call(rbind, lapply(seq_len(25), function(i)
  contrasts(generate(old$seed[i]), row$tau)))
same_sample_error <- c(
  DRMST = max(abs(paired[, "u_drmst"] - old$st_rmst[1:25])),
  RAH = max(abs(paired[, "u_rah"] - old$st_rah[1:25])))
stopifnot(max(same_sample_error) < 1e-10)

message("Replaying current seeds (B=2000) for paired bootstrap MC SE")
started <- Sys.time()
current <- do.call(rbind, parallel::mclapply(seq_len(row$B), function(i)
  contrasts(generate(row$seed + i - 1L), row$tau), mc.cores = 2))
current_summary <- summarize_mc(current)
stopifnot(abs(current_summary$ere[["rah_drmst"]] - row$ere_rah_drmst) < 1e-12)
old_stats <- as.matrix(old[, c("st_cox", "st_rmst", "st_rah")])
colnames(old_stats) <- colnames(current)

bootstrap <- function(stats, seed) {
  set.seed(seed)
  draws <- replicate(2000, {
    ix <- sample.int(nrow(stats), nrow(stats), replace = TRUE)
    summarize_mc(stats[ix, , drop = FALSE])$ere
  })
  data.frame(metric = rownames(draws),
             estimate = unname(summarize_mc(stats)$ere),
             mc_se = apply(draws, 1, sd),
             lo = apply(draws, 1, quantile, .025),
             hi = apply(draws, 1, quantile, .975))
}
summary <- rbind(cbind(run = "Old seeds", bootstrap(old_stats, 27301)),
                 cbind(run = "Current seeds", bootstrap(current, 27302)))
write.csv(summary, "audit/ere_mc_se.csv", row.names = FALSE)
saveRDS(list(scenario = row, legacy_file = old_path,
             same_sample_max_error = same_sample_error,
             old = old_stats, current = current,
             bootstrap_summary = summary,
             elapsed_seconds = as.numeric(difftime(Sys.time(), started, units = "secs")),
             session = sessionInfo()), "audit/legacy_ere_replay.rds")
print(summary)
print(same_sample_error)
