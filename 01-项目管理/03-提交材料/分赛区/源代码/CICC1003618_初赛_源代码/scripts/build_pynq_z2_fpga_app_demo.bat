@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
set "REPO_ROOT=%SCRIPT_DIR%.."
for %%I in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fI"

echo Building YH_rv_cpu FPGA application demo firmware...
call "%SCRIPT_DIR%build_firmware.bat" fpga_app_demo
if errorlevel 1 (
    echo Failed to build fpga_app_demo firmware.
    exit /b 1
)

set "ROM_INIT_HEX_OVERRIDE=%REPO_ROOT%\build\sw\YH_rv_cpu_fpga_app_demo.hex"
set "ROM_INIT_MEM32_HEX_OVERRIDE=%REPO_ROOT%\build\sw\YH_rv_cpu_fpga_app_demo.mem32.hex"
set "ROM_BYTES_OVERRIDE=16384"
set "RAM_BYTES_OVERRIDE=16384"

set "PYNQ_INPUT_CLOCK_PERIOD_NS_OVERRIDE=8.000"
set "PYNQ_CPU_CLK_FREQ_HZ_OVERRIDE=50000000"
set "PYNQ_USE_CLK_MMCM_62M5_OVERRIDE=0"
set "PYNQ_USE_CLK_MMCM_50M_OVERRIDE=1"

set "PYNQ_ENABLE_M_EXTENSION_OVERRIDE=0"
set "PYNQ_ENABLE_ZMMUL_EXTENSION_OVERRIDE=1"
set "PYNQ_ENABLE_BITMANIP_EXTENSION_OVERRIDE=1"
set "PYNQ_ENABLE_ZBC_EXTENSION_OVERRIDE=0"
set "PYNQ_ENABLE_ZICOND_EXTENSION_OVERRIDE=0"
set "PYNQ_ENABLE_ZBKB_EXTENSION_OVERRIDE=0"
set "PYNQ_ENABLE_XTHEAD_EXTENSION_OVERRIDE=0"
set "PYNQ_ENABLE_XTHEAD_COND_MOVE_OVERRIDE=0"
set "PYNQ_ENABLE_ID_BRANCH_EX_FORWARD_OVERRIDE=1"

set "PYNQ_DEBUG_LED_MODE_OVERRIDE=0"
set "PYNQ_DEBUG_UART_DIAG_MODE_OVERRIDE=0"

echo Building PYNQ-Z2 bitstream with CPU software UART application output...
call "%SCRIPT_DIR%build_pynq_z2_project.bat" impl
exit /b %ERRORLEVEL%
