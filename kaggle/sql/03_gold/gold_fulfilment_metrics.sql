-- =============================================
-- gold.fulfilment_metrics
-- order fulfilment time analysis by state
-- answers: where are the delays in our delivery process?
-- =============================================

create table gold.fulfilment_metrics as
-- step 1: calculate time intervals for each delivered order
with order_intervals as (
    select
        o.order_id,
        c.customer_state,
        -- days from purchase to payment approval
        round(
            extract(epoch from (
                o.order_approved_at - o.order_purchase_timestamp
            )) / 86400
        , 2)                                                as days_to_approval,
        -- days from approval to carrier pickup
        round(
            extract(epoch from (
                o.order_delivered_carrier_date - o.order_approved_at
            )) / 86400
        , 2)                                                as days_to_carrier,
        -- days from carrier pickup to customer delivery
        round(
            extract(epoch from (
                o.order_delivered_customer_date - o.order_delivered_carrier_date
            )) / 86400
        , 2)                                                as days_to_delivery,

        -- total end to end fulfilment time
        round(
            extract(epoch from (
                o.order_delivered_customer_date - o.order_purchase_timestamp
            )) / 86400
        , 2)                                                as total_fulfilment_days,
        -- was the order delivered on time vs estimate?
        case
            when o.order_delivered_customer_date <= o.order_estimated_delivery_date
            then 1 else 0
        end                                                 as delivered_on_time

    from silver.orders o
    inner join silver.customers c
        on o.customer_id = c.customer_id
    -- only fully delivered orders with all dates present
    where o.order_status = 'delivered'
      and o.order_approved_at is not null
      and o.order_delivered_carrier_date is not null
      and o.order_delivered_customer_date is not null
)
-- step 2: aggregate to state level
select
    customer_state,
    count(order_id)                                         as total_orders,
    -- average time for each fulfilment stage
    round(avg(days_to_approval), 2)                         as avg_days_to_approval,
    round(avg(days_to_carrier), 2)                          as avg_days_to_carrier,
    round(avg(days_to_delivery), 2)                         as avg_days_to_delivery,
    round(avg(total_fulfilment_days), 2)                    as avg_total_fulfilment_days,
    -- median total fulfilment days
    -- more reliable than average when data is skewed
    round(cast(
        percentile_cont(0.5) within group (
            order by total_fulfilment_days
        ) as numeric
    ), 2)                                                   as median_fulfilment_days,
    -- on time delivery rate as a percentage
    round(
        sum(delivered_on_time) * 100.0 / count(order_id)
    , 2)                                                    as on_time_delivery_pct,
    -- fastest and slowest deliveries
    min(total_fulfilment_days)                              as min_fulfilment_days,
    max(total_fulfilment_days)                              as max_fulfilment_days
from order_intervals
group by customer_state
order by avg_total_fulfilment_days asc;

select
    customer_state,
    total_orders,
    avg_total_fulfilment_days,
    median_fulfilment_days,
    on_time_delivery_pct
from gold.fulfilment_metrics
order by avg_total_fulfilment_days asc;