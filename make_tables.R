dir.create("output/tables", recursive = TRUE, showWarnings = FALSE)

fmt <- function(x, d = 3) formatC(as.numeric(x), format = "f", digits = d)
censor_label <- function(x) ifelse(x == "light", "Light", "Heavy")
write_table <- function(name, caption, label, header, rows, align = NULL) {
  if (is.null(align)) align <- paste0("l", paste(rep("c", length(header) - 1), collapse = ""))
  resize <- length(header) >= 8
  lines <- c("\\begin{table}[ht]", "\\centering", paste0("\\caption{", caption, "}"),
             paste0("\\label{", label, "}"),
             if (resize) "\\resizebox{\\textwidth}{!}{%" else character(),
             paste0("\\begin{tabular}{", align, "}"), "\\toprule",
             paste(header, collapse = " & "), "\\\\", "\\midrule",
             unlist(lapply(seq_along(rows), function(i) c(
               if (i > 1 && rows[[i]][1] != rows[[i-1]][1] &&
                   rows[[i]][1] %in% c("Light", "Heavy")) "\\midrule" else character(),
               paste0(paste(rows[[i]], collapse = " & "), " \\\\")))),
             "\\bottomrule", "\\end{tabular}",
             if (resize) "}" else character(), "\\end{table}")
  writeLines(lines, file.path("output/tables", name))
}

metric_row <- function(label, x, include_power = FALSE) {
  ans <- c(label, fmt(x$are_drmst_cox), fmt(x$are_rah_cox), fmt(x$are_rah_drmst),
           fmt(x$ere_drmst_cox), fmt(x$ere_rah_cox), fmt(x$ere_rah_drmst))
  if (include_power) {
    ans <- c(label, fmt(x$are_drmst_cox), fmt(x$are_rah_cox), fmt(x$are_rah_drmst),
             fmt(x$power_cox), fmt(x$power_drmst), fmt(x$power_rah),
             fmt(x$ere_drmst_cox), fmt(x$ere_rah_cox), fmt(x$ere_rah_drmst))
  }
  ans
}

obs <- readRDS("results/checkmate_observed.rds")
sim <- readRDS("results/checkmate_sim.rds")
mph <- readRDS("results/main_ph.rds")
mnp <- readRDS("results/main_nonph.rds")
h82 <- readRDS("results/appendix_hr082.rds")
t10 <- readRDS("results/appendix_tau10.rds")
cross <- readRDS("results/appendix_crossing.rds")

# Table 1
t1 <- obs$table
t1 <- t1[order(match(t1$dataset, c("original", "sensitivity")),
               match(t1$method, c("Cox", "D-RMST", "RAH"))), ]
rows <- lapply(seq_len(nrow(t1)), function(i) {
  r <- t1[i, ]
  est <- if (r$method == "D-RMST") fmt(r$estimate, 2) else fmt(r$estimate, 3)
  ci <- if (r$method == "D-RMST") sprintf("(%s, %s)", fmt(r$ci_lo, 2), fmt(r$ci_hi, 2)) else
    sprintf("(%s, %s)", fmt(r$ci_lo), fmt(r$ci_hi))
  c(ifelse(r$dataset == "original", "Original", "Sensitivity"), r$method, est, ci,
    ifelse(r$pval < .001, "$<0.001$", fmt(r$pval)))
})
write_table("table1-checkmate-results.tex",
            paste0("CheckMate 057 overall-survival results under two censoring reconstructions. ",
                   "All three methods use an analysis horizon of $\\tau=24$ months; for Cox, ",
                   "follow-up is administratively censored at $\\tau$ before model fitting. ",
                   "Values below 1 for Cox and RAH, or above 0 for D-RMST, favor nivolumab."),
            "tab:results-cm057-intro", c("Dataset", "Method", "Estimate", "95\\% CI", "$p$-value"), rows)

# Tables 2 and 3
p <- mph$scenarios
t2 <- p[p$shape == 0.826, ]
t2 <- t2[order(match(t2$censoring, c("light", "heavy")), t2$s0), ]
write_table("table2-main-ph-s0.tex",
            "ARE and ERE under PH (HR$=0.70$), $\\kappa=0.826$, $\\tau=40$, $n=400$ per arm, $B=2000$.",
            "tab:main-sim-ph-hr070-s0-010-090-light-heavy",
            c("Censoring", "$S_0(40)$", "ARE(D/C)", "ARE(R/C)", "ARE(R/D)", "ERE(D/C)", "ERE(R/C)", "ERE(R/D)"),
            lapply(seq_len(nrow(t2)), function(i) metric_row(c(censor_label(t2$censoring[i]), fmt(t2$s0[i], 2)), t2[i, ])))
t3 <- p[p$s0 == 0.5, ]
t3 <- t3[order(match(t3$censoring, c("light", "heavy")), t3$shape), ]
write_table("table3-main-ph-shape.tex",
            "ARE and ERE under PH (HR$=0.70$), $S_0(40)=0.50$, $\\tau=40$, $n=400$ per arm, $B=2000$.",
            "tab:main-sim-ph-hr070-kappa-050-200-light-heavy",
            c("Censoring", "$\\kappa$", "ARE(D/C)", "ARE(R/C)", "ARE(R/D)", "ERE(D/C)", "ERE(R/C)", "ERE(R/D)"),
            lapply(seq_len(nrow(t3)), function(i) metric_row(c(censor_label(t3$censoring[i]), fmt(t3$shape[i], 3)), t3[i, ])))

# Table 4
t4 <- mnp$scenarios[order(match(mnp$scenarios$case, c("fading", "delayed")),
                         match(mnp$scenarios$censoring, c("light", "heavy"))), ]
write_table("table4-main-nonph.tex",
            sprintf("ARE and ERE for monotone non-PH patterns; $\\tau=40$, $S_0(40)=0.50$, $t_M=%s$, $n=400$ per arm, $B=2000$.", fmt(unique(t4$t_m[is.finite(t4$t_m)]), 0)),
            "tab:main-sim-nonph",
            c("Pattern", "Cens.", "ARE(D/C)", "ARE(R/C)", "ARE(R/D)", "ERE(D/C)", "ERE(R/C)", "ERE(R/D)"),
            lapply(seq_len(nrow(t4)), function(i) metric_row(c(t4$case[i], censor_label(t4$censoring[i])), t4[i, ])))

# Table 5
b <- sim$sensitivity[sim$sensitivity$id == sim$baseline_id, ][1, ]
write_table("table5-checkmate-are-ere.tex",
            "Theoretical ARE and empirical ERE under the CheckMate 057 fitted non-PH DGP; all methods use $\\tau=24$ months, $n=300$ per arm, $B=500$.",
            "tab:cm057-are-ere", c("Comparison", "ARE", "ERE"),
            list(c("D-RMST/Cox", fmt(b$are_drmst_cox), fmt(b$ere_drmst_cox)),
                 c("RAH/Cox", fmt(b$are_rah_cox), fmt(b$ere_rah_cox)),
                 c("RAH/D-RMST", fmt(b$are_rah_drmst), fmt(b$ere_rah_drmst))))

# Table 6
pow <- sim$power[order(sim$power$n), ]
n80_grid <- function(y) {
  hit <- pow$n[y >= .8]
  if (length(hit)) min(hit) else NA_real_
}
n80 <- c(Cox = n80_grid(pow$Cox), DRMST = n80_grid(pow$DRMST), RAH = n80_grid(pow$RAH))
at300 <- pow[pow$n == 300, ]
sim_ratio <- n80 / n80[["RAH"]]
are_ratio <- c(Cox = b$are_rah_cox, DRMST = b$are_rah_drmst, RAH = 1)
ere_ratio <- c(Cox = b$ere_rah_cox, DRMST = b$ere_rah_drmst, RAH = 1)
write_table("table6-checkmate-power.tex",
            "Empirical power at $n=300$ per arm and first simulated sample size reaching 80\\% power (50-patient grid, $B=2000$), with simulated, ARE-, and ERE-implied ratios relative to RAH.",
            "tab:cm057-power-n80",
            c("Method", "Power", "$n_{80}$", "Sim. ratio", "ARE ratio", "ERE ratio"),
            lapply(c("Cox", "DRMST", "RAH"), function(m) c(ifelse(m == "DRMST", "D-RMST", m),
              fmt(at300[[m]]), fmt(n80[[m]], 0), fmt(sim_ratio[[m]], 2), fmt(are_ratio[[m]], 2), fmt(ere_ratio[[m]], 2))))

# Table 7
s <- sim$sensitivity[match(sim$sensitivity_views$id, sim$sensitivity$id), ]
s$panel <- sim$sensitivity_views$panel
s$panel <- c(tau = "Horizon", dropout = "Dropout", hazard = "Hazard")[s$panel]
s$label <- sim$sensitivity_views$label
format_sensitivity_label <- function(x) {
  if (grepl("^tau=", x)) return(sprintf("$\\tau=%s$", sub("^tau=", "", x)))
  if (grepl("^lambda_c=", x))
    return(sprintf("$\\lambda_c=%s$", sub("^lambda_c=", "", x)))
  if (grepl("^PH \\(HR=", x)) return(sub("HR=", "HR$=", sub("\\)$", "$)", x)))
  x
}
s$label <- vapply(s$label, format_sensitivity_label, character(1))
write_table("table7-checkmate-sensitivity.tex",
            "Sensitivity to analysis horizon, dropout rate, and hazard structure; the common baseline is $\\tau=24$, $\\lambda_c=0.005$, fitted non-PH, $n=300$ per arm and $B=500$.",
            "tab:sens-are",
            c("Panel", "Setting", "ARE(D/C)", "ARE(R/C)", "ARE(R/D)", "ERE(D/C)", "ERE(R/C)", "ERE(R/D)"),
            lapply(seq_len(nrow(s)), function(i) metric_row(c(s$panel[i], s$label[i]), s[i, ])))

# Tables 8 and 9
x <- h82$scenarios
t8 <- x[x$shape == 0.826, ]; t8 <- t8[order(match(t8$censoring, c("light", "heavy")), t8$s0), ]
write_table("table8-hr082-s0.tex", "ARE and ERE under PH (HR$=0.82$), $\\kappa=0.826$, $\\tau=40$, $n=400$ per arm, $B=2000$.",
            "tab:sim3a-hr082", c("Censoring", "$S_0(40)$", "ARE(D/C)", "ARE(R/C)", "ARE(R/D)", "ERE(D/C)", "ERE(R/C)", "ERE(R/D)"),
            lapply(seq_len(nrow(t8)), function(i) metric_row(c(censor_label(t8$censoring[i]), fmt(t8$s0[i],2)), t8[i, ])))
t9 <- x[x$s0 == 0.5, ]; t9 <- t9[order(match(t9$censoring, c("light", "heavy")), t9$shape), ]
write_table("table9-hr082-shape.tex", "ARE, power, and ERE under PH (HR$=0.82$), $S_0(40)=0.50$, $\\tau=40$, $n=400$ per arm, $B=2000$.",
            "tab:sim3c-hr082", c("Censoring", "$\\kappa$", "ARE(D/C)", "ARE(R/C)", "ARE(R/D)", "Power C", "Power D", "Power R", "ERE(D/C)", "ERE(R/C)", "ERE(R/D)"),
            lapply(seq_len(nrow(t9)), function(i) metric_row(c(censor_label(t9$censoring[i]), fmt(t9$shape[i],3)), t9[i, ], TRUE)))

# Tables 10 and 11
x <- t10$scenarios[order(match(t10$scenarios$censoring, c("light", "heavy")), t10$scenarios$shape), ]
write_table("table10-tau10.tex", "ARE and ERE under PH (HR$=0.70$), $\\tau=10$, $n=150$ per arm, $B=500$.",
            "tab:sim-tau10", c("Censoring", "Baseline", "ARE(D/C)", "ARE(R/C)", "ARE(R/D)", "ERE(D/C)", "ERE(R/C)", "ERE(R/D)"),
            lapply(seq_len(nrow(x)), function(i) metric_row(c(censor_label(x$censoring[i]), x$scenario[i]), x[i, ])))
x <- cross$scenarios[order(match(cross$scenarios$censoring, c("light", "heavy"))), ]
write_table("table11-crossing.tex", "ARE and ERE under crossing hazards; $t_M=43$, $\\tau=40$, $S_0(40)=0.50$, $n=400$ per arm, $B=2000$.",
            "tab:sim-crossing", c("Cens.", "ARE(D/C)", "ARE(R/C)", "ARE(R/D)", "ERE(D/C)", "ERE(R/C)", "ERE(R/D)"),
            lapply(seq_len(nrow(x)), function(i) metric_row(censor_label(x$censoring[i]), x[i, ])))

message("Wrote 11 tables to output/tables")
