-- =========================================================
-- Walmart Sales Data Analysis
-- End-to-end SQL analysis: trends, seasonality, product &
-- store performance, holiday impact, and customer behavior
-- proxies (basket size via avg sales / transaction density).
-- Engine: SQLite (portable to MySQL/PostgreSQL with minor
-- syntax tweaks, noted inline where relevant).
-- =========================================================


-- ---------------------------------------------------------
-- 1. DATA OVERVIEW
-- ---------------------------------------------------------

-- 1.1 Row counts and date range covered
SELECT
    (SELECT COUNT(*) FROM sales)      AS total_sales_rows,
    (SELECT COUNT(*) FROM stores)     AS total_stores,
    (SELECT COUNT(*) FROM departments) AS total_departments,
    (SELECT MIN(Date) FROM sales)     AS first_week,
    (SELECT MAX(Date) FROM sales)     AS last_week;

-- 1.2 Store mix by type
SELECT Type, COUNT(*) AS store_count, ROUND(AVG(Size),0) AS avg_size_sqft
FROM stores
GROUP BY Type
ORDER BY store_count DESC;


-- ---------------------------------------------------------
-- 2. OVERALL SALES TRENDS
-- ---------------------------------------------------------

-- 2.1 Total company-wide sales by week (trend line)
SELECT Date, ROUND(SUM(Weekly_Sales),2) AS total_sales
FROM sales
GROUP BY Date
ORDER BY Date;

-- 2.2 Month-over-month sales trend
SELECT
    strftime('%Y-%m', Date) AS year_month,
    ROUND(SUM(Weekly_Sales),2) AS monthly_sales
FROM sales
GROUP BY year_month
ORDER BY year_month;

-- 2.3 Year-over-year growth by month (self-join on same calendar month)
WITH monthly AS (
    SELECT strftime('%Y', Date) AS yr,
           strftime('%m', Date) AS mo,
           SUM(Weekly_Sales) AS sales
    FROM sales
    GROUP BY yr, mo
)
SELECT
    b.mo AS month,
    a.sales AS sales_2023,
    b.sales AS sales_2024,
    ROUND((b.sales - a.sales) * 100.0 / a.sales, 2) AS yoy_growth_pct
FROM monthly a
JOIN monthly b ON a.mo = b.mo AND a.yr = '2023' AND b.yr = '2024'
ORDER BY month;

-- 2.4 4-week moving average of total sales (smooths noise to reveal trend)
-- SQLite: window function with ROWS BETWEEN
WITH weekly AS (
    SELECT Date, SUM(Weekly_Sales) AS total_sales
    FROM sales
    GROUP BY Date
)
SELECT
    Date,
    total_sales,
    ROUND(AVG(total_sales) OVER (
        ORDER BY Date ROWS BETWEEN 3 PRECEDING AND CURRENT ROW
    ), 2) AS moving_avg_4wk
FROM weekly
ORDER BY Date;


-- ---------------------------------------------------------
-- 3. SEASONALITY & HOLIDAY IMPACT
-- ---------------------------------------------------------

-- 3.1 Holiday vs non-holiday week average sales
SELECT
    CASE WHEN IsHoliday = 1 THEN 'Holiday Week' ELSE 'Regular Week' END AS week_type,
    ROUND(AVG(Weekly_Sales),2) AS avg_sales_per_store_dept,
    COUNT(DISTINCT Date) AS weeks_counted
FROM sales
GROUP BY IsHoliday;

-- 3.2 Sales lift by holiday week specifically (top holiday weeks by total sales)
SELECT Date, ROUND(SUM(Weekly_Sales),2) AS total_sales
FROM sales
WHERE IsHoliday = 1
GROUP BY Date
ORDER BY total_sales DESC;

-- 3.3 Seasonality by calendar month (which months run hot/cold year-round)
SELECT
    strftime('%m', Date) AS month_num,
    CASE strftime('%m', Date)
        WHEN '01' THEN 'Jan' WHEN '02' THEN 'Feb' WHEN '03' THEN 'Mar'
        WHEN '04' THEN 'Apr' WHEN '05' THEN 'May' WHEN '06' THEN 'Jun'
        WHEN '07' THEN 'Jul' WHEN '08' THEN 'Aug' WHEN '09' THEN 'Sep'
        WHEN '10' THEN 'Oct' WHEN '11' THEN 'Nov' WHEN '12' THEN 'Dec'
    END AS month_name,
    ROUND(AVG(Weekly_Sales),2) AS avg_weekly_sales
FROM sales
GROUP BY month_num
ORDER BY month_num;

-- 3.4 Which departments spike hardest during holidays (holiday lift ratio)
SELECT
    d.DeptName,
    ROUND(AVG(CASE WHEN s.IsHoliday = 1 THEN s.Weekly_Sales END), 2) AS avg_holiday_sales,
    ROUND(AVG(CASE WHEN s.IsHoliday = 0 THEN s.Weekly_Sales END), 2) AS avg_regular_sales,
    ROUND(
        AVG(CASE WHEN s.IsHoliday = 1 THEN s.Weekly_Sales END) * 1.0
        / AVG(CASE WHEN s.IsHoliday = 0 THEN s.Weekly_Sales END), 2
    ) AS holiday_lift_ratio
FROM sales s
JOIN departments d ON s.Dept = d.Dept
GROUP BY d.DeptName
ORDER BY holiday_lift_ratio DESC;


-- ---------------------------------------------------------
-- 4. PRODUCT (DEPARTMENT) PERFORMANCE
-- ---------------------------------------------------------

-- 4.1 Total and average sales by department, ranked
SELECT
    d.DeptName,
    ROUND(SUM(s.Weekly_Sales),2) AS total_sales,
    ROUND(AVG(s.Weekly_Sales),2) AS avg_weekly_sales,
    RANK() OVER (ORDER BY SUM(s.Weekly_Sales) DESC) AS sales_rank
FROM sales s
JOIN departments d ON s.Dept = d.Dept
GROUP BY d.DeptName
ORDER BY total_sales DESC;

-- 4.2 Department contribution to total revenue (% of total)
WITH dept_totals AS (
    SELECT d.DeptName, SUM(s.Weekly_Sales) AS dept_sales
    FROM sales s JOIN departments d ON s.Dept = d.Dept
    GROUP BY d.DeptName
)
SELECT
    DeptName,
    ROUND(dept_sales,2) AS dept_sales,
    ROUND(dept_sales * 100.0 / (SELECT SUM(dept_sales) FROM dept_totals), 2) AS pct_of_total
FROM dept_totals
ORDER BY pct_of_total DESC;

-- 4.3 Fastest-growing vs declining departments (first 6 months vs last 6 months)
WITH periods AS (
    SELECT
        Dept,
        CASE WHEN Date < '2023-08-01' THEN 'early' ELSE 'late' END AS period,
        Weekly_Sales
    FROM sales
    WHERE Date < '2023-08-01' OR Date >= '2024-08-01'
),
agg AS (
    SELECT Dept, period, SUM(Weekly_Sales) AS total
    FROM periods
    GROUP BY Dept, period
)
SELECT
    d.DeptName,
    e.total AS early_period_sales,
    l.total AS late_period_sales,
    ROUND((l.total - e.total) * 100.0 / e.total, 2) AS growth_pct
FROM agg e
JOIN agg l ON e.Dept = l.Dept AND e.period='early' AND l.period='late'
JOIN departments d ON d.Dept = e.Dept
ORDER BY growth_pct DESC;


-- ---------------------------------------------------------
-- 5. STORE PERFORMANCE
-- ---------------------------------------------------------

-- 5.1 Top and bottom 5 stores by total sales
SELECT st.Store, st.Type, st.Size, ROUND(SUM(s.Weekly_Sales),2) AS total_sales
FROM sales s JOIN stores st ON s.Store = st.Store
GROUP BY st.Store, st.Type, st.Size
ORDER BY total_sales DESC
LIMIT 5;

SELECT st.Store, st.Type, st.Size, ROUND(SUM(s.Weekly_Sales),2) AS total_sales
FROM sales s JOIN stores st ON s.Store = st.Store
GROUP BY st.Store, st.Type, st.Size
ORDER BY total_sales ASC
LIMIT 5;

-- 5.2 Sales efficiency: revenue per square foot by store type
SELECT
    st.Type,
    ROUND(SUM(s.Weekly_Sales),2) AS total_sales,
    ROUND(SUM(s.Weekly_Sales) / AVG(st.Size), 2) AS sales_per_sqft
FROM sales s
JOIN stores st ON s.Store = st.Store
GROUP BY st.Type
ORDER BY sales_per_sqft DESC;

-- 5.3 Store performance vs company average (over/under performers)
WITH store_avg AS (
    SELECT Store, AVG(Weekly_Sales) AS avg_sales
    FROM sales GROUP BY Store
),
company_avg AS (
    SELECT AVG(Weekly_Sales) AS overall_avg FROM sales
)
SELECT
    st.Store, st.Type,
    ROUND(sa.avg_sales,2) AS store_avg_weekly_sales,
    ROUND(ca.overall_avg,2) AS company_avg_weekly_sales,
    ROUND((sa.avg_sales - ca.overall_avg) * 100.0 / ca.overall_avg, 2) AS pct_vs_company_avg
FROM store_avg sa, company_avg ca
JOIN stores st ON st.Store = sa.Store
ORDER BY pct_vs_company_avg DESC;


-- ---------------------------------------------------------
-- 6. ECONOMIC FACTOR CORRELATION (subquery-driven)
-- ---------------------------------------------------------

-- 6.1 Average sales at different fuel price bands
SELECT
    CASE
        WHEN f.Fuel_Price < 3.2 THEN 'Low (<$3.20)'
        WHEN f.Fuel_Price < 3.5 THEN 'Mid ($3.20-3.50)'
        ELSE 'High (>$3.50)'
    END AS fuel_price_band,
    ROUND(AVG(s.Weekly_Sales),2) AS avg_sales
FROM sales s
JOIN features f ON s.Store = f.Store AND s.Date = f.Date
GROUP BY fuel_price_band
ORDER BY avg_sales DESC;

-- 6.2 Stores with above-average unemployment but still above-average sales
-- (resilient markets — useful for expansion/marketing prioritization)
SELECT DISTINCT st.Store, st.Type
FROM stores st
WHERE st.Store IN (
    SELECT f.Store FROM features f
    WHERE f.Unemployment > (SELECT AVG(Unemployment) FROM features)
)
AND st.Store IN (
    SELECT s.Store FROM sales s
    GROUP BY s.Store
    HAVING AVG(s.Weekly_Sales) > (SELECT AVG(Weekly_Sales) FROM sales)
);


-- ---------------------------------------------------------
-- 7. CUSTOMER BEHAVIOR PROXIES
-- (No raw transaction/customer table in this dataset, so we
-- proxy basket strength via department diversity per store
-- and spend concentration — standard workaround for
-- store-level retail data.)
-- ---------------------------------------------------------

-- 7.1 Department diversity per store (how many departments drive 80% of a store's sales — concentration risk)
WITH store_dept_sales AS (
    SELECT Store, Dept, SUM(Weekly_Sales) AS dept_sales
    FROM sales GROUP BY Store, Dept
),
ranked AS (
    SELECT Store, Dept, dept_sales,
           SUM(dept_sales) OVER (PARTITION BY Store ORDER BY dept_sales DESC) AS running_total,
           SUM(dept_sales) OVER (PARTITION BY Store) AS store_total
    FROM store_dept_sales
)
SELECT Store,
       COUNT(*) AS depts_to_reach_80pct
FROM ranked
WHERE running_total <= store_total * 0.8
GROUP BY Store
ORDER BY depts_to_reach_80pct;

-- 7.2 Most consistent vs most volatile departments (std-dev proxy via variance formula, SQLite has no STDEV built-in)
SELECT
    d.DeptName,
    ROUND(AVG(s.Weekly_Sales),2) AS avg_sales,
    ROUND(
        SQRT(AVG(s.Weekly_Sales * s.Weekly_Sales) - AVG(s.Weekly_Sales) * AVG(s.Weekly_Sales))
        / AVG(s.Weekly_Sales), 3
    ) AS coefficient_of_variation
FROM sales s
JOIN departments d ON s.Dept = d.Dept
GROUP BY d.DeptName
ORDER BY coefficient_of_variation DESC;

-- =========================================================
-- END OF ANALYSIS QUERIES
-- =========================================================
