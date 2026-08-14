-- =========================================================
-- Walmart Sales Data Analysis — Database Schema
-- =========================================================

DROP TABLE IF EXISTS sales;
DROP TABLE IF EXISTS stores;
DROP TABLE IF EXISTS features;
DROP TABLE IF EXISTS departments;

CREATE TABLE stores (
    Store       INTEGER PRIMARY KEY,
    Type        TEXT NOT NULL,      -- A, B, C store format
    Size        INTEGER NOT NULL    -- square footage
);

CREATE TABLE departments (
    Dept        INTEGER PRIMARY KEY,
    DeptName    TEXT NOT NULL
);

CREATE TABLE features (
    Store         INTEGER NOT NULL,
    Date          TEXT NOT NULL,
    Temperature   REAL,
    Fuel_Price    REAL,
    CPI           REAL,
    Unemployment  REAL,
    IsHoliday     INTEGER NOT NULL,
    PRIMARY KEY (Store, Date),
    FOREIGN KEY (Store) REFERENCES stores(Store)
);

CREATE TABLE sales (
    Store         INTEGER NOT NULL,
    Dept          INTEGER NOT NULL,
    Date          TEXT NOT NULL,
    Weekly_Sales  REAL NOT NULL,
    IsHoliday     INTEGER NOT NULL,
    FOREIGN KEY (Store) REFERENCES stores(Store),
    FOREIGN KEY (Dept) REFERENCES departments(Dept)
);

CREATE INDEX idx_sales_store ON sales(Store);
CREATE INDEX idx_sales_dept ON sales(Dept);
CREATE INDEX idx_sales_date ON sales(Date);
CREATE INDEX idx_features_store_date ON features(Store, Date);
