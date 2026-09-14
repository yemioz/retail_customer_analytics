CREATE VIEW analytics.favorite_item_by_type AS
WITH ranked_items AS (
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
	customer_type, 
	item_name,
	purchase_count 
FROM ranked_items
WHERE rn = 1;