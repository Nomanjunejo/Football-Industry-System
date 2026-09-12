"""
Data-access layer. Each function does one thing against the DB
session; routers call these instead of embedding raw ORM calls,
which keeps HTTP concerns (status codes) separate from persistence.
"""

from sqlalchemy.orm import Session
from sqlalchemy import func

from app import models, schemas
from app.auth.security import hash_password


# ===============================================================
# Employee / Auth
# ===============================================================

def get_employee_by_email(db: Session, email: str):
    return (
        db.query(models.Employee)
        .filter(models.Employee.Email == email)
        .first()
    )


def create_employee(db: Session, data: schemas.EmployeeCreate):
    emp = models.Employee(
        FullName=data.full_name,
        Email=data.email,
        PasswordHash=hash_password(data.password),
        Role=data.role,
        Department=data.department,
        Phone=data.phone,
    )

    db.add(emp)
    db.commit()
    db.refresh(emp)

    return emp


def get_customer_by_email(db: Session, email: str):
    return (
        db.query(models.Customer)
        .filter(models.Customer.Email == email)
        .first()
    )


def create_customer(db: Session, data: schemas.CustomerRegister):
    cust = models.Customer(
        FullName=data.full_name,
        Email=data.email,
        PasswordHash=hash_password(data.password),
        Phone=data.phone,
        Country=data.country,
        City=data.city,
        Address=data.address,
    )

    db.add(cust)
    db.commit()
    db.refresh(cust)

    return cust


# ===============================================================
# Manufacturer
# ===============================================================

def list_manufacturers(
    db: Session,
    country: str | None = None,
    skip: int = 0,
    limit: int = 100,
):
    q = (
        db.query(models.Manufacturer)
        .filter(models.Manufacturer.IsActive == True)  # noqa: E712
    )

    if country:
        q = q.filter(models.Manufacturer.Country == country)

    # SQL Server requires ORDER BY when using OFFSET/LIMIT
    return (
        q.order_by(models.Manufacturer.ManufacturerID)
        .offset(skip)
        .limit(limit)
        .all()
    )


def get_manufacturer(db: Session, manufacturer_id: int):
    return (
        db.query(models.Manufacturer)
        .filter(
            models.Manufacturer.ManufacturerID == manufacturer_id
        )
        .first()
    )


def create_manufacturer(
    db: Session,
    data: schemas.ManufacturerCreate,
):
    m = models.Manufacturer(**data.model_dump())

    db.add(m)
    db.commit()
    db.refresh(m)

    return m


def update_manufacturer(
    db: Session,
    manufacturer_id: int,
    data: schemas.ManufacturerUpdate,
):
    m = get_manufacturer(db, manufacturer_id)

    if not m:
        return None

    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(m, field, value)

    db.commit()
    db.refresh(m)

    return m


def delete_manufacturer(
    db: Session,
    manufacturer_id: int,
):
    m = get_manufacturer(db, manufacturer_id)

    if not m:
        return False

    m.IsActive = False

    db.commit()

    return True


# ===============================================================
# Supplier / RawMaterial
# ===============================================================

def list_suppliers(
    db: Session,
    skip: int = 0,
    limit: int = 100,
):
    return (
        db.query(models.Supplier)
        .filter(models.Supplier.IsActive == True)  # noqa: E712
        .order_by(models.Supplier.SupplierID)
        .offset(skip)
        .limit(limit)
        .all()
    )


def create_supplier(
    db: Session,
    data: schemas.SupplierCreate,
):
    s = models.Supplier(**data.model_dump())

    db.add(s)
    db.commit()
    db.refresh(s)

    return s


def list_raw_materials(
    db: Session,
    skip: int = 0,
    limit: int = 100,
):
    return (
        db.query(models.RawMaterial)
        .order_by(models.RawMaterial.RawMaterialID)
        .offset(skip)
        .limit(limit)
        .all()
    )


def create_raw_material(
    db: Session,
    data: schemas.RawMaterialCreate,
):
    rm = models.RawMaterial(**data.model_dump())

    db.add(rm)
    db.commit()
    db.refresh(rm)

    return rm


# ===============================================================
# Product
# ===============================================================

def list_products(
    db: Session,
    category: str | None = None,
    manufacturer_id: int | None = None,
    search: str | None = None,
    skip: int = 0,
    limit: int = 50,
):
    q = (
        db.query(models.Product)
        .filter(models.Product.IsActive == True)  # noqa: E712
    )

    if category:
        q = q.filter(
            models.Product.Category == category
        )

    if manufacturer_id:
        q = q.filter(
            models.Product.ManufacturerID == manufacturer_id
        )

    if search:
        q = q.filter(
            models.Product.ProductName.ilike(
                f"%{search}%"
            )
        )

    # SQL Server requires ORDER BY when using OFFSET/LIMIT
    return (
        q.order_by(models.Product.ProductID)
        .offset(skip)
        .limit(limit)
        .all()
    )


def get_product(
    db: Session,
    product_id: int,
):
    return (
        db.query(models.Product)
        .filter(
            models.Product.ProductID == product_id
        )
        .first()
    )


def create_product(
    db: Session,
    data: schemas.ProductCreate,
):
    p = models.Product(**data.model_dump())

    db.add(p)
    db.commit()
    db.refresh(p)

    return p


def update_product(
    db: Session,
    product_id: int,
    data: schemas.ProductUpdate,
):
    p = get_product(db, product_id)

    if not p:
        return None

    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(p, field, value)

    db.commit()
    db.refresh(p)

    return p


def delete_product(
    db: Session,
    product_id: int,
):
    p = get_product(db, product_id)

    if not p:
        return False

    p.IsActive = False

    db.commit()

    return True


# ===============================================================
# Production Batch / Quality Inspection
# ===============================================================

def list_batches(
    db: Session,
    status: str | None = None,
    skip: int = 0,
    limit: int = 100,
):
    q = db.query(models.ProductionBatch)

    if status:
        q = q.filter(
            models.ProductionBatch.Status == status
        )

    return (
        q.order_by(
            models.ProductionBatch.ProductionDate.desc()
        )
        .offset(skip)
        .limit(limit)
        .all()
    )


def create_batch(
    db: Session,
    data: schemas.ProductionBatchCreate,
):
    b = models.ProductionBatch(
        **data.model_dump(),
        Status="Planned",
    )

    db.add(b)
    db.commit()
    db.refresh(b)

    return b


def update_batch_status(
    db: Session,
    batch_id: int,
    data: schemas.ProductionBatchStatusUpdate,
):
    b = (
        db.query(models.ProductionBatch)
        .filter(
            models.ProductionBatch.BatchID == batch_id
        )
        .first()
    )

    if not b:
        return None

    b.Status = data.Status

    if data.CompletionDate:
        b.CompletionDate = data.CompletionDate

    db.commit()
    db.refresh(b)

    return b


def create_inspection(
    db: Session,
    data: schemas.QualityInspectionCreate,
):
    """
    A FAILED batch never becomes sellable inventory.

    The batch's own Status remains whatever the production
    manager set it to.

    Inventory is updated by the database trigger only when:
        Status = 'Completed'
        AND
        QualityInspection.Status = 'PASS'
    """

    qi = models.QualityInspection(
        **data.model_dump()
    )

    db.add(qi)
    db.commit()
    db.refresh(qi)

    return qi


# ===============================================================
# Warehouse / Inventory
# ===============================================================

def list_warehouses(db: Session):
    return (
        db.query(models.Warehouse)
        .all()
    )


def create_warehouse(
    db: Session,
    data: schemas.WarehouseCreate,
):
    w = models.Warehouse(**data.model_dump())

    db.add(w)
    db.commit()
    db.refresh(w)

    return w


def list_inventory(
    db: Session,
    warehouse_id: int | None = None,
    low_stock_only: bool = False,
):
    q = db.query(models.Inventory)

    if warehouse_id:
        q = q.filter(
            models.Inventory.WarehouseID == warehouse_id
        )

    if low_stock_only:
        q = q.filter(
            models.Inventory.Quantity
            <= models.Inventory.ReorderLevel
        )

    return q.all()


def adjust_inventory(
    db: Session,
    data: schemas.InventoryAdjust,
):
    """
    Mirrors sp_UpdateInventory.

    Adjusts stock by a signed delta inside
    a single transaction and refuses to let
    inventory become negative.
    """

    row = (
        db.query(models.Inventory)
        .filter(
            models.Inventory.ProductID == data.ProductID,
            models.Inventory.WarehouseID == data.WarehouseID,
        )
        .with_for_update()
        .first()
    )

    if not row:
        row = models.Inventory(
            ProductID=data.ProductID,
            WarehouseID=data.WarehouseID,
            Quantity=0,
            ReorderLevel=50,
        )

        db.add(row)
        db.flush()

    new_qty = row.Quantity + data.QuantityDelta

    if new_qty < 0:
        db.rollback()

        raise ValueError(
            "Insufficient stock: operation would result "
            "in negative inventory."
        )

    row.Quantity = new_qty

    row.StockStatus = (
        "Out of Stock"
        if new_qty == 0
        else "Low Stock"
        if new_qty <= row.ReorderLevel
        else "Available"
    )

    db.commit()
    db.refresh(row)

    return row