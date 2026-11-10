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