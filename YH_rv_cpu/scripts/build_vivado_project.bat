@echo off
setlocal

set MODE=%~1
if "%MODE%"=="" set MODE=synth

set VIVADO_CMD=
set SCRIPT_DIR=%~dp0
set PROJECT_DIR=%SCRIPT_DIR%..\..\project
set USERDATA_ROOT=%PROJECT_DIR%\.vivado_user
set USERPROFILE=%USERDATA_ROOT%\profile
set HOME=%USERPROFILE%
set APPDATA=%USERDATA_ROOT%\AppData\Roaming
set LOCALAPPDATA=%USERDATA_ROOT%\AppData\Local
set TEMP=%USERDATA_ROOT%\Temp
set TMP=%USERDATA_ROOT%\Temp

if not exist "%PROJECT_DIR%" mkdir "%PROJECT_DIR%"
if not exist "%USERPROFILE%" mkdir "%USERPROFILE%"
if not exist "%APPDATA%" mkdir "%APPDATA%"
if not exist "%LOCALAPPDATA%" mkdir "%LOCALAPPDATA%"
if not exist "%TEMP%" mkdir "%TEMP%"

where vivado >nul 2>nul
if not errorlevel 1 (
    for /f "delims=" %%I in ('where vivado') do (
        set VIVADO_CMD=%%I
        goto :vivado_found
    )
)

for /d %%D in (D:\Vivado\20* C:\Xilinx\Vivado\20* D:\Xilinx\Vivado\20*) do (
    if exist "%%~fD\Vivado\bin\vivado.bat" (
        set VIVADO_CMD=%%~fD\Vivado\bin\vivado.bat
        goto :vivado_found
    )
    if exist "%%~fD\bin\vivado.bat" (
        set VIVADO_CMD=%%~fD\bin\vivado.bat
        goto :vivado_found
    )
)

:vivado_found
if not defined VIVADO_CMD (
    echo Missing vivado. Please install Vivado and ensure it is in PATH.
    exit /b 1
)

set TCL_PATH=%SCRIPT_DIR%..\fpga\vivado\scripts\build_nexys_a7_100_project.tcl

if not exist "%TCL_PATH%" (
    echo Missing TCL script: %TCL_PATH%
    exit /b 1
)

pushd "%PROJECT_DIR%"
call "%VIVADO_CMD%" -mode batch -notrace -source "%TCL_PATH%" -tclargs %MODE%
set EC=%ERRORLEVEL%
popd
exit /b %EC%
