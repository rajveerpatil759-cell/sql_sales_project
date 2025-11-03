# Superstore Sales Analysis SQL Project

## Project Overview

**Project Title**:Superstore Sales Analysis  
**Database**: project

This project is designed to demonstrate SQL skills and techniques typically used by data analysts to explore, clean, and analyze  sales data. The project involves setting up a  sales database, performing exploratory data analysis (EDA), and answering specific business questions through SQL queries. This project is ideal for those who are starting their journey in data analysis and want to build a solid foundation in SQL.

## Objectives

1. **Set up a retail sales database**: Create and populate a  sales database with the provided sales data.
2. **Data Cleaning**: Identify and remove any records with missing or null values.
3. **Exploratory Data Analysis (EDA)**: Perform basic exploratory data analysis to understand the dataset.
4. **Business Analysis**: Use SQL to answer specific business questions and derive insights from the sales data.

5. ## Project Structure

### 1. Database Setup

- **Database Creation**: The project starts by creating a database named `project`.
- **Table Creation**: A table named `customer_table` is created to store the customer data. The table structure includes columns for Customer_ID ,Customer_Name ,Segment ,City ,State ,Region .
                      A table named `product_table` is created to store the product data.The table structure includes columns for ProductID,Category	,Sub-Category,	Product Name.
                       A table named `transcation_table` is created to store the transaction data.The table structure includes columns for Order ID	,Order Date	,Customer ID	,Product ID,Sales.
                     


--customer table
```sql
create table customer_table(Customer_ID varchar(30) primary key,
                            Customer_Name varchar(30),
							              Segment varchar(30),
							              City varchar(30),
							              State varchar(30),
							              Region varchar(30));
```
--product table
```sql
create table product_table(product_id varchar(30) primary key,
                           Category varchar(30),
							             Sub_Category varchar(30),
							             Product_Name varchar(130));
```

--transaction table 
```sql
create table transcation_table(Order_ID varchar(30) not null ,
                               Order_Date date,
							                 Customer_ID varchar(30),
							                 product_id varchar(30) not null ,
							                 Sales NUMERIC(10,2),
							                 CONSTRAINT fk_product FOREIGN KEY (product_id) REFERENCES product_table(product_id),
                               CONSTRAINT fk_customer FOREIGN KEY (Customer_ID) REFERENCES customer_table(Customer_ID),
							                 primary key (Order_ID ,product_id));
```

### 2. Data Cleaning
**A. Check for Cleaned Duplicates**
**B. Check for Cleaned Duplicates**
```sql
SELECT COUNT(Order_ID, product_id) - COUNT(DISTINCT Order_ID, product_id) FROM transcation_table;
SELECT COUNT(*) FROM transcation_table WHERE product_id IS NULL OR Customer_ID IS NULL;
```
### 2. Data Validation
**A. Find Sales without a Valid Product**

**B. Find Sales without a Valid Customer**
**C. Check for Nulls in Critical Dimension Columns**
**D. Isolate Negative Sales (Returns/Cancellations)**
**E. Check for Inconsistent Region Names**
**F. Standardize Casing (If inconsistencies are found)**
```sql
SELECT ft.Order_ID, ft.product_id FROM transcation_table AS ft LEFT JOIN product_table AS dp ON ft.product_id = dp.product_id dp.product_id IS NULL;
SELECT ft.Order_ID, ft.Customer_ID FROM transcation_table AS ft LEFT JOIN customer_table AS dc ON ft.Customer_ID = dc.Customer_ID WHERE dc.Customer_ID IS NULL;
SELECT DISTINCT Region, COUNT(*) FROM customer_table GROUP BY Region HAVING COUNT(*) > 1   ORDER BY 2 DESC;
SELECT COUNT(*) AS Negative_Sales_Count, SUM(Sales) AS Total_Negative_Value FROM transcation_table WHERE Sales < 0;
SELECT DISTINCT Region, COUNT(*) FROM customer_table GROUP BY Region HAVING COUNT(*) > 1   ORDER BY 2 DESC;
UPDATE customer_table SET Region = INITCAP(Region) WHERE Region IS NOT NULL AND Region != INITCAP(Region);
```

