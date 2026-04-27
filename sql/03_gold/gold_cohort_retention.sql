-- =============================================
-- gold.cohort_retention
-- monthly cohort retention matrix
-- answers: how well do we retain customers over time?
-- =============================================

create table gold.cohort_retention as
-- step 1: find every customer's first purchase month
-- this defines which cohort they belong to
with customer_first_order as (
    select
        c.customer_unique_id,
        -- the month of their very first order = their cohort
        date_trunc('month', min(o.order_purchase_timestamp)) as cohort_month
    from silver.customers c
    inner join silver.orders o
        on c.customer_id = o.customer_id
    where o.order_status = 'delivered'
    group by c.customer_unique_id
),
-- step 2: get all orders for every customer with their cohort attached
customer_orders as (
    select
        c.customer_unique_id,
        f.cohort_month,
        -- the month this specific order was placed
        date_trunc('month', o.order_purchase_timestamp)     as order_month
    from silver.customers c
    inner join silver.orders o
        on c.customer_id = o.customer_id
    inner join customer_first_order f
        on c.customer_unique_id = f.customer_unique_id
    where o.order_status = 'delivered'
),
-- step 3: calculate how many months after cohort each order was placed
-- period 0 = the month they first purchased
-- period 1 = one month later, period 2 = two months later, etc.
cohort_periods as (
    select
        customer_unique_id,
        cohort_month,
        order_month,

        -- extract the year/month difference as an integer period number
        (extract(year from order_month) * 12 + extract(month from order_month))
        -
        (extract(year from cohort_month) * 12 + extract(month from cohort_month))
                                                            as cohort_period
    from customer_orders
),
-- step 4: count distinct customers per cohort per period
cohort_size as (
    select
        cohort_month,
        cohort_period,
        count(distinct customer_unique_id)                  as customers
    from cohort_periods
    group by cohort_month, cohort_period
)
-- step 5: final output with retention rate
select
    cohort_month,
    cohort_period,
    customers                                               as retained_customers,
    -- cohort size = how many customers in period 0 (their first month)
    first_value(customers) over (
        partition by cohort_month
        order by cohort_period
    )                                                       as cohort_size,
    -- retention rate = retained / cohort size
    round(
        customers * 100.0 /
        first_value(customers) over (
            partition by cohort_month
            order by cohort_period
        )
    , 2)                                                    as retention_rate_pct
from cohort_size
order by cohort_month, cohort_period;

-- retention matrix: first 6 months for cohorts in 2017
select
    to_char(cohort_month, 'YYYY-MM')                        as cohort,
    cohort_size,
    max(case when cohort_period = 0 then retention_rate_pct end) as month_0,
    max(case when cohort_period = 1 then retention_rate_pct end) as month_1,
    max(case when cohort_period = 2 then retention_rate_pct end) as month_2,
    max(case when cohort_period = 3 then retention_rate_pct end) as month_3,
    max(case when cohort_period = 4 then retention_rate_pct end) as month_4,
    max(case when cohort_period = 5 then retention_rate_pct end) as month_5
from gold.cohort_retention
where cohort_month >= '2017-01-01'
  and cohort_month < '2018-01-01'
group by cohort_month, cohort_size
order by cohort_month;