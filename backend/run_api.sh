#!/bin/bash
cd "$(dirname "$0")"
[ -f "venv/bin/activate" ] && source venv/bin/activate
[ -f ".venv/bin/activate" ] && source .venv/bin/activate
echo "Starting API on http://0.0.0.0:8000"
exec python3 -m uvicorn api:app --host 0.0.0.0 --port 8000
