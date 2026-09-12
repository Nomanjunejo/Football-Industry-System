/* ============================================================
   02_create_tables.sql
   Creates all core tables in dependency order.
   Normalization: schema is designed to 3NF -- every non-key
   column depends on the whole primary key and nothing but the
   primary key. Many-to-many relationships are resolved with
   junction tables (BatchMaterialUsage, OrderDetail,
   CustomerOrderItem).
   ============================================================ */

USE FootballIndustryDB;
GO

/* ---------------------------------------------------------
   1. EMPLOYEE  (also serves as staff/admin login account)
   --------------------------------------------------------- */
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

/* ---------------------------------------------------------
   2. MANUFACTURER  (doubles as the public "Company Directory"
      record -- Manufacturing + Industry Intelligence module)
   --------------------------------------------------------- */
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

/* ---------------------------------------------------------
   3. SUPPLIER
   --------------------------------------------------------- */
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

/* ---------------------------------------------------------
   4. RAW MATERIAL
   --------------------------------------------------------- */
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

/* ---------------------------------------------------------
   5. PRODUCT
   --------------------------------------------------------- */
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
    ImageURL           NVARCHAR(500)  NULL,   -- e.g. "/images/image3.jpg"
    AverageRating      DECIMAL(3,2)   NOT NULL DEFAULT (0) CHECK (AverageRating BETWEEN 0 AND 5),
    IsActive           BIT            NOT NULL DEFAULT (1),
    CreatedAt          DATETIME2      NOT NULL DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT FK_Product_Manufacturer FOREIGN KEY (ManufacturerID)
        REFERENCES Manufacturer(ManufacturerID) ON DELETE NO ACTION ON UPDATE CASCADE
);
GO

/* ---------------------------------------------------------
   6. PRODUCTION BATCH
   --------------------------------------------------------- */
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
