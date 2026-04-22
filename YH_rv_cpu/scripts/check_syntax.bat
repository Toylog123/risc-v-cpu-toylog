@echo off
setlocal

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0check_syntax.ps1"
rem Propagate the PowerShell exit code to callers unchanged.
exit /b %ERRORLEVEL%
