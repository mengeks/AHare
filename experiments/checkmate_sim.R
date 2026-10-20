run_experiment_checkmate_sim <- function(cfg) {
  started <- Sys.time()
  z <- cfg$checkmate057
  obs <- readRDS("results/checkmate_observed.rds")
  wb0 <- obs$weibull$control
  wb1 <- obs$weibull$treatment
  base_alpha <- weibull_alpha(wb0[["shape"]], wb0[["scale"]],
                              wb1[["shape"]], wb1[["scale"]])
  rows <- list()
  run_row <- function(id, panel, label, tau, lambda_c, shape1, scale1, alpha_fn) {
    if (id %in% names(rows)) return(invisible())
    message("Running ", id)
    seed <- scenario_seed(cfg, id)
    th <- theory_result(wb0[["shape"]], wb0[["scale"]], alpha_fn, tau,
                        lambda_c, z$censoring_uniform,
                        z$integration_step)
    gen <- function() {
      d0 <- gen_weibull_arm(z$n_per_arm, wb0[["shape"]], wb0[["scale"]],
                            lambda_c, z$censoring_uniform)
      d1 <- gen_weibull_arm(z$n_per_arm, shape1, scale1, lambda_c,
                            z$censoring_uniform)
      data.frame(time = c(d0$time, d1$time), status = c(d0$status, d1$status),
                 arm = rep(0:1, each = z$n_per_arm))
    }
    mc <- simulate_methods(z$B_ere, seed, gen, tau, cfg$project$alpha_level,
                           need_power = FALSE, workers = cfg$project$workers)
    rows[[id]] <<- as.list(c(id = id, panel = panel, label = label,
                             seed = seed, n = z$n_per_arm, B = z$B_ere,
                             tau = tau, lambda_c = lambda_c,
                             named_ratio_fields(th, mc)))
    rows[[id]]$theory <<- list(th)
  }
  for (tau in unlist(z$horizon_grid)) {
    id <- sprintf("cm_nonph_tau_%02d_lc_005", tau)
    run_row(id, "tau", sprintf("tau=%d", tau), tau, z$dropout_rate,
            wb1[["shape"]], wb1[["scale"]], base_alpha)
  }
  for (lc in unlist(z$dropout_grid)) {
    id <- sprintf("cm_nonph_tau_24_lc_%03d", round(1000 * lc))
    run_row(id, "dropout", sprintf("lambda_c=%.3f", lc), z$tau, lc,
            wb1[["shape"]], wb1[["scale"]], base_alpha)
  }
  scale1_ph <- wb0[["scale"]] / z$ph_hr^(1 / wb0[["shape"]])
  run_row("cm_ph_tau_24_lc_005", "hazard", "PH fitted shape", z$tau,
          z$dropout_rate, wb0[["shape"]], scale1_ph, alpha_ph(z$ph_hr))

  power_rows <- list()
  for (n in unlist(z$power_n_grid)) {
    id <- sprintf("cm_power_n_%03d", n)
    message("Running ", id)
    seed <- scenario_seed(cfg, id)
    gen <- function() {
      d0 <- gen_weibull_arm(n, wb0[["shape"]], wb0[["scale"]],
                            z$dropout_rate, z$censoring_uniform)
      d1 <- gen_weibull_arm(n, wb1[["shape"]], wb1[["scale"]],
                            z$dropout_rate, z$censoring_uniform)
      data.frame(time = c(d0$time, d1$time), status = c(d0$status, d1$status),
                 arm = rep(0:1, each = n))
    }
    mc <- simulate_methods(z$B_power, seed, gen, z$tau,
                           cfg$project$alpha_level, need_power = TRUE,
                           workers = cfg$project$workers,
                           cox_power_test = z$cox_power_test,
                           rah_power_method = z$rah_power_method)
    power_rows[[id]] <- data.frame(n = n, seed = seed,
                                    Cox = mc$power[["Cox"]],
                                    DRMST = mc$power[["DRMST"]],
                                    RAH = mc$power[["RAH"]])
  }
  baseline_id <- "cm_nonph_tau_24_lc_005"
  baseline_theory <- rows[[baseline_id]]$theory[[1]]
  flat_rows <- lapply(rows, function(x) { x$theory <- NULL; x })
  views <- data.frame(
    panel = c(rep("tau", 3), rep("dropout", 3), rep("hazard", 2)),
    label = c("tau=18", "tau=21", "tau=24",
              "lambda_c=0.001", "lambda_c=0.005", "lambda_c=0.020",
              "Non-PH (fitted)", "PH (HR=0.75)"),
    id = c("cm_nonph_tau_18_lc_005", "cm_nonph_tau_21_lc_005",
           baseline_id, "cm_nonph_tau_24_lc_001", baseline_id,
           "cm_nonph_tau_24_lc_020", baseline_id, "cm_ph_tau_24_lc_005"),
    stringsAsFactors = FALSE
  )
  result <- list(metadata = result_metadata(cfg, "checkmate_sim",
                                             scenario_seed(cfg, "checkmate_sim"), started),
                 sensitivity = rows_df(flat_rows), baseline_id = baseline_id,
                 sensitivity_views = views, baseline_theory = baseline_theory,
                 power = do.call(rbind, power_rows))
  save_experiment("results/checkmate_sim.rds", result)
}
