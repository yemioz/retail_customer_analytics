CREATE OR REPLACE VIEW analytics.customer_basket_size AS
	SELECT
		t.transaction_id,
		CASE
			WHEN t.user_id IS NOT NULL THEN 'Member'
			ELSE 'Guest'
		END AS customer_type,
		t.voucher_id,
		SUM(ti.quantity) AS units_sold,
		t.original_amount AS original_transaction_value,
		t.final_amount,
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