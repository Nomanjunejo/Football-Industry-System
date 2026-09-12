from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from app.database import get_db
from app import schemas
from app.crud import manufacturing_crud
from app.auth.security import verify_password, create_access_token
from app.auth.deps import require_roles

router = APIRouter(prefix="/api/auth", tags=["Authentication"])


@router.post("/employee/login", response_model=schemas.Token)
def employee_login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    """
    OAuth2PasswordRequestForm expects 'username' + 'password' fields
    (standard for FastAPI/Swagger's built-in login form). We treat
    'username' as the employee's email.
    """
    employee = manufacturing_crud.get_employee_by_email(db, form_data.username)
    if not employee or not verify_password(form_data.password, employee.PasswordHash):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Incorrect email or password")
    if not employee.IsActive:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="This account has been deactivated")

    token = create_access_token({"sub": str(employee.EmployeeID), "type": "employee", "role": employee.Role})
    return schemas.Token(access_token=token, role=employee.Role, full_name=employee.FullName, user_id=employee.EmployeeID)


@router.post("/employee/register", response_model=schemas.EmployeeOut)
def register_employee(
    data: schemas.EmployeeCreate,
    db: Session = Depends(get_db),
    _admin=Depends(require_roles("Admin")),
):
    """Only an Admin can create new staff accounts."""
    if manufacturing_crud.get_employee_by_email(db, data.email):
        raise HTTPException(status_code=400, detail="An employee with this email already exists.")
    return manufacturing_crud.create_employee(db, data)


@router.post("/customer/register", response_model=schemas.CustomerOut)
def register_customer(data: schemas.CustomerRegister, db: Session = Depends(get_db)):
    if manufacturing_crud.get_customer_by_email(db, data.email):
        raise HTTPException(status_code=400, detail="An account with this email already exists.")
    return manufacturing_crud.create_customer(db, data)


@router.post("/customer/login", response_model=schemas.Token)
def customer_login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    customer = manufacturing_crud.get_customer_by_email(db, form_data.username)
    if not customer or not verify_password(form_data.password, customer.PasswordHash):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Incorrect email or password")

    token = create_access_token({"sub": str(customer.CustomerID), "type": "customer", "role": "Customer"})
    return schemas.Token(access_token=token, role="Customer", full_name=customer.FullName, user_id=customer.CustomerID)
