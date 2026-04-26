-- =============================================
-- gold.sales_summary_monthly
-- monthly revenue, order volume, and aov
-- by state
-- answers: which months and states drive revenue?
-- =============================================

create table gold.sales_summary_monthly as

-- step 1: join orders, items, and customers together
-- build one clean row per order with all the info we need
with order_revenue as (
    select
        o.order_id,
        o.order_status,
        o.order_purchase_timestamp,

        -- truncate the timestamp down to just the month
        date_trunc('month', o.order_purchase_timestamp)     as order_month,

        c.customer_state,

        -- total revenue for this order = sum of all item prices
        sum(i.price)                                        as order_revenue,

        -- total freight for this order
        sum(i.freight_value)                                as order_freight,

        -- total items in this order
        count(i.order_item_id)                              as item_count
    from silver.orders o
    inner join silver.order_items i
        on o.order_id = i.order_id
    inner join silver.customers c
        on o.customer_id = c.customer_id
    -- only count completed orders, not cancelled or unavailable
    where o.order_status in ('delivered', 'shipped', 'invoiced', 'processing')
    group by
        o.order_id,
        o.order_status,
        o.order_purchase_timestamp,
        c.customer_state
)
-- step 2: aggregate to monthly level by state
select
    order_month,
    customer_state,

    -- how many orders in this month and state
    count(order_id)                                         as total_orders,

    -- total revenue
    round(sum(order_revenue), 2)                            as total_revenue,

    -- total freight collected
    round(sum(order_freight), 2)                            as total_freight,

    -- average order value = revenue divided by number of orders
    round(sum(order_revenue) / count(order_id), 2)          as avg_order_value,

    -- average items per order
    round(avg(item_count), 2)                               as avg_items_per_order
from order_revenue
group by order_month, customer_state
order by order_month, total_revenue desc;

-- top 10 months by revenue across all states
select
    order_month,
    sum(total_revenue)                                      as monthly_revenue,
    sum(total_orders)                                       as monthly_orders,
    round(avg(avg_order_value), 2)                          as avg_order_value
from gold.sales_summary_monthly
group by order_month
order by monthly_revenue desc
limit 10;

-- revenue by state overall
select
    customer_state,
    sum(total_revenue)                                      as total_revenue,
    sum(total_orders)                                       as total_orders
from gold.sales_summary_monthly
group by customer_state
order by total_revenue desc;