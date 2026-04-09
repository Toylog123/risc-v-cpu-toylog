@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0stage_default_sync.ps1" %*
exit /b %ERRORLEVEL%
