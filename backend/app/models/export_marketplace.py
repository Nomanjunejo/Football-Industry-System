from sqlalchemy import (
    Column,
    Integer,
    String,
    Numeric,
    Date,
    DateTime,
    ForeignKey,
    UniqueConstraint,
    Computed,
    SmallInteger,
)
from sqlalchemy.orm import relationship
from datetime import datetime

from app.database import Base


# ===============================================================
# Client
# ===============================================================

class Client(Base):
    __tablename__ = "Client"

    ClientID = Column(
        Integer,
        primary_key=True,
        autoincrement=True
    )

    CompanyName = Column(
        String(150),
        nullable=False
    )

    Country = Column(
        String(80),
        nullable=False
    )

    City = Column(String(80))
    ContactPerson = Column(String(100))

    ContactEmail = Column(
        String(150),
        nullable=False,
        unique=True
    )

    ContactPhone = Column(String(30))
    CreatedAt = Column(
        DateTime,
        default=datetime.utcnow
    )

    export_orders = relationship(
        "ExportOrder",
        back_populates="client"
    )


# ===============================================================
# Export Order
# ===============================================================

class ExportOrder(Base):
    __tablename__ = "ExportOrder"

    ExportOrderID = Column(
        Integer,
        primary_key=True,
        autoincrement=True
    )

    ClientID = Column(
        Integer,
        ForeignKey("Client.ClientID"),
        nullable=False
    )

    ExportOfficerID = Column(
        Integer,
        ForeignKey("Employee.EmployeeID")
    )

    OrderDate = Column(
        Date,
        default=datetime.utcnow
    )

    DestinationCountry = Column(
        String(80),
        nullable=False
    )

    TotalAmount = Column(
        Numeric(14, 2),
        default=0
    )

    PaymentStatus = Column(
        String(20),
        default="Pending"
    )

    ExportStatus = Column(
        String(20),
        default="Processing"
    )

    CreatedAt = Column(
        DateTime,
        default=datetime.utcnow
    )

    client = relationship(
        "Client",
        back_populates="export_orders"
    )

    export_officer = relationship(
        "Employee",
        back_populates="export_orders"
    )

    order_details = relationship(
        "OrderDetail",
        back_populates="export_order",
        cascade="all, delete-orphan"
    )

    shipment = relationship(
        "Shipment",
        back_populates="export_order",
        uselist=False
    )


# ===============================================================
# Order Detail
# ===============================================================

class OrderDetail(Base):
    __tablename__ = "OrderDetail"

    OrderDetailID = Column(
        Integer,
        primary_key=True,
        autoincrement=True
    )

    ExportOrderID = Column(
        Integer,
        ForeignKey("ExportOrder.ExportOrderID"),
        nullable=False
    )

    ProductID = Column(
        Integer,
        ForeignKey("Product.ProductID"),
        nullable=False
    )

    Quantity = Column(
        Integer,
        nullable=False
    )

    UnitPrice = Column(
        Numeric(10, 2),
        nullable=False
    )

    LineTotal = Column(
        Numeric(18, 2),
        Computed("Quantity * UnitPrice")
    )

    export_order = relationship(
        "ExportOrder",
        back_populates="order_details"
    )

    product = relationship(
        "Product"
    )


# ===============================================================
# Shipment
# ===============================================================

class Shipment(Base):
    __tablename__ = "Shipment"

    ShipmentID = Column(
        Integer,
        primary_key=True,
        autoincrement=True
    )

    ExportOrderID = Column(
        Integer,
        ForeignKey("ExportOrder.ExportOrderID"),
        nullable=False,
        unique=True
    )

    Carrier = Column(String(100))
    TrackingNumber = Column(String(60))

    ShipmentStatus = Column(
        String(20),
        default="Processing"
    )

    ShippedDate = Column(Date)
    EstimatedArrival = Column(Date)
    DeliveredDate = Column(Date)

    export_order = relationship(
        "ExportOrder",
        back_populates="shipment"
    )


# ===============================================================
# Customer
# ===============================================================

class Customer(Base):
    __tablename__ = "Customer"

    CustomerID = Column(
        Integer,
        primary_key=True,
        autoincrement=True
    )

    FullName = Column(
        String(120),
        nullable=False
    )

    Email = Column(
        String(150),
        nullable=False,
        unique=True
    )

    PasswordHash = Column(
        String(255),
        nullable=False
    )

    Phone = Column(String(30))
    Country = Column(String(80))
    City = Column(String(80))
    Address = Column(String(250))

    CreatedAt = Column(
        DateTime,
        default=datetime.utcnow
    )

    orders = relationship(
        "CustomerOrder",
        back_populates="customer"
    )

    reviews = relationship(
        "Review",
        back_populates="customer"
    )


# ===============================================================
# Customer Order
# ===============================================================

class CustomerOrder(Base):
    __tablename__ = "CustomerOrder"

    CustomerOrderID = Column(
        Integer,
        primary_key=True,
        autoincrement=True
    )

    CustomerID = Column(
        Integer,
        ForeignKey("Customer.CustomerID"),
        nullable=False
    )

    OrderDate = Column(
        DateTime,
        default=datetime.utcnow
    )

    TotalAmount = Column(
        Numeric(12, 2),
        default=0
    )

    PaymentStatus = Column(
        String(20),
        default="Pending"
    )

    OrderStatus = Column(
        String(20),
        default="Processing"
    )

    ShippingAddress = Column(
        String(250)
    )

    customer = relationship(
        "Customer",
        back_populates="orders"
    )

    items = relationship(
        "CustomerOrderItem",
        back_populates="order",
        cascade="all, delete-orphan"
    )


# ===============================================================
# Customer Order Item
# ===============================================================

class CustomerOrderItem(Base):
    __tablename__ = "CustomerOrderItem"

    CustomerOrderItemID = Column(
        Integer,
        primary_key=True,
        autoincrement=True
    )

    CustomerOrderID = Column(
        Integer,
        ForeignKey("CustomerOrder.CustomerOrderID"),
        nullable=False
    )

    ProductID = Column(
        Integer,
        ForeignKey("Product.ProductID"),
        nullable=False
    )

    Quantity = Column(
        Integer,
        nullable=False
    )

    UnitPrice = Column(
        Numeric(10, 2),
        nullable=False
    )

    LineTotal = Column(
        Numeric(18, 2),
        Computed("Quantity * UnitPrice")
    )

    order = relationship(
        "CustomerOrder",
        back_populates="items"
    )

    product = relationship(
        "Product"
    )


# ===============================================================
# Review
# ===============================================================

class Review(Base):
    __tablename__ = "Review"

    ReviewID = Column(
        Integer,
        primary_key=True,
        autoincrement=True
    )

    CustomerID = Column(
        Integer,
        ForeignKey("Customer.CustomerID"),
        nullable=False
    )

    ProductID = Column(
        Integer,
        ForeignKey("Product.ProductID"),
        nullable=False
    )

    Rating = Column(
        SmallInteger,
        nullable=False
    )

    Comment = Column(String(500))

    ReviewDate = Column(
        DateTime,
        default=datetime.utcnow
    )

    __table_args__ = (
        UniqueConstraint(
            "CustomerID",
            "ProductID",
            name="UQ_Review_Customer_Product"
        ),
    )

    customer = relationship(
        "Customer",
        back_populates="reviews"
    )

    product = relationship(
        "Product",
        back_populates="reviews"
    )


# ===============================================================
# Certification
# ===============================================================

class Certification(Base):
    __tablename__ = "Certification"

    CertificationID = Column(
        Integer,
        primary_key=True,
        autoincrement=True
    )

    ProductID = Column(
        Integer,
        ForeignKey("Product.ProductID"),
        nullable=False
    )

    CertificationType = Column(
        String(80),
        nullable=False
    )

    CertificateNumber = Column(
        String(60)
    )

    IssuingOrganization = Column(
        String(120)
    )

    IssueDate = Column(Date)
    ExpiryDate = Column(Date)

    Status = Column(
        String(20),
        default="Active"
    )

    DataSource = Column(
        String(150)
    )

    product = relationship(
        "Product",
        back_populates="certifications"
    )