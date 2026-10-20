run_experiment_main_nonph <- function(cfg) {
  started <- Sys.time()
  z <- cfg$simulation
  rates <- unlist(z$censoring_rates)
  alphas <- list(
    fading = alpha_fading(z$tau, z$effect_shape, z$fading_t_m,
                          step = z$effect_calibration_step),
    delayed = alpha_delayed(z$tau, z$effect_shape, step = z$effect_calibration_step)
  )
  rows <- list()
  for (case in names(alphas)) for (cn in names(rates)) {
    id <- sprintf("nonph_%s_s_%.1f_%s", case, z$effect_shape, cn)
    rows[[id]] <- run_nonph_scenario(cfg, id, z$n_per_arm, z$B, z$tau,
                                     z$shape, z$s0, alphas[[case]], rates[[cn]],
                                     z$censoring_uniform, case, z$effect_shape,
                                     if (case == "fading") z$fading_t_m else NA_real_)
    rows[[id]]$censoring <- cn
  }
  s_grid <- c(0.5, 1, 2)
  curves <- list(
    fading = lapply(s_grid, function(s) theoretical_survival(
      z$shape, weibull_scale(z$s0, z$tau, z$shape),
      alpha_fading(z$tau, s, z$fading_t_m, step = z$effect_calibration_step), z$tau)),
    delayed = lapply(s_grid, function(s) theoretical_survival(
      z$shape, weibull_scale(z$s0, z$tau, z$shape),
      alpha_delayed(z$tau, s, step = z$effect_calibration_step), z$tau))
  )
  result <- list(metadata = result_metadata(cfg, "main_nonph",
                                             scenario_seed(cfg, "main_nonph"), started),
                 scenarios = rows_df(rows), effect_shapes = s_grid, curves = curves)
  save_experiment("results/main_nonph.rds", result)
}
