/* ============================================================
   07_triggers.sql
   Three purposeful triggers -- no recursive or redundant logic.
   ============================================================ */

USE FootballIndustryDB;
GO

/* ---------------------------------------------------------
   trg_UpdateInventoryAfterBatch
   When a ProductionBatch's Status changes to 'Completed', and
   that batch has a PASS quality inspection, add the produced
   quantity to inventory at a default warehouse (first
   warehouse on record). Applications should call
   sp_UpdateInventory directly when they want a specific
   warehouse; this trigger guarantees stock is never silently
   lost if a batch is completed without an explicit inventory
   call.
   --------------------------------------------------------- */
CREATE OR ALTER TRIGGER trg_UpdateInventoryAfterBatch
ON ProductionBatch
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT UPDATE(Status) RETURN;

    DECLARE @defaultWarehouseID INT = (SELECT MIN(WarehouseID) FROM Warehouse);

    INSERT INTO Inventory (ProductID, WarehouseID, Quantity, ReorderLevel, StockStatus)
    SELECT i.ProductID, @defaultWarehouseID, i.Quantity, 50, 'Available'
    FROM inserted i
    WHERE i.Status = 'Completed'
      AND EXISTS (SELECT 1 FROM QualityInspection qi WHERE qi.BatchID = i.BatchID AND qi.Status = 'PASS')
      AND NOT EXISTS (SELECT 1 FROM Inventory inv WHERE inv.ProductID = i.ProductID AND inv.WarehouseID = @defaultWarehouseID);

    UPDATE inv
    SET inv.Quantity = inv.Quantity + i.Quantity,
        inv.LastUpdated = SYSUTCDATETIME(),
        inv.StockStatus = CASE
            WHEN inv.Quantity + i.Quantity = 0 THEN 'Out of Stock'
            WHEN inv.Quantity + i.Quantity <= inv.ReorderLevel THEN 'Low Stock'
            ELSE 'Available'
        END
    FROM Inventory inv
    INNER JOIN inserted i ON i.ProductID = inv.ProductID AND inv.WarehouseID = @defaultWarehouseID
    INNER JOIN deleted d ON d.BatchID = i.BatchID
    WHERE i.Status = 'Completed'
      AND d.Status <> 'Completed'
      AND EXISTS (SELECT 1 FROM QualityInspection qi WHERE qi.BatchID = i.BatchID AND qi.Status = 'PASS');
END
GO

/* ---------------------------------------------------------
   trg_UpdateOrderTotal
   Recalculates ExportOrder.TotalAmount whenever OrderDetail
   rows are inserted, updated, or deleted.
   --------------------------------------------------------- */
CREATE OR ALTER TRIGGER trg_UpdateOrderTotal
ON OrderDetail
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH AffectedOrders AS (
        SELECT ExportOrderID FROM inserted
        UNION
        SELECT ExportOrderID FROM deleted
    )
    UPDATE eo
    SET eo.TotalAmount = ISNULL((SELECT SUM(od.LineTotal) FROM OrderDetail od WHERE od.ExportOrderID = eo.ExportOrderID), 0)
    FROM ExportOrder eo
    INNER JOIN AffectedOrders ao ON ao.ExportOrderID = eo.ExportOrderID;
END
GO

/* ---------------------------------------------------------
   trg_PreventNegativeInventory
   Belt-and-braces safeguard: rejects any UPDATE that would
   leave Inventory.Quantity negative, even if a future code
   path forgets to route through sp_UpdateInventory.
   --------------------------------------------------------- */
CREATE OR ALTER TRIGGER trg_PreventNegativeInventory
ON Inventory
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM inserted WHERE Quantity < 0)
    BEGIN
        RAISERROR('Inventory quantity cannot go negative.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END
GO

PRINT 'Triggers created successfully.';
GO
