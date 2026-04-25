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