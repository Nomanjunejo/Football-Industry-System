from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from app.database import get_db
from app import schemas
from app.crud import export_marketplace_crud
from app.auth.deps import require_customer

router = APIRouter(prefix="/api/marketplace", tags=["Marketplace (Customer)"])


@router.post("/checkout", response_model=schemas.CustomerOrderOut)
def checkout(data: schemas.CustomerOrderCreate, db: Session = Depends(get_db),
             current_user: dict = Depends(require_customer)):
    """
    Places a marketplace order for the logged-in customer. Payment is
    simulated -- no real payment gateway is called; PaymentStatus
    starts as 'Pending' and can be marked 'Paid' by the demo checkout
    flow in the frontend.
    """
    try:
        return export_marketplace_crud.create_customer_order(db, current_user["id"], data)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/orders", response_model=List[schemas.CustomerOrderOut])
def my_orders(db: Session = Depends(get_db), current_user: dict = Depends(require_customer)):
    return export_marketplace_crud.list_customer_orders(db, current_user["id"])


@router.post("/reviews", response_model=schemas.ReviewOut)
def leave_review(data: schemas.ReviewCreate, db: Session = Depends(get_db),
                  current_user: dict = Depends(require_customer)):
    try:
        return export_marketplace_crud.create_review(db, current_user["id"], data)
    except Exception as e:
        raise HTTPException(status_code=400, detail="You may have already reviewed this product.")
