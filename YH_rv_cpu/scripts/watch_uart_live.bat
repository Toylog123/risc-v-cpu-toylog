@echo off
setlocal

set "PORT=%~1"
if "%PORT%"=="" set "PORT=COM7"

set "LOG=%~2"
if "%LOG%"=="" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0watch_uart_live.ps1" -Port "%PORT%"
) else (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0watch_uart_live.ps1" -Port "%PORT%" -LogPath "%LOG%"
)

exit /b %ERRORLEVEL%
