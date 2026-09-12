from pydantic import BaseModel, EmailStr, ConfigDict, Field
from typing import Optional, List
from datetime import date, datetime
from decimal import Decimal


# ---------------------------------------------------------------
# Client / Export
# ---------------------------------------------------------------
class ClientCreate(BaseModel):
    CompanyName: str
    Country: str
    City: Optional[str] = None
    ContactPerson: Optional[str] = None
    ContactEmail: EmailStr
    ContactPhone: Optional[str] = None


class ClientOut(ClientCreate):
    model_config = ConfigDict(from_attributes=True)
    ClientID: int


class OrderLineIn(BaseModel):
    ProductID: int
    Quantity: int
    UnitPrice: Decimal


class ExportOrderCreate(BaseModel):
    ClientID: int
    ExportOfficerID: Optional[int] = None
    DestinationCountry: str
    OrderLines: List[OrderLineIn] = Field(min_length=1)


class ExportOrderStatusUpdate(BaseModel):
    PaymentStatus: Optional[str] = None
    ExportStatus: Optional[str] = None


class OrderDetailOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    OrderDetailID: int
    ProductID: int
    Quantity: int
    UnitPrice: Decimal
    LineTotal: Decimal


class ExportOrderOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    ExportOrderID: int
    ClientID: int
    ExportOfficerID: Optional[int] = None
    OrderDate: date
    DestinationCountry: str
    TotalAmount: Decimal
    PaymentStatus: str
    ExportStatus: str
    order_details: List[OrderDetailOut] = []


class ShipmentUpdate(BaseModel):
    Carrier: Optional[str] = None
    TrackingNumber: Optional[str] = None
    ShipmentStatus: Optional[str] = None
    ShippedDate: Optional[date] = None
    EstimatedArrival: Optional[date] = None
    DeliveredDate: Optional[date] = None


class ShipmentOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    ShipmentID: int
    ExportOrderID: int
    Carrier: Optional[str] = None
    TrackingNumber: Optional[str] = None
    ShipmentStatus: str
    ShippedDate: Optional[date] = None
    EstimatedArrival: Optional[date] = None
    DeliveredDate: Optional[date] = None


# ---------------------------------------------------------------
# Marketplace (Customer-facing)
# ---------------------------------------------------------------
class CartItemIn(BaseModel):
    ProductID: int
    Quantity: int


class CustomerOrderCreate(BaseModel):
    Items: List[CartItemIn] = Field(min_length=1)
    ShippingAddress: Optional[str] = None


class CustomerOrderItemOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    CustomerOrderItemID: int
    ProductID: int
    Quantity: int
    UnitPrice: Decimal
    LineTotal: Decimal


class CustomerOrderOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    CustomerOrderID: int
    CustomerID: int
    OrderDate: datetime
    TotalAmount: Decimal
    PaymentStatus: str
    OrderStatus: str
    ShippingAddress: Optional[str] = None
    items: List[CustomerOrderItemOut] = []


class ReviewCreate(BaseModel):
    ProductID: int
    Rating: int = Field(ge=1, le=5)
    Comment: Optional[str] = None


class ReviewOut(ReviewCreate):
    model_config = ConfigDict(from_attributes=True)
    ReviewID: int
    CustomerID: int
    ReviewDate: datetime


class CertificationCreate(BaseModel):
    ProductID: int
    CertificationType: str
    CertificateNumber: Optional[str] = None
    IssuingOrganization: Optional[str] = None
    IssueDate: Optional[date] = None
    ExpiryDate: Optional[date] = None
    DataSource: Optional[str] = None


class CertificationOut(CertificationCreate):
    model_config = ConfigDict(from_attributes=True)
    CertificationID: int
    Status: str


# ---------------------------------------------------------------
# Analytics / Dashboard
# ---------------------------------------------------------------
class DashboardSummary(BaseModel):
    total_manufacturers: int
    total_products: int
    total_production_units: int
    total_inventory_units: int
    total_export_orders: int
    total_export_revenue: Decimal
    total_customers: int
    total_buyers: int
    top_export_country: Optional[str] = None
    best_selling_product: Optional[str] = None


class RevenueByCountry(BaseModel):
    DestinationCountry: str
    TotalOrders: int
    TotalUnitsExported: int
    TotalRevenue: Decimal


class LowStockItem(BaseModel):
    ProductID: int
    ProductName: str
    Category: str
    WarehouseID: int
    WarehouseName: str
    Quantity: int
    ReorderLevel: int
    StockStatus: str
