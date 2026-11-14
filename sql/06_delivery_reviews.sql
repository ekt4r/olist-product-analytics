SELECT
    is_delivered_late,
    COUNT(*) AS delivered_order_count,
    COUNT(avg_review_score) AS reviewed_order_count,
    ROUND(AVG(avg_review_score), 2) AS mean_review_score,
    COUNT(*) FILTER (WHERE avg_review_score <= 2) AS low_score_order_count,
    ROUND(COUNT(*) FILTER (WHERE avg_review_score <= 2) * 100.0 / NULLIF(COUNT(avg_review_score), 0), 2) AS low_score_order_pct
FROM public.mart_orders mo
WHERE is_delivered_late IS NOT NULL AND order_purchase_timestamp >= DATE '2017-02-01' AND order_purchase_timestamp < DATE '2018-09-01'
GROUP BY is_delivered_late
ORDER BY is_delivered_late;

SELECT
    is_delivered_late,
    DATE_TRUNC('month', order_purchase_timestamp) AS purchase_month,
    COUNT(*) AS delivered_order_count,
    COUNT(avg_review_score) AS reviewed_order_count,
    ROUND(AVG(avg_review_score), 2) AS mean_review_score,
    COUNT(*) FILTER (WHERE avg_review_score <= 2) AS low_score_order_count,
    ROUND(COUNT(*) FILTER (WHERE avg_review_score <= 2) * 100.0 / NULLIF(COUNT(avg_review_score), 0), 2) AS low_score_order_pct
FROM public.mart_orders mo
WHERE is_delivered_late IS NOT NULL AND order_purchase_timestamp >= DATE '2017-02-01' AND order_purchase_timestamp < DATE '2018-09-01'
GROUP BY is_delivered_late, DATE_TRUNC('month', order_purchase_timestamp)
ORDER BY purchase_month, is_delivered_late;