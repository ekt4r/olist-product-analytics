# Исходные данные

Скачайте [публичный набор данных Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) и распакуйте девять CSV-файлов в `data/raw/`. Git игнорирует эту папку.

```sh
kaggle datasets download -d olistbr/brazilian-ecommerce -p data/raw --unzip
```

Для аудита используется отдельная локальная база PostgreSQL `olist_analytics`. Таблицы находятся в схеме `public` и называются без префикса `olist_`, например `orders`, `order_items` и `order_payments`.

В базу загружены исходные CSV. Аудит проверяет уникальность `orders.order_id` и выявляет товарные позиции без связанного заказа.
