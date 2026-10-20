# AHare reproducible analysis

All analysis commands run from the `AHare/` repository root.

Prerequisites: Git and R (tested with R 4.5.1; the pinned Matrix version
requires R >= 4.4). `--install-deps` restores missing/mismatched packages from
`renv.lock` into the local `.library/`, without changing the global R library.
Internet access is needed for cloning and package restoration. This command
runs every simulation, generates all tables, figures and in-text number
macros, and executes the method-regression and cross-output consistency tests.
R itself and TeX are not installed by the pipeline.

With dependencies already installed, a full independent rerun is simply:

```bash
Rscript run_all.R --force
```

The complete run took 18.47 minutes on the development Mac with four processes.
Runtime depends on hardware and whether dependency installation is needed.
Parallel computation is implemented in `R/utils_methods.R` using
`parallel::mclapply(..., mc.cores = workers)`. `project.workers: 4` in
`config.yaml` means up to four parallel R processes on macOS/Linux. Set it to
`1` for serial computation; Windows runs serially. Each replicate is explicitly
seeded, so scheduling does not change its data. Changing workers changes the
config hash and triggers recomputation even though the numerical design is unchanged.

## Reuse the committed results (no simulation rerun)

The branch includes `results/`, `output/tables/`, `output/figures/` and
`output/numbers.tex`. A clone already contains the inputs needed to compile
the manuscript; no R command is needed merely to use those inputs.

To rebuild displays from current saved results and run the tests:

```bash
Rscript run_all.R
```

Experiments are skipped when their saved config hash matches `config.yaml`.
Use `--force` after changing statistical code or when checking independent
replication; the cache check does not hash the R source files.

For one experiment, or to check dependency versions without running analysis:

```bash
Rscript run_all.R --only checkmate_sim --force
Rscript run_all.R --check-deps
```

Valid experiment names: `checkmate_observed`, `main_ph`, `main_nonph`,
`checkmate_sim`, `appendix_hr082`, `appendix_tau10`, `appendix_crossing`.
Run the unrestricted entry point after a partial run to ensure all results
and displays use the same config.

## Methods and software

All methods use the same analysis horizon within a comparison: 40 months in
the main simulations, 24 months for CheckMate 057, and 10 months in the
short-horizon appendix. Cox follow-up is administratively censored at that horizon.
CheckMate design-stage calculations use independent censoring
`C = min(U, E)`, with `U ~ Uniform(13, 28)` months and exponential dropout
at 0.005/month, motivated by accrual and the March 2015 database lock.

- Cox: `survival::coxph`; original score p-values for PH simulation power,
  original Wald p-values for CheckMate power and observed analyses.
- D-RMST: public `survRM2::rmst2` for ERE, power and observed analyses,
  retaining the original tau-support check. Unsupported repeats return NA
  for D-RMST only; finite Cox/RAH results are retained independently.
- RAH: `survAH::ah1` supplies simulation point contrasts and the original
  main/appendix power calculation; `survAH::ah2` supplies CheckMate power
  and observed analyses. Original method-specific NA rules are retained.
  Per-arm `survival::aeqSurv` preprocessing preserves the near-tie convention
  already used by the original `survfit` calculation and survRM2's KM core.
- ARE/cosine: shared theoretical integration in `R/utils_theory.R`, not
  empirical package estimates. ERE is squared mean contrast divided by its
  Monte Carlo variance, not an efficacy calculation on standardized Z scores.
  Original numerical grids are retained (theory: 0.01 months for simulations,
  0.05 for CheckMate; non-PH generation/calibration: 0.1 months).

Pinned versions: yaml 2.3.10, digest 0.6.37, survival 3.8-3, survRM2 1.0-4,
survAH 1.2.0, Matrix 1.7-3, lattice 0.22-7; `renv.lock` also pins renv 1.2.3.
`output/sessionInfo.txt` records the actual environment;
`output/replication_runtime.txt` records total entry-point time, while each
result object's metadata records its experiment runtime, config and seed.
