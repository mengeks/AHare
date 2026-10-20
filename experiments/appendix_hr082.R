run_experiment_appendix_hr082 <- function(cfg) {
  started <- Sys.time()
  z <- cfg$simulation; a <- cfg$appendix_hr082
  rates <- unlist(z$censoring_rates)
  rows <- list()
  add <- function(shape, s0, cn) {
    id <- sprintf("ph_hr082_shape_%04d_s0_%03d_%s",
                  round(1000 * shape), round(100 * s0), cn)
    if (id %in% names(rows)) return(invisible())
    rows[[id]] <<- run_ph_scenario(cfg, id, a$n_per_arm, a$B, z$tau,
                                   shape, s0, a$hr, rates[[cn]],
                                   z$censoring_uniform, need_power = TRUE)
    rows[[id]]$censoring <<- cn
  }
  for (s0 in unlist(a$s0_grid)) for (cn in names(rates)) add(z$shape, s0, cn)
  for (shape in unlist(a$shape_grid)) for (cn in names(rates)) add(shape, z$s0, cn)
  result <- list(metadata = result_metadata(cfg, "appendix_hr082",
                                             scenario_seed(cfg, "appendix_hr082"), started),
                 scenarios = rows_df(rows))
  save_experiment("results/appendix_hr082.rds", result)
}
