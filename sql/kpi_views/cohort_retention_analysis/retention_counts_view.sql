CREATE OR REPLACE VIEW analytics.retention_counts AS 
SELECT 
	cohort_month,
	months_since_signup,
	COUNT(DISTINCT(user_id)) AS active_users
FROM analytics.cohort_data
GROUP BY 
	cohort_month,
	months_since_signup