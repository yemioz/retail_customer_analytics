/*
Retail Customer Analytics
Exploratory Data Analysis

Purpose:
    Performs exploratory analysis of transaction quality, customer composition,
    promotional usage, revenue patterns, store performance, and voucher
    performance before downstream KPI development, Power BI reporting,
    cohort analysis, and Bayesian promotional-effectiveness modeling.

Notes:
    - Member transactions are identified by user_id IS NOT NULL.
    - Guest transactions are identified by user_id IS NULL.
    - Promotional transactions are identified by voucher_id IS NOT NULL.
    - The member-vs-guest spend comparison below is descriptive and should not
      be interpreted as causal lift.
*/


-- 1. DATASET OVERVIEW

SELECT
    COUNT(*) AS total_transactions,
    MIN(created_at) AS first_transaction,
    MAX(created_at) AS last_transaction,
    ROUND(AVG(original_amount), 2) AS avg_original_amount,
    ROUND(AVG(final_amount), 2) AS avg_final_amount,
    MIN(final_amount) AS min_final_amount,
    MAX(final_amount) AS max_final_amount
FROM transactions;


-- 2. DATA QUALITY

SELECT
    COUNT(*) FILTER (
        WHERE transaction_id IS NULL
    ) AS missing_transaction_id,

    COUNT(*) FILTER (
        WHERE store_id IS NULL
    ) AS missing_store_id,

    COUNT(*) FILTER (
        WHERE payment_method_id IS NULL
    ) AS missing_payment_method_id,

    COUNT(*) FILTER (
        WHERE original_amount IS NULL
    ) AS missing_original_amount,

    COUNT(*) FILTER (
        WHERE discount_applied IS NULL
    ) AS missing_discount_applied,

    COUNT(*) FILTER (
        WHERE final_amount IS NULL
    ) AS missing_final_amount,

    COUNT(*) FILTER (
        WHERE created_at IS NULL
    ) AS missing_created_at

FROM transactions;

-- Check transaction ID uniqueness

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT transaction_id) AS unique_transaction_ids
FROM transactions;

-- Check for negative financial values

SELECT
    COUNT(*) FILTER (
        WHERE original_amount < 0
    ) AS negative_original_amount,

    COUNT(*) FILTER (
        WHERE discount_applied < 0
    ) AS negative_discount,

    COUNT(*) FILTER (
        WHERE final_amount < 0
    ) AS negative_final_amount
FROM transactions;

-- Check financial consistency

SELECT
    COUNT(*) AS inconsistent_transactions
FROM transactions
WHERE ABS(
    original_amount
    - COALESCE(discount_applied, 0)
    - final_amount
) > 0.01;


-- 3. CUSTOMER COMPOSITION

SELECT
    CASE
        WHEN user_id IS NOT NULL THEN 'Member'
        ELSE 'Guest'
    END AS customer_type,

    COUNT(*) AS transactions,

    ROUND(
        COUNT(*) * 100.0
        / SUM(COUNT(*)) OVER (),
        2
    ) AS transaction_percent

FROM transactions
GROUP BY
    customer_type;


-- 4. PROMOTION COMPOSITION

SELECT
    CASE
        WHEN voucher_id IS NOT NULL THEN 'Promotion'
        ELSE 'No Promotion'
    END AS promotion_status,

    COUNT(*) AS transactions,

    ROUND(
        COUNT(*) * 100.0
        / SUM(COUNT(*)) OVER (),
        2
    ) AS transaction_percent

FROM transactions
GROUP BY
    promotion_status;


-- Promotion usage within member / guest groups

SELECT
    CASE
        WHEN user_id IS NOT NULL THEN 'Member'
        ELSE 'Guest'
    END AS customer_type,

    CASE
        WHEN voucher_id IS NOT NULL THEN 'Promotion'
        ELSE 'No Promotion'
    END AS promotion_status,

    COUNT(*) AS transactions,

    ROUND(
        COUNT(*) * 100.0
        / SUM(COUNT(*)) OVER (
            PARTITION BY
                CASE
                    WHEN user_id IS NOT NULL THEN 'Member'
                    ELSE 'Guest'
                END
        ),
        2
    ) AS percent_within_customer_type

FROM transactions
GROUP BY
    customer_type,
    promotion_status
ORDER BY
    customer_type,
    promotion_status;


-- 5. PROMOTION VS NO-PROMOTION OUTCOMES

SELECT
    CASE
        WHEN voucher_id IS NOT NULL THEN 'Promotion'
        ELSE 'No Promotion'
    END AS promotion_status,

    COUNT(*) AS transactions,

    ROUND(
        AVG(original_amount),
        2
    ) AS avg_original_amount,

    ROUND(
        AVG(discount_applied),
        2
    ) AS avg_discount,

    ROUND(
        AVG(final_amount),
        2
    ) AS avg_final_amount,

    MIN(final_amount) AS min_final_amount,
    MAX(final_amount) AS max_final_amount
FROM transactions
GROUP BY
    promotion_status;


-- 6. PROMOTION OUTCOMES BY CUSTOMER TYPE

SELECT
    CASE
        WHEN user_id IS NOT NULL THEN 'Member'
        ELSE 'Guest'
    END AS customer_type,

    CASE
        WHEN voucher_id IS NOT NULL THEN 'Promotion'
        ELSE 'No Promotion'
    END AS promotion_status,

    COUNT(*) AS transactions,

    ROUND(
        AVG(original_amount),
        2
    ) AS avg_original_amount,

    ROUND(
        AVG(discount_applied),
        2
    ) AS avg_discount,

    ROUND(
        AVG(final_amount),
        2
    ) AS avg_final_amount

FROM transactions
GROUP BY
    customer_type,
    promotion_status
ORDER BY
    customer_type,
    promotion_status;


-- 7. MEMBER VS GUEST SPEND DIFFERENCE

WITH averages AS (
    SELECT
        ROUND(
            AVG(
                CASE
                    WHEN user_id IS NOT NULL
                    THEN final_amount
                END
            ),
            2
        ) AS avg_member_spend,

        ROUND(
            AVG(
                CASE
                    WHEN user_id IS NULL
                    THEN final_amount
                END
            ),
            2
        ) AS avg_guest_spend

    FROM transactions
)

SELECT
    avg_member_spend,
    avg_guest_spend,

    ROUND(
        (
            avg_member_spend
            - avg_guest_spend
        ) * 100.0
        / NULLIF(avg_guest_spend, 0),
        2
    ) AS member_spend_difference_percent

FROM averages;


-- 8. STORE PERFORMANCE

SELECT
    s.store_id,
    s.store_name,
    COUNT(
        t.transaction_id
    ) AS transactions,
    ROUND(
        SUM(t.final_amount),
        2
    ) AS revenue,
    ROUND(
        AVG(t.final_amount),
        2
    ) AS average_transaction_value
FROM transactions t
JOIN stores s
    ON s.store_id = t.store_id
GROUP BY
    s.store_id,
    s.store_name
ORDER BY
    revenue DESC;


-- 9. VOUCHER PERFORMANCE

SELECT
    t.voucher_id,
    v.voucher_code,
    COUNT(*) AS total_applications,
    ROUND(
        COUNT(*) * 100.0
        / (
            SELECT COUNT(*)
            FROM transactions
        ),
        4
    ) AS percent_of_transactions,
    ROUND(
        SUM(
            COALESCE(t.discount_applied, 0)
        ),
        2
    ) AS total_discount_value,
    ROUND(
        SUM(t.final_amount),
        2
    ) AS total_revenue,
    ROUND(
        AVG(t.discount_applied),
        2
    ) AS avg_discount
FROM transactions t
JOIN vouchers v
    ON t.voucher_id = v.voucher_id
GROUP BY
    t.voucher_id,
    v.voucher_code
ORDER BY
    total_discount_value DESC;


-- 10. BASKET SIZE OVERVIEW

WITH basket_size AS (
    SELECT
        transaction_id,
        SUM(quantity) AS total_items
    FROM transaction_items
    GROUP BY transaction_id
)

SELECT
    ROUND(
        AVG(total_items),
        2
    ) AS avg_basket_size,
    MIN(total_items) AS min_basket_size,
    MAX(total_items) AS max_basket_size
FROM basket_size;

-- Basket size by promotion status

WITH basket_size AS (
    SELECT
        transaction_id,
        SUM(quantity) AS total_items
    FROM transaction_items
    GROUP BY transaction_id
)

SELECT
    CASE
        WHEN t.voucher_id IS NOT NULL THEN 'Promotion'
        ELSE 'No Promotion'
    END AS promotion_status,

    COUNT(*) AS transactions,
    ROUND(
        AVG(bs.total_items),
        2
    ) AS avg_basket_size
FROM transactions t
JOIN basket_size bs
    ON t.transaction_id = bs.transaction_id
GROUP BY
    promotion_status;
