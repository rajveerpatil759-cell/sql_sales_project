--customer table

create table customer_table(Customer_ID varchar(30) primary key,
                            Customer_Name varchar(30),
							Segment varchar(30),
							City varchar(30),
							State varchar(30),
							Region varchar(30));
--product table

create table product_table(product_id varchar(30) primary key,
                            Category varchar(30),
							Sub_Category varchar(30),
							Product_Name varchar(130));

  

--transaction table

create table transcation_table(Order_ID varchar(30) not null ,
                               Order_Date date,
							   Customer_ID varchar(30),
							   product_id varchar(30) not null ,
							   Sales NUMERIC(10,2),
							   CONSTRAINT fk_product FOREIGN KEY (product_id) REFERENCES product_table(product_id),
							   CONSTRAINT fk_customer FOREIGN KEY (Customer_ID) REFERENCES customer_table(Customer_ID),
							   primary key (Order_ID ,product_id));

--DATA CLEANING
--A. Check for Cleaned Duplicates
SELECT COUNT(Order_ID, product_id) - COUNT(DISTINCT Order_ID, product_id) FROM transcation_table;

--B. Check for Cleaned Nulls
SELECT COUNT(*) FROM transcation_table WHERE product_id IS NULL OR Customer_ID IS NULL;
							   
-- DATA VALIDATION
--A. Find Sales without a Valid Product
SELECT
    ft.Order_ID,
    ft.product_id
FROM
    transcation_table AS ft
LEFT JOIN
    product_table AS dp ON ft.product_id = dp.product_id
WHERE
    dp.product_id IS NULL;-- Expected Result: Zero rows. If rows appear, it means the product_id exists in the transaction table but not in the product table.


--B. Find Sales without a Valid Customer
SELECT
    ft.Order_ID,
    ft.Customer_ID
FROM
    transcation_table AS ft
LEFT JOIN
    customer_table AS dc ON ft.Customer_ID = dc.Customer_ID
WHERE
    dc.Customer_ID IS NULL;-- Expected Result: Zero rows. If rows appear, it means the Customer_ID exists in the transaction table but not in the customer table.


--C. Check for Nulls in Critical Dimension Columns
-- Check for common misspellings or casing issues (e.g., 'West' vs 'west')
SELECT DISTINCT Region, COUNT(*)
FROM customer_table
GROUP BY Region
HAVING COUNT(*) > 1  -- Look for cases where a region might be counted multiple times due to spelling
ORDER BY 2 DESC;


--D. Isolate Negative Sales (Returns/Cancellations)
-- Count and view negative transactions
SELECT
    COUNT(*) AS Negative_Sales_Count,
    SUM(Sales) AS Total_Negative_Value
FROM
    transcation_table
WHERE
    Sales < 0;

--E. Check for Inconsistent Region Names
-- Check for common misspellings or casing issues (e.g., 'West' vs 'west')
SELECT DISTINCT Region, COUNT(*)
FROM customer_table
GROUP BY Region
HAVING COUNT(*) > 1  -- Look for cases where a region might be counted multiple times due to spelling
ORDER BY 2 DESC;

--F. Standardize Casing (If inconsistencies are found)
-- This query standardizes all Region names to start with a capital letter
UPDATE
    customer_table
SET
    Region = INITCAP(Region)
WHERE
    Region IS NOT NULL AND Region != INITCAP(Region);

	
--1. Write a Query find top selling products by total sales
SELECT
    dp.Product_Name,
    dp.Category,
    SUM(ft.Sales) AS Total_Revenue
FROM
    transcation_table AS ft
INNER JOIN
    product_table AS dp ON ft.product_id = dp.product_id
GROUP BY
    dp.Product_Name,
    dp.Category  -- Group by both to ensure correct unique product aggregation
ORDER BY
    Total_Revenue DESC
LIMIT 10;


--2. Write a Query to find Top-Ranked Product in Each Category
							   
WITH Ranked_Products AS (
    SELECT
        dp.Category,
        dp.Product_Name,
        SUM(ft.Sales) AS Total_Sales,
        -- Rank products within each Category (Partition) by sales (Order)
        RANK() OVER (PARTITION BY dp.Category ORDER BY SUM(ft.Sales) DESC) AS sales_rank
    FROM
	     product_table AS dp
        
    INNER JOIN
       transcation_table AS ft ON  dp.product_id = ft.product_id 
    GROUP BY
        dp.Category, dp.Product_Name
)
--Select only the top 3 products from each category
SELECT
    Category,
    Product_Name,
    Total_Sales
FROM
    Ranked_Products
WHERE
    sales_rank <= 3
ORDER BY
    Category, sales_rank;

--3 .Write a Query to Find out Regional Sales Performance
	SELECT
    dc.Region,
    SUM(ft.Sales) AS Total_Regional_Sales
FROM
    transcation_table AS ft
INNER JOIN
    customer_table AS dc ON ft.Customer_ID = dc.Customer_ID
GROUP BY
    dc.Region
ORDER BY
    Total_Regional_Sales DESC;

--4. Write a Query  to find Sales from Top 2 Performing Regions
SELECT
    dc.Region,
    SUM(ft.Sales) AS Top_Regional_Sales
FROM
    transcation_table AS ft
INNER JOIN
    customer_table AS dc ON ft.Customer_ID = dc.Customer_ID
WHERE
    dc.Region IN (
        -- Subquery: Finds the names of the top 2 regions by sales
        SELECT
            Region
        FROM
            customer_table AS c
        INNER JOIN
            transcation_table AS t ON c.Customer_ID = t.Customer_ID
        GROUP BY
            Region
        ORDER BY
            SUM(t.Sales) DESC
        LIMIT 2
    )
GROUP BY
    dc.Region
ORDER BY
    Top_Regional_Sales DESC;


--5. To make the query faster, we will add indexes to the columns in the largest table (transcation_table) that are used for  
--joining(your Foreign Keys) and filtering.
-- 1. Index for Joining to Product Table
CREATE INDEX idx_fk_product_id ON transcation_table (product_id);

-- 2. Index for Joining to Customer Table
CREATE INDEX idx_fk_customer_id ON transcation_table (Customer_ID);

-- 3. Index for Filtering/Grouping by Date
CREATE INDEX idx_order_date ON transcation_table (Order_Date);


--6. To see cost of operation using EXPLAIN ANALYZE command
EXPLAIN ANALYZE
SELECT
    dp.Category,
    dc.Region,
    SUM(ft.Sales) AS Total_Sales
FROM
    transcation_table AS ft
INNER JOIN
    product_table AS dp ON ft.product_id = dp.product_id  -- Join 1 on FK
INNER JOIN
    customer_table AS dc ON ft.Customer_ID = dc.Customer_ID -- Join 2 on FK
GROUP BY
    dp.Category,
    dc.Region;


--7. Write a Query to Calculate Month-over-Month (MoM) Sales Growth
WITH Monthly_Sales AS (
    SELECT
        DATE_TRUNC('month', Order_Date) AS sales_month,
        SUM(Sales) AS current_month_sales
    FROM
        transcation_table
    GROUP BY
        sales_month
),
MoM_Comparison AS (
    SELECT
        sales_month,
        current_month_sales,
        -- Get sales from the previous month in the same row
        LAG(current_month_sales, 1) OVER (ORDER BY sales_month) AS previous_month_sales
    FROM
        Monthly_Sales
)
SELECT
    sales_month,
    current_month_sales,
    (current_month_sales - previous_month_sales) / previous_month_sales AS mom_growth_rate
FROM
    MoM_Comparison
WHERE
    previous_month_sales IS NOT NULL;

--8. Write Query to find Sales Contribution of Each Region Over Time
SELECT
    sales_month,
    Region,
    Monthly_Regional_Sales,
    Total_Company_Sales,
    -- Calculate the percentage contribution
    ROUND((Monthly_Regional_Sales * 100.0 / Total_Company_Sales), 2) AS Region_Contribution_Pct
FROM (
    SELECT
        DATE_TRUNC('month', ft.Order_Date) AS sales_month,
        dc.Region,
        SUM(ft.Sales) AS Monthly_Regional_Sales,
        -- Calculate the total sales for the entire company for that month (Window Function)
        SUM(SUM(ft.Sales)) OVER (PARTITION BY DATE_TRUNC('month', ft.Order_Date)) AS Total_Company_Sales
    FROM
        transcation_table AS ft
    INNER JOIN
        customer_table AS dc ON ft.Customer_ID = dc.Customer_ID
    GROUP BY
        sales_month,
        dc.Region
) AS Regional_Monthly_Performance
ORDER BY
    sales_month,
    Region_Contribution_Pct DESC;

--9. Write a Query to Segment customers into high, medium, and low value based on their average transaction
--size and count the number of customers in each segment.
WITH Customer_Metrics AS (
    SELECT
        Customer_ID,
        COUNT(DISTINCT Order_ID) AS Total_Orders,
        AVG(Sales) AS Avg_Order_Value
    FROM
        transcation_table
    GROUP BY
        Customer_ID
)
--Classify customers based on their average order value (AOV)
SELECT
    COUNT(Customer_ID) AS Customer_Count,
    CASE
        WHEN Avg_Order_Value >= 500 THEN 'High-Value'
        WHEN Avg_Order_Value >= 100 THEN 'Medium-Value'
        ELSE 'Low-Value'
    END AS Customer_Segment_AOV
FROM
    Customer_Metrics
GROUP BY
    Customer_Segment_AOV
ORDER BY
    Customer_Count DESC;

--10.Write a Query to Calculate the cumulative sales total from the beginning of the dataset to track overall business growth.
SELECT
    DATE_TRUNC('month', Order_Date) AS sales_month,
    SUM(Sales) AS monthly_sales,
    -- Calculate the running sum of sales ordered by month
    SUM(SUM(Sales)) OVER (ORDER BY DATE_TRUNC('month', Order_Date)) AS cumulative_sales
FROM
    transcation_table
GROUP BY
    sales_month
ORDER BY
    sales_month;

   