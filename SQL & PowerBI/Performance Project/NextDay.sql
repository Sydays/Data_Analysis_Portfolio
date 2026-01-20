
-- Data cleaning and exploration in SQL
-- Skills : Update, Create , Select , Joins , Case , Group By , Order By 


-- Checking for duplicates customers and products

SELECT COUNT(*) AS numbers_of_duplicates,customer_id,customer_zip_code_prefix,customer_city, customer_state from customers 
GROUP BY customer_id,customer_zip_code_prefix,customer_city, customer_state
HAVING count(*)> 1;

SELECT COUNT(*) AS numbers_of_duplicates,product_id,product_category_name,product_weight_g,product_length_cm,product_height_cm,product_width_cm from products
GROUP BY product_id,product_category_name,product_weight_g,product_length_cm,product_height_cm,product_width_cm
HAVING count(*)> 1;

Create Table products_clean AS SELECT * FROM products
GROUP BY product_id,product_category_name,product_weight_g,product_length_cm,product_height_cm,product_width_cm;




-----------------------------------------------------------------------------------------------------


-- Making all payment types have the appropriate wording(change coupon to voucher)

SELECT payment_type, COUNT(payment_type) AS num_of_payments FROM payments
GROUP BY payment_type; 

UPDATE supply_data_set
SET payment_type= "voucher"
WHERE payment_type = "coupon";


-----------------------------------------------------------------------------------------------------

-- Rename empty values 

SELECT product_category_name FROM products 
WHERE TRIM(product_category_name) = '';

UPDATE products
SET product_category_name = "other"
WHERE TRIM(product_category_name) = '';


-----------------------------------------------------------------------------------------------------


-- Alter the data type for the orders table

CREATE TABLE orders_staging 
LIKE orders;
INSERT orders_staging 
SELECT * FROM orders;


-----------------------------------------------------------------------------------------------------

-- Check/Update order times 

SELECT order_purchase_timestamp FROM orders_staging
WHERE order_purchase_timestamp IS NULL;

SELECT order_id,order_approved_at FROM orders_staging
WHERE STR_TO_DATE(order_approved_at , '%Y-%m-%d %H:%i:%s') IS NULL AND TRIM(order_approved_at) = '';

UPDATE orders_staging 
SET order_approved_at = NULL
WHERE TRIM(order_approved_at) = '' 
OR STR_TO_DATE(order_approved_at , '%Y-%m-%d %H:%i:%s') IS NULL;

SELECT order_id,order_delivered_timestamp FROM orders_staging
WHERE STR_TO_DATE(order_approved_at , '%Y-%m-%d %H:%i:%s') IS NULL AND TRIM(order_approved_at) = '';

SELECT order_delivered_timestamp FROM orders_staging 
WHERE order_delivered_timestamp IS NOT NULL
AND order_delivered_timestamp NOT REGEXP 
'^[0-9]{4}-[0-2{2}-[0-9]{2}([0-9]{2}:[0-9]{2}:[0-9]{2})?$]';

UPDATE orders_staging
SET order_delivered_timestamp = NULL 
WHERE order_delivered_timestamp IS NOT NULL
AND order_delivered_timestamp NOT REGEXP 
'^[0-9]{4}-[0-2{2}-[0-9]{2}([0-9]{2}:[0-9]{2}:[0-9]{2})?$]';


-----------------------------------------------------------------------------------------------------

-- Changing the data type after all values are formated correctly 

ALTER TABLE orders_staging
MODIFY COLUMN  `order_purchase_timestamp` DATETIME; 

ALTER TABLE orders_staging
MODIFY COLUMN  `order_approved_at` DATETIME; 

ALTER TABLE orders_staging
MODIFY COLUMN  `order_delivered_timestamp` DATETIME ;

ALTER TABLE orders_staging
MODIFY COLUMN order_estimated_delivery_date DATE;



-----------------------------------------------------------------------------------------------------

-- Renaming tables back to normal

ALTER TABLE orders_staging 
RENAME TO orders;

ALTER TABLE products_clean
RENAME TO products;


-----------------------------------------------------------------------------------------------------

-- Total Revenue 

SELECT ROUND(SUM(payment_value),2)AS total_revenue FROM payments;



-----------------------------------------------------------------------------------------------------

-- Total Orderes

SELECT COUNT(order_id) AS total_orders FROM orders;

 
 -----------------------------------------------------------------------------------------------------
 
 
-- On average how does a customer spend

SELECT ROUND(AVG(payment_totals),2) AS avg_cust_total  FROM 
	( SELECT p.order_id , SUM(payment_value) AS payment_totals FROM orders o 
    JOIN payments p 
    ON o.order_id = p.order_id
	GROUP BY o.order_id) 
AS payment_sums; 


-----------------------------------------------------------------------------------------------------

-- What are the total number of Early, Late , On Time delevered orders

SELECT 
  CASE 
    WHEN DATE(order_delivered_timestamp) = DATE(order_estimated_delivery_date) THEN 'On Time'
	WHEN DATE(order_delivered_timestamp) > DATE(order_estimated_delivery_date) THEN 'Late'
    ELSE 'Early'
END AS delivery_status , COUNT(*) AS total_orders
FROM  orders 
WHERE order_delivered_timestamp IS NOT NULL
GROUP BY delivery_status;


-----------------------------------------------------------------------------------------------------


-- Delivery performance by state 

SELECT customer_state, ROUND(AVG(DATEDIFF(DATE(order_delivered_timestamp),DATE(order_purchase_timestamp))),0) AS days from customers c
LEFT JOIN orders o 
ON c.customer_id = o.customer_id
WHERE order_delivered_timestamp IS NOT NULL
GROUP BY customer_state;

-----------------------------------------------------------------------------------------------------


-- Monthly Revenue over time

CREATE VIEW revenue_timeline AS 
SELECT YEAR(order_estimated_delivery_date) AS YEAR,MONTH(order_estimated_delivery_date) AS MONTH, ROUND(sum(payment_value),2) AS Revenue FROM orders o
JOIN payments p
ON o.order_id = p.order_id
GROUP BY YEAR(order_estimated_delivery_date) , MONTH(order_estimated_delivery_date)
ORDER BY YEAR, MONTH asc; 


-----------------------------------------------------------------------------------------------------


-- What is the revenue by product category 

CREATE VIEW revenue_by_category AS 
SELECT product_category_name, ROUND(sum(payment_value),2) AS Total_Revenue FROM payments p 
LEFT JOIN order_items oi
ON p.order_id = oi.order_id 
JOIN products pc
ON pc.product_id = oi.product_id
GROUP BY product_category_name 
ORDER BY Total_Revenue DESC; 


-----------------------------------------------------------------------------------------------------


-- What items are canceled the most 

CREATE VIEW items_returned AS 
SELECT  product_category_name AS Product , count(order_status) AS total_cancled FROM orders o
JOIN order_items oi 
ON o.order_id = oi.order_id
JOIN products p
ON oi.product_id = p.product_id
 WHERE order_status =  "canceled"
 GROUP BY product_category_name
 ORDER BY total_cancled DESC;
 
 
 -----------------------------------------------------------------------------------------------------
 
 
 
-- How many orders are NEXT-DAY orders 

SELECT COUNT(*) AS next_day_deliveries FROM orders 
WHERE order_status = "delivered" 
AND DATE(order_delivered_timestamp) = DATE(order_purchase_timestamp) + INTERVAL 1 DAY;



-----------------------------------------------------------------------------------------------------


-- How much money is held in each status 

SELECT order_status,ROUND(sum(payment_value),2) as total from orders o
JOIN payments p
ON o.order_id = p.order_id 
GROUP BY order_status; 



