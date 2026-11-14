import os
from pathlib import Path

import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine


def read_named_queries(sql_path: Path) -> dict[str, str]:
    marker = "-- name: "
    query_lines_by_name: dict[str, list[str]] = {}
    query_name = None

    with sql_path.open(encoding="utf-8") as sql_file:
        for line in sql_file:
            if line.startswith(marker):
                query_name = line.removeprefix(marker).strip()
                if not query_name or query_name in query_lines_by_name:
                    raise ValueError(f"Пустая или повторная метка SQL в {sql_path}: {line.strip()}")
                query_lines_by_name[query_name] = []
            elif query_name is not None:
                query_lines_by_name[query_name].append(line)

    return {
        name: "".join(lines).strip()
        for name, lines in query_lines_by_name.items()
    }


def main() -> None:
    project_root = Path(__file__).resolve().parents[1]
    load_dotenv(project_root / ".env")
    database_url = os.getenv("DATABASE_URL")
    if not database_url:
        raise SystemExit("Задайте DATABASE_URL в окружении или скопируйте .env.example в .env и заполните его.")

    sql_dir = project_root / "sql"
    export_dir = project_root / "data" / "exports"
    queries_by_name = read_named_queries(sql_dir / "03_business_metrics.sql")
    metric_names = (
        "monthly_sales",
        "sales_by_state",
        "sales_by_category",
        "repeat_buyers",
        "monthly_cancellations",
        "monthly_delivery",
    )
    missing_queries = [name for name in metric_names if not queries_by_name.get(name)]
    if missing_queries:
        raise SystemExit(f"Отсутствуют или пусты SQL-запросы: {', '.join(missing_queries)}")

    export_queries = {name: queries_by_name[name] for name in metric_names}
    export_queries["cohort_activity"] = (sql_dir / "04_cohort_analysis.sql").read_text(encoding="utf-8")
    export_queries["rfm_segments"] = (sql_dir / "05_rfm_analysis.sql").read_text(encoding="utf-8")

    export_dir.mkdir(parents=True, exist_ok=True)
    engine = create_engine(database_url)
    with engine.begin() as connection:
        for name, sql_query in export_queries.items():
            export_data = pd.read_sql_query(sql_query, connection)
            export_path = export_dir / f"{name}.csv"
            export_data.to_csv(export_path, index=False, encoding="utf-8")
            print(f"Сохранено: {export_path}")


if __name__ == "__main__":
    main()
