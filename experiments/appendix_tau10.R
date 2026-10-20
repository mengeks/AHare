run_experiment_appendix_tau10 <- function(cfg) {
  started <- Sys.time()
  a <- cfg$appendix_tau10
  rates <- unlist(a$censoring_rates)
  rows <- list()
  for (shape in unlist(a$shapes)) for (cn in names(rates)) {
    s0 <- if (shape == 1) exp(-1) else 0.5
    id <- sprintf("tau10_shape_%04d_%s", round(1000 * shape), cn)
    rows[[id]] <- run_ph_scenario(cfg, id, a$n_per_arm, a$B, a$tau,
                                  shape, s0, a$hr, rates[[cn]],
                                  a$censoring_uniform)
    rows[[id]]$censoring <- cn
    rows[[id]]$scenario <- if (shape == 1) "Exponential(lambda0=0.10)" else
      sprintf("Weibull(kappa=%.1f)", shape)
  }
  result <- list(metadata = result_metadata(cfg, "appendix_tau10",
                                             scenario_seed(cfg, "appendix_tau10"), started),
                 scenarios = rows_df(rows))
  save_experiment("results/appendix_tau10.rds", result)
}

