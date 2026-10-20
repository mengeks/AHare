# Replication and differences from the 27 September manuscript

**Current shared-code update:** the later requested restoration to actual
legacy methods is recorded in [LEGACY_METHOD_RESTORE.md](LEGACY_METHOD_RESTORE.md).
The comparisons below describe the pre-restoration pipeline and remain
historical evidence; they must not be mistaken for the current shared code.

Audit date: 2 October 2026. Branch: `reproducible-pipeline-audit`.
Numerical pipeline independently cloned from GitHub at `e510dbf`; subsequent
changes add dependency setup, presentation, source export, and audits, not
a new simulation design or statistical method.

This section records the initial replication audit. The later switch to
package-backed empirical calculations, with the same estimators and design,
is documented separately in `PACKAGE_METHOD_UPDATE.md`.

## Evidence and limits

The supplied `AH-ARE-27Sep2026.pdf` is the numerical comparison authority.
Its SHA-256 is in `old27_pdf_sha256.txt`. `old27_table_cells.csv` extracts
474 numeric cells from Tables 1–11. `cell_changes_vs_27Sep.csv` pairs every
one with its current value, delta, contributors, and whether the ratio
crosses 1. Of these, 393 differ at displayed precision. This is not a count
of bugs. Cause labels are not a full factorial decomposition of each delta.

Legacy sources are in `scripts/main-sim-paper/`, `scripts/appendix-sim-paper/`,
`scripts/checkmate057/`, and `R/dgp-tian2017.R`. The new `experiments/`
directory is active code. Keep the legacy sources and historical outputs
in this **private checkout**, not in the cleaned collaborator checkout.
The complete older tree is also recoverable from Git commit `3d99cc2`.
Some old editable inputs no longer match the 27Sep PDF; unknown historical
configurations are labeled unknown rather than reconstructed by guesswork.

The fresh clone `/tmp/ahare-clean-gtlS0a/AHare` ran all seven experiments
with `Rscript run_all.R --force`, not a cache-only rebuild. All seven result
objects are exactly identical after removing execution metadata. Summed
experiment runtime was 2,249.1 seconds (37.49 minutes), excluding dependency
installation and PDF compilation. Per-experiment times are in
`clean_replication_results.csv`. Statistical sources/configuration are
unchanged from `e510dbf`; final display builders and exported sources were
then copied into the clone to rebuild the two presentations. Environment:
R 4.5.1, macOS arm64, four forked workers. Package versions and setup are
in `README.md` and `output/sessionInfo.txt`.

Both fresh-clone builds passed rendered-page comparison: all 29 pages of
the tables version and all 33 pages of the figures version are identical
at 100 dpi. All 11 generated table inputs and `numbers.tex` match exactly.
The independent clone's dependency check/build took another 6 seconds after
calculation (cached dependency check; not a first-time installation).
The dependency restore path was separately tested successfully. All seven
original figures and four summary figures were visually inspected in the
compiled versions; all three delivered manuscripts/redline were rendered
and inspected. Existing small TeX overfull-box warnings remain; no clipping
or overlap was found in this pass. The built-in standalone compiler cannot
resolve this multi-file project; the existing local TeX/latexmk build
provides the successful compilation evidence.

## Decision summary: what is OK and what is unresolved

Here, **OK** means a checked explanation, not that every old/new difference
is inside a 95% Monte Carlo band. **EXPLAINED, non-MC** means an identified
design, horizon, or implementation-policy change. **UNRESOLVED** means the
exact source of particular old PDF numbers has not been recovered; it does
not mean the current pipeline failed replication. **MC not quantified**
means no cell-specific MC interval has been measured, not a known bug.

ARE is deterministic: **no ARE change can be explained by seed or MC error**.
For ERE, the checked nominal two-batch MC criterion below is
`abs(new - old) <= 1.96 * sqrt(SE_old^2 + SE_new^2)`, using paired-method
bootstrap SEs. It is an approximate, cell-wise criterion, not a simultaneous
confidence guarantee across all tables.

| Cells/comparisons | Status | Can we say only seed/batch differs? |
|---|---|---|
| Table 2 RAH/D-RMST ERE: S0=.30 Light; S0=.50, .70, .90 under both censoring levels (7 cells) | **OK — within nominal 95% MC band** | **Yes**, for these ratios only: same event/censoring DGP, n, B, horizon and point contrasts; different MC batches. |
| Table 3 RAH/D-RMST ERE: every row except kappa=.826 Light (9 cells) | **OK — within nominal 95% MC band** | **Yes**, for these ratios only. |
| Table 3 kappa=.826 Light RAH/D-RMST ERE .870 → .942 | **OK — verified seed-only, but outside nominal 95% MC band** (2.25 combined MC SEs) | **Yes**. Do not describe it as inside the usual 95% MC range. |
| Table 2 RAH/D-RMST ERE: S0=.10 Light/Heavy; S0=.30 Heavy | **EXPLAINED — RMST support/retention policy plus seed** | **No**: the old RMST calculation omitted 4, 166 and 2 replicates respectively; the current ERE calculation retains their KM-tail point contrasts. |
| Table 1 Cox; Cox-related ARE in Tables 2–3, 8–10 | **EXPLAINED, non-MC — common analysis horizon** | No; Table 1 is an observed-data analysis, not a simulation. |
| Cox-related ERE/power in Tables 2–3, 8–10; Table 6 | **Known non-MC changes plus new batches; cell-specific MC contribution not quantified** | No: Cox horizon changed; Table 9 Cox power also changed score → Wald. Table 2 has the retention exceptions above. |
| Table 4 fading ARE/ERE | **EXPLAINED, non-MC — t_M=21.25 → 43**, plus numerical grids/seeds for ERE | No, including RAH/D-RMST. |
| Table 4 delayed ERE; other empirical cells not checked in the 20-cell replay | **MC not quantified; do not give blanket MC clearance** | Not established. Delayed DGP numerical grids also changed; appendix support/retention must not be assumed identical without checking. |
| Tables 5/7: all 27 ERE cells | **EXPLAINED — full paired horizon/policy/batch decomposition; all batch residuals within nominal 95% MC bands.** B=500, not 2000. | Only the 8 RAH/D-RMST ERE cells outside dropout=.020 are seed/batch-only. Cox-related cells also change horizon; dropout=.020 D-RMST-related cells also change RMST support retention. |
| Tables 5/7: the 21 ARE cells matching historical outputs | **EXPLAINED, non-MC — exact horizon/integration-grid decomposition** | No: ARE is deterministic. |
| Table 5's 3 ARE cells and Table 7 tau=24's 3 ARE cells | **UNRESOLVED — six old printed cells do not match preserved code/output** | No; deterministic discrepancy. See the exact triples below. |
| Table 11 old ARE/ERE | **UNRESOLVED — exact old generating model/run not recovered; current printed-model calculation OK** | No; deterministic ARE changes and a changed ordering rule out a seed-only explanation. |

Thus **16 main-PH RAH/D-RMST ERE cells are explicitly cleared as within MC
error and seed-only**, one further cell is seed-only but a nominal 95%
outlier, and three involve a verified retention-policy change. There is no
blanket “all remaining differences are Monte Carlo noise” conclusion.

## Changes by table

| Tables | Verified contributors | Important distinction |
|---|---|---|
| 1 | Observed Cox now truncated at 24 months; old Cox used all observed follow-up (maximum 26.7 months in both reconstructions). | D-RMST/RAH estimates unchanged; intro had original/sensitivity D-RMST order swapped. |
| 2–3 | Cox theory horizon 42.5 → 40; empirical Cox full follow-up → 40. New deterministic seeds; repeated scenario reuses one batch. Three Table 2 rows also change RMST support/retention. | n=400, B=2000 unchanged; S0 already calibrated at 40. Table 3 RAH/D-RMST ERE is seed-only; Table 2 has the three verified exceptions listed above. |
| 4 | Fading cutoff 21.25 → 43; common Cox horizon; new seeds; inverse-survival/effect-calibration grids refined. | Large RAH/D-RMST ARE shifts are not Monte Carlo noise. Delayed RAH/D-RMST ARE unchanged at displayed precision. |
| 5, 7 | Legacy generating scripts and saved CSVs identified: all old Table 5 ERE cells and 45/48 old Table 7 cells match at printed precision. Current Cox uses the row-specific horizon instead of theoretical t_H=26 / empirical full follow-up; integration grid and MC batches also changed. | Unresolved provenance is limited to the three old Table 5 ARE values and their three appearances in Table 7's tau=24 row, not the whole tables or horizon panel. |
| 6 | Cox truncation and new MC batches; original 50-patient grid retained. | No interpolation. Shared RAH variance agrees with old survAH::ah2 on identical samples. |
| 8–9 | PH horizon/seed changes; Table 9 old Cox power used score-test p-values, current power uses the declared Wald test. | HR=.82, n=400, B=2000 unchanged. |
| 10 | Cox theory 11 → 10; empirical Cox truncated at 10; new seeds. | n=150, B=500 unchanged; not a B=2000 experiment. |
| 11 | Current values reproduce the printed crossing model at t_M=43. No verified run for old printed cells; old ARE matches neither 21.25 nor 43. | ARE and ordering change: not seed noise. Exact old provenance unresolved. |

## Table 3: 0.870 → 0.942

The user-identified legacy source is
`scripts/main-sim-paper/table-main-sim-ph-hr070-kappa-050-200-light-heavy.R`.
It is a **table builder**, not the simulation generator: it calls
`main_sim_summarize_table()` in `main-sim-paper-common.R` to read saved raw
replicates. Unless `MAIN_SIM_RUN_DIR` is set, it selects the latest eligible
timestamped run. The preserved `20260629_170854` batch matches **all ten**
old PDF RAH/D-RMST ERE values, not just the disputed baseline row.

This is the **Light**, not Heavy, row at kappa=.826 and S0(40)=.50.
The Heavy row changes .669 → .656. Legacy B=2000 batch starts at seed
221234; current at 44388351. n=400, B, event/censoring DGP, and D-RMST/RAH
contrasts remain unchanged for this PH setting.

On 25 identical old samples, current contrasts match saved legacy contrasts
to 3.4e-14 (D-RMST) and 1.3e-15 (RAH). Replaying all 2,000 current samples
reproduces the current RAH/D-RMST ERE exactly, .9420365. A paired bootstrap
resamples all methods' statistics together:

| Batch | RAH/D-RMST ERE | MC SE | Approximate 95% interval |
|---|---:|---:|---:|
| Old seeds | .8698 | .0218 | .830–.915 |
| Current seeds | .9420 | .0235 | .897–.988 |

The .0723 difference is about 2.25 combined MC SEs. The matched-data check
supports seed/batch variation, not an estimator change. Such deviations can
occur across hundreds of cells. There is no universal “B=2000 implies
±.03–.05” bound: ERE is a ratio of estimated squared means/variances and its
uncertainty is scenario-specific. See `check_legacy_ere.R`, `ere_mc_se.csv`,
and the saved `legacy_ere_replay.rds`. Replay needs the local historical raw
CSV (not all timestamped raw files are tracked); the saved replay is tracked.

## Full Table 2/3 RAH/D-RMST ERE MC check

`check_main_ph_seed_mc.R` checks old `settings.csv` against every current
scenario, matches all 20 old displayed ratios to the PDF, and replays all
18 distinct current scenarios (B=2000 each). All replayed current EREs
match the saved results within 1e-10. On 25 same-seed datasets per old row,
finite old point contrasts match to 6.7e-14 (D-RMST) / 4.3e-15 (RAH).
For the three rows with old RMST exclusions, all 2000 old seeds are replayed
and all finite saved contrasts are checked. Bootstrap resampling keeps the
methods paired within each batch and uses 2000 bootstrap draws per batch.
Detailed evidence is in `main_ph_seed_mc_check.csv` and
`main_ph_seed_mc_replay.rds`; the check took 32.0 seconds. It did not replace
saved experimental results or paper inputs.

| Table | Setting | Old → new ERE | Combined MC z | Decision |
|---|---|---|---:|---|
| 2 | S0=.10, Light | .902 → .940 | 1.72 | Retention + seed; not seed-only |
| 2 | S0=.10, Heavy | .775 → .727 | -2.04 | Retention + seed; not seed-only |
| 2 | S0=.30, Light | .899 → .879 | -0.67 | **OK: seed-only, within MC band** |
| 2 | S0=.30, Heavy | .658 → .677 | 0.76 | Retention + seed; not seed-only |
| 2 | S0=.50, Light | .895 → .942 | 1.41 | **OK: seed-only, within MC band** |
| 2 | S0=.50, Heavy | .707 → .656 | -1.78 | **OK: seed-only, within MC band** |
| 2 | S0=.70, Light | .914 → .950 | 0.95 | **OK: seed-only, within MC band** |
| 2 | S0=.70, Heavy | .654 → .670 | 0.50 | **OK: seed-only, within MC band** |
| 2 | S0=.90, Light | .874 → .905 | 0.73 | **OK: seed-only, within MC band** |
| 2 | S0=.90, Heavy | .643 → .646 | 0.06 | **OK: seed-only, within MC band** |
| 3 | kappa=.500, Light | .951 → .942 | -0.30 | **OK: seed-only, within MC band** |
| 3 | kappa=.500, Heavy | .733 → .725 | -0.30 | **OK: seed-only, within MC band** |
| 3 | kappa=.826, Light | .870 → .942 | 2.25 | **OK: seed-only; outside nominal 95% band** |
| 3 | kappa=.826, Heavy | .669 → .656 | -0.46 | **OK: seed-only, within MC band** |
| 3 | kappa=1.000, Light | .870 → .879 | 0.26 | **OK: seed-only, within MC band** |
| 3 | kappa=1.000, Heavy | .614 → .628 | 0.51 | **OK: seed-only, within MC band** |
| 3 | kappa=1.500, Light | .833 → .832 | -0.01 | **OK: seed-only, within MC band** |
| 3 | kappa=1.500, Heavy | .590 → .569 | -0.74 | **OK: seed-only, within MC band** |
| 3 | kappa=2.000, Light | .797 → .805 | 0.21 | **OK: seed-only, within MC band** |
| 3 | kappa=2.000, Heavy | .572 → .521 | -1.70 | **OK: seed-only, within MC band** |

The three retention cases require a separate distinction. Old `rmst2`
returns NA for insufficient tau support, while old RAH keeps the KM-tail
point contrast. Current **ERE** uses the package's single-arm KM integral
for both methods and retains those contrasts. This policy predates the
subsequent package substitution; the package switch itself was numerically
equivalent to the refactored pipeline, not necessarily to every legacy
`rmst2` exclusion. Holding the **old seeds fixed** gives:

| Table 2 setting | Old finite D-RMST / RAH counts | Old ERE | Same old seeds, current retention | Current seeds/retention |
|---|---|---:|---:|---:|
| S0=.10, Light | 1996 / 2000 | .902466 | .903627 | .939533 |
| S0=.10, Heavy | 1834 / 2000 | .775147 | .763544 | .727284 |
| S0=.30, Heavy | 1998 / 2000 | .657961 | .657607 | .677237 |

Therefore even the two changes inside the displayed nominal MC band must
not be called seed-only. This audit identifies the policy difference; it
does **not** change it or claim that tail extension is scientifically
equivalent to restricting analysis to supported replicates.

## Fading benefit: the old cutoff really was 21.25

Old `R/dgp-tian2017.R` defaults to `t_M=TAU_H/2=21.25`, not 43.
Old Table 4 **does** match the preserved non-PH CSV and timestamped LaTeX.

| Fading RAH/D-RMST | 27Sep | Current |
|---|---:|---:|
| Light ARE | .510 | .669 |
| Light ERE | .404 | .637 |
| Heavy ARE | .376 | .494 |
| Heavy ERE | .289 | .454 |

At 21.25 benefit disappears halfway through analysis; at 43 it wanes
throughout 0–40 months. This changes the signal and ARE even without Cox.
The approved 43 matches the stated scientific model. The conclusion remains
D-RMST > Cox > RAH.

**Correction to Gate 1:** its statement that the old Table 4 artifact could
not be matched was too strong. Direct comparison to the PDF and preserved
files establishes the match. Small theory discrepancies in a modern replay
at 21.25 reflect historical numerical grids; the large current shift reflects
the cutoff change.

## t_M intuition (English)

In the fading-benefit model, t_M is the time when the treatment hazard ratio
reaches 1 and benefit disappears. It controls the duration of benefit;
tau controls how long follow-up is analyzed. With t_M=43 and tau=40,
benefit wanes throughout the analysis window but does not fully disappear
within it. Setting t_M=tau is not required and changes the scientific model.

In the crossing model, t_M sets the time scale of the increase in log hazard
ratio; it is not the crossing time. For alpha(t)=log(.46)+(t/t_M)^s,
the crossing time is t_M[-log(.46)]^(1/s). With s=1 and t_M=43, HR crosses
1 near month 33.39.

## Baseline and censoring: what actually changed

“Common baseline” means displays claiming the **same scenario** use the
same configuration/results. It does not replace all simulated hazards with
one baseline. Main tables already calibrated S0 at 40. Old Figures 2–4
instead used S0(42.5)=.30; current figures use the table DGP, including
S0(40)=.50 for non-PH examples. Thus the calibration discrepancy was mainly
between figures and tables, not a calibration change in every table cell.

The CheckMate baseline is the original-data fitted Weibulls, tau=24,
dropout=.005/month, Uniform(6,30) administrative censoring, n=300, B=500.
Table 5 and three Table 7 appearances now share one result row. Old prose
said Uniform(13,28), whereas the preserved generating code uses (6,30).

The old scripts **are present**:
`scripts/checkmate057/table-cm057-are-ere.R` and
`scripts/checkmate057/table-cm057-sens-are.R`, with their shared parameters
in `checkmate057-common.R`. They use tau=24, theoretical Cox t_H=26,
empirical Cox full follow-up, Uniform(6,30), dropout=.005, n=300,
B=500, seed=2024, and integration increment=.05. The sensitivity script
uses one sequential RNG stream and independently simulates repeated
baseline settings. The new pipeline uses common row-specific horizons,
increment=.01, deterministic scenario seeds, and one reused baseline batch.
These are documented changes; Cox-related ERE differences are **not**
classified as seed-only MC noise without a paired decomposition.

On 2 October, a read-only replay of the Table 5 theoretical section matched
its saved CSV to 4.7e-15. Comparison with `old27_table_cells.csv` confirms:

| Old PDF cells | Preserved output | Status |
|---|---|---|
| Table 5: all three ERE values (.883, 1.232, 1.395) | `output/checkmate057/paper/table-cm057-are-ere.csv` | Historical output identified; matches printed precision. |
| Table 7: 45/48 values, including all 24 ERE values and all ARE values outside tau=24 | `output/checkmate057/paper/table-cm057-sens-are.csv` | Historical output identified; matches printed precision. |
| Table 5: ARE .766/1.058/1.381; Table 7 tau=24: .766/1.058/1.380 | The scripts/CSVs instead give .906447/1.178071/1.299657 | Exact provenance of these six printed cells remains unresolved. ARE is deterministic, so this mismatch is not MC noise. |

All preserved timestamped baseline/sensitivity ARE-ERE CSVs were also
checked and have the same relevant ARE values as the stable outputs.
In the old PDF, Table 7's tau=24, dropout=.005, and fitted non-PH rows
claim the same baseline but have different ARE values; the saved script
outputs give identical ARE values for these three rows. This establishes
an old PDF/output inconsistency, but does not prove whether it arose from
manual editing or an unpreserved run. Trying Uniform(13,28) gets close but
does not establish the exact provenance of the six unmatched cells.

### Tables 5/7: the actual large discrepancies

Ratio order in the triples below is **D-RMST/Cox, RAH/Cox, RAH/D-RMST**.

| Comparison | Old PDF | Preserved old code/output | Current | Interpretation |
|---|---|---|---|---|
| Table 5 ARE | .766 / 1.058 / 1.381 | .906 / 1.178 / 1.300 | .915 / 1.199 / 1.310 | The large PDF → current shift includes an old PDF/output mismatch. Only the exact old printed triple is unresolved. |
| Table 5 ERE | .883 / 1.232 / 1.395 | Same as PDF | .935 / 1.332 / 1.425 | Paired replay resolves the horizon and seed/batch contributions; all batch residuals within nominal 95% MC bands. Only RAH/D-RMST is seed-only. |
| Table 7 tau=18 ARE | .531 / .964 / 1.817 | Same as PDF | .651 / 1.198 / 1.841 | Explained deterministic correction: old Cox uses 26 months while alternatives use 18; current all use 18, with refined integration grid. RAH/Cox crosses 1. |
| Table 7 tau=18 ERE | .451 / .943 / 2.091 | Same as PDF | .607 / 1.292 / 2.127 | Empirical Cox was full-follow-up, now 18 months; new MC batches also contribute. Not seed-only. |
| Table 7 tau=21 ARE | .731 / 1.110 / 1.519 | Same as PDF | .789 / 1.211 / 1.533 | Old output identified; horizon/grid correction, not MC. |
| Table 7 tau=24 ARE | .766 / 1.058 / 1.380 | .906 / 1.178 / 1.300 | .915 / 1.199 / 1.310 | Same unresolved old-PDF triple as Table 5, including a .001 rounding/copy discrepancy. |
| Table 7 dropout=.005 and fitted non-PH ARE | .906 / 1.178 / 1.300 | Same as PDF | .915 / 1.199 / 1.310 | These old baseline rows are identified; much smaller horizon/grid shifts. |

In particular, **the old tau=18 and tau=21 rows are not unresolved**.
The earlier blanket wording about the entire horizon panel was too broad.
The unresolved Tables 5/7 issue is exactly **six ARE cells**, not their ERE
cells and not the entire tables. `check_checkmate_old_cells.R` independently
replays the old theoretical prefix without executing its MC/output writers;
`checkmate_old_cell_provenance.csv` records all 54 comparisons and the six
mismatches. The current repeated baseline views agree by construction and
pass the consistency tests; no current calculation is left failing here.

### Tables 5/7: per-cell paired attribution (2 October follow-up)

`decompose_checkmate_changes.R` replays 9 historical 500-replicate batches
(Table 5 plus all 8 Table 7 rows) and all 6 distinct current scenario
batches. Every historical ERE matches its saved CSV, and all current
ARE/ERE match `results/checkmate_sim.rds` to the asserted 1e-10 tolerance.
Fitted Weibull parameters, Uniform(6,30), row-specific dropout, n=300,
and B=500 are unchanged. No manuscript or primary result file was edited.

The decomposition is a specified sequential path, not a unique factorial
allocation: old PDF -> preserved old output -> change Cox horizon on the
same data -> change RMST support retention on the same data -> change MC
batch. For ARE, the last deterministic step is grid .05 -> .01 instead
of support/batch. Tiny PDF-rounding residuals are retained in the CSV.

In the same-data comparisons, finite D-RMST/RAH contrasts agree within
2.7e-15. One exception concerns **retention, not the finite contrast**:
Table 7 dropout=.020, old replicate 100 has maximum follow-up 23.99733
months in arm 0 and 28.92811 in arm 1. Public `rmst2(tau=24)` rejects it;
old D-RMST ERE uses 499 valid contrasts, whereas the current ERE uses 500
KM-tail point contrasts. Its separate effect is +.002275 on D-RMST/Cox
and -.002867 on RAH/D-RMST. RAH/Cox is unaffected by this RMST policy.
All other historical and current batches have 500 valid contrasts per
method. This historical support-policy difference predates the package
switch; the package switch itself retained current results.

Below, "large" means absolute old-PDF/current difference >= .05, solely
as a reporting threshold, not a significance test. D=D-RMST, R=RAH,
C=Cox. Contributions use unrounded replay values, displayed to .001;
rounding can prevent displayed components from summing exactly.

#### Large ARE differences: all 10 cells

"Unmatched old" is the old-PDF -> preserved-output gap, whose generating
provenance remains unknown, not a proved editing error. Cox theory was
26 months; its new horizon is the row's tau. No ARE contribution is MC.

| Table / setting | Ratio | Old -> current | Unmatched old | Cox horizon | Grid |
|---|---|---|---:|---:|---:|
| 5 baseline | D/C | .766 -> .915 | +.140 | +.022 | -.013 |
| 5 baseline | R/C | 1.058 -> 1.199 | +.120 | +.029 | -.008 |
| 5 baseline | R/D | 1.381 -> 1.310 | -.081 | .000 | +.010 |
| 7 tau=18 | D/C | .531 -> .651 | .000 | +.133 | -.013 |
| 7 tau=18 | R/C | .964 -> 1.198 | .000 | +.242 | -.008 |
| 7 tau=21 | D/C | .731 -> .789 | .000 | +.071 | -.013 |
| 7 tau=21 | R/C | 1.110 -> 1.211 | .000 | +.108 | -.008 |
| 7 tau=24 | D/C | .766 -> .915 | +.140 | +.022 | -.013 |
| 7 tau=24 | R/C | 1.058 -> 1.199 | +.120 | +.029 | -.008 |
| 7 tau=24 | R/D | 1.380 -> 1.310 | -.080 | .000 | +.010 |

#### Large ERE differences: all 16 cells

Cox is changed from full follow-up to row-specific tau on the **same old
samples**. "Batch" changes only the random sample after applying current
horizon/point-retention conventions. Each batch residual below is within
its nominal 95% two-batch MC band: **OK**. Total differences involving
Cox or the retention exception are not described as seed-only.

| Table / setting | Ratio | Old -> current | Cox truncation | RMST retention | Seed/batch |
|---|---|---|---:|---:|---:|
| 5 baseline | D/C | .883 -> .935 | +.056 | .000 | -.005 |
| 5 baseline | R/C | 1.232 -> 1.332 | +.079 | .000 | +.021 |
| 7 tau=18 | D/C | .451 -> .607 | +.157 | .000 | -.001 |
| 7 tau=18 | R/C | .943 -> 1.292 | +.329 | .000 | +.020 |
| 7 tau=21 | D/C | .676 -> .768 | +.088 | .000 | +.004 |
| 7 tau=21 | R/C | 1.145 -> 1.299 | +.149 | .000 | +.005 |
| 7 tau=24 | R/C | 1.221 -> 1.332 | +.067 | .000 | +.043 |
| 7 dropout=.001 | D/C | .834 -> .895 | +.040 | .000 | +.021 |
| 7 dropout=.001 | R/D | 1.455 -> 1.367 | .000 | .000 | -.088 |
| 7 dropout=.005 | D/C | .882 -> .935 | +.055 | .000 | -.003 |
| 7 dropout=.005 | R/C | 1.210 -> 1.332 | +.076 | .000 | +.046 |
| 7 dropout=.005 | R/D | 1.371 -> 1.425 | .000 | .000 | +.054 |
| 7 dropout=.020 | R/C | 1.461 -> 1.369 | +.049 | .000 | -.142 |
| 7 dropout=.020 | R/D | 1.381 -> 1.278 | .000 | -.003 | -.100 |
| 7 fitted non-PH | D/C | .874 -> .935 | +.033 | .000 | +.028 |
| 7 fitted non-PH | R/D | 1.483 -> 1.425 | .000 | .000 | -.058 |

Bootstrap resamples methods together within each batch (4,000 draws).
After horizon/retention adjustments, **all 27 ERE batch residuals** are
inside +/-1.96 combined MC SEs; the largest absolute z is 1.824. This is
an approximate marginal criterion, not a simultaneous guarantee or proof
that every total old/new difference is MC. The old repeated baseline rows
used separate sequential batches; current views reuse one scenario batch,
explaining why their empirical numbers now agree exactly.

Category summary:

1. **Cox horizon correction — explained, non-MC.** Accounts for most large
   tau=18/21 Cox-related changes; it causes the tau=18 RAH/Cox ordering
   reversal. Fitted baseline RAH > Cox > D-RMST is unchanged.
2. **Integration grid — explained, non-MC.** Step .05 -> .01 affects ARE
   only, including RAH/D-RMST; it does not explain ERE shifts.
3. **Seed/batch and baseline reuse — checked MC, OK.** All 27 adjusted ERE
   residuals pass the nominal MC criterion. Eight RAH/D-RMST ERE cells
   outside dropout=.020 are genuinely seed/batch-only.
4. **RMST support retention — explained implementation policy, non-MC.**
   One sample at dropout=.020 affects two ERE ratios; its contribution is
   small and separately quantified. Do not label these ratios seed-only.
5. **Six old printed ARE cells — provenance unresolved.** Restricted to
   Table 5 ARE and Table 7 tau=24 ARE; the old PDF/output gap is the dominant
   contribution in these cells. Current theory reproduces successfully.
6. **DGP, fitted baseline parameters, sample size or B changes — ruled out
   between the recovered historical scripts/outputs and current runs.**
   "Common baseline" is result/config reuse, not a different baseline
   hazard or a changed censoring window in these runs. This cannot establish
   the generating DGP of the six still-unmatched old printed ARE cells.

Full 54-cell numeric attribution and MC SE/z values:
`checkmate_change_decomposition.csv`; paired replay data:
`checkmate_change_decomposition.rds`; retention/sample counts:
`checkmate_replay_diagnostics.csv` and `checkmate_rmst_support_exception.csv`.
Re-run from the repository root with
`Rscript audit/decompose_checkmate_changes.R`; `--summarize-only` reuses
the explicitly saved audit replay, checks its config, and recomputes summaries.

Heavy censoring parameters are unchanged: lambda_c=.025, U~Uniform(24,43).
S_C(40)=exp(-.025*40)*(43-40)/(43-24)=.058086, not .04; Light=.154390.
The prose correction does not retune censoring, which remains heavier.

“Misidentified” meant citing the RAH/D-RMST column (.812) as RAH/Cox (.798),
not patient misidentification. The editorial aside was removed; the paper
now simply states both correct comparisons.

## Table 11: what is and is not resolved

The current crossing design is explicit: tau=40, S0(40)=.50,
`alpha(t)=log(.46)+(t/43)^1`, n=400 and B=2000, with the main simulation's
Light/Heavy censoring. Its crossing time is approximately 33.39 months.
Current calculations reproduce this model and pass pipeline replication.

| Censoring / quantity | Old PDF: D/C, R/C, R/D | Current: D/C, R/C, R/D |
|---|---|---|
| Light ARE | 1.040 / 1.072 / 1.031 | 1.193 / .683 / .573 |
| Heavy ARE | 1.041 / 1.053 / 1.012 | 1.016 / .429 / .422 |
| Light ERE | 1.027 / 1.075 / 1.047 | 1.272 / .599 / .471 |
| Heavy ERE | 1.021 / 1.070 / 1.048 | 1.060 / .374 / .353 |

**Current-model calculation: OK. Old-number provenance: UNRESOLVED.**
The six old ARE values match neither the preserved old default t_M=21.25
nor the printed/current t_M=43 model. No verified old generating run has
been linked to the six old ERE values either. This is not an MC-only change;
in particular, the ARE discrepancy cannot come from a random seed.

It is also incorrect to infer a coding error merely because all three old
ratios exceed 1: they consistently imply **RAH > D-RMST > Cox**, which is
mathematically possible. What is established is that those numbers do not
reproduce the stated crossing model. We have **not localized a specific
old erroneous code line**, so “a verified old coding bug was fixed” would
overstate the evidence. The current ordering **D-RMST > Cox > RAH** is a
material correction relative to the old PDF, not an unchanged conclusion.

## No RAH variance-formula change

Old CheckMate calls `survAH::ah2`; shared simulation code computes the same
log-RAH contrast/variance. Thirty matched datasets at n=150,300,400 give
maximum errors 2.1e-15 (contrast), 3.9e-17 (variance), 1.2e-14 (p-value).
See `rah_same_data_equivalence.csv` and `check_rah_equivalence.R`.

## Qualitative conclusions: two exceptions to communicate

Main PH, fading, delayed, and fitted CheckMate rankings remain. Near-tie
ERE reversals occur; Section 4.4 now allows them explicitly.

- Table 7 tau=18: RAH/Cox ARE .964 → 1.198; ERE .943 → 1.292. The current
  common-horizon sensitivity supports RAH over tau=18–24; the old sensitivity
  interpretation was not identical.
- Table 11 Light ARE D/C=1.193, R/C=.683, R/D=.573; Heavy
  1.016/.429/.422. ARE and ERE now give D-RMST > Cox > RAH, replacing
  the old appendix claim that both alternatives exceed Cox. This is material.

Current CheckMate n80 points are 400/400/300 (Cox/D-RMST/RAH), old
350/400/250, on the same 50-patient grid. n=250 RAH power is near .8,
making this threshold particularly sensitive to MC variation. Current
power at n=300 is .717/.680/.843. At n<300 the existing shared function can
return unavailable tests when rmst2 cannot support tau, and power averages
finite replicates. That behavior was preserved; it was not silently changed.
The n>=300 threshold rows have finite 2,000-replicate denominators in the
controlled check.

## Presentation and merge

Tables 2,3,8,9,10 are grouped Light/Heavy first, parameter second. Figure 1's
caption was restored. Both compiled versions use the same calculations:
main-text tables, or four replacement figures plus concrete tables in
Appendix F. The redline expands frozen old/new input trees; formatting
changes may replace a whole table. It is not an exact editable reconstruction
of the 27Sep PDF. Use the 474-cell CSV for exact old/new numerical comparison.

Technical merge readiness requires clean result comparisons, tests, setup,
and both fresh-clone PDF comparisons to pass. Scientific sign-off should
acknowledge Table 11 and the horizon-sensitivity correction; do not write
“all qualitative conclusions unchanged.” Old Table 11 provenance remains a
historical limitation. No merge or manuscript overwrite is performed.

## Clean collaborator checkout: entry-point repair on 2 October

The collaborator checkout deliberately omits `audit/`, `scripts/`,
`manuscript/` and `old/`, and retains the user's concise README. Its failure
was a regression test sourcing the deleted
`audit/reference_methods_pre_package_switch.R`. The reference formulas now
live in `tests/fixtures/reference_methods_pre_package_switch.R`, and only
that test's source path changes. No experiment, config, saved result,
README content, or manuscript source was changed by this repair.

Validation: pinned dependency check passed; package regression tests passed
(maximum error 2.84e-14); all consistency assertions passed. A temporary
copy of the actual cleaned working tree, not an old Git snapshot, completed
`Rscript run_all.R` in 2.732 seconds using all seven cached result objects.
All 11 table inputs and `numbers.tex` were byte-identical after rebuilding.
All 11 rebuilt figure pages were also pixel-identical to the collaborator's
existing PDFs at 100 dpi; PDF timestamp differences were not treated as
scientific differences.
This is an end-to-end **cached entry-point check**, not another forced MC
replication. The earlier full forced replications remain the numerical
replication evidence. Generated files were rebuilt only in the temporary
copy, preserving the collaborator's existing output files.

The shared parent `paper.tex` was not edited or compiled. Its before/after
SHA-256 is
`35ad7e8fae1e33c8984f0fc5a30e453283ddc5bf8cdceb5106a0b8ee250e0eb7`.
The private audit remains in this private checkout and in the older Git
snapshot; no audit directory is restored to the collaborator checkout.
This follow-up leaves changes local; it does not commit, push, or merge the
collaborator's pending cleanup or the private audit updates.
