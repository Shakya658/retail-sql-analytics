-- ============================================================================
-- Project: Retail Sales Analytics Pipeline
-- Script: data_quality_checks.sql
-- Purpose: Validate row volumes, required keys, duplicate keys and Gold outputs
--          after the Bronze, Silver and Gold layers have been created.
-- ============================================================================

-- 1. Bronze row counts
SELECT 'bronze.raw_orders' AS table_name, COUNT(*) AS row_count
FROM bronze.raw_orders
UNION ALL
SELECT 'bronze.raw_order_items', COUNT(*) FROM bronze.raw_order_items
UNION ALL
SELECT 'bronze.raw_customers', COUNT(*) FROM bronze.raw_customers
UNION ALL
SELECT 'bronze.raw_products', COUNT(*) FROM bronze.raw_products
UNION ALL
SELECT 'bronze.raw_payments', COUNT(*) FROM bronze.raw_payments
UNION ALL
SELECT 'bronze.raw_reviews', COUNT(*) FROM bronze.raw_reviews
UNION ALL
SELECT 'bronze.raw_sellers', COUNT(*) FROM bronze.raw_sellers
UNION ALL
SELECT 'bronze.raw_geolocation', COUNT(*) FROM bronze.raw_geolocation
UNION ALL
SELECT 'bronze.raw_category_name_translation', COUNT(*)
FROM bronze.raw_category_name_translation
ORDER BY table_name;

-- 2. Silver row counts
SELECT 'silver.orders' AS table_name, COUNT(*) AS row_count
FROM silver.orders
UNION ALL
SELECT 'silver.order_items', COUNT(*) FROM silver.order_items
UNION ALL
SELECT 'silver.customers', COUNT(*) FROM silver.customers
UNION ALL
SELECT 'silver.products', COUNT(*) FROM silver.products
UNION ALL
SELECT 'silver.payments', COUNT(*) FROM silver.payments
UNION ALL
SELECT 'silver.reviews', COUNT(*) FROM silver.reviews
ORDER BY table_name;

-- 3. Required-key null checks
SELECT 'silver.orders.order_id' AS check_name, COUNT(*) AS issue_count
FROM silver.orders
WHERE order_id IS NULL
UNION ALL
SELECT 'silver.orders.customer_id', COUNT(*)
FROM silver.orders
WHERE customer_id IS NULL
UNION ALL
SELECT 'silver.customers.customer_id', COUNT(*)
FROM silver.customers
WHERE customer_id IS NULL
UNION ALL
SELECT 'silver.order_items.order_id', COUNT(*)
FROM silver.order_items
WHERE order_id IS NULL
UNION ALL
SELECT 'silver.order_items.product_id', COUNT(*)
FROM silver.order_items
WHERE product_id IS NULL
UNION ALL
SELECT 'silver.products.product_id', COUNT(*)
FROM silver.products
WHERE product_id IS NULL;

-- 4. Duplicate business-key checks
SELECT 'silver.orders.order_id' AS check_name,
       COUNT(*) AS duplicate_group_count
FROM (
    SELECT order_id
    FROM silver.orders
    GROUP BY order_id
    HAVING COUNT(*) > 1
) AS duplicates
UNION ALL
SELECT 'silver.customers.customer_id', COUNT(*)
FROM (
    SELECT customer_id
    FROM silver.customers
    GROUP BY customer_id
    HAVING COUNT(*) > 1
) AS duplicates
UNION ALL
SELECT 'silver.products.product_id', COUNT(*)
FROM (
    SELECT product_id
    FROM silver.products
    GROUP BY product_id
    HAVING COUNT(*) > 1
) AS duplicates;

-- 5. Referential-integrity checks between transformed tables
SELECT 'orders_without_customer' AS check_name, COUNT(*) AS issue_count
FROM silver.orders AS o
LEFT JOIN silver.customers AS c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL
UNION ALL
SELECT 'items_without_order', COUNT(*)
FROM silver.order_items AS i
LEFT JOIN silver.orders AS o
    ON i.order_id = o.order_id
WHERE o.order_id IS NULL
UNION ALL
SELECT 'items_without_product', COUNT(*)
FROM silver.order_items AS i
LEFT JOIN silver.products AS p
    ON i.product_id = p.product_id
WHERE p.product_id IS NULL;

-- 6. Basic value-range checks
SELECT 'negative_item_price' AS check_name, COUNT(*) AS issue_count
FROM silver.order_items
WHERE price < 0
UNION ALL
SELECT 'negative_freight_value', COUNT(*)
FROM silver.order_items
WHERE freight_value < 0
UNION ALL
SELECT 'review_score_outside_1_to_5', COUNT(*)
FROM silver.reviews
WHERE review_score NOT BETWEEN 1 AND 5;

-- 7. Gold-layer row counts
SELECT 'gold.sales_summary_monthly' AS table_name, COUNT(*) AS row_count
FROM gold.sales_summary_monthly
UNION ALL
SELECT 'gold.product_performance', COUNT(*) FROM gold.product_performance
UNION ALL
SELECT 'gold.customer_rfm', COUNT(*) FROM gold.customer_rfm
UNION ALL
SELECT 'gold.fulfilment_metrics', COUNT(*) FROM gold.fulfilment_metrics
UNION ALL
SELECT 'gold.cohort_retention', COUNT(*) FROM gold.cohort_retention
ORDER BY table_name;

-- Expected interpretation:
-- - Required-key, duplicate-key and value-range issue counts should be zero.
-- - Referential-integrity counts should be reviewed and explained if non-zero.
-- - Row counts should be plausible relative to the source-table grain.
