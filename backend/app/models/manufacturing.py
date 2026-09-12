"""
SQLAlchemy models mirroring database/02_create_tables.sql exactly.
Column names, types, and nullability match the SQL schema so that
no translation layer is needed between the DB and the API.
"""

from sqlalchemy import (
    Column,
    Integer,
    String,
    Numeric,
    Date,
    DateTime,
    Boolean,
    SmallInteger,
    ForeignKey,
    UniqueConstraint,
    Computed,
)
from sqlalchemy.orm import relationship
from datetime import datetime

from app.database import Base


# ===============================================================
# Employee
# ===============================================================

class Employee(Base):
    __tablename__ = "Employee"

    EmployeeID = Column(Integer, primary_key=True, autoincrement=True)
    FullName = Column(String(120), nullable=False)
    Email = Column(String(150), nullable=False, unique=True)
    PasswordHash = Column(String(255), nullable=False)
    Role = Column(String(30), nullable=False)
    Department = Column(String(60))
    Phone = Column(String(30))
    HireDate = Column(Date, default=datetime.utcnow)
    IsActive = Column(Boolean, default=True)
    CreatedAt = Column(DateTime, default=datetime.utcnow)

    supervised_batches = relationship(
        "ProductionBatch",
        back_populates="supervisor"
    )

    inspections = relationship(
        "QualityInspection",
        back_populates="inspector"
    )

    export_orders = relationship(
        "ExportOrder",
        back_populates="export_officer"
    )

    warehouses = relationship(
        "Warehouse",
        back_populates="manager"
    )


# ===============================================================
# Manufacturer
# ===============================================================

class Manufacturer(Base):
    __tablename__ = "Manufacturer"

    ManufacturerID = Column(Integer, primary_key=True, autoincrement=True)
    CompanyName = Column(String(150), nullable=False, unique=True)
    Country = Column(String(80), nullable=False)
    City = Column(String(80))
    EstablishedYear = Column(SmallInteger)
    CompanyType = Column(String(40))
    Description = Column(String(1000))
    Website = Column(String(200))
    ContactEmail = Column(String(150))
    ContactPhone = Column(String(30))
    LogoUrl = Column(String(300))
    AnnualRevenueUSD = Column(Numeric(18, 2))
    PrimaryExportMarkets = Column(String(300))
    IndustryScore = Column(Numeric(5, 2))
    DataSource = Column(String(150))
    DataType = Column(String(20), default="Synthetic")
    VerificationStatus = Column(String(20), default="Unverified")
    IsActive = Column(Boolean, default=True)
    CreatedAt = Column(DateTime, default=datetime.utcnow)

    products = relationship(
        "Product",
        back_populates="manufacturer"
    )

    batches = relationship(
        "ProductionBatch",
        back_populates="manufacturer"
    )


# ===============================================================
# Supplier
# ===============================================================

class Supplier(Base):
    __tablename__ = "Supplier"

    SupplierID = Column(Integer, primary_key=True, autoincrement=True)
    SupplierName = Column(String(150), nullable=False)
    Country = Column(String(80), nullable=False)
    City = Column(String(80))
    ContactEmail = Column(String(150), unique=True)
    ContactPhone = Column(String(30))
    MaterialCategory = Column(String(80))
    Rating = Column(Numeric(3, 2))
    IsActive = Column(Boolean, default=True)
    CreatedAt = Column(DateTime, default=datetime.utcnow)

    raw_materials = relationship(
        "RawMaterial",
        back_populates="supplier"
    )


# ===============================================================
# Raw Material
# ===============================================================

class RawMaterial(Base):
    __tablename__ = "RawMaterial"

    RawMaterialID = Column(Integer, primary_key=True, autoincrement=True)
    SupplierID = Column(
        Integer,
        ForeignKey("Supplier.SupplierID"),
        nullable=False
    )
    MaterialName = Column(String(120), nullable=False)
    Unit = Column(String(20), nullable=False)
    UnitCost = Column(Numeric(12, 2), nullable=False)
    StockQuantity = Column(Numeric(14, 2), default=0)
    ReorderLevel = Column(Numeric(14, 2), default=100)
    CreatedAt = Column(DateTime, default=datetime.utcnow)

    supplier = relationship(
        "Supplier",
        back_populates="raw_materials"
    )


# ===============================================================
# Product
# ===============================================================

class Product(Base):
    __tablename__ = "Product"

    ProductID = Column(Integer, primary_key=True, autoincrement=True)

    ManufacturerID = Column(
        Integer,
        ForeignKey("Manufacturer.ManufacturerID"),
        nullable=False
    )

    ProductName = Column(String(120), nullable=False)
    Category = Column(String(40), nullable=False)
    SizeNumber = Column(SmallInteger, nullable=False)
    Material = Column(String(80))
    ConstructionMethod = Column(String(40))
    Price = Column(Numeric(10, 2), nullable=False)
    Description = Column(String(500))

    # Product image path stored in database
    # Example: /images/image3.jpg
    ImageURL = Column(String(500), nullable=True)

    AverageRating = Column(Numeric(3, 2), default=0)
    IsActive = Column(Boolean, default=True)
    CreatedAt = Column(DateTime, default=datetime.utcnow)

    manufacturer = relationship(
        "Manufacturer",
        back_populates="products"
    )

    batches = relationship(
        "ProductionBatch",
        back_populates="product"
    )

    inventory_rows = relationship(
        "Inventory",
        back_populates="product"
    )

    certifications = relationship(
        "Certification",
        back_populates="product"
    )

    reviews = relationship(
        "Review",
        back_populates="product"
    )


# ===============================================================
# Production Batch
# ===============================================================

class ProductionBatch(Base):
    __tablename__ = "ProductionBatch"

    BatchID = Column(Integer, primary_key=True, autoincrement=True)

    ProductID = Column(
        Integer,
        ForeignKey("Product.ProductID"),
        nullable=False
    )

    ManufacturerID = Column(
        Integer,
        ForeignKey("Manufacturer.ManufacturerID"),
        nullable=False
    )

    SupervisorID = Column(
        Integer,
        ForeignKey("Employee.EmployeeID")
    )

    Quantity = Column(Integer, nullable=False)
    ProductionDate = Column(Date, nullable=False)
    CompletionDate = Column(Date)
    Status = Column(String(20), default="Planned")
    CreatedAt = Column(DateTime, default=datetime.utcnow)

    product = relationship(
        "Product",
        back_populates="batches"
    )

    manufacturer = relationship(
        "Manufacturer",
        back_populates="batches"
    )

    supervisor = relationship(
        "Employee",
        back_populates="supervised_batches"
    )

    inspections = relationship(
        "QualityInspection",
        back_populates="batch"
    )

    material_usage = relationship(
        "BatchMaterialUsage",
        back_populates="batch"
    )


# ===============================================================
# Batch Material Usage
# ===============================================================

class BatchMaterialUsage(Base):
    __tablename__ = "BatchMaterialUsage"

    BatchID = Column(
        Integer,
        ForeignKey("ProductionBatch.BatchID"),
        primary_key=True
    )

    RawMaterialID = Column(
        Integer,
        ForeignKey("RawMaterial.RawMaterialID"),
        primary_key=True
    )

    QuantityUsed = Column(Numeric(14, 2), nullable=False)

    batch = relationship(
        "ProductionBatch",
        back_populates="material_usage"
    )

    raw_material = relationship(
        "RawMaterial"
    )


# ===============================================================
# Quality Inspection
# ===============================================================

class QualityInspection(Base):
    __tablename__ = "QualityInspection"

    InspectionID = Column(Integer, primary_key=True, autoincrement=True)

    BatchID = Column(
        Integer,
        ForeignKey("ProductionBatch.BatchID"),
        nullable=False
    )

    InspectorID = Column(
        Integer,
        ForeignKey("Employee.EmployeeID")
    )

    WeightTestPass = Column(Boolean, default=False)
    CircumferenceTestPass = Column(Boolean, default=False)
    PressureTestPass = Column(Boolean, default=False)
    BounceTestPass = Column(Boolean, default=False)
    ShapeTestPass = Column(Boolean, default=False)
    MaterialTestPass = Column(Boolean, default=False)

    QualityScore = Column(Numeric(5, 2), nullable=False)
    Status = Column(String(10), nullable=False)
    InspectionDate = Column(Date, default=datetime.utcnow)

    batch = relationship(
        "ProductionBatch",
        back_populates="inspections"
    )

    inspector = relationship(
        "Employee",
        back_populates="inspections"
    )


# ===============================================================
# Warehouse
# ===============================================================

class Warehouse(Base):
    __tablename__ = "Warehouse"

    WarehouseID = Column(Integer, primary_key=True, autoincrement=True)
    WarehouseName = Column(String(100), nullable=False)
    Location = Column(String(150), nullable=False)
    Capacity = Column(Integer, nullable=False)

    ManagerID = Column(
        Integer,
        ForeignKey("Employee.EmployeeID")
    )

    CreatedAt = Column(DateTime, default=datetime.utcnow)

    manager = relationship(
        "Employee",
        back_populates="warehouses"
    )

    inventory_rows = relationship(
        "Inventory",
        back_populates="warehouse"
    )


# ===============================================================
# Inventory
# ===============================================================

class Inventory(Base):
    __tablename__ = "Inventory"

    InventoryID = Column(Integer, primary_key=True, autoincrement=True)

    ProductID = Column(
        Integer,
        ForeignKey("Product.ProductID"),
        nullable=False
    )

    WarehouseID = Column(
        Integer,
        ForeignKey("Warehouse.WarehouseID"),
        nullable=False
    )

    Quantity = Column(Integer, default=0)
    ReorderLevel = Column(Integer, default=20)
    StockStatus = Column(String(20), default="Out of Stock")
    LastUpdated = Column(DateTime, default=datetime.utcnow)

    __table_args__ = (
        UniqueConstraint(
            "ProductID",
            "WarehouseID",
            name="UQ_Inventory_Product_Warehouse"
        ),
    )

    product = relationship(
        "Product",
        back_populates="inventory_rows"
    )

    warehouse = relationship(
        "Warehouse",
        back_populates="inventory_rows"
    )