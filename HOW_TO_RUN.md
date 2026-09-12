# How to Run — Full Procedure (Database → Backend → Frontend → n8n)

## Part 1: Database — one script instead of nine

`00_run_all.sql` is `01_create_database.sql` through `09_reporting_queries.sql` concatenated into a single
file, in the correct order, with each original file's `GO` batch separators preserved. Running this ONE file
does everything the 9 separate files would do together.

### Steps

1. Open **SQL Server Management Studio (SSMS)**.
2. **Connect** to your local SQL Server instance (usually `localhost` or `localhost\SQLEXPRESS` — whatever
   you chose during SQL Server installation; Windows Authentication is fine for a local dev machine).
3. **File → Open → File...** → select `00_run_all.sql`.
4. Press **F5** (or the "Execute" ▶ button).
5. Watch the **Messages** tab at the bottom. You should see a sequence of `PRINT` confirmations ending in:
   ```
   Combined script finished successfully.
   ```
   If you see a red error instead, scroll up in the Messages tab to find the first error — fix that one
   thing and re-run the whole script from the top (it's safe to re-run: `01_create_database.sql`'s logic
   drops and recreates `FootballIndustryDB` first, so you always start clean).
6. In the **Object Explorer** (left panel), refresh **Databases**, expand `FootballIndustryDB` → `Tables` —
   you should see 19 tables with data already in them (right-click any table → "Select Top 1000 Rows" to
   check).

That's the entire database step. You never need to touch `01`–`09` individually unless you specifically want
to re-run just one part (e.g., re-seed data without recreating tables) — in that case, open and run only that
one numbered file instead.

## Part 2: Understanding how everything connects

**SSMS is not in the request path.** It's a tool you use once (or occasionally) to set up and inspect the
database by hand. The actual, live connection your website uses is:

```
Browser (you)
   │  HTTP requests (clicking buttons, viewing pages)
   ▼
React frontend — http://localhost:5173
   │  Axios calls, e.g. GET /api/products
   ▼
FastAPI backend — http://localhost:8000
   │  SQLAlchemy + pyodbc, using the DATABASE_URL in backend/.env
   ▼
SQL Server engine — FootballIndustryDB
```

- The **frontend never talks to SQL Server directly** — it only ever calls the FastAPI backend over HTTP.
- The **backend connects to SQL Server the same way SSMS does** — as a client, using a connection string
  (`backend/.env` → `DATABASE_URL`), not "through" SSMS in any way. SSMS could be closed and the backend
  would work identically.
- SQL Server itself must simply be **running** (as a Windows service, typically started automatically) for
  either SSMS or the backend to connect to it.

## Part 3: Full run procedure, start to finish

### Step 1 — Confirm SQL Server is running
Open **Services** (Windows: `services.msc`) and confirm "SQL Server (MSSQLSERVER)" or
"SQL Server (SQLEXPRESS)" shows **Running**. If not, right-click → Start.

### Step 2 — Build the database
Run `database/00_run_all.sql` in SSMS as described in Part 1.

### Step 3 — Configure and start the backend
```bash
cd backend
python -m venv venv
venv\Scripts\activate            # Windows
# or: source venv/bin/activate   # macOS/Linux

pip install -r requirements.txt
copy .env.example .env           # Windows: copy | macOS/Linux: cp
```
Open `.env` in a text editor and set:
- `DATABASE_URL` — match how you connect in SSMS. Two common examples are already written as comments inside
  `.env.example`; uncomment/adjust the one that matches your setup (Windows auth vs. SQL login).
- `SECRET_KEY` — any long random string.

Then fix the demo passwords and start the server:
```bash
python -m app.utils.generate_demo_hashes
```
This prints two `UPDATE` statements — copy them, paste them into a **new query window in SSMS**, and run
them (F5). This is the one place after Part 1 where you go back to SSMS.

```bash
uvicorn app.main:app --reload --port 8000
```
Leave this terminal window running. Confirm it worked by opening **http://localhost:8000/docs** in a browser
— you should see the Swagger UI listing all endpoints.

### Step 4 — Start the frontend
Open a **second, separate terminal** (leave the backend one running):
```bash
cd frontend
npm install
copy .env.example .env           # Windows
npm run dev
```
Open **http://localhost:5173** in a browser. You should see the site with real data pulled from your
database (e.g. the Companies page listing manufacturers you just seeded).

### Step 5 — (Optional) Start n8n
Open a **third terminal**:
```bash
npx n8n
```
Open **http://localhost:5678**, import the 4 workflows from `n8n/workflows/`, and follow `n8n/README.md` to
wire the webhook URLs back into `backend/.env`.

### Summary of what should be running simultaneously
| Terminal / Window | What's running | Port |
|---|---|---|
| SQL Server (Windows service) | Database engine | 1433 (default) |
| Terminal 1 | `uvicorn` (backend) | 8000 |
| Terminal 2 | `npm run dev` (frontend) | 5173 |
| Terminal 3 (optional) | `npx n8n` | 5678 |
| SSMS | Only needed occasionally, not a running "service" you keep open | — |

If the frontend loads but shows no data / network errors in the browser console, check, in this order:
1. Is the backend terminal still running without errors?
2. Does http://localhost:8000/docs load?
3. Does `backend/.env`'s `FRONTEND_URL` exactly match `http://localhost:5173` (CORS)?
4. Does `frontend/.env`'s `VITE_API_BASE_URL` exactly match `http://localhost:8000`?
