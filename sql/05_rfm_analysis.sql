WITH rfm_params AS (
	SELECT DATE '2018-09-01' AS snapshot_date
), customer_rfm AS (
	SELECT
		mo.customer_unique_id,
		p.snapshot_date - MAX(mo.order_purchase_timestamp)::date AS recency_days,
		COUNT(*) AS order_count,
		SUM(items_total) AS customer_items_total
	FROM public.mart_orders mo
	CROSS JOIN rfm_params p
	WHERE mo.order_status = 'delivered' AND mo.customer_unique_id IS NOT NULL AND mo.order_purchase_timestamp < p.snapshot_date
	GROUP BY mo.customer_unique_id, p.snapshot_date
), rfm_cutoffs AS (
	SELECT
		PERCENTILE_CONT(ARRAY[0.33, 0.67])
	    WITHIN GROUP (ORDER BY recency_days) AS recency_cutoffs,
	    PERCENTILE_CONT(ARRAY[0.33, 0.67])
	    WITHIN GROUP (ORDER BY customer_items_total) AS monetary_cutoffs
	FROM customer_rfm
), scored_customers AS (
	SELECT
		*,
		CASE
			WHEN recency_days > cutoffs.recency_cutoffs[2] THEN 1
			WHEN recency_days > cutoffs.recency_cutoffs[1] THEN 2
			ELSE 3
		END AS recency_score,
		CASE
			WHEN order_count = 1 THEN 1
			WHEN order_count = 2 THEN 2
			WHEN order_count >= 3 THEN 3
			ELSE 0
		END AS frequency_score,
		CASE
			WHEN customer_items_total > cutoffs.monetary_cutoffs[2] THEN 3
			WHEN customer_items_total > cutoffs.monetary_cutoffs[1] THEN 2
			ELSE 1
		END AS monetary_score
	FROM customer_rfm
	CROSS JOIN rfm_cutoffs AS cutoffs
), segment_totals AS (
	SELECT
		rfm_segment,
		COUNT(*) AS buyer_count,
		SUM(COUNT(*)) OVER () AS total_buyer_count,
		SUM(customer_items_total) AS segment_items_total,
		SUM(SUM(customer_items_total)) OVER () AS all_items_total
	FROM (
		SELECT
			customer_unique_id,
			customer_items_total,
			CASE
				WHEN frequency_score = 3 THEN '1. Три и более заказа'
				WHEN monetary_score >= 2
				    AND (
				        frequency_score = 2
				        OR (frequency_score = 1 AND recency_score = 3)
				    )
				THEN '2. Средняя или высокая сумма, два заказа или недавняя покупка'
				WHEN frequency_score = 2 AND monetary_score = 1 THEN '3. Два заказа, низкая сумма покупок'
				WHEN frequency_score = 1 AND monetary_score >= 2 THEN '4. Один заказ, средняя или высокая сумма покупок'
				WHEN frequency_score = 1 AND monetary_score = 1 THEN '5. Один заказ, низкая сумма покупки'
				ELSE '6. Не классифицирован'
			END AS rfm_segment
		FROM scored_customers
	)
	GROUP BY rfm_segment
)

SELECT
	rfm_segment,
	buyer_count,
	ROUND(buyer_count * 100.0 / total_buyer_count, 2) AS buyer_pct,
	segment_items_total,
	ROUND(segment_items_total * 100.0 / all_items_total, 2) AS segment_items_pct
FROM segment_totals
ORDER BY rfm_segment;
