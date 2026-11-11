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
)

SELECT
	cma.cohort_month,
	months_since_first_purchase,
	active_buyer_count,
	cohort_size,
	ROUND(active_buyer_count * 100.0 / cohort_size, 2) AS active_buyer_pct
FROM cohort_monthly_activity cma
LEFT JOIN cohort_sizes cs ON cma.cohort_month = cs.cohort_month
ORDER BY cma.cohort_month, months_since_first_purchase;