cfg <- yaml::read_yaml("config.yaml")
stopifnot(cfg$simulation$tau == cfg$simulation$cox_tau)
stopifnot(cfg$checkmate057$tau == cfg$checkmate057$cox_tau)
stopifnot(cfg$appendix_tau10$tau == cfg$appendix_tau10$cox_tau)
stopifnot(cfg$simulation$fading_t_m == 43)
stopifnot(identical(as.numeric(unlist(cfg$checkmate057$censoring_uniform)), c(13, 28)))
stopifnot(identical(as.numeric(unlist(cfg$checkmate057$power_n_grid)),
                    seq(100, 500, by = 50)))

required <- file.path("results", c("main_ph.rds", "main_nonph.rds",
  "checkmate_observed.rds", "checkmate_sim.rds", "appendix_hr082.rds",
  "appendix_tau10.rds", "appendix_crossing.rds"))
stopifnot(all(file.exists(required)))

mph <- readRDS("results/main_ph.rds")
mnp <- readRDS("results/main_nonph.rds")
cm <- readRDS("results/checkmate_sim.rds")
h82 <- readRDS("results/appendix_hr082.rds")
stopifnot(all(mnp$scenarios$t_m[mnp$scenarios$case == "fading"] == 43))
first_n80 <- vapply(c("Cox", "DRMST", "RAH"), function(method)
  min(cm$power$n[cm$power[[method]] >= 0.8]), numeric(1))
stopifnot(all(first_n80 %in% unlist(cfg$checkmate057$power_n_grid)))

# Table 2 S0=.50 and Table 3 kappa=.826 are literally the same result rows.
shared <- mph$scenarios[mph$scenarios$shape == .826 & mph$scenarios$s0 == .5, ]
stopifnot(nrow(shared) == 2L)
stopifnot(!anyDuplicated(shared$id))

# Ratio identities from the single theory routine.
check_identities <- function(x, tol = 1e-12) {
  stopifnot(all(abs(x$are_rah_drmst - x$are_rah_cox / x$are_drmst_cox) < tol))
  stopifnot(all(abs(x$cos2_rah / x$cos2_cox - x$are_rah_cox) < tol))
  stopifnot(all(abs(x$cos2_drmst / x$cos2_cox - x$are_drmst_cox) < tol))
  stopifnot(all(abs(x$ere_rah_drmst - x$ere_rah_cox / x$ere_drmst_cox) < tol))
}
check_identities(mph$scenarios)
check_identities(mnp$scenarios)
check_identities(cm$sensitivity)
check_identities(h82$scenarios)
check_identities(readRDS("results/appendix_tau10.rds")$scenarios)
check_identities(readRDS("results/appendix_crossing.rds")$scenarios)

# Table 5 and every Table 7 baseline appearance use one shared row/result.
b <- cm$sensitivity[cm$sensitivity$id == cm$baseline_id, ]
stopifnot(nrow(b) == 1L)
base_views <- cm$sensitivity_views[cm$sensitivity_views$id == cm$baseline_id, ]
stopifnot(nrow(base_views) == 3L)
stopifnot(abs(unname(b$are_rah_cox) -
              unname(cm$baseline_theory$are[["rah_cox"]])) < 1e-12)
stopifnot(abs(unname(b$cos2_rah / b$cos2_cox) -
              unname(b$are_rah_cox)) < 1e-12)

# CheckMate design-stage benchmark: fitted Weibull model, Uniform(13,28),
# dropout .005/month, common tau=24, original .05-month integration grid.
# These rounded reference values are test expectations, not production inputs.
observed_benchmark <- as.numeric(b[c("are_drmst_cox", "are_rah_cox",
  "are_rah_drmst", "cos2_cox", "cos2_drmst", "cos2_rah")])
stopifnot(max(abs(observed_benchmark -
  c(.778, 1.067, 1.372, .603, .469, .643))) < .0005)

# PH ARE is invariant to the magnitude of the constant log-HR.
cols <- c("are_drmst_cox", "are_rah_cox", "are_rah_drmst")
for (cn in c("light", "heavy")) {
  a <- mph$scenarios[mph$scenarios$shape == .826 & mph$scenarios$s0 == .5 & mph$scenarios$censoring == cn, cols]
  b82 <- h82$scenarios[h82$scenarios$shape == .826 & h82$scenarios$s0 == .5 & h82$scenarios$censoring == cn, cols]
  stopifnot(max(abs(a - b82)) < 1e-12)
}

stopifnot(file.exists("output/numbers.tex"))
number_lines <- readLines("output/numbers.tex")
stopifnot(sprintf("\\newcommand{\\CMAdminLower}{%.0f}",
  cfg$checkmate057$censoring_uniform[[1]]) %in% number_lines,
  sprintf("\\newcommand{\\CMAdminUpper}{%.0f}",
  cfg$checkmate057$censoring_uniform[[2]]) %in% number_lines,
  sprintf("\\newcommand{\\CMDropoutRate}{%.3f}",
  cfg$checkmate057$dropout_rate) %in% number_lines,
  sprintf("\\newcommand{\\CMDropoutAnnualPct}{%.0f}",
  100 * (1 - exp(-12 * cfg$checkmate057$dropout_rate))) %in% number_lines)
for (i in seq_along(first_n80)) {
  expected <- sprintf("\\newcommand{\\%s}{%.0f}",
                      c("NPowerCoxCM", "NPowerDrmstCM", "NPowerRahCM")[i], first_n80[i])
  stopifnot(expected %in% number_lines)
}
stopifnot(all(vapply(required, result_is_current, logical(1), cfg = cfg)))
stopifnot(length(list.files("output/tables", pattern = "\\.tex$")) == 11L)
stopifnot(length(list.files("output/figures", pattern = "^figure[1-7].*\\.pdf$")) == 7L)
cat("All consistency assertions passed.\n")
