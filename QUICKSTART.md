# Quickstart

Everything — database scripts, backend, frontend, n8n — lives in this **one folder**. Open it in VS Code with:

```bash
code .
```

That opens the folder for editing. It does **not** install dependencies or start any servers by itself —
no command can do that automatically, because SQL Server has to be created and configured first, and Node/
Python dependencies have to be downloaded once. Here's the actual minimum-friction path:

## One-time setup (do this once, ever)

1. Make sure SQL Server is installed and running.
2. Open SSMS, open `database/00_run_all.sql`, press **F5**. (Builds the entire database in one shot.)
3. In a terminal, from this folder:
   ```bash
   ./setup.sh          # macOS/Linux
   setup.bat            # Windows (double-click it, or run from a terminal)
   ```
   This creates the backend's Python virtual environment, installs all Python packages, runs `npm install`
   for the frontend, and creates `backend/.env` / `frontend/.env` from the templates.
4. Open `backend/.env` and set a real `DATABASE_URL` and `SECRET_KEY`.
5. Fix the demo login passwords (one-time):
   ```bash
   cd backend
   source venv/bin/activate      # Windows: venv\Scripts\activate
   python -m app.utils.generate_demo_hashes
   ```
   Copy the two `UPDATE` statements it prints, paste them into a new query window in SSMS, run them.

## Every time after that: one command

```bash
./start.sh           # macOS/Linux
start.bat             # Windows
```

This starts the backend, frontend, and n8n together. You'll see:
```
 Backend:  http://localhost:8000/docs
 Frontend: http://localhost:5173
 n8n:      http://localhost:5678
```

- **macOS/Linux**: all three run in one terminal window; `Ctrl+C` stops all of them together.
- **Windows**: three separate windows open, one per service; close a window (or `Ctrl+C` inside it) to stop
  just that service.

## Or, without leaving VS Code

After opening the folder with `code .`:
1. `Ctrl+Shift+P` (or `Cmd+Shift+P` on Mac) → type **"Run Task"** → Enter
2. Choose **"2. Run Everything (Backend + Frontend + n8n)"**

This uses the tasks defined in `.vscode/tasks.json` and runs each service in its own VS Code terminal panel,
so you can watch all three logs side by side inside the editor.

## Folder map

```
Football-Industry-System/
├── .vscode/tasks.json    ← VS Code "Run Task" definitions
├── setup.sh / setup.bat  ← one-time dependency install
├── start.sh / start.bat  ← every-time launcher (backend+frontend+n8n)
├── database/             ← run 00_run_all.sql in SSMS first
├── backend/               ← FastAPI (needs backend/.env configured)
├── frontend/             ← React (needs frontend/.env configured)
├── n8n/                  ← workflow JSON files to import into n8n
├── QUICKSTART.md         ← this file
├── HOW_TO_RUN.md         ← longer step-by-step explanation + architecture diagram
└── README.md             ← project overview, features, viva prep
```
