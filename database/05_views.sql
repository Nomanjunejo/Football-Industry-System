/* ============================================================
   05_views.sql
   Reporting views used by both SSMS ad-hoc queries and the
   FastAPI analytics endpoints.
   ============================================================ */

USE FootballIndustryDB;
GO

-- 1. Export revenue aggregated by destination country
CREATE OR ALTER VIEW vw_ExportRevenueByCountry AS
SELECT
    eo.DestinationCountry,
    COUNT(DISTINCT eo.ExportOrderID) AS TotalOrders,
    SUM(od.Quantity)                 AS TotalUnitsExported,
    SUM(od.LineTotal)                AS TotalRevenue
FROM ExportOrder eo
INNER JOIN OrderDetail od ON od.ExportOrderID = eo.ExportOrderID
WHERE eo.ExportStatus <> 'Cancelled'
GROUP BY eo.DestinationCountry;
GO

-- 2. Products currently at or below their reorder level
CREATE OR ALTER VIEW vw_LowStockProducts AS
SELECT
    p.ProductID,
    p.ProductName,
    p.Category,
    i.WarehouseID,
    w.WarehouseName,
    i.Quantity,
    i.ReorderLevel,
    i.StockStatus
FROM Inventory i
INNER JOIN Product p ON p.ProductID = i.ProductID
INNER JOIN Warehouse w ON w.WarehouseID = i.WarehouseID
WHERE i.Quantity <= i.ReorderLevel;
GO

-- 3. Production summary per manufacturer
CREATE OR ALTER VIEW vw_ProductionSummary AS
SELECT
    m.ManufacturerID,
    m.CompanyName,
    COUNT(pb.BatchID)                                             AS TotalBatches,
    SUM(CASE WHEN pb.Status = 'Completed' THEN 1 ELSE 0 END)      AS CompletedBatches,
    SUM(CASE WHEN pb.Status = 'Failed' THEN 1 ELSE 0 END)         AS FailedBatches,
    SUM(CASE WHEN pb.Status = 'Completed' THEN pb.Quantity ELSE 0 END) AS TotalUnitsProduced
FROM Manufacturer m
LEFT JOIN ProductionBatch pb ON pb.ManufacturerID = m.ManufacturerID
GROUP BY m.ManufacturerID, m.CompanyName;
GO

-- 4. Company export performance (used by Compare Companies + Ranking)
CREATE OR ALTER VIEW vw_CompanyExportPerformance AS
SELECT
    m.ManufacturerID,
    m.CompanyName,
    m.Country,
    COUNT(DISTINCT eo.ExportOrderID)   AS TotalExportOrders,
    ISNULL(SUM(od.LineTotal), 0)       AS TotalExportRevenue,
    ISNULL(SUM(od.Quantity), 0)        AS TotalUnitsExported,
    COUNT(DISTINCT eo.DestinationCountry) AS DistinctExportMarkets
FROM Manufacturer m
LEFT JOIN Product p        ON p.ManufacturerID = m.ManufacturerID
LEFT JOIN OrderDetail od   ON od.ProductID = p.ProductID
LEFT JOIN ExportOrder eo   ON eo.ExportOrderID = od.ExportOrderID AND eo.ExportStatus <> 'Cancelled'
GROUP BY m.ManufacturerID, m.CompanyName, m.Country;
GO

-- 5. Product sales performance (export + marketplace combined)
CREATE OR ALTER VIEW vw_ProductSalesPerformance AS
SELECT
    p.ProductID,
    p.ProductName,
    p.Category,
    ISNULL(exp.ExportUnits, 0)   AS ExportUnitsSold,
    ISNULL(exp.ExportRevenue, 0) AS ExportRevenue,
    ISNULL(mkt.MarketplaceUnits, 0)   AS MarketplaceUnitsSold,
    ISNULL(mkt.MarketplaceRevenue, 0) AS MarketplaceRevenue,
    p.AverageRating
FROM Product p
LEFT JOIN (
    SELECT od.ProductID, SUM(od.Quantity) AS ExportUnits, SUM(od.LineTotal) AS ExportRevenue
    FROM OrderDetail od
    INNER JOIN ExportOrder eo ON eo.ExportOrderID = od.ExportOrderID
    WHERE eo.ExportStatus <> 'Cancelled'
    GROUP BY od.ProductID
) exp ON exp.ProductID = p.ProductID
LEFT JOIN (
    SELECT coi.ProductID, SUM(coi.Quantity) AS MarketplaceUnits, SUM(coi.LineTotal) AS MarketplaceRevenue
    FROM CustomerOrderItem coi
    INNER JOIN CustomerOrder co ON co.CustomerOrderID = coi.CustomerOrderID
    WHERE co.OrderStatus <> 'Cancelled'
    GROUP BY coi.ProductID
) mkt ON mkt.ProductID = p.ProductID;
GO

-- 6. Inventory status overview across all warehouses
CREATE OR ALTER VIEW vw_InventoryStatus AS
SELECT
    w.WarehouseID,
    w.WarehouseName,
    p.ProductID,
    p.ProductName,
    i.Quantity,
    i.ReorderLevel,
    i.StockStatus,
    i.LastUpdated
FROM Inventory i
INNER JOIN Product p   ON p.ProductID = i.ProductID
INNER JOIN Warehouse w ON w.WarehouseID = i.WarehouseID;
GO

-- 7. Top export markets by revenue (ranked)
CREATE OR ALTER VIEW vw_TopExportMarkets AS
SELECT
    DestinationCountry,
    TotalRevenue,
    TotalUnitsExported,
    TotalOrders,
    RANK() OVER (ORDER BY TotalRevenue DESC) AS RevenueRank
FROM vw_ExportRevenueByCountry;
GO

PRINT 'Views created successfully.';
GO
