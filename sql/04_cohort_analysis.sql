SELECT
	customer_unique_id,
	DATE_TRUNC('month', MIN(order_purchase_timestamp)) AS cohort_month
FROM public.mart_orders
WHERE order_status = 'delivered' AND customer_unique_id IS NOT NULL
GROUP BY customer_unique_id;