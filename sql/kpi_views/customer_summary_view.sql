CREATE VIEW analytics.customer_summary AS (
	WITH items_per_transaction AS (
		SELECT 
			transaction_id,
			SUM(quantity) AS total_items
		FROM transaction_items
		GROUP BY transaction_id
	)
	
	SELECT 
		t.user_id, MAX(t.created_at) AS last_purchase_date, 
		'2025-07-01'::date - MAX(t.created_at) AS days_since_last_transaction,
		COUNT(*) AS num_of_transactions, 
		ROUND(AVG(t.final_amount) , 2) AS avg_purchase,
		ROUND(AVG(ipt.total_items), 2) AS avg_basket_size,
		MAX(t.final_amount) AS max_purchase,
		SUM(t.final_amount) AS total_spent
	FROM transactions t
	JOIN items_per_transaction ipt ON t.transaction_id = ipt.transaction_id
	
	WHERE t.user_id IS NOT NULL
	GROUP BY t.user_id
	ORDER BY days_since_last_transaction ASC
)