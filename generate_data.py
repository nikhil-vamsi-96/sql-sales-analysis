import numpy as np, pandas as pd
from datetime import datetime, timedelta

rng = np.random.default_rng(42)

# --- Stores dimension (mirrors Kaggle Walmart schema) ---
n_stores = 20
store_types = rng.choice(['A','B','C'], size=n_stores, p=[0.5,0.3,0.2])
store_size = np.where(store_types=='A', rng.integers(150000,220000,n_stores),
             np.where(store_types=='B', rng.integers(90000,150000,n_stores),
                      rng.integers(35000,90000,n_stores)))
stores = pd.DataFrame({'Store': range(1,n_stores+1), 'Type': store_types, 'Size': store_size})

# --- Departments ---
depts = list(range(1,11))
dept_names = {1:'Grocery',2:'Electronics',3:'Apparel',4:'Home & Garden',5:'Toys',
              6:'Pharmacy',7:'Sporting Goods',8:'Automotive',9:'Beauty',10:'Furniture'}

# --- Weekly dates: 2 full years ---
start = datetime(2023,2,3)  # Fridays, like the real dataset
dates = [start + timedelta(weeks=i) for i in range(104)]

us_holidays = {  # approximate weekly buckets flagged IsHoliday in the real dataset
    'SuperBowl': ['2023-02-10','2024-02-09'],
    'LaborDay':  ['2023-09-08','2024-09-06'],
    'Thanksgiving': ['2023-11-24','2024-11-29'],
    'Christmas': ['2023-12-29','2024-12-27'],
}
holiday_dates = set()
for v in us_holidays.values():
    holiday_dates.update(v)

# --- Features: Store x Date (economic + weather signals) ---
feat_rows = []
for s in stores.itertuples():
    base_temp = rng.uniform(45,75)
    base_fuel = 3.2
    base_cpi = rng.uniform(210,225)
    base_unemp = rng.uniform(6.0,8.5)
    for i,d in enumerate(dates):
        seasonal_temp = base_temp + 20*np.sin(2*np.pi*(i%52)/52 - np.pi/2) + rng.normal(0,3)
        fuel = base_fuel + 0.15*np.sin(2*np.pi*i/52) + rng.normal(0,0.05) + i*0.002
        cpi = base_cpi + i*0.05 + rng.normal(0,0.3)
        unemp = max(3.5, base_unemp - i*0.01 + rng.normal(0,0.1))
        is_hol = d.strftime('%Y-%m-%d') in holiday_dates
        feat_rows.append([s.Store, d.strftime('%Y-%m-%d'), round(seasonal_temp,1),
                           round(fuel,3), round(cpi,3), round(unemp,3), int(is_hol)])
features = pd.DataFrame(feat_rows, columns=['Store','Date','Temperature','Fuel_Price','CPI','Unemployment','IsHoliday'])

# --- Sales fact table: Store x Dept x Date ---
dept_base = {1:45000,2:28000,3:22000,4:18000,5:12000,6:15000,7:14000,8:16000,9:9000,10:11000}
sales_rows = []
for s in stores.itertuples():
    size_factor = s.Size / 120000
    for dpt in depts:
        base = dept_base[dpt] * size_factor * (1.15 if s.Type=='A' else 1.0 if s.Type=='B' else 0.8)
        for i,d in enumerate(dates):
            weekly_seasonal = 1 + 0.12*np.sin(2*np.pi*(i%52)/52)
            trend = 1 + i*0.0015  # slight YoY growth
            noise = rng.normal(1, 0.08)
            dstr = d.strftime('%Y-%m-%d')
            holiday_boost = 1.0
            if dstr in us_holidays['Thanksgiving'] or dstr in us_holidays['Christmas']:
                holiday_boost = rng.uniform(1.5,2.1) if dpt in (2,3,5,10) else rng.uniform(1.15,1.4)
            elif dstr in us_holidays['SuperBowl']:
                holiday_boost = rng.uniform(1.1,1.3) if dpt in (1,7) else 1.0
            elif dstr in us_holidays['LaborDay']:
                holiday_boost = rng.uniform(1.05,1.2)
            sales = max(0, base * weekly_seasonal * trend * noise * holiday_boost)
            is_hol = dstr in holiday_dates
            sales_rows.append([s.Store, dpt, dstr, round(sales,2), int(is_hol)])

sales = pd.DataFrame(sales_rows, columns=['Store','Dept','Date','Weekly_Sales','IsHoliday'])
dept_lookup = pd.DataFrame(list(dept_names.items()), columns=['Dept','DeptName'])

stores.to_csv('stores.csv', index=False)
features.to_csv('features.csv', index=False)
sales.to_csv('sales.csv', index=False)
dept_lookup.to_csv('departments.csv', index=False)

print(stores.shape, features.shape, sales.shape)
print(sales.head())
