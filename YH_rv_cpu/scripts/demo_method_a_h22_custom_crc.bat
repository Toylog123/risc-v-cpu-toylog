@echo off
setlocal

set "PORT=%~1"
if "%PORT%"=="" set "PORT=COM7"

for %%I in ("%~dp0..") do set "PROJECT_DIR=%%~fI"
for %%I in ("%PROJECT_DIR%\..") do set "REPO_ROOT=%%~fI"

set "LOG_DIR=%REPO_ROOT%\artifacts\coremark_method_a_h22_custom_crc_20260514\board_logs"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

for /f %%I in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set "STAMP=%%I"
set "UART_LOG=%LOG_DIR%\method_a_h22_uart_%PORT%_%STAMP%.txt"

echo METHOD_A_H22_DEMO_PORT=%PORT%
echo METHOD_A_H22_UART_LOG=%UART_LOG%
echo.
echo The UART capture opens first. Programming starts in 2 seconds.
echo If capture fails because the port is busy, close other serial tools and rerun.
echo.

start "YH_rv_cpu Method A H22 UART" powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0capture_uart.ps1" -Port "%PORT%" -Seconds 45 -LogPath "%UART_LOG%"
timeout /t 2 /nobreak >nul

call "%~dp0program_pynq_z2_method_a_h22_custom_crc.bat"
set "RC=%ERRORLEVEL%"

if not "%RC%"=="0" (
    echo Method A H22 programming failed.
    exit /b %RC%
)

echo Method A H22 programming completed. UART capture window will stop automatically.
echo UART log path: %UART_LOG%
exit /b 0
