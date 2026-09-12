from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import Optional, List
from app.database import get_db
from app import schemas
from app.crud import export_marketplace_crud
from app.services import n8n_notify
from app.auth.deps import require_roles

router = APIRouter(prefix="/api/export", tags=["Export Management"])


@router.get("/clients", response_model=List[schemas.ClientOut])
def list_clients(skip: int = 0, limit: int = 100, db: Session = Depends(get_db),
                  _emp=Depends(require_roles("Admin", "ExportOfficer"))):
    return export_marketplace_crud.list_clients(db, skip, limit)


@router.post("/clients", response_model=schemas.ClientOut)
def create_client(data: schemas.ClientCreate, db: Session = Depends(get_db),
                   _emp=Depends(require_roles("Admin", "ExportOfficer"))):
    return export_marketplace_crud.create_client(db, data)


@router.get("/orders", response_model=List[schemas.ExportOrderOut])
def list_export_orders(status: Optional[str] = None, country: Optional[str] = None,
                        skip: int = 0, limit: int = 100, db: Session = Depends(get_db),
                        _emp=Depends(require_roles("Admin", "ExportOfficer"))):
    return export_marketplace_crud.list_export_orders(db, status, country, skip, limit)


@router.get("/orders/{export_order_id}", response_model=schemas.ExportOrderOut)
def get_export_order(export_order_id: int, db: Session = Depends(get_db),
                      _emp=Depends(require_roles("Admin", "ExportOfficer"))):
    order = export_marketplace_crud.get_export_order(db, export_order_id)
    if not order:
        raise HTTPException(status_code=404, detail="Export order not found.")
    return order


@router.post("/orders", response_model=schemas.ExportOrderOut)
def place_export_order(data: schemas.ExportOrderCreate, db: Session = Depends(get_db),
                        _emp=Depends(require_roles("Admin", "ExportOfficer"))):
    """
    Equivalent to sp_PlaceExportOrder: creates the order header, its
    OrderDetail lines, and an initial Shipment row inside one
    transaction. TotalAmount is kept correct by trg_UpdateOrderTotal.
    """
    try:
        order = export_marketplace_crud.create_export_order(db, data)
        n8n_notify.notify_new_export_order(order)
        return order
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.patch("/orders/{export_order_id}/status", response_model=schemas.ExportOrderOut)
def update_export_order_status(export_order_id: int, data: schemas.ExportOrderStatusUpdate,
                                db: Session = Depends(get_db),
                                _emp=Depends(require_roles("Admin", "ExportOfficer"))):
    order = export_marketplace_crud.update_export_order_status(db, export_order_id, data)
    if not order:
        raise HTTPException(status_code=404, detail="Export order not found.")
    return order


@router.patch("/orders/{export_order_id}/shipment", response_model=schemas.ShipmentOut)
def update_shipment(export_order_id: int, data: schemas.ShipmentUpdate, db: Session = Depends(get_db),
                     _emp=Depends(require_roles("Admin", "ExportOfficer", "WarehouseStaff"))):
    """
    Used by the n8n 'Shipment Update' workflow: FastAPI updates the
    Shipment row, then the caller (n8n) fires a notification.
    """
    shipment = export_marketplace_crud.update_shipment(db, export_order_id, data)
    if not shipment:
        raise HTTPException(status_code=404, detail="Shipment not found for this export order.")
    n8n_notify.notify_shipment_update(shipment)
    return shipment
