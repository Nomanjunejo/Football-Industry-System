#!/usr/bin/env bash
# Run this ONCE, from the project root: ./setup.sh
# It creates the backend virtualenv + installs both backend and
# frontend dependencies. It does NOT create the database or start
# any servers -- see database/00_run_all.sql and start.sh for that.
set -e

echo "=== Setting up backend (Python venv) ==="
cd backend
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
deactivate
cd ..

if [ ! -f backend/.env ]; then
  cp backend/.env.example backend/.env
  echo "Created backend/.env from template -- EDIT IT before starting (DATABASE_URL, SECRET_KEY)."
fi

echo ""
echo "=== Setting up frontend (npm) ==="
cd frontend
npm install
cd ..

if [ ! -f frontend/.env ]; then
  cp frontend/.env.example frontend/.env
  echo "Created frontend/.env from template."
fi

echo ""
echo "=========================================================="
echo "Setup complete. Next steps:"
echo "1. Run database/00_run_all.sql in SSMS (or sqlcmd) first."
echo "2. Edit backend/.env with your real DATABASE_URL and SECRET_KEY."
echo "3. Run: cd backend && source venv/bin/activate && python -m app.utils.generate_demo_hashes"
echo "   then paste the printed UPDATE statements into SSMS."
echo "4. Run ./start.sh to launch backend + frontend + n8n together."
echo "=========================================================="
