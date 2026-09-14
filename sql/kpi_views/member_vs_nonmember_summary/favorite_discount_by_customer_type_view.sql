CREATE OR REPLACE VIEW analytics.favorite_discounts_by_type AS 
	WITH ranked_discounts AS (
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
	)
	
	SELECT 
		customer_type, 
		voucher_code, 
		usage_count
	FROM ranked_discounts
	WHERE rn = 1;



