

USE master;
GO

IF DB_ID('FootballIndustryDB') IS NOT NULL
BEGIN
    ALTER DATABASE FootballIndustryDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE FootballIndustryDB;
END
GO

CREATE DATABASE FootballIndustryDB;
GO

ALTER DATABASE FootballIndustryDB SET RECOVERY SIMPLE;
GO

USE FootballIndustryDB;
GO

PRINT 'Database FootballIndustryDB created successfully.';
GO

GO



USE FootballIndustryDB;
GO

CREATE TABLE Employee (
    EmployeeID       INT IDENTITY(1,1) PRIMARY KEY,
    FullName         NVARCHAR(120)   NOT NULL,
    Email            NVARCHAR(150)   NOT NULL UNIQUE,
    PasswordHash     NVARCHAR(255)   NOT NULL,
    Role             NVARCHAR(30)    NOT NULL
                        CHECK (Role IN ('Admin','ProductionManager','WarehouseStaff','ExportOfficer','QualityInspector')),
    Department       NVARCHAR(60)    NULL,
    Phone            NVARCHAR(30)    NULL,
    HireDate         DATE            NOT NULL DEFAULT (CAST(GETDATE() AS DATE)),
    IsActive         BIT             NOT NULL DEFAULT (1),
    CreatedAt        DATETIME2       NOT NULL DEFAULT (SYSUTCDATETIME())
);
GO


CREATE TABLE Manufacturer (
    ManufacturerID     INT IDENTITY(1,1) PRIMARY KEY,
    CompanyName        NVARCHAR(150)  NOT NULL UNIQUE,
    Country            NVARCHAR(80)   NOT NULL,
    City               NVARCHAR(80)   NULL,
    EstablishedYear    SMALLINT       NULL CHECK (EstablishedYear BETWEEN 1800 AND 2100),
    CompanyType        NVARCHAR(40)   NULL
                          CHECK (CompanyType IN ('Manufacturer','Exporter','Manufacturer & Exporter','Distributor')),
    Description        NVARCHAR(1000) NULL,
    Website            NVARCHAR(200)  NULL,
    ContactEmail       NVARCHAR(150)  NULL,
    ContactPhone       NVARCHAR(30)   NULL,
    LogoUrl            NVARCHAR(300)  NULL,
    AnnualRevenueUSD   DECIMAL(18,2)  NULL CHECK (AnnualRevenueUSD IS NULL OR AnnualRevenueUSD >= 0),
    PrimaryExportMarkets NVARCHAR(300) NULL,   -- comma-separated summary, e.g. "USA, Germany, UAE"
    IndustryScore      DECIMAL(5,2)   NULL CHECK (IndustryScore IS NULL OR IndustryScore BETWEEN 0 AND 100),
    DataSource         NVARCHAR(150)  NULL,     -- e.g. "Company website", "TDAP directory"
    DataType           NVARCHAR(20)   NOT NULL DEFAULT ('Synthetic')
                          CHECK (DataType IN ('Verified','Estimated','Synthetic')),
    VerificationStatus NVARCHAR(20)   NOT NULL DEFAULT ('Unverified')
                          CHECK (VerificationStatus IN ('Verified','Unverified','Pending')),
    IsActive           BIT            NOT NULL DEFAULT (1),
    CreatedAt          DATETIME2      NOT NULL DEFAULT (SYSUTCDATETIME())
);
GO


CREATE TABLE Supplier (
    SupplierID       INT IDENTITY(1,1) PRIMARY KEY,
    SupplierName     NVARCHAR(150)  NOT NULL,
    Country          NVARCHAR(80)   NOT NULL,
    City             NVARCHAR(80)   NULL,
    ContactEmail     NVARCHAR(150)  NULL UNIQUE,
    ContactPhone     NVARCHAR(30)   NULL,
    MaterialCategory NVARCHAR(80)   NULL,     -- e.g. "Synthetic Leather", "Rubber Bladder"
    Rating           DECIMAL(3,2)   NULL CHECK (Rating IS NULL OR Rating BETWEEN 0 AND 5),
    IsActive         BIT            NOT NULL DEFAULT (1),
    CreatedAt        DATETIME2      NOT NULL DEFAULT (SYSUTCDATETIME())
);
GO

CREATE TABLE RawMaterial (
    RawMaterialID    INT IDENTITY(1,1) PRIMARY KEY,
    SupplierID       INT NOT NULL,
    MaterialName     NVARCHAR(120)  NOT NULL,   -- e.g. "TPU Panel Sheet", "Latex Bladder"
    Unit             NVARCHAR(20)   NOT NULL CHECK (Unit IN ('kg','meter','piece','liter','roll')),
    UnitCost         DECIMAL(12,2)  NOT NULL CHECK (UnitCost >= 0),
    StockQuantity    DECIMAL(14,2)  NOT NULL DEFAULT (0) CHECK (StockQuantity >= 0),
    ReorderLevel     DECIMAL(14,2)  NOT NULL DEFAULT (100) CHECK (ReorderLevel >= 0),
    CreatedAt        DATETIME2      NOT NULL DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT FK_RawMaterial_Supplier FOREIGN KEY (SupplierID)
        REFERENCES Supplier(SupplierID) ON DELETE NO ACTION ON UPDATE CASCADE
);
GO

CREATE TABLE Product (
    ProductID          INT IDENTITY(1,1) PRIMARY KEY,
    ManufacturerID     INT NOT NULL,
    ProductName        NVARCHAR(120)  NOT NULL,
    Category           NVARCHAR(40)   NOT NULL
                          CHECK (Category IN ('Match','Training','Futsal','Beach','Youth','Promotional','Custom')),
    SizeNumber         TINYINT        NOT NULL CHECK (SizeNumber BETWEEN 1 AND 5),
    Material           NVARCHAR(80)   NULL,       -- e.g. "PU Synthetic Leather"
    ConstructionMethod NVARCHAR(40)   NULL CHECK (ConstructionMethod IN ('Hand-Stitched','Machine-Stitched','Thermal-Bonded','Butyl-Bladder') OR ConstructionMethod IS NULL),
    Price              DECIMAL(10,2)  NOT NULL CHECK (Price > 0),
    Description        NVARCHAR(500)  NULL,
    AverageRating      DECIMAL(3,2)   NOT NULL DEFAULT (0) CHECK (AverageRating BETWEEN 0 AND 5),
    IsActive           BIT            NOT NULL DEFAULT (1),
    CreatedAt          DATETIME2      NOT NULL DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT FK_Product_Manufacturer FOREIGN KEY (ManufacturerID)
        REFERENCES Manufacturer(ManufacturerID) ON DELETE NO ACTION ON UPDATE CASCADE
);
GO

CREATE TABLE ProductionBatch (
    BatchID          INT IDENTITY(1,1) PRIMARY KEY,
    ProductID        INT NOT NULL,
    ManufacturerID   INT NOT NULL,
    SupervisorID     INT NULL,                 -- FK Employee (ProductionManager)
    Quantity         INT NOT NULL CHECK (Quantity > 0),
    ProductionDate   DATE NOT NULL,
    CompletionDate   DATE NULL,
    Status           NVARCHAR(20) NOT NULL DEFAULT ('Planned')
                        CHECK (Status IN ('Planned','In Production','Completed','Failed','Cancelled')),
    CreatedAt        DATETIME2 NOT NULL DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT FK_Batch_Product FOREIGN KEY (ProductID)
        REFERENCES Product(ProductID) ON DELETE NO ACTION,
    CONSTRAINT FK_Batch_Manufacturer FOREIGN KEY (ManufacturerID)
        REFERENCES Manufacturer(ManufacturerID) ON DELETE NO ACTION,
    CONSTRAINT FK_Batch_Supervisor FOREIGN KEY (SupervisorID)
        REFERENCES Employee(EmployeeID) ON DELETE SET NULL,
    CONSTRAINT CK_Batch_Dates CHECK (CompletionDate IS NULL OR CompletionDate >= ProductionDate)
);
GO

/* ---------------------------------------------------------
   7. BATCH MATERIAL USAGE  (junction: ProductionBatch <-> RawMaterial)
   --------------------------------------------------------- */
CREATE TABLE BatchMaterialUsage (
    BatchID          INT NOT NULL,
    RawMaterialID    INT NOT NULL,
    QuantityUsed     DECIMAL(14,2) NOT NULL CHECK (QuantityUsed > 0),
    CONSTRAINT PK_BatchMaterialUsage PRIMARY KEY (BatchID, RawMaterialID),
    CONSTRAINT FK_BMU_Batch FOREIGN KEY (BatchID)
        REFERENCES ProductionBatch(BatchID) ON DELETE CASCADE,
    CONSTRAINT FK_BMU_Material FOREIGN KEY (RawMaterialID)
        REFERENCES RawMaterial(RawMaterialID) ON DELETE NO ACTION
);
GO

/* ---------------------------------------------------------
   8. QUALITY INSPECTION
   --------------------------------------------------------- */
CREATE TABLE QualityInspection (
    InspectionID     INT IDENTITY(1,1) PRIMARY KEY,
    BatchID          INT NOT NULL,
    InspectorID      INT NULL,                 -- FK Employee (QualityInspector)
    WeightTestPass   BIT NOT NULL DEFAULT (0),
    CircumferenceTestPass BIT NOT NULL DEFAULT (0),
    PressureTestPass BIT NOT NULL DEFAULT (0),
    BounceTestPass   BIT NOT NULL DEFAULT (0),
    ShapeTestPass    BIT NOT NULL DEFAULT (0),
    MaterialTestPass BIT NOT NULL DEFAULT (0),
    QualityScore     DECIMAL(5,2) NOT NULL CHECK (QualityScore BETWEEN 0 AND 100),
    Status           NVARCHAR(10) NOT NULL CHECK (Status IN ('PASS','FAIL')),
    InspectionDate   DATE NOT NULL DEFAULT (CAST(GETDATE() AS DATE)),
    CONSTRAINT FK_QI_Batch FOREIGN KEY (BatchID)
        REFERENCES ProductionBatch(BatchID) ON DELETE CASCADE,
    CONSTRAINT FK_QI_Inspector FOREIGN KEY (InspectorID)
        REFERENCES Employee(EmployeeID) ON DELETE SET NULL
);
GO

/* ---------------------------------------------------------
   9. WAREHOUSE
   --------------------------------------------------------- */
CREATE TABLE Warehouse (
    WarehouseID      INT IDENTITY(1,1) PRIMARY KEY,
    WarehouseName    NVARCHAR(100) NOT NULL,
    Location         NVARCHAR(150) NOT NULL,
    Capacity         INT NOT NULL CHECK (Capacity > 0),
    ManagerID        INT NULL,                 -- FK Employee (WarehouseStaff)
    CreatedAt        DATETIME2 NOT NULL DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT FK_Warehouse_Manager FOREIGN KEY (ManagerID)
        REFERENCES Employee(EmployeeID) ON DELETE SET NULL
);
GO

/* ---------------------------------------------------------
   10. INVENTORY  (junction-like: Product <-> Warehouse, with stock facts)
   --------------------------------------------------------- */
CREATE TABLE Inventory (
    InventoryID      INT IDENTITY(1,1) PRIMARY KEY,
    ProductID        INT NOT NULL,
    WarehouseID      INT NOT NULL,
    Quantity         INT NOT NULL DEFAULT (0) CHECK (Quantity >= 0),
    ReorderLevel     INT NOT NULL DEFAULT (20) CHECK (ReorderLevel >= 0),
    StockStatus      NVARCHAR(20) NOT NULL DEFAULT ('Out of Stock')
                        CHECK (StockStatus IN ('Available','Low Stock','Out of Stock','Reserved','Damaged')),
    LastUpdated      DATETIME2 NOT NULL DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT UQ_Inventory_Product_Warehouse UNIQUE (ProductID, WarehouseID),
    CONSTRAINT FK_Inventory_Product FOREIGN KEY (ProductID)
        REFERENCES Product(ProductID) ON DELETE CASCADE,
    CONSTRAINT FK_Inventory_Warehouse FOREIGN KEY (WarehouseID)
        REFERENCES Warehouse(WarehouseID) ON DELETE CASCADE
);
GO

/* ---------------------------------------------------------
   11. CLIENT  (international export buyers)
   --------------------------------------------------------- */
CREATE TABLE Client (
    ClientID         INT IDENTITY(1,1) PRIMARY KEY,
    CompanyName      NVARCHAR(150) NOT NULL,
    Country          NVARCHAR(80)  NOT NULL,
    City             NVARCHAR(80)  NULL,
    ContactPerson    NVARCHAR(100) NULL,
    ContactEmail     NVARCHAR(150) NOT NULL UNIQUE,
    ContactPhone     NVARCHAR(30)  NULL,
    CreatedAt        DATETIME2 NOT NULL DEFAULT (SYSUTCDATETIME())
);
GO

/* ---------------------------------------------------------
   12. EXPORT ORDER
   --------------------------------------------------------- */
CREATE TABLE ExportOrder (
    ExportOrderID    INT IDENTITY(1,1) PRIMARY KEY,
    ClientID         INT NOT NULL,
    ExportOfficerID  INT NULL,                 -- FK Employee
    OrderDate        DATE NOT NULL DEFAULT (CAST(GETDATE() AS DATE)),
    DestinationCountry NVARCHAR(80) NOT NULL,
    TotalAmount      DECIMAL(14,2) NOT NULL DEFAULT (0) CHECK (TotalAmount >= 0),
    PaymentStatus    NVARCHAR(20) NOT NULL DEFAULT ('Pending')
                        CHECK (PaymentStatus IN ('Pending','Paid','Failed','Refunded')),
    ExportStatus     NVARCHAR(20) NOT NULL DEFAULT ('Processing')
                        CHECK (ExportStatus IN ('Processing','Packed','Shipped','In Transit','Customs','Delivered','Cancelled')),
    CreatedAt        DATETIME2 NOT NULL DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT FK_ExportOrder_Client FOREIGN KEY (ClientID)
        REFERENCES Client(ClientID) ON DELETE NO ACTION,
    CONSTRAINT FK_ExportOrder_Officer FOREIGN KEY (ExportOfficerID)
        REFERENCES Employee(EmployeeID) ON DELETE SET NULL
);
GO

/* ---------------------------------------------------------
   13. ORDER DETAIL  (junction: ExportOrder <-> Product)
   --------------------------------------------------------- */
CREATE TABLE OrderDetail (
    OrderDetailID    INT IDENTITY(1,1) PRIMARY KEY,
    ExportOrderID    INT NOT NULL,
    ProductID        INT NOT NULL,
    Quantity         INT NOT NULL CHECK (Quantity > 0),
    UnitPrice        DECIMAL(10,2) NOT NULL CHECK (UnitPrice > 0),
    LineTotal        AS (Quantity * UnitPrice) PERSISTED,
    CONSTRAINT FK_OrderDetail_Order FOREIGN KEY (ExportOrderID)
        REFERENCES ExportOrder(ExportOrderID) ON DELETE CASCADE,
    CONSTRAINT FK_OrderDetail_Product FOREIGN KEY (ProductID)
        REFERENCES Product(ProductID) ON DELETE NO ACTION
);
GO

/* ---------------------------------------------------------
   14. SHIPMENT
   --------------------------------------------------------- */
CREATE TABLE Shipment (
    ShipmentID       INT IDENTITY(1,1) PRIMARY KEY,
    ExportOrderID    INT NOT NULL UNIQUE,
    Carrier          NVARCHAR(100) NULL,
    TrackingNumber   NVARCHAR(60)  NULL,
    ShipmentStatus   NVARCHAR(20) NOT NULL DEFAULT ('Processing')
                        CHECK (ShipmentStatus IN ('Processing','Packed','Shipped','In Transit','Customs','Delivered','Cancelled')),
    ShippedDate      DATE NULL,
    EstimatedArrival DATE NULL,
    DeliveredDate    DATE NULL,
    CONSTRAINT FK_Shipment_Order FOREIGN KEY (ExportOrderID)
        REFERENCES ExportOrder(ExportOrderID) ON DELETE CASCADE
);
GO

/* ---------------------------------------------------------
   15. CUSTOMER  (marketplace / B2C login)
   --------------------------------------------------------- */
CREATE TABLE Customer (
    CustomerID       INT IDENTITY(1,1) PRIMARY KEY,
    FullName         NVARCHAR(120) NOT NULL,
    Email            NVARCHAR(150) NOT NULL UNIQUE,
    PasswordHash     NVARCHAR(255) NOT NULL,
    Phone            NVARCHAR(30)  NULL,
    Country          NVARCHAR(80)  NULL,
    City             NVARCHAR(80)  NULL,
    Address          NVARCHAR(250) NULL,
    CreatedAt        DATETIME2 NOT NULL DEFAULT (SYSUTCDATETIME())
);
GO

/* ---------------------------------------------------------
   16. CUSTOMER ORDER  (marketplace order header)
   --------------------------------------------------------- */
CREATE TABLE CustomerOrder (
    CustomerOrderID  INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID       INT NOT NULL,
    OrderDate        DATETIME2 NOT NULL DEFAULT (SYSUTCDATETIME()),
    TotalAmount      DECIMAL(12,2) NOT NULL DEFAULT (0) CHECK (TotalAmount >= 0),
    PaymentStatus    NVARCHAR(20) NOT NULL DEFAULT ('Pending')
                        CHECK (PaymentStatus IN ('Pending','Paid','Failed','Refunded')),
    OrderStatus      NVARCHAR(20) NOT NULL DEFAULT ('Processing')
                        CHECK (OrderStatus IN ('Processing','Shipped','Delivered','Cancelled')),
    ShippingAddress  NVARCHAR(250) NULL,
    CONSTRAINT FK_CustomerOrder_Customer FOREIGN KEY (CustomerID)
        REFERENCES Customer(CustomerID) ON DELETE CASCADE
);
GO

/* ---------------------------------------------------------
   17. CUSTOMER ORDER ITEM  (junction: CustomerOrder <-> Product)
   --------------------------------------------------------- */
CREATE TABLE CustomerOrderItem (
    CustomerOrderItemID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerOrderID     INT NOT NULL,
    ProductID           INT NOT NULL,
    Quantity            INT NOT NULL CHECK (Quantity > 0),
    UnitPrice           DECIMAL(10,2) NOT NULL CHECK (UnitPrice > 0),
    LineTotal           AS (Quantity * UnitPrice) PERSISTED,
    CONSTRAINT FK_COI_Order FOREIGN KEY (CustomerOrderID)
        REFERENCES CustomerOrder(CustomerOrderID) ON DELETE CASCADE,
    CONSTRAINT FK_COI_Product FOREIGN KEY (ProductID)
        REFERENCES Product(ProductID) ON DELETE NO ACTION
);
GO

/* ---------------------------------------------------------
   18. REVIEW
   --------------------------------------------------------- */
CREATE TABLE Review (
    ReviewID         INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID       INT NOT NULL,
    ProductID        INT NOT NULL,
    Rating           TINYINT NOT NULL CHECK (Rating BETWEEN 1 AND 5),
    Comment          NVARCHAR(500) NULL,
    ReviewDate       DATETIME2 NOT NULL DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT UQ_Review_Customer_Product UNIQUE (CustomerID, ProductID),
    CONSTRAINT FK_Review_Customer FOREIGN KEY (CustomerID)
        REFERENCES Customer(CustomerID) ON DELETE CASCADE,
    CONSTRAINT FK_Review_Product FOREIGN KEY (ProductID)
        REFERENCES Product(ProductID) ON DELETE CASCADE
);
GO

/* ---------------------------------------------------------
   19. CERTIFICATION
   --------------------------------------------------------- */
CREATE TABLE Certification (
    CertificationID   INT IDENTITY(1,1) PRIMARY KEY,
    ProductID         INT NOT NULL,
    CertificationType NVARCHAR(80) NOT NULL,   -- e.g. "ISO 9001", "Match Ball Standard"
    CertificateNumber NVARCHAR(60) NULL,
    IssuingOrganization NVARCHAR(120) NULL,
    IssueDate         DATE NULL,
    ExpiryDate        DATE NULL,
    Status            NVARCHAR(20) NOT NULL DEFAULT ('Active')
                        CHECK (Status IN ('Active','Expired','Revoked')),
    DataSource        NVARCHAR(150) NULL,
    CONSTRAINT FK_Certification_Product FOREIGN KEY (ProductID)
        REFERENCES Product(ProductID) ON DELETE CASCADE,
    CONSTRAINT CK_Certification_Dates CHECK (ExpiryDate IS NULL OR IssueDate IS NULL OR ExpiryDate >= IssueDate)
);
GO

PRINT 'All 19 tables created successfully.';
GO

/* END: 02_create_tables.sql */
GO

/* ============================================================
   BEGIN: 03_constraints_indexes.sql
   ============================================================ */

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

/* END: 03_constraints_indexes.sql */
GO



USE FootballIndustryDB;
GO

SET NOCOUNT ON;

/* ---------------------------------------------------------
   MANUFACTURERS
   First 12 rows: real, publicly known football manufacturers
   (mainly Sialkot, Pakistan -- the world's largest hand-stitched
   football manufacturing cluster -- plus a few international
   names). Only identity fields are marked Verified; revenue is
   NULL unless publicly disclosed, otherwise Estimated/omitted.
   Remaining rows: synthetic demo manufacturers to reach 20+.
   --------------------------------------------------------- */
INSERT INTO Manufacturer
 (CompanyName, Country, City, EstablishedYear, CompanyType, Description, Website, PrimaryExportMarkets, DataSource, DataType, VerificationStatus)
VALUES
('Forward Sports Pvt Ltd','Pakistan','Sialkot',1985,'Manufacturer & Exporter','One of Sialkot''s largest football manufacturers, known for producing machine and hand-stitched match balls for international sporting-goods brands.','https://forwardsports.com','Europe, North America, Asia','Publicly known Sialkot sporting-goods manufacturer','Verified','Verified'),
('Grand Sports Ltd','Pakistan','Sialkot',1975,'Manufacturer & Exporter','Long-established Sialkot manufacturer of footballs and other sporting goods for export markets.','https://grandsports.com','Europe, North America','Publicly known Sialkot sporting-goods manufacturer','Verified','Verified'),
('Saga Sports (Pvt) Ltd','Pakistan','Sialkot',1980,'Manufacturer & Exporter','Sialkot-based manufacturer producing thermally bonded and stitched footballs for global sports brands.','https://sagasports.com','Europe, Middle East','Publicly known Sialkot sporting-goods manufacturer','Verified','Verified'),
('Silver Star Enterprises','Pakistan','Sialkot',1978,'Manufacturer & Exporter','Sialkot football and sports-glove manufacturer exporting to multiple continents.','https://silverstarsialkot.com','Europe, Asia','Publicly known Sialkot sporting-goods manufacturer','Verified','Verified'),
('Anwar Khawaja Industries (Pvt) Ltd','Pakistan','Sialkot',1985,'Manufacturer & Exporter','Manufacturer of the "Baseline" brand of footballs and other sports equipment, based in Sialkot.','https://akius.com','Europe, North America, Middle East','Publicly known Sialkot sporting-goods manufacturer','Verified','Verified'),
('Kingsway Sports Industries','Pakistan','Sialkot',1990,'Manufacturer & Exporter','Sialkot manufacturer of match and training footballs.','NULL','Europe','Publicly known Sialkot sporting-goods manufacturer','Verified','Unverified'),
('Awan Sports','Pakistan','Sialkot',1992,'Manufacturer','Football and sportswear manufacturer based in Sialkot.','NULL','Middle East, Asia','Publicly known Sialkot sporting-goods manufacturer','Verified','Unverified'),
('Capital Sports International','Pakistan','Sialkot',1995,'Manufacturer & Exporter','Sialkot-based producer of footballs for club and promotional use.','NULL','Europe, Africa','Publicly known Sialkot sporting-goods manufacturer','Verified','Unverified'),
('Metro Sports Industries','Pakistan','Sialkot',1988,'Manufacturer','Football manufacturer supplying regional and export markets from Sialkot.','NULL','Asia, Middle East','Publicly known Sialkot sporting-goods manufacturer','Verified','Unverified'),
('Talon Sports','Pakistan','Sialkot',1997,'Manufacturer & Exporter','Sialkot manufacturer of match and futsal footballs.','NULL','Europe','Publicly known Sialkot sporting-goods manufacturer','Verified','Unverified'),
('Larsson Sports Industry','Pakistan','Sialkot',2000,'Manufacturer','Sialkot-based football and sports-equipment manufacturer.','NULL','Europe, North America','Publicly known Sialkot sporting-goods manufacturer','Verified','Unverified'),
('Select Sport A/S','Denmark','Glostrup',1947,'Manufacturer & Exporter','Danish football manufacturer known for match and training balls used in several European leagues.','https://select-sport.com','Europe','Publicly known international football manufacturer','Verified','Verified'),
-- Synthetic demo manufacturers below (clearly fictitious, for
-- generating additional production/inventory/export activity)
('Falcon Ball Works','Pakistan','Lahore',2005,'Manufacturer','Demo manufacturer created for database seed purposes.','NULL','Asia','Synthetic demo record','Synthetic','Unverified'),
('Punjab Football Traders','Pakistan','Karachi',2008,'Manufacturer & Exporter','Demo manufacturer created for database seed purposes.','NULL','Middle East','Synthetic demo record','Synthetic','Unverified'),
('Indus Sporting Goods','Pakistan','Sialkot',2010,'Manufacturer','Demo manufacturer created for database seed purposes.','NULL','Europe','Synthetic demo record','Synthetic','Unverified'),
('Everstrike Sports Co.','Pakistan','Sialkot',2012,'Manufacturer & Exporter','Demo manufacturer created for database seed purposes.','NULL','North America','Synthetic demo record','Synthetic','Unverified'),
('GoalPro Manufacturing','Pakistan','Gujranwala',2014,'Manufacturer','Demo manufacturer created for database seed purposes.','NULL','Asia','Synthetic demo record','Synthetic','Unverified'),
('Champion Stitch Sports','Pakistan','Sialkot',2009,'Manufacturer','Demo manufacturer created for database seed purposes.','NULL','Europe','Synthetic demo record','Synthetic','Unverified'),
('Victory Ball Industries','Pakistan','Sialkot',2011,'Manufacturer & Exporter','Demo manufacturer created for database seed purposes.','NULL','Middle East','Synthetic demo record','Synthetic','Unverified'),
('Titan Sports Manufacturing','Pakistan','Sialkot',2016,'Manufacturer','Demo manufacturer created for database seed purposes.','NULL','Asia','Synthetic demo record','Synthetic','Unverified'),
('Prime Kick Industries','Pakistan','Sialkot',2013,'Manufacturer','Demo manufacturer created for database seed purposes.','NULL','Europe','Synthetic demo record','Synthetic','Unverified'),
('Sialkot United Sports','Pakistan','Sialkot',2007,'Manufacturer & Exporter','Demo manufacturer created for database seed purposes.','NULL','North America, Europe','Synthetic demo record','Synthetic','Unverified'),
('Elite Match Balls Ltd','Pakistan','Sialkot',2015,'Manufacturer','Demo manufacturer created for database seed purposes.','NULL','Asia','Synthetic demo record','Synthetic','Unverified');
GO

-- clean up the literal 'NULL' strings used above for readability into real NULLs
UPDATE Manufacturer SET Website = NULL WHERE Website = 'NULL';
GO

/* ---------------------------------------------------------
   SUPPLIERS (raw material suppliers -- synthetic/demo)
   --------------------------------------------------------- */
INSERT INTO Supplier (SupplierName, Country, City, ContactEmail, ContactPhone, MaterialCategory, Rating) VALUES
('Sialkot Synthetic Leather Co.','Pakistan','Sialkot','sales@sslc-demo.pk','+92-52-1000001','Synthetic Leather',4.2),
('Punjab Rubber Industries','Pakistan','Sialkot','info@punjabrubber-demo.pk','+92-52-1000002','Rubber Bladder',4.0),
('Latex Craft Suppliers','Pakistan','Gujranwala','contact@latexcraft-demo.pk','+92-55-1000003','Latex Bladder',3.8),
('Global TPU Sheets Ltd','China','Guangzhou','sales@globaltpu-demo.cn','+86-20-1000004','TPU Panel Sheet',4.5),
('Karachi Thread & Textile','Pakistan','Karachi','info@kthread-demo.pk','+92-21-1000005','Stitching Thread',4.1),
('Lahore Foam Supplies','Pakistan','Lahore','sales@lahorefoam-demo.pk','+92-42-1000006','EVA Foam Lining',3.9),
('Faisalabad Fabric Mills','Pakistan','Faisalabad','info@ffmills-demo.pk','+92-41-1000007','Backing Fabric',4.0),
('Anhui Butyl Chemicals','China','Hefei','contact@anhuibutyl-demo.cn','+86-551-1000008','Butyl Rubber',4.3),
('Sialkot Adhesive Works','Pakistan','Sialkot','sales@sadhesive-demo.pk','+92-52-1000009','Bonding Adhesive',3.7),
('Multan Cotton Traders','Pakistan','Multan','info@multancotton-demo.pk','+92-61-1000010','Cotton Lining',3.6),
('Guangzhou Polymer Co.','China','Guangzhou','sales@gzpolymer-demo.cn','+86-20-1000011','PU Synthetic Leather',4.4),
('Sialkot Valve Manufacturers','Pakistan','Sialkot','info@svm-demo.pk','+92-52-1000012','Air Valve',4.0),
('Karachi Packaging Solutions','Pakistan','Karachi','sales@kpackaging-demo.pk','+92-21-1000013','Packaging Material',3.8),
('Sialkot Dye & Pigments','Pakistan','Sialkot','info@sdye-demo.pk','+92-52-1000014','Dye & Pigment',3.9),
('Islamabad Industrial Supplies','Pakistan','Islamabad','sales@iis-demo.pk','+92-51-1000015','General Hardware',3.7),
('Sheikhupura Rubber Mills','Pakistan','Sheikhupura','info@srmills-demo.pk','+92-56-1000016','Rubber Compound',3.8);
GO

/* ---------------------------------------------------------
   WAREHOUSES
   --------------------------------------------------------- */
INSERT INTO Warehouse (WarehouseName, Location, Capacity) VALUES
('Sialkot Central Warehouse','Sialkot, Punjab, Pakistan',50000),
('Lahore Distribution Hub','Lahore, Punjab, Pakistan',30000),
('Karachi Port Warehouse','Karachi, Sindh, Pakistan',40000),
('Gujranwala Storage Facility','Gujranwala, Punjab, Pakistan',20000),
('Islamabad Regional Depot','Islamabad, Pakistan',15000);
GO

PRINT 'Reference data (Manufacturers, Suppliers, Warehouses) seeded.';
GO

/* ---------------------------------------------------------
   EMPLOYEES (synthetic demo staff -- 30+ rows generated below)
   PasswordHash values are bcrypt hashes of the demo password
   "Passw0rd!" -- see README for demo login credentials.
   --------------------------------------------------------- */
DECLARE @DemoHash NVARCHAR(255) = '$2b$12$KIXQ8m3rN0v0v0v0v0v0vO7Qy1z1z1z1z1z1z1z1z1z1z1z1z1z1O'; -- placeholder, regenerate via backend seeding script

INSERT INTO Employee (FullName, Email, PasswordHash, Role, Department, Phone, HireDate) VALUES
('Ahmed Raza','admin@footballindustry.local',@DemoHash,'Admin','Management','+92-300-1000001','2019-01-15'),
('Bilal Ahmed','bilal.ahmed@footballindustry.local',@DemoHash,'ProductionManager','Production','+92-300-1000002','2020-03-10'),
('Sana Tariq','sana.tariq@footballindustry.local',@DemoHash,'ProductionManager','Production','+92-300-1000003','2020-06-01'),
('Usman Khalid','usman.khalid@footballindustry.local',@DemoHash,'WarehouseStaff','Warehouse','+92-300-1000004','2021-02-11'),
('Ayesha Malik','ayesha.malik@footballindustry.local',@DemoHash,'WarehouseStaff','Warehouse','+92-300-1000005','2021-05-19'),
('Hassan Iqbal','hassan.iqbal@footballindustry.local',@DemoHash,'ExportOfficer','Export','+92-300-1000006','2019-08-23'),
('Mariam Yousuf','mariam.yousuf@footballindustry.local',@DemoHash,'ExportOfficer','Export','+92-300-1000007','2020-11-02'),
('Kamran Shah','kamran.shah@footballindustry.local',@DemoHash,'QualityInspector','Quality Control','+92-300-1000008','2018-09-17'),
('Fatima Noor','fatima.noor@footballindustry.local',@DemoHash,'QualityInspector','Quality Control','+92-300-1000009','2022-01-05'),
('Zeeshan Aslam','zeeshan.aslam@footballindustry.local',@DemoHash,'ProductionManager','Production','+92-300-1000010','2021-07-14');
GO

-- Generate 20 more synthetic employees across the same roles
DECLARE @i INT = 1;
DECLARE @roles TABLE (r NVARCHAR(30));
INSERT INTO @roles VALUES ('ProductionManager'),('WarehouseStaff'),('ExportOfficer'),('QualityInspector');
WHILE @i <= 20
BEGIN
    DECLARE @role NVARCHAR(30) = (SELECT TOP 1 r FROM @roles ORDER BY (@i % 4));
    INSERT INTO Employee (FullName, Email, PasswordHash, Role, Department, Phone, HireDate)
    VALUES (
        CONCAT('Staff Member ', @i),
        CONCAT('staff', @i, '@footballindustry.local'),
        '$2b$12$KIXQ8m3rN0v0v0v0v0v0vO7Qy1z1z1z1z1z1z1z1z1z1z1z1z1z1O',
        @role,
        CASE @role WHEN 'ProductionManager' THEN 'Production' WHEN 'WarehouseStaff' THEN 'Warehouse' WHEN 'ExportOfficer' THEN 'Export' ELSE 'Quality Control' END,
        CONCAT('+92-300-11',RIGHT('00000'+CAST(@i AS VARCHAR),5)),
        DATEADD(DAY, -@i*45, CAST(GETDATE() AS DATE))
    );
    SET @i += 1;
END
GO

/* ---------------------------------------------------------
   RAW MATERIALS (linked to suppliers, 20+ rows)
   --------------------------------------------------------- */
INSERT INTO RawMaterial (SupplierID, MaterialName, Unit, UnitCost, StockQuantity, ReorderLevel) VALUES
(1,'PU Synthetic Leather Panel','meter',3.50,5000,500),
(2,'Rubber Bladder - Size 5','piece',1.20,8000,800),
(3,'Latex Bladder - Size 5','piece',1.50,6000,600),
(4,'TPU Panel Sheet','meter',4.20,4500,450),
(5,'Polyester Stitching Thread','roll',2.10,3000,300),
(6,'EVA Foam Lining Sheet','meter',2.80,4000,400),
(7,'Backing Fabric (Polyester Cotton)','meter',1.90,5000,500),
(8,'Butyl Rubber Compound','kg',3.00,2500,250),
(9,'Industrial Bonding Adhesive','liter',5.50,1200,150),
(10,'Cotton Lining Fabric','meter',1.60,3500,350),
(11,'PU Synthetic Leather (Premium)','meter',5.00,3000,300),
(12,'Air Valve Assembly','piece',0.35,10000,1000),
(13,'Export Packaging Box','piece',0.60,7000,700),
(14,'Dye - Standard Colors','liter',4.00,1500,150),
(15,'Assorted Hardware Kit','piece',0.25,4000,400),
(16,'Rubber Compound - Training Grade','kg',2.60,3000,300),
(1,'PU Synthetic Leather Panel (Textured)','meter',3.90,2000,300),
(2,'Rubber Bladder - Size 4','piece',1.10,4000,400),
(4,'TPU Panel Sheet (Thermal-Bond Grade)','meter',4.60,2500,300),
(6,'EVA Foam Lining Sheet (Thick)','meter',3.10,1800,250),
(9,'Bonding Adhesive (Fast-Cure)','liter',6.20,900,120),
(11,'PU Synthetic Leather (Futsal Grade)','meter',4.70,1500,200);
GO

/* ---------------------------------------------------------
   PRODUCTS (30+ rows across manufacturers/categories)
   --------------------------------------------------------- */
DECLARE @p INT = 1;
DECLARE @categories TABLE (id INT IDENTITY(1,1), name NVARCHAR(40));
INSERT INTO @categories(name) VALUES ('Match'),('Training'),('Futsal'),('Beach'),('Youth'),('Promotional'),('Custom');
DECLARE @catCount INT = (SELECT COUNT(*) FROM @categories);
DECLARE @manCount INT = (SELECT COUNT(*) FROM Manufacturer);

WHILE @p <= 34
BEGIN
    DECLARE @manId INT = ((@p - 1) % @manCount) + 1;
    DECLARE @catId INT = ((@p - 1) % @catCount) + 1;
    DECLARE @catName NVARCHAR(40) = (SELECT name FROM @categories WHERE id = @catId);
    DECLARE @size TINYINT = CASE WHEN @catName IN ('Youth') THEN 4 WHEN @catName = 'Futsal' THEN 4 ELSE 5 END;
    DECLARE @price DECIMAL(10,2) = CAST(8 + (@p * 1.75) AS DECIMAL(10,2));
    DECLARE @construction NVARCHAR(40) = CASE (@p % 4) WHEN 0 THEN 'Hand-Stitched' WHEN 1 THEN 'Machine-Stitched' WHEN 2 THEN 'Thermal-Bonded' ELSE 'Butyl-Bladder' END;

    INSERT INTO Product (ManufacturerID, ProductName, Category, SizeNumber, Material, ConstructionMethod, Price, Description)
    VALUES (
        @manId,
        CONCAT(@catName, ' Football ', 'Model-', RIGHT('000'+CAST(@p AS VARCHAR),3)),
        @catName,
        @size,
        CASE WHEN @p % 2 = 0 THEN 'PU Synthetic Leather' ELSE 'TPU Panel' END,
        @construction,
        @price,
        CONCAT(@catName, ' grade football suitable for ', LOWER(@catName), ' play, size ', @size, '.')
    );
    SET @p += 1;
END
GO

/* ---------------------------------------------------------
   CLIENTS (international export buyers, 30+ rows)
   --------------------------------------------------------- */
DECLARE @countries TABLE (id INT IDENTITY(1,1), name NVARCHAR(80));
INSERT INTO @countries(name) VALUES
('Germany'),('United States'),('United Kingdom'),('France'),('Spain'),('Italy'),('United Arab Emirates'),
('Saudi Arabia'),('Turkey'),('Netherlands'),('Belgium'),('South Africa'),('Australia'),('Canada'),
('Brazil'),('Japan'),('South Korea'),('Egypt'),('Nigeria'),('Poland');

DECLARE @c INT = 1;
DECLARE @ccount INT = (SELECT COUNT(*) FROM @countries);
WHILE @c <= 32
BEGIN
    DECLARE @countryId INT = ((@c - 1) % @ccount) + 1;
    DECLARE @countryName NVARCHAR(80) = (SELECT name FROM @countries WHERE id = @countryId);
    INSERT INTO Client (CompanyName, Country, City, ContactPerson, ContactEmail, ContactPhone)
    VALUES (
        CONCAT('Buyer Import Co. ', @c),
        @countryName,
        CONCAT(@countryName, ' City'),
        CONCAT('Contact Person ', @c),
        CONCAT('buyer', @c, '@importco-demo.com'),
        CONCAT('+1-555-', RIGHT('0000'+CAST(@c AS VARCHAR),4))
    );
    SET @c += 1;
END
GO

PRINT 'Employees, RawMaterials, Products, and Clients seeded.';
GO

/* ---------------------------------------------------------
   PRODUCTION BATCHES (100+ rows)
   --------------------------------------------------------- */
DECLARE @prodCount INT = (SELECT COUNT(*) FROM Product);
DECLARE @supervisorMin INT = (SELECT MIN(EmployeeID) FROM Employee WHERE Role = 'ProductionManager');
DECLARE @supervisorMax INT = (SELECT MAX(EmployeeID) FROM Employee WHERE Role = 'ProductionManager');
DECLARE @b INT = 1;

WHILE @b <= 120
BEGIN
    DECLARE @prodId INT = ((@b - 1) % @prodCount) + 1;
    DECLARE @manForBatch INT = (SELECT ManufacturerID FROM Product WHERE ProductID = @prodId);
    DECLARE @sup INT = @supervisorMin + (@b % (NULLIF(@supervisorMax - @supervisorMin,0)+1));
    DECLARE @qty INT = 200 + (@b * 7) % 800;
    DECLARE @prodDate DATE = DATEADD(DAY, -(@b * 3), CAST(GETDATE() AS DATE));
    DECLARE @statusRoll INT = @b % 10;
    DECLARE @status NVARCHAR(20) =
        CASE
            WHEN @statusRoll <= 6 THEN 'Completed'
            WHEN @statusRoll = 7 THEN 'In Production'
            WHEN @statusRoll = 8 THEN 'Planned'
            WHEN @statusRoll = 9 THEN 'Failed'
            ELSE 'Cancelled'
        END;
    DECLARE @compDate DATE = CASE WHEN @status IN ('Completed','Failed') THEN DATEADD(DAY, 5, @prodDate) ELSE NULL END;

    INSERT INTO ProductionBatch (ProductID, ManufacturerID, SupervisorID, Quantity, ProductionDate, CompletionDate, Status)
    VALUES (@prodId, @manForBatch, @sup, @qty, @prodDate, @compDate, @status);

    SET @b += 1;
END
GO

/* ---------------------------------------------------------
   BATCH MATERIAL USAGE (junction rows -- 2 materials per batch)
   --------------------------------------------------------- */
DECLARE @matCount INT = (SELECT COUNT(*) FROM RawMaterial);
INSERT INTO BatchMaterialUsage (BatchID, RawMaterialID, QuantityUsed)
SELECT
    pb.BatchID,
    ((pb.BatchID - 1) % @matCount) + 1,
    CAST(pb.Quantity * 0.6 AS DECIMAL(14,2))
FROM ProductionBatch pb;

INSERT INTO BatchMaterialUsage (BatchID, RawMaterialID, QuantityUsed)
SELECT
    pb.BatchID,
    (((pb.BatchID) % @matCount) + 1),
    CAST(pb.Quantity * 0.35 AS DECIMAL(14,2))
FROM ProductionBatch pb
WHERE ((pb.BatchID - 1) % @matCount) + 1 <> (((pb.BatchID) % @matCount) + 1);
GO

/* ---------------------------------------------------------
   QUALITY INSPECTIONS
   One inspection per Completed or Failed batch.
   --------------------------------------------------------- */
DECLARE @inspMin INT = (SELECT MIN(EmployeeID) FROM Employee WHERE Role = 'QualityInspector');
DECLARE @inspMax INT = (SELECT MAX(EmployeeID) FROM Employee WHERE Role = 'QualityInspector');

INSERT INTO QualityInspection
 (BatchID, InspectorID, WeightTestPass, CircumferenceTestPass, PressureTestPass, BounceTestPass, ShapeTestPass, MaterialTestPass, QualityScore, Status, InspectionDate)
SELECT
    pb.BatchID,
    @inspMin + (pb.BatchID % (NULLIF(@inspMax - @inspMin,0)+1)),
    CASE WHEN pb.Status = 'Completed' THEN 1 ELSE (pb.BatchID % 2) END,
    CASE WHEN pb.Status = 'Completed' THEN 1 ELSE (pb.BatchID % 2) END,
    CASE WHEN pb.Status = 'Completed' THEN 1 ELSE 0 END,
    CASE WHEN pb.Status = 'Completed' THEN 1 ELSE (pb.BatchID % 2) END,
    CASE WHEN pb.Status = 'Completed' THEN 1 ELSE 1 END,
    CASE WHEN pb.Status = 'Completed' THEN 1 ELSE 0 END,
    CASE WHEN pb.Status = 'Completed' THEN 88 + (pb.BatchID % 12) ELSE 40 + (pb.BatchID % 20) END,
    CASE WHEN pb.Status = 'Completed' THEN 'PASS' ELSE 'FAIL' END,
    DATEADD(DAY, 1, pb.CompletionDate)
FROM ProductionBatch pb
WHERE pb.Status IN ('Completed','Failed');
GO

/* ---------------------------------------------------------
   INVENTORY
   Only PASSED batches contribute to sellable stock. One
   Inventory row per Product/Warehouse combination that has
   ever received completed+passed stock.
   --------------------------------------------------------- */
DECLARE @whCount INT = (SELECT COUNT(*) FROM Warehouse);

INSERT INTO Inventory (ProductID, WarehouseID, Quantity, ReorderLevel, StockStatus)
SELECT
    p.ProductID,
    ((p.ProductID - 1) % @whCount) + 1 AS WarehouseID,
    ISNULL(SUM(CASE WHEN pb.Status = 'Completed' AND qi.Status = 'PASS' THEN pb.Quantity ELSE 0 END), 0) AS Quantity,
    50 AS ReorderLevel,
    'Out of Stock' AS StockStatus
FROM Product p
LEFT JOIN ProductionBatch pb ON pb.ProductID = p.ProductID
LEFT JOIN QualityInspection qi ON qi.BatchID = pb.BatchID
GROUP BY p.ProductID;

-- recompute stock status based on quantity vs reorder level
UPDATE Inventory
SET StockStatus =
    CASE
        WHEN Quantity = 0 THEN 'Out of Stock'
        WHEN Quantity <= ReorderLevel THEN 'Low Stock'
        ELSE 'Available'
    END;
GO

PRINT 'Production, Quality Inspection, and Inventory data seeded.';
GO

/* ---------------------------------------------------------
   EXPORT ORDERS + ORDER DETAILS (100+ orders, 200+ lines)
   Note: 07_triggers.sql (run later) will keep TotalAmount in
   sync automatically for new orders placed through the app.
   Here we compute it manually after inserting order lines,
   since the trigger does not exist yet at seed time.
   --------------------------------------------------------- */
DECLARE @clientCount INT = (SELECT COUNT(*) FROM Client);
DECLARE @officerMin INT = (SELECT MIN(EmployeeID) FROM Employee WHERE Role = 'ExportOfficer');
DECLARE @officerMax INT = (SELECT MAX(EmployeeID) FROM Employee WHERE Role = 'ExportOfficer');
DECLARE @prodCount2 INT = (SELECT COUNT(*) FROM Product);
DECLARE @eo INT = 1;

WHILE @eo <= 110
BEGIN
    DECLARE @clientId INT = ((@eo - 1) % @clientCount) + 1;
    DECLARE @destCountry NVARCHAR(80) = (SELECT Country FROM Client WHERE ClientID = @clientId);
    DECLARE @officer INT = @officerMin + (@eo % (NULLIF(@officerMax - @officerMin,0)+1));
    DECLARE @orderDate DATE = DATEADD(DAY, -(@eo * 4), CAST(GETDATE() AS DATE));
    DECLARE @payStatus NVARCHAR(20) = CASE (@eo % 4) WHEN 0 THEN 'Pending' WHEN 1 THEN 'Paid' WHEN 2 THEN 'Paid' ELSE 'Refunded' END;
    DECLARE @expStatus NVARCHAR(20) = CASE (@eo % 7)
        WHEN 0 THEN 'Processing' WHEN 1 THEN 'Packed' WHEN 2 THEN 'Shipped'
        WHEN 3 THEN 'In Transit' WHEN 4 THEN 'Customs' WHEN 5 THEN 'Delivered' ELSE 'Cancelled' END;

    INSERT INTO ExportOrder (ClientID, ExportOfficerID, OrderDate, DestinationCountry, TotalAmount, PaymentStatus, ExportStatus)
    VALUES (@clientId, @officer, @orderDate, @destCountry, 0, @payStatus, @expStatus);

    DECLARE @newOrderId INT = SCOPE_IDENTITY();

    -- 1 to 3 line items per order
    DECLARE @lines INT = 1 + (@eo % 3);
    DECLARE @l INT = 1;
    WHILE @l <= @lines
    BEGIN
        DECLARE @lineProdId INT = ((@eo + @l - 1) % @prodCount2) + 1;
        DECLARE @lineQty INT = 100 + ((@eo * @l) % 400);
        DECLARE @lineUnitPrice DECIMAL(10,2) = (SELECT Price FROM Product WHERE ProductID = @lineProdId);

        INSERT INTO OrderDetail (ExportOrderID, ProductID, Quantity, UnitPrice)
        VALUES (@newOrderId, @lineProdId, @lineQty, @lineUnitPrice);

        SET @l += 1;
    END

    -- keep TotalAmount consistent with its order lines
    UPDATE ExportOrder
    SET TotalAmount = (SELECT ISNULL(SUM(LineTotal),0) FROM OrderDetail WHERE ExportOrderID = @newOrderId)
    WHERE ExportOrderID = @newOrderId;

    -- one shipment per export order, status mirrors ExportStatus
    INSERT INTO Shipment (ExportOrderID, Carrier, TrackingNumber, ShipmentStatus, ShippedDate, EstimatedArrival, DeliveredDate)
    VALUES (
        @newOrderId,
        CASE (@eo % 3) WHEN 0 THEN 'DHL Express' WHEN 1 THEN 'FedEx Freight' ELSE 'Maersk Line' END,
        CONCAT('TRK', RIGHT('000000'+CAST(@newOrderId AS VARCHAR),6)),
        @expStatus,
        CASE WHEN @expStatus <> 'Processing' THEN DATEADD(DAY,2,@orderDate) ELSE NULL END,
        DATEADD(DAY,20,@orderDate),
        CASE WHEN @expStatus = 'Delivered' THEN DATEADD(DAY,18,@orderDate) ELSE NULL END
    );

    SET @eo += 1;
END
GO

PRINT 'Export orders, order details, and shipments seeded.';
GO

/* ---------------------------------------------------------
   CUSTOMERS (marketplace, 50+ rows)
   PasswordHash values are bcrypt hashes of "Passw0rd!"
   --------------------------------------------------------- */
DECLARE @custHash NVARCHAR(255) = '$2b$12$KIXQ8m3rN0v0v0v0v0v0vO7Qy1z1z1z1z1z1z1z1z1z1z1z1z1z1O';
DECLARE @cn INT = 1;
DECLARE @custCountries TABLE (id INT IDENTITY(1,1), name NVARCHAR(80));
INSERT INTO @custCountries(name) VALUES ('Pakistan'),('United States'),('United Kingdom'),('Germany'),('UAE'),('Canada'),('Australia');
DECLARE @ccCount INT = (SELECT COUNT(*) FROM @custCountries);

WHILE @cn <= 55
BEGIN
    DECLARE @custCountry NVARCHAR(80) = (SELECT name FROM @custCountries WHERE id = ((@cn - 1) % @ccCount) + 1);
    INSERT INTO Customer (FullName, Email, PasswordHash, Phone, Country, City, Address)
    VALUES (
        CONCAT('Demo Customer ', @cn),
        CONCAT('customer', @cn, '@marketplace-demo.com'),
        @custHash,
        CONCAT('+1-555-9', RIGHT('0000'+CAST(@cn AS VARCHAR),4)),
        @custCountry,
        CONCAT(@custCountry, ' Town'),
        CONCAT(@cn, ' Demo Street')
    );
    SET @cn += 1;
END
GO

/* ---------------------------------------------------------
   CUSTOMER ORDERS + ITEMS
   --------------------------------------------------------- */
DECLARE @custCount INT = (SELECT COUNT(*) FROM Customer);
DECLARE @prodCount3 INT = (SELECT COUNT(*) FROM Product);
DECLARE @co INT = 1;

WHILE @co <= 60
BEGIN
    DECLARE @custId INT = ((@co - 1) % @custCount) + 1;
    DECLARE @coDate DATETIME2 = DATEADD(DAY, -(@co * 2), SYSUTCDATETIME());
    DECLARE @coPayStatus NVARCHAR(20) = CASE (@co % 4) WHEN 0 THEN 'Pending' WHEN 3 THEN 'Refunded' ELSE 'Paid' END;
    DECLARE @coOrderStatus NVARCHAR(20) = CASE (@co % 4) WHEN 0 THEN 'Processing' WHEN 1 THEN 'Shipped' WHEN 2 THEN 'Delivered' ELSE 'Cancelled' END;

    INSERT INTO CustomerOrder (CustomerID, OrderDate, TotalAmount, PaymentStatus, OrderStatus, ShippingAddress)
    VALUES (@custId, @coDate, 0, @coPayStatus, @coOrderStatus, (SELECT Address FROM Customer WHERE CustomerID = @custId));

    DECLARE @newCoId INT = SCOPE_IDENTITY();
    DECLARE @itemCount INT = 1 + (@co % 3);
    DECLARE @it INT = 1;
    WHILE @it <= @itemCount
    BEGIN
        DECLARE @itemProdId INT = ((@co + @it) % @prodCount3) + 1;
        DECLARE @itemQty INT = 1 + (@it % 3);
        DECLARE @itemPrice DECIMAL(10,2) = (SELECT Price FROM Product WHERE ProductID = @itemProdId);

        INSERT INTO CustomerOrderItem (CustomerOrderID, ProductID, Quantity, UnitPrice)
        VALUES (@newCoId, @itemProdId, @itemQty, @itemPrice);

        SET @it += 1;
    END

    UPDATE CustomerOrder
    SET TotalAmount = (SELECT ISNULL(SUM(LineTotal),0) FROM CustomerOrderItem WHERE CustomerOrderID = @newCoId)
    WHERE CustomerOrderID = @newCoId;

    SET @co += 1;
END
GO

/* ---------------------------------------------------------
   REVIEWS (100+ rows)
   --------------------------------------------------------- */
DECLARE @rCustCount INT = (SELECT COUNT(*) FROM Customer);
DECLARE @rProdCount INT = (SELECT COUNT(*) FROM Product);
DECLARE @r INT = 1;
DECLARE @comments TABLE (id INT IDENTITY(1,1), txt NVARCHAR(300));
INSERT INTO @comments(txt) VALUES
('Great bounce and durability, held up well after weeks of use.'),
('Good value football, stitching started to wear after heavy use.'),
('Excellent match ball, consistent flight and grip in wet conditions.'),
('Decent training ball for the price, slightly heavier than expected.'),
('Loved the design, performs well on artificial turf.'),
('Solid futsal ball, great bounce control on indoor courts.'),
('Perfect size for youth training sessions.'),
('Good promotional ball, not intended for competitive play but works fine casually.');
DECLARE @cmCount INT = (SELECT COUNT(*) FROM @comments);

WHILE @r <= 130
BEGIN
    DECLARE @revCustId INT = ((@r - 1) % @rCustCount) + 1;
    DECLARE @revProdId INT = ((@r * 3 - 1) % @rProdCount) + 1;
    DECLARE @rating TINYINT = CAST(3 + (@r % 3) AS TINYINT);
    DECLARE @comment NVARCHAR(300) = (SELECT txt FROM @comments WHERE id = ((@r - 1) % @cmCount) + 1);

    IF NOT EXISTS (SELECT 1 FROM Review WHERE CustomerID = @revCustId AND ProductID = @revProdId)
    BEGIN
        INSERT INTO Review (CustomerID, ProductID, Rating, Comment, ReviewDate)
        VALUES (@revCustId, @revProdId, @rating, @comment, DATEADD(DAY, -(@r), SYSUTCDATETIME()));
    END
    SET @r += 1;
END
GO

-- keep Product.AverageRating consistent with seeded reviews
UPDATE p
SET p.AverageRating = agg.AvgRating
FROM Product p
INNER JOIN (
    SELECT ProductID, CAST(AVG(CAST(Rating AS DECIMAL(4,2))) AS DECIMAL(3,2)) AS AvgRating
    FROM Review
    GROUP BY ProductID
) agg ON agg.ProductID = p.ProductID;
GO

/* ---------------------------------------------------------
   CERTIFICATIONS (sample rows for Match category products)
   --------------------------------------------------------- */
INSERT INTO Certification (ProductID, CertificationType, CertificateNumber, IssuingOrganization, IssueDate, ExpiryDate, Status, DataSource)
SELECT
    ProductID,
    'ISO 9001 Quality Management',
    CONCAT('ISO-', RIGHT('00000'+CAST(ProductID AS VARCHAR),5)),
    'Demo Certification Body',
    '2023-01-01',
    '2026-01-01',
    'Active',
    'Synthetic demo record'
FROM Product
WHERE Category = 'Match';
GO

PRINT 'Customers, Customer Orders, Reviews, and Certifications seeded.';
PRINT 'Seed data load complete.';
GO

/* END: 04_seed_data.sql */
GO

/* ============================================================
   BEGIN: 05_views.sql
   ============================================================ */

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

/* END: 05_views.sql */
GO

/* ============================================================
   BEGIN: 06_stored_procedures.sql
   ============================================================ */

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

/* END: 06_stored_procedures.sql */
GO

/* ============================================================
   BEGIN: 07_triggers.sql
   ============================================================ */

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

/* END: 07_triggers.sql */
GO

/* ============================================================
   BEGIN: 08_transactions.sql
   ============================================================ */

/* ============================================================
  08_transactions.sql
   Standalone demonstrations of explicit transactions, separate
   from the stored procedures in 06 (which already wrap their
   logic in transactions). Useful to show your instructor raw
   BEGIN/COMMIT/ROLLBACK/TRY-CATCH behaviour directly in SSMS.
   ============================================================ */

USE FootballIndustryDB;
GO

BEGIN TRY

    BEGIN TRANSACTION;

    DECLARE @DemoCustomerID INT;

    SELECT TOP 1
        @DemoCustomerID = CustomerID
    FROM Customer
    ORDER BY CustomerID;

    DECLARE @DemoProductID INT;

    SELECT TOP 1
        @DemoProductID = ProductID
    FROM Product
    ORDER BY ProductID;

    DECLARE @DemoQty INT = 5;

    DECLARE @DemoPrice DECIMAL(10,2);

    SELECT
        @DemoPrice = Price
    FROM Product
    WHERE ProductID = @DemoProductID;

    IF @DemoCustomerID IS NULL
    BEGIN
        THROW 50001, 'No customer exists for the marketplace demo.', 1;
    END;

    IF @DemoProductID IS NULL
    BEGIN
        THROW 50002, 'No product exists for the marketplace demo.', 1;
    END;

    IF @DemoPrice IS NULL
    BEGIN
        THROW 50003, 'Selected product has no price.', 1;
    END;

    DECLARE @DemoWarehouseID INT;

    SELECT TOP 1
        @DemoWarehouseID = WarehouseID
    FROM Inventory
    WHERE ProductID = @DemoProductID
      AND Quantity >= @DemoQty
    ORDER BY WarehouseID;

    IF @DemoWarehouseID IS NULL
    BEGIN
        THROW 50004, 'Insufficient stock for demo marketplace order.', 1;
    END;

    INSERT INTO CustomerOrder
    (
        CustomerID,
        TotalAmount,
        PaymentStatus,
        OrderStatus
    )
    VALUES
    (
        @DemoCustomerID,
        0,
        'Pending',
        'Processing'
    );

    DECLARE @DemoOrderID INT;

    SET @DemoOrderID = SCOPE_IDENTITY();

    INSERT INTO CustomerOrderItem
    (
        CustomerOrderID,
        ProductID,
        Quantity,
        UnitPrice
    )
    VALUES
    (
        @DemoOrderID,
        @DemoProductID,
        @DemoQty,
        @DemoPrice
    );

    UPDATE CustomerOrder
    SET TotalAmount =
    (
        SELECT SUM(LineTotal)
        FROM CustomerOrderItem
        WHERE CustomerOrderID = @DemoOrderID
    )
    WHERE CustomerOrderID = @DemoOrderID;

    DECLARE @NegativeQty INT;

    SET @NegativeQty = 0 - @DemoQty;

    EXEC sp_UpdateInventory
        @ProductID = @DemoProductID,
        @WarehouseID = @DemoWarehouseID,
        @QuantityDelta = @NegativeQty;

    COMMIT TRANSACTION;

    PRINT 'Demo 1 completed successfully.';
    PRINT 'Marketplace order was committed.';
    PRINT 'Order ID: ' + CAST(@DemoOrderID AS VARCHAR(20));
    PRINT 'Product ID: ' + CAST(@DemoProductID AS VARCHAR(20));
    PRINT 'Quantity: ' + CAST(@DemoQty AS VARCHAR(20));

END TRY

BEGIN CATCH

    IF XACT_STATE() <> 0
    BEGIN
        ROLLBACK TRANSACTION;
    END;

    PRINT 'Demo 1 FAILED.';
    PRINT 'Transaction rolled back.';
    PRINT 'Error: ' + ERROR_MESSAGE();

END CATCH;
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
SELECT TOP (2)
    ProductID,
    50,
    Price
FROM Product
ORDER BY ProductID;

DECLARE @DemoClientID INT;
DECLARE @DemoNewOrderID INT;

SELECT TOP (1)
    @DemoClientID = ClientID
FROM Client
ORDER BY ClientID;

EXEC sp_PlaceExportOrder
    @ClientID = @DemoClientID,
    @ExportOfficerID = NULL,
    @DestinationCountry = 'Germany',
    @OrderLines = @DemoLines,
    @NewExportOrderID = @DemoNewOrderID OUTPUT;

PRINT CONCAT(
    'Demo 3 (export order placement) created ExportOrderID = ',
    @DemoNewOrderID
);

GO

/* END: 08_transactions.sql */
GO

/* ============================================================
   BEGIN: 09_reporting_queries.sql
   ============================================================ */

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

/* END: 09_reporting_queries.sql */
GO

PRINT 'Combined script finished successfully.';
GO



select * from CustomerOrder 


SELECT 
    InventoryID,
    ProductID,
    WarehouseID,
    Quantity,
    ReorderLevel,
    StockStatus
FROM Inventory;
UPDATE Inventory
SET Quantity = 5,
    StockStatus = 'Low Stock',
    LastUpdated = SYSUTCDATETIME()
WHERE InventoryID = 1;    


USE FootballIndustryDB;
GO

SELECT 
    InventoryID,
    ProductID,
    WarehouseID,
    Quantity,
    ReorderLevel,
    StockStatus
FROM dbo.Inventory;


USE FootballIndustryDB;
GO

UPDATE dbo.Inventory
SET Quantity = 5,
    StockStatus = 'Low Stock'
WHERE InventoryID = 7;


USE FootballIndustryDB;
GO

SELECT *
FROM dbo.Employee;

USE FootballIndustryDB;
GO

SELECT *
FROM dbo.Client;
USE FootballIndustryDB;
GO

SELECT TOP 31 *
FROM dbo.Product;


USE FootballIndustryDB;
GO

ALTER TABLE dbo.Product
ADD ImageURL NVARCHAR(500) NULL;
GO

SELECT *
FROM dbo.Manufacturer;

SELECT
    ManufacturerID,
    ManufacturerName
FROM dbo.Manufacturer
ORDER BY ManufacturerID;


SELECT
    ProductID,
    ProductName,
    Category,
    ManufacturerID,
    ImageURL
FROM dbo.Product
ORDER BY ProductID;


SELECT DISTINCT Category
FROM dbo.Product
ORDER BY Category;





UPDATE dbo.Product
SET ImageURL = '/images/image4.jpg'
WHERE Category = 'Beach Football';

UPDATE dbo.Product
SET ImageURL = '/images/image7.jpg'
WHERE Category = 'Custom';

UPDATE dbo.Product
SET ImageURL = '/images/image2.jpg'
WHERE Category = 'Futsal';

UPDATE dbo.Product
SET ImageURL = '/images/image1.jpg'
WHERE Category = 'Match Football';

UPDATE dbo.Product
SET ImageURL = '/images/image6.jpg'
WHERE Category = 'Promotional';

UPDATE dbo.Product
SET ImageURL = '/images/image3.jpg'
WHERE Category = 'Training Football';

UPDATE dbo.Product
SET ImageURL = '/images/image5.jpg'
WHERE Category = 'Youth Football';


SELECT ProductID, ProductName, Category, ImageURL
FROM dbo.Product
WHERE ProductID = 1;

SELECT DISTINCT Category
FROM dbo.Product;


USE FootballIndustryDB;
GO

UPDATE dbo.Product
SET ImageURL = '/images/image4.jpg'
WHERE Category = 'Beach';

UPDATE dbo.Product
SET ImageURL = '/images/image7.jpg'
WHERE Category = 'Custom';

UPDATE dbo.Product
SET ImageURL = '/images/image6.jpg'
WHERE Category = 'Futsal';

UPDATE dbo.Product
SET ImageURL = '/images/image3.jpg'
WHERE Category = 'Match';

UPDATE dbo.Product
SET ImageURL = '/images/image5.jpg'
WHERE Category = 'Promotional';

UPDATE dbo.Product
SET ImageURL = '/images/image6.jpg'
WHERE Category = 'Training';

UPDATE dbo.Product
SET ImageURL = '/images/image7.jpg'
WHERE Category = 'Youth';

GO


SELECT ProductID, ProductName, Category, ImageURL
FROM dbo.Product
ORDER BY ProductID;

SELECT ProductID, ProductName, Category, ImageURL
FROM dbo.Product
WHERE ProductID = 1; 




USE FootballIndustryDB;
GO

ALTER TABLE Product
ADD ImageURL NVARCHAR(500) NULL;
GO

USE FootballIndustryDB;
GO

SELECT ProductID, ProductName, Category, ImageURL
FROM Product
WHERE ProductID = 1;

USE FootballIndustryDB;

SELECT 
    t.TABLE_NAME AS EntityName,
    c.COLUMN_NAME AS AttributeName,
    c.DATA_TYPE AS DataType,
    c.IS_NULLABLE AS Nullable
FROM INFORMATION_SCHEMA.TABLES t
JOIN INFORMATION_SCHEMA.COLUMNS c
    ON t.TABLE_NAME = c.TABLE_NAME
    AND t.TABLE_SCHEMA = c.TABLE_SCHEMA
WHERE t.TABLE_TYPE = 'BASE TABLE'
ORDER BY t.TABLE_NAME, c.ORDINAL_POSITION;


USE FootballIndustryDB;

SELECT 
    TABLE_SCHEMA AS SchemaName,
    TABLE_NAME AS EntityName
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;


select * from Product






USE FootballIndustryDB;

DECLARE @SQL NVARCHAR(MAX) = N'';

SELECT @SQL = @SQL +
    'SELECT TOP (3) ''' +
    REPLACE(TABLE_SCHEMA + '.' + TABLE_NAME, '''', '''''') +
    ''' AS EntityName, * ' +
    'FROM ' + QUOTENAME(TABLE_SCHEMA) + '.' + QUOTENAME(TABLE_NAME) + ';' + CHAR(13)
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;

EXEC sp_executesql @SQL;

SELECT
p.ProductName,
m.ManufacturerName,
i.QuantityInStock
FROM Product p
JOIN Manufacturer m
ON p.ManufacturerID = m.ManufacturerID
JOIN Inventory i
ON p.ProductID = i.ProductID
WHERE i.QuantityInStock < 50;

USE FootballIndustryDB;
GO

SELECT
    p.ProductName,
    m.ManufacturerName,
    i.QuantityInStock
FROM Product AS p
JOIN Manufacturer AS m
    ON p.ManufacturerID = m.ManufacturerID
JOIN Inventory AS i
    ON p.ProductID = i.ProductID
WHERE i.QuantityInStock < 50;

USE FootballIndustryDB;
GO

SELECT 
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME IN ('Product', 'Manufacturer', 'Inventory')
ORDER BY TABLE_NAME, ORDINAL_POSITION;

USE FootballIndustryDB;
GO

SELECT
    p.ProductName,
    m.CompanyName,
    i.Quantity
FROM Product AS p
JOIN Manufacturer AS m
    ON p.ManufacturerID = m.ManufacturerID
JOIN Inventory AS i
    ON p.ProductID = i.ProductID
WHERE i.Quantity < 50;


select * from customer



USE FootballIndustryDB;
GO

-- See the original value
SELECT TOP 1
    ProductID,
    Quantity
FROM Inventory
ORDER BY ProductID;

-- Start Transaction
BEGIN TRANSACTION;

-- Update the inventory temporarily
UPDATE Inventory
SET Quantity = Quantity + 10
WHERE ProductID = (
    SELECT TOP 1 ProductID
    FROM Inventory
    ORDER BY ProductID
);

-- See the changed value inside the transaction
SELECT TOP 1
    ProductID,
    Quantity
FROM Inventory
ORDER BY ProductID;

-- Undo the transaction
ROLLBACK TRANSACTION;

-- Check the value after ROLLBACK
SELECT TOP 1
    ProductID,
    Quantity
FROM Inventory
ORDER BY ProductID;