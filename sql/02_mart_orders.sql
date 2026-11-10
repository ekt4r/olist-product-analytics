CREATE OR REPLACE VIEW public.mart_orders AS
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
		COUNT(DISTINCT payment_type) AS payment_type_count,
		SUM(payment_value) AS payment_total
	FROM public.order_payments
	GROUP BY order_id
), order_reviews_agg AS (
	SELECT
		order_id,
		COUNT(DISTINCT review_id) AS review_count,
		AVG(review_score) AS avg_review_score
	FROM public.order_reviews
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
	op.payment_type_count,
	op.payment_total,
	ora.review_count,
	ora.avg_review_score,
	CASE
		WHEN o.order_status = 'delivered'
		THEN o.order_estimated_delivery_date::date < o.order_delivered_customer_date::date
		ELSE NULL
	END AS is_delivered_late
FROM public.orders o
LEFT JOIN public.customers c ON o.customer_id = c.customer_id
LEFT JOIN order_items_agg oi ON o.order_id = oi.order_id
LEFT JOIN order_payments_agg op ON o.order_id = op.order_id
LEFT JOIN order_reviews_agg ora ON o.order_id = ora.order_id;
