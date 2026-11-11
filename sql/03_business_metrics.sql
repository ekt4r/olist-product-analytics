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

SELECT
	customer_state,
	COUNT(*) AS delivered_order_count,
	SUM(items_total) AS delivered_items_total,
	AVG(items_total) AS avg_delivered_order_items_total
FROM public.mart_orders
WHERE order_status = 'delivered'
GROUP BY customer_state
ORDER BY delivered_items_total DESC;

SELECT
	COALESCE(product_category_name, 'Без категории') AS product_category_name,
	SUM(price) AS delivered_items_total
FROM public.order_items oi
LEFT JOIN public.products p ON oi.product_id = p.product_id
LEFT JOIN public.mart_orders mo ON oi.order_id = mo.order_id
WHERE mo.order_status = 'delivered'
GROUP BY product_category_name
ORDER BY delivered_items_total DESC;

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