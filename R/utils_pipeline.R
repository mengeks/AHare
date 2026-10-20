source("R/utils_config.R")
source("R/utils_dgp.R")
source("R/utils_methods.R")
source("R/utils_theory.R")

named_ratio_fields <- function(theory, mc) {
  c(
    are_drmst_cox = theory$are[["drmst_cox"]],
    are_rah_cox = theory$are[["rah_cox"]],
    are_rah_drmst = theory$are[["rah_drmst"]],
    cos2_cox = theory$cos2[["Cox"]],
    cos2_drmst = theory$cos2[["DRMST"]],
    cos2_rah = theory$cos2[["RAH"]],
    ere_drmst_cox = mc$ere[["drmst_cox"]],
    ere_rah_cox = mc$ere[["rah_cox"]],
    ere_rah_drmst = mc$ere[["rah_drmst"]],
    power_cox = mc$power[["Cox"]],
    power_drmst = mc$power[["DRMST"]],
    power_rah = mc$power[["RAH"]]
  )
}

run_ph_scenario <- function(cfg, id, n, B, tau, shape, s0, hr, lambda_c,
                            uniform_range, need_power = FALSE) {
  message("Running ", id)
  scale0 <- weibull_scale(s0, tau, shape)
  scale1 <- scale0 / hr^(1 / shape)
  seed <- scenario_seed(cfg, id)
  th <- theory_result(shape, scale0, alpha_ph(hr), tau, lambda_c,
                      uniform_range, cfg$project$integration_step)
  gen <- function() gen_ph_dataset(n, shape, scale0, scale1, lambda_c,
                                   uniform_range)
  mc <- simulate_methods(B, seed, gen, tau, cfg$project$alpha_level,
                         need_power = need_power, workers = cfg$project$workers,
                         cox_power_test = cfg$simulation$cox_power_test)
  as.list(c(id = id, seed = seed, n = n, B = B, tau = tau, shape = shape,
            s0 = s0, hr = hr, lambda_c = lambda_c, scale0 = scale0,
            scale1 = scale1, named_ratio_fields(th, mc)))
}

run_nonph_scenario <- function(cfg, id, n, B, tau, shape, s0, alpha_fn,
                               lambda_c, uniform_range, case, s, t_m = NA_real_) {
  message("Running ", id)
  scale0 <- weibull_scale(s0, tau, shape)
  seed <- scenario_seed(cfg, id)
  th <- theory_result(shape, scale0, alpha_fn, tau, lambda_c, uniform_range,
                      cfg$project$integration_step)
  surv_grid <- make_nonph_survival_grid(shape, scale0, alpha_fn,
                                       cfg$simulation$nonph_grid_max,
                                       cfg$simulation$nonph_grid_n)
  gen <- function() gen_nonph_dataset(n, shape, scale0, alpha_fn, lambda_c,
                                      uniform_range, surv_grid)
  mc <- simulate_methods(B, seed, gen, tau, cfg$project$alpha_level,
                         need_power = FALSE, workers = cfg$project$workers)
  as.list(c(id = id, seed = seed, n = n, B = B, tau = tau, shape = shape,
            s0 = s0, hr = NA_real_, lambda_c = lambda_c, scale0 = scale0,
            scale1 = NA_real_, case = case, s = s, t_m = t_m,
            named_ratio_fields(th, mc)))
}

rows_df <- function(rows) {
  out <- do.call(rbind, lapply(rows, function(x) {
    as.data.frame(x, stringsAsFactors = FALSE)
  }))
  numeric_names <- setdiff(names(out), c("id", "case", "scenario", "censoring", "panel", "label"))
  for (nm in numeric_names) out[[nm]] <- suppressWarnings(as.numeric(out[[nm]]))
  row.names(out) <- NULL
  out
}

save_experiment <- function(path, result) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  saveRDS(result, path)
  message("Saved ", path)
  invisible(result)
}

fit_checkmate_weibull <- function(dat) {
  fit <- survreg(Surv(time, status) ~ 1, data = dat, dist = "weibull")
  c(shape = 1 / fit$scale, scale = exp(coef(fit)[[1]]))
}

read_checkmate_data <- function() {
  list(original = read.csv("data/CheckMate057-OS-original.csv"),
       sensitivity = read.csv("data/CheckMate057-OS-censoring-reconstructed.csv"))
}
