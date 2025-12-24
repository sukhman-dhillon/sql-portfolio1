-- Project 02: Marketing Funnel & Conversion Analysis
-- Dataset: bigquery-public-data.thelook_ecommerce

-- Q1: Revenue, orders, and AOV by traffic source

SELECT
  u.traffic_source,
  ROUND(SUM(oi.sale_price), 2) AS revenue,
  COUNT(DISTINCT oi.order_id) AS orders,
  ROUND(SUM(oi.sale_price) / COUNT(DISTINCT oi.order_id), 2) AS aov
FROM 
    `bigquery-public-data.thelook_ecommerce.order_items` oi
JOIN 
    `bigquery-public-data.thelook_ecommerce.users` u
  ON oi.user_id = u.id
WHERE 
    oi.status NOT IN ('Cancelled', 'Returned')
GROUP BY 
    u.traffic_source
ORDER BY 
    revenue DESC;

-- Q2: Monthly revenue trend by traffic source

SELECT
  DATE_TRUNC(DATE(oi.created_at), MONTH) AS month,
  u.traffic_source,
  ROUND(SUM(oi.sale_price), 2) AS revenue,
  COUNT(DISTINCT oi.order_id) AS orders,
  ROUND(SUM(oi.sale_price) / COUNT(DISTINCT oi.order_id), 2) AS aov
FROM 
    `bigquery-public-data.thelook_ecommerce.order_items` oi
JOIN 
    `bigquery-public-data.thelook_ecommerce.users` u
  ON oi.user_id = u.id
WHERE 
    oi.status NOT IN ('Cancelled', 'Returned')
GROUP BY month, 
  u.traffic_source
ORDER BY month, 
  revenue DESC;

-- Q3: New vs returning customers by traffic source
-- Definition:
-- - New customer = customer's first order month equals the month of the order

WITH first_order AS (
  SELECT
    oi.user_id,
    MIN(DATE(oi.created_at)) AS first_order_date
  FROM `bigquery-public-data.thelook_ecommerce.order_items` oi
  WHERE oi.status NOT IN ('Cancelled', 'Returned')
  GROUP BY oi.user_id
),
orders_enriched AS (
  SELECT
    DATE_TRUNC(DATE(oi.created_at), MONTH) AS month,
    oi.user_id,
    oi.order_id,
    u.traffic_source,
    DATE_TRUNC(fo.first_order_date, MONTH) AS first_order_month
  FROM `bigquery-public-data.thelook_ecommerce.order_items` oi
  JOIN `bigquery-public-data.thelook_ecommerce.users` u
    ON oi.user_id = u.id
  JOIN first_order fo
    ON oi.user_id = fo.user_id
  WHERE oi.status NOT IN ('Cancelled', 'Returned')
)
SELECT
  traffic_source,
  COUNT(DISTINCT user_id) AS customers,
  COUNT(DISTINCT order_id) AS orders,
  COUNT(DISTINCT CASE WHEN month = first_order_month THEN user_id END) AS new_customers,
  COUNT(DISTINCT CASE WHEN month != first_order_month THEN user_id END) AS returning_customers,
  ROUND(
    COUNT(DISTINCT CASE WHEN month != first_order_month THEN user_id END) /
    COUNT(DISTINCT user_id),
    4
  ) AS returning_customer_share
FROM 
  orders_enriched
GROUP BY 
  traffic_source
ORDER BY 
  customers DESC;

-- Q4: Customer value by traffic source (total revenue per customer)

WITH customer_revenue AS (
  SELECT
    oi.user_id,
    u.traffic_source,
    SUM(oi.sale_price) AS total_revenue
  FROM `
    bigquery-public-data.thelook_ecommerce.order_items` oi
  JOIN 
    `bigquery-public-data.thelook_ecommerce.users` u
    ON oi.user_id = u.id
  WHERE 
    oi.status NOT IN ('Cancelled', 'Returned')
  GROUP BY 
    oi.user_id, u.traffic_source
)

SELECT
  traffic_source,
  COUNT(*) AS customers,
  ROUND(AVG(total_revenue), 2) AS avg_revenue_per_customer
FROM 
  customer_revenue
GROUP BY 
  traffic_source
ORDER BY 
  avg_revenue_per_customer DESC;

-- Q5: High-value order rate by traffic source

WITH order_totals AS (
  SELECT
    oi.order_id,
    oi.user_id,
    SUM(oi.sale_price) AS order_revenue
  FROM 
    `bigquery-public-data.thelook_ecommerce.order_items` oi
  WHERE 
    oi.status NOT IN ('Cancelled', 'Returned')
  GROUP BY 
    oi.order_id, oi.user_id
)
SELECT
  u.traffic_source,
  COUNT(*) AS orders,
  COUNTIF(order_revenue >= 150) AS high_value_orders,
  ROUND(COUNTIF(order_revenue >= 150) / COUNT(*), 4) AS high_value_order_rate,
  ROUND(AVG(order_revenue), 2) AS avg_order_value
FROM 
  order_totals ot
JOIN `
  bigquery-public-data.thelook_ecommerce.users` u
  ON ot.user_id = u.id
GROUP BY 
  u.traffic_source
ORDER BY 
  high_value_order_rate DESC;

-- Q6: Paid vs Organic channel grouping (simple bucketing)

WITH base AS (
  SELECT
    u.traffic_source,
    CASE
      WHEN LOWER(u.traffic_source) IN ('adwords', 'facebook', 'display', 'paid', 'paid_search') THEN 'Paid'
      ELSE 'Organic/Other'
    END AS channel_group,
    oi.order_id,
    oi.user_id,
    oi.sale_price
  FROM 
    `bigquery-public-data.thelook_ecommerce.order_items` oi
  JOIN 
    `bigquery-public-data.thelook_ecommerce.users` u
    ON oi.user_id = u.id
  WHERE 
    oi.status NOT IN ('Cancelled', 'Returned')
)
SELECT
  channel_group,
  ROUND(SUM(sale_price), 2) AS revenue,
  COUNT(DISTINCT order_id) AS orders,
  ROUND(SUM(sale_price) / COUNT(DISTINCT order_id), 2) AS aov,
  COUNT(DISTINCT user_id) AS customers
FROM 
  base
GROUP BY 
    channel_group
ORDER BY 
    revenue DESC;

-- Q7: Best day of week for revenue and orders (marketing scheduling insight)

SELECT
  EXTRACT(DAYOFWEEK FROM DATE(oi.created_at)) AS day_of_week_num,
  ROUND(SUM(oi.sale_price), 2) AS revenue,
  COUNT(DISTINCT oi.order_id) AS orders,
  ROUND(SUM(oi.sale_price) / COUNT(DISTINCT oi.order_id), 2) AS aov
FROM 
  `bigquery-public-data.thelook_ecommerce.order_items` oi
WHERE 
  oi.status NOT IN ('Cancelled', 'Returned')
GROUP BY 
  day_of_week_num
ORDER BY 
  revenue DESC;

