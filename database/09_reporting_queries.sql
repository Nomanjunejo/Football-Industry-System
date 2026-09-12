/* ============================================================
   09_reporting_queries.sql
   Each query below has a real business purpose and is labelled
   with the SQL concept(s) it demonstrates for the DBMS viva.
   ============================================================ */

USE FootballIndustryDB;
GO

-- [SELECT, WHERE, LIKE] Find all products whose name mentions "Match"
SELECT ProductID, ProductName, Category, Price
FROM Product
WHERE ProductName LIKE '%Match%';
GO

-- [WHERE, IN] Export orders going to major European markets
SELECT ExportOrderID, DestinationCountry, TotalAmount, ExportStatus
FROM ExportOrder
WHERE DestinationCountry IN ('Germany','France','United Kingdom','Spain','Italy');
GO

-- [WHERE, BETWEEN] Production batches produced in the last 90 days
SELECT BatchID, ProductID, Quantity, ProductionDate, Status
FROM ProductionBatch
WHERE ProductionDate BETWEEN DATEADD(DAY, -90, CAST(GETDATE() AS DATE)) AND CAST(GETDATE() AS DATE)
ORDER BY ProductionDate DESC;
GO

-- [WHERE, IS NULL] Batches that have not yet been quality-inspected
SELECT pb.BatchID, pb.ProductID, pb.Status
FROM ProductionBatch pb
LEFT JOIN QualityInspection qi ON qi.BatchID = pb.BatchID
WHERE qi.InspectionID IS NULL AND pb.Status IN ('Completed','Failed');
GO

-- [COUNT, GROUP BY, HAVING] Manufacturers with more than 3 failed batches
SELECT ManufacturerID, COUNT(*) AS FailedBatches
FROM ProductionBatch
WHERE Status = 'Failed'
GROUP BY ManufacturerID
HAVING COUNT(*) > 3;
GO

-- [SUM, AVG, MIN, MAX, GROUP BY] Revenue statistics per product category
SELECT
    p.Category,
    SUM(od.LineTotal)  AS TotalRevenue,
    AVG(od.UnitPrice)  AS AvgUnitPrice,
    MIN(od.UnitPrice)  AS MinUnitPrice,
    MAX(od.UnitPrice)  AS MaxUnitPrice
FROM OrderDetail od
INNER JOIN Product p ON p.ProductID = od.ProductID
GROUP BY p.Category
ORDER BY TotalRevenue DESC;
GO

-- [INNER JOIN] Export orders with client and destination detail
SELECT eo.ExportOrderID, c.CompanyName AS ClientName, eo.DestinationCountry, eo.TotalAmount
FROM ExportOrder eo
INNER JOIN Client c ON c.ClientID = eo.ClientID;
GO

-- [LEFT JOIN] Every manufacturer, with production batch count even if zero
SELECT m.CompanyName, COUNT(pb.BatchID) AS BatchCount
FROM Manufacturer m
LEFT JOIN ProductionBatch pb ON pb.ManufacturerID = m.ManufacturerID
GROUP BY m.CompanyName
ORDER BY BatchCount DESC;
GO

-- [RIGHT JOIN] Every warehouse, even those with no inventory rows yet
SELECT w.WarehouseName, i.ProductID, i.Quantity
FROM Inventory i
RIGHT JOIN Warehouse w ON w.WarehouseID = i.WarehouseID;
GO

-- [FULL OUTER JOIN] Reconcile products that have export sales vs marketplace sales
SELECT
    COALESCE(exp.ProductID, mkt.ProductID) AS ProductID,
    exp.ExportUnits,
    mkt.MarketplaceUnits
FROM (
    SELECT ProductID, SUM(Quantity) AS ExportUnits FROM OrderDetail GROUP BY ProductID
) exp
FULL OUTER JOIN (
    SELECT ProductID, SUM(Quantity) AS MarketplaceUnits FROM CustomerOrderItem GROUP BY ProductID
) mkt ON mkt.ProductID = exp.ProductID;
GO

-- [Subquery] Products priced above the overall average price
SELECT ProductName, Price
FROM Product
WHERE Price > (SELECT AVG(Price) FROM Product);
GO

-- [Correlated subquery] Clients whose total export spend exceeds their own country's average
SELECT c.CompanyName, c.Country,
       (SELECT SUM(eo2.TotalAmount) FROM ExportOrder eo2 WHERE eo2.ClientID = c.ClientID) AS ClientTotalSpend
FROM Client c
WHERE (SELECT SUM(eo2.TotalAmount) FROM ExportOrder eo2 WHERE eo2.ClientID = c.ClientID) >
      (SELECT AVG(country_totals.total) FROM (
            SELECT eo3.ClientID, SUM(eo3.TotalAmount) AS total
            FROM ExportOrder eo3
            INNER JOIN Client c3 ON c3.ClientID = eo3.ClientID
            WHERE c3.Country = c.Country
            GROUP BY eo3.ClientID
       ) country_totals);
GO

-- [CASE] Categorize products into price tiers
SELECT ProductName, Price,
    CASE
        WHEN Price < 15 THEN 'Budget'
        WHEN Price BETWEEN 15 AND 30 THEN 'Mid-Range'
        ELSE 'Premium'
    END AS PriceTier
FROM Product;
GO

-- [CTE] Manufacturers ranked by total export revenue
;WITH ManufacturerRevenue AS (
    SELECT m.ManufacturerID, m.CompanyName, ISNULL(SUM(od.LineTotal),0) AS Revenue
    FROM Manufacturer m
    LEFT JOIN Product p ON p.ManufacturerID = m.ManufacturerID
    LEFT JOIN OrderDetail od ON od.ProductID = p.ProductID
    GROUP BY m.ManufacturerID, m.CompanyName
)
SELECT *, RANK() OVER (ORDER BY Revenue DESC) AS RevenueRank
FROM ManufacturerRevenue
ORDER BY Revenue DESC;
GO

-- [Window function] Running monthly export revenue total
SELECT
    MonthStart,
    Revenue,
    SUM(Revenue) OVER (ORDER BY MonthStart ROWS UNBOUNDED PRECEDING) AS RunningTotal
FROM (
    SELECT DATEFROMPARTS(YEAR(eo.OrderDate), MONTH(eo.OrderDate), 1) AS MonthStart, SUM(od.LineTotal) AS Revenue
    FROM ExportOrder eo
    INNER JOIN OrderDetail od ON od.ExportOrderID = eo.ExportOrderID
    GROUP BY DATEFROMPARTS(YEAR(eo.OrderDate), MONTH(eo.OrderDate), 1)
) monthly
ORDER BY MonthStart;
GO

-- [UPDATE] Mark all Delivered shipments' orders as Paid if still Pending
UPDATE eo
SET eo.PaymentStatus = 'Paid'
FROM ExportOrder eo
INNER JOIN Shipment s ON s.ExportOrderID = eo.ExportOrderID
WHERE s.ShipmentStatus = 'Delivered' AND eo.PaymentStatus = 'Pending';
GO

-- [DELETE] Remove certifications that expired more than 2 years ago
DELETE FROM Certification
WHERE ExpiryDate IS NOT NULL AND ExpiryDate < DATEADD(YEAR, -2, CAST(GETDATE() AS DATE));
GO

PRINT 'Reporting query catalog executed successfully.';
GO
