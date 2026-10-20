# Final verification relative to the pulled GitHub baseline, not old private runs.
source("R/utils_pipeline.R")
cfg <- read_pipeline_config()
backup <- "../local-history/hajime-censoring-before-20261005-pfkWdM"
stopifnot(all(vapply(file.path("results", paste0(c("checkmate_observed",
  "main_ph", "main_nonph", "checkmate_sim", "appendix_hr082",
  "appendix_tau10", "appendix_crossing"), ".rds")), result_is_current,
  logical(1), cfg = cfg)))
unchanged <- lapply(c("checkmate_observed", "main_ph", "main_nonph",
  "appendix_hr082", "appendix_tau10", "appendix_crossing"), function(name) {
  old <- readRDS(file.path(backup, "github-results", paste0(name, ".rds")))
  new <- readRDS(file.path("results", paste0(name, ".rds")))
  same <- identical(old[setdiff(names(old), "metadata")],
                    new[setdiff(names(new), "metadata")])
  stopifnot(same)
  data.frame(experiment = name, scientific_results_identical = same)
})
write.csv(do.call(rbind, unchanged), "audit/uniform1328_unchanged_experiments.csv",
          row.names = FALSE)
old <- readRDS(file.path(backup, "github-results/checkmate_sim.rds"))
new <- readRDS("results/checkmate_sim.rds")
fields <- c("are_drmst_cox", "are_rah_cox", "are_rah_drmst",
            "ere_drmst_cox", "ere_rah_cox", "ere_rah_drmst",
            "cos2_cox", "cos2_drmst", "cos2_rah")
changes <- do.call(rbind, lapply(new$sensitivity$id, function(id) {
  a <- old$sensitivity[old$sensitivity$id == id, ]
  b <- new$sensitivity[new$sensitivity$id == id, ]
  stopifnot(a$seed == b$seed, a$n == b$n, a$B == b$B, a$tau == b$tau)
  data.frame(id = id, metric = fields, before = as.numeric(a[fields]),
             after = as.numeric(b[fields]))
}))
changes$delta <- changes$after - changes$before
write.csv(changes, "audit/uniform1328_efficiency_changes.csv", row.names = FALSE)
power <- do.call(rbind, lapply(c("Cox", "DRMST", "RAH"), function(method) {
  stopifnot(identical(old$power$seed, new$power$seed))
  data.frame(n = new$power$n, method = method, before = old$power[[method]],
             after = new$power[[method]])
}))
write.csv(power, "audit/uniform1328_power_changes.csv", row.names = FALSE)
print(new$sensitivity[new$sensitivity$id == new$baseline_id, c("id", fields)])
print(new$power)
obs <- readRDS("results/checkmate_observed.rds")
dat <- read_checkmate_data()$original
censored <- dat$time[dat$status == 0]
w0 <- obs$weibull$control
w1 <- obs$weibull$treatment
range <- cfg$checkmate057$censoring_uniform
lc <- cfg$checkmate057$dropout_rate
event_survival <- function(t)
  (sum(dat$arm == 0) * exp(-(t / w0[["scale"]])^w0[["shape"]]) +
   sum(dat$arm == 1) * exp(-(t / w1[["scale"]])^w1[["shape"]])) / nrow(dat)
censor_density <- function(t) {
  su <- pmax(0, pmin(1, (range[[2]] - t) / diff(range)))
  fu <- as.numeric(t >= range[[1]] & t < range[[2]]) / diff(range)
  exp(-lc * t) * (lc * su + fu)
}
# This is the distribution of observed censoring times conditional on C<T,
# not the unconditional distribution of the administrative time U.
censor_prob <- function(to) {
  joint <- function(t) event_survival(t) * censor_density(t)
  ans <- integrate(joint, 0, min(to, range[[1]]))$value
  if (to > range[[1]])
    ans <- ans + integrate(joint, range[[1]], min(to, range[[2]]))$value
  ans
}
pc <- censor_prob(range[[2]])
model_median <- uniroot(function(t) censor_prob(t) / pc - .5,
                        c(0, range[[2]]))$root
pattern <- data.frame(
  metric = c("censor_fraction", "fraction_censored_before_13.2",
             "median_censor_time"),
  reconstructed = c(length(censored) / nrow(dat), mean(censored < 13.2),
                    median(censored)),
  working_model = c(pc, censor_prob(13.2) / pc, model_median))
write.csv(pattern, "audit/uniform1328_censor_pattern.csv", row.names = FALSE)
print(pattern)
cat("Six unaffected experiments are exactly identical outside metadata.\n")
