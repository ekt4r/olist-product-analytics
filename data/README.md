# Source data

Download the [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) and extract the nine CSV files into `data/raw/`. Git excludes that directory.

```sh
kaggle datasets download -d olistbr/brazilian-ecommerce -p data/raw --unzip
```

The existing local PostgreSQL database is `sql_practice`. Its Olist tables are in the `public` schema and use unprefixed names such as `orders`, `order_items`, and `order_payments`. The audit expects these tables to be available before running any queries.
