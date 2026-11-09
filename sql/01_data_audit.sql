SELECT
	COUNT(*) AS number_of_rows,
	COUNT(DISTINCT order_id) AS cnt_distinct_orders,
	COUNT(*) FILTER (WHERE order_id IS NULL) AS cnt_null_orders
FROM public.orders;

SELECT
	order_status,
	COUNT(*) AS total_orders,
	COUNT(order_delivered_customer_date) AS orders_with_delivery_date,
	COUNT(*) FILTER (WHERE order_delivered_customer_date IS NULL) AS orders_without_delivery_date,
	ROUND(COUNT(*) FILTER (WHERE order_delivered_customer_date IS NULL) * 100.0 / COUNT(*), 2) AS missing_delivery_date_pct
FROM public.orders
GROUP BY order_status;

SELECT
	COUNT(*) FILTER (WHERE oi.order_id IS NULL) AS items_without_order_id,
	COUNT(*) FILTER (WHERE oi.order_id IS NOT NULL AND o.order_id IS NULL) AS items_with_unknown_order_id
FROM public.order_items oi
LEFT JOIN public.orders o USING(order_id);