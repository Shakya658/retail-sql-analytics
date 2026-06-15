# Retail Sales Analytics Pipeline
### End-to-End SQL Project | Medallion Architecture | PostgreSQL

---

## Project Overview

A production-style retail analytics pipeline built in PostgreSQL using 
Medallion Architecture (Bronze → Silver → Gold). The project ingests 
~1.6 million rows of raw e-commerce transaction data across 9 related 
tables, transforms it through cleaning and enrichment layers, and 
delivers 5 business-ready Gold tables that answer 8 core retail 
business questions.

Built to demonstrate real-world SQL skills relevant to data analyst 
roles — including window functions, CTEs, cohort analysis, and 
RFM segmentation.

---

## Business Questions Answered

| # | Business Question | Gold Table Used |
|---|---|---|
| 1 | Which months and states generate the most revenue and how is it trending? | sales_summary_monthly |
| 2 | Which products and categories drive the most revenue? | product_performance |
| 3 | Who are our high-value customers and what does each segment look like? | customer_rfm |
| 4 | Which states show declining revenue and need attention? | sales_summary_monthly |
| 5 | What is the average basket size and how does it vary by state? | sales_summary_monthly |
| 6 | How well do we retain customers after their first purchase? | cohort_retention |
| 7 | Where are the delays in our fulfilment process? | fulfilment_metrics |
| 8 | Which products have high revenue but poor customer satisfaction? | product_performance |

---

## Architecture

```Raw CSVs
│
▼
┌─────────────────────────────────────────┐
│  BRONZE LAYER                           │
│  Raw ingestion — all columns VARCHAR    │
│  9 tables — exact replica of source     │
│  ~1.6M rows total                       │
└─────────────────────────────────────────┘
│
▼
┌─────────────────────────────────────────┐
│  SILVER LAYER                           │
│  Cleaned and transformed                │
│  Proper types, nulls handled            │
│  AU state mapping applied               │
│  7 tables                               │
└─────────────────────────────────────────┘
│
▼
┌─────────────────────────────────────────┐
│  GOLD LAYER                             │
│  Business-ready aggregations            │
│  Answers specific business questions    │
│  5 tables                               │
└─────────────────────────────────────────┘

---

## Key Findings

**Revenue & Sales**
- November 2017 was the highest revenue month at $1,003,862 — driven 
  by Black Friday. Average order value grew 14% from Jan to Apr 2018.
- NSW dominates at $5.56M total revenue and fastest fulfilment 
  at 9.1 days average.

**Customer Segmentation (RFM)**
- Champions (12.3% of customers) generate 21.1% of total revenue.
- Potential Loyalists are 24.8% of customers but only 8.6% of revenue 
  — the largest re-engagement opportunity in the dataset.
- Cohort retention drops below 1% after the first purchase across 
  all 2017 cohorts — the business is acquisition-dependent.

**Product Performance**
- Health & Beauty leads revenue at $1.23M with a 4.25 review score.
- Bed, Bath & Table ($1.02M revenue) flagged as high-risk — 
  review score of 3.90 with 10,009 orders indicates a satisfaction 
  problem at scale.
- Computers average $1,367 per order — highest ticket item by far.

**Fulfilment**
- VIC ranked worst on on-time delivery at 86.82% despite being 
  the second largest market by volume — a logistics problem, 
  not a distance problem.
- ACT has the slowest average fulfilment at 18.72 days.
- NSW delivers fastest at 9.1 days with 94% on-time rate.

---

## Tech Stack

- **Database:** PostgreSQL 15+
- **Query Tool:** DBeaver
- **Version Control:** Git / GitHub
- **Dataset:** Olist Brazilian E-Commerce (Kaggle)

---

## Repository Structure
retail-sql-analytics/
│
├── README.md
│
├── data/
│   └── README.md            ← Dataset download instructions
│
├── sql/
│   ├── 00_setup/
│   │   └── create_schemas.sql
│   ├── 01_bronze/
│   │   └── create_bronze_tables.sql
│   ├── 02_silver/
│   │   └── create_silver_tables.sql
│   ├── 03_gold/
│   │   ├── gold_sales_summary.sql
│   │   ├── gold_product_performance.sql
│   │   ├── gold_customer_rfm.sql
│   │   ├── gold_cohort_retention.sql
│   │   └── gold_fulfilment_metrics.sql
│   └── 04_analysis/
│       └── business_questions.sql
│
└── docs/
└── data_dictionary.md

---

## How to Run This Project

1. Install PostgreSQL and DBeaver
2. Download the Olist dataset from Kaggle 
   (see `/data/README.md` for instructions)
3. Run scripts in order:
   - `00_setup/create_schemas.sql`
   - `01_bronze/create_bronze_tables.sql`
   - Import CSVs via DBeaver import tool
   - `02_silver/create_silver_tables.sql`
   - All scripts in `03_gold/` in any order
   - `04_analysis/business_questions.sql`

---

## SQL Concepts Demonstrated

| Concept | Where Used |
|---|---|
| Multi-table JOINs (INNER, LEFT) | All Gold tables |
| CTEs — single and chained | All Gold tables |
| Window functions — NTILE, FIRST_VALUE, LAG, RANK | RFM, cohort, trends |
| Aggregations — SUM, COUNT, AVG, COUNT DISTINCT | Throughout |
| Date functions — date_trunc, extract, epoch | Orders, cohort, fulfilment |
| CASE WHEN conditional logic | Silver layer, product quadrants |
| COALESCE and NULLIF null handling | Silver and Gold layers |
| PERCENTILE_CONT for median | Fulfilment metrics |
| Regex filtering | Silver reviews |
| Type casting | Entire Silver layer |

File names match exactly — the README section I drafted will work as-is. Here it is again, ready to paste into your README (recommended placement: after "Key Findings", before "Tech Stack"):
markdown---

## Power BI Dashboard

An interactive 5-page Power BI dashboard built on top of the Gold layer tables, 
visualizing the key findings above.

### Pages

1. **Executive Overview** — revenue trends, state-level breakdown, and 
   top-line KPIs
2. **Regional Performance** — fulfilment days and on-time delivery rate 
   by state
3. **Product Performance** — category revenue breakdown and the 
   revenue-vs-satisfaction risk analysis
4. **Customer Segmentation (RFM)** — segment distribution and revenue 
   contribution by segment
5. **Cohort Retention** — monthly cohort retention heatmap

### Screenshots

![Executive Overview](Screenshots/01_executive_overview.png)
![Regional Performance](Screenshots/02_regional_performance.png)
![Product Performance](Screenshots/03_product_performance.png)
![Customer Segmentation](Screenshots/04_customer_segmentation.png)
![Cohort Retention](Screenshots/05_cohort_retention.png)

The `.pbix` file is available in the `Powerbi/` folder — connect it to your 
own PostgreSQL instance with the Gold tables loaded to explore interactively.

---