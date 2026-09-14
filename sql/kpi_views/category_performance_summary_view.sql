CREATE OR REPLACE VIEW analytics.category_performance_summary AS
SELECT 
	mi.category,
	SUM(ti.subtotal) AS revenue,
	SUM(ti.quantity) AS category_sold_qty,
	ROUND(SUM(ti.subtotal) * 100.0 / SUM(SUM(ti.subtotal))
		OVER (), 2) AS percent_of_total_revenue,
	cyc.revenue_yoy_percent_change,
	ci.category_top_item,
	ci.item_revenue,
	ci.sold_qty
FROM transaction_items ti

JOIN menu_items mi ON ti.item_id = mi.item_id

LEFT JOIN analytics.category_top_item ci
	ON mi.category = ci.category 

LEFT JOIN analytics.category_yoy_performance cyc
	ON mi.category = cyc.category

GROUP BY 
	mi.category,
	revenue_yoy_percent_change,
	ci.category_top_item,
	ci.item_revenue,
	ci.sold_qty