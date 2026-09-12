from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from app.database import get_db
from app.auth.security import decode_access_token
from app import models

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/employee/login", auto_error=False)


def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    """
    Decodes the JWT and returns a dict describing whoever is logged in:
    {"type": "employee"|"customer", "id": int, "role": str}
    Raises 401 if the token is missing/invalid/expired.
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    if token is None:
        raise credentials_exception

    payload = decode_access_token(token)
    if payload is None:
        raise credentials_exception

    subject_type = payload.get("type")
    subject_id = payload.get("sub")
    role = payload.get("role")
    if subject_type is None or subject_id is None:
        raise credentials_exception

    if subject_type == "employee":
        user = db.query(models.Employee).filter(models.Employee.EmployeeID == int(subject_id)).first()
        if user is None or not user.IsActive:
            raise credentials_exception
    else:
        user = db.query(models.Customer).filter(models.Customer.CustomerID == int(subject_id)).first()
        if user is None:
            raise credentials_exception

    return {"type": subject_type, "id": int(subject_id), "role": role, "record": user}


def require_roles(*allowed_roles: str):
    """
    Dependency factory: require_roles("Admin", "ProductionManager")
    Restricts an endpoint to specific employee roles. Customers are
    always rejected by this dependency (marketplace endpoints use
    get_current_user directly and check type == "customer" instead).
    """
    def dependency(current_user: dict = Depends(get_current_user)):
        if current_user["type"] != "employee" or current_user["role"] not in allowed_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You do not have permission to perform this action.",
            )
        return current_user
    return dependency


def require_customer(current_user: dict = Depends(get_current_user)):
    if current_user["type"] != "customer":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Customer account required.")
    return current_user
