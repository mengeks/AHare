source("R/fun-ares-v2.R")

theory_result <- function(shape, scale0, alpha_fn, tau, lambda_c,
                          uniform_range, step = 0.01) {
  x <- seq(0, tau, by = step)
  h0 <- weibull_hazard(x, shape, scale0); h0[[1]] <- 0
  P <- list(tau = tau, increment = step, x = x, k = length(x), p1 = 0.5,
            lambda_t = h0, alpha_t = alpha_fn(x), lambda_cens = lambda_c,
            cens_tau_l = uniform_range[[1]], cens_tau_u = uniform_range[[2]])
  ft <- ares_v2(P)
  eff <- ft$aeff
  signal_norm2 <- sum(ft$parm$alpha_t^2 * ft$parm$w_t *
                        ft$parm$lambda_t) * step
  cos2 <- eff / signal_norm2
  list(
    efficiency = eff,
    are = c(drmst_cox = unname(eff[["RMST"]] / eff[["Cox"]]),
            rah_cox = unname(eff[["AHSW"]] / eff[["Cox"]]),
            rah_drmst = unname(eff[["AHSW"]] / eff[["RMST"]])),
    cos2 = c(Cox = unname(cos2[["Cox"]]),
             DRMST = unname(cos2[["RMST"]]),
             RAH = unname(cos2[["AHSW"]])),
    signal_norm2 = signal_norm2,
    grid = data.frame(t = x, S0 = ft$parm$S_t, Sc = ft$parm$S_c0_t,
                      w = ft$parm$w_t, alpha = ft$parm$alpha_t,
                      W_cox = ft$parm$weight_k_cox,
                      W_drmst = ft$parm$weight_k_rmst,
                      W_rah = ft$parm$weight_k_ah)
  )
}

weibull_alpha <- function(shape0, scale0, shape1, scale1) {
  function(t) log(weibull_hazard(t, shape1, scale1) /
                    weibull_hazard(t, shape0, scale0))
}

