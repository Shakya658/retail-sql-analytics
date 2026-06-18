# Retail Sales Analytics Pipeline

**End-to-End SQL Project | Medallion Architecture | PostgreSQL | Power BI**

A production-style retail analytics pipeline built in PostgreSQL using a Bronze → Silver → Gold architecture. The project processes approximately **1.6 million rows across nine source tables**, transforms raw e-commerce data into business-ready analytical models, and presents the results in a five-page Power BI dashboard.

## Project Overview

The project demonstrates practical data-analyst and analytics-engineering skills across:

- Relational data modelling
- Raw-data ingestion
- Data cleaning and type conversion
- Reusable analytical tables
- Window functions and multi-step CTEs
- RFM customer segmentation
- Cohort-retention analysis
- Fulfilment and regional performance analysis
- Power BI reporting and business storytelling

## Business Questions

| # | Business question | Gold table |
|---:|---|---|
| 1 | Which months and states generate the most revenue, and how is performance trending? | `gold.sales_summary_monthly` |
| 2 | Which products and categories drive the most revenue? | `gold.product_performance` |
| 3 | Who are the highest-value customers, and what does each segment look like? | `gold.customer_rfm` |
| 4 | Which states show declining revenue and need attention? | `gold.sales_summary_monthly` |
| 5 | What is the average basket size, and how does it vary by state? | `gold.sales_summary_monthly` |
| 6 | How well are customers retained after their first purchase? | `gold.cohort_retention` |
| 7 | Where are delays occurring in the fulfilment process? | `gold.fulfilment_metrics` |
| 8 | Which product categories combine high revenue with lower customer satisfaction? | `gold.product_performance` |

## Data Architecture

```text
Raw CSV files
      │
      ▼
BRONZE LAYER
- Direct source ingestion
- Nine raw tables
- Source columns retained as VARCHAR
- Approximately 1.6 million rows
      │
      ▼
SILVER LAYER
- Cleaned and standardised records
- Correct PostgreSQL data types
- Null handling and validation
- Product-category translation
- Australian scenario mapping
- Six transformed analytical tables
      │
      ▼
GOLD LAYER
- Business-ready aggregate tables
- Revenue, customer, product, cohort and fulfilment models
- Five final analytical tables
      │
      ▼
POWER BI
- Five dashboard pages
- Executive KPIs and visual storytelling
```

## Dataset and Australian Scenario

The underlying source is the **Olist Brazilian E-Commerce dataset** from Kaggle.

To make the portfolio scenario more relevant to the Australian job market, Brazilian state codes are **synthetically remapped** to Australian state and territory labels in the Silver customer transformation. This is a presentation-layer scenario transformation only.

Important limitations:

- The underlying customer behaviour, order history and transaction values remain based on the Olist dataset.
- NSW, VIC, QLD and other Australian labels do not represent real Australian transactions.
- Geographic findings should be interpreted as scenario-based portfolio insights, not real Australian market research.

The mapping logic is documented in `sql/02_silver/create_silver_tables.sql`.

## Key Findings

### Revenue and sales

- November 2017 was the highest-revenue month at approximately **$1.00 million**, driven by Black Friday-period sales.
- Average order value increased by approximately **14% from January to April 2018**.
- In the Australian scenario, NSW generated approximately **$5.56 million** and recorded the fastest average fulfilment time.

### Customer segmentation

- **Champions**, representing approximately **12.3%** of customers, generated approximately **21.1%** of revenue.
- **Potential Loyalists**, representing approximately **24.8%** of customers, contributed approximately **8.6%** of revenue, indicating a meaningful development opportunity.
- Retention falls below 1% after the first purchase in later cohort periods, suggesting strong dependence on customer acquisition.

### Product performance

- Health and Beauty led category revenue at approximately **$1.23 million**, with an average rating of approximately **4.25**.
- Bed, Bath and Table showed a potential risk pattern: high revenue combined with a lower average satisfaction score of approximately **3.90**.
- Computers recorded the highest average order value at approximately **$1,367 per order**.

### Fulfilment and operations

- VIC recorded the lowest on-time delivery rate at approximately **86.82%**, despite high order volume.
- ACT had the slowest average fulfilment time at approximately **18.72 days**.
- NSW performed strongest overall, with approximately **94%** on-time delivery and an average fulfilment time of approximately **9.1 days**.

These values reflect the current transformed portfolio scenario and should be interpreted alongside the localisation note above.

## Repository Structure

```text
retail-sql-analytics/
├── README.md
├── data/
│   └── README.md
├── docs/
│   └── data_dictionary.md
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
│   │   ├── gold_fulfilment_metrics.sql
│   │   └── gold_cohort_retention.sql
│   ├── 04_analysis/
│   │   └── business_questions.sql
│   └── 05_validation/
│       └── data_quality_checks.sql
├── Powerbi/
│   └── retail_analytics.pbix
└── Screenshots/
    ├── 01_executive_overview.png
    ├── 02_regional_performance.png
    ├── 03_product_performance.png
    ├── 04_customer_segmentation.png
    └── 05_cohort_retention.png
```

The existing `Powerbi/` and `Screenshots/` folder names are retained to avoid breaking current file paths and README image links.

## How to Run the Project

### Prerequisites

- PostgreSQL 15 or later
- DBeaver, pgAdmin or another PostgreSQL client
- Power BI Desktop
- Git
- The Olist CSV files listed in `data/README.md`

### 1. Clone the repository

```bash
git clone https://github.com/Shakya658/retail-sql-analytics.git
cd retail-sql-analytics
```

### 2. Download the source data

Download the Olist Brazilian E-Commerce dataset from Kaggle and follow the file-placement and naming instructions in:

```text
data/README.md
```

The raw CSV files are not committed to this repository.

### 3. Create the PostgreSQL schemas

Run:

```text
sql/00_setup/create_schemas.sql
```

### 4. Create the Bronze tables

Run:

```text
sql/01_bronze/create_bronze_tables.sql
```

### 5. Import the CSV files

Import each source CSV into its matching `bronze.raw_*` table using DBeaver or another PostgreSQL import tool.

Examples:

| Source file | Target table |
|---|---|
| Orders CSV | `bronze.raw_orders` |
| Order items CSV | `bronze.raw_order_items` |
| Customers CSV | `bronze.raw_customers` |
| Products CSV | `bronze.raw_products` |
| Payments CSV | `bronze.raw_payments` |
| Reviews CSV | `bronze.raw_reviews` |
| Sellers CSV | `bronze.raw_sellers` |
| Geolocation CSV | `bronze.raw_geolocation` |
| Category translation CSV | `bronze.raw_category_name_translation` |

After import, use the row-count query at the bottom of `create_bronze_tables.sql` to confirm the tables were populated.

### 6. Build the Silver layer

Run:

```text
sql/02_silver/create_silver_tables.sql
```

This script applies type conversion, null handling, category translation, review cleaning and the Australian scenario mapping.

### 7. Build the Gold layer

Run the Gold scripts in this order:

```text
sql/03_gold/gold_sales_summary.sql
sql/03_gold/gold_product_performance.sql
sql/03_gold/gold_customer_rfm.sql
sql/03_gold/gold_fulfilment_metrics.sql
sql/03_gold/gold_cohort_retention.sql
```

### 8. Validate the pipeline

Run:

```text
sql/05_validation/data_quality_checks.sql
```

The validation script checks:

- Bronze, Silver and Gold row counts
- Nulls in required keys
- Duplicate business keys
- Referential-integrity gaps
- Negative prices and freight values
- Review scores outside the valid 1–5 range

Required-key, duplicate-key and invalid-value issue counts should normally be zero. Any non-zero referential-integrity count should be investigated and documented.

### 9. Run the business analysis

Run:

```text
sql/04_analysis/business_questions.sql
```

### 10. Open the Power BI dashboard

Open:

```text
Powerbi/retail_analytics.pbix
```

Update the PostgreSQL data-source connection to your local database, then refresh the model.

## Power BI Dashboard

The Power BI report contains five pages built from the Gold layer.

1. **Executive Overview** — revenue, order volume, average order value and trends
2. **Regional Performance** — state-level revenue and fulfilment performance
3. **Product Performance** — category revenue and satisfaction analysis
4. **Customer Segmentation** — RFM groups and revenue contribution
5. **Cohort Retention** — customer-retention heatmap over time

### Screenshots

![Executive Overview](Screenshots/01_executive_overview.png)

![Regional Performance](Screenshots/02_regional_performance.png)

![Product Performance](Screenshots/03_product_performance.png)

![Customer Segmentation](Screenshots/04_customer_segmentation.png)

![Cohort Retention](Screenshots/05_cohort_retention.png)

## SQL Skills Demonstrated

| Concept | Where used |
|---|---|
| Inner and left joins | Silver and Gold transformations |
| Multi-level CTEs | Gold analytical models |
| Window functions: `RANK`, `LAG`, `NTILE` | Trends, cohorts and RFM segmentation |
| Aggregations | All Gold tables |
| Date functions | Orders, cohorts and fulfilment |
| `CASE WHEN` logic | Silver and Gold layers |
| `COALESCE` and `NULLIF` | Cleaning and null handling |
| Percentile calculations | Fulfilment analysis |
| Regular-expression filtering | Review-score cleaning |
| Type casting | Entire Silver layer |
| Data-quality validation | `sql/05_validation/` |

## Tech Stack

- PostgreSQL 15+
- SQL
- DBeaver
- Power BI Desktop
- Power Query
- Git and GitHub
- Olist Brazilian E-Commerce dataset

## Author

**Shirish Man Shakya**  
Data Analyst | Business Intelligence | Predictive Analytics

- [Portfolio](https://shakya658.github.io/portfolio/)
- [LinkedIn](https://linkedin.com/in/shirish-man-shakya)
- [GitHub](https://github.com/Shakya658)
