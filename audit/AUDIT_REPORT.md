# AH-ARE Gate 1 audit report

> Historical report. See `REPLICATION_AND_CHANGE_REPORT.md` for the completed
> Phase 2 and direct comparison with the supplied 27Sep PDF. The old Table 4
> CSV/LaTeX artifact has now been matched to that PDF; the earlier statement
> below that it could not be matched is superseded. Exact old Table 5 and
> Table 11 provenance remains unresolved.

Audit date: 2026-09-30  
Branch: `reproducible-pipeline-audit`
Source baseline: GitHub `unoichi/AHare`, commit `a9af179`  
Pipeline config hash: `ab145e7906d5ab16926275ff46438a6282b53f4b01603e65f4025125b43e6a7e`

## Gate 1 status

Phase 0 and Phase 1 are complete. The full paper-count pipeline ran to
completion and all assertions passed. The manuscript has not been edited; that
is intentionally deferred to Phase 2 after the decisions at the end of this
report.

The new pipeline is driven by `config.yaml` and `Rscript run_all.R`. It saves
one final RDS per experiment under `results/`, then generates 11 LaTeX tables,
seven PDF figures, and `output/numbers.tex` only from those result objects.
Every result contains the config snapshot and hash, deterministic scenario
seed(s), source Git hash, date, and runtime. The full run used 2,000 replicates
for the main simulations, CheckMate power curve, HR=.82 appendix, and crossing
appendix; 500 for CheckMate ERE/sensitivity and the short-horizon appendix.

## Cross-output assertions

All assertions in `tests/test_consistency.R` pass:

- Cox, D-RMST, and RAH use the same horizon in every comparison.
- Table 2 `S0(40)=.50,kappa=.826` and Table 3 `kappa=.826,S0(40)=.50`
  are the same saved rows, including ERE.
- Table 5 and the three Table 7 baseline appearances are one saved row.
- `ARE(R/D) = ARE(R/C) / ARE(D/C)` and the corresponding ERE identity hold
  to `1e-12` for every scenario.
- `cos^2_R / cos^2_C = ARE(R/C)` and
  `cos^2_D / cos^2_C = ARE(D/C)` hold to `1e-12`.
- The PH ARE rows at HR=.70 and HR=.82 agree to `1e-12`; ERE is not asserted
  across those two alternatives because their finite effect sizes differ.
- The CheckMate power grid is exactly 100, 150, ..., 500, as approved.
- Exactly 11 generated tables, seven generated figures, and `numbers.tex`
  exist.

## Issue-by-issue findings

### 1. Table 7 baseline rows

- **Root cause:** config mismatch plus independent RNG consumption. Table 5
  used Cox theory to 26 months; older manuscript inputs also pointed at
  different timestamped runs. Table 7 regenerated nominally identical rows
  independently, so ERE varied by row order.
- **Old:** manuscript review found RAH/Cox ARE 1.058 versus 1.178; committed
  stable Table 5 contained ARE 1.178 and ERE 1.232.
- **New:** all Table 5/Table 7 baseline appearances are exactly ARE
  D/C=.915, R/C=1.199, R/D=1.310 and ERE D/C=.935, R/C=1.332,
  R/D=1.425.
- **Proposed Phase 2 fix:** input generated Tables 5 and 7; describe Table 7
  as horizon, dropout, and hazard-structure sensitivity. No decision needed.

### 2. Section 5 horizon paragraph

- **Root cause:** wrong/stale rows in text.
- **Old:** 0.91, 0.96–1.18, and 1.30 were quoted from mixed columns/runs.
- **New:** as tau goes 18, 21, 24, ARE D/C is .651, .789, .915; ARE R/C is
  1.198, 1.211, 1.199; ARE R/D is 1.841, 1.533, 1.310.
- **Proposed fix:** rewrite from macros generated from the Table 7 result.

### 3. Section 5 dropout paragraph

- **Root cause:** RAH/D-RMST was described as RAH/Cox.
- **Old:** “ARE(RAH/Cox) 1.21–1.32.”
- **New:** over lambda_c=.001,.005,.020, ARE R/C is 1.180, 1.199, 1.265;
  ARE R/D is 1.335, 1.310, 1.217.
- **Proposed fix:** use the correct macros and describe R/C as modestly
  increasing while R/D decreases.

### 4. Figure 6 versus text and Table 5

- **Root cause:** Figure 6 duplicated theory code and used horizon 26,
  censoring `[13,28]`, and a different grid; Table 5 used `[6,30]`.
- **Old text:** cosines .603/.462/.638.
- **New:** Cox=.552, D-RMST=.506, RAH=.662. The exact result object gives
  .662/.552=1.199 (RAH/Cox) and .506/.552=.915 (D-RMST/Cox).
- **Proposed fix:** use the new Figure 6 and generated cosine macros.

### 5. Introduction versus Table 1

- **Root cause:** D-RMST original/sensitivity order was reversed; Cox used all
  observed follow-up.
- **Old Cox:** original HR=.750, p=.004; sensitivity HR=.840, p=.157.
- **New common-tau Cox:** original HR=.740, p=.002; sensitivity HR=.783,
  p=.052. D-RMST is 1.75 original and 1.73 sensitivity. RAH is .739 and .743.
- **Proposed fix:** regenerate prose from Table 1 macros. Decision D5 governs
  whether the truncated Cox estimate gets a footnote.

### 6. Table 6 and power text

- **Root cause:** stale prose and a 50-patient threshold grid.
- **Old at n=300:** Cox 75.6%, D-RMST 68.8% (reported as 67%), RAH 84.8%;
  n80 350/400/250.
- **Final at n=300:** Cox 71.7%, D-RMST 68.0%, RAH 84.3%. On the approved
  50-patient grid, without interpolation, the first points reaching 80% are
  400, 400, and 300, respectively. Cox and D-RMST therefore each require 33%
  more patients than RAH on this grid; Table 6 also reports ARE- and
  ERE-implied ratios.
- **Applied fix:** retain the existing grid and report its discrete threshold
  explicitly, without interpolation.

### 7. Section 4.2 at S0(40)=.10

- **Root cause:** RAH/D-RMST was cited as RAH/Cox.
- **Old:** .81 for RAH/Cox under heavy censoring.
- **New:** RAH/Cox=.798 and RAH/D-RMST=.812.
- **Proposed fix:** use the correct generated macro.

### 8. Appendix D sample size

- **Root cause:** inconsistent prose, not code.
- **Code/result:** n=150 per arm, B=500.
- **Old prose:** one location said 300; Section 4.1, the caption, and code said
  150.
- **Proposed fix:** make all four locations say 150.

### 9. Fading-benefit t_M

- **Root cause:** `R/dgp-tian2017.R` set `t_M=42.5/2=21.25`, while the paper
  states 43. Figures used 21.25 but different baseline survival; the old Table 4
  artifact did not reproduce from current code.
- **New audit run:** Table 4 and Figure 3 share t_M=21.25 and S0(40)=.50.
  Fading ARE at light censoring is D/C=1.342, R/C=.684, R/D=.510; under
  heavy censoring 1.019, .383, .376. A theory-only check at t_M=43 gives
  light 1.108/.741/.669 and heavy 1.011/.499/.494.
- **Proposed fix:** decision D2. Do not edit text until t_M is chosen.

### 10. 40 versus 42.5 versus 43

- **Root cause:** historical `TAU_H=42.5` mixed a Cox horizon/calibration point
  with `tau=40`; 43 is the upper uniform-censoring limit and the appendix
  crossing `t_M`.
- **New:** all main analysis and calibration grids end at 40; all CheckMate
  analysis grids end at 24. The 42.5 marker is removed.
- **Proposed fix:** Phase 2 captions/text should reserve 43 for censoring upper
  limit (and crossing `t_M`) and use 40 for analysis/calibration.

### 11. S0 in Figures 3–4

- **Root cause:** figures calibrated S0(42.5)=.30 independently of Table 4.
- **New:** the figures and Table 4 use one DGP with S0(40)=.50.
- **Proposed fix:** use the new generated figures.

### 12. Heavy-censoring S_C(40)

- **Root cause:** wrong text value.
- **Old:** .04.
- **New derived macro:** light=.154; heavy=.058 for lambda_c=.025 and
  U[24,43].
- **Proposed fix:** decision D3: keep lambda_c=.025 and report .058, or retune.

### 13–16. Mathematical and notation corrections

- **Root cause:** manuscript algebra/notation errors, not simulation code.
- **Confirmed:** the RAH weight used by the shared theory implementation has
  the positive sign and equals
  `S0(tau) + {1-S0(tau)} W_D-RMST(t)`. The Cox expansion is proportional, the
  D-RMST integral requires changing integration order, and the orientation of
  U does not affect efficacy because the mean is squared.
- **Proposed Phase 2 fix:** apply the exact replacement text supplied in the
  brief for the RAH bullet, orientation sentence, Proposition 1 sign, R0
  notation, Cox statement, equation (20) differential, and D-RMST chain.
  Replace the contribution counts in both Introduction and Discussion with the
  supplied “three contributions” text.

### 18. Table 7 caption

- **Root cause:** caption described sample-size and baseline-hazard dimensions
  that are not in the table.
- **New generated caption:** horizon, dropout rate, and hazard structure, with
  the exact baseline identified.
- **Proposed fix:** input the generated table.

### 19. ARE/ERE agreement claim

- **Root cause:** claim was not checked row by row.
- **New audit:** directions disagree only for near-null comparisons, but the
  largest such distance from 1 is about .067 (short-horizon RAH/D-RMST), so
  “within .05” is too tight.
- **Proposed fix:** say directions agree except when ARE and ERE are both close
  to 1 (within about .07).

### 20. Tables 2, 3, and 8

- **Root cause:** duplicate computation with different seeds; Table 8 also has
  a genuinely different HR (.82 versus .70).
- **New:** Tables 2 and 3 share exact ARE and ERE rows. PH ARE at HR=.70 and
  HR=.82 is identical to `1e-12`, as expected from scale invariance. ERE is not
  forced equal across HR because the finite alternatives are different.
- **Proposed fix:** retain the exact shared-row assertion for Tables 2/3 and the
  ARE-only invariance assertion across Tables 2/8; keep captions explicit about
  HR so the ERE rows are not presented as the same setting.

### 21–22. Figure style and typography

- **Root cause:** duplicated local styles and debug annotations.
- **New:** one shared map is used everywhere: Cox red solid, D-RMST blue
  dashed, RAH green dotted, signal black dashed. Debug annotations and 26/42.5
  markers are gone; Figure 6 uses the requested cosine title; fonts were
  enlarged. All seven PDFs were rendered to PNG and visually checked after the
  final update; no clipping or overlap remains.
- **Proposed fix:** use the generated PDFs and correct the remaining manuscript
  caption typo in Phase 2.

## Re-read items N1–N4

### N1. CheckMate ARE/ERE gap

Common truncation substantially closes the D-RMST/Cox gap: ARE=.915 versus
ERE=.935 (absolute gap .019), compared with old .766/.883 in the review. For
RAH/Cox the new values are 1.199/1.332 (gap .133), smaller than the reviewed
1.058/1.232 gap (.174) but not eliminated. The remaining difference is
compatible with B=500 Monte Carlo variability and finite-alternative effects;
it should be described rather than claimed to vanish.

### N2. CheckMate alpha(t)

The fitted Weibull log-HR is unbounded as t approaches zero. At month 1 it is
.187, it crosses zero near 1.97 months, and it is -.693 at month 24.
Use the proposed finite-time wording from the brief.

### N3. ERE statistic definition

Confirmed. All three EREs are computed from unstandardized statistics on the
same replicate: Cox log-HR coefficient, D-RMST difference, and log-RAH
contrast. Efficacy is `mean(U)^2/var(U)` for each; no test mixes U and Z.

### N4. ARE computation

Confirmed. All methods use the same `ares_v2` theory call, grid step .01, and
rectangular integration. Ratio identities pass to `1e-12` for every result.

## Decisions requested at Gate 1

1. **D1 — horizons:** confirm the implemented tau=40 (simulations) and tau=24
   (CheckMate), with Cox administratively censored at the same tau. This matches
   the decision already stated in the brief.
2. **D2 — fading t_M:** choose 21.25 (what the existing code/old figures used)
   or 43 (what the manuscript says). **Approved: 43.**
3. **D3 — heavy censoring:** keep lambda_c=.025 and report S_C(40)=.058, or
   retune lambda_c to target .04. The current audit keeps .025.
4. **D4 — Table 7:** approve the three panels retained here—analysis horizon,
   dropout rate, and hazard structure—with one shared baseline result displayed
   in each panel.
5. **D5 — Table 1:** recommend using the common-tau Cox estimate everywhere
   and adding a footnote that it is administratively truncated at 24 months,
   rather than preserving a one-off untruncated Cox result.
6. **D6 — Table 6/Figure 7:** choose the proposed finer/interpolated method or
   retain the original 50-patient grid. **Approved: retain the original grid,
   with no interpolation.**

## Approved Gate 1 resolutions applied in Phase 2

- Simulations use a common 40-month analysis horizon; CheckMate 057 uses a
  common 24-month horizon, including administrative truncation before Cox
  fitting.
- The fading-benefit null time is `t_M=43`. This is a DGP parameter, not the
  40-month analysis horizon. The regenerated results preserve the qualitative
  ordering D-RMST > Cox > RAH.
- Heavy censoring retains `lambda_c=0.025`; the manuscript reports the derived
  `S_C(40)=0.058` rather than retuning the design.
- Table 7 retains the horizon, dropout, and hazard-structure panels.
- Table 1 reports the common-24-month Cox analysis and explains the truncation
  in its caption.
- Sample-size thresholds use the existing grid 100, 150, ..., 500 and the
  first simulated point reaching 80% power, without interpolation.

Phase 2 replaces manuscript results with generated macros, tables, and figures;
applies the algebra and notation corrections; and records textual changes in
`audit/TEXT_CHANGELOG.md`.
