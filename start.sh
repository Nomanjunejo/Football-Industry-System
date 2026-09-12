#!/usr/bin/env bash
# Run this every time you want to work on the project: ./start.sh
# Starts the backend (port 8000), frontend (port 5173), and n8n
# (port 5678) together, and stops all three cleanly on Ctrl+C.
#
# Prerequisites (one-time): ./setup.sh has been run, the database
# has been created (database/00_run_all.sql), and backend/.env /
# frontend/.env have real values.

set -e
cd "$(dirname "$0")"

pids=()
cleanup() {
  echo ""
  echo "Stopping all services..."
  for pid in "${pids[@]}"; do
    kill "$pid" 2>/dev/null || true
  done
  exit 0
}
trap cleanup INT TERM

echo "Starting backend on http://localhost:8000 ..."
(cd backend && source venv/bin/activate && uvicorn app.main:app --reload --port 8000) &
pids+=($!)

sleep 2

echo "Starting frontend on http://localhost:5173 ..."
(cd frontend && npm run dev) &
pids+=($!)

if command -v n8n >/dev/null 2>&1 || [ -d "$HOME/.npm" ]; then
  echo "Starting n8n on http://localhost:5678 ..."
  (npx n8n) &
  pids+=($!)
else
  echo "Skipping n8n (optional) -- run 'npx n8n' separately if you want automation workflows active."
fi

echo ""
echo "=========================================================="
echo " Backend:  http://localhost:8000/docs"
echo " Frontend: http://localhost:5173"
echo " n8n:      http://localhost:5678"
echo " Press Ctrl+C to stop everything."
echo "=========================================================="

wait
