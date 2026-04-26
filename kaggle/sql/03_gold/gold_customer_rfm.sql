-- =============================================
-- gold.customer_rfm
-- recency, frequency, monetary segmentation
-- answers: who are our best and worst customers?
-- =============================================
create table gold.customer_rfm as
-- step 1: calculate raw rfm metrics per customer
with customer_metrics as (
    select
        c.customer_unique_id,
        c.customer_state,
        -- recency: days since their last order
        -- we use the max purchase date in the dataset as "today"
        extract(day from (
            (select max(order_purchase_timestamp) from silver.orders)
            - max(o.order_purchase_timestamp)
        ))                                                  as recency_days,
        -- frequency: how many orders they placed
        count(distinct o.order_id)                          as frequency,
        -- monetary: total amount they spent
        round(sum(i.price), 2)                              as monetary_value
    from silver.customers c
    inner join silver.orders o
        on c.customer_id = o.customer_id
    inner join silver.order_items i
        on o.order_id = i.order_id
    where o.order_status = 'delivered'
    group by
        c.customer_unique_id,
        c.customer_state
),
-- step 2: score each customer 1-4 on each rfm dimension
-- ntile(4) splits all customers into 4 equal buckets
rfm_scores as (
    select
        customer_unique_id,
        customer_state,
        recency_days,
        frequency,
        monetary_value,
        -- recency: lower days = better = higher score
        -- so we reverse the order (order by recency_days asc = best gets 4)
        ntile(4) over (order by recency_days desc)          as r_score,
        -- frequency: higher = better = higher score
        ntile(4) over (order by frequency asc)              as f_score,
        -- monetary: higher = better = higher score
        ntile(4) over (order by monetary_value asc)         as m_score
    from customer_metrics
),
-- step 3: combine scores and assign segment labels
rfm_segments as (
    select
        customer_unique_id,
        customer_state,
        recency_days,
        frequency,
        monetary_value,
        r_score,
        f_score,
        m_score,

        -- combined rfm score out of 12
        (r_score + f_score + m_score)                       as rfm_total_score
    from rfm_scores
)
-- step 4: assign human-readable segment labels
select
    customer_unique_id,
    customer_state,
    recency_days,
    frequency,
    monetary_value,
    r_score,
    f_score,
    m_score,
    rfm_total_score,
    case
        when r_score = 4 and f_score >= 3 and m_score >= 3  then 'champion'
        when r_score >= 3 and f_score >= 3                  then 'loyal'
        when r_score >= 3 and f_score <= 2                  then 'potential loyalist'
        when r_score = 2 and f_score >= 2                   then 'at risk'
        when r_score <= 2 and f_score <= 2 and m_score >= 3 then 'cannot lose them'
        when r_score = 1 and f_score = 1                    then 'lost'
        else                                                     'needs attention'
    end                                                     as customer_segment
from rfm_segments
order by rfm_total_score desc;

-- segment distribution
select
    customer_segment,
    count(*)                                                as customer_count,
    round(avg(monetary_value), 2)                           as avg_spend,
    round(avg(recency_days), 0)                             as avg_recency_days,
    round(avg(frequency), 2)                                as avg_frequency
from gold.customer_rfm
group by customer_segment
order by avg_spend desc;