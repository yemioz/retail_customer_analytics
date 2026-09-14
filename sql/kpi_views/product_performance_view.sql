CREATE OR REPLACE VIEW analytics.product_performance AS 
SELECT 
	m.item_name, 
	m.category,
	SUM(ti.quantity) AS units_sold,
	SUM(ti.subtotal) AS revenue,
	ROUND(SUM(ti.subtotal) * 100.0 / 
	SUM(SUM(ti.subtotal)) OVER (), 2)
		AS percent_of_total_revenue,
	ROUND(SUM(ti.subtotal) * 100.0 / 
		SUM(SUM(ti.subtotal)) OVER(PARTITION BY m.category), 2)
			AS percent_of_category_revenue,
	ROUND(COUNT(DISTINCT ti.transaction_id) * 100.0 / (SELECT COUNT(*) FROM transactions),
		2) AS basket_penetration_rate
FROM transaction_items ti
JOIN menu_items m ON ti.item_id = m.item_id
GROUP BY m.item_name, m.category
ORDER BY units_sold DESC