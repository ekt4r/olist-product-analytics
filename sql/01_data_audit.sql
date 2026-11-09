SELECT
	COUNT(*) AS number_of_rows,
	COUNT(DISTINCT order_id) AS cnt_distinct_orders,
	COUNT(*) FILTER (WHERE order_id IS NULL) AS cnt_null_orders
FROM public.orders;