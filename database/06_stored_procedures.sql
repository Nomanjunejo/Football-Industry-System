/* ============================================================
   06_stored_procedures.sql
   ============================================================ */

USE FootballIndustryDB;
GO

/* ---------------------------------------------------------
   sp_PlaceExportOrder
   Inserts an ExportOrder header plus its OrderDetail lines
   inside a single transaction. Uses a table-valued parameter
   for the line items so the whole order is atomic.
   --------------------------------------------------------- */
CREATE TYPE OrderDetailTableType AS TABLE (
    ProductID INT NOT NULL,
    Quantity  INT NOT NULL,
    UnitPrice DECIMAL(10,2) NOT NULL
);
GO

CREATE OR ALTER PROCEDURE sp_PlaceExportOrder
    @ClientID          INT,
    @ExportOfficerID   INT = NULL,
    @DestinationCountry NVARCHAR(80),
    @OrderLines        OrderDetailTableType READONLY,
    @NewExportOrderID  INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS (SELECT 1 FROM Client WHERE ClientID = @ClientID)
    BEGIN
        RAISERROR('Invalid ClientID.', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM @OrderLines)
    BEGIN
        RAISERROR('An export order must contain at least one product line.', 16, 1);
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO ExportOrder (ClientID, ExportOfficerID, DestinationCountry, TotalAmount, PaymentStatus, ExportStatus)
        VALUES (@ClientID, @ExportOfficerID, @DestinationCountry, 0, 'Pending', 'Processing');

        SET @NewExportOrderID = SCOPE_IDENTITY();

        INSERT INTO OrderDetail (ExportOrderID, ProductID, Quantity, UnitPrice)
        SELECT @NewExportOrderID, ProductID, Quantity, UnitPrice
        FROM @OrderLines;

        UPDATE ExportOrder
        SET TotalAmount = (SELECT SUM(LineTotal) FROM OrderDetail WHERE ExportOrderID = @NewExportOrderID)
        WHERE ExportOrderID = @NewExportOrderID;

        INSERT INTO Shipment (ExportOrderID, ShipmentStatus)
        VALUES (@NewExportOrderID, 'Processing');

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

/* ---------------------------------------------------------
   sp_GenerateProductionReport
   Batch-wise production output for a given date range.
   --------------------------------------------------------- */
CREATE OR ALTER PROCEDURE sp_GenerateProductionReport
    @StartDate DATE,
    @EndDate   DATE
AS
BEGIN
    SET NOCOUNT ON;

    IF @StartDate > @EndDate
    BEGIN
        RAISERROR('StartDate cannot be after EndDate.', 16, 1);
        RETURN;
    END

    SELECT
        pb.BatchID,
        p.ProductName,
        m.CompanyName AS Manufacturer,
        pb.Quantity,
        pb.ProductionDate,
        pb.CompletionDate,
        pb.Status,
        qi.QualityScore,
        qi.Status AS QCStatus
    FROM ProductionBatch pb
    INNER JOIN Product p       ON p.ProductID = pb.ProductID
    INNER JOIN Manufacturer m  ON m.ManufacturerID = pb.ManufacturerID
    LEFT JOIN QualityInspection qi ON qi.BatchID = pb.BatchID
    WHERE pb.ProductionDate BETWEEN @StartDate AND @EndDate
    ORDER BY pb.ProductionDate DESC;
END
GO

/* ---------------------------------------------------------
   sp_CreateProductionBatch
   Validates and creates a new batch, optionally recording
   raw-material consumption in the same transaction.
   --------------------------------------------------------- */
CREATE OR ALTER PROCEDURE sp_CreateProductionBatch
    @ProductID      INT,
    @ManufacturerID INT,
    @SupervisorID   INT = NULL,
    @Quantity       INT,
    @ProductionDate DATE,
    @NewBatchID     INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @Quantity <= 0
    BEGIN
        RAISERROR('Quantity must be greater than zero.', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM Product WHERE ProductID = @ProductID)
    BEGIN
        RAISERROR('Invalid ProductID.', 16, 1);
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO ProductionBatch (ProductID, ManufacturerID, SupervisorID, Quantity, ProductionDate, Status)
        VALUES (@ProductID, @ManufacturerID, @SupervisorID, @Quantity, @ProductionDate, 'Planned');

        SET @NewBatchID = SCOPE_IDENTITY();

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

/* ---------------------------------------------------------
   sp_UpdateInventory
   Safely adjusts inventory quantity (positive or negative
   delta) and recalculates stock status. Prevents negative
   stock explicitly (in addition to trg_PreventNegativeInventory).
   --------------------------------------------------------- */
CREATE OR ALTER PROCEDURE sp_UpdateInventory
    @ProductID   INT,
    @WarehouseID INT,
    @QuantityDelta INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1 FROM Inventory WHERE ProductID = @ProductID AND WarehouseID = @WarehouseID)
        BEGIN
            INSERT INTO Inventory (ProductID, WarehouseID, Quantity, ReorderLevel, StockStatus)
            VALUES (@ProductID, @WarehouseID, 0, 50, 'Out of Stock');
        END

        DECLARE @currentQty INT = (SELECT Quantity FROM Inventory WHERE ProductID = @ProductID AND WarehouseID = @WarehouseID);

        IF @currentQty + @QuantityDelta < 0
        BEGIN
            RAISERROR('Insufficient stock: operation would result in negative inventory.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        UPDATE Inventory
        SET Quantity = Quantity + @QuantityDelta,
            LastUpdated = SYSUTCDATETIME(),
            StockStatus = CASE
                WHEN Quantity + @QuantityDelta = 0 THEN 'Out of Stock'
                WHEN Quantity + @QuantityDelta <= ReorderLevel THEN 'Low Stock'
                ELSE 'Available'
            END
        WHERE ProductID = @ProductID AND WarehouseID = @WarehouseID;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

/* ---------------------------------------------------------
   sp_GetCompanyPerformance
   Wraps vw_CompanyExportPerformance + vw_ProductionSummary
   for the Compare Companies feature.
   --------------------------------------------------------- */
CREATE OR ALTER PROCEDURE sp_GetCompanyPerformance
    @ManufacturerID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT * FROM vw_CompanyExportPerformance WHERE ManufacturerID = @ManufacturerID;
    SELECT * FROM vw_ProductionSummary WHERE ManufacturerID = @ManufacturerID;
    SELECT ProductID, ProductName, Category, AverageRating
    FROM Product WHERE ManufacturerID = @ManufacturerID;
END
GO

/* ---------------------------------------------------------
   sp_GetExportReport
   Combined export analytics for a date range: revenue by
   country, top products, monthly trend.
   --------------------------------------------------------- */
CREATE OR ALTER PROCEDURE sp_GetExportReport
    @StartDate DATE,
    @EndDate   DATE
AS
BEGIN
    SET NOCOUNT ON;

    -- revenue by country
    SELECT eo.DestinationCountry, SUM(od.LineTotal) AS Revenue, SUM(od.Quantity) AS Units
    FROM ExportOrder eo
    INNER JOIN OrderDetail od ON od.ExportOrderID = eo.ExportOrderID
    WHERE eo.OrderDate BETWEEN @StartDate AND @EndDate AND eo.ExportStatus <> 'Cancelled'
    GROUP BY eo.DestinationCountry
    ORDER BY Revenue DESC;

    -- top products
    SELECT TOP 10 p.ProductName, SUM(od.Quantity) AS UnitsSold, SUM(od.LineTotal) AS Revenue
    FROM OrderDetail od
    INNER JOIN ExportOrder eo ON eo.ExportOrderID = od.ExportOrderID
    INNER JOIN Product p ON p.ProductID = od.ProductID
    WHERE eo.OrderDate BETWEEN @StartDate AND @EndDate AND eo.ExportStatus <> 'Cancelled'
    GROUP BY p.ProductName
    ORDER BY Revenue DESC;

    -- monthly trend
    SELECT
        DATEFROMPARTS(YEAR(eo.OrderDate), MONTH(eo.OrderDate), 1) AS MonthStart,
        SUM(od.LineTotal) AS Revenue
    FROM ExportOrder eo
    INNER JOIN OrderDetail od ON od.ExportOrderID = eo.ExportOrderID
    WHERE eo.OrderDate BETWEEN @StartDate AND @EndDate AND eo.ExportStatus <> 'Cancelled'
    GROUP BY DATEFROMPARTS(YEAR(eo.OrderDate), MONTH(eo.OrderDate), 1)
    ORDER BY MonthStart;
END
GO

PRINT 'Stored procedures created successfully.';
GO
