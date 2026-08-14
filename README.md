# Walmart Sales Data Analysis (SQL)

End-to-end SQL project analyzing retail sales trends, seasonality, and
product/store performance across a simulated 20-store, 10-department,
2-year Walmart-style dataset (modeled on the schema of the [Kaggle
Walmart Recruiting — Store Sales Forecasting](https://www.kaggle.com/c/walmart-recruiting-store-sales-forecasting/data)
competition: `stores`, `features`, and weekly `sales`).

> **Note on data:** Kaggle requires an authenticated download, which
> isn't reachable from this environment. To keep the project fully
> runnable end-to-end, `generate_data.py` builds a synthetic dataset
> with the identical schema and realistic sales patterns (holiday
> spikes, seasonality, store-type effects, economic indicators). Swap
> in the real Kaggle CSVs and the schema/queries work unchanged.

## Project Structure
```
sql-sales-analysis/
├── generate_data.py       # builds stores.csv, features.csv, sales.csv, departments.csv
├── schema.sql              # table definitions, keys, indexes
├── analysis_queries.sql    # 20+ business-question queries (Sections 1-7 below)
├── walmart_sales.db        # SQLite database, pre-loaded and ready to query
├── stores.csv / features.csv / sales.csv / departments.csv
└── README.md
```

## Schema
- **stores** (Store, Type[A/B/C], Size) — 20 stores
- **departments** (Dept, DeptName) — 10 departments (Grocery, Electronics, etc.)
- **features** (Store, Date, Temperature, Fuel_Price, CPI, Unemployment, IsHoliday) — weekly economic/weather signals
- **sales** (Store, Dept, Date, Weekly_Sales, IsHoliday) — 20,800 rows, 104 weeks (Feb 2023 – Jan 2025)

## Key Tasks Covered (`analysis_queries.sql`)
1. Data overview
2. Overall sales trends (weekly/monthly totals, YoY growth via self-join, 4-week moving average with window functions)
3. Seasonality & holiday impact (holiday vs regular week lift, per-department holiday sensitivity)
4. Product/department performance (ranking with `RANK()`, revenue contribution %, growth comparison across periods)
5. Store performance (top/bottom performers, sales-per-sqft efficiency, over/under-performance vs company average using correlated subqueries)
6. Economic factor correlation (fuel price banding, resilient-market subqueries)
7. Customer behavior proxies (department concentration via cumulative window functions, volatility via coefficient of variation)

Techniques used throughout: joins, subqueries (correlated and non-correlated), CTEs, window functions (`RANK`, `SUM() OVER`, moving averages), conditional aggregation, and derived KPIs.

## How to Run
```bash
python3 generate_data.py          # regenerate data (optional, .db already built)
sqlite3 walmart_sales.db < schema.sql
sqlite3 walmart_sales.db < analysis_queries.sql
```

## Insights (from actual query output)

**Trends & seasonality**
- Total company sales average **$24.4K/week per store-department** in regular weeks vs **$29.5K in holiday weeks** — a **21% holiday lift** overall.
- YoY growth is uneven month to month: **August (+34.5%)** and **May (+34.1%)** were the strongest growth months year-over-year, while **June (-14.6%)** and **September (-14.0%)** declined — pointing to a mid-year promotional/back-to-school shift worth investigating further.

**Department performance**
- **Grocery dominates revenue** at **23.6% of total sales** ($121.4M), more than double the next department (Electronics, 14.9%).
- **Furniture (1.36x), Toys (1.34x), and Apparel (1.34x)** see the largest holiday-week sales lift — discretionary categories, as expected — while Grocery's lift is modest (1.16x) despite being the top revenue driver, since it's a staple category.
- **Toys and Furniture are also the most volatile** departments (coefficient of variation ~0.50), meaning inventory/staffing plans for these categories need wider buffers than staples like Beauty or Automotive (CV ~0.48).

**Store performance**
- **Type A stores generate ~$1,665 in sales per sq ft**, vs **$1,268 for Type B** and just **$722 for Type C** — Type A stores are meaningfully more space-efficient, not just larger.
- The gap between the top store (Store 11, $42.6M) and bottom store (Store 3, $6.3M) is nearly **7x**, concentrated almost entirely along the Type A vs Type C divide rather than random variation.

**Economic factors**
- Sales were actually highest in the **mid fuel-price band ($3.20–3.50)**, not the lowest — suggesting fuel price alone isn't a strong standalone driver of spend in this dataset; it likely correlates with a broader macro cycle rather than acting causally.

## Suggested Next Steps
- Add a `RANK() ... PARTITION BY Store` query to find each store's best/worst department.
- Feed the moving-average and YoY tables into a Power BI or Tableau line chart for the visual layer (pairs well with the existing Telecom Churn Power BI dashboard).
- Swap in the real Kaggle CSVs when available — schema and all queries run unchanged.
