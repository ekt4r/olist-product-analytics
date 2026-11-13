WITH duplicate_order_ids AS (
    SELECT
        order_id
    FROM public.mart_orders
    GROUP BY order_id
    HAVING COUNT(*) > 1
), duplicate_check AS (
    SELECT COUNT(*) AS duplicate_order_id_count
    FROM duplicate_order_ids
), mart_orders_count AS (
    SELECT COUNT(*) AS row_count
    FROM public.mart_orders
), orders_count AS (
    SELECT COUNT(*) AS row_count
    FROM public.orders
), row_count_check AS (
    SELECT moc.row_count - oc.row_count AS order_row_count_difference
    FROM mart_orders_count moc
    CROSS JOIN orders_count oc
), item_totals_by_order AS (
    SELECT
        order_id,
        SUM(price) AS source_items_total
    FROM order_items
    GROUP BY order_id
), items_total_check AS (
    SELECT
    COUNT(*) FILTER (WHERE is_different) AS items_total_mismatch_count
    FROM (
        SELECT
            items_total IS DISTINCT FROM source_items_total AS is_different
        FROM public.mart_orders mo
        LEFT JOIN item_totals_by_order it USING(order_id)
    )
)

SELECT
    duplicate_order_id_count,
    order_row_count_difference,
    items_total_mismatch_count,
    (
        duplicate_order_id_count <> 0
        OR order_row_count_difference <> 0
        OR items_total_mismatch_count <> 0
    ) AS checks_failed
FROM duplicate_check
CROSS JOIN row_count_check
CROSS JOIN items_total_check

\gset

\echo Дубликаты заказов: :duplicate_order_id_count
\echo Разница в числе строк: :order_row_count_difference
\echo Расхождения в стоимости товаров: :items_total_mismatch_count

\if :checks_failed
DO $$
BEGIN
    RAISE EXCEPTION 'Проверка витрины mart_orders не пройдена';
END;
$$;
\endif
