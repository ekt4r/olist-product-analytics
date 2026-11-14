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

SELECT COUNT(*) AS orders_with_multiple_items
FROM (
	SELECT order_id
	FROM public.order_items
	WHERE order_id IS NOT NULL
	GROUP BY order_id
	HAVING COUNT(*) >= 2
) AS multi_item_orders;

WITH order_items_agg AS (
	SELECT
		order_id,
		SUM(price) AS price,
		SUM(freight_value) AS freight_value
	FROM public.order_items
	GROUP BY order_id
), order_payments_agg AS (
	SELECT
		order_id,
		SUM(payment_value) AS payment_value
	FROM public.order_payments
	GROUP BY order_id
)

SELECT
	o.order_id,
	price AS items_total,
	freight_value AS freight_total,
	payment_value AS payment_total,
	payment_value - (price + freight_value) AS payment_diff
FROM public.orders o
LEFT JOIN order_items_agg oi ON o.order_id = oi.order_id
LEFT JOIN order_payments_agg op ON o.order_id = op.order_id;

SELECT COUNT(*) AS orders_with_multiple_reviews
FROM (
	SELECT
		order_id
	FROM public.order_reviews
	GROUP BY order_id
	HAVING COUNT(DISTINCT review_id) > 1
) AS multi_review_orders;

SELECT COUNT(*) AS orders_with_multiple_payment_types
FROM (
	SELECT
		order_id
	FROM public.order_payments
	GROUP BY order_id
	HAVING COUNT(DISTINCT payment_type) > 1
) AS multi_payment_type_orders;
