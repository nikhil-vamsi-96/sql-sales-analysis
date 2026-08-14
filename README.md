# 🛒 Walmart Sales Analysis — SQL

An end-to-end SQL analytics project focused on **retail sales performance, seasonality, department trends, store efficiency, and business KPIs**.

## 🎯 Business Problem

Retail teams need to understand which stores and departments drive revenue, how sales change during holidays, and where operational efficiency can improve.

This project uses SQL to answer those questions and turn raw sales data into business insights.

> **Data note:** The project uses a synthetic dataset modeled on the schema of the Walmart Recruiting Store Sales Forecasting dataset. The included generator makes the project fully reproducible without requiring authenticated Kaggle access.

## 📊 Dataset

- 20 stores
- 10 departments
- 104 weeks of sales
- 20,800 sales records
- Store, department, sales, holiday, weather and economic features

## 🧰 Tools & Techniques

**Tools:** SQLite • SQL

**SQL techniques:**
- Joins
- CTEs
- Correlated subqueries
- Window functions
- `RANK()`
- Moving averages
- Conditional aggregation
- KPI calculations

## 🔍 Analysis

1. Overall sales trends
2. Monthly and year-over-year performance
3. Holiday vs. regular-week sales
4. Department revenue contribution
5. Store ranking and efficiency
6. Sales-per-square-foot analysis
7. Economic-factor analysis
8. Department sales concentration and volatility

## 💡 Key Insights

- Holiday weeks show approximately a **21% sales lift** compared with regular weeks in the analyzed dataset.
- **Grocery contributes 23.6% of total sales**, making it the largest revenue department.
- Type A stores generate approximately **$1,665 sales per square foot**, compared with about $1,268 for Type B and $722 for Type C.
- The highest-performing store generates almost **7×** the sales of the lowest-performing store, highlighting a major store-type performance gap.
- Fuel price alone does not appear to be a strong standalone driver of sales in this dataset.

## 📁 Project Structure

```text
sql-sales-analysis/
├── generate_data.py
├── schema.sql
├── analysis_queries.sql
├── walmart_sales.db
├── stores.csv
├── features.csv
├── sales.csv
├── departments.csv
├── images/
└── README.md
```

## ▶️ How to Run

```bash
python3 generate_data.py
sqlite3 walmart_sales.db < schema.sql
sqlite3 walmart_sales.db < analysis_queries.sql
```

## 🚀 Possible Extensions

- Build a Power BI sales dashboard
- Add store-level department rankings
- Add cohort or seasonal analysis
- Compare forecasted vs. actual sales
- Add automated KPI reporting

## 👤 Author

**Nikhil Vamsi** — Aspiring Data Analyst

[GitHub](https://github.com/nikhil-vamsi-96) • [Portfolio](https://github.com/nikhil-vamsi-96/Data-Portfolio) • [Email](mailto:nikhilvamsi96@gmail.com)
