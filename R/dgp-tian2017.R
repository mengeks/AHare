#=============================================================
# dgp-tian2017.R
# Shared data-generating process (DGP) for Tian et al. (2017) simulations.
# Sourced by: sim02-tian2017.R, sim02a-replicate-table1.R, gen-dgp-figure.R
#=============================================================

# --- Study-wide constants (paper Section 4.2) ---
SHAPE <- 0.826   # Weibull shape; decreasing hazard h0(u) = a0 * u^(-0.174)
TAU   <- 40      # RMST analysis horizon t
TAU_H <- 42.5    # Cox/HR analysis horizon tH
TAU_L <- 24      # uniform censoring lower bound
TAU_U <- 43      # uniform censoring upper bound
t_M   <- TAU_H / 2   # midpoint used in alpha functions (= 21.25)

#-------------------------------------------------------------
# weibull_scale: solve S(t; scale) = target_S for scale
#   S(t) = exp(-(t/scale)^shape)  =>  scale = t / (-log(target_S))^(1/shape)
#-------------------------------------------------------------
weibull_scale <- function(target_S, t, shape) {
  t / (-log(target_S))^(1 / shape)
}

#-------------------------------------------------------------
# gen_arm: one arm — Weibull event times + mixed censoring
#-------------------------------------------------------------
gen_arm <- function(n, shape, scale, lambda_cens, tau_l, tau_u) {
  T_ev   <- scale * (-log(runif(n)))^(1 / shape)
  C_time <- pmin(rexp(n, lambda_cens), runif(n, tau_l, tau_u))
  time   <- pmin(T_ev, C_time)
  status <- as.integer(T_ev <= C_time)
  data.frame(time = time, status = status)
}

#-------------------------------------------------------------
# gen_weibull_tian: two-arm PH dataset (Weibull event times)
#-------------------------------------------------------------
gen_weibull_tian <- function(n0, n1, shape, scale0, scale1,
                              lambda_cens, tau_l, tau_u) {
  d0 <- gen_arm(n0, shape, scale0, lambda_cens, tau_l, tau_u)
  d1 <- gen_arm(n1, shape, scale1, lambda_cens, tau_l, tau_u)
  data.frame(
    time   = c(d0$time,   d1$time),
    status = c(d0$status, d1$status),
    arm    = c(rep(0L, n0), rep(1L, n1))
  )
}

#-------------------------------------------------------------
# gen_nonph_tian: two-arm non-PH dataset via inverse-CDF
#   h1(t) = h0(t) * exp(alpha_fn(t)); cumulative hazards integrated numerically
#-------------------------------------------------------------
gen_nonph_tian <- function(n0, n1, shape, scale0, alpha_fn,
                            lambda_cens, tau_l, tau_u,
                            t_max = 500, n_grid = 5000) {
  t_grid <- seq(0, t_max, length.out = n_grid + 1)
  dt     <- t_grid[2] - t_grid[1]

  h0 <- (shape / scale0) * (t_grid / scale0)^(shape - 1)
  h0[1] <- 0
  h1 <- h0 * exp(alpha_fn(t_grid))

  S0 <- exp(-cumsum(h0) * dt)
  S1 <- exp(-cumsum(h1) * dt)

  inv_surv <- function(S_grid, u_vec) {
    approx(S_grid, t_grid, xout = u_vec, rule = 2)$y
  }

  gen_arm_nonph <- function(n, S_grid) {
    T_ev   <- inv_surv(S_grid, runif(n))
    C_time <- pmin(rexp(n, lambda_cens), runif(n, tau_l, tau_u))
    time   <- pmin(T_ev, C_time)
    status <- as.integer(T_ev <= C_time)
    list(time = time, status = status)
  }

  d0 <- gen_arm_nonph(n0, S0)
  d1 <- gen_arm_nonph(n1, S1)
  data.frame(
    time   = c(d0$time,   d1$time),
    status = c(d0$status, d1$status),
    arm    = c(rep(0L, n0), rep(1L, n1))
  )
}

#-------------------------------------------------------------
# calibrate_c: find constant c such that mean(alpha_fn_c(t, c)) == target
#   Used for Cases 2 and 3 where c controls the overall effect size.
#-------------------------------------------------------------
calibrate_c <- function(alpha_fn_c, target = log(0.70),
                         tau = TAU, step = 0.1) {
  t_grid <- seq(0, tau, by = step)
  uniroot(function(c_val) mean(alpha_fn_c(t_grid, c_val)) - target,
          interval = c(1e-4, 10))$root
}

#-------------------------------------------------------------
# make_alpha_*: factory functions returning alpha(u) for each case
#   Case 1 (crossing hazards): alpha(u) = log(0.46) + (u/t_M)^s
#   Case 2 (fading benefit):   alpha(u) = -c * max(t_M - u, 0)^s, c calibrated
#   Case 3 (delayed benefit):  alpha(u) = -c * u^s, c calibrated
#-------------------------------------------------------------
make_alpha_case1 <- function(s, t_m = t_M) {
  function(u) log(0.46) + (u / t_m)^s
}

make_alpha_case2 <- function(s, t_m = t_M, tau = TAU) {
  c_fn  <- function(u, c) -c * pmax(t_m - u, 0)^s
  c_val <- calibrate_c(c_fn, tau = tau)
  function(u) c_fn(u, c_val)
}

make_alpha_case3 <- function(s, tau = TAU) {
  c_fn  <- function(u, c) -c * u^s
  c_val <- calibrate_c(c_fn, tau = tau)
  function(u) c_fn(u, c_val)
}

#-------------------------------------------------------------
# compute_surv: theoretical S0, S1, HR for a given alpha_fn (plotting use)
#-------------------------------------------------------------
compute_surv <- function(alpha_fn, t_grid, shape, scale0) {
  dt <- t_grid[2] - t_grid[1]
  h0 <- (shape / scale0) * (t_grid / scale0)^(shape - 1)
  h1 <- h0 * exp(alpha_fn(t_grid))
  list(
    S0 = exp(-cumsum(h0) * dt),
    S1 = exp(-cumsum(h1) * dt),
    hr = exp(alpha_fn(t_grid))
  )
}
