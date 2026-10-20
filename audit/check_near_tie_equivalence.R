# Why ah1 needs the same per-arm timefix convention as the original survfit.
# Run from AHare/: Rscript audit/check_near_tie_equivalence.R
if (dir.exists(".library")) .libPaths(c(normalizePath(".library"), .libPaths()))
source("R/utils_pipeline.R")
reference <- new.env(parent = globalenv())
sys.source("audit/reference_methods_pre_package_switch.R", reference)
row <- subset(readRDS("results/main_ph.rds")$scenarios,
              shape == 2 & s0 == .5 & censoring == "light")
stopifnot(nrow(row) == 1)
one <- function(i) {
  seed <- row$seed + i - 1L
  set.seed(seed)
  dat <- truncate_at_tau(gen_ph_dataset(row$n, row$shape, row$scale0,
                                        row$scale1, row$lambda_c, c(24, 43)), 40)
  kms <- lapply(0:1, function(a)
    survfit(Surv(time, status) ~ 1, data = dat[dat$arm == a, ]))
  log_ah <- vapply(kms, function(km)
    log((1 - summary(km, times = 40, extend = TRUE)$surv) /
          reference$rmst_from_km(km, 40)), numeric(1))
  old <- log_ah[[2]] - log_ah[[1]]
  raw <- vapply(0:1, function(a) {
    z <- dat[dat$arm == a, ]
    invisible(capture.output(fit <- survAH::ah1(z$time, z$status, tau = 40)))
    fit$result1["AH(tau)", "log(Est)"]
  }, numeric(1))
  fixed <- rah_components(dat, 40)$stat
  data.frame(seed = seed, raw_package_error = abs(old - (raw[[2]] - raw[[1]])),
             matched_timefix_error = abs(old - fixed))
}
rows <- if (.Platform$OS.type == "windows") lapply(seq_len(row$B), one) else
  parallel::mclapply(seq_len(row$B), one, mc.cores = 4)
out <- do.call(rbind, rows)
stopifnot(max(out$matched_timefix_error) < 1e-10)
write.csv(out[out$raw_package_error > 1e-10, ],
          "audit/near_tie_equivalence.csv", row.names = FALSE)
print(vapply(out[-1], max, numeric(1)))
cat(sum(out$raw_package_error > 1e-10), "of", row$B,
    "replicates differ without the inherited timefix convention.\n")
