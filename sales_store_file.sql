CREATE DATABASE SALES_SQL;
use sales_sql;

CREATE TABLE sales_store(
transaction_id VARCHAR(15),
customer_id VARCHAR(15),
customer_name VARCHAR(30),
customber_age INT,
gender VARCHAR(15),
product_id VARCHAR(15),
product_name VARCHAR(15),
product_category VARCHAR(15),
quantiy INT,
prce FLOAT,
payment_mode varchar(15),
purchase_date VARCHAR(15),
time_of_purchase TIME,
status varchar(15)
);

SELECT * FROM sales_store;

LOAD DATA LOCAL INFILE 'C:/Users/HP/Downloads/sales_store/sales.csv'
INTO TABLE sales_store
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

SET GLOBAL local_infile = 1;
SHOW GLOBAL VARIABLES LIKE 'local_infile';
# write in cmd  ---   mysql --local-infile=1 -u root -p 
# write in cmd  ---   use sales_sql;
# write in cmd  ---   LOAD DATA LOCAL INFILE 'C:/Users/HP/Downloads/sales_store/sales.csv'
#    -> INTO TABLE sales_store
#    -> FIELDS TERMINATED BY ','
#    -> LINES TERMINATED BY '\n'
#    -> IGNORE 1 LINES;



# Data Cleaning
# step 1 : To check duplicates
CREATE TABLE sales LIKE sales_store;

INSERT INTO sales SELECT * FROM sales_store;

SELECT * FROM sales_store;
SELECT * FROM sales;
drop table sales;


SELECT transaction_id, COUNT(*)
FROM sales
group by transaction_id
having COUNT(transaction_id) > 1;

#TXN855235	2
#TXN342128	2
#TXN240646	2
#TXN981773	2


WITH CTE AS (
    SELECT *,
	        ROW_NUMBER() OVER(PARTITION BY transaction_id ORDER BY transaction_id) AS Row_Num
 	   FROM sales
	)
	SELECT *
	FROM CTE
	WHERE transaction_id IN ('TXN240646', 'TXN342128', 'TXN855235', 'TXN981773');
# it will show the duplicate row and orignal row.



DELETE FROM sales
WHERE transaction_id IN ('TXN240646', 'TXN342128', 'TXN855235', 'TXN981773')
AND (transaction_id, customer_id) IN (
    SELECT t.transaction_id, t.customer_id
    FROM (
        SELECT *,
               ROW_NUMBER() OVER (PARTITION BY transaction_id ORDER BY transaction_id) AS row_num
        FROM sales
    ) AS t
    WHERE t.row_num = 2
);


 
 # Step 2 : Correction of headers

ALTER TABLE sales
RENAME COLUMN prce TO price;
 
ALTER TABLE sales
RENAME COLUMN quantiy TO quantity;

ALTER TABLE sales
RENAME COLUMN customber_age TO customer_age;

select* from sales;



# Step 3 :To Check The  datatype
 
 SHOW COLUMNS FROM sales;



# Step 4 :To Check The NUll Count 

SELECT 'transaction_id' AS ColumnName, SUM(transaction_id IS NULL) AS NullCount FROM sales_store
UNION ALL
SELECT 'customer_id', SUM(customer_id IS NULL) FROM sales
UNION ALL
SELECT 'customer_name', SUM(customer_name IS NULL) FROM sales
UNION ALL
SELECT 'customer_age', SUM(customer_age IS NULL) FROM sales
UNION ALL
SELECT 'gender', SUM(gender IS NULL) FROM sales
UNION ALL
SELECT 'product_id', SUM(product_id IS NULL) FROM sales
UNION ALL
SELECT 'product_name', SUM(product_name IS NULL) FROM sales
UNION ALL
SELECT 'product_category', SUM(product_category IS NULL) FROM sales
UNION ALL
SELECT 'quantity', SUM(quantity IS NULL) FROM sales
UNION ALL
SELECT 'price', SUM(price IS NULL) FROM sales
UNION ALL
SELECT 'payment_mode', SUM(payment_mode IS NULL) FROM sales
UNION ALL
SELECT 'purchase_date', SUM(purchase_date IS NULL) FROM sales
UNION ALL
SELECT 'time_of_purchase', SUM(time_of_purchase IS NULL) FROM sales
UNION ALL
SELECT 'status', SUM(status IS NULL) FROM sales;


# Step 5 : Data Cleaning

select * from sales;

SELECT DISTINCT gender 
FROM sales;

UPDATE sales
SET gender = 'Male'
WHERE gender = 'm';

UPDATE sales
SET gender = 'Female'
WHERE gender = 'f';

SELECT DISTINCT payment_mode
FROM sales;

UPDATE sales
SET payment_mode = 'Credit Card'
WHERE payment_mode = 'CC';

# Step 5 : Data Analysis

# 1. What are the top most selling products by quantity?
SELECT * FROM sales;

SELECT DISTINCT status
FROM sales;

SELECT product_name, SUM(quantity) AS total_quantity_sold
FROM sales
WHERE status = 'delivered'
GROUP BY product_name
ORDER BY total_quantity_sold DESC
LIMIT 5;

-- Business Problem : We dont know products are most in demand.alter
-- Business Impact : Helps priorities stock and boost sales through targeted promotions.
---------------------------------------------------------------------------------------------


# 2. Which product are most frequently canceld?

SELECT product_name, SUM(quantity) AS total_cancelled_quantity
FROM sales
WHERE status = 'cancelled'
GROUP BY product_name
ORDER BY total_cancelled_quantity DESC
LIMIT 5;

-- Business Problem : Frequent cancellation affect revenie and customber trust.
-- Business Impact : Identify poor-performing products to improve quality or remove from catalog.
---------------------------------------------------------------------------------------------


# 3. What time of the day has the highest number of purchse?

SELECT 
    CASE
        WHEN HOUR(time_of_purchase) BETWEEN 0 AND 5 THEN 'Night'
        WHEN HOUR(time_of_purchase) BETWEEN 6 AND 11 THEN 'Morning'
        WHEN HOUR(time_of_purchase) BETWEEN 12 AND 17 THEN 'Afternoon'
        WHEN HOUR(time_of_purchase) BETWEEN 18 AND 23 THEN 'Evening'
    END AS time_of_day,
    COUNT(*) AS total_purchases
FROM sales
GROUP BY time_of_day
ORDER BY total_purchases DESC;

-- Business Problem Solved : Find peak times.
-- Business Impact :Optimize staffing, promotions, and server loads.
-----------------------------------------------------------------------------------------

# 4. who are the top 5 highest spending customer?
SELECT 
    customer_name,
    CONCAT('₹ ', FORMAT(SUM(quantity * price), 0, 'en_IN')) AS total_spending
FROM sales
GROUP BY customer_name
ORDER BY SUM(quantity * price) DESC
LIMIT 5;

-- Business Problem Solved : Identify VIP customers.
-- Business Impact :Personalized offers, loyalty rewards, and retention.
------------------------------------------------------------------------------------------------

# 5. Which product categories genrate the highest revenue?

SELECT 
    product_category,
    CONCAT('₹ ', FORMAT(SUM(quantity * price), 0, 'en_IN')) AS total_revenue
FROM sales
GROUP BY product_category
ORDER BY SUM(quantity * price) DESC;

-- Business Problem Solved : Find peak times.
-- Business Impact :Optimize staffing, promotions, and server loads.
-----------------------------------------------------------------------------------------

# 6. what is the return/cancellation rate per product category?

SELECT 
    product_category,

    -- Cancellation Rate
    CONCAT(
        ROUND((SUM(status = 'cancelled') / COUNT(*)) * 100, 2),
        '%'
    ) AS cancellation_rate,

    -- Return Rate
    CONCAT(
        ROUND((SUM(status = 'returned') / COUNT(*)) * 100, 2),
        '%'
    ) AS return_rate

FROM sales
GROUP BY product_category
ORDER BY (SUM(status = 'cancelled') / COUNT(*)) DESC;

-- Business Problem Solved : Moniter dissatifaction treds per category.
-- Business Impact :Reduce return, improve product descreption/expectation.
#				   :Helps identify and fix product or logistics issues.
-----------------------------------------------------------------------------------------

# 7. what is the most prefered payment mode?

SELECT 
    payment_mode,
    COUNT(*) AS total_count
FROM sales
GROUP BY payment_mode
ORDER BY total_count DESC;

-- Business Problem Solved : Know which payment options customer prefer.
-- Business Impact :Stremline payment processing, prioritize popular modes.
-----------------------------------------------------------------------------------------

# 8. How does age group affect purchasing behaviour ?

SELECT 
    CASE
        WHEN customer_age BETWEEN 18 AND 25 THEN 'Teen (18–25)'
        WHEN customer_age BETWEEN 26 AND 35 THEN 'Young Adult (26–35)'
        WHEN customer_age BETWEEN 36 AND 50 THEN 'Adult (36–50)'
        WHEN customer_age > 60 THEN 'Senior (60+)'
        ELSE 'Unknown'
    END AS age_group,

    CONCAT('₹ ', FORMAT(SUM(quantity * price), 0, 'en_IN')) AS total_purchase
FROM sales
GROUP BY age_group
ORDER BY SUM(quantity * price) DESC;

-- Business Problem Solved :  Understand customer demographics
-- Business Impact : Targeted marketiong and product recomdention by age group.
-----------------------------------------------------------------------------------------


# 9. what is the monthly sales trend ?

SELECT 
    DATE_FORMAT(purchase_date, '%Y-%m') AS month,

    -- Total Revenue in Indian Format
    CONCAT('₹ ', FORMAT(SUM(quantity * price), 0, 'en_IN')) AS total_sales,

    -- Total Quantity Sold
    SUM(quantity) AS total_quantity

FROM sales
GROUP BY DATE_FORMAT(purchase_date, '%Y-%m')
ORDER BY month;

-- Business Problem Solved : Sales fluctuation go unnotice.
-- Business Impact : Plan inventory and marketing according to seasonal trends.
-----------------------------------------------------------------------------------------


# 10. Are certain genders buying more specific product categories? ?

SELECT 
    gender,
    product_category,
    CONCAT('₹ ', FORMAT(SUM(quantity * price), 0, 'en_IN')) AS total_purchase
FROM sales
GROUP BY gender, product_category
ORDER BY SUM(quantity * price) DESC;

SELECT 
    gender,

    CONCAT('₹ ', FORMAT(SUM(CASE WHEN product_category = 'Electronics' THEN quantity * price END), 0, 'en_IN')) AS Electronics,
    CONCAT('₹ ', FORMAT(SUM(CASE WHEN product_category = 'Furniture' THEN quantity * price END), 0, 'en_IN')) AS Furniture,
    CONCAT('₹ ', FORMAT(SUM(CASE WHEN product_category = 'Clothing' THEN quantity * price END), 0, 'en_IN')) AS Clothing,
    CONCAT('₹ ', FORMAT(SUM(CASE WHEN product_category = 'Groceries' THEN quantity * price END), 0, 'en_IN')) AS Groceries,
    CONCAT('₹ ', FORMAT(SUM(CASE WHEN product_category = 'Home Decor' THEN quantity * price END), 0, 'en_IN')) AS `Home Decor`

FROM sales
GROUP BY gender
ORDER BY gender;

-- Business Problem Solved : Gender based product preference.
-- Business Impact : Personalized ads, gender- foucs campaigns.
-----------------------------------------------------------------------------------------

