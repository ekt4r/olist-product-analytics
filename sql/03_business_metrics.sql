-- name: monthly_sales
-- Считаем все доставленные заказы по месяцу покупки.
-- Сумма товаров и средний чек учитывают только заказы с известной стоимостью товаров.
SELECT
	DATE_TRUNC('month', order_purchase_timestamp) AS purchase_month,
	COUNT(*) AS delivered_order_count,
	SUM(items_total) AS delivered_items_total,
	AVG(items_total) AS avg_delivered_order_items_total
FROM public.mart_orders
WHERE order_status = 'delivered'
GROUP BY DATE_TRUNC('month', order_purchase_timestamp)
ORDER BY purchase_month ASC;

-- name: sales_by_state
SELECT
	customer_state,
	COUNT(*) AS delivered_order_count,
	SUM(items_total) AS delivered_items_total,
	AVG(items_total) AS avg_delivered_order_items_total
FROM public.mart_orders
WHERE order_status = 'delivered'
GROUP BY customer_state
ORDER BY delivered_items_total DESC;

-- name: sales_by_category
SELECT
	COALESCE(pc.product_category_name_english, p.product_category_name, 'Без категории') AS product_category_name,
	SUM(price) AS delivered_items_total
FROM public.order_items oi
LEFT JOIN public.products p ON oi.product_id = p.product_id
LEFT JOIN public.mart_orders mo ON oi.order_id = mo.order_id
LEFT JOIN public.product_category_name_translation pc ON p.product_category_name = pc.product_category_name
WHERE mo.order_status = 'delivered'
GROUP BY COALESCE(pc.product_category_name_english, p.product_category_name, 'Без категории')
ORDER BY delivered_items_total DESC;

-- name: repeat_buyers
WITH orders_by_customer AS (
	SELECT
		customer_unique_id,
		COUNT(*) AS delivered_order_count
	FROM public.mart_orders
	WHERE order_status = 'delivered' AND customer_unique_id IS NOT NULL
	GROUP BY customer_unique_id
)

SELECT
	COUNT(*) AS buyer_count,
	COUNT(*) FILTER (WHERE delivered_order_count >= 2) AS repeat_buyer_count,
	ROUND(COUNT(*) FILTER (WHERE delivered_order_count >= 2) * 100.0 / NULLIF(COUNT(*), 0), 2) AS repeat_buyer_pct
FROM orders_by_customer;

-- name: monthly_cancellations
SELECT
	DATE_TRUNC('month', order_purchase_timestamp) AS purchase_month,
	COUNT(*) FILTER (WHERE order_status = 'canceled') AS canceled_order_count,
	COUNT(*) AS total_order_count,
	ROUND(COUNT(*) FILTER (WHERE order_status = 'canceled') * 100.0 / COUNT(*), 2) AS canceled_order_pct
FROM public.mart_orders
GROUP BY DATE_TRUNC('month', order_purchase_timestamp)
ORDER BY purchase_month;

-- name: monthly_delivery
SELECT
	DATE_TRUNC('month', order_purchase_timestamp) AS purchase_month,
	COUNT(*) AS delivered_order_count,
	COUNT(*) FILTER (WHERE is_delivered_late IS NOT NULL) AS known_lateness_count,
	COUNT(*) FILTER (WHERE is_delivered_late IS NULL) AS unknown_lateness_count,
	COUNT(*) FILTER (WHERE is_delivered_late = TRUE) AS delivered_late_count,
	ROUND(
		COUNT(*) FILTER (WHERE is_delivered_late = TRUE) * 100.0 /
		NULLIF(COUNT(*) FILTER (WHERE is_delivered_late IS NOT NULL), 0),
	2) AS late_order_pct
FROM public.mart_orders
WHERE order_status = 'delivered'
GROUP BY DATE_TRUNC('month', order_purchase_timestamp);