# Current package-backed calculations versus the actual legacy methods.
local({
  reference <- new.env(parent = globalenv())
  sys.source("tests/fixtures/reference_legacy_methods.R", envir = reference)
  legacy_dgp <- new.env(parent = globalenv())
  sys.source("tests/fixtures/reference_legacy_dgp.R", envir = legacy_dgp)
  max_error <- 0
  check_vector <- function(old, new) {
    stopifnot(length(old) == length(new), identical(is.na(old), is.na(new)),
              identical(is.infinite(old), is.infinite(new)))
    finite <- is.finite(old)
    if (any(finite)) {
      err <- max(abs(old[finite] - new[finite]))
      max_error <<- max(max_error, err)
      stopifnot(err < 1e-10)
    }
  }
  check_sample <- function(dat, tau) {
    for (power in c(FALSE, TRUE)) for (profile in c("main", "checkmate")) {
      ct <- if (profile == "main") "score" else "wald"
      rt <- if (profile == "main") "ah1" else "ah2"
      check_vector(suppressWarnings(reference$test_statistics(dat, tau, power, ct, rt)),
                   suppressWarnings(test_statistics(dat, tau, power, ct, rt)))
    }
  }
  for (s0 in c(.1, .5, .9)) for (lc in c(.0006, .025)) {
    for (i in seq_len(3)) {
      seed <- 310000 + round(s0 * 1000) + round(lc * 100000) + i
      scale0 <- weibull_scale(s0, 40, .826)
      set.seed(seed)
      dat <- gen_ph_dataset(150, .826, scale0, scale0 / .7^(1/.826), lc, c(24, 43))
      set.seed(seed)
      old <- legacy_dgp$gen_weibull_tian(150, 150, .826, scale0,
                                        scale0 / .7^(1/.826), lc, 24, 43)
      check_vector(as.matrix(old), as.matrix(dat))
      check_sample(dat, 40)
    }
  }
  for (case in c("fading", "delayed", "crossing")) {
    fn <- switch(case, fading = alpha_fading(40, 1, 43),
                 delayed = alpha_delayed(40), crossing = alpha_crossing())
    old_fn <- switch(case, fading = legacy_dgp$make_alpha_case2(1, t_m = 43),
                     delayed = legacy_dgp$make_alpha_case3(1),
                     crossing = legacy_dgp$make_alpha_case1(1, t_m = 43))
    check_vector(old_fn(seq(0, 40, by = .1)), fn(seq(0, 40, by = .1)))
    scale0 <- weibull_scale(.5, 40, .826)
    set.seed(311111)
    dat <- gen_nonph_dataset(150, .826, scale0, fn, .025, c(24, 43))
    set.seed(311111)
    old <- legacy_dgp$gen_nonph_tian(150, 150, .826, scale0, old_fn, .025, 24, 43)
    check_vector(as.matrix(old), as.matrix(dat))
    check_sample(dat, 40)
  }
  tail <- data.frame(time = c(1, 2, 3, 1.5, 2.5, 3.5),
                     status = rep(c(1L, 0L, 0L), 2), arm = rep(0:1, each = 3))
  check_sample(tail, 5)
  ans <- test_statistics(tail, 5, TRUE)
  stopifnot(is.na(ans[["u_drmst"]]), is.na(ans[["p_drmst"]]),
            all(is.finite(ans[c("u_cox", "u_rah", "p_cox", "p_rah")])))
  zero_survival <- tail
  zero_survival$status[1:3] <- 1L
  check_sample(zero_survival, 3)
  stopifnot(is.finite(test_statistics(zero_survival, 3)[["u_rah"]]),
            is.na(test_statistics(zero_survival, 3, TRUE,
                                 rah_power_method = "ah2")[["p_rah"]]))
  no_events <- tail
  no_events$status[] <- 0L
  check_sample(no_events, 5)
  ties <- tail
  ties$time <- c(1, 2, 2, 1, 2, 3)
  check_sample(ties, 2)
  near_ties <- tail
  near_ties$time <- c(1, 2, 2 + 1e-9, 1.5, 2.5, 3.5)
  near_ties$status[2] <- 1L
  check_sample(near_ties, 3)
  scale0 <- weibull_scale(.5, 40, .826)
  generator <- function() gen_ph_dataset(150, .826, scale0,
                                        scale0 / .7^(1/.826), .025, c(24, 43))
  serial_summary <- simulate_methods(16, 312000, generator, 40,
                                     progress = FALSE, workers = 1)
  parallel_summary <- simulate_methods(16, 312000, generator, 40,
                                       progress = FALSE, workers = 4)
  stopifnot(identical(serial_summary, parallel_summary))
  message(sprintf("Legacy method/DGP equivalence tests passed (max error %.3g).", max_error))
})
