weibull_scale <- function(target_survival, time, shape) {
  time / (-log(target_survival))^(1 / shape)
}

weibull_hazard <- function(t, shape, scale) {
  tt <- pmax(t, 1e-8)
  (shape / scale) * (tt / scale)^(shape - 1)
}

weibull_survival <- function(t, shape, scale) exp(-(t / scale)^shape)

censor_survival <- function(t, lambda, uniform_range) {
  lo <- uniform_range[[1]]
  hi <- uniform_range[[2]]
  exp(-lambda * t) * pmax(hi - pmax(t, lo), 0) / (hi - lo)
}

calibrate_effect <- function(builder, tau, target = log(0.70), step = 0.01) {
  grid <- seq(0, tau, by = step)
  uniroot(function(c0) mean(builder(grid, c0)) - target,
          interval = c(1e-8, 100))$root
}

alpha_ph <- function(hr) {
  force(hr)
  function(t) rep(log(hr), length(t))
}

alpha_crossing <- function(s = 1, t_m = 43) {
  force(s); force(t_m)
  function(t) log(0.46) + (t / t_m)^s
}

alpha_fading <- function(tau, s = 1, t_m = 21.25, target = log(0.70)) {
  builder <- function(t, c0) -c0 * pmax(t_m - t, 0)^s
  c0 <- calibrate_effect(builder, tau, target)
  function(t) builder(t, c0)
}

alpha_delayed <- function(tau, s = 1, target = log(0.70)) {
  builder <- function(t, c0) -c0 * t^s
  c0 <- calibrate_effect(builder, tau, target)
  function(t) builder(t, c0)
}

gen_weibull_arm <- function(n, shape, scale, lambda_c, uniform_range) {
  event <- scale * (-log(runif(n)))^(1 / shape)
  censor <- pmin(rexp(n, lambda_c),
                 runif(n, uniform_range[[1]], uniform_range[[2]]))
  data.frame(time = pmin(event, censor), status = as.integer(event <= censor))
}

gen_ph_dataset <- function(n, shape, scale0, scale1, lambda_c, uniform_range) {
  d0 <- gen_weibull_arm(n, shape, scale0, lambda_c, uniform_range)
  d1 <- gen_weibull_arm(n, shape, scale1, lambda_c, uniform_range)
  data.frame(time = c(d0$time, d1$time), status = c(d0$status, d1$status),
             arm = rep(0:1, each = n))
}

make_nonph_survival_grid <- function(shape, scale0, alpha_fn,
                                     max_time = 500, n_grid = 10000) {
  t <- seq(0, max_time, length.out = n_grid + 1L)
  dt <- t[[2]] - t[[1]]
  h0 <- weibull_hazard(t, shape, scale0); h0[[1]] <- 0
  h1 <- h0 * exp(alpha_fn(t))
  list(t = t, S0 = exp(-cumsum(h0) * dt), S1 = exp(-cumsum(h1) * dt))
}

gen_nonph_dataset <- function(n, shape, scale0, alpha_fn, lambda_c,
                              uniform_range, survival_grid = NULL) {
  if (is.null(survival_grid)) {
    survival_grid <- make_nonph_survival_grid(shape, scale0, alpha_fn)
  }
  draw_arm <- function(S) {
    event <- approx(rev(S), rev(survival_grid$t), xout = runif(n),
                    rule = 2, ties = "ordered")$y
    censor <- pmin(rexp(n, lambda_c),
                   runif(n, uniform_range[[1]], uniform_range[[2]]))
    data.frame(time = pmin(event, censor), status = as.integer(event <= censor))
  }
  d0 <- draw_arm(survival_grid$S0)
  d1 <- draw_arm(survival_grid$S1)
  data.frame(time = c(d0$time, d1$time), status = c(d0$status, d1$status),
             arm = rep(0:1, each = n))
}

theoretical_survival <- function(shape, scale0, alpha_fn, tau, step = 0.05) {
  t <- seq(step, tau, by = step)
  h0 <- weibull_hazard(t, shape, scale0)
  h1 <- h0 * exp(alpha_fn(t))
  list(t = t, hr = exp(alpha_fn(t)),
       S0 = exp(-cumsum(h0) * step), S1 = exp(-cumsum(h1) * step))
}

