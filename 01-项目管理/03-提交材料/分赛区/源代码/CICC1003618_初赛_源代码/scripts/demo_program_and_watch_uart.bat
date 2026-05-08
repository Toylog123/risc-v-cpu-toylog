@echo off
setlocal
cd /d "%~dp0.."

call "%~dp0program_pynq_z2_bitstream.bat"
if errorlevel 1 exit /b %ERRORLEVEL%

echo.
echo Starting UART live monitor on COM7...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0watch_uart_live.ps1" -Port COM7
