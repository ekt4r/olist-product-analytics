WITH order_items_agg AS (
	SELECT
		order_id,
		SUM(price) AS items_total,
		SUM(freight_value) AS freight_total
	FROM public.order_items
	GROUP BY order_id
), order_payments_agg AS (
	SELECT
		order_id,
		SUM(payment_value) AS payment_total
	FROM public.order_payments
	GROUP BY order_id
)

SELECT
	o.*,
	c.customer_unique_id,
	c.customer_city,
	c.customer_state,
	c.customer_zip_code_prefix,
	oi.items_total,
	oi.freight_total,
	op.payment_total
FROM public.orders o
LEFT JOIN public.customers c ON o.customer_id = c.customer_id
LEFT JOIN order_items_agg oi ON o.order_id = oi.order_id
LEFT JOIN order_payments_agg op ON o.order_id = op.order_id;
