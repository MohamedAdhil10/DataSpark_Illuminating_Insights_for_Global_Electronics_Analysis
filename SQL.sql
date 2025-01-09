-- Select all columns from each table
SELECT * FROM customer_details;
SELECT * FROM exchange_details;
SELECT * FROM product_details;
SELECT * FROM sales_details;
SELECT * FROM stores_details;

-- Describe tables
-- Change dtypes to date
-- customer table
-- customer_details;
SELECT column_name, data_type, character_maximum_length
FROM information_schema.columns
WHERE table_name = 'customer_details'
AND table_schema = 'dataspark';
UPDATE customer_details
SET Birthday = STR_TO_DATE(Birthday, '%Y-%m-%d');
ALTER TABLE customer_details
MODIFY COLUMN Birthday DATE;


-- sales table
-- sales_details;
SELECT column_name, data_type, character_maximum_length
FROM information_schema.columns
WHERE table_name = 'sales_details'
  AND table_schema = 'dataspark';
UPDATE sales_details SET Order_Date = STR_TO_DATE(Order_Date, '%Y-%m-%d');
ALTER TABLE sales_details
MODIFY COLUMN Order_Date DATE;

-- stores table
-- stores_details
SELECT column_name, data_type, character_maximum_length
FROM information_schema.columns
WHERE table_name = 'stores_details'
AND table_schema = 'dataspark';
UPDATE stores_details SET Open_Date = STR_TO_DATE(Open_Date, '%Y-%m-%d');
ALTER TABLE stores_details
MODIFY COLUMN Open_Date DATE;

-- exchange rate table
UPDATE exchange_details SET Date = STR_TO_DATE(Date, '%Y-%m-%d');
ALTER TABLE exchange_details
MODIFY COLUMN Date DATE;


-- queries to get insights from 5 tables
-- 1. Overall female count
SELECT COUNT(Gender) AS Female_count
FROM customer_details
WHERE Gender = 'Female';


-- 2. Overall male count
SELECT COUNT(Gender) AS Male_count
FROM customer_details
WHERE Gender = 'Male';


-- 3.Count of customers in country-wise
SELECT sd.Country, COUNT(DISTINCT c.CustomerKey) AS customer_count
FROM sales_details c
JOIN stores_details sd ON c.StoreKey = sd.StoreKey
GROUP BY sd.Country
ORDER BY customer_count DESC;


-- 4.Overall count of customers
SELECT COUNT(DISTINCT s.CustomerKey) AS customer_count
FROM sales_details s;


-- 5. Count of stores in country-wise
SELECT Country, COUNT(StoreKey) AS store_count
FROM stores_details
GROUP BY Country
ORDER BY store_count DESC;


-- 6. Store-wise sales
SELECT s.StoreKey, sd.Country, SUM(Unit_Price_USD * s.Quantity) AS total_sales_amount
FROM product_details pd
JOIN sales_details s ON pd.ProductKey = s.ProductKey
JOIN stores_details sd ON s.StoreKey = sd.StoreKey
GROUP BY s.StoreKey, sd.Country;


-- 7. Overall selling amount
SELECT SUM(Unit_Price_USD * sd.Quantity) AS total_sales_amount
FROM product_details pd
JOIN sales_details sd ON pd.ProductKey = sd.ProductKey;


-- 8. CP and SP difference and profit
SELECT 
    Product_name, 
    Unit_price_USD, 
    Unit_Cost_USD, 
    ROUND(Unit_price_USD - Unit_Cost_USD, 2) AS diff,
    ROUND((Unit_price_USD - Unit_Cost_USD) / Unit_Cost_USD * 100, 2) AS profit
FROM product_details;


-- 9. Brand-wise selling amount
SELECT 
    Brand, 
    ROUND(SUM(pd.Unit_Price_USD * sd.Quantity), 2) AS sales_amount
FROM product_details pd
JOIN sales_details sd ON pd.ProductKey = sd.ProductKey
GROUP BY Brand;


-- 10. Subcategory-wise selling amount
SELECT Subcategory, COUNT(Subcategory) AS subcategory_count
FROM product_details
GROUP BY Subcategory;

SELECT 
    Subcategory, 
    ROUND(SUM(pd.Unit_Price_USD * sd.Quantity), 2) AS TOTAL_SALES_AMOUNT
FROM product_details pd
JOIN sales_details sd ON pd.ProductKey = sd.ProductKey
GROUP BY Subcategory
ORDER BY TOTAL_SALES_AMOUNT DESC;


-- 11. Country-wise overall sales
SELECT s.Country, SUM(pd.Unit_price_USD * sd.Quantity) AS total_sales
FROM product_details pd
JOIN sales_details sd ON pd.ProductKey = sd.ProductKey
JOIN stores_details s ON sd.StoreKey = s.StoreKey
GROUP BY s.Country;

SELECT s.Country, COUNT(DISTINCT s.StoreKey), SUM(pd.Unit_price_USD * sd.Quantity) AS total_sales
FROM product_details pd
JOIN sales_details sd ON pd.ProductKey = sd.ProductKey
JOIN stores_details s ON sd.StoreKey = s.StoreKey
GROUP BY s.Country;


-- 12. Year-wise brand sales
SELECT 
    YEAR(Order_Date) AS order_year, 
    pd.Brand, 
    ROUND(SUM(pd.Unit_Price_USD * sd.Quantity), 2) AS year_sales
FROM sales_details sd
JOIN product_details pd ON sd.ProductKey = pd.ProductKey
GROUP BY YEAR(Order_Date), pd.Brand;


-- 13. Overall sales with quantity
SELECT Brand, SUM(Unit_Price_USD * sd.Quantity) AS sp, SUM(Unit_Cost_USD * sd.Quantity) AS cp,
       (SUM(Unit_Price_USD * sd.Quantity) - SUM(Unit_Cost_USD * sd.Quantity)) / SUM(Unit_Cost_USD * sd.Quantity) * 100 AS profit
FROM product_details pd
JOIN sales_details sd ON sd.ProductKey = pd.ProductKey
GROUP BY Brand;


-- 14. Month-wise sales with quantity
SELECT DATE_FORMAT(Order_Date, '%Y-%m') AS month, 
       SUM(pd.Unit_Price_USD * sd.Quantity) AS sp_month
FROM sales_details sd
JOIN product_details pd ON sd.ProductKey = pd.ProductKey
GROUP BY DATE_FORMAT(Order_Date, '%Y-%m');


-- 15. Month and year-wise sales with quantity
SELECT 
    DATE_FORMAT(Order_Date, '%Y-%m') AS month, 
    YEAR(Order_Date) AS year, 
    pd.Brand, 
    SUM(pd.Unit_Price_USD * sd.Quantity) AS sp_month
FROM sales_details sd
JOIN product_details pd ON sd.ProductKey = pd.ProductKey
GROUP BY DATE_FORMAT(Order_Date, '%Y-%m'), YEAR(Order_Date), pd.Brand;


-- 16. Year-wise sales
SELECT 
    YEAR(Order_Date) AS year, 
    SUM(pd.Unit_Price_USD * sd.Quantity) AS sp_year
FROM sales_details sd
JOIN product_details pd ON sd.ProductKey = pd.ProductKey
GROUP BY YEAR(Order_Date);


-- 17. Comparing current month and previous month
SELECT t1.month, t1.sales, t2.sales AS Previous_Month_Sales
FROM (
    SELECT DATE_FORMAT(Order_Date, '%Y-%m') AS month, 
           SUM(Unit_Price_USD * sd.Quantity) AS sales
    FROM sales_details sd
    JOIN product_details pd ON sd.ProductKey = pd.ProductKey
    GROUP BY DATE_FORMAT(Order_Date, '%Y-%m')
) t1
LEFT JOIN (
    SELECT DATE_FORMAT(Order_Date, '%Y-%m') AS month, 
           SUM(Unit_Price_USD * sd.Quantity) AS sales
    FROM sales_details sd
    JOIN product_details pd ON sd.ProductKey = pd.ProductKey
    GROUP BY DATE_FORMAT(Order_Date, '%Y-%m')
) t2 ON t1.month = DATE_FORMAT(DATE_SUB(STR_TO_DATE(t2.month, '%Y-%m'), INTERVAL 1 MONTH), '%Y-%m');


-- 18. Comparing current year and previous year sales
SELECT t1.year, t1.sales, t2.sales AS Previous_Year_Sales
FROM (
    SELECT YEAR(Order_Date) AS year, SUM(pd.Unit_Price_USD * sd.Quantity) AS sales
    FROM sales_details sd
    JOIN product_details pd ON sd.ProductKey = pd.ProductKey
    GROUP BY YEAR(Order_Date)
) t1
LEFT JOIN (
    SELECT YEAR(Order_Date) AS year, SUM(pd.Unit_Price_USD * sd.Quantity) AS sales
    FROM sales_details sd
    JOIN product_details pd ON sd.ProductKey = pd.ProductKey
    GROUP BY YEAR(Order_Date)
) t2 ON t1.year = t2.year + 1;


-- 19. Month-wise profit
SELECT DATE_FORMAT(Order_Date, '%Y-%m') AS month, 
       SUM(Unit_Price_USD * sd.Quantity) - SUM(Unit_Cost_USD * sd.Quantity) AS profit
FROM sales_details sd
JOIN product_details pd ON sd.ProductKey = pd.ProductKey
GROUP BY DATE_FORMAT(Order_Date, '%Y-%m');


-- 20. Year-wise profit
SELECT YEAR(Order_Date) AS year, 
       SUM(Unit_Price_USD * sd.Quantity) - SUM(Unit_Cost_USD * sd.Quantity) AS profit
FROM sales_details sd
JOIN product_details pd ON sd.ProductKey = pd.ProductKey
GROUP BY YEAR(Order_Date);

