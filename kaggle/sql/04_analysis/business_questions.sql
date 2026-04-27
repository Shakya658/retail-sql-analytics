-- =============================================
-- business questions analysis
-- answers all 8 core business questions
-- using the gold layer tables
-- =============================================


-- -----------------------------------------------
-- question 1: which months and states generate
-- the most revenue and how is the business trending?
-- -----------------------------------------------

select
    to_char(order_month, 'YYYY-MM')                         as month,
    customer_state,
    total_orders,
    total_revenue,
    avg_order_value,
    -- month over month revenue change
    -- lag() looks at the previous row's value
    -- we partition by state so we compare each state to its own prior month
    round(
        total_revenue - lag(total_revenue) over (
            partition by customer_state
            order by order_month
        )
    , 2)                                                    as revenue_vs_prior_month,
    -- percentage change vs prior month
    round(
        (total_revenue - lag(total_revenue) over (
            partition by customer_state
            order by order_month
        )) * 100.0 / nullif(lag(total_revenue) over (
            partition by customer_state
            order by order_month
        ), 0)
    , 2)                                                    as pct_change_vs_prior_month
from gold.sales_summary_monthly
order by order_month, total_revenue desc;


-- -----------------------------------------------
-- question 2: which products and categories
-- drive the most revenue?
-- -----------------------------------------------

select
    product_category,
    count(product_id)                                       as total_skus,
    sum(total_orders)                                       as total_orders,
    sum(total_units_sold)                                   as total_units_sold,
    round(sum(total_revenue), 2)                            as total_revenue,
    round(avg(avg_price), 2)                                as avg_price,
    round(avg(avg_review_score), 2)                         as avg_review_score,
    -- revenue rank across all categories
    rank() over (
        order by sum(total_revenue) desc
    )                                                       as revenue_rank
from gold.product_performance
where total_orders > 0
group by product_category
order by total_revenue desc
limit 20;


-- -----------------------------------------------
-- question 3: who are our high value customers?
-- what does each segment look like?
-- -----------------------------------------------

select
    customer_segment,
    count(customer_unique_id)                               as customer_count,
    round(avg(monetary_value), 2)                           as avg_spend,
    round(avg(recency_days), 0)                             as avg_recency_days,
    round(avg(frequency), 2)                                as avg_orders,
    round(sum(monetary_value), 2)                           as total_segment_revenue,
    -- what percentage of total customers is this segment?
    round(
        count(customer_unique_id) * 100.0 /
        sum(count(customer_unique_id)) over ()
    , 2)                                                    as pct_of_customers,

    -- what percentage of total revenue does this segment generate?
    round(
        sum(monetary_value) * 100.0 /
        sum(sum(monetary_value)) over ()
    , 2)                                                    as pct_of_revenue
from gold.customer_rfm
group by customer_segment
order by avg_spend desc;


-- -----------------------------------------------
-- question 4: which states show declining revenue
-- and need attention?
-- -----------------------------------------------

with monthly_state_revenue as (
    select
        customer_state,
        order_month,
        total_revenue,
        -- compare each month to the same state 3 months prior
        lag(total_revenue, 3) over (
            partition by customer_state
            order by order_month
        )                                                   as revenue_3_months_ago
    from gold.sales_summary_monthly
),
state_trend as (
    select
        customer_state,

        -- average revenue in the last 3 months of data
        round(avg(case
            when order_month >= (select max(order_month) - interval '3 months'
                                 from gold.sales_summary_monthly)
            then total_revenue end), 2)                     as recent_avg_revenue,
        -- average revenue in the 3 months before that
        round(avg(case
            when order_month >= (select max(order_month) - interval '6 months'
                                 from gold.sales_summary_monthly)
             and order_month <  (select max(order_month) - interval '3 months'
                                 from gold.sales_summary_monthly)
            then total_revenue end), 2)                     as prior_avg_revenue
    from gold.sales_summary_monthly
    group by customer_state
)
select
    customer_state,
    recent_avg_revenue,
    prior_avg_revenue,
    round(recent_avg_revenue - prior_avg_revenue, 2)        as revenue_change,
    round(
        (recent_avg_revenue - prior_avg_revenue) * 100.0 /
        nullif(prior_avg_revenue, 0)
    , 2)                                                    as pct_change,
    case
        when recent_avg_revenue < prior_avg_revenue then 'declining'
        when recent_avg_revenue > prior_avg_revenue then 'growing'
        else 'stable'
    end                                                     as trend
from state_trend
order by pct_change asc;


-- -----------------------------------------------
-- question 5: what is the average basket size
-- and how does it vary by state?
-- -----------------------------------------------

select
    s.customer_state,
    count(distinct s.order_month)                           as months_active,
    round(avg(s.total_orders), 0)                           as avg_monthly_orders,
    round(avg(s.avg_order_value), 2)                        as avg_order_value,
    round(avg(s.avg_items_per_order), 2)                    as avg_items_per_order,
    round(sum(s.total_revenue), 2)                          as total_revenue
from gold.sales_summary_monthly s
group by s.customer_state
order by total_revenue desc;


-- -----------------------------------------------
-- question 6: how well do we retain customers
-- after their first purchase?
-- show the first 6 months for each cohort
-- -----------------------------------------------

select
    to_char(cohort_month, 'YYYY-MM')                        as cohort,
    cohort_size,
    max(case when cohort_period = 0 then retention_rate_pct end) as month_0_pct,
    max(case when cohort_period = 1 then retention_rate_pct end) as month_1_pct,
    max(case when cohort_period = 2 then retention_rate_pct end) as month_2_pct,
    max(case when cohort_period = 3 then retention_rate_pct end) as month_3_pct,
    max(case when cohort_period = 4 then retention_rate_pct end) as month_4_pct,
    max(case when cohort_period = 5 then retention_rate_pct end) as month_5_pct
from gold.cohort_retention
where cohort_month >= '2017-01-01'
  and cohort_month < '2018-07-01'
group by cohort_month, cohort_size
order by cohort_month;


-- -----------------------------------------------
-- question 7: where are the delays in our
-- fulfilment process and which states are worst?
-- -----------------------------------------------

select
    customer_state,
    avg_days_to_approval,
    avg_days_to_carrier,
    avg_days_to_delivery,
    avg_total_fulfilment_days,
    median_fulfilment_days,
    on_time_delivery_pct,
    rank() over (order by on_time_delivery_pct asc)         as worst_on_time_rank,
    case
        when on_time_delivery_pct < (
            select avg(on_time_delivery_pct) from gold.fulfilment_metrics
        ) then 'below average'
        else 'at or above average'
    end                                                     as performance_flag
from gold.fulfilment_metrics
order by on_time_delivery_pct asc;


-- -----------------------------------------------
-- question 8: which products have the best
-- combination of high revenue and high satisfaction?
-- and which have high revenue but poor reviews?
-- -----------------------------------------------

select
    product_category,
    round(sum(total_revenue), 2)                            as total_revenue,
    round(avg(avg_review_score), 2)                         as avg_review_score,
    sum(total_orders)                                       as total_orders,
    -- classify each category into a performance quadrant
    case
        when avg(avg_review_score) >= 4.0
         and sum(total_revenue) >= (
             select percentile_cont(0.5) within group (
                 order by cat_revenue
             )
             from (
                 select sum(total_revenue) as cat_revenue
                 from gold.product_performance
                 group by product_category
             ) sub
         ) then 'star — high revenue, high satisfaction'
        when avg(avg_review_score) < 4.0
         and sum(total_revenue) >= (
             select percentile_cont(0.5) within group (
                 order by cat_revenue
             )
             from (
                 select sum(total_revenue) as cat_revenue
                 from gold.product_performance
                 group by product_category
             ) sub
         ) then 'problem — high revenue, low satisfaction'
        when avg(avg_review_score) >= 4.0
         and sum(total_revenue) < (
             select percentile_cont(0.5) within group (
                 order by cat_revenue
             )
             from (
                 select sum(total_revenue) as cat_revenue
                 from gold.product_performance
                 group by product_category
             ) sub
         ) then 'potential — low revenue, high satisfaction'

        else 'underperformer — low revenue, low satisfaction'
    end                                                     as performance_quadrant
from gold.product_performance
where total_orders > 0
group by product_category
order by total_revenue desc;