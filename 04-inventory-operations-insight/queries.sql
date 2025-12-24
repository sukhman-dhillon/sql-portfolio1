-- Project 04: Inventory and Operations Insights
-- Dataset: bigquery-public-data.thelook_ecommerce

-- Q1: Weekly units sold by product (velocity baseline)

SELECT
  p.name AS product_name,
  p.category,
  DATE_TRUNC(DATE(oi.created_at), WEEK) AS week,
  COUNT(*) AS units_sold
FROM 
  `bigquery-public-data.thelook_ecommerce.order_items` oi
JOIN 
  `bigquery-public-data.thelook_ecommerce.products` p
  ON oi.product_id = p.id
WHERE 
  oi.status NOT IN ('Cancelled', 'Returned')
GROUP BY 
  product_name, category, week
ORDER BY 
  units_sold DESC;

-- Q2: Return rate by product category

SELECT
  p.category,
  COUNT(*) AS total_items,
  COUNTIF(oi.status = 'Returned') AS returned_items,
  ROUND(COUNTIF(oi.status = 'Returned') / COUNT(*), 4) AS return_rate
FROM 
  `bigquery-public-data.thelook_ecommerce.order_items` oi
JOIN 
  `bigquery-public-data.thelook_ecommerce.products` p
  ON oi.product_id = p.id
GROUP BY 
  p.category
ORDER BY 
  return_rate DESC;

-- Q3: Average weekly demand per product

WITH weekly_sales AS (
  SELECT
    p.id AS product_id,
    p.name AS product_name,
    DATE_TRUNC(DATE(oi.created_at), WEEK) AS week,
    COUNT(*) AS units_sold
  FROM 
    `bigquery-public-data.thelook_ecommerce.order_items` oi
  JOIN 
    `bigquery-public-data.thelook_ecommerce.products` p
    ON oi.product_id = p.id
  WHERE 
    oi.status NOT IN ('Cancelled', 'Returned')
  GROUP BY 
    product_id, product_name, week
)
SELECT
  product_name,
  ROUND(AVG(units_sold), 2) AS avg_weekly_units
FROM 
  weekly_sales
GROUP BY 
  product_name
ORDER BY 
  avg_weekly_units DESC;

-- Q4: Demand variability by product (sales volatility)

WITH weekly_sales AS (
  SELECT
    p.id AS product_id,
    p.name AS product_name,
    DATE_TRUNC(DATE(oi.created_at), WEEK) AS week,
    COUNT(*) AS units_sold
  FROM 
    `bigquery-public-data.thelook_ecommerce.order_items` oi
  JOIN 
    `bigquery-public-data.thelook_ecommerce.products` p
    ON oi.product_id = p.id
  WHERE 
    oi.status NOT IN ('Cancelled', 'Returned')
  GROUP BY 
    product_id, product_name, week
)
SELECT
  product_name,
  ROUND(AVG(units_sold), 2) AS avg_units,
  ROUND(STDDEV(units_sold), 2) AS demand_stddev
FROM 
  weekly_sales
GROUP BY 
  product_name
ORDER BY 
  demand_stddev DESC;


-- Q5: Fast / Medium / Slow moving product classification

WITH weekly_sales AS (
  SELECT
    p.name AS product_name,
    DATE_TRUNC(DATE(oi.created_at), WEEK) AS week,
    COUNT(*) AS units_sold
  FROM 
    `bigquery-public-data.thelook_ecommerce.order_items` oi
  JOIN 
    `bigquery-public-data.thelook_ecommerce.products` p
    ON oi.product_id = p.id
  WHERE 
    oi.status NOT IN ('Cancelled', 'Returned')
  GROUP BY 
    product_name, week
),
avg_sales AS (
  SELECT
    product_name,
    AVG(units_sold) AS avg_weekly_units
  FROM 
    weekly_sales
  GROUP BY 
    product_name
)
SELECT
  product_name,
  ROUND(avg_weekly_units, 2) AS avg_weekly_units,
  CASE
    WHEN avg_weekly_units >= 5 THEN 'Fast mover'
    WHEN avg_weekly_units >= 2 THEN 'Medium mover'
    ELSE 'Slow mover'
  END AS velocity_class
FROM 
    avg_sales
ORDER BY 
    avg_weekly_units DESC;

-- Q6: High revenue but low unit volume products (inventory risk)

SELECT
  p.name AS product_name,
  p.category,
  COUNT(*) AS units_sold,
  ROUND(SUM(oi.sale_price), 2) AS total_revenue,
  ROUND(SUM(oi.sale_price) / COUNT(*), 2) AS revenue_per_unit
FROM 
    `bigquery-public-data.thelook_ecommerce.order_items` oi
JOIN 
    `bigquery-public-data.thelook_ecommerce.products` p
  ON oi.product_id = p.id
WHERE 
    oi.status NOT IN ('Cancelled', 'Returned')
GROUP BY 
    product_name, category
HAVING COUNT(*) < 10
ORDER BY 
  total_revenue DESC;
