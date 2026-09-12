/* ============================================================
   08_transactions.sql
   Standalone demonstrations of explicit transactions, separate
   from the stored procedures in 06 (which already wrap their
   logic in transactions). Useful to show your instructor raw
   BEGIN/COMMIT/ROLLBACK/TRY-CATCH behaviour directly in SSMS.
   ============================================================ */

USE FootballIndustryDB;
GO

/* ---------------------------------------------------------
   DEMO 1: Marketplace order placement
   Inserts a CustomerOrder + CustomerOrderItem rows, then
   deducts stock from Inventory. Rolls back entirely if stock
   is insufficient for any line.
   --------------------------------------------------------- */
BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @DemoCustomerID INT = (SELECT TOP 1 CustomerID FROM Customer ORDER BY CustomerID);
    DECLARE @DemoProductID  INT = (SELECT TOP 1 ProductID FROM Product ORDER BY ProductID);
    DECLARE @DemoQty        INT = 5;
    DECLARE @DemoPrice      DECIMAL(10,2) = (SELECT Price FROM Product WHERE ProductID = @DemoProductID);

    INSERT INTO CustomerOrder (CustomerID, TotalAmount, PaymentStatus, OrderStatus)
    VALUES (@DemoCustomerID, 0, 'Pending', 'Processing');

    DECLARE @DemoOrderID INT = SCOPE_IDENTITY();

    INSERT INTO CustomerOrderItem (CustomerOrderID, ProductID, Quantity, UnitPrice)
    VALUES (@DemoOrderID, @DemoProductID, @DemoQty, @DemoPrice);

    UPDATE CustomerOrder
    SET TotalAmount = (SELECT SUM(LineTotal) FROM CustomerOrderItem WHERE CustomerOrderID = @DemoOrderID)
    WHERE CustomerOrderID = @DemoOrderID;

    -- deduct from the first warehouse that stocks this product
    DECLARE @DemoWarehouseID INT = (SELECT TOP 1 WarehouseID FROM Inventory WHERE ProductID = @DemoProductID AND Quantity >= @DemoQty);

    IF @DemoWarehouseID IS NULL
    BEGIN
        RAISERROR('Insufficient stock for demo marketplace order.', 16, 1);
    END

    EXEC sp_UpdateInventory @ProductID = @DemoProductID, @WarehouseID = @DemoWarehouseID, @QuantityDelta = -@DemoQty;

    COMMIT TRANSACTION;
    PRINT 'Demo 1 (marketplace order) committed successfully.';
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    PRINT 'Demo 1 rolled back: ' + ERROR_MESSAGE();
END CATCH
GO

/* ---------------------------------------------------------
   DEMO 2: Production completion
   Moves a Planned/In Production batch to Completed, records a
   passing QC inspection, and lets trg_UpdateInventoryAfterBatch
   push the stock into inventory automatically.
   --------------------------------------------------------- */
BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @DemoBatchID INT = (SELECT TOP 1 BatchID FROM ProductionBatch WHERE Status = 'Planned' ORDER BY BatchID);

    IF @DemoBatchID IS NULL
    BEGIN
        RAISERROR('No Planned batch available for demo.', 16, 1);
    END

    UPDATE ProductionBatch
    SET Status = 'Completed', CompletionDate = CAST(GETDATE() AS DATE)
    WHERE BatchID = @DemoBatchID;

    INSERT INTO QualityInspection
     (BatchID, WeightTestPass, CircumferenceTestPass, PressureTestPass, BounceTestPass, ShapeTestPass, MaterialTestPass, QualityScore, Status)
    VALUES (@DemoBatchID, 1, 1, 1, 1, 1, 1, 95, 'PASS');

    COMMIT TRANSACTION;
    PRINT 'Demo 2 (production completion) committed successfully -- inventory updated by trigger.';
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    PRINT 'Demo 2 rolled back: ' + ERROR_MESSAGE();
END CATCH
GO

/* ---------------------------------------------------------
   DEMO 3: Export order placement via sp_PlaceExportOrder
   --------------------------------------------------------- */
DECLARE @DemoLines OrderDetailTableType;
INSERT INTO @DemoLines (ProductID, Quantity, UnitPrice)
SELECT TOP 2 ProductID, 50, Price FROM Product ORDER BY ProductID;

DECLARE @DemoClientID INT = (SELECT TOP 1 ClientID FROM Client ORDER BY ClientID);
DECLARE @DemoNewOrderID INT;

EXEC sp_PlaceExportOrder
    @ClientID = @DemoClientID,
    @ExportOfficerID = NULL,
    @DestinationCountry = 'Germany',
    @OrderLines = @DemoLines,
    @NewExportOrderID = @DemoNewOrderID OUTPUT;

PRINT CONCAT('Demo 3 (export order placement) created ExportOrderID = ', @DemoNewOrderID);
GO
