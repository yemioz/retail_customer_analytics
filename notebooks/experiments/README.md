# Experiments

Rejected or superseded modeling attempts from `basket_size` analysis, kept here as a record of the
actual exploration rather than deleted. Neither notebook is required reading to follow the main
analysis in `../customer_behavior.ipynb` — the main notebook's `zt_poisson` model is the one
actually used to answer the business question.

| Notebook | What it tried | Why it didn't make the cut |
|---|---|---|
| `standard_poisson_basket_size.ipynb` | Plain (untruncated) Poisson likelihood | Posterior predictive checks generate impossible basket sizes (0, or 10+) |
| `zero_upper_truncated_generalized_poisson.ipynb` | Custom truncated Generalized Poisson with a dispersion parameter, implemented as a `pm.CustomDist` | Fitted dispersion parameter concentrated at ≈0 — no measurable fit improvement over the simpler truncated Poisson |

Both notebooks assume the same data path as the main notebook
(`../../sql/modeling/promo_analysis_dataset.csv`) and are self-contained — each can be run
independently without first running the main notebook.
