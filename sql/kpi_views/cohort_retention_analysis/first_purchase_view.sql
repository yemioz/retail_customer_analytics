CREATE OR REPLACE VIEW analytics.first_purchase AS 
SELECT 
	user_id,
	DATE_TRUNC(
		'month',
		MIN(created_at)
	) AS cohort_month
FROM transactions
WHERE user_id IS NOT NULL
GROUP BY user_id
