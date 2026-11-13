WITH cohort_params AS (
	SELECT DATE '2018-09-01' AS observation_end_exclusive
), eligible_orders AS (
	SELECT
		customer_unique_id,
		order_purchase_timestamp
	FROM public.mart_orders
	CROSS JOIN cohort_params
	WHERE order_status = 'delivered' AND customer_unique_id IS NOT NULL
	AND order_purchase_timestamp < observation_end_exclusive
), customer_cohorts AS (
	SELECT
		customer_unique_id,
		DATE_TRUNC('month', MIN(order_purchase_timestamp)) AS cohort_month
	FROM eligible_orders
	GROUP BY customer_unique_id
), customer_purchase_months AS (
	SELECT
		eo.customer_unique_id,
		DATE_TRUNC('month', eo.order_purchase_timestamp) AS purchase_month,
		cohort_month
	FROM eligible_orders eo
	JOIN customer_cohorts cc ON eo.customer_unique_id = cc.customer_unique_id
	GROUP BY eo.customer_unique_id, DATE_TRUNC('month', eo.order_purchase_timestamp), cohort_month
), customer_month_offsets AS (
	SELECT
		customer_unique_id,
		purchase_month,
		cohort_month,
		((EXTRACT(YEAR FROM purchase_month) - EXTRACT(YEAR FROM cohort_month)) * 12
		+ EXTRACT(MONTH FROM purchase_month) - EXTRACT(MONTH FROM cohort_month))::integer AS months_since_first_purchase
	FROM customer_purchase_months
), cohort_monthly_activity AS (
	SELECT
		cohort_month,
		months_since_first_purchase,
		COUNT(customer_unique_id) AS active_buyer_count
	FROM customer_month_offsets
	GROUP BY cohort_month, months_since_first_purchase
	ORDER BY cohort_month, months_since_first_purchase
), cohort_sizes AS (
	SELECT
		cohort_month,
		COUNT(*) AS cohort_size
	FROM customer_cohorts
	GROUP BY cohort_month
), cohort_calendar AS (
	SELECT
		cs.cohort_month,
		cs.cohort_size,
		months.month_start,
		((EXTRACT(YEAR FROM months.month_start) - EXTRACT(YEAR FROM cohort_month)) * 12
		+ EXTRACT(MONTH FROM months.month_start) - EXTRACT(MONTH FROM cohort_month))::integer AS months_since_first_purchase
	FROM cohort_sizes cs
	CROSS JOIN cohort_params
	CROSS JOIN LATERAL generate_series(
		cs.cohort_month,
		observation_end_exclusive - INTERVAL '1 month',
		INTERVAL '1 MONTH'
	) AS months(month_start)
)

SELECT
	cc.cohort_month,
	cc.months_since_first_purchase,
	COALESCE(active_buyer_count, 0) AS active_buyer_count,
	cohort_size,
	ROUND(COALESCE(active_buyer_count, 0) * 100.0 / cc.cohort_size, 2) AS active_buyer_pct
FROM cohort_calendar cc
LEFT JOIN cohort_monthly_activity cma ON (
	cc.cohort_month = cma.cohort_month
	AND cc.months_since_first_purchase = cma.months_since_first_purchase
)
ORDER BY cc.cohort_month, cc.months_since_first_purchase;