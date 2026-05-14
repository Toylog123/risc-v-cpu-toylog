@echo off
setlocal

for %%I in ("%~dp0..") do set "PROJECT_DIR=%%~fI"
for %%I in ("%PROJECT_DIR%\..") do set "REPO_ROOT=%%~fI"

set "DEFAULT_BIT=%REPO_ROOT%\artifacts\coremark_method_a_h22_custom_crc_20260514\YH_rv_cpu_pynq_z2_method_a_h22_custom_crc_20260514.bit"
set "BIT=%~1"
set "TCLARG_BIT=%BIT%"
if "%BIT%"=="" (
    set "BIT=%DEFAULT_BIT%"
    set "TCLARG_BIT=V:\artifacts\coremark_method_a_h22_custom_crc_20260514\YH_rv_cpu_pynq_z2_method_a_h22_custom_crc_20260514.bit"
)

set "TCL=%PROJECT_DIR%\fpga\vivado\scripts\program_hw_bitstream.tcl"
set "VIVADO_BAT=D:\Vivado\2025.2\Vivado\bin\vivado.bat"
set "LOG_DIR=%REPO_ROOT%\artifacts\coremark_method_a_h22_custom_crc_20260514\board_logs"

if not exist "%BIT%" (
    echo Bitstream not found:
    echo %BIT%
    exit /b 1
)

if not exist "%TCL%" (
    echo Vivado programming TCL script not found:
    echo %TCL%
    exit /b 1
)

if not exist "%VIVADO_BAT%" (
    echo Vivado not found:
    echo %VIVADO_BAT%
    exit /b 1
)

if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

subst V: /d >nul 2>nul
subst V: "%REPO_ROOT%"
if errorlevel 1 (
    echo Failed to create V: path mapping.
    exit /b 1
)

echo METHOD_A_H22_PROGRAM_BIT=%BIT%
echo METHOD_A_H22_LOG_DIR=%LOG_DIR%

"%VIVADO_BAT%" -mode batch -notrace ^
    -log "V:\artifacts\coremark_method_a_h22_custom_crc_20260514\board_logs\program_method_a_h22_custom_crc.log" ^
    -journal "V:\artifacts\coremark_method_a_h22_custom_crc_20260514\board_logs\program_method_a_h22_custom_crc.jou" ^
    -source "V:\YH_rv_cpu\fpga\vivado\scripts\program_hw_bitstream.tcl" ^
    -tclargs "%TCLARG_BIT%"

set "RC=%ERRORLEVEL%"
subst V: /d >nul 2>nul

if not "%RC%"=="0" (
    echo PROGRAM_FAILED: exit code %RC%.
    exit /b %RC%
)

echo PROGRAM_OK
exit /b 0
