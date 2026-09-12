from sqlalchemy.orm import Session
from sqlalchemy import func, text
from app import models, schemas


# ---------------------------------------------------------------
# Client
# ---------------------------------------------------------------
def list_clients(db: Session, skip: int = 0, limit: int = 100):
    return db.query(models.Client).offset(skip).limit(limit).all()


def create_client(db: Session, data: schemas.ClientCreate):
    c = models.Client(**data.model_dump())
    db.add(c)
    db.commit()
    db.refresh(c)
    return c


# ---------------------------------------------------------------
# Export Order
# Mirrors sp_PlaceExportOrder: header + lines inserted together;
# trg_UpdateOrderTotal (fires at the DB level regardless of client)
# keeps TotalAmount correct, and a Shipment row is created to match.
# ---------------------------------------------------------------
def list_export_orders(db: Session, status: str | None = None, country: str | None = None,
                        skip: int = 0, limit: int = 100):
    q = db.query(models.ExportOrder)
    if status:
        q = q.filter(models.ExportOrder.ExportStatus == status)
    if country:
        q = q.filter(models.ExportOrder.DestinationCountry == country)
    return q.order_by(models.ExportOrder.OrderDate.desc()).offset(skip).limit(limit).all()


def get_export_order(db: Session, export_order_id: int):
    return db.query(models.ExportOrder).filter(models.ExportOrder.ExportOrderID == export_order_id).first()


def create_export_order(db: Session, data: schemas.ExportOrderCreate):
    try:
        order = models.ExportOrder(
            ClientID=data.ClientID,
            ExportOfficerID=data.ExportOfficerID,
            DestinationCountry=data.DestinationCountry,
            TotalAmount=0,
            PaymentStatus="Pending",
            ExportStatus="Processing",
        )
        db.add(order)
        db.flush()  # get ExportOrderID without committing yet

        for line in data.OrderLines:
            db.add(models.OrderDetail(
                ExportOrderID=order.ExportOrderID,
                ProductID=line.ProductID,
                Quantity=line.Quantity,
                UnitPrice=line.UnitPrice,
            ))

        db.add(models.Shipment(ExportOrderID=order.ExportOrderID, ShipmentStatus="Processing"))

        db.commit()
        db.refresh(order)
        return order
    except Exception:
        db.rollback()
        raise


def update_export_order_status(db: Session, export_order_id: int, data: schemas.ExportOrderStatusUpdate):
    order = get_export_order(db, export_order_id)
    if not order:
        return None
    if data.PaymentStatus:
        order.PaymentStatus = data.PaymentStatus
    if data.ExportStatus:
        order.ExportStatus = data.ExportStatus
        # keep the Shipment row's status roughly in sync
        if order.shipment:
            order.shipment.ShipmentStatus = data.ExportStatus
    db.commit()
    db.refresh(order)
    return order


def update_shipment(db: Session, export_order_id: int, data: schemas.ShipmentUpdate):
    order = get_export_order(db, export_order_id)
    if not order or not order.shipment:
        return None
    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(order.shipment, field, value)
    db.commit()
    db.refresh(order.shipment)
    return order.shipment


# ---------------------------------------------------------------
# Marketplace: Customer Orders
# ---------------------------------------------------------------
def create_customer_order(db: Session, customer_id: int, data: schemas.CustomerOrderCreate):
    try:
        order = models.CustomerOrder(
            CustomerID=customer_id,
            TotalAmount=0,
            PaymentStatus="Pending",
            OrderStatus="Processing",
            ShippingAddress=data.ShippingAddress,
        )
        db.add(order)
        db.flush()

        for item in data.Items:
            product = db.query(models.Product).filter(models.Product.ProductID == item.ProductID).first()
            if not product:
                raise ValueError(f"Product {item.ProductID} not found.")

            db.add(models.CustomerOrderItem(
                CustomerOrderID=order.CustomerOrderID,
                ProductID=item.ProductID,
                Quantity=item.Quantity,
                UnitPrice=product.Price,
            ))

            # deduct stock from the first warehouse that has enough units
            inv = (
                db.query(models.Inventory)
                .filter(models.Inventory.ProductID == item.ProductID, models.Inventory.Quantity >= item.Quantity)
                .first()
            )
            if not inv:
                raise ValueError(f"Insufficient stock for product {item.ProductID}.")
            inv.Quantity -= item.Quantity
            inv.StockStatus = (
                "Out of Stock" if inv.Quantity == 0 else "Low Stock" if inv.Quantity <= inv.ReorderLevel else "Available"
            )

        db.commit()
        db.refresh(order)
        return order
    except Exception:
        db.rollback()
        raise


def list_customer_orders(db: Session, customer_id: int):
    return (
        db.query(models.CustomerOrder)
        .filter(models.CustomerOrder.CustomerID == customer_id)
        .order_by(models.CustomerOrder.OrderDate.desc())
        .all()
    )


# ---------------------------------------------------------------
# Reviews / Certifications
# ---------------------------------------------------------------
def create_review(db: Session, customer_id: int, data: schemas.ReviewCreate):
    review = models.Review(CustomerID=customer_id, **data.model_dump())
    db.add(review)
    db.commit()
    db.refresh(review)

    # recompute the product's AverageRating
    avg = db.query(func.avg(models.Review.Rating)).filter(models.Review.ProductID == data.ProductID).scalar()
    product = db.query(models.Product).filter(models.Product.ProductID == data.ProductID).first()
    if product:
        product.AverageRating = round(float(avg or 0), 2)
        db.commit()

    return review


def list_reviews_for_product(db: Session, product_id: int):
    return db.query(models.Review).filter(models.Review.ProductID == product_id).all()


def create_certification(db: Session, data: schemas.CertificationCreate):
    cert = models.Certification(**data.model_dump())
    db.add(cert)
    db.commit()
    db.refresh(cert)
    return cert


def list_certifications_for_product(db: Session, product_id: int):
    return db.query(models.Certification).filter(models.Certification.ProductID == product_id).all()


# ---------------------------------------------------------------
# Analytics (backed by the SQL views created in 05_views.sql)
# ---------------------------------------------------------------
def dashboard_summary(db: Session) -> dict:
    total_manufacturers = db.query(func.count(models.Manufacturer.ManufacturerID)).filter(models.Manufacturer.IsActive == True).scalar()  # noqa: E712
    total_products = db.query(func.count(models.Product.ProductID)).filter(models.Product.IsActive == True).scalar()  # noqa: E712
    total_production_units = db.query(func.sum(models.ProductionBatch.Quantity)).filter(models.ProductionBatch.Status == "Completed").scalar() or 0
    total_inventory_units = db.query(func.sum(models.Inventory.Quantity)).scalar() or 0
    total_export_orders = db.query(func.count(models.ExportOrder.ExportOrderID)).scalar()
    total_export_revenue = db.query(func.sum(models.ExportOrder.TotalAmount)).filter(models.ExportOrder.ExportStatus != "Cancelled").scalar() or 0
    total_customers = db.query(func.count(models.Customer.CustomerID)).scalar()
    total_buyers = db.query(func.count(models.Client.ClientID)).scalar()

    top_country_row = (
        db.query(models.ExportOrder.DestinationCountry, func.sum(models.ExportOrder.TotalAmount).label("rev"))
        .filter(models.ExportOrder.ExportStatus != "Cancelled")
        .group_by(models.ExportOrder.DestinationCountry)
        .order_by(func.sum(models.ExportOrder.TotalAmount).desc())
        .first()
    )
    best_product_row = (
        db.query(models.Product.ProductName, func.sum(models.OrderDetail.Quantity).label("units"))
        .join(models.OrderDetail, models.OrderDetail.ProductID == models.Product.ProductID)
        .group_by(models.Product.ProductName)
        .order_by(func.sum(models.OrderDetail.Quantity).desc())
        .first()
    )

    return {
        "total_manufacturers": total_manufacturers,
        "total_products": total_products,
        "total_production_units": int(total_production_units),
        "total_inventory_units": int(total_inventory_units),
        "total_export_orders": total_export_orders,
        "total_export_revenue": total_export_revenue,
        "total_customers": total_customers,
        "total_buyers": total_buyers,
        "top_export_country": top_country_row[0] if top_country_row else None,
        "best_selling_product": best_product_row[0] if best_product_row else None,
    }


def revenue_by_country(db: Session):
    return db.execute(text("SELECT * FROM vw_ExportRevenueByCountry ORDER BY TotalRevenue DESC")).mappings().all()


def low_stock_products(db: Session):
    return db.execute(text("SELECT * FROM vw_LowStockProducts")).mappings().all()


def production_summary(db: Session):
    return db.execute(text("SELECT * FROM vw_ProductionSummary")).mappings().all()


def company_export_performance(db: Session):
    return db.execute(text("SELECT * FROM vw_CompanyExportPerformance ORDER BY TotalExportRevenue DESC")).mappings().all()


def product_sales_performance(db: Session):
    return db.execute(text("SELECT * FROM vw_ProductSalesPerformance")).mappings().all()


def top_export_markets(db: Session):
    return db.execute(text("SELECT * FROM vw_TopExportMarkets")).mappings().all()


def monthly_export_trend(db: Session):
    return db.execute(text("""
        SELECT DATEFROMPARTS(YEAR(eo.OrderDate), MONTH(eo.OrderDate), 1) AS MonthStart,
               SUM(od.LineTotal) AS Revenue
        FROM ExportOrder eo
        INNER JOIN OrderDetail od ON od.ExportOrderID = eo.ExportOrderID
        WHERE eo.ExportStatus <> 'Cancelled'
        GROUP BY DATEFROMPARTS(YEAR(eo.OrderDate), MONTH(eo.OrderDate), 1)
        ORDER BY MonthStart
    """)).mappings().all()
