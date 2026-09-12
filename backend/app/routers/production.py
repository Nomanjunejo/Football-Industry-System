from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import Optional, List
from app.database import get_db
from app import schemas
from app.crud import manufacturing_crud
from app.auth.deps import require_roles

router = APIRouter(prefix="/api/production", tags=["Manufacturing & Quality Control"])


@router.get("/batches", response_model=List[schemas.ProductionBatchOut])
def list_batches(status: Optional[str] = None, skip: int = 0, limit: int = 100, db: Session = Depends(get_db),
                  _emp=Depends(require_roles("Admin", "ProductionManager", "WarehouseStaff", "QualityInspector"))):
    return manufacturing_crud.list_batches(db, status, skip, limit)


@router.post("/batches", response_model=schemas.ProductionBatchOut)
def create_batch(data: schemas.ProductionBatchCreate, db: Session = Depends(get_db),
                  _emp=Depends(require_roles("Admin", "ProductionManager"))):
    """
    Statuses progress: Planned -> In Production -> Completed/Failed/Cancelled.
    Use PATCH /batches/{id}/status to move a batch through its lifecycle.
    """
    return manufacturing_crud.create_batch(db, data)


@router.patch("/batches/{batch_id}/status", response_model=schemas.ProductionBatchOut)
def update_batch_status(batch_id: int, data: schemas.ProductionBatchStatusUpdate, db: Session = Depends(get_db),
                         _emp=Depends(require_roles("Admin", "ProductionManager"))):
    """
    Setting Status='Completed' here does NOT by itself make a batch
    sellable -- trg_UpdateInventoryAfterBatch only stocks inventory
    once a QualityInspection with Status='PASS' also exists for this
    batch (see POST /production/inspections).
    """
    b = manufacturing_crud.update_batch_status(db, batch_id, data)
    if not b:
        raise HTTPException(status_code=404, detail="Production batch not found.")
    return b


@router.post("/inspections", response_model=schemas.QualityInspectionOut)
def create_inspection(data: schemas.QualityInspectionCreate, db: Session = Depends(get_db),
                       _emp=Depends(require_roles("Admin", "QualityInspector"))):
    return manufacturing_crud.create_inspection(db, data)
