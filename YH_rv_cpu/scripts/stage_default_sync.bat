@echo off
setlocal
rem Preserve argv and hand off to the PowerShell staging helper unchanged.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0stage_default_sync.ps1" %*
exit /b %ERRORLEVEL%
