@echo off
REM Run this every time you want to work on the project: start.bat
REM Opens three separate terminal windows: backend, frontend, n8n.
REM Close each window (or Ctrl+C inside it) to stop that service.
REM
REM Prerequisites (one-time): setup.bat has been run, the database
REM has been created (database\00_run_all.sql), and backend\.env /
REM frontend\.env have real values.

cd /d "%~dp0"

echo Starting backend on http://localhost:8000 ...
start "Backend (FastAPI)" cmd /k "cd backend && venv\Scripts\activate && uvicorn app.main:app --reload --port 8000"

timeout /t 3 /nobreak >nul

echo Starting frontend on http://localhost:5173 ...
start "Frontend (React)" cmd /k "cd frontend && npm run dev"

echo Starting n8n on http://localhost:5678 ...
start "n8n" cmd /k "npx n8n"

echo.
echo ==========================================================
echo  Backend:  http://localhost:8000/docs
echo  Frontend: http://localhost:5173
echo  n8n:      http://localhost:5678
echo  Each service is running in its own window -- close a
echo  window (or Ctrl+C inside it) to stop that service.
echo ==========================================================
