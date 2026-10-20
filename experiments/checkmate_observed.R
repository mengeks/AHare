run_experiment_checkmate_observed <- function(cfg) {
  started <- Sys.time()
  z <- cfg$checkmate057
  dat <- read_checkmate_data()
  tables <- do.call(rbind, lapply(names(dat), function(nm) {
    x <- observed_test_results(dat[[nm]], z$tau)
    x$dataset <- nm
    x
  }))
  wb <- list(control = fit_checkmate_weibull(dat$original[dat$original$arm == 0, ]),
             treatment = fit_checkmate_weibull(dat$original[dat$original$arm == 1, ]))
  fit <- coxph(Surv(time, status) ~ arm, data = truncate_at_tau(dat$original, z$tau))
  zph <- cox.zph(fit, transform = "identity")
  ph_p <- unname(zph$table[nrow(zph$table), "p"])
  km_fit <- survfit(Surv(time, status) ~ arm, data = dat$original)
  km <- data.frame(time = km_fit$time, surv = km_fit$surv,
                   strata = rep(names(km_fit$strata), km_fit$strata))
  zph_data <- data.frame(time = zph$x, residual = zph$y[, 1])
  result <- list(metadata = result_metadata(cfg, "checkmate_observed",
                                             scenario_seed(cfg, "checkmate_observed"), started),
                 table = tables, weibull = wb, schoenfeld_p = ph_p,
                 km = km, schoenfeld = zph_data)
  save_experiment("results/checkmate_observed.rds", result)
}
