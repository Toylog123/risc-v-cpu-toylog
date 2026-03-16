@echo off
setlocal

set PROJECT_DIR=%~dp0..\..\project

if not exist "%PROJECT_DIR%" (
    echo Missing local Vivado project directory: %PROJECT_DIR%
    exit /b 0
)

for %%D in (".Xil" "2025.2" "tclapp" "reportstrategies" "strategies") do (
    if exist "%PROJECT_DIR%\%%~D" (
        rmdir /s /q "%PROJECT_DIR%\%%~D"
    )
)

del /q "%PROJECT_DIR%\dfx_runtime.txt" >nul 2>nul
del /q "%PROJECT_DIR%\vivado_*.backup.jou" >nul 2>nul
del /q "%PROJECT_DIR%\vivado_*.backup.log" >nul 2>nul
del /q "%PROJECT_DIR%\vivado_synth_latest.log" >nul 2>nul

if exist "%PROJECT_DIR%\.vivado_user\Temp" (
    rmdir /s /q "%PROJECT_DIR%\.vivado_user\Temp"
)

echo Cleaned local Vivado temporary files under %PROJECT_DIR%
echo Kept reports, checkpoints, vivado.log and vivado.jou for review.
exit /b 0
