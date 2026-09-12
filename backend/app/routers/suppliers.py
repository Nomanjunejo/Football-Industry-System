from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from typing import List
from app.database import get_db
from app import schemas
from app.crud import manufacturing_crud
from app.auth.deps import require_roles

router = APIRouter(prefix="/api/suppliers", tags=["Suppliers & Raw Materials"])


@router.get("", response_model=List[schemas.SupplierOut])
def list_suppliers(skip: int = 0, limit: int = 100, db: Session = Depends(get_db),
                    _emp=Depends(require_roles("Admin", "ProductionManager"))):
    return manufacturing_crud.list_suppliers(db, skip, limit)


@router.post("", response_model=schemas.SupplierOut)
def create_supplier(data: schemas.SupplierCreate, db: Session = Depends(get_db),
                     _emp=Depends(require_roles("Admin", "ProductionManager"))):
    return manufacturing_crud.create_supplier(db, data)


@router.get("/raw-materials", response_model=List[schemas.RawMaterialOut])
def list_raw_materials(skip: int = 0, limit: int = 100, db: Session = Depends(get_db),
                        _emp=Depends(require_roles("Admin", "ProductionManager"))):
    return manufacturing_crud.list_raw_materials(db, skip, limit)


@router.post("/raw-materials", response_model=schemas.RawMaterialOut)
def create_raw_material(data: schemas.RawMaterialCreate, db: Session = Depends(get_db),
                         _emp=Depends(require_roles("Admin", "ProductionManager"))):
    return manufacturing_crud.create_raw_material(db, data)
