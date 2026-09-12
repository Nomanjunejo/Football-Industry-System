from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import Optional, List
from app.database import get_db
from app import schemas
from app.crud import manufacturing_crud
from app.auth.deps import require_roles

router = APIRouter(prefix="/api/manufacturers", tags=["Manufacturers / Company Directory"])


@router.get("", response_model=List[schemas.ManufacturerOut])
def list_manufacturers(country: Optional[str] = None, skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """Public endpoint -- powers the Companies directory page."""
    return manufacturing_crud.list_manufacturers(db, country=country, skip=skip, limit=limit)


@router.get("/{manufacturer_id}", response_model=schemas.ManufacturerOut)
def get_manufacturer(manufacturer_id: int, db: Session = Depends(get_db)):
    m = manufacturing_crud.get_manufacturer(db, manufacturer_id)
    if not m:
        raise HTTPException(status_code=404, detail="Manufacturer not found.")
    return m


@router.post("", response_model=schemas.ManufacturerOut)
def create_manufacturer(data: schemas.ManufacturerCreate, db: Session = Depends(get_db), _admin=Depends(require_roles("Admin"))):
    return manufacturing_crud.create_manufacturer(db, data)


@router.put("/{manufacturer_id}", response_model=schemas.ManufacturerOut)
def update_manufacturer(manufacturer_id: int, data: schemas.ManufacturerUpdate, db: Session = Depends(get_db), _admin=Depends(require_roles("Admin"))):
    m = manufacturing_crud.update_manufacturer(db, manufacturer_id, data)
    if not m:
        raise HTTPException(status_code=404, detail="Manufacturer not found.")
    return m


@router.delete("/{manufacturer_id}")
def delete_manufacturer(manufacturer_id: int, db: Session = Depends(get_db), _admin=Depends(require_roles("Admin"))):
    ok = manufacturing_crud.delete_manufacturer(db, manufacturer_id)
    if not ok:
        raise HTTPException(status_code=404, detail="Manufacturer not found.")
    return {"detail": "Manufacturer deactivated."}
