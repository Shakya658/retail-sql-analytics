-- =============================================
-- gold.product_performance
-- revenue, order volume, and review scores
-- per product and category
-- answers: which products and categories perform best?
-- =============================================
create table gold.product_performance as
-- step 1: calculate revenue and order metrics per product
with product_sales as (
    select
        i.product_id,
        count(distinct i.order_id)                          as total_orders,
        count(i.order_item_id)                              as total_units_sold,
        round(sum(i.price), 2)                              as total_revenue,
        round(avg(i.price), 2)                              as avg_price

    from silver.order_items i
    inner join silver.orders o
        on i.order_id = o.order_id

    where o.order_status = 'delivered'

    group by i.product_id
),
-- step 2: calculate average review score per product
product_reviews as (
    select
        i.product_id,
        round(avg(r.review_score), 2)                       as avg_review_score,
        count(r.review_id)                                  as total_reviews

    from silver.order_items i
    inner join silver.orders o
        on i.order_id = o.order_id
    inner join silver.reviews r
        on o.order_id = r.order_id

    where o.order_status = 'delivered'

    group by i.product_id
)
-- step 3: join both ctes with product details
select
    p.product_id,
    p.product_category,
    coalesce(s.total_orders, 0)                             as total_orders,
    coalesce(s.total_units_sold, 0)                         as total_units_sold,
    coalesce(s.total_revenue, 0)                            as total_revenue,
    coalesce(s.avg_price, 0)                                as avg_price,
    rv.avg_review_score,
    coalesce(rv.total_reviews, 0)                           as total_reviews,
    -- revenue per review as engagement proxy
    -- nullif(x, 0) prevents division by zero
    round(
        coalesce(s.total_revenue, 0) /
        nullif(coalesce(rv.total_reviews, 0), 0)
    , 2)                                                    as revenue_per_review
from silver.products p
left join product_sales s
    on p.product_id = s.product_id
left join product_reviews rv
    on p.product_id = rv.product_id;
    
-- top 10 categories by revenue
select
    product_category,
    count(product_id)                                       as total_products,
    sum(total_orders)                                       as total_orders,
    round(sum(total_revenue), 2)                            as total_revenue,
    round(avg(avg_review_score), 2)                         as avg_review_score
from gold.product_performance
group by product_category
order by total_revenue desc
limit 10;