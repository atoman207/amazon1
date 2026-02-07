@echo off
chcp 65001 >nul
title Amazon Automation Tool - Setup
color 0B

echo ============================================================
echo     AMAZON AUTOMATION TOOL - INITIAL SETUP
echo ============================================================
echo.

REM Change to script directory
cd /d "%~dp0"

REM ---------------------------------------------------------------------------
REM Step 1: Find Python - prefer 3.12 or 3.11 (greenlet has pre-built wheels)
REM ---------------------------------------------------------------------------
set PYCMD=
py -3.12 --version >nul 2>&1
if %errorlevel% equ 0 (
    set PYCMD=py -3.12
    echo [INFO] Using Python 3.12
    goto :have_python
)
py -3.11 --version >nul 2>&1
if %errorlevel% equ 0 (
    set PYCMD=py -3.11
    echo [INFO] Using Python 3.11
    goto :have_python
)
python --version >nul 2>&1
if %errorlevel% equ 0 (
    set PYCMD=python
    echo [INFO] Using default Python
    goto :have_python
)
echo [ERROR] Python is not installed or not in PATH.
echo.
echo Install Python 3.11 or 3.12 from: https://www.python.org/downloads/
echo Make sure to check "Add Python to PATH".
echo.
pause
exit /b 1

:have_python
echo [INFO] Python version:
%PYCMD% --version
echo.

REM ---------------------------------------------------------------------------
REM Step 2: Create or recreate virtual environment
REM ---------------------------------------------------------------------------
if not "%PYCMD%"=="python" (
    REM Using py -3.12 or py -3.11 - recreate venv with this version
    if exist "venv" (
        echo [INFO] Removing old venv to use Python 3.11/3.12...
        rmdir /s /q venv
    )
)
if not exist "venv" (
    echo [INFO] Creating virtual environment...
    %PYCMD% -m venv venv
    if errorlevel 1 (
        echo [ERROR] Failed to create virtual environment
        pause
        exit /b 1
    )
    echo [SUCCESS] Virtual environment created
) else (
    echo [INFO] Virtual environment already exists
)
echo.

REM ---------------------------------------------------------------------------
REM Step 3: Activate virtual environment
REM ---------------------------------------------------------------------------
echo [INFO] Activating virtual environment...
call venv\Scripts\activate.bat
echo.

REM ---------------------------------------------------------------------------
REM Step 4: Check for Python 3.14+ (no greenlet wheels - may fail)
REM ---------------------------------------------------------------------------
python -c "import sys; exit(0 if sys.version_info >= (3,14) else 1)" 2>nul
if %errorlevel% equ 0 (
    echo [WARNING] Python 3.14+ detected - greenlet has no pre-built wheels.
    echo [WARNING] Building from source requires Microsoft C++ Build Tools.
    echo.
    echo RECOMMENDED: Use Python 3.11 or 3.12. Run this script again after
    echo   installing from https://www.python.org/downloads/
    echo.
    choice /C YN /M "Continue anyway (install may fail)"
    if errorlevel 2 exit /b 1
    echo.
)

REM ---------------------------------------------------------------------------
REM Step 5: Upgrade pip, setuptools, wheel
REM ---------------------------------------------------------------------------
echo [INFO] Upgrading pip, setuptools, and wheel...
python -m pip install --upgrade pip setuptools wheel
echo.

REM ---------------------------------------------------------------------------
REM Step 6: Install dependencies (greenlet workaround for Python 3.14+)
REM ---------------------------------------------------------------------------
echo [INFO] Installing Python dependencies from requirements.txt...
pip install greenlet --only-binary :all: 2>nul
if errorlevel 1 (
    pip install greenlet --prefer-binary 2>nul
    if errorlevel 1 (
        echo [WARNING] greenlet wheel not available - trying full install...
        pip install greenlet 2>nul
        if errorlevel 1 (
            echo [ERROR] greenlet failed. Use Python 3.11 or 3.12, or install
            echo   Microsoft C++ Build Tools from:
            echo   https://visualstudio.microsoft.com/visual-cpp-build-tools/
            pause
            exit /b 1
        )
    )
)
pip install -r requirements.txt
if errorlevel 1 (
    echo [ERROR] Failed to install dependencies
    pause
    exit /b 1
)
echo [SUCCESS] Dependencies installed
echo.

REM ---------------------------------------------------------------------------
REM Step 7: Install Playwright browsers
REM ---------------------------------------------------------------------------
echo [INFO] Installing Playwright browsers (this may take a few minutes)...
python -m playwright install chromium
echo.

REM ---------------------------------------------------------------------------
REM Step 8: Create .env file if it doesn't exist
REM ---------------------------------------------------------------------------
if not exist ".env" (
    echo [INFO] Creating .env file...
    if exist ".env.example" (
        copy .env.example .env
        echo [SUCCESS] .env created from .env.example
    ) else (
        echo AMAZON_EMAIL= > .env
        echo AMAZON_PASSWORD= >> .env
        echo SLACK_WEBHOOK_URL= >> .env
        echo [SUCCESS] .env file created
    )
    echo [WARNING] Please edit .env and set AMAZON_EMAIL, AMAZON_PASSWORD, SLACK_WEBHOOK_URL
    echo.
) else (
    echo [INFO] .env file already exists
    echo.
)

REM ---------------------------------------------------------------------------
REM Step 9: Check Gmail credentials
REM ---------------------------------------------------------------------------
if not exist "data\client_secret_*.json" (
    echo [WARNING] Gmail API credentials not found in data\ folder
    echo [INFO] Add your client_secret JSON to data\ from:
    echo        https://console.cloud.google.com/apis/credentials
    echo.
)

echo ============================================================
echo     SETUP COMPLETED
echo ============================================================
echo.
echo Next steps:
echo   1. Edit .env and set AMAZON_EMAIL, AMAZON_PASSWORD, SLACK_WEBHOOK_URL
echo   2. Put Gmail API credentials (client_secret_*.json) in data\ folder
echo   3. Run the program: run.bat
echo.
echo ============================================================
pause
