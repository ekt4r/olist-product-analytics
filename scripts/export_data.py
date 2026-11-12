from pathlib import Path
import pandas as pd
from sqlalchemy import create_engine, text

engine = create_engine(
    "postgresql+psycopg://ektar@localhost:5432/olist_analytics"
)

with engine.connect() as connection:
    database_name = connection.execute(text("SELECT current_database()")).scalar_one()

print(database_name)

project_root = Path(__file__).resolve().parents[1]
sql_dir = project_root / 'sql'
export_dir = project_root / 'data' / 'exports'

export_dir.mkdir(parents=True, exist_ok=True)

business_metric_queries = [
    query.strip()
    for query in (sql_dir / "03_business_metrics.sql").read_text(encoding="utf-8").split(";")
    if query.strip()
]
cohort_query = (sql_dir / "04_cohort_analysis.sql").read_text(encoding="utf-8")
rfm_query = (sql_dir / "05_rfm_analysis.sql").read_text(encoding="utf-8")

sql_queries = [
    *business_metric_queries,
    cohort_query,
    rfm_query
]

export_names = [
    'monthly_sales.csv',
    'sales_by_state.csv',
    'sales_by_category.csv',
    'repeat_buyers.csv',
    'monthly_cancellations.csv',
    'monthly_delivery.csv',
    'cohort_activity.csv',
    'rfm_segments.csv'
]

with engine.connect() as conn, conn.begin():

    for sql_query, export_name in zip(sql_queries, export_names, strict=True):

        export_data = pd.read_sql_query(
            sql_query,
            conn
        )

        export_data.to_csv(export_dir / export_name, index=False, encoding="utf-8")
        print(f'Saved: {export_dir / export_name}')