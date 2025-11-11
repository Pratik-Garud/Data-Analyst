-- Question 1: Second-Best Selling Product by Category

WITH my_cte AS (
	SELECT c.category_name,p.product_name,SUM(od.unit_price * od.quantity * (1 - COALESCE(od.discount,0))) AS total_revenue FROM categories c
JOIN products p
ON c.category_id = p.category_id
JOIN order_details od
ON p.product_id = od.product_id
GROUP BY c.category_name,p.product_name
),

ranked AS (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY category_name ORDER BY total_revenue DESC) AS rn
  FROM my_cte
)

SELECT
  category_name,
  product_name,
  total_revenue
FROM ranked
WHERE rn = 2
ORDER BY category_name;



-- Question 2: Top 3 Customers by Total Sales

WITH my_cte AS (
SELECT o.customer_id,
	cs.contact_name as customer_name,
SUM(od.unit_price * od.quantity * (1 - COALESCE(od.discount,0))) AS total_spent
FROM order_details od
JOIN orders o
ON od.order_id = o.order_id
JOIN customers cs
ON cs.customer_id = o.customer_id
GROUP BY o.customer_id,cs.contact_name
),

ranked AS (
SELECT * ,
DENSE_RANK() over (order by total_spent DESC) as rn
from my_cte
)

SELECT customer_name,total_spent,rn from ranked
where rn<=3



--Question 3: Top category by Product Variety

WITH category_product_count AS (
  SELECT
    c.category_id,
    c.category_name,
    COUNT(p.product_id) AS product_count
  FROM categories c
  JOIN products p ON p.category_id = c.category_id
  GROUP BY c.category_id, c.category_name
)
SELECT
  category_name,
  product_count,
  DENSE_RANK() OVER (ORDER BY product_count DESC) AS category_rank
FROM category_product_count
ORDER BY product_count DESC;



--Question 4: Most Recent Order per Customer

SELECT distinct c.contact_name,max(o.order_date) AS most_recent_order_date from orders o
JOIN customers c
ON c.customer_id = o.customer_id
group by c.contact_name
ORDER BY most_recent_order_date


--or 


WITH customer_orders AS (
  SELECT
    c.customer_id,
    c.contact_name AS customer_name,
    o.order_id,
    o.order_date,
    ROW_NUMBER() OVER (PARTITION BY c.customer_id ORDER BY o.order_date DESC, o.order_id DESC) AS rn
  FROM customers c
  LEFT JOIN orders o ON c.customer_id = o.customer_id
)
SELECT
  customer_name,
  order_date AS most_recent_order_date
FROM customer_orders
WHERE rn = 1
ORDER BY most_recent_order_date;


--Question 5: Cumulative Sales by Month

WITH monthly_sales AS (
  SELECT
    date_trunc('month', o.order_date) AS month_start,
    SUM(od.unit_price * od.quantity * (1 - COALESCE(od.discount,0))) AS month_sales
  FROM orders o
  JOIN order_details od ON o.order_id = od.order_id
  WHERE o.order_date >= '2014-01-01'::date
    AND o.order_date <  '2015-01-01'::date
  GROUP BY date_trunc('month', o.order_date)
)
SELECT
  to_char(month_start, 'YYYY-MM') AS month,
  month_sales,
  SUM(month_sales) OVER (ORDER BY month_start
                         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_ytd
FROM monthly_sales
ORDER BY month_start;



--Question 6: Days Between Customer Orders

WITH ordered AS (
  SELECT
    o.order_id,
    o.customer_id,
    c.contact_name AS customer_name,
    o.order_date::date AS order_date,
    LAG(o.order_date::date) OVER (PARTITION BY o.customer_id ORDER BY o.order_date, o.order_id) AS prev_order_date
  FROM orders o
  JOIN customers c ON o.customer_id = c.customer_id
)
SELECT
  customer_name,
  order_date,
  (order_date - prev_order_date) AS days_since_prev_order
FROM ordered
WHERE prev_order_date IS NOT NULL
ORDER BY customer_name, order_date;







--Question 7: Next Order Date and Reorder Interval

WITH ordered_forward AS (
  SELECT
    o.order_id,
    o.customer_id,
    c.contact_name AS customer_name,
    o.order_date::date AS order_date,
    LEAD(o.order_date::date) OVER (PARTITION BY o.customer_id ORDER BY o.order_date, o.order_id) AS next_order_date
  FROM orders o
  JOIN customers c ON o.customer_id = c.customer_id
)
SELECT
  customer_name,
  order_date AS current_order_date,
  next_order_date,
  (next_order_date - order_date) AS days_until_next_order
FROM ordered_forward
WHERE next_order_date IS NOT NULL
ORDER BY customer_name, order_date;




--Question 8: Highest-Value Order and Its Salesperson


WITH order_totals AS (
  SELECT
    o.order_id,
    o.employee_id,
    SUM(od.unit_price * od.quantity * (1 - COALESCE(od.discount,0))) AS order_total
  FROM orders o
  JOIN order_details od ON o.order_id = od.order_id
  GROUP BY o.order_id, o.employee_id
),
max_order AS (
  SELECT order_id, employee_id, order_total
  FROM order_totals
  ORDER BY order_total DESC
  LIMIT 1
)
SELECT
  mo.order_id,
  mo.order_total,
  e.employee_name
FROM max_order mo
LEFT JOIN employees e ON mo.employee_id = e.employee_id;
