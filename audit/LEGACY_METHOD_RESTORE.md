# Legacy-equivalent simulation methods (2 October 2026)

Target: the clean collaborator AHare checkout. No manuscript source edits.
This supersedes the pre-restoration implementation comparisons in
REPLICATION_AND_CHANGE_REPORT.md, while retaining that historical evidence.

## Intended scientific changes retained

1. Cox follow-up/theory horizon equals each comparison's tau: main 40,
   CheckMate 24 (18/21/24 in sensitivity), short appendix 10 months.
2. Fading-benefit t_M=43 instead of the legacy 21.25, as approved.

The crossing appendix continues to use its printed t_M=43 model. Its old
PDF cells have no identified generating run. All three pairwise ratios
being above 1 is mathematically possible (RAH > D-RMST > Cox), so it is
not by itself evidence of a coding error. The reproducible current model,
not the sign of those old ratios alone, is the basis for the corrected table.

## Other refactor differences restored to legacy behavior

| Item | Pre-restoration refactor | Restored clean pipeline |
|---|---|---|
| RMST ERE support | Internal rmst1 accepted unsupported tails | Public survRM2::rmst2, original support rejection; unsupported repeat is NA for RMST |
| Method failure handling | One method error made all methods NA | Each method fails independently, as in the original scripts |
| PH appendix Cox power | Wald | Original score test; CheckMate/observed remain original Wald |
| RAH power boundary convention | ah1 everywhere | Original main/appendix calculation via ah1; original CheckMate ah2 support rules |
| Non-PH event-time integration | 0.05-month grid; ordered inverse interpolation | Original 5000 intervals over 500 months (0.1), original mean-tie interpolation |
| Effect calibration | 0.01-month grid; different root bracket | Original 0.1-month grid and root bracket [0.0001,10] |
| CheckMate theoretical integration | 0.01-month grid | Original 0.05-month grid; one routine/grid for all tests within each comparison |

The package substitutions are checked against frozen actual legacy formulas
in tests/fixtures/reference_legacy_methods.R and reference_legacy_dgp.R.
Same seed/data comparisons include PH/non-PH generation, contrasts, p-values,
ties, zero events, zero survival, unsupported tau, independent NA retention,
and the original score/Wald and ah1/ah2 profiles. Maximum numerical difference
was 2.44e-15; tests passed. This is a stronger target than equivalence merely
to the earlier refactored implementation.

Scenario-ID seeds and reuse of identical baseline rows are retained. ERE
and power can therefore differ from old batches by Monte Carlo variation;
this does not promise that every cell is inside a nominal 95% MC band.
ARE is deterministic and must never be explained by random seeds.

A separate check against the actual legacy theoretical routines passed all
62 comparisons: 18 main-PH, 26 HR=.82 appendix, six short-horizon appendix,
four fading/delayed, and eight CheckMate sensitivity views. Maximum error
under the same approved design/horizon was 5.33e-15. The RAH/D-RMST ARE
is invariant to Cox truncation; fading comparisons explicitly hold t_M=43
on both implementations. These are implementation checks, not claims that
the untraceable old crossing PDF has the same generating design. Evidence:
check_restored_theory.R and restored_theory_equivalence.csv.

The complete restored main-PH result confirms this directly: all 18
scenarios' AREs and RAH/Cox EREs are unchanged from the pre-restoration
results (within numerical tolerance). Only the three previously identified
RMST-support rows change their D-RMST-related EREs. RAH/D-RMST changes:
S0=.10 Light .939533 -> .939935, S0=.10 Heavy .727284 -> .739399,
S0=.30 Heavy .677237 -> .677605. These are corrections back to the legacy
rule, not additional intended scientific changes versus the original code.

After restoring the public rmst2 support mask, all 20 Table 2/3
RAH/D-RMST ERE comparisons are now seed/batch-only relative to the preserved
old runs. Paired bootstrap MC checks clear 19/20 within nominal 95% combined
MC bands. Table 3 kappa=.826 Light remains a 2.25-MC-SE outlier (.869785 ->
.942036); it is seed-only but must not be described as inside that band.
The formerly mixed support/seed Table 2 S0=.10 Heavy comparison is now
.775147 -> .739399, z=-1.45. Evidence: restored_main_ph_mc_check.csv and
check_restored_main_ph_mc.R; current raw contrasts are in
restored_main_ph_mc_replay.rds.

CheckMate rerun: the 80%-power grid points remain Cox/D-RMST/RAH =
400/400/300. At n=300, power is .7165/.6800/.8424212. Original ah2
support checks now apply to RAH power independently of RMST failures.

Restoring the original CheckMate 0.05-month integration grid gives the
fitted-PH D-RMST/Cox ARE 1.005300 (a numerical near-tie). A read-only
same-design grid check gives .994748 at 0.01 and .993437 at 0.005. Thus
the coarse-grid result slightly above 1 should not be interpreted as
substantive D-RMST superiority under PH. This is a retained legacy
quadrature limitation, not a reason to alter the original formulas here.

## One versus four workers

Pilot: B=300, three workloads, two repetitions, reversing worker order on
the second repetition. Warm-up is excluded. Same seeds were used throughout;
all 1/4-worker summaries were exactly identical.

| Workload | Mean 1-worker seconds | Mean 4-worker seconds |
|---|---:|---:|
| PH ERE, n=400 | 7.845 | 2.139 |
| PH appendix power, n=400 | 9.149 | 2.481 |
| CheckMate power, n=300 | 15.743 | 4.128 |

Total measured time: 65.471 seconds with one worker, 17.495 with four.
Four workers were 3.74 times faster on this Mac; default remains four.
Evidence: worker_pilot_legacy_restore.csv; pilot_workers_legacy_restore.R.

## Cleanup and preservation

R/main-sim-paper-helpers.R and R/sim03-helpers.R were not sourced by the
active workflow and were removed from the collaborator checkout. Originals
remain in the private checkout and Git history. No audit/ or scripts/
directory was restored to the collaborator checkout. README remains concise.
Pre-change results, outputs, config and R sources were copied to the private
audit/pre-legacy-restore-3SgK5r/ directory before regeneration.

Shared paper.tex SHA-256 before edits:
35ad7e8fae1e33c8984f0fc5a30e453283ddc5bf8cdceb5106a0b8ee250e0eb7.

## Full regeneration

Completed successfully: Rscript run_all.R --force in the collaborator
checkout, using four workers. Total entry-point time was 1099.696 seconds
(18.33 minutes), R 4.5.1. All seven experiment objects were regenerated;
all eleven tables, eleven figures and number macros were rebuilt. The
method-regression and cross-output consistency tests passed; every saved
result has the current config hash. All eleven PDF figures were rendered
and visually inspected: axes, legends and panels are readable and unclipped.

Current Table 11 supports D-RMST > Cox > RAH under both censoring settings:

| Censoring | ARE D-RMST/Cox | ARE RAH/Cox | ARE RAH/D-RMST | ERE D-RMST/Cox | ERE RAH/Cox | ERE RAH/D-RMST |
|---|---:|---:|---:|---:|---:|---:|
| Light | 1.192511 | .682822 | .572592 | 1.273285 | .596707 | .468636 |
| Heavy | 1.016436 | .429326 | .422384 | 1.059890 | .374396 | .353241 |

The shared paper.tex checksum is unchanged after regeneration. It was not
edited or compiled. No commit, push, or merge was performed.

## Wording supported by this restoration

Relative to the preserved original simulation code, the intended scientific
changes are (i) Cox administratively truncated at the common analysis
horizon and (ii) fading-benefit t_M changed from 21.25 to 43. The cleaner
workflow retains the original estimators, tests, method-specific support
rules, numerical grids, sample sizes and Monte Carlo replicate counts.

Changing t_M can affect all fading-benefit efficiency cells. Cox truncation
affects Cox-related cells, not RAH/D-RMST ARE. Outside fading benefit,
differences in RAH/D-RMST empirical efficiency relative to matched old
designs can arise from new seed/batch allocation; they should not be used
to explain deterministic ARE differences. For Tables 2/3 this seed-only
attribution has been explicitly replayed and MC-checked as described above;
it is not an assertion that every cell in every appendix has an identified
old generating run. The six historical Table 5/7 ARE provenance discrepancies
remain recorded in the earlier report and were not pursued further, as
requested.

Table 11 now reproducibly evaluates the printed crossing model and shows
D-RMST > Cox > RAH. Because the old generating run is unavailable, the
specific old error cannot be proven; all pairwise ratios above one alone
would not establish an error.
