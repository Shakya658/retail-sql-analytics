-- =============================================
-- bronze layer: raw table definitions
-- all columns varchar to safely accept raw data
-- no transformations, no business logic
-- =============================================

-- orders: one row per order
create table bronze.raw_orders (
    order_id                          varchar,
    customer_id                       varchar,
    order_status                      varchar,
    order_purchase_timestamp          varchar,
    order_approved_at                 varchar,
    order_delivered_carrier_date      varchar,
    order_delivered_customer_date     varchar,
    order_estimated_delivery_date     varchar
);

-- order items: one row per item within an order
-- an order can have multiple items
create table bronze.raw_order_items (
    order_id             varchar,
    order_item_id        varchar,
    product_id           varchar,
    seller_id            varchar,
    shipping_limit_date  varchar,
    price                varchar,
    freight_value        varchar
);

-- customers: one row per customer
create table bronze.raw_customers (
    customer_id               varchar,
    customer_unique_id        varchar,
    customer_zip_code_prefix  varchar,
    customer_city             varchar,
    customer_state            varchar
);

-- products: one row per product sku
create table bronze.raw_products (
    product_id                  varchar,
    product_category_name       varchar,
    product_name_length         varchar,
    product_description_length  varchar,
    product_photos_qty          varchar,
    product_weight_g            varchar,
    product_length_cm           varchar,
    product_height_cm           varchar,
    product_width_cm            varchar
);

-- payments: one row per payment event
-- one order can have multiple payment rows (e.g. card + voucher)
create table bronze.raw_payments (
    order_id              varchar,
    payment_sequential    varchar,
    payment_type          varchar,
    payment_installments  varchar,
    payment_value         varchar
);

-- reviews: one row per customer review
create table bronze.raw_reviews (
    review_id                varchar,
    order_id                 varchar,
    review_score             varchar,
    review_comment_title     varchar,
    review_comment_message   varchar,
    review_creation_date     varchar,
    review_answer_timestamp  varchar
);

-- sellers: one row per seller
create table bronze.raw_sellers (
    seller_id                varchar,
    seller_zip_code_prefix   varchar,
    seller_city              varchar,
    seller_state             varchar
);

-- geolocation: zip code to location mapping
create table bronze.raw_geolocation (
    geolocation_zip_code_prefix  varchar,
    geolocation_lat              varchar,
    geolocation_lng              varchar,
    geolocation_city             varchar,
    geolocation_state            varchar
);

-- category name translation: portuguese to english
create table bronze.raw_category_name_translation (
    product_category_name          varchar,
    product_category_name_english  varchar
);


-- =============================================
-- verify bronze layer row counts
-- =============================================

select 'raw_orders'                    as table_name, count(*) as row_count from bronze.raw_orders
union all
select 'raw_order_items',              count(*) from bronze.raw_order_items
union all
select 'raw_customers',                count(*) from bronze.raw_customers
union all
select 'raw_products',                 count(*) from bronze.raw_products
union all
select 'raw_payments',                 count(*) from bronze.raw_payments
union all
select 'raw_reviews',                  count(*) from bronze.raw_reviews
union all
select 'raw_sellers',                  count(*) from bronze.raw_sellers
union all
select 'raw_geolocation',              count(*) from bronze.raw_geolocation
union all
select 'raw_category_name_translation', count(*) from bronze.raw_category_name_translation;