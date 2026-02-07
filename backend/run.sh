#!/bin/bash
# Amazon Automation Tool - run script for Linux/VPS
set -e
cd "$(dirname "$0")"

echo "============================================================"
echo "     AMAZON AUTOMATION TOOL - STARTING (VPS/Linux)"
echo "============================================================"
echo ""

# Activate venv if present
if [ -f "venv/bin/activate" ]; then
    echo "[INFO] Activating virtual environment (venv)..."
    source venv/bin/activate
    echo "[SUCCESS] Virtual environment activated"
    echo ""
elif [ -f ".venv/bin/activate" ]; then
    echo "[INFO] Activating virtual environment (.venv)..."
    source .venv/bin/activate
    echo "[SUCCESS] Virtual environment activated"
    echo ""
else
    echo "[INFO] No virtual environment found, using system Python"
    echo ""
fi

# Check Python
if ! command -v python3 &> /dev/null; then
    echo "[ERROR] python3 not found. Please install Python 3.8+"
    exit 1
fi
echo "[INFO] Python version: $(python3 --version)"
echo ""

# Install deps if needed
if ! python3 -c "import playwright" 2>/dev/null; then
    echo "[WARNING] Dependencies not installed. Installing..."
    python3 -m pip install -r requirements.txt
    python3 -m playwright install chromium
    echo ""
fi

# Check .env
if [ ! -f ".env" ]; then
    echo "[WARNING] .env not found"
    echo "[INFO] Create .env with AMAZON_EMAIL and AMAZON_PASSWORD"
    exit 1
fi

echo "============================================================"
echo "     RUNNING AMAZON AUTOMATION"
echo "============================================================"
echo ""

python3 amazon_auto.py
exitcode=$?

if [ $exitcode -ne 0 ]; then
    echo ""
    echo "[ERROR] Automation failed (exit code $exitcode)"
    exit $exitcode
fi
echo ""
echo "[SUCCESS] Automation completed"
