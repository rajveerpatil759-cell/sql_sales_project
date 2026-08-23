# 🗄️ Superstore Sales — SQL Analysis

> End-to-end SQL project covering database design, data engineering, and 27 business-driven queries on 4 years of US retail superstore data.

---

## 📌 Project Overview

**Project Title:** Superstore Sales SQL Analysis
**Tool:** SQL (PostgreSQL)

This project builds a complete PostgreSQL database for the Superstore Sales dataset (2014–2017) and answers 27 real business questions using advanced SQL techniques. The goal was to go beyond basic queries and demonstrate production-ready SQL skills including window functions, CTEs, stored functions, views, and database optimization.

**Tools Used:**
- 🗄️ PostgreSQL — database engine
- 🐍 Python (pandas) — data cleaning and feature engineering
- 🐙 GitHub — version control

---

## 🔑 Key Skills Demonstrated

- **Advanced SQL:** Window Functions (`RANK`, `LAG`, `SUM OVER`, `PARTITION BY`), CTEs, Aggregations
- **Database Design:** Normalization, Foreign Keys, Composite Primary Keys, CHECK Constraints
- **Database Performance:** 8 indexes, `NULLIF` for division safety
- **Data Engineering:** 6 derived columns engineered in Python
- **Reusability:** Stored Function (`plpgsql`), Reusable View
- **Business Intelligence:** YoY growth, MoM trends, Customer Segmentation, Margin Analysis

---

## 📂 Repository Structure

```
superstore-sql/
│
├── data/
│   ├── customer_data.csv
│   ├── product_data.csv
│   └── transaction_data.csv
│
├── sales.sql
└── README.md
```

---

## 📊 Dataset Overview

| Metric | Value |
|--------|-------|
| Time Period | 2014 — 2017 |
| Total Revenue | $2.30M |
| Total Profit | $286K |
| Overall Margin | 12.47% |
| Total Orders | 5,009 |
| Unique Customers | 793 |
| Unique Products | 1,862 |
| Loss Order Rate | 18.72% |

**Three source tables:**
- `customer_table` — 793 customers with segment, city, state, region
- `product_table` — 1,862 products with category and sub-category
- `transaction_table` — 9,994 order lines with 23 columns including engineered features

---

## 🗺️ Entity Relationship Diagram (ERD)

```mermaid
erDiagram
    CUSTOMER ||--o{ TRANSACTION : places
    PRODUCT  ||--o{ TRANSACTION : contains

    CUSTOMER {
        string  Customer_ID   PK
        string  Customer_Name
        string  Segment
        string  City
        string  State
        string  Postal_Code
        string  Region
    }

    PRODUCT {
        string  Product_ID    PK
        string  Category
        string  Sub_Category
        string  Product_Name
    }

    TRANSACTION {
        string   Order_ID          PK
        string   Product_ID        PK_FK
        date     Order_Date
        date     Ship_Date
        string   Ship_Mode
        string   Ship_Speed
        string   Customer_ID       FK
        numeric  Sales
        int      Quantity
        numeric  Discount
        numeric  Profit
        numeric  Profit_Margin_Pct
        int      Delivery_Days
        string   Discount_Band
        int      Order_Year
        int      Order_Month
        string   Order_Month_Name
        string   Season
        string   Is_Loss
        string   Margin_Band
        string   Sales_Bucket
        numeric  Revenue_per_Unit
        numeric  Profit_per_Unit
        numeric  Discount_Amount
    }
```

---

## 🔧 Data Engineering

Six derived columns were engineered in Python before loading into SQL:

| Column | Description | Formula |
|--------|-------------|---------|
| `Revenue_per_Unit` | Revenue per unit sold | Sales / Quantity |
| `Profit_per_Unit` | Profit per unit sold | Profit / Quantity |
| `Discount_Amount` | Actual discount value in dollars | Sales × Discount |
| `Sales_Bucket` | Order size category | Micro / Small / Medium / Large / XL |
| `Margin_Band` | Profit margin category | Loss / Low / Medium / High |
| `Ship_Speed` | Shipping speed label | Express / Fast / Standard / Economy |

---

## 🏗️ Database Design

### Schema
- **3 normalized tables** with primary and foreign key constraints
- **Composite primary key** on transaction_table (Order_ID, Product_ID)
- **CHECK constraints** on Sales (> 0) and Quantity (> 0)
- **NULLIF protection** throughout all division operations

### Indexes (8 total)
```sql
CREATE INDEX idx_product_id    ON transaction_table (Product_ID);
CREATE INDEX idx_customer_id   ON transaction_table (Customer_ID);
CREATE INDEX idx_order_date    ON transaction_table (Order_Date);
CREATE INDEX idx_order_year    ON transaction_table (Order_Year);
CREATE INDEX idx_region        ON customer_table    (Region);
CREATE INDEX idx_category      ON product_table     (Category);
CREATE INDEX idx_segment       ON customer_table    (Segment);
CREATE INDEX idx_discount_band ON transaction_table (Discount_Band);
```

### Reusable View
```sql
CREATE VIEW sales_summary AS
SELECT ft.*, dc.Customer_Name, dc.Segment, dc.City, dc.State, dc.Region,
       dp.Category, dp.Sub_Category, dp.Product_Name
FROM transaction_table ft
JOIN customer_table dc ON ft.Customer_ID = dc.Customer_ID
JOIN product_table  dp ON ft.Product_ID  = dp.Product_ID;
```

### Stored Function
```sql
-- Dynamically returns category and sub-category data for any region
CREATE OR REPLACE FUNCTION get_region_sales(p_region VARCHAR)
RETURNS TABLE (
    Category     VARCHAR,
    Sub_Category VARCHAR,
    Sales        NUMERIC,
    Profit       NUMERIC,
    Discount     NUMERIC
)
LANGUAGE plpgsql
```

---

## 📋 Business Queries — 27 Questions Across 6 Sections

### Section 1 — Executive Overview (Q1–Q3)
| Query | Business Question |
|-------|------------------|
| Q1 | Is the company actually profitable or just growing revenue? |
| Q2 | Is revenue growth translating into profit growth? |
| Q3 | How efficient is the delivery operation by ship mode? |

### Section 2 — Product Profitability (Q4–Q10)
| Query | Business Question |
|-------|------------------|
| Q4 | Which category generates the most revenue and profit? |
| Q5 | Within each category which sub-categories are profitable? |
| Q6 | Which individual products should be prioritized? |
| Q7 | Which specific products are generating the most losses? |
| Q8 | How are orders distributed across margin bands? |
| Q9 | How are orders distributed across sales size buckets? |
| Q10 | Which products lead each category by revenue? |

### Section 3 — Regional & State Performance (Q11–Q14)
| Query | Business Question |
|-------|------------------|
| Q11 | Which regions are driving profit vs underperforming? |
| Q12 | Which states are top performers and which are loss-making? |
| Q13 | Why does Central region underperform — using stored function? |
| Q14 | How is each region contributing to revenue over time? |

### Section 4 — Discount & Margin Analysis (Q15–Q18)
| Query | Business Question |
|-------|------------------|
| Q15 | Is discounting driving sales volume or destroying profit? |
| Q16 | Which sub-categories are discounted the most? |
| Q17 | Which sub-categories generate the most losses? |
| Q18 | How does discount band impact each category differently? |

### Section 5 — Customer Intelligence (Q19–Q22)
| Query | Business Question |
|-------|------------------|
| Q19 | Which customer segment is most valuable? |
| Q20 | Who are the top 10 customers by lifetime profit? |
| Q21 | How loyal is the customer base — repeat vs one-time buyers? |
| Q22 | How are customers distributed by spending level? |

### Section 6 — Time & Seasonal Trends (Q23–Q27)
| Query | Business Question |
|-------|------------------|
| Q23 | Are there specific months where business consistently peaks? |
| Q24 | Is the company on an overall growth trajectory? |
| Q25 | Which months drive the most revenue? |
| Q26 | Which season drives the most revenue and profit? |
| Q27 | How does seasonality affect each category differently? |

---

## 🔑 SQL Techniques Demonstrated

| Technique | Used In |
|-----------|---------|
| CTEs (`WITH` clause) | Q2, Q10, Q12, Q22, Q23 |
| Window Functions (`LAG`, `RANK`, `SUM OVER`, `PARTITION BY`) | Q2, Q10, Q12, Q14, Q24, Q25 |
| Aggregate Functions with FILTER | Q1, Q4, Q9, Q11 |
| NULLIF for division safety | All division operations |
| Stored Function (plpgsql) | get_region_sales() |
| Reusable View | Q4, Q6, Q11 |
| Subqueries | Q14, Q21 |
| HAVING clause | Q7 |
| CASE WHEN | Q12, Q21, Q22 |
| DATE_TRUNC | Q23, Q24 |
| Foreign Key Constraints | Schema design |
| Composite Primary Key | transaction_table |
| CHECK Constraints | Sales > 0, Quantity > 0 |

---

## 🔑 Key Business Insights

**1. Discounting is the #1 profit killer**
- No-discount orders earn **29.5% margin**
- High-discount (41%+) orders lose **89.56% margin**
- Breakeven point is at **20% discount** — above it every order destroys value

**2. Furniture is a revenue trap**
- $742K revenue but only **$18K profit** (2.48% margin)
- Tables alone lose **$17.7K** driven by 26% average discount

**3. Geographic performance gap**
- East leads at **15.5% margin**
- South at **7.5% margin** — half of East
- Texas and Ohio are biggest loss states

**4. Customer retention is exceptional**
- **98.5% repeat customer rate**
- Growth challenge is margin improvement, not customer acquisition

**5. Seasonal concentration**
- Fall drives **37% of annual revenue**
- November and December consistently peak across all 4 years
- February is **83% weaker** than November

---

## 🚀 How to Run

1. Install PostgreSQL
2. Create a new database:
```sql
CREATE DATABASE superstore;
```
3. Run the SQL file:
```bash
psql -d superstore -f sales.sql
```
4. Load CSV data into tables using pgAdmin, COPY command, or Python
5. Execute individual queries to explore insights

---

## 👤 Author

**Rajveer**
- 📧 [your email]
- 💼 [your LinkedIn]
- 🐙 [your GitHub]

---

## 📄 License

This project is for portfolio and educational purposes.
Data source: Superstore Sales Dataset (publicly available sample retail dataset)
