CREATE OR REPLACE VIEW analytics.member_vs_nonmember_patterns_summary AS
	SELECT
		c.customer_type,
		ROUND(AVG(c.units_sold), 2) AS avg_basket_size,
		ROUND(AVG(c.original_transaction_value), 2)
			AS avg_original_transaciton_value,
		COUNT(c.voucher_id) AS discounts_used, 
		ROUND(COUNT(c.voucher_id) * 100.0
				/ COUNT(*), 2) AS discount_usage_rate,
		ROUND(AVG(c.discount_applied), 2) AS avg_discount,
		ROUND(AVG(c.final_amount), 2) AS avg_final_amount,
		fd.voucher_code AS favorite_discount,
		fi.item_name AS favorite_item
	FROM analytics.customer_basket_size c
	LEFT JOIN analytics.favorite_discounts_by_type fd
		ON c.customer_type = fd.customer_type
	LEFT JOIN analytics.favorite_item_by_type fi
		ON c.customer_type = fi.customer_type
	GROUP BY 
		c.customer_type,
		fd.voucher_code,
		fi.item_name
	ORDER BY 
		c.customer_type