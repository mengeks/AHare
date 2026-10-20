Subject: Re: AH-ARE — CheckMate 057 censoring model

Hi Hajime,

Thank you for reviewing the manuscript and clarifying the censoring assumption.

I have changed the CheckMate administrative censoring window to Uniform(13,28), retaining independent exponential dropout at 0.005 per month, and rerun the ARE, ERE, power, and sample-size calculations.

The theoretical values match your expectations: ARE(D-RMST/Cox) = 0.778, ARE(RAH/Cox) = 1.067, and ARE(RAH/D-RMST) = 1.372; the corresponding cos² values are 0.603, 0.469, and 0.643 for Cox, D-RMST, and RAH.

I also added the censoring-model paragraph to Section 5 and regenerated the CheckMate tables, figures, and in-text numbers. I described the dropout rate as a working assumption assessed in the sensitivity analysis. The CheckMate ordering remains RAH > Cox > D-RMST. On the existing 50-patient-per-arm grid, the sample sizes reaching 80% power are 300, 400, and 250 per arm for Cox, D-RMST, and RAH.

Your Introduction revisions are preserved. The analysis methods and seeds are unchanged, and the other experiments reproduce their previous results exactly.

Best,
Xiang

---
Draft only: not sent. The update is currently local and has not yet been committed or pushed.

