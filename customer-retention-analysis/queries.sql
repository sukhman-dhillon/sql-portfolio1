-- Project 03: Customer Retention and Purchase Behavior
-- Dataset: bigquery-public-data.thelook_ecommerce

-- Q1: One-time vs repeat customers (based on valid orders)

WITH valid_orders AS (
  SELECT
    oi.user_id,
    oi.order_id
  FROM 
    `bigquery-public-data.thelook_ecommerce.order_items` oi
  WHERE 
    oi.status NOT IN ('Cancelled', 'Returned')
  GROUP BY 
    oi.user_id, oi.order_id
),
orders_per_customer AS (
  SELECT
    user_id,
    COUNT(DISTINCT order_id) AS orders_count
  FROM 
    valid_orders
  GROUP BY
    user_id
)
SELECT
  CASE
    WHEN orders_count = 1 THEN 'One-time'
    WHEN orders_count >= 2 THEN 'Repeat'
  END AS customer_type,
  COUNT(*) AS customers,
  ROUND(COUNT(*) / SUM(COUNT(*)) OVER(), 4) AS customer_share
FROM 
    orders_per_customer
GROUP BY 
    customer_type
ORDER BY  
  customers DESC;

-- Q2: Revenue share from repeat customers

WITH valid_items AS (
  SELECT
    oi.user_id,
    oi.order_id,
    oi.sale_price
  FROM 
    `bigquery-public-data.thelook_ecommerce.order_items` oi
  WHERE 
    oi.status NOT IN ('Cancelled', 'Returned')
),
orders_per_customer AS (
  SELECT
    user_id,
    COUNT(DISTINCT order_id) AS orders_count
  FROM 
    valid_items
  GROUP BY 
    user_id
),
customer_revenue AS (
  SELECT
    vi.user_id,
    SUM(vi.sale_price) AS revenue
  FROM 
    valid_items vi
  GROUP BY 
    vi.user_id
)
SELECT
  CASE
    WHEN opc.orders_count = 1 THEN 'One-time'
    ELSE 'Repeat'
  END AS customer_type,
  ROUND(SUM(cr.revenue), 2) AS revenue,
  ROUND(SUM(cr.revenue) / SUM(SUM(cr.revenue)) OVER(), 4) AS revenue_share
FROM 
  customer_revenue cr
JOIN 
  orders_per_customer opc
  ON cr.user_id = opc.user_id
GROUP BY 
  customer_type
ORDER BY 
  revenue DESC;

-- Q3: Time to second order (days) for repeat customers

WITH valid_orders AS (
  SELECT
    oi.user_id,
    oi.order_id,
    MIN(DATE(oi.created_at)) AS order_date
  FROM 
    `bigquery-public-data.thelook_ecommerce.order_items` oi
  WHERE 
    oi.status NOT IN ('Cancelled', 'Returned')
  GROUP BY 
    oi.user_id, oi.order_id
),
ranked_orders AS (
  SELECT
    user_id,
    order_id,
    order_date,
    ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY order_date, order_id) AS order_rank
  FROM 
    valid_orders
),
first_second AS (
  SELECT
    user_id,
    MAX(CASE WHEN order_rank = 1 THEN order_date END) AS first_order_date,
    MAX(CASE WHEN order_rank = 2 THEN order_date END) AS second_order_date
  FROM 
    ranked_orders
  GROUP BY 
    user_id
)
SELECT
  COUNT(*) AS repeat_customers,
  ROUND(AVG(DATE_DIFF(second_order_date, first_order_date, DAY)), 2) AS avg_days_to_second_order,
  APPROX_QUANTILES(DATE_DIFF(second_order_date, first_order_date, DAY), 100)[OFFSET(50)] AS median_days_to_second_order
FROM 
  first_second
WHERE 
  second_order_date IS NOT NULL;

-- Q4: AOV for first order vs repeat orders (order-level)

WITH valid_orders AS (
  SELECT
    oi.user_id,
    oi.order_id,
    MIN(DATE(oi.created_at)) AS order_date,
    SUM(oi.sale_price) AS order_revenue
  FROM
     `bigquery-public-data.thelook_ecommerce.order_items` oi
  WHERE
     oi.status NOT IN ('Cancelled', 'Returned')
  GROUP BY
     oi.user_id, oi.order_id
),
ranked AS (
  SELECT
    user_id,
    order_id,
    order_date,
    order_revenue,
    ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY order_date, order_id) AS order_rank
  FROM 
    valid_orders
)
SELECT
  CASE
    WHEN order_rank = 1 THEN 'First order'
    ELSE 'Repeat orders'
  END AS order_type,
  COUNT(*) AS orders,
  ROUND(AVG(order_revenue), 2) AS avg_order_value
FROM 
  ranked
GROUP BY 
  order_type
ORDER BY 
  orders DESC;

-- Q5: Top customers by lifetime revenue (simple LTV)

WITH customer_ltv AS (
  SELECT
    oi.user_id,
    ROUND(SUM(oi.sale_price), 2) AS lifetime_revenue,
    COUNT(DISTINCT oi.order_id) AS orders
  FROM 
    `bigquery-public-data.thelook_ecommerce.order_items` oi
  WHERE 
    oi.status NOT IN ('Cancelled', 'Returned')
  GROUP BY 
    oi.user_id
)
SELECT
  user_id,
  lifetime_revenue,
  orders,
  ROUND(lifetime_revenue / orders, 2) AS revenue_per_order
FROM 
  customer_ltv
ORDER BY 
  lifetime_revenue DESC
LIMIT 20;

-- Q6: Purchase frequency distribution (orders per customer)

WITH valid_orders AS (
  SELECT
    oi.user_id,
    oi.order_id
  FROM 
    `bigquery-public-data.thelook_ecommerce.order_items` oi
  WHERE 
    oi.status NOT IN ('Cancelled', 'Returned')
  GROUP BY 
    oi.user_id, oi.order_id
),
orders_per_customer AS (
  SELECT
    user_id,
    COUNT(DISTINCT order_id) AS orders_count
  FROM 
    valid_orders
  GROUP BY 
    user_id
)
SELECT
  orders_count,
  COUNT(*) AS customers,
  ROUND(COUNT(*) / SUM(COUNT(*)) OVER(), 4) AS customer_share
FROM 
  orders_per_customer
GROUP BY 
  orders_count
ORDER BY 
  orders_count;




