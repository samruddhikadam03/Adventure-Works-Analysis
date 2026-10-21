create database adventure_works_cycle;
use adventure_works_cycle;

select * from dimcustomer;
select* from dimdate;
select * from dimproduct;
select * from dimproductcategory;
select * from dimproductsubcategory;
select * from dimsalesterritory;
select * from factinternetsales;
select * from factinternetsalesnew;

#Q 0.Union of Fact Internet sales and Fact internet sales new

CREATE VIEW FactInternetSales_All AS
SELECT ProductKey, OrderDateKey, DueDateKey, ShipDateKey, CustomerKey,
       PromotionKey, CurrencyKey, SalesTerritoryKey, SalesOrderNumber,
       SalesOrderLineNumber, RevisionNumber, OrderQuantity, UnitPrice,
       ExtendedAmount, UnitPriceDiscountPct, DiscountAmount,
       ProductStandardCost, TotalProductCost, SalesAmount, TaxAmt,
       Freight, CarrierTrackingNumber, CustomerPONumber,
       OrderDate, DueDate, ShipDate
FROM FactInternetSales
UNION ALL
SELECT ProductKey, OrderDateKey, DueDateKey, ShipDateKey, CustomerKey,
       PromotionKey, CurrencyKey, SalesTerritoryKey, SalesOrderNumber,
       SalesOrderLineNumber, RevisionNumber, OrderQuantity, UnitPrice,
       ExtendedAmount, UnitPriceDiscountPct, DiscountAmount,
       ProductStandardCost, TotalProductCost, SalesAmount, TaxAmt,
       Freight, CarrierTrackingNumber, CustomerPONumber,
       OrderDate, DueDate, ShipDate
FROM FactInternetSalesNew;


SELECT * FROM FactInternetSales_All;

CREATE OR REPLACE VIEW vw_sales_with_product AS
SELECT
    f.SalesOrderNumber,
    p.EnglishProductName AS ProductName,
    f.UnitPrice,
    f.OrderQuantity,
    f.SalesAmount
FROM FactInternetSales_All f
LEFT JOIN DimProduct p
    ON f.ProductKey = p.ProductKey;
    
    select	* from vw_sales_with_product;

# Q.2.Lookup the Customerfullname from the Customer and Unit Price from Product sheet to Sales sheet.
CREATE OR REPLACE VIEW vw_sales_customer AS
SELECT
    f.SalesOrderNumber,
    f.SalesOrderLineNumber,
    f.OrderDateKey,
    c.CustomerKey,
    CONCAT_WS(' ', c.FirstName, c.LastName) AS CustomerFullName,
    c.Gender,
    c.EnglishOccupation,
    p.ProductKey,
    p.EnglishProductName AS ProductName,
    p.ListPrice,
    f.OrderQuantity,
    f.UnitPrice,
    f.SalesAmount
FROM FactInternetSales_All f
LEFT JOIN DimCustomer c
    ON f.CustomerKey = c.CustomerKey
LEFT JOIN DimProduct p
    ON f.ProductKey = p.ProductKey;
    
SELECT Gender, COUNT(*), SUM(SalesAmount), COUNT(SalesAmount)
FROM vw_sales_customer
GROUP BY Gender;

SELECT
    COALESCE(NULLIF(TRIM(Gender), ''), 'Unknown') AS Gender,
    CONCAT(CAST(COALESCE(SUM(SalesAmount), 0) / 1000000 AS DECIMAL(12,2)), ' M') AS TotalSales
FROM vw_sales_customer
GROUP BY COALESCE(NULLIF(TRIM(Gender), ''), 'Unknown');

select * from vw_sales_customer;


# Q3 A)Year
SELECT
    d.FullDateAlternateKey AS OrderDate,
    d.CalendarYear AS Year
FROM FactInternetSales_All f
JOIN DimDate d
    ON f.OrderDateKey = d.DateKey
ORDER BY d.FullDateAlternateKey;
# B. Monthno, C.MonthFullName
SELECT
    d.FullDateAlternateKey AS OrderDate,
    d.MonthNumberOfYear AS MonthNo,
    d.EnglishMonthName AS MonthName
FROM FactInternetSales_All f
JOIN DimDate d
    ON f.OrderDateKey = d.DateKey
ORDER BY d.FullDateAlternateKey;

SELECT
    STR_TO_DATE(f.OrderDateKey, '%Y%m%d') AS OrderDate,
    MONTHNAME(STR_TO_DATE(f.OrderDateKey, '%Y%m%d')) AS MonthFullName
FROM FactInternetSales_All f
ORDER BY OrderDate;
# D. Quarter
SELECT
    d.FullDateAlternateKey AS OrderDate,
    d.CalendarQuarter AS Quarter
FROM FactInternetSales_All f
JOIN DimDate d
    ON f.OrderDateKey = d.DateKey
ORDER BY d.FullDateAlternateKey;
# E.YearMonth
SELECT
    d.FullDateAlternateKey AS OrderDate,
    DATE_FORMAT(d.FullDateAlternateKey, '%Y-%b') AS YearMonth
FROM FactInternetSales_All f
JOIN DimDate d
    ON f.OrderDateKey = d.DateKey
ORDER BY d.FullDateAlternateKey;
# F.WeekdayNo
SELECT
    d.FullDateAlternateKey AS OrderDate,
    d.DayNumberOfWeek AS WeekdayNo
FROM FactInternetSales_All f
JOIN DimDate d
    ON f.OrderDateKey = d.DateKey
ORDER BY d.FullDateAlternateKey;
# G. WeekdayName
SELECT
    d.FullDateAlternateKey AS OrderDate,
    d.EnglishDayNameOfWeek AS WeekdayName
FROM FactInternetSales_All f
JOIN DimDate d
    ON f.OrderDateKey = d.DateKey
ORDER BY d.FullDateAlternateKey;
# H. Financial Month
SELECT
    d.FullDateAlternateKey AS OrderDate,
    CONCAT(
        'FM',
        CASE
            WHEN d.MonthNumberOfYear >= 4
                THEN d.MonthNumberOfYear - 3
            ELSE d.MonthNumberOfYear + 9
        END
    ) AS FinancialMonth
FROM FactInternetSales_All f
JOIN DimDate d
    ON f.OrderDateKey = d.DateKey
ORDER BY d.FullDateAlternateKey;

# I. Financial Quarter
SELECT
    d.FullDateAlternateKey AS OrderDate,
    CONCAT('FQ', d.FiscalQuarter) AS FinancialQuarter
FROM FactInternetSales_All f
JOIN DimDate d
    ON f.OrderDateKey = d.DateKey
ORDER BY d.FullDateAlternateKey;


CREATE OR REPLACE VIEW vw_sales_with_datefields AS
SELECT
    f.SalesOrderNumber,
    f.SalesOrderLineNumber,
    d.FullDateAlternateKey AS OrderDate,
    d.CalendarYear AS Year,
    d.MonthNumberOfYear AS MonthNo,
    d.EnglishMonthName AS MonthFullName,
    d.CalendarQuarter AS Quarter,
    DATE_FORMAT(d.FullDateAlternateKey, '%Y-%b') AS YearMonth,
    d.DayNumberOfWeek AS WeekdayNo,
    d.EnglishDayNameOfWeek AS WeekdayName,
    CONCAT(
        'FM',
        CASE
            WHEN d.MonthNumberOfYear >= 4 THEN d.MonthNumberOfYear - 3
            ELSE d.MonthNumberOfYear + 9
        END
    ) AS FinancialMonth,
    CASE
        WHEN d.MonthNumberOfYear BETWEEN 4 AND 6   THEN 'FQ1'
        WHEN d.MonthNumberOfYear BETWEEN 7 AND 9   THEN 'FQ2'
        WHEN d.MonthNumberOfYear BETWEEN 10 AND 12 THEN 'FQ3'
        ELSE 'FQ4'
    END AS FinancialQuarter,
    f.SalesAmount,
    f.OrderQuantity
FROM FactInternetSales_All f
JOIN DimDate d
    ON f.OrderDateKey = d.DateKey;

SELECT *
FROM vw_sales_with_datefields;


# Q.4.Calculate the Sales amount uning the columns(unit price,order quantity,unit discount)
SELECT
    f.UnitPrice,
    f.OrderQuantity,
    f.UnitPriceDiscountPct AS UnitDiscount,
    (f.UnitPrice * f.OrderQuantity)
      - (f.UnitPrice * f.OrderQuantity * f.UnitPriceDiscountPct)
      AS SalesAmount
FROM FactInternetSales_All f;

# Total Sales
SELECT
    concat(cast(SUM((f.UnitPrice * f.OrderQuantity)
            - (f.UnitPrice * f.OrderQuantity * f.UnitPriceDiscountPct)) / 1000000
        AS DECIMAL(12,2)),' M'
    ) AS TotalSales_Million
FROM FactInternetSales_All f;

# Q.5.Calculate the Productioncost uning the columns(unit cost ,order quantity)
SELECT
    f.SalesOrderNumber,
    f.ProductKey,
    f.OrderQuantity,
    p.StandardCost AS UnitCost,
    (p.StandardCost * f.OrderQuantity) AS ProductionCost
FROM FactInternetSales_All f
JOIN DimProduct p
    ON f.ProductKey = p.ProductKey;
 
# Q.6.Calculate the profit.
    SELECT
    f.SalesOrderNumber,
    f.OrderQuantity,
    f.UnitPrice,
    p.standardcost,
CAST(((f.UnitPrice * f.OrderQuantity)
            - (f.UnitPrice * f.OrderQuantity * f.UnitPriceDiscountPct)
            - (p.StandardCost * f.OrderQuantity))
        AS DECIMAL(12,2)
    ) AS Profit
    FROM FactInternetSales_All f
	JOIN DimProduct p
    ON f.ProductKey = p.ProductKey;

    
# Q.7. Total Profit
SELECT COUNT(*) FROM DimProduct;


SELECT
    CONCAT(CAST(SUM(
            (f.UnitPrice * f.OrderQuantity)
            - (f.UnitPrice * f.OrderQuantity * f.UnitPriceDiscountPct)
            - (COALESCE(p.StandardCost, 0) * f.OrderQuantity)
        ) / 1000000 AS DECIMAL(12,2)),
        ' M'
    ) AS TotalProfit
FROM FactInternetSales_All f
JOIN DimProduct p
    ON f.ProductKey = p.ProductKey;

# Q.8 Yearwise Sales
SELECT
    YEAR(STR_TO_DATE(f.OrderDateKey, '%Y%m%d')) AS Year,
    concat(CAST(SUM((f.UnitPrice * f.OrderQuantity)
            - (f.UnitPrice * f.OrderQuantity * f.UnitPriceDiscountPct))/1000000 AS DECIMAL (12,2)),' M'
    ) AS YearwiseSales
FROM FactInternetSales_All f
GROUP BY Year
ORDER BY Year;

# Q.9. Monthwise Sales
SELECT
    MONTHNAME(order_date) AS MonthFullName,
    CONCAT(CAST(SUM(UnitPrice * OrderQuantity * (1 - UnitPriceDiscountPct)) / 1000000
            AS DECIMAL(12,2)),' M'
    ) AS MonthwiseSales
FROM (
    SELECT
        *,
        STR_TO_DATE(OrderDateKey, '%Y%m%d') AS order_date
    FROM FactInternetSales_All) f
GROUP BY
    MONTH(order_date),
    MONTHNAME(order_date)
ORDER BY
    MONTH(order_date);


# Q.10. Quarterwise Sales
    SELECT
    CONCAT('Q', qtr) AS Quarter,
    CONCAT(CAST(
            SUM(UnitPrice * OrderQuantity * (1 - UnitPriceDiscountPct)) / 1000000
            AS DECIMAL(12,2)
        ),' M'
    ) AS QuarterwiseSales
FROM (
    SELECT
        UnitPrice,
        OrderQuantity,
        UnitPriceDiscountPct,
        QUARTER(STR_TO_DATE(OrderDateKey, '%Y%m%d')) AS qtr
    FROM FactInternetSales_All
) f
GROUP BY qtr
ORDER BY qtr;

#Q.11. Yearwise Sales and ProductionCost
SELECT
    YEAR(STR_TO_DATE(f.OrderDateKey, '%Y%m%d')) AS Year,
    -- Sales Amount 
    CONCAT(ROUND(SUM((f.UnitPrice * f.OrderQuantity)
                - (f.UnitPrice * f.OrderQuantity * f.UnitPriceDiscountPct)
            ) / 1000000,2),' M'
    ) AS SalesAmount,
    -- Production 
    CONCAT(ROUND(SUM(p.StandardCost * f.OrderQuantity) / 
    1000000,2),' M'
    ) AS ProductionCost
FROM FactInternetSales_All f
JOIN DimProduct p
    ON f.ProductKey = p.ProductKey

GROUP BY YEAR(STR_TO_DATE(f.OrderDateKey, '%Y%m%d'))
ORDER BY Year;

# Q.12 Build KPI's
SELECT
    COUNT(DISTINCT f.CustomerKey) AS TotalCustomers,
    COUNT(DISTINCT f.SalesOrderNumber) AS TotalOrders,
    CONCAT(
        ROUND(SUM(
            (f.UnitPrice * f.OrderQuantity)
            - (f.UnitPrice * f.OrderQuantity * f.UnitPriceDiscountPct)
        ) / 1000000, 2), ' M'
    ) AS TotalSales,
    CONCAT(
        ROUND(SUM(
            (f.UnitPrice * f.OrderQuantity)
            - (f.UnitPrice * f.OrderQuantity * f.UnitPriceDiscountPct)
            - (COALESCE(p.StandardCost, 0) * f.OrderQuantity)
        ) / 1000000, 2), ' M'
    ) AS TotalProfit
FROM FactInternetSales_All f
JOIN DimProduct p
    ON f.ProductKey = p.ProductKey;










