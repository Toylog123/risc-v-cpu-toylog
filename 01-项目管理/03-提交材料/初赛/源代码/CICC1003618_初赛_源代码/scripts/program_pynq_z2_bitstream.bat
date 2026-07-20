@echo off
setlocal

set "ROOT=%~dp0.."
set "BIT=%ROOT%\project\YH_rv_cpu_pynq_z2_sysclk_8p000ns_cpu50.bit"
set "TCL=%ROOT%\fpga\vivado\scripts\program_hw_bitstream.tcl"
set "VIVADO_BAT=D:\Vivado\2025.2\Vivado\bin\vivado.bat"

if not exist "%BIT%" (
    echo Bitstream not found:
    echo %BIT%
    exit /b 1
)

if not exist "%TCL%" (
    echo Program script not found:
    echo %TCL%
    exit /b 1
)

if not exist "%VIVADO_BAT%" (
    echo Vivado not found:
    echo %VIVADO_BAT%
    exit /b 1
)

subst V: /d >nul 2>nul
subst V: "%ROOT%"
if errorlevel 1 (
    echo Failed to create V: path mapping.
    exit /b 1
)

echo Programming PYNQ-Z2 bitstream...
echo Bitstream: %BIT%

"%VIVADO_BAT%" -mode batch -notrace ^
    -log "V:\_tmp\tool_logs\vivado\program_pynq_z2_bitstream.log" ^
    -journal "V:\_tmp\tool_logs\vivado\program_pynq_z2_bitstream.jou" ^
    -source "V:\fpga\vivado\scripts\program_hw_bitstream.tcl" ^
    -tclargs "V:\project\YH_rv_cpu_pynq_z2_sysclk_8p000ns_cpu50.bit"

set "RC=%ERRORLEVEL%"
subst V: /d >nul 2>nul

if not "%RC%"=="0" (
    echo Programming failed, exit code %RC%.
    exit /b %RC%
)

echo PROGRAM_OK
exit /b 0
