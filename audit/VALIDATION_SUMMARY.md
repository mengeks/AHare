# Validation summary — 2 October 2026

## Initial clean-replication audit (before package-backed follow-up)

| Check | Outcome |
|---|---|
| Fresh GitHub clone at e510dbf, all seven experiments forced | PASS; no cached simulation results used |
| All seven independent RDS objects, execution metadata excluded | Exactly identical |
| Statistical R sources, experiment sources, config versus e510dbf | Unchanged in this follow-up |
| Independent calculation runtime | 2,249.103 seconds / 37.485 minutes, summed experiment times |
| Final tables and numbers.tex from independent results | All 11 tables and macros byte-identical |
| Tables manuscript, independent build | All 29 pages pixel-identical at 100 dpi |
| Figures manuscript, independent build | All 33 pages pixel-identical at 100 dpi |
| Consistency assertions | PASS in both working checkout and independent clone |
| Versioned dependency check and actual renv restore | PASS; network/cache permission needed in the sandbox |
| Same-data old/new D-RMST and RAH PH contrasts | Errors below 3.4e-14 on 25 legacy samples |
| Current B=2000 PH replay | Reproduces saved RAH/D-RMST ERE exactly |
| Same-data shared RAH versus survAH::ah2 | 30 datasets; statistic/variance/p-value agree within 1.2e-14 |
| Direct 27Sep PDF table audit | 474 cells matched; 393 changed at displayed precision |
| PDF visual QA | All pages of both manuscripts and redline inspected; four summary plots inspected separately |
| Desktop skill consolidation | Existing paper-writing preserved with focused sync addition; new reproducible-sim-pipeline; both quick-validated |

The two PDF comparisons use the final presentation sources copied into the
independent clone, after its full numerical run. Numerical sources and
configuration were not changed between that run and the final presentation.
PDF byte hashes are not expected to match because timestamps/document IDs
can differ; rendered-page pixels are identical on the tested machine.

This is not a claim of exact equality across different R/TeX/OS environments,
an exact reconstruction of the old PDF's editable source, or resolution of
the missing old Table 11 generating run. Those limits are documented in
`REPLICATION_AND_CHANGE_REPORT.md`. The scientific correction changes
Table 11's ordering and part of Table 7's horizon interpretation.

No coauthor-shared files were overwritten, no email was sent, and no merge
into main was performed.

## Package-backed follow-up

The active empirical calculations have subsequently been switched to
survRM2/survAH while retaining the existing estimators and boundary policies.
See `PACKAGE_METHOD_UPDATE.md` for the separately recorded verification.
All seven experiments were forced in an isolated clone; maximum numerical
difference from the saved results was 1.03e-14. All tables/macros are
byte-identical and all 11 figure pages are pixel-identical at 100 dpi.
Method boundary, near-tie, serial/parallel and dependency restoration tests
passed. Total entry-point time was 914.959 seconds (15.25 minutes).
