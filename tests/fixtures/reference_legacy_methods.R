# Independent legacy formulas, for regression tests only.
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

# Frozen 27Sep methods: only Cox input receives the approved tau truncation.
test_statistics <- function(dat, tau, need_power = FALSE,
                            cox_power_test = "score", rah_power_method = "ah1") {
  cd <- dat
  after <- cd$time > tau
  cd$status[after] <- 0L
  cd$time[after] <- tau
  ans <- c(u_cox = unname(cox_stat(cd)), u_drmst = rmst_stat(dat, tau),
           u_rah = rah_stat(dat, tau))
  if (need_power) {
    cp <- if (cox_power_test == "score") unname(cox_pval(cd)) else
      tryCatch(unname(summary(coxph(Surv(time, status) ~ arm, data = cd))$coefficients[1, 5]),
               error = function(e) NA_real_)
    rp <- if (rah_power_method == "ah1") rah_pval(dat, tau) else
      tryCatch(suppressMessages(survAH::ah2(dat$time, dat$status, dat$arm, tau = tau))$rah[1, "P-value"],
               error = function(e) NA_real_)
    ans <- c(ans, p_cox = cp, p_drmst = rmst_pval(dat, tau), p_rah = unname(rp))
  }
  ans
}
