from fastapi import APIRouter, Depends, Header, HTTPException
from sqlalchemy.orm import Session
from datetime import date
from typing import List
from app.database import get_db
from app import schemas
from app.crud import export_marketplace_crud
from app.auth.deps import require_roles
from app.config import settings

router = APIRouter(prefix="/api/analytics", tags=["Analytics & Reports"])

STAFF_ROLES = ("Admin", "ProductionManager", "WarehouseStaff", "ExportOfficer", "QualityInspector")


@router.get("/dashboard", response_model=schemas.DashboardSummary)
def dashboard(db: Session = Depends(get_db), _emp=Depends(require_roles(*STAFF_ROLES))):
    """
    All figures here come directly from SQL Server via live queries --
    nothing is hardcoded on the frontend or backend.
    """
    return export_marketplace_crud.dashboard_summary(db)


@router.get("/export-revenue-by-country")
def export_revenue_by_country(db: Session = Depends(get_db), _emp=Depends(require_roles(*STAFF_ROLES))):
    """Backed by vw_ExportRevenueByCountry."""
    return export_marketplace_crud.revenue_by_country(db)


@router.get("/low-stock")
def low_stock(db: Session = Depends(get_db), _emp=Depends(require_roles(*STAFF_ROLES))):
    """Backed by vw_LowStockProducts. For the staff dashboard (JWT-protected)."""
    return export_marketplace_crud.low_stock_products(db)


@router.get("/low-stock/automation")
def low_stock_for_automation(db: Session = Depends(get_db), x_automation_key: str = Header(default="")):
    """
    Same data as /low-stock, but secured with the shared automation key
    instead of a JWT so the n8n 'Low Stock Alert' schedule-triggered
    workflow can call it directly (see n8n/README.md).
    """
    if not settings.N8N_AUTOMATION_KEY or x_automation_key != settings.N8N_AUTOMATION_KEY:
        raise HTTPException(status_code=401, detail="Invalid or missing automation key.")
    return export_marketplace_crud.low_stock_products(db)


@router.get("/production-summary")
def production_summary(db: Session = Depends(get_db), _emp=Depends(require_roles(*STAFF_ROLES))):
    """Backed by vw_ProductionSummary."""
    return export_marketplace_crud.production_summary(db)


@router.get("/company-performance")
def company_performance(db: Session = Depends(get_db)):
    """
    Backed by vw_CompanyExportPerformance. Public endpoint --
    powers the Compare Companies and Manufacturer Ranking pages.
    IndustryScore shown alongside this is explicitly labelled
    'System Calculated Industry Score' by the frontend, never an
    official ranking.
    """
    return export_marketplace_crud.company_export_performance(db)


@router.get("/product-sales-performance")
def product_sales_performance(db: Session = Depends(get_db), _emp=Depends(require_roles(*STAFF_ROLES))):
    """Backed by vw_ProductSalesPerformance."""
    return export_marketplace_crud.product_sales_performance(db)


@router.get("/top-export-markets")
def top_export_markets(db: Session = Depends(get_db), _emp=Depends(require_roles(*STAFF_ROLES))):
    """Backed by vw_TopExportMarkets (uses RANK() window function)."""
    return export_marketplace_crud.top_export_markets(db)


@router.get("/monthly-export-trend")
def monthly_export_trend(db: Session = Depends(get_db), _emp=Depends(require_roles(*STAFF_ROLES))):
    return export_marketplace_crud.monthly_export_trend(db)


@router.get("/scheduled-report-summary")
def scheduled_report_summary(db: Session = Depends(get_db), x_automation_key: str = Header(default="")):
    """
    Used by the n8n 'Scheduled Report' workflow (see n8n/README.md). Secured
    with a shared secret header rather than a JWT so a scheduled n8n job
    doesn't need to manage a login/token-refresh flow -- set N8N_AUTOMATION_KEY
    in both this backend's .env and the n8n workflow's HTTP Request node.
    """
    if not settings.N8N_AUTOMATION_KEY or x_automation_key != settings.N8N_AUTOMATION_KEY:
        raise HTTPException(status_code=401, detail="Invalid or missing automation key.")

    return {
        "dashboard": export_marketplace_crud.dashboard_summary(db),
        "low_stock_items": export_marketplace_crud.low_stock_products(db),
        "top_export_markets": export_marketplace_crud.top_export_markets(db)[:5],
    }
