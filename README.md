# 🚚 Supply Chain Analytics — SQL Data Engineering + Power BI Dashboard

**SQL (Data Cleaning, Modeling & Transformation) → Power BI (Dashboard & Insights)**

![SQL](https://img.shields.io/badge/SQL-Data%20Modeling-4479A1)
![Power BI](https://img.shields.io/badge/Dashboard-Power%20BI-F2C811)
![Status](https://img.shields.io/badge/Status-Complete-brightgreen)

---

## 📌 Project Overview

This project analyzes end-to-end supply chain performance — covering warehouses, suppliers, carriers, and shipments — to identify where delays originate and which parts of the network are underperforming.

Unlike a typical clean CSV → dashboard project, this one focuses on the **data engineering side of analytics**: taking messy, inconsistent, raw supply chain data and building it into a proper relational structure *inside SQL* before any visualization happens. The result is a dashboard built on trustworthy, well-modeled data rather than a single flat table.

**Workflow:**

1. **SQL** — Cleaned, standardized, deduplicated, and modeled raw supply chain data into a normalized structure with staging layers, cleaned views, and a final fact table.
2. **Power BI** — Connected to the cleaned data model and built a dashboard to surface SLA performance, carrier reliability, warehouse efficiency, and root causes of delay.

This project reflects a skill set closer to what's expected in production analytics environments: building a reliable data foundation first, then layering insight on top of it.

---

## 🧰 Tools & Tech Stack

| Stage | Tool | Purpose |
|---|---|---|
| Data Modeling & Cleaning | **SQL** | Normalize entities, standardize formats, deduplicate, build staging → clean → fact layers |
| Visualization | **Power BI** | Build an interactive dashboard on top of the cleaned data model |

---

## 🗄️ SQL Work — Data Cleaning & Modeling

All data preparation for this project was done directly in SQL, simulating a real analytics engineering workflow rather than a one-off cleaning script. Key steps:

- **Relational modeling** — Built normalized tables for the core supply chain entities: `warehouses`,  `warehouses_orders`, `orders`, `suppliers`, and `shipments`, instead of working off one wide flat table.
- **Dimension table creation** — The raw `orders` data had warehouse details embedded directly in it rather than as a separate entity. Extracted the distinct warehouse information out of `orders` and built a standalone `warehouses` dimension table, with `warehouse_id` established as its primary key — removing redundancy and giving the model a proper star-schema-style structure (fact table + dimension tables) instead of repeating warehouse attributes on every order row.
- **Date standardization** — Parsed messy, inconsistent text-based date fields (multiple formats) and converted them into proper `DATE` types for reliable time-based analysis.
- **Field standardization** — Cleaned and standardized categorical/identifier fields such as warehouse IDs, carrier names, order status, and fulfillment types to eliminate inconsistent labeling.
- **Deduplication** — Used window functions (`ROW_NUMBER()`) to identify and remove duplicate records in both transactional and master data.
- **Staging layers** — Created staging tables to safely transform raw data before it touched any final production-style tables.
- **Analytics-ready views** — Built cleaned views (`orders_clean`, `suppliers_clean`, `warehouses_clean`) to serve as the single source of truth for downstream analysis.
- **Fact table construction** — Assembled a final structured `shipments` fact table from raw staging data, ready for aggregation and reporting.
- **Referential integrity** — Applied primary and foreign key constraints across tables to enforce valid relationships and protect data quality.

> 📄 See [`schema.sql`](./sql/schema.sql) for table definitions and constraints.
> 📄 See [`cleaning.sql`](./cleaning.sql) for transformation logic.


---

## 📊 Dashboard (Power BI)

The cleaned, modeled data was connected to **Power BI** to build a dashboard focused on SLA performance, delay root causes, carrier reliability, and warehouse efficiency.

### 🔑 Key Insights

**SLA & Seasonality**
- 📉 **February recorded the lowest SLA %** across the entire period — suggesting a seasonal demand surge or post-holiday fulfillment strain.

**Carrier Performance**
- 📦 **DHL has the highest late delivery %** among all carriers — its high volume is amplifying network-wide SLA impact.
- 💰 **UPS has the 2nd highest shipping cost but ranks last on on-time delivery %** — the worst cost-to-performance ratio in the carrier portfolio.
- ⏱️ **FedEx has the longest average delivery time** across all carriers.

**Root Cause of Delays**
- 🏭 **Supplier stock shortage is the #1 root cause of delays** — the problem originates upstream, before orders even reach the warehouse or carrier.

**Warehouse Performance**
- ⚠️ **WH-30 has the highest error rate and longest processing time**, despite only medium order volume — indicating an operational or process gap rather than an overload issue.
- 🏆 **WH-35 leads the network on utilization %** — a strong candidate for a best-practice benchmark.

### 💡 Business Recommendations

1. **Fix the upstream problem first** — Prioritize supplier stock reliability; resolving this single root cause reduces downstream pressure on both carriers and warehouses simultaneously.
2. **Audit WH-30 immediately** — Investigate training, equipment, and process gaps. Its error rate is a risk multiplier for shipment delays and SLA breaches network-wide.
3. **Replicate the WH-35 model** — Study its space and throughput management practices and roll them out to underperforming warehouses.
4. **Review the UPS contract** — Paying a premium for the lowest on-time performance in the portfolio is an unacceptable cost-to-performance trade-off; renegotiate SLA terms.
5. **Re-route time-sensitive orders away from FedEx** — Given its longest average delivery time, HIGH priority orders should be shifted to faster carrier lanes.


>
> ## 📊 Dashboard Preview

### Executive Overview
![Executive Dashboard](https://github.com/4nshulj/supply-chain-analytics/blob/main/images/SCM1.png)

### Warehouse Performance
![Warehouse Dashboard](https://github.com/4nshulj/supply-chain-analytics/blob/main/images/SCM2.png)

### Carrier Analysis
![Carrier Dashboard](https://github.com/4nshulj/supply-chain-analytics/blob/main/images/SCM3.png)
---

## 📁 Project Structure

```
📦 supply-chain-analytics

├── 📁 dashboard
│   └── supply_chain_dashboard.pbix
│   └── theme
│
├── 📁 images
│   ├── SCM1
│   ├── SCM2
│   ├── SCM3
│
├── 📁 raw_data
│   ├── orders.csv
│   ├── shipments.csv
│   ├── suppliers.csv
│   ├── warehouses.csv
│   ├── warehouses_orders.csv
|
├── 📁 sql
│   └── cleaning.sql
│   └── schema.sql
│   
├──   🗄️model.ping (data model)
|
└── 📄 README.md
```

---

## ⚙️ How to Run This Project Locally

1. **Clone the repository**
   ```bash
   git clone https://github.com/<your-username>/supply-chain-analytics.git
   cd supply-chain-analytics
   ```

2. **Set up the database**
   - Create a database (e.g., `supply_chain`)
   - Run `sql/schema.sql` to create the normalized tables and constraints

3. **Load and transform the data**
   - Load raw source data into the staging tables
   - Run `sql/staging_and_cleaning.sql` to standardize, deduplicate, and populate the cleaned views (`orders_clean`, `suppliers_clean`, `warehouses_clean`) and the final `shipments` fact table

4. **Run the analysis queries**
   - Execute `sql/analysis_queries.sql` using your preferred SQL client (pgAdmin, DBeaver, SSMS, etc.)

5. **Open the dashboard**
   - Open `dashboard/supply_chain_dashboard.pbix` in Power BI Desktop
   - Update the database connection settings if needed, then refresh

---

## 🚀 Key Takeaways 

- Ability to design a **normalized relational data model** from raw, messy source data
- Strong **SQL data cleaning skills**: inconsistent date parsing, categorical standardization, deduplication with window functions
- Understanding of proper **data pipeline layering** (staging → clean views → fact tables) rather than working off one flat table
- Ability to spot embedded/repeated attributes in a flat source table and **extract them into a proper dimension table** (e.g., pulling `warehouses` out of `warehouses_orders` with `warehouse_id` as its primary key) — core star-schema thinking
- Applied knowledge of **referential integrity** and constraint design
- Ability to translate a clean data model into a **root-cause-driven business dashboard** with actionable recommendations, not just descriptive charts

---

## 👤 Author
**[Anshul]**
Aspiring Data Analyst | SQL · Data Modeling · Power BI
📧 [1311anshul@gmail.com] | 🔗 [LinkedIn](https://www.linkedin.com/in/anshuljangra4/) 
