# Data Dictionary

---

## Bronze Layer

### bronze.raw_orders
| Column | Type | Description |
|---|---|---|
| order_id | varchar | Unique order identifier |
| customer_id | varchar | Customer identifier (not unique per person) |
| order_status | varchar | Raw order status from source system |
| order_purchase_timestamp | varchar | When the order was placed |
| order_approved_at | varchar | When payment was approved |
| order_delivered_carrier_date | varchar | When handed to carrier |
| order_delivered_customer_date | varchar | When delivered to customer |
| order_estimated_delivery_date | varchar | Estimated delivery date at time of purchase |

### bronze.raw_order_items
| Column | Type | Description |
|---|---|---|
| order_id | varchar | Foreign key to raw_orders |
| order_item_id | varchar | Sequential item number within the order |
| product_id | varchar | Foreign key to raw_products |
| seller_id | varchar | Foreign key to raw_sellers |
| shipping_limit_date | varchar | Deadline for seller to hand to carrier |
| price | varchar | Item price in BRL (raw) |
| freight_value | varchar | Freight cost in BRL (raw) |

### bronze.raw_customers
| Column | Type | Description |
|---|---|---|
| customer_id | varchar | Order-level customer ID — not unique per person |
| customer_unique_id | varchar | True unique person identifier across orders |
| customer_zip_code_prefix | varchar | First 5 digits of zip code |
| customer_city | varchar | Customer city (raw, uncleaned) |
| customer_state | varchar | Brazilian state code (e.g. SP, RJ) |

---

## Silver Layer

### silver.orders
| Column | Type | Description |
|---|---|---|
| order_id | varchar | Unique order identifier |
| customer_id | varchar | Customer identifier |
| order_status | varchar | Cleaned and lowercased status |
| order_purchase_timestamp | timestamp | When the order was placed |
| order_approved_at | timestamp | Payment approval time — null for cancelled orders |
| order_delivered_carrier_date | timestamp | Carrier handoff time — null if not dispatched |
| order_delivered_customer_date | timestamp | Delivery time — null if not yet delivered |
| order_estimated_delivery_date | timestamp | Estimated delivery at time of purchase |

### silver.customers
| Column | Type | Description |
|---|---|---|
| customer_id | varchar | Order-level customer ID |
| customer_unique_id | varchar | True unique person identifier |
| zip_code | varchar | Customer zip code prefix |
| customer_city | varchar | City name — cleaned with initcap |
| customer_state | varchar | Mapped to Australian state (NSW, VIC, QLD etc.) |

### silver.order_items
| Column | Type | Description |
|---|---|---|
| order_id | varchar | Foreign key to silver.orders |
| order_item_id | int | Sequential item number within order |
| product_id | varchar | Foreign key to silver.products |
| seller_id | varchar | Foreign key to silver.sellers |
| shipping_limit_date | timestamp | Seller shipping deadline |
| price | numeric(10,2) | Item price |
| freight_value | numeric(10,2) | Freight cost |
| total_item_value | numeric(10,2) | price + freight_value |

### silver.products
| Column | Type | Description |
|---|---|---|
| product_id | varchar | Unique product identifier |
| product_category | varchar | English category name — 'uncategorised' if no translation |
| product_weight_g | numeric | Product weight in grams |
| product_length_cm | numeric | Product length in centimetres |
| product_height_cm | numeric | Product height in centimetres |
| product_width_cm | numeric | Product width in centimetres |

### silver.payments
| Column | Type | Description |
|---|---|---|
| order_id | varchar | Foreign key to silver.orders |
| payment_sequential | int | Payment sequence number for multi-payment orders |
| payment_type | varchar | Standardised: credit card, debit card, bank slip, voucher |
| payment_installments | int | Number of installments |
| payment_value | numeric(10,2) | Payment amount |

### silver.reviews
| Column | Type | Description |
|---|---|---|
| review_id | varchar | Unique review identifier |
| order_id | varchar | Foreign key to silver.orders |
| review_score | int | Score 1–5 |
| sentiment | varchar | Derived: negative (1-2), neutral (3), positive (4-5) |
| review_comment_title | varchar | Review title — null if not provided |
| review_comment_message | varchar | Review body — null if not provided |
| review_creation_date | timestamp | When review was submitted |
| review_answer_timestamp | timestamp | When seller responded |

### silver.sellers
| Column | Type | Description |
|---|---|---|
| seller_id | varchar | Unique seller identifier |
| zip_code | varchar | Seller zip code prefix |
| seller_city | varchar | City name — cleaned with initcap |
| seller_state | varchar | Mapped to Australian state |

---

## Gold Layer

### gold.sales_summary_monthly
| Column | Type | Description |
|---|---|---|
| order_month | timestamp | First day of the month |
| customer_state | varchar | Australian state |
| total_orders | bigint | Number of orders in this month and state |
| total_revenue | numeric | Sum of item prices |
| total_freight | numeric | Sum of freight collected |
| avg_order_value | numeric | total_revenue / total_orders |
| avg_items_per_order | numeric | Average number of items per order |

### gold.product_performance
| Column | Type | Description |
|---|---|---|
| product_id | varchar | Unique product identifier |
| product_category | varchar | English category name |
| total_orders | bigint | Number of delivered orders containing this product |
| total_units_sold | bigint | Total units sold (each row in order_items = 1 unit) |
| total_revenue | numeric | Sum of price across all delivered orders |
| avg_price | numeric | Average selling price |
| avg_review_score | numeric | Average review score for orders containing this product |
| total_reviews | bigint | Number of reviews |
| revenue_per_review | numeric | total_revenue / total_reviews |

### gold.customer_rfm
| Column | Type | Description |
|---|---|---|
| customer_unique_id | varchar | True unique customer identifier |
| customer_state | varchar | Australian state |
| recency_days | numeric | Days since last order (vs dataset max date) |
| frequency | bigint | Number of delivered orders placed |
| monetary_value | numeric | Total spend across all delivered orders |
| r_score | int | Recency score 1–4 (4 = most recent) |
| f_score | int | Frequency score 1–4 (4 = most frequent) |
| m_score | int | Monetary score 1–4 (4 = highest spend) |
| rfm_total_score | int | Sum of r + f + m scores (max 12) |
| customer_segment | varchar | Champion, Loyal, Potential Loyalist, At Risk, Cannot Lose Them, Lost, Needs Attention |

### gold.cohort_retention
| Column | Type | Description |
|---|---|---|
| cohort_month | timestamp | Month of customer's first purchase |
| cohort_period | numeric | Months since first purchase (0 = acquisition month) |
| retained_customers | bigint | Customers from this cohort active in this period |
| cohort_size | bigint | Total customers in this cohort (period 0 count) |
| retention_rate_pct | numeric | retained_customers / cohort_size × 100 |

### gold.fulfilment_metrics
| Column | Type | Description |
|---|---|---|
| customer_state | varchar | Australian state |
| total_orders | bigint | Total delivered orders used in calculation |
| avg_days_to_approval | numeric | Avg days from purchase to payment approval |
| avg_days_to_carrier | numeric | Avg days from approval to carrier handoff |
| avg_days_to_delivery | numeric | Avg days from carrier handoff to customer delivery |
| avg_total_fulfilment_days | numeric | Avg end-to-end days from purchase to delivery |
| median_fulfilment_days | numeric | Median end-to-end fulfilment days |
| on_time_delivery_pct | numeric | % of orders delivered on or before estimated date |
| min_fulfilment_days | numeric | Fastest delivery in this state |
| max_fulfilment_days | numeric | Slowest delivery in this state |