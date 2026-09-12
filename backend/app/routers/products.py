from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import Optional, List
from app.database import get_db
from app import schemas
from app.crud import manufacturing_crud, export_marketplace_crud
from app.auth.deps import require_roles

router = APIRouter(prefix="/api/products", tags=["Products"])


@router.get("", response_model=List[schemas.ProductOut])
def list_products(category: Optional[str] = None, manufacturer_id: Optional[int] = None,
                   search: Optional[str] = None, skip: int = 0, limit: int = 50,
                   db: Session = Depends(get_db)):
    """Public endpoint -- powers the marketplace Products page (search/filter)."""
    return manufacturing_crud.list_products(db, category, manufacturer_id, search, skip, limit)


@router.get("/{product_id}", response_model=schemas.ProductOut)
def get_product(product_id: int, db: Session = Depends(get_db)):
    p = manufacturing_crud.get_product(db, product_id)
    if not p:
        raise HTTPException(status_code=404, detail="Product not found.")
    return p


@router.get("/{product_id}/reviews", response_model=List[schemas.ReviewOut])
def get_product_reviews(product_id: int, db: Session = Depends(get_db)):
    return export_marketplace_crud.list_reviews_for_product(db, product_id)


@router.get("/{product_id}/certifications", response_model=List[schemas.CertificationOut])
def get_product_certifications(product_id: int, db: Session = Depends(get_db)):
    return export_marketplace_crud.list_certifications_for_product(db, product_id)


@router.post("", response_model=schemas.ProductOut)
def create_product(data: schemas.ProductCreate, db: Session = Depends(get_db),
                    _emp=Depends(require_roles("Admin", "ProductionManager"))):
    return manufacturing_crud.create_product(db, data)


@router.put("/{product_id}", response_model=schemas.ProductOut)
def update_product(product_id: int, data: schemas.ProductUpdate, db: Session = Depends(get_db),
                    _emp=Depends(require_roles("Admin", "ProductionManager"))):
    p = manufacturing_crud.update_product(db, product_id, data)
    if not p:
        raise HTTPException(status_code=404, detail="Product not found.")
    return p


@router.delete("/{product_id}")
def delete_product(product_id: int, db: Session = Depends(get_db), _admin=Depends(require_roles("Admin"))):
    ok = manufacturing_crud.delete_product(db, product_id)
    if not ok:
        raise HTTPException(status_code=404, detail="Product not found.")
    return {"detail": "Product deactivated."}


@router.post("/certifications", response_model=schemas.CertificationOut)
def add_certification(data: schemas.CertificationCreate, db: Session = Depends(get_db),
                       _emp=Depends(require_roles("Admin", "ProductionManager"))):
    return export_marketplace_crud.create_certification(db, data)
