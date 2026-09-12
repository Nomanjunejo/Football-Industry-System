# Frontend — React + Vite

## Setup

```bash
cd frontend
npm install
cp .env.example .env    # macOS/Linux
copy .env.example .env  # Windows
```

Edit `.env` if your backend isn't running on the default `http://localhost:8000`.

## Run

```bash
npm run dev
```

Open http://localhost:5173. The backend must already be running on port 8000 (CORS is configured for this
exact origin in `backend/app/config.py` / `.env`).

## Structure

```
frontend/src/
├── components/    # Navbar, Footer, DataTable, StatCard, Badge, route guards
├── layouts/       # PublicLayout (navbar+footer), AdminLayout (sidebar)
├── pages/
│   ├── public/    # Home, Companies, CompanyDetails, Products, ProductDetails, About, Compare, Ranking
│   ├── admin/     # Login, Dashboard, Manufacturers, Suppliers, Products, Production, QC, Warehouses, Clients, ExportOrders, Reports
│   └── customer/  # Login, Register, Cart, Checkout, MyOrders
├── context/       # AuthContext (JWT session), CartContext (in-memory cart)
├── services/      # api.js (axios + interceptors), authService.js, resourceService.js (all 37 endpoints)
├── App.jsx        # all routes
└── main.jsx       # entry point
```

## Notes

- Verified with `npm run build` (Vite production build) — zero errors, 924 modules transformed.
- The cart is kept in React state only (per the project's `localStorage`/`sessionStorage` restriction for
  in-browser demos) — it resets on page refresh. This is intentional and documented in code comments.
- Role-based UI: `RequireStaff` / `RequireCustomer` route guards in `components/ProtectedRoute.jsx` mirror the
  backend's `require_roles(...)` dependency, so a Warehouse Staff account, for example, can log in but the
  backend will still return 403 on endpoints outside their role even if a stale UI element were clicked.
- Dynamic Tailwind class names (e.g. `text-${accent}-700`) are deliberately avoided throughout — Tailwind's
  JIT compiler only generates CSS for class names it can find literally in source, so anything built from a
  variable silently renders unstyled. See the comment in `components/StatCard.jsx`.
