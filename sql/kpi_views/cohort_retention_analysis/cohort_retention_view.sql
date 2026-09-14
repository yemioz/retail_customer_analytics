CREATE OR REPLACE VIEW analytics.cohort_retention AS
SELECT
	TO_CHAR(cohort_month, 'FMMONTH YYYY') AS cohort_month,
	months_since_signup,
	active_users,

	FIRST_VALUE(active_users)
        OVER (
            PARTITION BY cohort_month
            ORDER BY months_since_signup
        ) AS cohort_size,
	
	ROUND(
		active_users * 100
		/ 
		FIRST_VALUE(active_users)
			OVER (
				PARTITION BY cohort_month
				ORDER BY months_since_signup
			), 2
	) AS retention_rate

FROM analytics.retention_counts