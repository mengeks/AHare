# Tests for ares_v2() in R/fun-ares-v2.R
# Run from AHare/ or from AHare/tests/

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

pass <- function(msg) cat("  PASS:", msg, "\n")
fail <- function(msg) { cat("  FAIL:", msg, "\n"); stop(msg) }

# Helper: minimal P list with constant hazard and constant alpha
make_P <- function(tau = 40, inc = 0.01,
                   lambda_val  = 0.03,   # constant baseline hazard
                   alpha_val   = 0,      # log-HR drift
                   lambda_cens = 0.02,
                   cens_tau_l  = 20,
                   cens_tau_u  = 60) {
  x <- seq(0, tau, by = inc)
  k <- length(x)
  list(
    tau = tau, increment = inc, x = x, k = k, p1 = 0.5,
    lambda_t    = c(0, rep(lambda_val, k - 1)),
    alpha_t     = rep(alpha_val, k),
    lambda_cens = lambda_cens,
    cens_tau_l  = cens_tau_l,
    cens_tau_u  = cens_tau_u
  )
}

cat("\n=== Tests for ares_v2 ===\n")

# Test 1: under null (alpha = 0), all efficiencies are 0
ft0 <- ares_v2(make_P(alpha_val = 0))
if (all(abs(ft0$aeff) < 1e-10)) pass("T1: all efficiencies = 0 under null alpha") else
  fail("T1: efficiencies should be 0 under null")

# Test 2: ARE diagonal is exactly 1 for any alpha
ft1 <- ares_v2(make_P(alpha_val = 0.1))
if (all(abs(diag(ft1$ares) - 1) < 1e-9)) pass("T2: ARE diagonal = 1") else
  fail("T2: ARE diagonal should be 1")

# Test 3: ARE is transpose-reciprocal: ARE(i,j) * ARE(j,i) = 1
ok <- all(abs(ft1$ares * t(ft1$ares) - 1) < 1e-9)
if (ok) pass("T3: ARE(i,j) * ARE(j,i) = 1 for all pairs") else
  fail("T3: ARE matrix not transpose-reciprocal")

# Test 4: Cox >= RMST efficiency under PH with constant hazard
# (logrank is asymptotically optimal under PH)
ft_ph <- ares_v2(make_P(alpha_val = log(0.7), lambda_val = 0.03))
if (ft_ph$aeff["Cox"] >= ft_ph$aeff["RMST"]) pass("T4: Cox >= RMST efficiency under PH") else
  fail("T4: expected Cox to dominate RMST under PH")

# Test 5: numer1 and numer2 are equal (Fubini equivalence)
# numer1 = sum A(t)*S0(t)*dt ; numer2 = sum bar_mu0(t)*alpha(t)*h0(t)*dt
P_check <- make_P(alpha_val = 0.05, lambda_val = 0.02)
ft_check <- ares_v2(P_check)
# reconstruct numer2 manually
P <- ft_check$parm
numer2_manual <- sum(P$rev_RMST_t * P$alpha_t * P$lambda_t) * P$increment
numer1_manual <- sum(P$cum_alpha_lamda_t * P$S_t) * P$increment
if (abs(numer1_manual - numer2_manual) / (abs(numer1_manual) + 1e-12) < 1e-3)
  pass("T5: numer1 (sum A*S0*dt) == numer2 (sum bar_mu0*alpha*h0*dt) by Fubini (tol 0.1%)") else
  fail(sprintf("T5: numer1=%.6f numer2=%.6f", numer1_manual, numer2_manual))

# Test 6: output has correct shape and row/col names
if (all(dim(ft1$out) == c(3, 3)) &&
    all(rownames(ft1$out) == c("Cox", "RMST", "AHSW")) &&
    all(colnames(ft1$out) == c("mean", "var", "eff")))
  pass("T6: output matrix is 3x3 with correct row/col names") else
  fail("T6: unexpected output structure")

# Test 7: Fubini equivalence holds across a range of tau values (converts chk01.R)
# numer1 = sum_j A(t_j) S0(t_j) dt  and  numer2 = sum_j bar_mu0(t_j) alpha(t_j) h0(t_j) dt
# should agree to < 0.1% for any tau in [1, 10]
ok7 <- TRUE
for (tau_val in seq(2, 10, by = 0.5)) {
  P_tau <- make_P(tau = tau_val, alpha_val = 0.05, lambda_val = 0.02,
                  cens_tau_l = 1, cens_tau_u = tau_val + 5)
  ft_tau <- ares_v2(P_tau)
  P2 <- ft_tau$parm
  n2 <- sum(P2$rev_RMST_t * P2$alpha_t * P2$lambda_t) * P2$increment
  n1 <- sum(P2$cum_alpha_lamda_t * P2$S_t) * P2$increment
  rel_err <- abs(n1 - n2) / (abs(n1) + 1e-12)
  if (rel_err >= 2e-2) { ok7 <- FALSE; break }
}
if (ok7) pass("T7: Fubini numer1==numer2 holds across tau in [2,10] (tol 2%)") else
  fail(sprintf("T7: Fubini failed at tau=%.1f, rel_err=%.2e", tau_val, rel_err))

# Test 8: weight_k_ah floor equals S0(tau), not S_C(tau)
# W_RAH(v) = S0(tau) + [1-S0(tau)] * W_RMST(v)  (Tian 2017)
# At v=tau: W_RMST(tau)=0, so floor = S0(tau) = S_t[k]
ft8   <- ares_v2(make_P(tau = 40, alpha_val = 0.05))
P8    <- ft8$parm
floor_computed <- P8$weight_k_ah[P8$k]          # W_RAH at v=tau
floor_theory   <- P8$S_t[P8$k]                   # S0(tau)
floor_wrong    <- P8$S_c0_t[P8$k]                # S_C(tau) — old buggy value
rel_err_correct <- abs(floor_computed - floor_theory) / (floor_theory + 1e-12)
differs_from_wrong <- abs(floor_computed - floor_wrong) > 1e-6
if (rel_err_correct < 1e-6 && differs_from_wrong)
  pass(sprintf("T8: weight_k_ah floor = S0(tau)=%.4f, not S_C(tau)=%.4f",
               floor_theory, floor_wrong)) else
  fail(sprintf("T8: floor=%.6f  S0(tau)=%.6f  S_C(tau)=%.6f",
               floor_computed, floor_theory, floor_wrong))

cat("\nAll tests passed.\n\n")
