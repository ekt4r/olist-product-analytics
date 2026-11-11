WITH customer_cohorts AS (
	SELECT
		customer_unique_id,
		DATE_TRUNC('month', MIN(order_purchase_timestamp)) AS cohort_month
	FROM public.mart_orders
	WHERE order_status = 'delivered' AND customer_unique_id IS NOT NULL
	GROUP BY customer_unique_id
)

SELECT
	mo.customer_unique_id,
	DATE_TRUNC('month', mo.order_purchase_timestamp) AS purchase_month,
	cohort_month
FROM public.mart_orders mo
JOIN customer_cohorts cc ON mo.customer_unique_id = cc.customer_unique_id
WHERE mo.order_status = 'delivered'
GROUP BY mo.customer_unique_id, DATE_TRUNC('month', mo.order_purchase_timestamp), cohort_month;