# CheckMate 057 update: Uniform(13,28)

Date: 5 October 2026. All new analysis and manuscript edits are in the private AH-ARE folder.

## Outcome and comparison baseline

GitHub was pulled first on branch `reproducible-pipeline-audit`. The baseline is commit `d4b42e4` (the latest available commit at the pull), not the 27 September PDF or older private audit results. The private repository was fast-forwarded from 3d99cc2 to d4b42e4 after preserving its existing work.

The CheckMate administrative censoring window was changed from Uniform(6,30) to Uniform(13,28). Independent exponential dropout remains 0.005/month. All seven experiments were rerun because the config hash changed. The completed run took 1108.313 seconds (18.47 minutes), with four processes and R 4.5.1.

The six theoretical benchmarks match Hajime's expected values to the reported three decimals. Existing seeds, fitted Weibull parameters, horizons, replicate counts, sample-size grid, integration grid, estimators, and sample-retention rules were not changed. The CheckMate ARE, ERE, and power differences below are caused by the censoring-law change; they are not a different-seed rerun.

## Numerical changes

Baseline: tau = 24 months, n = 300 per arm, B_ERE = 500, B_power = 2000. Theory retains the existing 0.05-month integration grid.

| Metric | Pulled baseline: U(6,30) | Updated: U(13,28) |
| --- | ---: | ---: |
| ARE(D-RMST/Cox) | 0.928 | 0.778 |
| ARE(RAH/Cox) | 1.207 | 1.067 |
| ARE(RAH/D-RMST) | 1.300 | 1.372 |
| ERE(D-RMST/Cox) | 0.935 | 0.776 |
| ERE(RAH/Cox) | 1.332 | 1.167 |
| ERE(RAH/D-RMST) | 1.425 | 1.504 |
| cos²(Cox) | 0.558 | 0.603 |
| cos²(D-RMST) | 0.518 | 0.469 |
| cos²(RAH) | 0.673 | 0.643 |
| Power: Cox | 0.717 | 0.849 |
| Power: D-RMST | 0.680 | 0.725 |
| Power: RAH | 0.842 | 0.889 |
| First grid n with ≥80% power: Cox | 400 | 300 |
| First grid n with ≥80% power: D-RMST | 400 | 400 |
| First grid n with ≥80% power: RAH | 300 | 250 |

The existing sample-size rule is retained: the first simulated point attaining 80% power on the 100–500, 50-patient-per-arm grid. No interpolation or new sample-size method was introduced.

RAH > Cox > D-RMST remains the CheckMate fitted non-PH ordering in baseline ARE/ERE and at all nine simulated power-grid points. That ARE/ERE ordering also holds in the non-PH horizon/dropout sensitivity rows. In the PH sensitivity row, Cox is most efficient, as stated in the existing manuscript.

All six unaffected experiments are exactly identical outside metadata, not merely within Monte Carlo error: checkmate_observed, main_ph, main_nonph, appendix_hr082, appendix_tau10, appendix_crossing. Thus this update does not change observed-data estimates, the fitted event-time model, or main/appendix simulation results.

Full-precision per-cell comparisons are saved in:
- [Efficiency/cosine comparison](/Users/xmeng/Partners HealthCare Dropbox/Xiang Meng/Apps/Overleaf/AH-ARE/AHare/audit/uniform1328_efficiency_changes.csv)
- [Power comparison](/Users/xmeng/Partners HealthCare Dropbox/Xiang Meng/Apps/Overleaf/AH-ARE/AHare/audit/uniform1328_power_changes.csv)
- [Exact unchanged-result checks](/Users/xmeng/Partners HealthCare Dropbox/Xiang Meng/Apps/Overleaf/AH-ARE/AHare/audit/uniform1328_unchanged_experiments.csv)

## Code/documentation changed

| File | Change |
| --- | --- |
| [config.yaml](/Users/xmeng/Partners HealthCare Dropbox/Xiang Meng/Apps/Overleaf/AH-ARE/AHare/config.yaml:38) | CheckMate censoring window [6,30] → [13,28], plus trial-design comment. This is the only numerical config change. |
| [make_numbers.R](/Users/xmeng/Partners HealthCare Dropbox/Xiang Meng/Apps/Overleaf/AH-ARE/AHare/make_numbers.R:73) | Generate administrative lower/upper bounds, dropout rate, and approximate annual dropout probability as LaTeX macros. |
| [make_tables.R](/Users/xmeng/Partners HealthCare Dropbox/Xiang Meng/Apps/Overleaf/AH-ARE/AHare/make_tables.R:88) | Generate the censoring-window statement in the three CheckMate table captions from saved result metadata. |
| [tests/test_consistency.R](/Users/xmeng/Partners HealthCare Dropbox/Xiang Meng/Apps/Overleaf/AH-ARE/AHare/tests/test_consistency.R:6) | Assert the new window, rounded theoretical benchmarks, and agreement of the four new design macros with config. Benchmarks are test expectations, not production inputs. |
| [README.md](/Users/xmeng/Partners HealthCare Dropbox/Xiang Meng/Apps/Overleaf/AH-ARE/AHare/README.md:19) | Document the design-stage censoring law and actual runtime. |
| [run_all.R](/Users/xmeng/Partners HealthCare Dropbox/Xiang Meng/Apps/Overleaf/AH-ARE/AHare/run_all.R:86) | Logging-only cleanup: omit trailing whitespace after Arguments: for a run without CLI arguments. No workflow or statistical change. |

No statistical source in R/ or experiments/, or legacy test fixture, was changed.

## Generated outputs changed

Scientifically changed:

- [results/checkmate_sim.rds](/Users/xmeng/Partners HealthCare Dropbox/Xiang Meng/Apps/Overleaf/AH-ARE/AHare/results/checkmate_sim.rds): all CheckMate design-stage ARE, ERE, cosine, power, and sample-size results.
- [output/numbers.tex](/Users/xmeng/Partners HealthCare Dropbox/Xiang Meng/Apps/Overleaf/AH-ARE/AHare/output/numbers.tex): updated CheckMate numerical macros and four new censoring-design macros.
- [output/tables/table5-checkmate-are-ere.tex](/Users/xmeng/Partners HealthCare Dropbox/Xiang Meng/Apps/Overleaf/AH-ARE/AHare/output/tables/table5-checkmate-are-ere.tex).
- [output/tables/table6-checkmate-power.tex](/Users/xmeng/Partners HealthCare Dropbox/Xiang Meng/Apps/Overleaf/AH-ARE/AHare/output/tables/table6-checkmate-power.tex).
- [output/tables/table7-checkmate-sensitivity.tex](/Users/xmeng/Partners HealthCare Dropbox/Xiang Meng/Apps/Overleaf/AH-ARE/AHare/output/tables/table7-checkmate-sensitivity.tex).
- [output/figures/figure6-cosine-checkmate057.pdf](/Users/xmeng/Partners HealthCare Dropbox/Xiang Meng/Apps/Overleaf/AH-ARE/AHare/output/figures/figure6-cosine-checkmate057.pdf).
- [output/figures/figure7-checkmate-power.pdf](/Users/xmeng/Partners HealthCare Dropbox/Xiang Meng/Apps/Overleaf/AH-ARE/AHare/output/figures/figure7-checkmate-power.pdf).
- [output/figures/summary-checkmate-sensitivity.pdf](/Users/xmeng/Partners HealthCare Dropbox/Xiang Meng/Apps/Overleaf/AH-ARE/AHare/output/figures/summary-checkmate-sensitivity.pdf).

Run metadata only:

- results/checkmate_observed.rds
- results/main_ph.rds
- results/main_nonph.rds
- results/appendix_hr082.rds
- results/appendix_tau10.rds
- results/appendix_crossing.rds
- [output/replication_runtime.txt](/Users/xmeng/Partners HealthCare Dropbox/Xiang Meng/Apps/Overleaf/AH-ARE/AHare/output/replication_runtime.txt)

The six RDS scientific payloads above are unchanged; only their metadata reflects the current config. output/sessionInfo.txt is unchanged. The other eight generated tables are byte-identical. The other eight figures rendered identically and their baseline PDF bytes were preserved to avoid meaningless PDF timestamp differences.

The generated table filenames retain the historical table5/table6/table7 prefixes. With Hajime's current Introduction (which comments out the old observed-data table), these appear as Tables 4/5/6 in the compiled paper. LaTeX cross-references are automatic; no table source was renumbered manually.

## Manuscript and diff

- [paper.tex](/Users/xmeng/Partners HealthCare Dropbox/Xiang Meng/Apps/Overleaf/AH-ARE/paper.tex:868): added the Section 5 design-stage censoring paragraph, citing Borghaei2015. It uses generated config macros. Hajime's Introduction revisions and other manuscript wording were preserved.
- [refs.bib](/Users/xmeng/Partners HealthCare Dropbox/Xiang Meng/Apps/Overleaf/AH-ARE/refs.bib:215): copied the missing FDA2025OS reference from the collaborator folder, resolving the citation already present in Hajime's Introduction. No introduction text was changed.
- [Exact paper source patch](/Users/xmeng/Partners HealthCare Dropbox/Xiang Meng/Apps/Overleaf/AH-ARE/AHare/audit/PAPER_05OCT2026.diff).
- [Exact bibliography patch](/Users/xmeng/Partners HealthCare Dropbox/Xiang Meng/Apps/Overleaf/AH-ARE/AHare/audit/REFS_05OCT2026.diff).
- [Updated manuscript PDF](/Users/xmeng/Partners HealthCare Dropbox/Xiang Meng/Apps/Overleaf/AH-ARE/AHare/output/pdf/AH-ARE-05Oct2026.pdf).
- [Numerical manuscript redline PDF](/Users/xmeng/Partners HealthCare Dropbox/Xiang Meng/Apps/Overleaf/AH-ARE/AHare/output/pdf/AH-ARE-05Oct2026-diff.pdf).

The redline freezes both versions' generated numbers and expands their table inputs before comparison; it therefore marks changed table cells and macro-based in-text numbers even though paper.tex contains the same macro names. Its baseline combines the unedited current manuscript with d4b42e4 outputs. Graphics are not pixel-redlined; old figures remain in the backup for side-by-side comparison. The review copy removes booktabs rules to support latexdiff's cell markup, without changing production tables.

Additional private audit artifacts created:
- audit/check_checkmate_uniform1328.R (comparison and censor-pattern diagnostics).
- audit/build_checkmate_update_diff.py (frozen-input redline builder).
- audit/qa_checkmate_pdfs.py (PDF rendering/contact sheets for visual review).
- audit/uniform1328_censor_pattern.csv.
- audit/CHECKMATE_UNIFORM1328_CHANGE_REPORT.md (this report).
- audit/EMAIL_TO_HAJIME_05OCT2026.md (reply draft).
- output/pdf/AH-ARE-05Oct2026-diff.tex and the before/after expanded source files used for the redline.

## Censoring-model qualification

The [primary trial report](https://pmc.ncbi.nlm.nih.gov/articles/PMC5705936/) supports enrollment in November 2012–December 2013, the March 2015 database lock, and minimum follow-up of 13.2 months. Uniform(13,28) is a rounded design-stage administrative window, not an estimate of each reconstructed patient's censoring distribution. Dropout at 0.005/month is retained as requested; 1 − exp(−12 × 0.005) = 5.82% per year, reported as about 6%.

Under the fitted event-time model, a diagnostic of observed censoring conditional on C < T gives:

| Diagnostic | Reconstructed data | Working model |
| --- | ---: | ---: |
| Overall censoring fraction | 28.01% | 28.32% |
| Median observed censoring time (months) | 17.65 | 17.11 |
| Fraction of censored observations before 13.2 months | 4.91% (8/163) | 17.31% |

Thus the overall fraction and median are close, but the early tail is not fully reproduced. The manuscript intentionally describes a design-informed working model and does not assert complete reproduction of the censoring pattern. No dropout re-fitting was performed.

Lu's hand-edited ARE values are plausibly consistent with this window, but their exact generating run remains unavailable. A read-only finer-grid check gave AREs 0.766/1.060/1.383 at 0.01 months, whereas production keeps the original 0.05 grid and matches Hajime's supplied 0.778/1.067/1.372. This supports compatibility, not proven provenance; neither the grid nor production values were altered to match a hand-edited number.

## Verification and preservation

- Full pipeline completed successfully; method-regression and cross-output consistency tests passed.
- Legacy same-data method/DGP regression maximum error: 2.44e−15.
- All seven saved results match the new config hash.
- Updated manuscript and numerical redline compiled successfully (28 pages each); references/citations are resolved.
- All pages and the three changed figures were visually reviewed. Existing minor overfull-box warnings remain, with no clipping in the changed content.
- git diff --check passes.

A full pre-pull backup is at:
/Users/xmeng/Partners HealthCare Dropbox/Xiang Meng/Apps/Overleaf/AH-ARE/local-history/hajime-censoring-before-20261005-pfkWdM

It includes old paper.tex, refs.bib, paper.pdf, private results/output/audit, and frozen d4b42e4 GitHub results/output. The old tracked private audit/output also remain in a recoverable Git stash named “Preserve private audit and outputs before 2026-10-05 GitHub pull”.

The collaborator AHare repository was only pulled and is clean at d4b42e4. The collaborator paper.tex and refs.bib were not edited. Local audit artifacts remain private and are not intended for the clean GitHub branch.

No commit, push, or email sending was performed for this update.

