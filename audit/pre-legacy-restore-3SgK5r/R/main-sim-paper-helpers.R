#=============================================================
# main-sim-paper-helpers.R
# Shared test statistics, ARE/ERE computation, and print helpers
# for the main paper simulation scripts.
# Source this file after fun-ares-v2.R and dgp-tian2017.R.
#=============================================================

#-------------------------------------------------------------
# Test statistics (one simulated dataset -> one scalar)
#-------------------------------------------------------------
rmst_from_km <- function(km, tau) {
  tt  <- c(0, km$time)
  ss  <- c(1, km$surv)
  idx <- tt <= tau
  tt  <- c(tt[idx], tau)
  ss  <- c(ss[idx], approx(km$time, km$surv, tau, rule = 2)$y)
  sum(diff(tt) * ss[-length(ss)])
}

rah_stat <- function(dat, tau) {
  tryCatch({
    km0    <- survfit(Surv(time, status) ~ 1, data = dat[dat$arm == 0, ])
    km1    <- survfit(Surv(time, status) ~ 1, data = dat[dat$arm == 1, ])
    F0_tau <- 1 - summary(km0, times = tau, extend = TRUE)$surv
    F1_tau <- 1 - summary(km1, times = tau, extend = TRUE)$surv
    R0_tau <- rmst_from_km(km0, tau)
    R1_tau <- rmst_from_km(km1, tau)
    if (any(c(F0_tau, F1_tau, R0_tau, R1_tau) <= 0)) return(NA_real_)
    log(F1_tau / R1_tau) - log(F0_tau / R0_tau)
  }, error = function(e) NA_real_)
}

cox_stat <- function(dat) {
  tryCatch(coef(coxph(Surv(time, status) ~ arm, data = dat))[1],
           error = function(e) NA_real_)
}

rmst_stat <- function(dat, tau) {
  tryCatch({
    r <- rmst2(dat$time, dat$status, dat$arm, tau = tau)
    r$unadjusted.result[1, 1]
  }, error = function(e) NA_real_)
}

# p-value variants (two-sided)
cox_pval <- function(dat) {
  tryCatch(summary(coxph(Surv(time, status) ~ arm, data = dat))$sctest["pvalue"],
           error = function(e) NA_real_)
}

rmst_pval <- function(dat, tau) {
  tryCatch({
    r <- rmst2(dat$time, dat$status, dat$arm, tau = tau)
    r$unadjusted.result[1, 4]
  }, error = function(e) NA_real_)
}

rah_pval <- function(dat, tau) {
  tryCatch({
    km0    <- survfit(Surv(time, status) ~ 1, data = dat[dat$arm == 0, ])
    km1    <- survfit(Surv(time, status) ~ 1, data = dat[dat$arm == 1, ])
    F0_tau <- 1 - summary(km0, times = tau, extend = TRUE)$surv
    F1_tau <- 1 - summary(km1, times = tau, extend = TRUE)$surv
    R0_tau <- rmst_from_km(km0, tau)
    R1_tau <- rmst_from_km(km1, tau)
    if (any(c(F0_tau, F1_tau, R0_tau, R1_tau) <= 0)) return(NA_real_)
    log_ratio <- log(F1_tau / R1_tau) - log(F0_tau / R0_tau)
    # delta-method variance: sum over each arm of
    #   sum_i phi(t_i)^2 * d_i / Y_i^2,  phi(t) = 1/F(tau) - R(t)/R(tau)
    rah_var_arm <- function(km, F_tau, R_tau) {
      idx  <- km$time <= tau & km$n.event > 0
      if (!any(idx)) return(0)
      t_ev <- km$time[idx]; d_ev <- km$n.event[idx]; Y_ev <- km$n.risk[idx]
      R_t  <- sapply(t_ev, function(t0) rmst_from_km(km, t0))
      phi  <- 1 / F_tau - R_t / R_tau
      sum(phi^2 * d_ev / Y_ev^2)
    }
    var_rah <- rah_var_arm(km0, F0_tau, R0_tau) +
               rah_var_arm(km1, F1_tau, R1_tau)
    if (var_rah <= 0) return(NA_real_)
    2 * pnorm(-abs(log_ratio / sqrt(var_rah)))
  }, error = function(e) NA_real_)
}

#-------------------------------------------------------------
# Theoretical ARE: RMST/RAH at tau=TAU; Cox at tau_H=TAU_H
#-------------------------------------------------------------
make_P_for <- function(shape, scale0, alpha_fn, lambda_cens, tau_l, tau_u,
                        horizon, increment = 0.01) {
  x  <- seq(0, horizon, by = increment)
  k  <- length(x)
  h0 <- (shape / scale0) * (x / scale0)^(shape - 1)
  h0[1] <- 0
  list(tau = horizon, increment = increment, x = x, k = k, p1 = 0.5,
       lambda_t    = h0,
       alpha_t     = alpha_fn(x),
       lambda_cens = lambda_cens,
       cens_tau_l  = tau_l,
       cens_tau_u  = tau_u)
}

#-------------------------------------------------------------
# Cosine-squared: cos^2(theta_X) = xi_X / ||s||^2
#   where s(v) = alpha(v)*sqrt(w(v))  and  xi_X = mu_X^2/sigma_X^2
#   All three tests evaluated at the SAME horizon (TAU) for comparability.
#   Under PH: cos^2(theta_Cox) = 1; for RMST and RAH it equals ARE(X/Cox)
#   at the single horizon.
#-------------------------------------------------------------
compute_cos2_triple <- function(shape, scale0, alpha_fn, lambda_cens,
                                 tau_l, tau_u, increment = 0.01) {
  ft <- ares_v2(make_P_for(shape, scale0, alpha_fn, lambda_cens,
                            tau_l, tau_u, TAU, increment))
  P  <- ft$parm
  s_norm2 <- sum(P$alpha_t^2 * P$w_t * P$lambda_t) * P$increment
  if (s_norm2 < 1e-12) return(list(cos2_cox=NA, cos2_rmst=NA, cos2_ah=NA))
  list(
    cos2_cox  = unname(ft$aeff["Cox"]  / s_norm2),
    cos2_rmst = unname(ft$aeff["RMST"] / s_norm2),
    cos2_ah   = unname(ft$aeff["AHSW"] / s_norm2)
  )
}

compute_are_triple <- function(shape, scale0, alpha_fn, lambda_cens,
                                tau_l, tau_u, increment = 0.01) {
  ft_rmst <- ares_v2(make_P_for(shape, scale0, alpha_fn, lambda_cens,
                                 tau_l, tau_u, TAU, increment))
  ft_cox  <- ares_v2(make_P_for(shape, scale0, alpha_fn, lambda_cens,
                                 tau_l, tau_u, TAU_H, increment))
  eff_rmst <- ft_rmst$aeff["RMST"]
  eff_ahsw <- ft_rmst$aeff["AHSW"]
  eff_cox  <- ft_cox$aeff["Cox"]
  list(
    are_rmst_cox  = unname(eff_rmst / eff_cox),
    are_ahsw_cox  = unname(eff_ahsw / eff_cox),
    are_ahsw_rmst = unname(eff_ahsw / eff_rmst)
  )
}

#-------------------------------------------------------------
# ERE helpers
#-------------------------------------------------------------
.eff <- function(x) {
  x <- x[is.finite(x)]
  if (length(x) < 2) return(NA_real_)
  vx <- var(x)
  if (!is.finite(vx) || vx <= 0) return(NA_real_)
  mean(x)^2 / vx
}

make_replicate_seeds <- function(seed, B) {
  if (B < 1) stop("B must be positive")
  as.integer(seed) + seq_len(B) - 1L
}

compute_ere_from_stats <- function(stats_df) {
  list(
    ere_rmst_cox  = .eff(stats_df$st_rmst) / .eff(stats_df$st_cox),
    ere_ahsw_cox  = .eff(stats_df$st_rah)  / .eff(stats_df$st_cox),
    ere_ahsw_rmst = .eff(stats_df$st_rah)  / .eff(stats_df$st_rmst)
  )
}

write_mc_stats <- function(stats_df, stats_path, metadata = NULL) {
  if (is.null(stats_path)) return(invisible(stats_df))
  dir.create(dirname(stats_path), recursive = TRUE, showWarnings = FALSE)
  out <- stats_df
  if (!is.null(metadata) && length(metadata) > 0) {
    meta_df <- as.data.frame(metadata, stringsAsFactors = FALSE)
    meta_df <- meta_df[rep(1, nrow(out)), , drop = FALSE]
    row.names(meta_df) <- NULL
    out <- cbind(meta_df, out)
  }
  write.csv(out, stats_path, row.names = FALSE)
  invisible(out)
}

compute_power_triple_ph <- function(shape, scale0, scale1, lambda_cens,
                                     tau_l, tau_u, n, B, seed,
                                     alpha_level = 0.05) {
  pv_cox  <- numeric(B)
  pv_rmst <- numeric(B)
  pv_rah  <- numeric(B)
  replicate_seeds <- make_replicate_seeds(seed, B)
  for (i in seq_len(B)) {
    set.seed(replicate_seeds[i])
    dat <- gen_weibull_tian(n, n, shape, scale0, scale1,
                            lambda_cens, tau_l, tau_u)
    pv_cox[i]  <- cox_pval(dat)
    pv_rmst[i] <- rmst_pval(dat, TAU)
    pv_rah[i]  <- rah_pval(dat, TAU)
  }
  list(
    pow_cox  = mean(pv_cox  < alpha_level, na.rm = TRUE),
    pow_rmst = mean(pv_rmst < alpha_level, na.rm = TRUE),
    pow_rah  = mean(pv_rah  < alpha_level, na.rm = TRUE)
  )
}

compute_ere_triple_ph <- function(shape, scale0, scale1, lambda_cens,
                                   tau_l, tau_u, n, B, seed,
                                   stats_path = NULL, metadata = NULL,
                                   progress_every = NULL,
                                   return_stats = FALSE) {
  replicate_seeds <- make_replicate_seeds(seed, B)
  stats <- data.frame(
    replicate = seq_len(B),
    seed      = replicate_seeds,
    st_cox    = NA_real_,
    st_rmst   = NA_real_,
    st_rah    = NA_real_
  )
  if (is.null(progress_every) && B > 300 && !is.null(stats_path)) {
    progress_every <- 100L
  }
  for (i in seq_len(B)) {
    set.seed(replicate_seeds[i])
    dat <- gen_weibull_tian(n, n, shape, scale0, scale1,
                            lambda_cens, tau_l, tau_u)
    stats$st_cox[i]  <- cox_stat(dat)
    stats$st_rmst[i] <- rmst_stat(dat, TAU)
    stats$st_rah[i]  <- rah_stat(dat, TAU)
    if (!is.null(progress_every) && !is.null(stats_path) &&
        i %% progress_every == 0L) {
      write_mc_stats(stats[seq_len(i), ], stats_path, metadata)
    }
  }
  write_mc_stats(stats, stats_path, metadata)
  out <- compute_ere_from_stats(stats)
  if (return_stats) out$stats <- stats
  out
}

compute_ere_triple <- function(shape, scale0, alpha_fn, lambda_cens,
                                tau_l, tau_u, n, B, seed,
                                stats_path = NULL, metadata = NULL,
                                progress_every = NULL,
                                return_stats = FALSE) {
  replicate_seeds <- make_replicate_seeds(seed, B)
  stats <- data.frame(
    replicate = seq_len(B),
    seed      = replicate_seeds,
    st_cox    = NA_real_,
    st_rmst   = NA_real_,
    st_rah    = NA_real_
  )
  if (is.null(progress_every) && B > 300 && !is.null(stats_path)) {
    progress_every <- 100L
  }
  for (i in seq_len(B)) {
    set.seed(replicate_seeds[i])
    dat <- gen_nonph_tian(n, n, shape, scale0, alpha_fn,
                          lambda_cens, tau_l, tau_u)
    stats$st_cox[i]  <- cox_stat(dat)
    stats$st_rmst[i] <- rmst_stat(dat, TAU)
    stats$st_rah[i]  <- rah_stat(dat, TAU)
    if (!is.null(progress_every) && !is.null(stats_path) &&
        i %% progress_every == 0L) {
      write_mc_stats(stats[seq_len(i), ], stats_path, metadata)
    }
  }
  write_mc_stats(stats, stats_path, metadata)
  out <- compute_ere_from_stats(stats)
  if (return_stats) out$stats <- stats
  out
}

#-------------------------------------------------------------
# Print helpers
#-------------------------------------------------------------
print_header <- function(title) {
  cat("\n", strrep("=", 70), "\n", title, "\n", strrep("=", 70), "\n", sep = "")
  cat(sprintf("%-28s  %9s %9s %9s  %9s %9s %9s\n",
              "Scenario",
              "ARE R/C", "ARE A/C", "ARE A/R",
              "ERE R/C", "ERE A/C", "ERE A/R"))
  cat(strrep("-", 86), "\n")
}

print_row <- function(label, are, ere) {
  cat(sprintf("%-28s  %9.3f %9.3f %9.3f  %9.3f %9.3f %9.3f\n",
              label,
              are$are_rmst_cox, are$are_ahsw_cox, are$are_ahsw_rmst,
              ere$ere_rmst_cox, ere$ere_ahsw_cox, ere$ere_ahsw_rmst))
}

rows_to_df <- function(rows) {
  do.call(rbind, lapply(rows, function(r) as.data.frame(r, stringsAsFactors = FALSE)))
}
