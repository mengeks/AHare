# Tests for helper functions in ../sim02-tian2017.R
# Run from AHare/ or from AHare/tests/

library(survival)

if (!exists("weibull_scale")) {
  # source just the function definitions without running the scenario loops
  e <- new.env()
  # define functions directly
  weibull_scale <- function(target_S, t, shape) t / (-log(target_S))^(1 / shape)
  gen_weibull_tian <- function(n0, n1, shape, scale0, scale1, lambda_cens, tau_l, tau_u) {
    gen_arm <- function(n, scale) {
      T_event <- scale * (-log(runif(n)))^(1 / shape)
      C_exp   <- rexp(n, rate = lambda_cens)
      C_unif  <- runif(n, min = tau_l, max = tau_u)
      C_time  <- pmin(C_exp, C_unif)
      time    <- pmin(T_event, C_time)
      status  <- as.integer(T_event <= C_time)
      list(time = time, status = status)
    }
    d0 <- gen_arm(n0, scale0); d1 <- gen_arm(n1, scale1)
    data.frame(time=c(d0$time, d1$time), status=c(d0$status, d1$status),
               arm=c(rep(0,n0), rep(1,n1)))
  }
  rmst_from_km <- function(km, tau) {
    tt <- c(0, km$time); ss <- c(1, km$surv)
    idx <- tt <= tau
    tt  <- c(tt[idx], tau)
    ss  <- c(ss[idx], approx(km$time, km$surv, tau, rule=2)$y)
    sum(diff(tt) * ss[-length(ss)])
  }
}

source_first <- function(paths) {
  for (path in paths) {
    if (file.exists(path)) {
      source(path)
      return(invisible(path))
    }
  }
  stop("Could not find any of: ", paste(paths, collapse = ", "))
}

if (!exists("ares_v2")) {
  source_first(c("R/fun-ares-v2.R", "../R/fun-ares-v2.R"))
}

theory_are_tian <- function(shape, scale0, alpha_fn, lambda_cens, tau_l, tau_u,
                             tau = 40, increment = 0.01) {
  x <- seq(0, tau, by = increment); k <- length(x)
  h0 <- (shape / scale0) * (x / scale0)^(shape - 1); h0[1] <- 0
  P <- list(tau=tau, increment=increment, x=x, k=k, p1=0.5,
            lambda_t=h0, alpha_t=alpha_fn(x),
            lambda_cens=lambda_cens, cens_tau_l=tau_l, cens_tau_u=tau_u)
  ares_v2(P)
}

pass <- function(msg) cat("  PASS:", msg, "\n")
fail <- function(msg) { cat("  FAIL:", msg, "\n"); stop(msg) }

cat("\n=== Tests for sim02 helpers ===\n")

# T1: weibull_scale round-trip
sc <- weibull_scale(0.3, 42.5, 0.826)
if (abs(exp(-(42.5/sc)^0.826) - 0.3) < 1e-6) pass("T1: weibull_scale round-trip S(tau_H)=0.3") else
  fail("T1: weibull_scale round-trip failed")

# T2: weibull_scale monotone
if (weibull_scale(0.7, 42.5, 0.826) > weibull_scale(0.1, 42.5, 0.826)) pass("T2: weibull_scale monotone in target_S") else
  fail("T2: weibull_scale not monotone")

# T3: rmst_from_km in [0, tau]
set.seed(1)
sc0 <- weibull_scale(0.3, 42.5, 0.826)
dat <- gen_weibull_tian(200, 200, 0.826, sc0, sc0, 0.0006, 24, 43)
km  <- survfit(Surv(time, status) ~ 1, data = dat[dat$arm == 0, ])
rv  <- rmst_from_km(km, 40)
if (rv >= 0 && rv <= 40) pass("T3: rmst_from_km in [0, 40]") else
  fail(sprintf("T3: value %.3f out of range", rv))

# T4: rmst_from_km monotone in tau
rv20 <- rmst_from_km(km, 20)
if (rv20 < rv) pass("T4: rmst_from_km monotone in tau") else
  fail("T4: rmst_from_km not monotone")

# T5: theory_are_tian positive efficiencies under PH
ft <- theory_are_tian(0.826, sc0, function(u) rep(log(0.70), length(u)), 0.0006, 24, 43)
if (all(ft$aeff > 0)) pass("T5: theory_are_tian all efficiencies > 0 under PH") else
  fail("T5: some efficiency <= 0")

# T6: theory_are_tian unit diagonal
if (all(abs(diag(ft$ares) - 1) < 1e-9)) pass("T6: theory_are_tian ARE diagonal = 1") else
  fail("T6: ARE diagonal not 1")

cat("\nAll tests passed.\n\n")
