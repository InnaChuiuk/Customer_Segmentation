-- Standardizing data types

ALTER TABLE dbo.online_retail_SQl ALTER COLUMN Quantity INT;
ALTER TABLE dbo.online_retail_SQl ALTER COLUMN Price FLOAT;
ALTER TABLE dbo.online_retail_SQl ALTER COLUMN InvoiceDate DATETIME2;

-- Verifying data transformation and calculating total revenue per line item

SELECT TOP 10
    Quantity,
    Price,
    (Quantity * Price) AS TotalPrice
FROM 
    dbo.online_retail_SQl
ORDER BY 
    Quantity DESC;


-- Initiating customer segmentation

SELECT 
    Customer_ID,
    MAX(InvoiceDate) AS Last_Purchase_Date,
    COUNT(DISTINCT Invoice) AS Total_Orders,
    SUM(Quantity * Price) AS Total_Spend
FROM 
    dbo.online_retail_SQl
WHERE 
    Customer_ID IS NOT NULL
GROUP BY 
    Customer_ID;


-- Data overview using aggregate functions

;WITH agg_columns AS (
    SELECT
        Customer_ID,
        MAX(InvoiceDate) AS Last_Purchase_Date,
        COUNT(DISTINCT Invoice) AS Total_Orders,
        SUM(Quantity * Price) AS Total_Spend
    FROM 
        dbo.online_retail_SQl
    WHERE 
        Customer_ID IS NOT NULL
    GROUP BY 
        Customer_ID
)
SELECT
    MIN(Total_Orders) AS min_to,
    MAX(Total_Orders) AS max_to,
    AVG(Total_Orders) AS avg_to,
    MIN(Total_Spend) AS min_ts,
    MAX(Total_Spend) AS max_ts,
    AVG(Total_Spend) AS avg_ts
FROM 
    agg_columns;


-- Reviewing data distribution using percentiles to identify outliers and ranges

;WITH prc_columns AS (
    SELECT
        Customer_ID,
        DATEDIFF(DAY, MAX(InvoiceDate), (SELECT MAX(InvoiceDate) FROM dbo.online_retail_sql)) AS recent_days_count,
        COUNT(DISTINCT Invoice) AS Total_Orders,
        SUM(Quantity * Price)   AS Total_Spend
    FROM 
        dbo.online_retail_SQl
    WHERE 
        Customer_ID IS NOT NULL
    GROUP BY 
        Customer_ID
)
SELECT DISTINCT
    -- Days since last purchase
    PERCENTILE_DISC(0.2) WITHIN GROUP(ORDER BY recent_days_count) OVER() AS prc_20_rd,
    PERCENTILE_DISC(0.4) WITHIN GROUP(ORDER BY recent_days_count) OVER() AS prc_40_rd,
    PERCENTILE_DISC(0.6) WITHIN GROUP(ORDER BY recent_days_count) OVER() AS prc_60_rd,
    PERCENTILE_DISC(0.8) WITHIN GROUP(ORDER BY recent_days_count) OVER() AS prc_80_rd,

    -- Total number of orders
    PERCENTILE_DISC(0.2) WITHIN GROUP(ORDER BY Total_Orders) OVER() AS prc_20_to,
    PERCENTILE_DISC(0.4) WITHIN GROUP(ORDER BY Total_Orders) OVER() AS prc_40_to,
    PERCENTILE_DISC(0.6) WITHIN GROUP(ORDER BY Total_Orders) OVER() AS prc_60_to,
    PERCENTILE_DISC(0.8) WITHIN GROUP(ORDER BY Total_Orders) OVER() AS prc_80_to,

    -- Total spend
    PERCENTILE_DISC(0.2) WITHIN GROUP(ORDER BY Total_Spend) OVER() AS prc_20_ts,
    PERCENTILE_DISC(0.4) WITHIN GROUP(ORDER BY Total_Spend) OVER() AS prc_40_ts,
    PERCENTILE_DISC(0.6) WITHIN GROUP(ORDER BY Total_Spend) OVER() AS prc_60_ts,
    PERCENTILE_DISC(0.8) WITHIN GROUP(ORDER BY Total_Spend) OVER() AS prc_80_ts
FROM 
    prc_columns


-- Determining the reference date for calculating Recency (days since last purchase)


SELECT MAX(InvoiceDate) AS Global_Max_Date
FROM dbo.online_retail_SQL;


-- Creating a view to calculate RFM metrics: Recency, Frequency, and Monetary value
-- Assigning scores based on data distribution (quintiles/percentiles)
-- Assigning final segments to each customer based on their aggregate scores


CREATE VIEW segmentation_analysis AS
WITH segmentation AS (
    SELECT
        Customer_ID,
        DATEDIFF(DAY, MAX(InvoiceDate), '2011-12-10') AS recent_days_count,
        COUNT(DISTINCT Invoice) AS total_orders,
        SUM(Quantity * Price)   AS total_spend
    FROM 
        dbo.online_retail_SQL
    WHERE 
        Customer_ID IS NOT NULL
    GROUP BY 
        Customer_ID
), 
scores AS (
    SELECT *,
        -- Recency scoring
        CASE
            WHEN recent_days_count <= 30  THEN 5
            WHEN recent_days_count <= 90  THEN 4
            WHEN recent_days_count <= 179 THEN 3
            WHEN recent_days_count <= 270 THEN 2
            ELSE 1
        END AS r_score,

        -- Frequency scoring (Orders)
        CASE
            WHEN total_orders <= 1 THEN 1
            WHEN total_orders <= 2 THEN 2
            WHEN total_orders <= 3 THEN 3
            WHEN total_orders <= 6 THEN 4
            ELSE 5
        END AS o_score,

        -- Monetary scoring (Spend)
        CASE 
            WHEN total_spend <= 250  THEN 1
            WHEN total_spend <= 490  THEN 2
            WHEN total_spend <= 942  THEN 3
            WHEN total_spend <= 2059 THEN 4
            ELSE 5
        END AS s_score
    FROM 
        segmentation
)
SELECT *,
    CASE
        WHEN r_score >= 4 AND o_score >= 4 AND s_score >= 4 THEN 'Best Customer'
        WHEN r_score <= 1 THEN 'Lost Customer'
        WHEN r_score >= 4 AND o_score = 1 THEN 'New Customer'
        WHEN r_score <= 2 AND o_score >= 4 THEN 'At Risk/Inactive/Many orders'
        WHEN r_score <= 2 AND o_score < 4 THEN 'At Risk/Inactive/Few orders'
        WHEN r_score > 2  AND o_score < 4 THEN 'Recent/Few orders'
        WHEN r_score > 2  AND o_score >= 4 THEN 'Recent/Many orders'
        ELSE 'Other'
    END AS customer_segment
FROM 
    scores

SELECT *
FROM segmentation_analysis
WHERE customer_segment = 'Other'




