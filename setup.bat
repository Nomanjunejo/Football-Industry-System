@echo off
REM Run this ONCE, from the project root: setup.bat
REM It creates the backend virtualenv + installs both backend and
REM frontend dependencies. It does NOT create the database or start
REM any servers -- see database\00_run_all.sql and start.bat for that.

echo === Setting up backend (Python venv) ===
cd backend
python -m venv venv
call venv\Scripts\activate.bat
pip install --upgrade pip
pip install -r requirements.txt
call venv\Scripts\deactivate.bat
cd ..

if not exist backend\.env (
    copy backend\.env.example backend\.env
    echo Created backend\.env from template -- EDIT IT before starting (DATABASE_URL, SECRET_KEY).
)

echo.
echo === Setting up frontend (npm) ===
cd frontend
call npm install
cd ..

if not exist frontend\.env (
    copy frontend\.env.example frontend\.env
    echo Created frontend\.env from template.
)

echo.
echo ==========================================================
echo Setup complete. Next steps:
echo 1. Run database\00_run_all.sql in SSMS first.
echo 2. Edit backend\.env with your real DATABASE_URL and SECRET_KEY.
echo 3. Run: cd backend ^&^& venv\Scripts\activate ^&^& python -m app.utils.generate_demo_hashes
echo    then paste the printed UPDATE statements into SSMS.
echo 4. Run start.bat to launch backend + frontend + n8n together.
echo ==========================================================
pause
