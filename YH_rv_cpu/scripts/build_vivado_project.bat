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

if /I "%MODE%"=="impl50" (
    set MODE=impl
    if not defined CLOCK_PERIOD_NS_OVERRIDE set CLOCK_PERIOD_NS_OVERRIDE=20.000
)

if /I "%MODE%"=="impl100" (
    set MODE=impl
    if not defined CLOCK_PERIOD_NS_OVERRIDE set CLOCK_PERIOD_NS_OVERRIDE=10.000
)

set VIVADO_CMD=
set PHYSICAL_SCRIPT_DIR=%~dp0
set SCRIPT_DIR=%PHYSICAL_SCRIPT_DIR%
for %%I in ("%PHYSICAL_SCRIPT_DIR%..\..") do set REPO_ROOT=%%~fI
set MAP_DRIVE=
set MAPPED_ROOT=
set CREATED_MAP=
set MAP_DRIVES=V: W: X: Y: Z:

for %%D in (%MAP_DRIVES%) do (
    subst %%D "%REPO_ROOT%" >nul 2>nul
    if not errorlevel 1 (
        set CREATED_MAP=1
        set MAP_DRIVE=%%D
        set MAPPED_ROOT=%%D\
        goto :map_ready
    )
)

:map_ready
if not defined MAPPED_ROOT (
    echo Failed to map an ASCII drive for Vivado. Please free one of V:/W:/X:/Y:/Z: and retry.
    exit /b 1
)

set SCRIPT_DIR=%MAPPED_ROOT%YH_rv_cpu\scripts\
set PROJECT_DIR=%MAPPED_ROOT%project
set TMP_ROOT=%MAPPED_ROOT%_tmp
set USERDATA_ROOT=%TMP_ROOT%\vivado_user
set VIVADO_LOG_ROOT=%TMP_ROOT%\tool_logs\vivado
set VIVADO_LOG_FILE=%VIVADO_LOG_ROOT%\vivado_%MODE%.log
set VIVADO_JOU_FILE=%VIVADO_LOG_ROOT%\vivado_%MODE%.jou
set USERPROFILE=%USERDATA_ROOT%\profile
set HOME=%USERPROFILE%
set APPDATA=%USERDATA_ROOT%\AppData\Roaming
set LOCALAPPDATA=%USERDATA_ROOT%\AppData\Local
set TEMP=%USERDATA_ROOT%\Temp
set TMP=%USERDATA_ROOT%\Temp

if not exist "%PROJECT_DIR%" mkdir "%PROJECT_DIR%"
if not exist "%TMP_ROOT%" mkdir "%TMP_ROOT%"
if not exist "%VIVADO_LOG_ROOT%" mkdir "%VIVADO_LOG_ROOT%"
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
set ROM_INIT_MEM32_HEX_OVERRIDE=
set ROM_BYTES_OVERRIDE=
set RAM_BYTES_OVERRIDE=
if exist "%SCRIPT_DIR%..\build\tests\riscv-tests\current.hex" (
    set ROM_INIT_HEX_OVERRIDE=%SCRIPT_DIR%..\build\tests\riscv-tests\current.hex
    set ROM_BYTES_OVERRIDE=8192
    set RAM_BYTES_OVERRIDE=8192
)
if not defined ROM_INIT_HEX_OVERRIDE if exist "%SCRIPT_DIR%..\build\tests\riscv-tests\rv32\simple.hex" (
    set ROM_INIT_HEX_OVERRIDE=%SCRIPT_DIR%..\build\tests\riscv-tests\rv32\simple.hex
    set ROM_BYTES_OVERRIDE=8192
    set RAM_BYTES_OVERRIDE=8192
)
if exist "%SCRIPT_DIR%..\build\tests\riscv-tests\current.mem32.hex" (
    set ROM_INIT_MEM32_HEX_OVERRIDE=%SCRIPT_DIR%..\build\tests\riscv-tests\current.mem32.hex
)
if not defined ROM_INIT_MEM32_HEX_OVERRIDE if exist "%SCRIPT_DIR%..\build\tests\riscv-tests\rv32\simple.mem32.hex" (
    set ROM_INIT_MEM32_HEX_OVERRIDE=%SCRIPT_DIR%..\build\tests\riscv-tests\rv32\simple.mem32.hex
)

echo Using mapped repo root: %MAPPED_ROOT%
if defined ROM_INIT_HEX_OVERRIDE echo Using ROM_INIT_HEX_OVERRIDE=%ROM_INIT_HEX_OVERRIDE%
if defined ROM_INIT_MEM32_HEX_OVERRIDE echo Using ROM_INIT_MEM32_HEX_OVERRIDE=%ROM_INIT_MEM32_HEX_OVERRIDE%

if exist "%SCRIPT_DIR%organize_tool_logs.bat" call "%SCRIPT_DIR%organize_tool_logs.bat"

pushd "%PROJECT_DIR%"
call "%VIVADO_CMD%" -mode batch -notrace -log "%VIVADO_LOG_FILE%" -journal "%VIVADO_JOU_FILE%" -source "%TCL_PATH%" -tclargs %MODE%
set EC=%ERRORLEVEL%
popd
if defined CREATED_MAP subst %MAP_DRIVE% /d >nul 2>nul
exit /b %EC%
