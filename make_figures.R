source("R/utils_plot.R")
source("R/utils_dgp.R")
source("R/utils_theory.R")
dir.create("output/figures", recursive = TRUE, showWarnings = FALSE)

mph <- readRDS("results/main_ph.rds")
mnp <- readRDS("results/main_nonph.rds")
obs <- readRDS("results/checkmate_observed.rds")
sim <- readRDS("results/checkmate_sim.rds")

l2_unit <- function(x, weight, dt) {
  n <- sqrt(sum(x^2 * weight, na.rm = TRUE) * dt)
  if (n == 0) x else x / n
}

plot_cosine <- function(theory, path, title) {
  g <- theory$grid
  dt <- g$t[[2]] - g$t[[1]]
  lam <- c(0, diff(-log(pmax(g$S0, 1e-15))) / dt)
  sqw <- sqrt(pmax(g$w, 1e-12))
  vec <- list(
    Signal = l2_unit(g$alpha * sqw, lam, dt),
    Cox = l2_unit(g$W_cox / sqw, lam, dt),
    DRMST = l2_unit(g$W_drmst / sqw, lam, dt),
    RAH = l2_unit(g$W_rah / sqw, lam, dt)
  )
  if (sum(vec$Signal * vec$RAH * lam, na.rm = TRUE) * dt < 0) {
    vec$Signal <- -vec$Signal
  }
  keep <- g$t >= 0.5
  pdf(path, width = 11, height = 5.5)
  paper_par(mfrow = c(1, 2), mar = c(4.5, 4.5, 3, 1.5))
  yy <- range(unlist(lapply(vec, function(x) x[keep])), finite = TRUE)
  plot(g$t[keep], vec$Signal[keep], type = "l", lwd = 2.6,
       col = PAPER_STYLE$colors[["Signal"]], lty = PAPER_STYLE$lty[["Signal"]],
       ylim = yy, xlab = "Time (months)", ylab = "Unit direction", main = title)
  for (nm in c("Cox", "DRMST", "RAH")) lines(g$t[keep], vec[[nm]][keep],
       col = PAPER_STYLE$colors[[nm]], lty = PAPER_STYLE$lty[[nm]], lwd = 2.4)
  abline(h = 0, col = "grey80")
  legend("bottomleft", legend = c("Signal", "Cox", "D-RMST", "RAH"),
         col = PAPER_STYLE$colors[c("Signal", "Cox", "DRMST", "RAH")],
         lty = PAPER_STYLE$lty[c("Signal", "Cox", "DRMST", "RAH")], lwd = 2.4,
         bty = "n", cex = 1.05)
  plot.new(); plot.window(c(-1.4, 1.4), c(-1.35, 1.35), asp = 1)
  th <- seq(0, 2 * pi, length.out = 300); lines(cos(th), sin(th), col = "grey70")
  arrows(0, 0, 0, 1, length = .1, lwd = 3)
  text(0, 1.18, "Signal", cex = 1.05)
  cos2 <- theory$cos2
  for (nm in c("Cox", "DRMST", "RAH")) {
    angle <- pi / 2 - acos(sqrt(max(0, min(1, cos2[[nm]]))))
    arrows(0, 0, cos(angle), sin(angle), length = .1, lwd = 2.5,
           col = PAPER_STYLE$colors[[nm]])
  }
  legend("bottom", inset = .01,
         legend = sprintf("%s: %.3f", c("Cox", "D-RMST", "RAH"),
                          cos2[c("Cox", "DRMST", "RAH")]),
         col = PAPER_STYLE$colors[c("Cox", "DRMST", "RAH")],
         lty = PAPER_STYLE$lty[c("Cox", "DRMST", "RAH")],
         lwd = 2.5, bty = "n", cex = .95, horiz = TRUE)
  title(main = expression(cos^2(theta[X]) == xi[X] / group("||", s[alpha], "||")^2),
        cex.main = 1.2)
  dev.off()
}

plot_cosine_rows <- function(theories, titles, path) {
  pdf(path, width = 11, height = 13)
  paper_par(mfrow = c(length(theories), 2), mar = c(4.5, 4.5, 3, 1.5))
  for (j in seq_along(theories)) {
    theory <- theories[[j]]
    g <- theory$grid
    dt <- g$t[[2]] - g$t[[1]]
    lam <- c(0, diff(-log(pmax(g$S0, 1e-15))) / dt)
    sqw <- sqrt(pmax(g$w, 1e-12))
    vec <- list(
      Signal = l2_unit(g$alpha * sqw, lam, dt),
      Cox = l2_unit(g$W_cox / sqw, lam, dt),
      DRMST = l2_unit(g$W_drmst / sqw, lam, dt),
      RAH = l2_unit(g$W_rah / sqw, lam, dt)
    )
    if (sum(vec$Signal * vec$RAH * lam, na.rm = TRUE) * dt < 0) {
      vec$Signal <- -vec$Signal
    }
    keep <- g$t >= 0.5
    yy <- range(unlist(lapply(vec, function(x) x[keep])), finite = TRUE)
    yy[[1]] <- min(yy[[1]], -0.45)
    plot(g$t[keep], vec$Signal[keep], type = "l", lwd = 2.6,
         col = PAPER_STYLE$colors[["Signal"]], lty = PAPER_STYLE$lty[["Signal"]],
         ylim = yy, xlab = "Time (months)", ylab = "Unit direction",
         main = titles[[j]])
    for (nm in c("Cox", "DRMST", "RAH")) lines(g$t[keep], vec[[nm]][keep],
         col = PAPER_STYLE$colors[[nm]], lty = PAPER_STYLE$lty[[nm]], lwd = 2.4)
    abline(h = 0, col = "grey80")
    legend("bottomleft", legend = c("Signal", "Cox", "D-RMST", "RAH"),
           col = PAPER_STYLE$colors[c("Signal", "Cox", "DRMST", "RAH")],
           lty = PAPER_STYLE$lty[c("Signal", "Cox", "DRMST", "RAH")],
           lwd = 2.4, bty = "n", cex = 1.05)
    plot.new(); plot.window(c(-1.4, 1.4), c(-1.35, 1.35), asp = 1)
    th <- seq(0, 2 * pi, length.out = 300)
    lines(cos(th), sin(th), col = "grey70")
    arrows(0, 0, 0, 1, length = .1, lwd = 3)
    text(0, 1.18, "Signal", cex = 1.05)
    cos2 <- theory$cos2
    for (nm in c("Cox", "DRMST", "RAH")) {
      angle <- pi / 2 - acos(sqrt(max(0, min(1, cos2[[nm]]))))
      arrows(0, 0, cos(angle), sin(angle), length = .1, lwd = 2.5,
             col = PAPER_STYLE$colors[[nm]])
    }
    legend("bottom", inset = .01,
           legend = sprintf("%s: %.3f", c("Cox", "D-RMST", "RAH"),
                            cos2[c("Cox", "DRMST", "RAH")]),
           col = PAPER_STYLE$colors[c("Cox", "DRMST", "RAH")],
           lty = PAPER_STYLE$lty[c("Cox", "DRMST", "RAH")],
           lwd = 2.5, bty = "n", cex = .95, horiz = TRUE)
    title(main = expression(cos^2(theta[X]) == xi[X] / group("||", s[alpha], "||")^2),
          cex.main = 1.2)
  }
  dev.off()
}

plot_dgp <- function(curves, labels, path, title, legend_title) {
  pdf(path, width = 10, height = 8)
  paper_par(mfrow = c(2, 2), mar = c(4.5, 4.5, 3, 1.5))
  cols <- c("#4575B4", "#D73027", "#1A9850")
  ltys <- c(1, 2, 3)
  yr <- range(unlist(lapply(curves, `[[`, "hr")))
  plot(curves[[1]]$t, curves[[1]]$hr, type = "l", lwd = 2.5, col = cols[1],
       lty = ltys[1], ylim = yr, xlab = "Time (months)", ylab = "Hazard ratio",
       main = title)
  for (i in 2:length(curves)) lines(curves[[i]]$t, curves[[i]]$hr,
                                     col = cols[i], lty = ltys[i], lwd = 2.5)
  abline(h = 1, col = "grey60", lty = 3)
  legend("topright", paste0(legend_title, " = ", labels), col = cols,
         lty = ltys, lwd = 2.5, bty = "n", cex = 1.05)
  for (i in seq_along(curves)) {
    z <- curves[[i]]
    plot(z$t, z$S0, type = "l", lwd = 2.5, col = "black", ylim = c(0, 1),
         xlab = "Time (months)", ylab = "Survival",
         main = paste0(legend_title, " = ", labels[i]))
    lines(z$t, z$S1, lwd = 2.5, col = cols[i], lty = 2)
    legend("topright", c(expression(S[0](t)), expression(S[1](t))),
           col = c("black", cols[i]), lty = c(1, 2), lwd = 2.5, bty = "n")
  }
  dev.off()
}

z <- mnp$metadata$config$simulation
scale0 <- weibull_scale(z$s0, z$tau, z$shape)
light_rate <- unlist(z$censoring_rates)[["light"]]
mnp_theories <- list(
  mph$baseline_theory,
  theory_result(z$shape, scale0,
                alpha_fading(z$tau, z$effect_shape, z$fading_t_m,
                              step = z$effect_calibration_step), z$tau,
                light_rate, z$censoring_uniform,
                mnp$metadata$config$project$integration_step),
  theory_result(z$shape, scale0, alpha_delayed(z$tau, z$effect_shape,
                                            step = z$effect_calibration_step), z$tau,
                light_rate, z$censoring_uniform,
                mnp$metadata$config$project$integration_step)
)
plot_cosine_rows(mnp_theories,
                 c("PH", "Fading benefit", "Delayed benefit"),
                 "output/figures/figure1-cosine-geometry.pdf")
plot_dgp(mph$curves, mph$plot_s0, "output/figures/figure2-dgp-ph.pdf",
         "PH scenario (HR = 0.70)", expression(S[0](40)))
plot_dgp(mnp$curves$fading, mnp$effect_shapes,
         "output/figures/figure3-dgp-fading.pdf", "Fading benefit", "s")
plot_dgp(mnp$curves$delayed, mnp$effect_shapes,
         "output/figures/figure4-dgp-delayed.pdf", "Delayed benefit", "s")

# Figure 5: Weibull fit and PH diagnostic from the saved observed-data result.
pdf("output/figures/figure5-checkmate-diagnostics.pdf", width = 11, height = 5.5)
paper_par(mfrow = c(1, 2), mar = c(4.5, 4.5, 3, 1.5))
plot(NA, xlim = c(0, max(obs$km$time)), ylim = c(0, 1),
     xlab = "Time (months)", ylab = "Survival", main = "CheckMate 057 Weibull fits")
for (i in 1:2) {
  stratum <- unique(obs$km$strata)[i]
  z <- obs$km[obs$km$strata == stratum, ]
  col <- c("#4575B4", "#D73027")[i]
  lines(z$time, z$surv, type = "s", col = col, lwd = 2)
  wb <- if (i == 1) obs$weibull$control else obs$weibull$treatment
  tt <- seq(0, max(obs$km$time), length.out = 300)
  lines(tt, weibull_survival(tt, wb[["shape"]], wb[["scale"]]), col = col,
        lwd = 2.5, lty = 2)
}
legend("topright", c("Docetaxel KM", "Docetaxel Weibull", "Nivolumab KM", "Nivolumab Weibull"),
       col = rep(c("#4575B4", "#D73027"), each = 2), lty = rep(c(1, 2), 2),
       lwd = 2.3, bty = "n", cex = .95)
plot(obs$schoenfeld$time, obs$schoenfeld$residual, pch = 16, cex = .6,
     col = adjustcolor("#D73027", .55), xlab = "Time (months)",
     ylab = "Scaled Schoenfeld residual", main = "Cox PH diagnostic")
lines(lowess(obs$schoenfeld$time, obs$schoenfeld$residual), lwd = 2.5, col = "black")
abline(h = 0, col = "grey60", lty = 2)
mtext(sprintf("Global test p = %.3f", obs$schoenfeld_p), side = 3, line = .2)
dev.off()

plot_cosine(sim$baseline_theory, "output/figures/figure6-cosine-checkmate057.pdf",
            "CheckMate 057 at tau = 24 months")

pdf("output/figures/figure7-checkmate-power.pdf", width = 7.5, height = 6)
paper_par(mar = c(4.5, 4.5, 2, 1.5))
p <- sim$power[order(sim$power$n), ]
plot(p$n, p$Cox, type = "l", lwd = 2.5, col = PAPER_STYLE$colors[["Cox"]],
     lty = PAPER_STYLE$lty[["Cox"]], ylim = c(0, 1), xlab = "Sample size per arm",
     ylab = "Empirical power")
lines(p$n, p$DRMST, lwd = 2.5, col = PAPER_STYLE$colors[["DRMST"]],
      lty = PAPER_STYLE$lty[["DRMST"]])
lines(p$n, p$RAH, lwd = 2.5, col = PAPER_STYLE$colors[["RAH"]],
      lty = PAPER_STYLE$lty[["RAH"]])
abline(h = .8, col = "grey50", lty = 3)
legend("bottomright", c("Cox", "D-RMST", "RAH"),
       col = PAPER_STYLE$colors[c("Cox", "DRMST", "RAH")],
       lty = PAPER_STYLE$lty[c("Cox", "DRMST", "RAH")], lwd = 2.5,
       bty = "n", cex = 1.05)
dev.off()
message("Wrote 7 figures to output/figures")
