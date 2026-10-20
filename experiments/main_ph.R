run_experiment_main_ph <- function(cfg) {
  started <- Sys.time()
  z <- cfg$simulation
  rates <- unlist(z$censoring_rates)
  rows <- list()
  add <- function(shape, s0, censoring) {
    id <- sprintf("ph_hr070_shape_%04d_s0_%03d_%s",
                  round(1000 * shape), round(100 * s0), censoring)
    if (id %in% names(rows)) return(invisible())
    rows[[id]] <<- run_ph_scenario(cfg, id, z$n_per_arm, z$B, z$tau,
                                   shape, s0, z$hr, rates[[censoring]],
                                   z$censoring_uniform)
    rows[[id]]$censoring <<- censoring
  }
  for (s0 in unlist(z$s0_grid)) for (cn in names(rates)) add(z$shape, s0, cn)
  for (shape in unlist(z$shape_grid)) for (cn in names(rates)) add(shape, z$s0, cn)
  curves <- lapply(unlist(z$s0_grid)[c(1, 2, 4)], function(s0) {
    theoretical_survival(z$shape, weibull_scale(s0, z$tau, z$shape),
                         alpha_ph(z$hr), z$tau)
  })
  baseline_theory <- theory_result(
    z$shape, weibull_scale(z$s0, z$tau, z$shape), alpha_ph(z$hr), z$tau,
    rates[["light"]], z$censoring_uniform, cfg$project$integration_step)
  result <- list(metadata = result_metadata(cfg, "main_ph",
                                             scenario_seed(cfg, "main_ph"), started),
                 scenarios = rows_df(rows), plot_s0 = unlist(z$s0_grid)[c(1, 2, 4)],
                 curves = curves, baseline_theory = baseline_theory)
  save_experiment("results/main_ph.rds", result)
}
