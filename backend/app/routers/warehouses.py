from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import Optional, List
from app.database import get_db
from app import schemas
from app.crud import manufacturing_crud
from app.auth.deps import require_roles

router = APIRouter(prefix="/api/warehouses", tags=["Warehouses & Inventory"])


@router.get("", response_model=List[schemas.WarehouseOut])
def list_warehouses(db: Session = Depends(get_db)):
    return manufacturing_crud.list_warehouses(db)


@router.post("", response_model=schemas.WarehouseOut)
def create_warehouse(data: schemas.WarehouseCreate, db: Session = Depends(get_db),
                      _admin=Depends(require_roles("Admin"))):
    return manufacturing_crud.create_warehouse(db, data)


@router.get("/inventory", response_model=List[schemas.InventoryOut])
def list_inventory(warehouse_id: Optional[int] = None, low_stock_only: bool = False, db: Session = Depends(get_db),
                    _emp=Depends(require_roles("Admin", "WarehouseStaff", "ProductionManager"))):
    return manufacturing_crud.list_inventory(db, warehouse_id, low_stock_only)


@router.post("/inventory/adjust", response_model=schemas.InventoryOut)
def adjust_inventory(data: schemas.InventoryAdjust, db: Session = Depends(get_db),
                      _emp=Depends(require_roles("Admin", "WarehouseStaff"))):
    """Equivalent to sp_UpdateInventory: adjusts stock by a signed delta, rejecting negative results."""
    try:
        return manufacturing_crud.adjust_inventory(db, data)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
