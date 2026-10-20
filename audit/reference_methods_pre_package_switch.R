# Frozen pre-package-switch formulas, for regression/audit only.
# Never sourced by run_all.R or an experiment. Source into a separate env.
rmst_from_km <- function(km, tau) {
  tt <- c(0, km$time)
  ss <- c(1, km$surv)
  keep <- tt <= tau
  tt <- c(tt[keep], tau)
  ss <- c(ss[keep], summary(km, times = tau, extend = TRUE)$surv)
  sum(diff(tt) * ss[-length(ss)])
}

rah_components <- function(dat, tau, km0 = NULL, km1 = NULL) {
  if (is.null(km0)) km0 <- survfit(Surv(time, status) ~ 1, data = dat[dat$arm == 0, ])
  if (is.null(km1)) km1 <- survfit(Surv(time, status) ~ 1, data = dat[dat$arm == 1, ])
  F0 <- 1 - summary(km0, times = tau, extend = TRUE)$surv
  F1 <- 1 - summary(km1, times = tau, extend = TRUE)$surv
  R0 <- rmst_from_km(km0, tau)
  R1 <- rmst_from_km(km1, tau)
  stat <- log(F1 / R1) - log(F0 / R0)
  variance_arm <- function(km, F, R) {
    idx <- km$time <= tau & km$n.event > 0
    if (!any(idx)) return(0)
    Rt <- vapply(km$time[idx], function(t) rmst_from_km(km, t), numeric(1))
    phi <- 1 / F - Rt / R
    sum(phi^2 * km$n.event[idx] / km$n.risk[idx]^2)
  }
  variance <- variance_arm(km0, F0, R0) + variance_arm(km1, F1, R1)
  list(stat = stat, se = sqrt(variance), F0 = F0, F1 = F1, R0 = R0, R1 = R1)
}

test_statistics <- function(dat, tau, need_power = FALSE) {
  dat <- truncate_at_tau(dat, tau)
  tryCatch({
    cox <- coxph(Surv(time, status) ~ arm, data = dat)
    km0 <- survfit(Surv(time, status) ~ 1, data = dat[dat$arm == 0, ])
    km1 <- survfit(Surv(time, status) ~ 1, data = dat[dat$arm == 1, ])
    r0 <- rmst_from_km(km0, tau)
    r1 <- rmst_from_km(km1, tau)
    ra <- rah_components(dat, tau, km0, km1)
    ans <- c(u_cox = unname(coef(cox)[[1]]), u_drmst = r1 - r0, u_rah = ra$stat)
    if (need_power) {
      cs <- summary(cox)
      rm <- survRM2::rmst2(dat$time, dat$status, dat$arm, tau = tau)
      ans <- c(ans, p_cox = unname(cs$coefficients[1, 5]),
               p_drmst = unname(rm$unadjusted.result[1, 4]),
               p_rah = 2 * pnorm(-abs(ra$stat / ra$se)))
    }
    ans
  }, error = function(e) rep(NA_real_, if (need_power) 6L else 3L))
}
