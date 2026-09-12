# Backend — FastAPI

## Prerequisites

- Python 3.10+
- Microsoft SQL Server (local instance) with `FootballIndustryDB` already created (see `../database/README.md`)
- ODBC Driver 17 (or 18) for SQL Server installed on your machine
  - Windows: download from Microsoft's "ODBC Driver for SQL Server" page
  - macOS/Linux: install via `msodbcsql17`/`msodbcsql18` packages (see Microsoft's docs for your distro)

## Setup

```bash
cd backend
python -m venv venv

# Windows
venv\Scripts\activate
# macOS/Linux
source venv/bin/activate

pip install -r requirements.txt

copy .env.example .env      # Windows
cp .env.example .env        # macOS/Linux
```

Edit `.env` and set a real `DATABASE_URL` and a long random `SECRET_KEY`.

### Fix the demo login passwords

The SQL seed data ships with a placeholder password hash that will not verify. Generate a real one and apply it:

```bash
python -m app.utils.generate_demo_hashes
```

Copy the two `UPDATE` statements it prints and run them in SSMS against `FootballIndustryDB`. After this, every
seeded `Employee` and `Customer` account logs in with the password `Passw0rd!` (see root README for the full
list of demo emails).

## Run

```bash
uvicorn app.main:app --reload --port 8000
```

- API base: http://localhost:8000
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## Project layout

```
backend/
├── app/
│   ├── main.py            # FastAPI app, CORS, router registration
│   ├── config.py          # settings loaded from .env
│   ├── database.py        # SQLAlchemy engine/session (mssql+pyodbc)
│   ├── models/            # SQLAlchemy ORM models (mirror the SQL schema exactly)
│   ├── schemas/           # Pydantic request/response models
│   ├── crud/              # data-access functions used by routers
│   ├── routers/           # one file per module (auth, products, production, ...)
│   ├── auth/               # password hashing, JWT, role-based dependencies
│   └── utils/              # one-off scripts (demo password hash generator)
├── requirements.txt
└── .env.example
```

## Authentication

- `POST /api/auth/employee/login` and `/api/auth/customer/login` use the standard OAuth2 password flow
  (`username` + `password` form fields — `username` is the email). Both return a JWT plus the user's role.
- Attach the token as `Authorization: Bearer <token>` on subsequent requests.
- `app/auth/deps.py` exposes `require_roles("Admin", "ProductionManager", ...)` as a FastAPI dependency —
  each router applies it per-endpoint so, for example, only `ExportOfficer`/`Admin` can place export orders,
  while product browsing stays public for the marketplace.

## A note on transactions

`sp_PlaceExportOrder`, `trg_UpdateOrderTotal`, and `trg_PreventNegativeInventory` all live in the database
itself (see `database/06_stored_procedures.sql` and `07_triggers.sql`) — they fire no matter what client
touches the tables, including this API. The Python CRUD layer (`app/crud/*.py`) additionally wraps its own
multi-row operations (placing an export order, checking out a marketplace cart) in explicit
`try/except` blocks with `db.rollback()`, so a failure partway through an operation cannot leave partial rows
behind, matching the `BEGIN TRANSACTION / COMMIT / ROLLBACK` pattern demonstrated in `08_transactions.sql`.
