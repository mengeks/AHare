run_experiment_appendix_crossing <- function(cfg) {
  started <- Sys.time()
  z <- cfg$simulation; a <- cfg$appendix_crossing
  rates <- unlist(z$censoring_rates)
  rows <- list()
  fn <- alpha_crossing(a$effect_shape, a$t_m)
  for (cn in names(rates)) {
    id <- sprintf("crossing_tm_%g_%s", a$t_m, cn)
    rows[[id]] <- run_nonph_scenario(cfg, id, a$n_per_arm, a$B, z$tau,
                                     z$shape, z$s0, fn, rates[[cn]],
                                     z$censoring_uniform, "crossing",
                                     a$effect_shape, a$t_m)
    rows[[id]]$censoring <- cn
  }
  result <- list(metadata = result_metadata(cfg, "appendix_crossing",
                                             scenario_seed(cfg, "appendix_crossing"), started),
                 scenarios = rows_df(rows))
  save_experiment("results/appendix_crossing.rds", result)
}
