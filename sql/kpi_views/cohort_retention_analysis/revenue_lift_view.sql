CREATE OR REPLACE VIEW analytics.revenue_lift AS
WITH averages AS (
	SELECT
		ROUND(AVG(CASE WHEN user_id IS NOT NULL
					THEN final_amount END), 2) AS avg_member_spend,
		ROUND(AVG(CASE WHEN user_id IS NULL
					THEN final_amount END), 2) AS avg_guest_spend
	FROM transactions
)

SELECT
	avg_member_spend,
	avg_guest_spend,
	ROUND(
		(avg_guest_spend - avg_member_spend) * 100 
		/ NULLIF(avg_guest_spend, 0), 2) AS revenue_lift_percent
FROM averages