Subject: AH-ARE: revised manuscript and reproducible analysis

Hi Hajime,

I have prepared a revised AH-ARE manuscript with a reproducible pipeline.
All three tests now use the same horizon: 24 months for CheckMate 057 and
40 months for the main simulations. The code, tables, figures and text
now use the same saved results.

Numerical changes reflect Monte Carlo variation and corrected settings,
including the Cox censoring window and fading-benefit specification. The main
findings are preserved. The updated sensitivity analysis favors RAH over Cox
throughout 18-24 months, and Table 11's crossing model now gives
D-RMST > Cox > RAH. Its previous values did not match the stated model;
the old generating run remains unverified.

To replicate the results, please use the `reproducible-pipeline-audit` branch
of [AHare](https://github.com/unoichi/AHare/tree/reproducible-pipeline-audit)
and run `Rscript run_all.R --install-deps --force` from the repository root.
The README has the details. Saved outputs are also included, so compiling
the manuscript does not require rerunning the simulations.

I also prepared a version replacing Tables 2, 3, 4 and 7 with summary figures,
while retaining the concrete tables in an appendix. Please let me know which
presentation you prefer.

Please feel free to edit the LaTeX in the shared project and run the code,
and let me know if you notice any issues.

Best,
Xiang
