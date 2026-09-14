SELECT 
	t.voucher_id, v.voucher_code, 
	COUNT(*) AS total_applications, 
	ROUND(
		COUNT(t.voucher_id) * 100.0 / 
			(SELECT COUNT(*) FROM transactions),
		4) AS percent_of_transactions,
	SUM(COALESCE(t.discount_applied, 0)) AS total_value,
	SUM(t.final_amount) AS total_revenue,
	ROUND(AVG(t.discount_applied),2 ) AS avg_discount
FROM transactions t
JOIN vouchers v ON t.voucher_id = v.voucher_id
GROUP BY t.voucher_id, v.voucher_code
ORDER BY total_value DESC;