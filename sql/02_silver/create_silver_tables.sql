-- =============================================
-- silver.orders
-- cleaned and typed version of bronze.raw_orders
-- =============================================

create table silver.orders as
select
    order_id,
    customer_id,

    -- standardise status to lowercase, trim whitespace
    lower(trim(order_status))                                    as order_status,

    -- cast all date strings to proper timestamps
    order_purchase_timestamp::timestamp                          as order_purchase_timestamp,

    -- approved_at can be null (e.g. cancelled orders)
    case
        when order_approved_at = '' or order_approved_at is null then null
        else order_approved_at::timestamp
    end                                                          as order_approved_at,

    -- carrier date can be null if not yet dispatched
    case
        when order_delivered_carrier_date = '' or order_delivered_carrier_date is null then null
        else order_delivered_carrier_date::timestamp
    end                                                          as order_delivered_carrier_date,

    -- delivery date can be null if not yet delivered
    case
        when order_delivered_customer_date = '' or order_delivered_customer_date is null then null
        else order_delivered_customer_date::timestamp
    end                                                          as order_delivered_customer_date,

    order_estimated_delivery_date::timestamp                     as order_estimated_delivery_date
from bronze.raw_orders
where order_id is not null
  and order_purchase_timestamp is not null;
  
 -- row count should be close to 99,441
select count(*) from silver.orders;

-- check no nulls in critical columns
select
    count(*)                                             as total_rows,
    count(order_id)                                      as non_null_order_id,
    count(order_purchase_timestamp)                      as non_null_purchase_date,
    count(order_delivered_customer_date)                 as delivered_orders
from silver.orders;

-- =============================================
-- silver.customers
-- deduplicated and au state mapped
-- =============================================

create table silver.customers as
select
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix                             as zip_code,

    -- clean city names
    initcap(trim(customer_city))                         as customer_city,

    -- map brazilian states to australian states
    -- this makes the project locally relevant
    case customer_state
        when 'SP' then 'NSW'
        when 'RJ' then 'VIC'
        when 'MG' then 'QLD'
        when 'RS' then 'SA'
        when 'PR' then 'WA'
        when 'SC' then 'TAS'
        when 'BA' then 'ACT'
        when 'GO' then 'NT'
        when 'DF' then 'NSW'
        when 'ES' then 'VIC'
        when 'PE' then 'QLD'
        when 'CE' then 'SA'
        when 'PA' then 'WA'
        when 'MT' then 'TAS'
        when 'MS' then 'ACT'
        when 'MA' then 'NT'
        when 'RN' then 'NSW'
        when 'PB' then 'VIC'
        when 'PI' then 'QLD'
        when 'AL' then 'SA'
        when 'SE' then 'WA'
        when 'TO' then 'TAS'
        when 'RO' then 'ACT'
        when 'AM' then 'NT'
        when 'AC' then 'NSW'
        when 'AP' then 'VIC'
        when 'RR' then 'QLD'
        else 'NSW'
    end                                                  as customer_state

from bronze.raw_customers
where customer_id is not null
  and customer_unique_id is not null;
 
-- row count should match bronze
select count(*) from silver.customers;

-- check state mapping worked
select
    customer_state,
    count(*) as customer_count
from silver.customers
group by customer_state
order by customer_count desc;

-- =============================================
-- silver.order_items
-- typed and enriched order items
-- =============================================

create table silver.order_items as
select
    order_id,
    order_item_id::int                                   as order_item_id,
    product_id,
    seller_id,
    shipping_limit_date::timestamp                       as shipping_limit_date,
    price::numeric(10,2)                                 as price,
    freight_value::numeric(10,2)                         as freight_value,

    -- calculated column: total value of this line item
    (price::numeric(10,2) + freight_value::numeric(10,2)) as total_item_value
from bronze.raw_order_items
where order_id is not null
  and product_id is not null
  and price is not null;
  
select
    count(*)                        as total_rows,
    round(avg(price::numeric),2)    as avg_price,
    round(avg(freight_value::numeric),2) as avg_freight,
    min(price::numeric)             as min_price,
    max(price::numeric)             as max_price
from silver.order_items;

-- =============================================
-- silver.products
-- english categories, typed dimensions
-- =============================================

create table silver.products as
select
    p.product_id,

    -- use english category name, fall back to 'uncategorised' if null
    coalesce(t.product_category_name_english, 'uncategorised') as product_category,

    -- cast dimensions to numeric, null if missing
    case
        when p.product_weight_g = '' or p.product_weight_g is null then null
        else p.product_weight_g::numeric
    end                                                         as product_weight_g,

    case
        when p.product_length_cm = '' or p.product_length_cm is null then null
        else p.product_length_cm::numeric
    end                                                         as product_length_cm,

    case
        when p.product_height_cm = '' or p.product_height_cm is null then null
        else p.product_height_cm::numeric
    end                                                         as product_height_cm,

    case
        when p.product_width_cm = '' or p.product_width_cm is null then null
        else p.product_width_cm::numeric
    end                                                         as product_width_cm
from bronze.raw_products p
left join bronze.raw_category_name_translation t
    on p.product_category_name = t.product_category_name
where p.product_id is not null;

-- check english categories came through
select
    product_category,
    count(*) as product_count
from silver.products
group by product_category
order by product_count desc
limit 10;

-- =============================================
-- silver.payments
-- typed, standardised payment records
-- =============================================

create table silver.payments as
select
    order_id,
    payment_sequential::int                              as payment_sequential,

    -- standardise payment type labels
    case lower(trim(payment_type))
        when 'credit_card'  then 'credit card'
        when 'boleto'       then 'bank slip'
        when 'voucher'      then 'voucher'
        when 'debit_card'   then 'debit card'
        else 'other'
    end                                                  as payment_type,

    payment_installments::int                            as payment_installments,
    payment_value::numeric(10,2)                         as payment_value
from bronze.raw_payments
where order_id is not null
  and payment_value is not null;
  
select
    payment_type,
    count(*)                            as transaction_count,
    round(sum(payment_value),2)         as total_value,
    round(avg(payment_value),2)         as avg_value
from silver.payments
group by payment_type
order by transaction_count desc;

-- =============================================
-- silver.reviews
-- typed scores with sentiment classification
-- =============================================

create table silver.reviews as
select
    review_id,
    order_id,
    review_score::int                                    as review_score,

    case
        when review_score::int in (1, 2) then 'negative'
        when review_score::int = 3       then 'neutral'
        when review_score::int in (4, 5) then 'positive'
        else 'unknown'
    end                                                  as sentiment,

    case
        when review_comment_title = '' or review_comment_title is null then null
        else trim(review_comment_title)
    end                                                  as review_comment_title,

    case
        when review_comment_message = '' or review_comment_message is null then null
        else trim(review_comment_message)
    end                                                  as review_comment_message,

    review_creation_date::timestamp                      as review_creation_date,
    review_answer_timestamp::timestamp                   as review_answer_timestamp

from bronze.raw_reviews
where review_id is not null
  and order_id is not null
  and review_score is not null
  -- filter out any rows where score is not a clean single digit
  and review_score ~ '^[1-5]$';
  
 select
    sentiment,
    count(*)                                             as review_count,
    round(count(*) * 100.0 / sum(count(*)) over(), 1)   as pct
from silver.reviews
group by sentiment
order by review_count desc;

-- =============================================
-- silver.sellers
-- au state mapped, cleaned city names
-- =============================================

create table silver.sellers as
select
    seller_id,
    seller_zip_code_prefix                               as zip_code,
    initcap(trim(seller_city))                           as seller_city,

    case seller_state
        when 'SP' then 'NSW'
        when 'RJ' then 'VIC'
        when 'MG' then 'QLD'
        when 'RS' then 'SA'
        when 'PR' then 'WA'
        when 'SC' then 'TAS'
        when 'BA' then 'ACT'
        when 'GO' then 'NT'
        when 'DF' then 'NSW'
        when 'ES' then 'VIC'
        when 'PE' then 'QLD'
        when 'CE' then 'SA'
        when 'PA' then 'WA'
        when 'MT' then 'TAS'
        when 'MS' then 'ACT'
        when 'MA' then 'NT'
        when 'RN' then 'NSW'
        when 'PB' then 'VIC'
        when 'PI' then 'QLD'
        when 'AL' then 'SA'
        when 'SE' then 'WA'
        when 'TO' then 'TAS'
        when 'RO' then 'ACT'
        when 'AM' then 'NT'
        when 'AC' then 'NSW'
        when 'AP' then 'VIC'
        when 'RR' then 'QLD'
        else 'NSW'
    end                                                  as seller_state
from bronze.raw_sellers
where seller_id is not null;

select
    seller_state,
    count(*) as seller_count
from silver.sellers
group by seller_state
order by seller_count desc;

-- confirm all 7 silver tables exist with correct row counts
select 'orders'     as table_name, count(*) as row_count from silver.orders
union all
select 'order_items',               count(*) from silver.order_items
union all
select 'customers',                 count(*) from silver.customers
union all
select 'products',                  count(*) from silver.products
union all
select 'payments',                  count(*) from silver.payments
union all
select 'reviews',                   count(*) from silver.reviews
union all
select 'sellers',                   count(*) from silver.sellers;