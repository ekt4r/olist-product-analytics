WITH customer_cohorts AS (
	SELECT
		customer_unique_id,
		DATE_TRUNC('month', MIN(order_purchase_timestamp)) AS cohort_month
	FROM public.mart_orders
	WHERE order_status = 'delivered' AND customer_unique_id IS NOT NULL
	GROUP BY customer_unique_id
), customer_purchase_months AS (
	SELECT
		mo.customer_unique_id,
		DATE_TRUNC('month', mo.order_purchase_timestamp) AS purchase_month,
		cohort_month
	FROM public.mart_orders mo
	JOIN customer_cohorts cc ON mo.customer_unique_id = cc.customer_unique_id
	WHERE mo.order_status = 'delivered'
	GROUP BY mo.customer_unique_id, DATE_TRUNC('month', mo.order_purchase_timestamp), cohort_month
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
	CROSS JOIN LATERAL generate_series(
		cs.cohort_month,
		TIMESTAMP '2018-08-01',
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