CREATE OR REPLACE VIEW analytics.user_activity AS 
SELECT
	user_id,
	DATE_TRUNC(
		'month',
		created_at
	) AS activity_month
FROM transactions
WHERE user_id IS NOT NULL
