CREATE OR REPLACE VIEW analytics.cohort_data AS 
SELECT
	fp.user_id,
	fp.cohort_month,
	ua.activity_month,

	(
    	EXTRACT(YEAR FROM AGE(ua.activity_month, fp.cohort_month)) * 12
        +
        EXTRACT(MONTH FROM AGE(ua.activity_month, fp.cohort_month))
    ) AS months_since_signup
		
FROM analytics.first_purchase fp
JOIN analytics.user_activity ua 	
	ON fp.user_id = ua.user_id 
	