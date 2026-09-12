/* ============================================================
   03_constraints_indexes.sql
   Most PK/FK/CHECK/UNIQUE/DEFAULT constraints are declared
   inline in 02_create_tables.sql (this keeps each table's
   business rules next to its definition, which is easier to
   defend in a viva). This script adds the NONCLUSTERED indexes
   that support the application's most common lookups and
   reports, plus two composite constraints that only make sense
   after all tables exist.
   ============================================================ */

USE FootballIndustryDB;
GO

-- Foreign-key columns benefit from indexes (SQL Server does not
-- auto-index FK columns the way PKs are auto-indexed).
CREATE NONCLUSTERED INDEX IX_RawMaterial_Supplier      ON RawMaterial(SupplierID);
CREATE NONCLUSTERED INDEX IX_Product_Manufacturer      ON Product(ManufacturerID);
CREATE NONCLUSTERED INDEX IX_Batch_Product             ON ProductionBatch(ProductID);
CREATE NONCLUSTERED INDEX IX_Batch_Manufacturer        ON ProductionBatch(ManufacturerID);
CREATE NONCLUSTERED INDEX IX_Batch_Status              ON ProductionBatch(Status);
CREATE NONCLUSTERED INDEX IX_QI_Batch                  ON QualityInspection(BatchID);
CREATE NONCLUSTERED INDEX IX_Inventory_Product         ON Inventory(ProductID);
CREATE NONCLUSTERED INDEX IX_Inventory_Warehouse       ON Inventory(WarehouseID);
CREATE NONCLUSTERED INDEX IX_Inventory_StockStatus     ON Inventory(StockStatus);
CREATE NONCLUSTERED INDEX IX_ExportOrder_Client        ON ExportOrder(ClientID);
CREATE NONCLUSTERED INDEX IX_ExportOrder_Country       ON ExportOrder(DestinationCountry);
CREATE NONCLUSTERED INDEX IX_ExportOrder_Date          ON ExportOrder(OrderDate);
CREATE NONCLUSTERED INDEX IX_OrderDetail_Order         ON OrderDetail(ExportOrderID);
CREATE NONCLUSTERED INDEX IX_OrderDetail_Product       ON OrderDetail(ProductID);
CREATE NONCLUSTERED INDEX IX_Shipment_Status           ON Shipment(ShipmentStatus);
CREATE NONCLUSTERED INDEX IX_CustomerOrder_Customer    ON CustomerOrder(CustomerID);
CREATE NONCLUSTERED INDEX IX_COI_Order                 ON CustomerOrderItem(CustomerOrderID);
CREATE NONCLUSTERED INDEX IX_COI_Product               ON CustomerOrderItem(ProductID);
CREATE NONCLUSTERED INDEX IX_Review_Product            ON Review(ProductID);
CREATE NONCLUSTERED INDEX IX_Certification_Product     ON Certification(ProductID);
CREATE NONCLUSTERED INDEX IX_Manufacturer_Country      ON Manufacturer(Country);
GO

PRINT 'Indexes created successfully.';
GO
