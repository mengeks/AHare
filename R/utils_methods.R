suppressPackageStartupMessages({
  library(survival)
  library(survRM2)
  library(survAH)
})

truncate_at_tau <- function(dat, tau) {
  after <- dat$time > tau
  dat$status[after] <- 0L
  dat$time[after] <- tau
  dat
}

rah_components <- function(dat, tau) {
  arm_summary <- function(z) {
    # Match the per-arm near-tie correction already applied by survfit
    # (and survRM2's KM core), instead of switching the old KM convention.
    z$time <- survival::aeqSurv(Surv(z$time, z$status))[, "time"]
    # ah1 prints a diagnostic for a KM tail extended to tau. Capture only
    # that printed text, not warnings/errors; do not change tau or the data.
    if (max(z$time) < tau) {
      invisible(capture.output(fit <- survAH::ah1(z$time, z$status, tau = tau)))
    } else {
      fit <- survAH::ah1(z$time, z$status, tau = tau)
    }
    # Legacy RAH point contrasts use the KM integral even at S(tau)=0.
    fit$result1
  }
  a0 <- arm_summary(dat[dat$arm == 0, ])
  a1 <- arm_summary(dat[dat$arm == 1, ])
  valid <- all(is.finite(c(a0["F(tau)", "Est"], a1["F(tau)", "Est"],
                          a0["RMST(tau)", "Est"], a1["RMST(tau)", "Est"]))) &&
    all(c(a0["F(tau)", "Est"], a1["F(tau)", "Est"],
          a0["RMST(tau)", "Est"], a1["RMST(tau)", "Est"]) > 0)
  list(stat = if (valid)
         unname(a1["AH(tau)", "log(Est)"] - a0["AH(tau)", "log(Est)"]) else NA_real_,
       se = sqrt(a0["AH(tau)", "SE(log(Est))"]^2 +
                   a1["AH(tau)", "SE(log(Est))"]^2),
       F0 = a0["F(tau)", "Est"], F1 = a1["F(tau)", "Est"],
       R0 = a0["RMST(tau)", "Est"], R1 = a1["RMST(tau)", "Est"])
}

test_statistics <- function(dat, tau, need_power = FALSE,
                            cox_power_test = c("score", "wald"),
                            rah_power_method = c("ah1", "ah2")) {
  cox_power_test <- match.arg(cox_power_test)
  rah_power_method <- match.arg(rah_power_method)
  # Only Cox input changes from the legacy design. RMST/RAH receive the
  # original follow-up and their original tau-based package calculations.
  cox <- tryCatch(coxph(Surv(time, status) ~ arm,
                       data = truncate_at_tau(dat, tau)), error = function(e) NULL)
  rm <- tryCatch(survRM2::rmst2(dat$time, dat$status, dat$arm, tau = tau),
                 error = function(e) NULL)
  ra <- tryCatch(rah_components(dat, tau), error = function(e) NULL)
  # Legacy methods fail independently: RMST's support rejection must not
  # discard a finite Cox or RAH statistic from the same simulated dataset.
  ans <- c(u_cox = if (is.null(cox)) NA_real_ else unname(coef(cox)[[1]]),
           u_drmst = if (is.null(rm)) NA_real_ else unname(rm$unadjusted.result[1, 1]),
           u_rah = if (is.null(ra)) NA_real_ else ra$stat)
  if (need_power) {
    p_cox <- if (is.null(cox)) NA_real_ else {
      cs <- summary(cox)
      if (cox_power_test == "score") unname(cs$sctest["pvalue"]) else
        unname(cs$coefficients[1, 5])
    }
    p_rah <- if (rah_power_method == "ah2") {
      tryCatch({
        # Silence only package-printed tail diagnostics, not warnings/errors.
        invisible(capture.output(fit <- suppressMessages(survAH::ah2(
          dat$time, dat$status, dat$arm, tau = tau))))
        fit$rah[1, "P-value"]
      }, error = function(e) NA_real_)
    } else if (is.null(ra) || !is.finite(ra$stat) ||
               !is.finite(ra$se) || ra$se <= 0) NA_real_ else
      2 * pnorm(-abs(ra$stat / ra$se))
    ans <- c(ans, p_cox = p_cox,
             p_drmst = if (is.null(rm)) NA_real_ else unname(rm$unadjusted.result[1, 4]),
             p_rah = unname(p_rah))
  }
  ans
}

efficacy <- function(x) {
  x <- x[is.finite(x)]
  if (length(x) < 2L || var(x) <= 0) return(NA_real_)
  mean(x)^2 / var(x)
}

summarize_mc <- function(stats, alpha_level = 0.05) {
  eff <- c(Cox = efficacy(stats[, "u_cox"]),
           DRMST = efficacy(stats[, "u_drmst"]),
           RAH = efficacy(stats[, "u_rah"]))
  power <- if ("p_cox" %in% colnames(stats)) {
    c(Cox = mean(stats[, "p_cox"] < alpha_level, na.rm = TRUE),
      DRMST = mean(stats[, "p_drmst"] < alpha_level, na.rm = TRUE),
      RAH = mean(stats[, "p_rah"] < alpha_level, na.rm = TRUE))
  } else c(Cox = NA_real_, DRMST = NA_real_, RAH = NA_real_)
  list(efficacy = eff, power = power,
       ere = c(drmst_cox = eff[["DRMST"]] / eff[["Cox"]],
               rah_cox = eff[["RAH"]] / eff[["Cox"]],
               rah_drmst = eff[["RAH"]] / eff[["DRMST"]]))
}

simulate_methods <- function(B, seed, generator, tau, alpha_level = 0.05,
                             progress = TRUE, need_power = FALSE, workers = 1L,
                             cox_power_test = "score", rah_power_method = "ah1") {
  cols <- c("u_cox", "u_drmst", "u_rah")
  if (need_power) cols <- c(cols, "p_cox", "p_drmst", "p_rah")
  out <- matrix(NA_real_, nrow = B, ncol = length(cols),
                dimnames = list(NULL, cols))
  one <- function(i) {
    set.seed(seed + i - 1L)
    test_statistics(generator(), tau, need_power, cox_power_test, rah_power_method)
  }
  workers <- max(1L, as.integer(workers))
  if (workers > 1L && .Platform$OS.type != "windows") {
    vals <- parallel::mclapply(seq_len(B), one, mc.cores = workers,
                               mc.preschedule = TRUE)
    out[,] <- do.call(rbind, vals)
    if (progress) message(sprintf("  %d/%d (%d workers)", B, B, workers))
  } else {
    for (i in seq_len(B)) {
      out[i, ] <- one(i)
      if (progress && (i %% 250L == 0L || i == B)) {
        message(sprintf("  %d/%d", i, B))
      }
    }
  }
  summarize_mc(out, alpha_level)
}

observed_test_results <- function(dat, tau) {
  dat <- truncate_at_tau(dat, tau)
  cox <- coxph(Surv(time, status) ~ arm, data = dat)
  cs <- summary(cox)
  rm <- rmst2(dat$time, dat$status, dat$arm, tau = tau, alpha = 0.05)
  ra <- suppressMessages(ah2(time = dat$time, status = dat$status,
                             arm = dat$arm, tau = tau, conf.int = 0.95))
  data.frame(
    method = c("Cox", "D-RMST", "RAH"),
    estimate = c(exp(coef(cox)[[1]]), rm$unadjusted.result[1, 1], ra$rah[1, "Est."]),
    ci_lo = c(exp(confint(cox))[1], rm$unadjusted.result[1, 2], ra$rah[1, "Lower 0.95"]),
    ci_hi = c(exp(confint(cox))[2], rm$unadjusted.result[1, 3], ra$rah[1, "Upper 0.95"]),
    pval = c(cs$coefficients[1, 5], rm$unadjusted.result[1, 4], ra$rah[1, "P-value"]),
    tau = tau,
    stringsAsFactors = FALSE
  )
}
