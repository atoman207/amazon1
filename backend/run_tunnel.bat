@echo off
chcp 65001 >nul
title Cloudflare Tunnel - Backend API
cd /d "%~dp0"

REM Use URL with no trailing backslash (invalid on Windows otherwise)
set "TUNNEL_ORIGIN=http://localhost:8000"

echo Starting Cloudflare Tunnel for %TUNNEL_ORIGIN%
echo Copy the HTTPS URL from the output and use it as VITE_API_BASE (add /api at the end).
echo.

cloudflared tunnel --url %TUNNEL_ORIGIN%
pause
