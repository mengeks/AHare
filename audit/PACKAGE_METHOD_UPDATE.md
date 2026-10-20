# Package-backed calculations and simplified entry point

Follow-up requested 2 October 2026. Scientific design, seeds, Monte Carlo
counts, ERE definition, power error policy and manuscript sources are unchanged.

## Implementation

- RMST point contrasts for ERE now use survRM2's own `rmst1` core, pinned to
  1.0-4. Observed analyses and power continue to use public `rmst2`.
- Simulation AH estimates and log-scale variances now come from public
  `survAH::ah1`; observed analyses continue to use public `ah2`.
- The previous handwritten implementation is frozen under `audit/` solely
  as an independent regression-test reference, not an active experiment path.
- `run_all.R --install-deps` incorporates the previous dependency setup.
  `--check-deps` verifies versions without running analysis. The separate
  dependency installer, replication shell wrapper and replication guide are
  removed; all current instructions are in README. Git retains their history.
- Mixed-config partial runs no longer build manuscript outputs until all
  result objects match the current config. Cache checks remain config-based;
  source changes require `--force` as documented in README.

## Boundary conventions deliberately retained

`rmst2` rejects some samples with insufficient follow-up at tau. Applying that
check to ERE would newly discard contrasts the previous pipeline retained.
The package's single-arm integral core preserves the existing KM-tail
extension instead. Similarly, `ah2` rejects zero KM survival at tau, whereas
`ah1` still supplies the point contrast. Its single-arm outputs preserve the
existing ERE/power handling without inserting observations or changing tau.

There is also a near-tie distinction. Original per-arm `survfit` calls use
`timefix=TRUE`; survRM2's KM core does the same, while raw survAH calculations
use exact time comparisons. We preprocess each arm with the same public
`survival::aeqSurv` routine before calling ah1. This retains the existing
convention, rather than changing the estimator when adopting package code.
See the [survival documentation](https://www.stat.ethz.ch/R-manual/R-devel/library/survival/html/aeqSurv.html).

The initial raw-package batch exposed ERE differences up to approximately
1e-6. A controlled 2,000-replicate replay of the PH shape=2, Light scenario
found three affected samples: maximum raw log-RAH contrast error 1.145056e-4,
versus 3.552714e-15 after matching timefix. The exact seeds and errors are in
`near_tie_equivalence.csv`; `check_near_tie_equivalence.R` regenerates them.
The unfinished raw-package full run was stopped and is not validation evidence.

## Verification

Method regression tests cover PH/non-PH, exact and near ties, zero events,
zero KM survival, insufficient follow-up, all-method power NA retention and
serial/parallel reproducibility. Maximum same-data error was 2.84e-14.
The separate 30-sample comparison to ah2 also passes within 1.2e-14.

Dependency setup was tested in a separate temporary project with an empty
user library and renv available: missing survRM2/survAH were detected, restored
from the pinned cache, and the final version check passed. Network/socket/cache
permission was required in the execution sandbox. The global R library was
not modified. Invalid CLI flags and missing `--only` values fail explicitly.

Full package-backed replication: **PASS**. In an isolated clone based on
fa907be with the updated method/entry-point/test sources overlaid,
`Rscript run_all.R --install-deps --force` reran all seven experiments in
914.959 seconds (15.25 minutes), including display generation and tests.
`package_method_comparison.csv` compares every result object after excluding
execution metadata: maximum absolute numerical difference 1.021405e-14;
all 11 tables and `numbers.tex` are byte-identical. All power points match.
The committed pre-switch results are retained because their numerical
outputs are unchanged; this follow-up does not replace their provenance.

All 11 regenerated figure pages are pixel-identical to the committed
reference at 100 dpi. The pre-existing user-modified working PDFs also
render identically to that reference; their bytes/session log are preserved.
Representative regenerated plots were visually inspected. This follow-up
does not compile or edit either manuscript or the shared project.

Validated method-source SHA-256:
`d1cfe72a0e8a71696376081f95b7b2cc052c720ada09715ffbf053bc477007c1`.

No shared coauthor files were edited. Pre-existing working-copy changes to
the figures and session log are outside this follow-up and are preserved.
