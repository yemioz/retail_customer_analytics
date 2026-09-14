WITH customer_basket_size AS (
    SELECT 
        t.transaction_id,

        CASE
            WHEN t.user_id IS NOT NULL THEN 'Member'
            ELSE 'Guest'
        END AS customer_type,

        t.voucher_id,
        SUM(ti.quantity) AS units_sold,
        t.original_amount AS rev_before_discount,
        t.final_amount AS final_amount,
        t.discount_applied

    FROM transactions t
    JOIN transaction_items ti
        ON t.transaction_id = ti.transaction_id

    GROUP BY
        t.transaction_id,
        t.user_id,
        t.voucher_id,
        t.original_amount,
        t.final_amount,
        t.discount_applied
),

favorite_discount AS (
    SELECT
        CASE
            WHEN t.user_id IS NOT NULL THEN 'Member'
            ELSE 'Guest'
        END AS customer_type,

        v.voucher_code,
        COUNT(*) AS usage_count,

        ROW_NUMBER() OVER (
            PARTITION BY
                CASE
                    WHEN t.user_id IS NOT NULL THEN 'Member'
                    ELSE 'Guest'
                END
            ORDER BY COUNT(*) DESC
        ) AS rn

    FROM transactions t
    JOIN vouchers v
        ON t.voucher_id = v.voucher_id

    WHERE t.voucher_id IS NOT NULL

    GROUP BY
        CASE
            WHEN t.user_id IS NOT NULL THEN 'Member'
            ELSE 'Guest'
        END,
        v.voucher_code
),

favorite_item AS (
    SELECT
        CASE
            WHEN t.user_id IS NOT NULL THEN 'Member'
            ELSE 'Guest'
        END AS customer_type,

        mi.item_name,
        COUNT(*) AS purchase_count,

        ROW_NUMBER() OVER (
            PARTITION BY
                CASE
                    WHEN t.user_id IS NOT NULL THEN 'Member'
                    ELSE 'Guest'
                END
            ORDER BY COUNT(*) DESC
        ) AS rn

    FROM transactions t
    JOIN transaction_items ti
        ON t.transaction_id = ti.transaction_id
    JOIN menu_items mi
        ON ti.item_id = mi.item_id

    GROUP BY
        CASE
            WHEN t.user_id IS NOT NULL THEN 'Member'
            ELSE 'Guest'
        END,
        mi.item_name
)

SELECT
    c.customer_type,

    ROUND(AVG(c.units_sold), 2) AS avg_basket_size,
    ROUND(AVG(c.rev_before_discount), 2) AS avg_original_transaction_value,
    COUNT(c.voucher_id) AS discounts_used,
	ROUND(
        COUNT(c.voucher_id) * 100.0 / COUNT(*),
        2
    ) AS discount_usage_rate,
    ROUND(AVG(c.discount_applied), 2) AS avg_discount,
    ROUND(AVG(c.final_amount), 2) AS avg_final_amount,

    fd.voucher_code AS favorite_discount,
    fi.item_name AS favorite_item,
	fi.purchase_count

FROM customer_basket_size c

LEFT JOIN favorite_discount fd
    ON c.customer_type = fd.customer_type
    AND fd.rn = 1

LEFT JOIN favorite_item fi
    ON c.customer_type = fi.customer_type
    AND fi.rn = 1

GROUP BY
    c.customer_type,
    fd.voucher_code,
    fi.item_name,
	fi.purchase_count

ORDER BY
    c.customer_type;