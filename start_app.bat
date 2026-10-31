@echo off
setlocal
cd /d "%~dp0"
title Instagram Non-Followers & Verifier App (v9)

if not exist "%~dp0index.html" (
    echo.
    echo  [!] ERROR: index.html was not found in this folder!
    echo  Please EXTRACT all files from the .zip archive into a folder first,
    echo  then double-click start_app.bat.
    echo.
    pause
    exit /b 1
)

if not exist "%~dp0app_engine.ps1" (
    echo.
    echo  [!] ERROR: app_engine.ps1 was not found in this folder!
    echo  Please EXTRACT all files from the .zip archive into a folder first,
    echo  then double-click start_app.bat.
    echo.
    pause
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0app_engine.ps1"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo  [!] The app engine stopped unexpectedly.
    pause
)
