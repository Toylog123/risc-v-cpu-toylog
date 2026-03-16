@echo off
setlocal

set MODE=%~1
if "%MODE%"=="" set MODE=synth
set CLOCK_PERIOD_NS_OVERRIDE=%~2

if /I "%MODE%"=="synth50" (
    set MODE=synth
    if not defined CLOCK_PERIOD_NS_OVERRIDE set CLOCK_PERIOD_NS_OVERRIDE=20.000
)

if /I "%MODE%"=="synth100" (
    set MODE=synth
    if not defined CLOCK_PERIOD_NS_OVERRIDE set CLOCK_PERIOD_NS_OVERRIDE=10.000
)

set VIVADO_CMD=
set PHYSICAL_SCRIPT_DIR=%~dp0
set SCRIPT_DIR=%PHYSICAL_SCRIPT_DIR%
for %%I in ("%PHYSICAL_SCRIPT_DIR%..\..") do set REPO_ROOT=%%~fI
set MAP_DRIVE=V:
set MAPPED_ROOT=
set CREATED_MAP=

subst %MAP_DRIVE% "%REPO_ROOT%" >nul 2>nul
if not errorlevel 1 (
    set CREATED_MAP=1
    set MAPPED_ROOT=%MAP_DRIVE%\
)

if defined MAPPED_ROOT (
    set SCRIPT_DIR=%MAPPED_ROOT%YH_rv_cpu\scripts\
)

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
    if defined CREATED_MAP subst %MAP_DRIVE% /d >nul 2>nul
    exit /b 1
)

set TCL_PATH=%SCRIPT_DIR%..\fpga\vivado\scripts\build_nexys_a7_100_project.tcl

if not exist "%TCL_PATH%" (
    echo Missing TCL script: %TCL_PATH%
    if defined CREATED_MAP subst %MAP_DRIVE% /d >nul 2>nul
    exit /b 1
)

set ROM_INIT_HEX_OVERRIDE=
set ROM_BYTES_OVERRIDE=
set RAM_BYTES_OVERRIDE=
if exist "%SCRIPT_DIR%..\build\tests\riscv-tests\rv32\simple.hex" (
    set ROM_INIT_HEX_OVERRIDE=%SCRIPT_DIR%..\build\tests\riscv-tests\rv32\simple.hex
    set ROM_BYTES_OVERRIDE=8192
    set RAM_BYTES_OVERRIDE=8192
)

pushd "%PROJECT_DIR%"
call "%VIVADO_CMD%" -mode batch -notrace -source "%TCL_PATH%" -tclargs %MODE%
set EC=%ERRORLEVEL%
popd
if defined CREATED_MAP subst %MAP_DRIVE% /d >nul 2>nul
exit /b %EC%
