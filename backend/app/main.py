from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.config import settings
from app.routers import (
    auth, manufacturers, suppliers, products, production,
    warehouses, export_orders, marketplace, analytics,
)

app = FastAPI(
    title="Football Manufacturing, Export, Industry Intelligence & E-Commerce Management System",
    description=(
        "University DBMS lab project. The relational database (Microsoft SQL Server) is the "
        "core of this system; this API is a thin, validated layer over its tables, views, and "
        "stored procedures. See /docs for interactive Swagger documentation."
    ),
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:5173",
        "http://127.0.0.1:5173",
        settings.FRONTEND_URL,
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(manufacturers.router)
app.include_router(suppliers.router)
app.include_router(products.router)
app.include_router(production.router)
app.include_router(warehouses.router)
app.include_router(export_orders.router)
app.include_router(marketplace.router)
app.include_router(analytics.router)


@app.get("/", tags=["Health"])
def root():
    return {"status": "ok", "service": "Football Industry Management System API"}


@app.get("/api/health", tags=["Health"])
def health():
    return {"status": "healthy"}
