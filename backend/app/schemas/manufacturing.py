"""
Pydantic v2 schemas. Naming convention: <Entity>Create (input for
creation), <Entity>Update (partial input for updates), <Entity>Out
(response shape, includes generated fields like IDs and timestamps).
"""
from pydantic import BaseModel, EmailStr, Field, ConfigDict
from typing import Optional, List
from datetime import date, datetime
from decimal import Decimal


# ---------------------------------------------------------------
# Auth
# ---------------------------------------------------------------
class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    role: str
    full_name: str
    user_id: int


class EmployeeLogin(BaseModel):
    email: EmailStr
    password: str


class EmployeeCreate(BaseModel):
    full_name: str
    email: EmailStr
    password: str = Field(min_length=8)
    role: str
    department: Optional[str] = None
    phone: Optional[str] = None


class EmployeeOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    EmployeeID: int
    FullName: str
    Email: EmailStr
    Role: str
    Department: Optional[str] = None
    Phone: Optional[str] = None
    HireDate: date
    IsActive: bool


class CustomerRegister(BaseModel):
    full_name: str
    email: EmailStr
    password: str = Field(min_length=8)
    phone: Optional[str] = None
    country: Optional[str] = None
    city: Optional[str] = None
    address: Optional[str] = None


class CustomerLogin(BaseModel):
    email: EmailStr
    password: str


class CustomerOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    CustomerID: int
    FullName: str
    Email: EmailStr
    Phone: Optional[str] = None
    Country: Optional[str] = None
    City: Optional[str] = None
    Address: Optional[str] = None


# ---------------------------------------------------------------
# Manufacturer / Company Directory
# ---------------------------------------------------------------
class ManufacturerBase(BaseModel):
    CompanyName: str
    Country: str
    City: Optional[str] = None
    EstablishedYear: Optional[int] = None
    CompanyType: Optional[str] = None
    Description: Optional[str] = None
    Website: Optional[str] = None
    ContactEmail: Optional[EmailStr] = None
    ContactPhone: Optional[str] = None
    LogoUrl: Optional[str] = None
    AnnualRevenueUSD: Optional[Decimal] = None
    PrimaryExportMarkets: Optional[str] = None
    DataSource: Optional[str] = None
    DataType: str = "Synthetic"
    VerificationStatus: str = "Unverified"


class ManufacturerCreate(ManufacturerBase):
    pass


class ManufacturerUpdate(BaseModel):
    CompanyName: Optional[str] = None
    Country: Optional[str] = None
    City: Optional[str] = None
    EstablishedYear: Optional[int] = None
    CompanyType: Optional[str] = None
    Description: Optional[str] = None
    Website: Optional[str] = None
    IsActive: Optional[bool] = None


class ManufacturerOut(ManufacturerBase):
    model_config = ConfigDict(from_attributes=True)
    ManufacturerID: int
    IndustryScore: Optional[Decimal] = None
    IsActive: bool


# ---------------------------------------------------------------
# Supplier / RawMaterial
# ---------------------------------------------------------------
class SupplierCreate(BaseModel):
    SupplierName: str
    Country: str
    City: Optional[str] = None
    ContactEmail: Optional[EmailStr] = None
    ContactPhone: Optional[str] = None
    MaterialCategory: Optional[str] = None
    Rating: Optional[Decimal] = None


class SupplierOut(SupplierCreate):
    model_config = ConfigDict(from_attributes=True)
    SupplierID: int
    IsActive: bool


class RawMaterialCreate(BaseModel):
    SupplierID: int
    MaterialName: str
    Unit: str
    UnitCost: Decimal
    StockQuantity: Decimal = Decimal("0")
    ReorderLevel: Decimal = Decimal("100")


class RawMaterialOut(RawMaterialCreate):
    model_config = ConfigDict(from_attributes=True)
    RawMaterialID: int


# ---------------------------------------------------------------
# Product
# ---------------------------------------------------------------
# ---------------------------------------------------------------
# Product
# ---------------------------------------------------------------
class ProductCreate(BaseModel):
    ManufacturerID: int
    ProductName: str
    Category: str
    SizeNumber: int
    Material: Optional[str] = None
    ConstructionMethod: Optional[str] = None
    Price: Decimal
    Description: Optional[str] = None


class ProductUpdate(BaseModel):
    ProductName: Optional[str] = None
    Price: Optional[Decimal] = None
    Description: Optional[str] = None
    IsActive: Optional[bool] = None


class ProductOut(ProductCreate):
    model_config = ConfigDict(from_attributes=True)
    ProductID: int
    AverageRating: Decimal
    IsActive: bool
    ImageURL: Optional[str] = None

# ---------------------------------------------------------------
# Production
# ---------------------------------------------------------------
class ProductionBatchCreate(BaseModel):
    ProductID: int
    ManufacturerID: int
    SupervisorID: Optional[int] = None
    Quantity: int
    ProductionDate: date


class ProductionBatchStatusUpdate(BaseModel):
    Status: str
    CompletionDate: Optional[date] = None


class ProductionBatchOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    BatchID: int
    ProductID: int
    ManufacturerID: int
    SupervisorID: Optional[int] = None
    Quantity: int
    ProductionDate: date
    CompletionDate: Optional[date] = None
    Status: str


class QualityInspectionCreate(BaseModel):
    BatchID: int
    InspectorID: Optional[int] = None
    WeightTestPass: bool
    CircumferenceTestPass: bool
    PressureTestPass: bool
    BounceTestPass: bool
    ShapeTestPass: bool
    MaterialTestPass: bool
    QualityScore: Decimal
    Status: str


class QualityInspectionOut(QualityInspectionCreate):
    model_config = ConfigDict(from_attributes=True)
    InspectionID: int
    InspectionDate: date


# ---------------------------------------------------------------
# Warehouse / Inventory
# ---------------------------------------------------------------
class WarehouseCreate(BaseModel):
    WarehouseName: str
    Location: str
    Capacity: int
    ManagerID: Optional[int] = None


class WarehouseOut(WarehouseCreate):
    model_config = ConfigDict(from_attributes=True)
    WarehouseID: int


class InventoryOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    InventoryID: int
    ProductID: int
    WarehouseID: int
    Quantity: int
    ReorderLevel: int
    StockStatus: str
    LastUpdated: datetime


class InventoryAdjust(BaseModel):
    ProductID: int
    WarehouseID: int
    QuantityDelta: int
