@echo off
chcp 65001 >nul
title Amazon Automation API
cd /d "%~dp0"

if exist "venv\Scripts\activate.bat" (call venv\Scripts\activate.bat) else if exist ".venv\Scripts\activate.bat" (call .venv\Scripts\activate.bat)

echo Starting API on http://0.0.0.0:8000
python -m uvicorn api:app --host 0.0.0.0 --port 8000
pause
