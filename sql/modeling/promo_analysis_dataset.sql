CREATE OR REPLACE VIEW analytics.promo_analysis_dataset AS

WITH basket_summary AS (
    SELECT
        ti.transaction_id,
        SUM(ti.quantity) AS basket_size,
        COUNT(DISTINCT ti.item_id) AS distinct_items
    FROM transaction_items ti
    GROUP BY ti.transaction_id
),

category_summary AS (
    SELECT
        ti.transaction_id,

       
        STRING_AGG(
            DISTINCT mi.category,
            ', ' ORDER BY mi.category
        ) AS product_categories,

        COUNT(DISTINCT mi.category) AS category_count

    FROM transaction_items ti
    JOIN menu_items mi
        ON ti.item_id = mi.item_id
    GROUP BY ti.transaction_id
)

SELECT
    t.transaction_id,
    t.created_at,

    CASE
        WHEN t.voucher_id IS NOT NULL THEN 1
        ELSE 0
    END AS promotion_used,

    CASE
        WHEN t.user_id IS NOT NULL THEN 1
        ELSE 0
    END AS loyalty_member,

    t.user_id,
    t.voucher_id,

    t.original_amount,
    t.discount_applied,
    t.final_amount,

    bs.basket_size,
    bs.distinct_items,

	cs.product_categories,
	cs.category_count,
	
	EXTRACT(ISODOW FROM t.created_at)::int AS day_of_week,
	EXTRACT(HOUR FROM t.created_at)::int AS transaction_hour,
	EXTRACT(MONTH FROM t.created_at)::int AS month_num,
	EXTRACT(YEAR FROM t.created_at):: int AS year_num

FROM transactions t
LEFT JOIN basket_summary bs 
	ON bs.transaction_id = t.transaction_id
LEFT JOIN category_summary cs ON 
	cs.transaction_id = t.transaction_id;