# AH-ARE pre-refactor provenance inventory

Inventory date: 2026-09-30. This is a read-only inventory of the code and
paper artifacts as they existed at GitHub commit `a9af179`. “Reproduces” means
that the current script can be tied to the value printed in `../paper.tex` or a
committed paper artifact without changing its settings; it does not mean the
setting is scientifically consistent with another output.

## Global implementations and configuration found in the current code

- Main simulations source `R/dgp-tian2017.R`, `R/fun-ares-v2.R`, and
  `R/main-sim-paper-helpers.R`. The effective settings are `tau=40`, Cox theory
  horizon `tau_h=42.5`, `t_M=21.25`, uniform censoring `[24,43]`, Weibull
  calibration at `S0(40)`, `n=400` per arm, and usually `B=2000`. Theory uses a
  rectangular grid with step 0.01. Cox ERE and power are fit to all observed
  follow-up, not administratively censored at `tau`.
- CheckMate scripts source `scripts/checkmate057/checkmate057-common.R`. The
  effective settings are `tau=24`, Cox theory/cosine horizon `tau_h=26`,
  uniform censoring `[6,30]`, exponential dropout `lambda_c=0.005`, `n=300` per
  arm, `B=500` for ERE and `B=2000` for power. Theory uses a rectangular grid
  with step 0.05. Cox observed-data estimates and simulated Cox statistics use
  all observed follow-up.
- ERE is `mean(U)^2/var(U)` for a Cox log-HR coefficient, a D-RMST estimate,
  and a log-RAH contrast. The statistics are all unstandardized `U`-scale
  quantities, but Cox uses longer follow-up than the other two tests.
- Seeds are set once per script in CheckMate code, so rows depend on loop order.
  Main simulations assign setting seeds but save per-replicate intermediate
  CSV files and timestamped run directories.

## Tables 1–11

| Paper item | Script → function(s) | Effective configuration | Current result file | Reproduces printed value? |
|---|---|---|---|---|
| Table 1, CheckMate estimates | `scripts/checkmate057/table-results-cm057-intro.R` → `cm057_results_table`, `cm057_cox_test`, `cm057_rmst_test`, `cm057_rah_test` | Observed original/sensitivity reconstructions; D-RMST/RAH `tau=24`; Cox untruncated; no MC | `output/checkmate057/paper/table-results-cm057-intro.csv` | Yes for the table artifact. Text reverses the two D-RMST estimates and contains stale RAH CIs/p-values. |
| Table 2, PH by `S0(40)` | `generate-main-sim-ph-hr070.R` and table builder → `main_sim_ph_s0_settings`, `compute_are_triple`, `compute_ere_triple_ph` | `tau=40`; Cox theory 42.5 and ERE untruncated; `t_M` N/A; censoring `min(Exp(lambda_c),U[24,43])`, `lambda_c={0.0006,0.025}`; calibration `S0(40)`; `n=400`; `B=2000`; setting seeds; grid 0.01 rectangular | `output/main-sim-paper/paper/table-main-sim-ph-hr070-s0-010-090-light-heavy.csv` | Yes for current artifact. It disagrees with Table 3 at the shared `kappa=.826,S0=.50` setting because different seeds are used for ERE. |
| Table 3, PH by Weibull shape | Same generator/table builder → `main_sim_ph_shape_settings`, shared theory/ERE helpers | Same as Table 2; fixed `S0(40)=.50`; shapes `.5,.826,1,1.5,2` | `output/main-sim-paper/paper/table-main-sim-ph-hr070-kappa-050-200-light-heavy.csv` | Yes for current artifact; shared row ERE differs from Table 2. |
| Table 4, monotone non-PH | `generate-main-sim-nonph.R` and table builder → `main_sim_nonph_settings`, `make_alpha_case2/3`, `compute_are_triple`, `compute_ere_triple` | `tau=40`; Cox theory 42.5 and ERE untruncated; **`t_M=21.25` for fading**; censoring as Table 2; `S0(40)=.50`; `n=400`; `B=2000`; setting seeds; grid 0.01 rectangular; inverse-CDF DGP grid 5,000 points to 500 | `output/main-sim-paper/paper/table-main-sim-nonph.csv` | No. The CSV currently committed contains values very different from the table printed in the manuscript, and the fading setting differs from the stated `t_M=43`. |
| Table 5, CheckMate ARE/ERE | `table-cm057-are-ere.R` → local `make_P`, `ares_v2`, `cm057_gen`, three `cm057_stat_*` functions | D-RMST/RAH `tau=24`; Cox theory 26 and ERE untruncated; fitted Weibulls; censoring `[6,30]` plus dropout .005; `n=300`; `B=500`; script seed 2024; grid .05 rectangular | `output/checkmate057/paper/table-cm057-are-ere.csv` | No for manuscript input: `paper.tex` points to timestamp `20260630_144612`; committed stable CSV has newer ARE values. Baseline should also equal Table 7 but does not in the manuscript. |
| Table 6, CheckMate power/sample size | `generate-cm057-power-sim.R`, `table-cm057-power-n80.R` → `cm057_gen`, `cm057_pval_*` | `tau=24` for D-RMST/RAH; Cox untruncated; fitted Weibulls; censoring `[6,30]` plus dropout .005; `n=100:500` by 50; `B=2000`; one script seed 2024 | `output/checkmate057/paper/cm057-power-curve.csv`; `table-cm057-power-n80.csv` | Yes for table artifact. Text reports D-RMST 67% instead of 68.8%; `n80` is quantized by a 50-person grid. |
| Table 7, CheckMate sensitivity | `table-cm057-sens-are.R` → local `are_ratios`, `ere_ratios`, `make_row` | D-RMST/RAH horizons 18/21/24; **Cox theory always 26 and ERE untruncated**; dropout .001/.005/.020; fitted non-PH or PH HR=.75; `n=300`; `B=500`; one script seed 2024 reused sequentially; grid .05 rectangular | `output/checkmate057/paper/table-cm057-sens-are.csv` | No for manuscript input (timestamped file), and duplicate baseline ERE rows are not identical because each row consumes a different RNG segment. |
| Table 8, PH HR=.82 by `S0(40)` | `appendix-sim-ph-hr082.R` → shared `compute_are_triple`, `compute_power_triple_ph`, `compute_ere_triple_ph` | `tau=40`; Cox theory 42.5 and simulations untruncated; censoring as Table 2; `n=400`; `B=2000`; sequential seed counter; grid .01 rectangular | timestamped `output/appendix-sim-paper/*/table3a-ph-hr082.csv`; table body is hand-copied into `paper.tex` | Can run, but the manuscript table is hand-typed and not linked to a stable generated result. |
| Table 9, PH HR=.82 by shape | Same appendix script and helpers | As Table 8; fixed `S0(40)=.50`; shapes `.5,.826,1,1.5,2`; power also computed | timestamped `output/appendix-sim-paper/*/table3c-ph-shapes-hr082.csv`; hand-copied table body | Can run, but not directly generated into the manuscript. |
| Table 10, short horizon | `appendix-sim-ph-tau10.R` → shared theory/ERE helpers | D-RMST/RAH `tau=10`; Cox theory 11 and simulations untruncated; censoring `U[8,12]` plus `.02/.20`; `n=150`; `B=500`; sequential seeds from 42; grid .01 rectangular | timestamped `output/appendix-sim-paper/*/table-ph-tau10.csv`; hand-copied table body | Can run. Code and caption use 150/arm; nearby manuscript prose formerly/comments state 300. |
| Table 11, crossing hazards | No dedicated current generator/table script; archived simulation code calls `make_alpha_case1` and shared helpers | Manuscript says `tau=40,t_M=43,S0(40)=.50,n=400`; current shared default is `t_M=21.25`; censoring as Table 2; printed caption omits `B` | No stable result file; table body is hand-typed in `paper.tex` | Cannot reproduce from a current paper-facing script. |

## Figures 1–7

| Paper item | Script → function(s) | Effective configuration | Current result file | Reproduces printed figure? |
|---|---|---|---|---|
| Figure 1, cosine geometry | `scripts/figures/gen-cosine-figure.R` → local `make_P_local`, `get_unit_vectors`, base plotting | `tau=40`, plot/Cox horizon 42.5, `S0(40)=.50`, shape .826, light censoring, grid .01; local duplicate theory implementation | `output/figures/cosine/paper/fig-cosine-geometry.pdf` | Yes, but contains code-style labels and a 42.5 marker. |
| Figure 2, PH DGP | `scripts/figures/gen-dgp-figure.R` → `compute_surv`, `plot_dgp_4panel` | Plot/calibration horizon 42.5; title says `S0(42.5)`; shapes .826; HR .70 | `output/figures/dgp/paper/dgp_ph.pdf` | Yes, but conflicts with the paper’s `tau=40` design. |
| Figure 3, fading DGP | Same script → `make_alpha_case2`, `compute_surv` | Plot/calibration horizon 42.5; `t_M=21.25`; control calibrated to `S0(42.5)=.30`; `s=.5,1,2` | `output/figures/dgp/paper/dgp_case2.pdf` | Yes, but conflicts with text/Table 4 (`S0(40)=.50`, stated `t_M=43`). |
| Figure 4, delayed DGP | Same script → `make_alpha_case3`, `compute_surv` | Plot/calibration horizon 42.5; control `S0(42.5)=.30`; `s=.5,1,2` | `output/figures/dgp/paper/dgp_case3.pdf` | Yes, but conflicts with Table 4’s control survival. |
| Figure 5, CheckMate fits/diagnostic | `figure-weibull.R` → `cm057_fit_weibull`; `figure-cm057-ph-diagnostic.R` → `cox.zph` | Observed original data; no simulation; Cox diagnostic untruncated | `output/checkmate057/paper/figure-weibull.pdf`; `cm057-ph-diagnostic.pdf` | Yes. |
| Figure 6, CheckMate cosine | `gen-cosine-checkmate057.R` → local duplicated `make_P_cm`, `get_unit_vectors_cm` | D-RMST/RAH `tau=24`; plot/Cox horizon 26; fitted Weibulls; dropout .005, censoring `[13,28]` (different from tables `[6,30]`); grid .02 | `output/figures/cosine/paper/fig-cosine-cm057.pdf` | No. Cosines and censoring configuration differ from Table 5; figure has debug/code-style annotations. |
| Figure 7, CheckMate power | `figure-cm057-power-curve.R` reads saved power CSV | Same result object as Table 6; current local color map differs from other figures | `output/checkmate057/paper/cm057-power-curve.pdf` | Yes for the saved CSV; style is inconsistent. |

## Result/design numbers quoted in prose

| Location and quoted content | Provenance | Reproduces? |
|---|---|---|
| Introduction: Table 1 estimates and p-values (`0.75/0.84`, `1.73/1.75`, `0.74/0.74`, and six p-values) | Table 1 result CSV | Partly. D-RMST original/sensitivity order is reversed in prose; RAH p-values are stale. |
| Simulation design: `tau=40`, shape `.826`, `lambda_c=.0006/.025`, `S_C(40)=.15/.04`, PH HR `.70`, `S0(40)=.10…90`, `t_M=43` | `dgp-tian2017.R` and prose calculation | No. Code has `tau_h=42.5`, `t_M=21.25`; heavy `S_C(40)=exp(-.025*40)*(43-40)/19=.0581`, not .04. |
| Section 4.2: Table 2 ranges/orderings including heavy RAH/Cox `0.81` at `S0=.10` | Table 2 CSV | No. `0.81` is RAH/D-RMST; RAH/Cox is about .797. Other prose is based on an older artifact. |
| Section 4.3: Table 3 RAH/Cox `.92` to `.73` and qualitative ordering | Table 3 CSV | Approximately reproduces after rounding for light censoring; shared baseline ERE is inconsistent with Table 2. |
| Section 4.4: qualitative orderings for Table 4 and “ERE close to ARE” | Table 4 CSV | No. Current CSV materially disagrees with the hand-copied manuscript values and some efficiency orderings. |
| CheckMate fitted Weibulls (`1.264,13.076`; `.987,17.320`), Schoenfeld `p=.001`, alpha/HR summaries | `figure-weibull-params.csv`, `cox.zph`, fitted-Weibull hazard ratio | Weibull parameters reproduce; `alpha(t)` actually diverges as `t→0`, so “decreases from .187”/month-1 wording needs care. |
| CheckMate cosines `.603/.462/.638` | Figure 6’s local calculation | No against Table 5. Current figure code/result differs from the Table 5 theory object; ratio identity is not asserted. |
| Power at 300 (`85/76/67%`), `n80=250/350/400`, “40%/60% more” | Table 6 power CSV and coarse threshold lookup | Partly. D-RMST is 68.8% (69%); percentages and `n80` depend on a 50-person grid. |
| Sensitivity horizon ranges (`.531→.766`, RAH/Cox `.964–1.110`, RAH/D-RMST `1.30–1.82`) | Table 7 | No. Several values are taken from different/stale rows; current baseline theory is `.906/1.178/1.300`. |
| Sensitivity dropout prose (`.87→1.03`, RAH/Cox `1.21–1.32`) | Table 7 | No. `1.21–1.32` is the RAH/D-RMST column, not RAH/Cox. |
| PH sensitivity (`1.00`, `.87`) | Table 7 PH row | Yes after rounding for ARE; ERE direction should be checked after common-horizon rerun. |
| Appendix HR=.82 claims and all Table 8/9 numbers | Appendix script/timestamped CSV | Can run, but values are hand-typed into LaTeX rather than generated. |
| Appendix short-horizon ranges `1.067–1.119`, `.66–.69` and Table 10 numbers | Appendix tau10 script/timestamped CSV | Can run; Cox horizon differs from `tau`; sample-size prose is inconsistent around the table. |
| Appendix crossing claims/Table 11 numbers | No current stable result | Cannot run from a dedicated current experiment; `t_M` ambiguity prevents a valid comparison. |

## Inventory conclusion

The current tree cannot satisfy a single provenance chain. It contains duplicate
theory implementations, different integration grids and censoring windows,
different Cox horizons, loop-order seeds, timestamped/intermediate outputs, and
four hand-entered appendix tables. Phase 1 must make the common horizon explicit
and central, reuse a single DGP/method/theory implementation, and make repeated
settings share the same result row rather than merely recompute nominally equal
rows.
