create schema amazon_brazil;

create table amazon_brazil.customers(
customer_id varchar(20),
customer_unique_id varchar(20),
customer_zip_code_prefix numeric
);

create table amazon_brazil.orders(
order_id varchar,
customer_id varchar,
corder_status varchar,
order_purchas_timestamp timestamp,
order_approved_at timestamp,
order_delivered_carrier_date timestamp,
order_delivered_customer_date timestamp,
order_estimated_delivery_date timestamp
);

create table amazon_brazil.payments(
order_id varchar,
payment_sequential numeric,
payment_type varchar,
payment_installments numeric,
payment_value numeric
);

create table amazon_brazil.seller(
seller_id varchar primary key,
seller_zip_code_prefix numeric
);

create table amazon_brazil.order_items(
order_id varchar,
order_item_id numeric,
product_id varchar,
seller_id varchar,
shipping_limit_date timestamp,
price numeric,
preight_value numeric
);

create table amazon_brazil.product(
product_id varchar primary key,
product_category_name varchar,
product_name_lenght numeric,
product_desciption_lenght numeric,
product_photos_qty numeric,
product_weight_g numeric,
product_lenght_cm numeric,
product_height_cm numeric,
product_width_cm numeric
);



--Analysis - I
--1)To simplify its financial reports, Amazon India needs to standardize payment values. 
--Round the average payment values to integer (no decimal) for each payment type 
--and display the results sorted in ascending order.

--Output: payment_type, rounded_avg_payment


SELECT payment_type,round(avg(payment_value),0) as rounded_avg_payment
FROM amazon_brazil.payments
GROUP BY payment_type
ORDER BY rounded_avg_payment;

--2)To refine its payment strategy, Amazon India wants to know the distribution of orders by payment type. 
--Calculate the percentage of total orders for each payment type, 
--rounded to one decimal place, and display them in descending order

--Output: payment_type, percentage_orders

SELECT payment_type,round(count(order_id)*100*1.0 / (SELECT count(*) FROM amazon_brazil.payments),1) as "percentage_orders"
FROM amazon_brazil.payments
GROUP BY payment_type
ORDER BY percentage_orders DESC;

--3)Amazon India seeks to create targeted promotions for products within specific price ranges. 
--Identify all products priced between 100 and 500 BRL that contain the word 'Smart' in their name. 
--Display these products, sorted by price in descending order.

--Output: product_id, price

SELECT p.product_id , o.price
FROM amazon_brazil.product p
JOIN amazon_brazil.order_items o
ON p.product_id = o.product_id
WHERE o.price BETWEEN 100 AND 500 AND p.product_category_name LIKE '%smart%'
ORDER BY o.price DESC;


--4)To identify seasonal sales patterns, Amazon India needs to focus on the most successful months. 
--Determine the top 3 months with the highest total sales value, rounded to the nearest integer.

--Output: month, total_sales

SELECT TO_CHAR(order_delivered_customer_date,'Month') as month, sum(oi.price) as total_Sales FROM amazon_brazil.orders o
JOIN amazon_brazil.order_items as oi
ON o.order_id = oi.order_id
group by month
order by total_sales DESC
limit 3;



--5)Amazon India is interested in product categories with significant price variations. Find categories where the difference between the maximum and minimum product prices is greater than 500 BRL.

--Output: product_category_name, price_difference


SELECT DISTINCT p.product_category_name ,(max(o.price)-min(o.price)) as price_difference FROM amazon_brazil.product p
JOIN amazon_brazil.order_items as o
ON o.product_id = p.product_id
GROUP BY product_category_name
HAVING (max(o.price)-min(o.price)) > 500
ORDER BY price_difference DESC;


-- 6)To enhance the customer experience, Amazon India wants to find which payment types have the most consistent transaction amounts. Identify the payment types with the least variance in transaction amounts, sorting by the smallest standard deviation first.

-- Output: payment_type, std_deviation

SELECT payment_type,ROUND(STDDEV_SAMP(payment_value),2) as std_deviation FROM amazon_brazil.payments 
GROUP BY payment_type
ORDER BY std_deviation ASC;


-- 7)Amazon India wants to identify products that may have incomplete name in order to fix it from their end. 
--Retrieve the list of products where the product category name is missing or contains only a single character.

-- Output: product_id, product_category_name
 

SELECT product_id, product_category_name FROM amazon_brazil.product
where product_category_name IS NULL OR LENGTH(TRIM(product_category_name))=1;


-- Analysis - II
-- 1)Amazon India wants to understand which payment types are most popular across different order value segments 
--(e.g., low, medium, high). Segment order values into three ranges: orders less than 200 BRL, between 200 and 1000 BRL, 
--and over 1000 BRL. Calculate the count of each payment type within these ranges and display the results in 
--descending order of count.

-- Output: order_value_segment, payment_type, count


SELECT CASE
		WHEN payment_value < 200 THEN 'Low'
		WHEN payment_value BETWEEN 200  AND 1000 THEN 'Medium'
		WHEN payment_value > 1000 THEN 'High'
	END as order_value_segment, 
	 payment_type , count(*) as "count"
FROM amazon_brazil.payments
GROUP BY order_value_segment,payment_type
ORDER BY count DESC;


-- 2)Amazon India wants to analyse the price range and average price for each product category. Calculate the minimum, 
--maximum, and average price for each category, and list them in descending order by the average price.

-- Output: product_category_name, min_price, max_price, avg_price

SELECT p.product_category_name,min(o.price) as min_price,max(o.price) as max_price,round(avg(o.price),2) as avg_price 
FROM amazon_brazil.product p
JOIN amazon_brazil.order_items o
ON p.product_id = o.product_id
GROUP BY p.product_category_name
ORDER BY avg_price DESC;


-- 3)Amazon India wants to identify the customers who have placed multiple orders over time. Find all customers with more 
--than one order, and display their customer unique IDs along with the total number of orders they have placed.

-- Output: customer_unique_id, total_orders

SELECT c.customer_unique_id, count(*) as total_orders
FROM amazon_brazil.customers c
JOIN amazon_brazil.orders o 
ON c.customer_id = o.customer_id
GROUP BY c.customer_unique_id,o.order_status
HAVING count(*) > 1
ORDER BY total_orders DESC



-- 4)Amazon India wants to categorize customers into different types ('New – order qty. = 1' ;  'Returning' –order qty. 2 to 4;  
--'Loyal' – order qty. >4) based on their purchase history. Use a temporary table to define these categories and join it with 
--the customers table to update and display the customer types.

-- Output: customer_unique_id, customer_type

CREATE TEMP TABLE table1 AS	(
	SELECT c.customer_unique_id, count(*) as total_orders
	FROM amazon_brazil.customers c
	JOIN amazon_brazil.orders o 
	ON c.customer_id = o.customer_id
	GROUP BY c.customer_unique_id
)

SELECT customer_unique_id,
	CASE 
		WHEN total_orders = 1 THEN 'New'
		WHEN total_orders BETWEEN 2 AND 4 THEN 'Returning'
		WHEN total_orders > 4 THEN 'Loyal'
	END as customer_type 
FROM table1
ORDER BY customer_type;






-- 5)Amazon India wants to know which product categories generate the most revenue. Use joins between the tables to calculate 
--the total revenue for each product category. Display the top 5 categories.

-- Output: product_category_name, total_revenue

SELECT p.product_category_name,SUM(o.price) as total_revenue FROM amazon_brazil.product p
JOIN amazon_brazil.order_items o
ON p.product_id = o.product_id
GROUP BY p.product_category_name
ORDER BY total_revenue DESC
LIMIT 5;



-- Analysis - III
-- 1)The marketing team wants to compare the total sales between different seasons. Use a subquery to calculate 
--total sales for each season (Spring, Summer, Autumn, Winter) based on order purchase dates, and display the results.
--Spring is in the months of March, April and May. Summer is from June to August and Autumn is between September and 
--November and rest months are Winter. 

-- Output: season, total_sales

SELECT season, SUM(o.price) AS total_sales
FROM amazon_brazil.order_items o
JOIN (
    SELECT order_id,
           CASE
               WHEN CAST(TO_CHAR(order_purchas_timestamp,'MM') AS INT) BETWEEN 3 AND 5 THEN 'Spring'
               WHEN CAST(TO_CHAR(order_purchas_timestamp,'MM') AS INT) BETWEEN 6 AND 8 THEN 'Summer'
               WHEN CAST(TO_CHAR(order_purchas_timestamp,'MM') AS INT) BETWEEN 9 AND 11 THEN 'Autumn'
               ELSE 'Winter'
           END AS season
    FROM amazon_brazil.orders 
) sub
ON o.order_id = sub.order_id
GROUP BY season
ORDER BY total_sales DESC;









-- 2)The inventory team is interested in identifying products that have sales volumes above the overall average. 
--Write a query that uses a subquery to filter products with a total quantity sold above the average quantity.

-- Output: product_id, total_quantity_sold

SELECT product_id, COUNT(*) AS total_quantity_sold
FROM amazon_brazil.order_items
GROUP BY product_id
HAVING COUNT(*) > (
    SELECT AVG(product_count)
    FROM (
        SELECT COUNT(*) AS product_count
        FROM amazon_brazil.order_items
        GROUP BY product_id
    ) AS sub
)
ORDER BY total_quantity_sold DESC;



-- 3)To understand seasonal sales patterns, the finance team is analysing the monthly revenue trends over the past 
--year (year 2018). Run a query to calculate total revenue generated each month and identify periods of peak and low sales. 
--Export the data to Excel and create a graph to visually represent revenue changes across the months. 

-- Output: month, total_revenue


SELECT
    TO_CHAR(order_delivered_customer_date,'Month') AS month,
    round(SUM(o.price),0) AS total_revenue
FROM amazon_brazil.order_items AS o
JOIN amazon_brazil.orders AS s
    ON o.order_id = s.order_id	
WHERE CAST(TO_CHAR(order_delivered_customer_date, 'YYYY') AS INTEGER) >=  2018
GROUP BY month
order by total_revenue desc;


-- 4)A loyalty program is being designed  for Amazon India. Create a segmentation based on purchase frequency: 
--‘Occasional’ for customers with 1-2 orders, ‘Regular’ for 3-5 orders, and ‘Loyal’ for more than 5 orders. 
--Use a CTE to classify customers and their count and generate a chart in Excel to show the proportion of each segment.

-- Output: customer_type, count


WITH my_cte AS (
	SELECT customer_id,count(order_id) as count FROM amazon_brazil.orders
	GROUP BY customer_id
)
SELECT CASE 
	WHEN count BETWEEN 1 AND 2 THEN 'Occasional'
	WHEN count BETWEEN 3 AND 5 THEN 'Regular'
	ELSE 'Loyal' 
	END as customer_type , count(*) FROM my_cte
	GROUP BY customer_type



-- 5)Amazon wants to identify high-value customers to target for an exclusive rewards program. You are required to 
--rank customers based on their average order value (avg_order_value) to find the top 20 customers.

-- Output: customer_id, avg_order_value, and customer_rank


select customer_id,round(avg(price),2) as avg_order_value,
dense_rank() over (order by round(avg(price),2) desc) as customer_rank
from amazon_brazil.orders as o
join amazon_brazil.order_items as i
on o.order_id=i.order_id
group by customer_id
order by avg_order_value desc 
limit 20	




-- 6)Amazon wants to analyze sales growth trends for its key products over their lifecycle. Calculate monthly cumulative 
--sales for each product from the date of its first sale. Use a recursive CTE to compute the cumulative sales (total_sales) 
--for each product month by month.

-- Output: product_id, sale_month, and total_sales

SELECT 
    oi.product_id,
    TO_CHAR(DATE_TRUNC('month', o.order_purchas_timestamp), 'YYYY-MM') AS sale_month,
    SUM(SUM(oi.price)) OVER (
        PARTITION BY oi.product_id 
        ORDER BY DATE_TRUNC('month', o.order_purchas_timestamp)
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS total_sales
FROM amazon_brazil.order_items oi
JOIN amazon_brazil.orders o 
    ON oi.order_id = o.order_id
GROUP BY oi.product_id, DATE_TRUNC('month', o.order_purchas_timestamp)
ORDER BY oi.product_id, sale_month;





-- 7)To understand how different payment methods affect monthly sales growth, Amazon wants to compute the total sales for 
--each payment method and calculate the month-over-month growth rate for the past year (year 2018). Write query to first 
--calculate total monthly sales for each payment method, then compute the percentage change from the previous month.

-- Output: payment_type, sale_month, monthly_total, monthly_change.

WITH monthly_sales AS (
    SELECT 
        p.payment_type,
        TO_CHAR(o.order_purchas_timestamp, 'YYYY-MM') AS sale_month,
        SUM(oi.price) AS monthly_total
    FROM amazon_brazil.payments p
    JOIN amazon_brazil.order_items oi ON p.order_id = oi.order_id
    JOIN amazon_brazil.orders o ON oi.order_id = o.order_id
    WHERE EXTRACT(YEAR FROM o.order_purchas_timestamp) = 2018
    GROUP BY p.payment_type, TO_CHAR(o.order_purchas_timestamp, 'YYYY-MM')
)
SELECT 
    payment_type,
    sale_month,
    monthly_total,
    (monthly_total - LAG(monthly_total) OVER (PARTITION BY payment_type ORDER BY sale_month)) AS monthly_change
FROM monthly_sales
ORDER BY payment_type, sale_month;



