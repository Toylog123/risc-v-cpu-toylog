@echo off
setlocal

for %%I in ("%~dp0..") do set "PROJECT_DIR=%%~fI"
for %%I in ("%PROJECT_DIR%\..") do set "REPO_ROOT=%%~fI"

set "FW_DIR=%REPO_ROOT%\artifacts\coremark8_hw_20260512\logs\h22_custom_crc_only_no_skip_20260514_firmware"
set "ARTIFACT_DIR=%REPO_ROOT%\artifacts\coremark_method_a_h22_custom_crc_20260514"

set "ROM_INIT_HEX_OVERRIDE=%FW_DIR%\h22_custom_crc_only_no_skip_20260514.hex"
set "ROM_INIT_MEM32_HEX_OVERRIDE=%FW_DIR%\h22_custom_crc_only_no_skip_20260514.mem32.hex"

if not exist "%ROM_INIT_HEX_OVERRIDE%" (
    echo Missing H22 CoreMark byte hex:
    echo %ROM_INIT_HEX_OVERRIDE%
    exit /b 1
)

if not exist "%ROM_INIT_MEM32_HEX_OVERRIDE%" (
    echo Missing H22 CoreMark mem32 hex:
    echo %ROM_INIT_MEM32_HEX_OVERRIDE%
    exit /b 1
)

set RAM_BASE_OVERRIDE=65536
set ROM_BYTES_OVERRIDE=65536
set RAM_BYTES_OVERRIDE=65536

set PYNQ_ENABLE_M_EXTENSION_OVERRIDE=0
set PYNQ_ENABLE_ZMMUL_EXTENSION_OVERRIDE=1
set PYNQ_ENABLE_BITMANIP_EXTENSION_OVERRIDE=1
set PYNQ_ENABLE_ZBC_EXTENSION_OVERRIDE=0
set PYNQ_ENABLE_ZICOND_EXTENSION_OVERRIDE=1
set PYNQ_ENABLE_ZBKB_EXTENSION_OVERRIDE=0
set PYNQ_ENABLE_XTHEAD_EXTENSION_OVERRIDE=1
set PYNQ_ENABLE_XTHEAD_COND_MOVE_OVERRIDE=1
set PYNQ_ENABLE_ID_BRANCH_EX_FORWARD_OVERRIDE=1
set PYNQ_USE_CLK_MMCM_62M5_OVERRIDE=0
set PYNQ_USE_CLK_MMCM_50M_OVERRIDE=1
set PYNQ_CPU_CLK_FREQ_HZ_OVERRIDE=50000000

echo METHOD_A_H22_ROM_INIT_HEX=%ROM_INIT_HEX_OVERRIDE%
echo METHOD_A_H22_ROM_INIT_MEM32_HEX=%ROM_INIT_MEM32_HEX_OVERRIDE%
echo METHOD_A_H22_ARTIFACT_DIR=%ARTIFACT_DIR%

call "%~dp0build_pynq_z2_project.bat" impl
if errorlevel 1 exit /b 1

if not exist "%ARTIFACT_DIR%" mkdir "%ARTIFACT_DIR%"
if not exist "%ARTIFACT_DIR%\firmware" mkdir "%ARTIFACT_DIR%\firmware"
if not exist "%ARTIFACT_DIR%\reports" mkdir "%ARTIFACT_DIR%\reports"

copy /y "%REPO_ROOT%\project\YH_rv_cpu_pynq_z2_sysclk_8p000ns_cpu50.bit" "%ARTIFACT_DIR%\YH_rv_cpu_pynq_z2_method_a_h22_custom_crc_20260514.bit" >nul
copy /y "%FW_DIR%\h22_custom_crc_only_no_skip_20260514.hex" "%ARTIFACT_DIR%\firmware\" >nul
copy /y "%FW_DIR%\h22_custom_crc_only_no_skip_20260514.mem32.hex" "%ARTIFACT_DIR%\firmware\" >nul
copy /y "%FW_DIR%\h22_custom_crc_only_no_skip_20260514.elf" "%ARTIFACT_DIR%\firmware\" >nul
copy /y "%FW_DIR%\h22_custom_crc_only_no_skip_20260514.dump" "%ARTIFACT_DIR%\firmware\" >nul
xcopy /y /i "%REPO_ROOT%\project\reports\pynq_z2_sysclk_8p000ns_cpu50\*.rpt" "%ARTIFACT_DIR%\reports\" >nul

(
    echo # PYNQ-Z2 CoreMark Method A H22 Custom CRC Artifact
    echo.
    echo Date: 2026-05-14
    echo.
    echo This Method A bitstream embeds the H22 CoreMark image. H22 enables custom CRC hardware instructions but does not enable `YH_COREMARK_SKIP_ZERO_STATE_RERUN`.
    echo.
    echo ## Firmware
    echo.
    echo - Source score summary: `artifacts/coremark8_hw_20260512/logs/h22_custom_crc_only_no_skip_20260514.summary.txt`
    echo - Firmware: `firmware/h22_custom_crc_only_no_skip_20260514.mem32.hex`
    echo - RAM base: `0x00010000`
    echo - CoreMark/MHz: `6.234161`
    echo - Raw ticks: `1604065`
    echo - Completion cycles: `1638280`
    echo.
    echo ## FPGA
    echo.
    echo - Board: `Xilinx PYNQ-Z2`
    echo - Part: `xc7z020clg400-1`
    echo - CPU clock: `50 MHz`
    echo - ISA: `RV32I + Zmmul + Zba/Zbb/Zbs + Zicond + XThead custom CRC/memidx`
    echo - Resources: `5830 LUT / 2503 FF / 32 BRAM / 15 DSP`
    echo - Timing: `WNS +0.042 ns / WHS +0.040 ns`
    echo - Bitstream: `YH_rv_cpu_pynq_z2_method_a_h22_custom_crc_20260514.bit`
    echo.
    echo ## Boundary
    echo.
    echo This is an ISA/hardware co-design artifact, not a pure RTL-only benchmark. It is cleaner than the historical fixed75 image because it does not skip the zero-state rerun path.
    echo.
    echo ## Programming
    echo.
    echo Use the English-path copy when selecting the bitstream manually in Vivado:
    echo.
    echo ```text
    echo vivado_program/YH_rv_cpu_pynq_z2_method_a_h22_custom_crc_20260514.bit
    echo ```
    echo.
    echo Or run the scripted flow from the worktree root:
    echo.
    echo ```bat
    echo YH_rv_cpu\scripts\demo_method_a_h22_custom_crc.bat COM7
    echo ```
) > "%ARTIFACT_DIR%\README.md"

echo METHOD_A_H22_BIT=%ARTIFACT_DIR%\YH_rv_cpu_pynq_z2_method_a_h22_custom_crc_20260514.bit
echo PASS: H22 Method A bitstream artifact generated.
exit /b 0
