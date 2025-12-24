-- Project 01: Ecommerce Sales Performance
-- Dataset: bigquery-public-data.thelook_ecommerce

-- Q1: Monthly Revenue Trend

SELECT
  DATE_TRUNC(DATE(oi.created_at), MONTH) AS MONTH,
  ROUND(SUM(oi.sale_price), 2) AS REVENUE,
  COUNT(DISTINCT oi.order_id) AS ORDERS
FROM 
  `bigquery-public-data.thelook_ecommerce.order_items` oi
WHERE 
  oi.status NOT IN ('Cancelled', 'Returned')
GROUP BY 
  MONTH
ORDER BY 
  MONTH;

-- Q2: Average Order Value (AOV) by Month
WITH monthly AS (
  SELECT
    DATE_TRUNC(DATE(oi.created_at), MONTH) AS MONTH,
    oi.order_id,
    SUM(oi.sale_price) AS order_revenue
  FROM 
    `bigquery-public-data.thelook_ecommerce.order_items` oi
  WHERE 
    oi.status NOT IN ('Cancelled', 'Returned')
  GROUP BY 
    MONTH, oi.order_id
)
SELECT
  MONTH,
  ROUND(AVG(order_revenue), 2) AS AVERAGE_ORDER_VALUE,
  COUNT(DISTINCT order_id) AS ORDERS
FROM 
  monthly
GROUP BY 
  MONTH
ORDER BY 
  MONTH;

-- Q3: Top 10 Products by Revenue
SELECT
  p.name AS Product_Name,
  p.category AS Category,
  ROUND(SUM(oi.sale_price), 2) AS Revenue,
  COUNT(*) AS Items_Sold
FROM 
  `bigquery-public-data.thelook_ecommerce.order_items` oi
JOIN 
  `bigquery-public-data.thelook_ecommerce.products` p
  ON oi.product_id = p.id
WHERE 
  oi.status NOT IN ('Cancelled', 'Returned')
GROUP BY 
  product_name, category
ORDER BY 
  revenue DESC
LIMIT 10;

-- Q4: Revenue by category with simple profit estimate

SELECT
  p.category,
  ROUND(SUM(oi.sale_price), 2) AS Revenue,
  ROUND(SUM(p.retail_price - p.cost), 2) AS EST_Unit_Profit_Sum,
  COUNT(*) AS Items_Sold
FROM 
  `bigquery-public-data.thelook_ecommerce.order_items` oi
JOIN 
  `bigquery-public-data.thelook_ecommerce.products` p
  ON oi.product_id = p.id
WHERE 
  oi.status NOT IN ('Cancelled', 'Returned')
GROUP BY 
  p.category
ORDER BY 
  revenue DESC;

-- Q5: Revenue by traffic source 

SELECT
  u.traffic_source,
  ROUND(SUM(oi.sale_price), 2) AS Revenue,
  COUNT(DISTINCT oi.order_id) AS Orders,
  ROUND(SUM(oi.sale_price) / COUNT(DISTINCT oi.order_id), 2) AS AOV
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


-- Q6: Repeat Customer Rate (Simple)

WITH customer_orders AS (
  SELECT
    oi.user_id,
    COUNT(DISTINCT oi.order_id) AS Order_Count
  FROM 
    `bigquery-public-data.thelook_ecommerce.order_items` oi
  WHERE 
    oi.status NOT IN ('Cancelled', 'Returned')
  GROUP BY 
    oi.user_id
)
SELECT
  COUNT(*) AS Total_Customers,
  SUM(CASE WHEN order_count >= 2 THEN 1 ELSE 0 END) AS Repeat_Customers,
  ROUND(SUM(CASE WHEN order_count >= 2 THEN 1 ELSE 0 END) / COUNT(*), 4) AS Repeat_Customer_Rate
FROM 
  customer_orders;

-- Q7: High Value Order Segmentation

WITH order_totals AS (
  SELECT
    oi.order_id,
    SUM(oi.sale_price) AS Order_Revenue
  FROM `bigquery-public-data.thelook_ecommerce.order_items` oi
  WHERE oi.status NOT IN ('Cancelled', 'Returned')
  GROUP BY oi.order_id
)

SELECT
  CASE
    WHEN order_revenue >= 150 THEN 'High value (150+)'
    WHEN order_revenue >= 75  THEN 'Mid value (75-149)'
    ELSE 'Low value (<75)'
  END AS order_segment,
  COUNT(*) AS Orders,
  ROUND(AVG(order_revenue), 2) AS AVG_Order_Value
FROM order_totals
GROUP BY order_segment
ORDER BY
  CASE
    WHEN order_segment = 'High value (150+)' THEN 1
    WHEN order_segment = 'Mid value (75-149)' THEN 2
    ELSE 3
  END;
