# Database Module — FootballIndustryDB

## Run order (in SSMS, connected to your local SQL Server instance)

1. `01_create_database.sql` — drops (if exists) and creates `FootballIndustryDB`
2. `02_create_tables.sql` — 19 tables, all PK/FK/CHECK/UNIQUE/DEFAULT constraints inline
3. `03_constraints_indexes.sql` — supporting nonclustered indexes
4. `04_seed_data.sql` — seed dataset (see Data Sources below)
5. `05_views.sql` — 7 reporting views
6. `06_stored_procedures.sql` — 1 table type + 5 stored procedures
7. `07_triggers.sql` — 3 triggers
8. `08_transactions.sql` — 3 standalone transaction demos (run after everything above; each block is idempotent-ish for demo purposes but will create new demo rows each run)
9. `09_reporting_queries.sql` — the required SQL concept catalog (joins, subqueries, CTEs, window functions, etc.)

Open each file in SSMS and execute with **F5** in order. Each script prints a confirmation message when it finishes.

## Why 19 tables instead of "10-15"?

The original report's 10 entities are all preserved (Manufacturer, Employee, Supplier, RawMaterial, Product,
ProductionBatch, Warehouse, Client, ExportOrder, OrderDetail). To support the expanded scope (QC, inventory,
marketplace, reviews, certifications, shipment tracking) without duplicating data, we added:
`QualityInspection`, `Inventory`, `Shipment`, `Customer`, `CustomerOrder`, `CustomerOrderItem`, `Review`,
`Certification`, and one junction table `BatchMaterialUsage`. The **Company Directory / Industry Intelligence**
module is *not* a separate table — it is implemented as additional columns on `Manufacturer`, because a
manufacturer and a "company directory entry" are the same real-world entity; a separate table would have
violated 3NF by duplicating identity attributes.

## Normalization notes (for your viva)

- **1NF**: every column holds a single atomic value (no comma-lists of products inside an order row — that's
  what `OrderDetail`/`CustomerOrderItem` junction tables are for).
- **2NF**: every non-key column depends on the *whole* primary key. Junction tables like `BatchMaterialUsage`
  and `OrderDetail` have composite/surrogate keys with no partial dependency — `QuantityUsed` depends on the
  (Batch, Material) pair, not on either alone.
- **3NF**: no transitive dependencies. E.g. `ExportOrder` does not store `ClientCountry` (that would depend on
  `ClientID`, not on `ExportOrderID`) — it's looked up via a JOIN to `Client` instead.

## Real vs. synthetic data

- **Verified**: identity facts (name, city, country, founding-era, company type) for well-known, publicly
  documented Sialkot/Pakistan football manufacturers (Forward Sports, Grand Sports, Saga Sports, Silver Star,
  Anwar Khawaja Industries, etc.) and one international manufacturer (Select Sport A/S, Denmark). No financial
  figures are fabricated for these real companies — `AnnualRevenueUSD` is left NULL because it is not
  reliably public.
- **Synthetic**: all transactional data (employees, production batches, export orders, customers, reviews,
  shipments) and additional demo manufacturers are clearly marked `DataType = 'Synthetic'` and use obviously
  fictitious names/emails (`*-demo.pk`, `*@footballindustry.local`). This data exists purely to give the
  database enough volume to demonstrate joins, aggregations, and reports.
- Every `Manufacturer` row carries `DataSource`, `DataType`, and `VerificationStatus` columns so the frontend
  can display an honest "Verified / Estimated / Synthetic" badge per company, per your report's requirement.

## Demo login credentials

All seeded `Employee` and `Customer` rows share the placeholder password hash in this SQL file. **Before
running the backend**, regenerate real bcrypt hashes for the demo password `Passw0rd!` using the helper script
`backend/app/utils/generate_demo_hashes.py` (see backend README) and re-run an `UPDATE` against `Employee`/
`Customer`, or simply re-seed through the FastAPI `/auth/register` endpoints once the backend is running.
