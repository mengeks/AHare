# Private audit only. Run from AHare/: Rscript audit/check_main_ph_seed_mc.R
# Compare the preserved Table 2/3 batches to the 27Sep PDF and current results.
if (dir.exists(".library")) .libPaths(c(normalizePath(".library"), .libPaths()))
source("R/utils_pipeline.R")
reference <- new.env(parent = globalenv())
sys.source("audit/reference_methods_pre_package_switch.R", envir = reference)
cfg <- read_pipeline_config()
current_rows <- readRDS("results/main_ph.rds")$scenarios
old_cells <- read.csv("audit/old27_table_cells.csv")
legacy_dir <- "output/main-sim-paper/20260629_170854"
settings <- read.csv(file.path(legacy_dir, "settings.csv"))
settings <- settings[settings$design == "ph", ]
stopifnot(nrow(settings) == 20L)

# ERE depends only on point contrasts, not standard errors or p-values.
contrasts <- function(dat, tau) {
  dat <- truncate_at_tau(dat, tau)
  arm_value <- function(z) {
    km <- survfit(Surv(time, status) ~ 1, data = z)
    r <- reference$rmst_from_km(km, tau)
    f <- 1 - summary(km, times = tau, extend = TRUE)$surv
    c(rmst = r, log_ah = log(f / r))
  }
  a0 <- arm_value(dat[dat$arm == 0, ])
  a1 <- arm_value(dat[dat$arm == 1, ])
  c(DRMST = unname(a1["rmst"] - a0["rmst"]),
    RAH = unname(a1["log_ah"] - a0["log_ah"]))
}
ratio <- function(x) efficacy(x[, "RAH"]) / efficacy(x[, "DRMST"])
draw <- function(row, seed) {
  set.seed(seed)
  contrasts(gen_ph_dataset(row$n, row$shape, row$scale0, row$scale1,
                           row$lambda_c, cfg$simulation$censoring_uniform), row$tau)
}
bootstrap_se <- function(stats, seed) {
  set.seed(seed)
  sd(replicate(2000, ratio(stats[sample.int(nrow(stats), nrow(stats),
                                          replace = TRUE), , drop = FALSE])))
}

started <- Sys.time()
current_batches <- list()
for (i in seq_len(nrow(current_rows))) {
  row <- current_rows[i, ]
  message("Point-contrast replay: ", row$id)
  stats <- do.call(rbind, parallel::mclapply(seq_len(row$B), function(j)
    draw(row, row$seed + j - 1L), mc.cores = 4))
  stopifnot(abs(ratio(stats) - row$ere_rah_drmst) < 1e-10)
  current_batches[[row$id]] <- stats
}

records <- list()
for (i in seq_len(nrow(settings))) {
  old_setting <- settings[i, ]
  table_number <- if (grepl("kappa", old_setting$table_label)) 3L else 2L
  setting <- if (table_number == 3L)
    sprintf("shape=%.3f;%s", old_setting$shape, old_setting$censoring) else
    sprintf("s0=%.2f;%s", old_setting$S0, old_setting$censoring)
  row <- current_rows[current_rows$shape == old_setting$shape &
                        current_rows$s0 == old_setting$S0 &
                        current_rows$censoring == old_setting$censoring, ]
  stopifnot(nrow(row) == 1L, row$n == old_setting$n_arm,
            row$B == old_setting$n_sim, row$tau == old_setting$tau,
            row$hr == old_setting$HR,
            abs(row$scale0 - old_setting$scale0) < 1e-10,
            abs(row$scale1 - old_setting$scale1) < 1e-10,
            row$lambda_c == old_setting$lambda_cens,
            all(cfg$simulation$censoring_uniform ==
                  c(old_setting$tau_l, old_setting$tau_u)))
  path <- file.path(legacy_dir, "mc", paste0("table-", old_setting$table_label),
                    paste0(old_setting$setting_id, ".csv"))
  legacy <- read.csv(path)
  old <- as.matrix(legacy[, c("st_rmst", "st_rah")])
  colnames(old) <- c("DRMST", "RAH")
  old_value <- ratio(old)
  pdf_value <- old_cells$old[old_cells$table == table_number &
                              old_cells$setting == setting &
                              old_cells$metric == "ere_rah_drmst"]
  stopifnot(length(pdf_value) == 1L, round(old_value, 3) == pdf_value)
  current <- current_batches[[row$id]]
  paired <- do.call(rbind, lapply(seq_len(25L), function(j)
    draw(row, legacy$seed[j])))
  drm_error <- max(abs(paired[, "DRMST"] - old[seq_len(25L), "DRMST"]),
                   na.rm = TRUE)
  rah_error <- max(abs(paired[, "RAH"] - old[seq_len(25L), "RAH"]),
                   na.rm = TRUE)
  stopifnot(drm_error < 1e-10, rah_error < 1e-10)
  retention_changed <- any(!is.finite(old))
  same_seed_new_policy <- old_value
  if (retention_changed) {
    message("Checking legacy support exclusions: Table ", table_number, " ", setting)
    filled <- do.call(rbind, parallel::mclapply(seq_len(nrow(legacy)), function(j)
      draw(row, legacy$seed[j]), mc.cores = 4))
    same_seed_new_policy <- ratio(filled)
    for (method in colnames(old)) {
      keep <- is.finite(old[, method])
      stopifnot(max(abs(filled[keep, method] - old[keep, method])) < 1e-10)
    }
  }
  old_se <- bootstrap_se(old, 27301)
  new_se <- bootstrap_se(current, 27302)
  new_value <- ratio(current)
  z <- (new_value - old_value) / sqrt(old_se^2 + new_se^2)
  inside <- abs(z) <= 1.96
  records[[i]] <- data.frame(
    table = table_number, setting = setting, old = old_value, new = new_value,
    old_mc_se = old_se, new_mc_se = new_se, combined_mc_z = z,
    within_nominal_95_mc_band = inside,
    old_drmst_finite = sum(is.finite(old[, "DRMST"])),
    old_rah_finite = sum(is.finite(old[, "RAH"])),
    new_drmst_finite = sum(is.finite(current[, "DRMST"])),
    new_rah_finite = sum(is.finite(current[, "RAH"])),
    seed_only = !retention_changed,
    same_old_seed_new_retention_ere = same_seed_new_policy,
    max_matched_drmst_error = drm_error, max_matched_rah_error = rah_error,
    status = if (retention_changed) "EXPLAINED: support-retention change plus seed" else
      if (inside) "OK: seed-only, within nominal 95% MC band" else
        "OK: seed-only, outside nominal 95% MC band",
    legacy_file = path)
}
out <- do.call(rbind, records)
out <- out[order(out$table, out$setting), ]
write.csv(out, "audit/main_ph_seed_mc_check.csv", row.names = FALSE)
saveRDS(list(current = current_batches, comparison = out,
             elapsed_seconds = as.numeric(difftime(Sys.time(), started, units = "secs")),
             session = sessionInfo()), "audit/main_ph_seed_mc_replay.rds")
print(out[, c("table", "setting", "old", "new", "combined_mc_z", "status")],
      row.names = FALSE)
