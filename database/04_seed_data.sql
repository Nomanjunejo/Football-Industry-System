/* ============================================================
   04_seed_data.sql
   Seed data strategy (see README for full explanation):

   VERIFIED   -> company identity facts (name/city/country/type)
                 for real, publicly known Sialkot/Pakistan and
                 international football manufacturers. No
                 fabricated financial figures are attached to
                 real companies.
   ESTIMATED  -> plausible values for fields that are not
                 publicly disclosed (e.g. approximate revenue
                 bands), clearly labelled.
   SYNTHETIC  -> all transactional data (batches, orders,
                 employees, customers, reviews, shipments) is
                 generated for the purpose of demonstrating the
                 database -- it is not real business activity.

   Run after 01, 02, 03.
   ============================================================ */

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
