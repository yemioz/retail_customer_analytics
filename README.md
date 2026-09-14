# Retail Customer Analytics

> A retail analytics project covering relational data modeling, SQL-based business reporting, and Bayesian modeling of promotion effects, built on more than 14.6 million simulated coffee-shop transactions.

## Overview

The project started as a retail business-intelligence analysis and grew into a deeper customer-behavior study. I wanted the analysis to answer questions that a retail or marketing team would actually care about:

- How do members and guests differ in purchasing behavior?
- Which products, categories, and discounts perform best?
- How does customer retention change across acquisition cohorts?
- Are promotions associated with customers spending more before the discount is applied?
- Are promoted transactions associated with larger baskets?

The workflow begins with raw monthly CSV files, cleans transaction identifiers in Python, loads the data into PostgreSQL, and builds analytical views with SQL. The Bayesian notebook then uses the SQL-generated modeling dataset to quantify the uncertainty around promotion-related differences.

This is an observational analysis. Promotion assignment was not randomized, so the Bayesian results describe **associations**, not causal promotional lift.

## Dataset at a glance

- **14,623,691** transactions across **17** modeling fields
- **617,551** promoted transactions (**4.22%** of all transactions)
- Loyalty membership is almost evenly split overall: **50.01% member transactions**
- Guests account for **56.82%** of promoted transactions
- Mean pre-discount transaction value is **$33.25** without a promotion and **$33.23** with a promotion
- Median pre-discount transaction value is **$31.00** in both groups
- Average basket size is approximately **4 items** in both groups

## Key Findings

The descriptive analysis showed very little separation between promoted and non-promoted transactions before discounts were applied. The Bayesian analysis reached the same conclusion after accounting for posterior uncertainty.

| Outcome | Selected model | Posterior mean difference | 94% credible interval |
|---|---|---:|---:|
| Pre-discount transaction value | Gamma regression with log link | -0.21% | [-2.03%, 1.53%] |
| Basket size | Zero- and upper-truncated Poisson | -0.27% | [-2.36%, 1.66%] |

For both outcomes, the credible interval includes zero and the posterior places essentially no probability on a difference of 5% or more. In this dataset, promotion use is **not associated with a practically meaningful change in pre-discount purchasing behavior**.

The notebook also showed why model checking matters:

- A Lognormal model produced a heavier upper tail than the observed transaction-value distribution.
- The Gamma likelihood provided a better posterior predictive fit for `original_amount`.
- A standard Poisson generated impossible basket sizes, so the final count model was truncated to the observed support of 1–9 items.
- A dispersion-flexible Generalized Poisson sensitivity model did not materially improve fit; its dispersion parameter concentrated near zero, supporting the simpler truncated Poisson.

See the full analysis in [`notebooks/customer_behavior.ipynb`](notebooks/customer_behavior.ipynb).

The part I found most useful was the model-selection process: several models produced similar treatment estimates, but their posterior predictive behavior was not equally believable. Keeping that distinction visible made the final conclusion more defensible and made the project a better representation of how I approach analytical work.

## Highlights

- Built a normalized PostgreSQL data model for customers, transactions, line items, products, stores, payment methods, and vouchers.
- Cleaned monthly transaction files in Python and bulk-loaded them into PostgreSQL using `COPY FROM STDIN`.
- Developed reusable SQL views for customer behavior, product/category performance, discount usage, and cohort retention.
- Built a transaction-level modeling dataset in SQL for promotion analysis.
- Used Bayesian regression in PyMC to test whether promoted transactions differ in **pre-discount spending** or **basket size**.
- Compared competing likelihoods with prior predictive checks, posterior diagnostics, and posterior predictive checks instead of selecting a model from fit statistics alone.
- Kept rejected count-model experiments in the repository to show the model-selection process rather than hiding unsuccessful approaches.

## Data and SQL Design

The PostgreSQL schema separates transaction-level and line-item data rather than flattening everything into one table.

Core tables include:

- `transactions`
- `transaction_items`
- `users`
- `menu_items`
- `stores`
- `payment_methods`
- `vouchers`

Guest purchases are represented by a nullable `user_id`, and non-promoted transactions by a nullable `voucher_id`. `transaction_items` uses an identity-generated surrogate key because a transaction can contain repeated item records.

SQL is used for both business reporting and model-ready feature construction. The repository includes views for:

- average transaction value
- customer summaries
- member vs. guest purchasing patterns
- product and category performance
- discount performance
- first purchase and monthly activity
- cohort retention
- promotion-analysis features such as basket size, distinct items, category count, transaction hour, and promotion/member indicators

### SQL example: cohort retention

One of the reusable SQL workflows calculates retention by acquisition cohort. The window function keeps each cohort's original size available while monthly active-user counts change over time:

```sql
SELECT
    TO_CHAR(cohort_month, 'FMMONTH YYYY') AS cohort_month,
    months_since_signup,
    active_users,
    FIRST_VALUE(active_users) OVER (
        PARTITION BY cohort_month
        ORDER BY months_since_signup
    ) AS cohort_size,
    ROUND(
        active_users * 100.0
        / FIRST_VALUE(active_users) OVER (
            PARTITION BY cohort_month
            ORDER BY months_since_signup
        ),
        2
    ) AS retention_rate
FROM analytics.retention_counts;
```

This sits on top of separate `first_purchase`, `user_activity`, and cohort-offset views, so the retention calculation is reproducible rather than embedded in a dashboard-only transformation.

## Bayesian Customer Behavior Analysis

For transaction $i$, promotion usage is represented by $T_i \in \{0,1\}$. The analysis estimates the promotion-group coefficient $\tau$ for two outcomes.

A small piece of the model specification shows how the business effect is connected to the likelihood. For the selected Gamma model,

$$
Y_i \sim \operatorname{Gamma}(\mu_i,\sigma),
\qquad
\log(\mu_i)=\alpha+\tau T_i.
$$

Because the model uses a log link, $e^{\tau}$ is the promoted-to-non-promoted mean ratio, and the percent difference is

$$
100\left(e^\tau-1\right).
$$

That transformation is what turns the posterior coefficient into the business-facing effect reported in the results table.

### Pre-discount spending

Two likelihoods are evaluated:

- Lognormal
- Gamma with a log link

Priors are evaluated with prior predictive simulation before the models are fitted. Posterior predictive checks are then used to decide which likelihood better reproduces the observed transaction-value distribution.

The Gamma model is retained because it better represents the upper tail while giving the same substantive result as the Lognormal model.

### Basket size

Basket size is observed on the discrete support $\{1,\ldots,9\}$. The final model therefore uses a zero- and upper-truncated Poisson likelihood rather than allowing impossible zero-item or very large baskets.

For the truncated count model, the notebook calculates the expected basket size from the truncated distribution directly instead of treating $e^\tau$ as the observed mean ratio.

### Python example: recovering the expected basket size after truncation

The count-model coefficient lives on the underlying Poisson-rate scale, so I calculate the expected basket size from the normalized truncated probabilities before reporting the promotion effect:

```python
def truncated_poisson_mean(mu, lower=1, upper=9):
    k = np.arange(lower, upper + 1)

    logp = (
        k * np.log(mu[:, None])
        - mu[:, None]
        - gammaln(k + 1)
    )
    logp -= logp.max(axis=1, keepdims=True)

    p = np.exp(logp)
    p /= p.sum(axis=1, keepdims=True)

    return (p * k).sum(axis=1)
```

This avoids reporting the latent rate ratio as though it were automatically the observed mean basket-size ratio after truncation.

Rejected or superseded alternatives are documented in [`notebooks/experiments/`](notebooks/experiments/).

## Project Workflow

```text
Monthly retail CSV files
        |
        v
Python preprocessing
src/preprocess_transactions.py
        |
        v
PostgreSQL ingestion
src/load_postgres.ipynb
        |
        v
Relational schema + validation
sql/schema.sql
sql/eda.sql
        |
        v
Reusable KPI / customer views
sql/kpi_views/
        |
        v
Modeling view
sql/modeling/promo_analysis_dataset.sql
        |
        v
Bayesian customer behavior analysis
notebooks/customer_behavior.ipynb
```

Large source and generated CSV files are intentionally not included in the repository. The analysis expects local raw/processed data directories when the pipeline is run.

## 📁 Repository Structure

```text
retail_customer_analytics/
├── data/
│   ├── raw/
│   │   ├── transactions/
│   │   ├── transaction_items/
│   │   ├── users/
│   │   ├── menu_items/
│   │   ├── stores/
│   │   ├── vouchers/
│   │   └── payment_methods/
│   └── processed/
│       ├── transactions_clean/
│       └── promo_analysis_dataset.csv
├── notebooks/
│   ├── customer_behavior.ipynb
│   └── experiments/
│       ├── README.md
│       ├── standard_poisson_basket_size.ipynb
│       └── zero_upper_truncated_generalized_poisson.ipynb
├── sql/
│   ├── schema.sql
│   ├── eda.sql
│   ├── kpi_views/
│   │   ├── cohort_retention_analysis/
│   │   └── member_vs_nonmember_summary/
│   └── modeling/
│       └── promo_analysis_dataset.sql
└── src/
    ├── preprocess_transactions.py
    └── load_postgres.ipynb
```

## Usage

The main analysis is designed to be read as a portfolio notebook:

1. Review the database design in [`sql/schema.sql`](sql/schema.sql).
2. Review the exploratory and validation queries in [`sql/eda.sql`](sql/eda.sql).
3. Browse the reusable business views under [`sql/kpi_views/`](sql/kpi_views/).
4. Open [`notebooks/customer_behavior.ipynb`](notebooks/customer_behavior.ipynb) for the Bayesian promotion analysis.
5. See [`notebooks/experiments/`](notebooks/experiments/) for count models that were tested and rejected.

To rebuild the local pipeline, place the source CSV files in the expected `data/raw/` directories, run the preprocessing step, create the PostgreSQL schema, load the files, and generate the modeling export used by the notebook.

## Tools

**Database and analytics:** PostgreSQL, SQL  
**Programming:** Python, pandas, NumPy  
**Bayesian modeling:** PyMC, ArviZ, ArviZ Plots  
**Visualization:** Matplotlib, Seaborn  
**Database connectivity:** psycopg2

## ⚠️ Limitations

- The underlying retail data are simulated, so the business findings should not be treated as estimates from a real operating company.
- Promotion assignment is observational rather than randomized; the promotion models estimate associations, not causal effects.
- The primary Bayesian models are unadjusted promotion-group comparisons. Loyalty status differs somewhat between promoted and non-promoted transactions, although the descriptive subgroup patterns are very similar.
- Large raw and processed CSV files are excluded from the repository because of their size.
- The final basket-size model captures the overall support and center of the distribution but does not reproduce every individual basket-size frequency exactly.