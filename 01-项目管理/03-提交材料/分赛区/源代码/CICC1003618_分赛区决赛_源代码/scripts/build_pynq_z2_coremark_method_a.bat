@echo off
setlocal EnableDelayedExpansion

for %%I in ("%~dp0..") do set PROJECT_DIR=%%~fI
for %%I in ("%PROJECT_DIR%\..") do set REPO_ROOT=%%~fI

for /f %%I in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set STAMP=%%I

set COREMARK_TARGET=%~1
if "%COREMARK_TARGET%"=="" set COREMARK_TARGET=rv32i_zmmul_zba_zbb_zbs_xthead_memidx_noautoinc_o2sched_nocaller_noifconv

set COREMARK_ITERATIONS=%~2
if "%COREMARK_ITERATIONS%"=="" set COREMARK_ITERATIONS=10

set COREMARK_DATA_SIZE=%~3
if "%COREMARK_DATA_SIZE%"=="" set COREMARK_DATA_SIZE=2000

set COREMARK_TIMER_HZ=%~4
if "%COREMARK_TIMER_HZ%"=="" set COREMARK_TIMER_HZ=100000000UL

set OUTPUT_NAME=method_a_coremark_%COREMARK_TARGET%_%STAMP%
set ARTIFACT_DIR=%REPO_ROOT%\artifacts\coremark_method_a_%STAMP%

echo METHOD_A_STEP=build_coremark
echo COREMARK_TARGET=%COREMARK_TARGET%
echo COREMARK_ITERATIONS=%COREMARK_ITERATIONS%
echo COREMARK_DATA_SIZE=%COREMARK_DATA_SIZE%
echo COREMARK_TIMER_HZ=%COREMARK_TIMER_HZ%

call "%~dp0build_coremark.bat" %COREMARK_TARGET% %COREMARK_ITERATIONS% %COREMARK_DATA_SIZE% %COREMARK_TIMER_HZ% 0 %OUTPUT_NAME%
if errorlevel 1 exit /b 1

set ROM_INIT_HEX_OVERRIDE=%PROJECT_DIR%\build\sw\%OUTPUT_NAME%.hex
set ROM_INIT_MEM32_HEX_OVERRIDE=%PROJECT_DIR%\build\sw\%OUTPUT_NAME%.mem32.hex
set RAM_BASE_OVERRIDE=65536
set ROM_BYTES_OVERRIDE=65536
set RAM_BYTES_OVERRIDE=65536

if not defined PYNQ_ENABLE_ZMMUL_EXTENSION_OVERRIDE set PYNQ_ENABLE_ZMMUL_EXTENSION_OVERRIDE=1
if not defined PYNQ_ENABLE_BITMANIP_EXTENSION_OVERRIDE set PYNQ_ENABLE_BITMANIP_EXTENSION_OVERRIDE=1
if not defined PYNQ_ENABLE_ZBC_EXTENSION_OVERRIDE set PYNQ_ENABLE_ZBC_EXTENSION_OVERRIDE=0
if not defined PYNQ_ENABLE_ZICOND_EXTENSION_OVERRIDE set PYNQ_ENABLE_ZICOND_EXTENSION_OVERRIDE=0
if not defined PYNQ_ENABLE_ZBKB_EXTENSION_OVERRIDE set PYNQ_ENABLE_ZBKB_EXTENSION_OVERRIDE=0
if not defined PYNQ_ENABLE_XTHEAD_EXTENSION_OVERRIDE set PYNQ_ENABLE_XTHEAD_EXTENSION_OVERRIDE=1
if not defined PYNQ_ENABLE_XTHEAD_COND_MOVE_OVERRIDE set PYNQ_ENABLE_XTHEAD_COND_MOVE_OVERRIDE=1
if not defined PYNQ_ENABLE_ID_BRANCH_EX_FORWARD_OVERRIDE set PYNQ_ENABLE_ID_BRANCH_EX_FORWARD_OVERRIDE=1
if not defined PYNQ_USE_CLK_MMCM_62M5_OVERRIDE set PYNQ_USE_CLK_MMCM_62M5_OVERRIDE=0
if not defined PYNQ_USE_CLK_MMCM_50M_OVERRIDE set PYNQ_USE_CLK_MMCM_50M_OVERRIDE=1
if not defined PYNQ_CPU_CLK_FREQ_HZ_OVERRIDE set PYNQ_CPU_CLK_FREQ_HZ_OVERRIDE=50000000

echo %COREMARK_TARGET% | findstr /I "zbc" >nul
if not errorlevel 1 set PYNQ_ENABLE_ZBC_EXTENSION_OVERRIDE=1
echo %COREMARK_TARGET% | findstr /I "zicond" >nul
if not errorlevel 1 set PYNQ_ENABLE_ZICOND_EXTENSION_OVERRIDE=1
echo %COREMARK_TARGET% | findstr /I "zbkb" >nul
if not errorlevel 1 set PYNQ_ENABLE_ZBKB_EXTENSION_OVERRIDE=1

echo METHOD_A_STEP=build_pynq_z2_bitstream
echo ROM_INIT_HEX_OVERRIDE=%ROM_INIT_HEX_OVERRIDE%
echo ROM_INIT_MEM32_HEX_OVERRIDE=%ROM_INIT_MEM32_HEX_OVERRIDE%
echo RAM_BASE_OVERRIDE=%RAM_BASE_OVERRIDE%
echo ROM_BYTES_OVERRIDE=%ROM_BYTES_OVERRIDE%
echo RAM_BYTES_OVERRIDE=%RAM_BYTES_OVERRIDE%
echo PYNQ_ENABLE_ZBC_EXTENSION_OVERRIDE=%PYNQ_ENABLE_ZBC_EXTENSION_OVERRIDE%
echo PYNQ_ENABLE_ZICOND_EXTENSION_OVERRIDE=%PYNQ_ENABLE_ZICOND_EXTENSION_OVERRIDE%
echo PYNQ_ENABLE_ZBKB_EXTENSION_OVERRIDE=%PYNQ_ENABLE_ZBKB_EXTENSION_OVERRIDE%

call "%~dp0build_pynq_z2_project.bat" impl
if errorlevel 1 exit /b 1

if not exist "%ARTIFACT_DIR%" mkdir "%ARTIFACT_DIR%"
if not exist "%ARTIFACT_DIR%\reports" mkdir "%ARTIFACT_DIR%\reports"
if not exist "%ARTIFACT_DIR%\firmware" mkdir "%ARTIFACT_DIR%\firmware"

copy /y "%REPO_ROOT%\project\YH_rv_cpu_pynq_z2_sysclk_8p000ns_cpu50.bit" "%ARTIFACT_DIR%\YH_rv_cpu_pynq_z2_method_a_coremark_%STAMP%.bit" >nul
copy /y "%ROM_INIT_HEX_OVERRIDE%" "%ARTIFACT_DIR%\firmware\%OUTPUT_NAME%.hex" >nul
copy /y "%ROM_INIT_MEM32_HEX_OVERRIDE%" "%ARTIFACT_DIR%\firmware\%OUTPUT_NAME%.mem32.hex" >nul
copy /y "%PROJECT_DIR%\build\sw\%OUTPUT_NAME%.elf" "%ARTIFACT_DIR%\firmware\%OUTPUT_NAME%.elf" >nul
copy /y "%PROJECT_DIR%\build\sw\%OUTPUT_NAME%.map" "%ARTIFACT_DIR%\firmware\%OUTPUT_NAME%.map" >nul
xcopy /y /i "%REPO_ROOT%\project\reports\pynq_z2_sysclk_8p000ns_cpu50\*.rpt" "%ARTIFACT_DIR%\reports\" >nul

(
    echo # PYNQ-Z2 CoreMark Method A Artifact
    echo.
    echo Build timestamp: %STAMP%
    echo.
    echo This artifact follows Method A: the CoreMark program image is compiled first, then embedded into the FPGA bitstream through ROM_INIT_HEX/ROM_INIT_MEM32_HEX generics.
    echo.
    echo ## Firmware
    echo.
    echo - Target: `%COREMARK_TARGET%`
    echo - Iterations: `%COREMARK_ITERATIONS%`
    echo - Data size: `%COREMARK_DATA_SIZE%`
    echo - Timer Hz macro: `%COREMARK_TIMER_HZ%`
    echo - RAM base generic: `%RAM_BASE_OVERRIDE%` decimal, matching linker RAM origin `0x00010000`
    echo - ROM/RAM bytes: `%ROM_BYTES_OVERRIDE%` / `%RAM_BYTES_OVERRIDE%`
    echo.
    echo ## FPGA
    echo.
    echo - Board: `Xilinx PYNQ-Z2`
    echo - Part: `xc7z020clg400-1`
    echo - CPU clock: `50 MHz`
    echo - UART: Pmod B PL UART, `115200 8N1`
    echo.
    echo ## Reproduce
    echo.
    echo Run:
    echo.
    echo ```bat
    echo YH_rv_cpu\scripts\build_pynq_z2_coremark_method_a.bat
    echo ```
) > "%ARTIFACT_DIR%\README.md"

echo METHOD_A_ARTIFACT_DIR=%ARTIFACT_DIR%
echo METHOD_A_BIT=%ARTIFACT_DIR%\YH_rv_cpu_pynq_z2_method_a_coremark_%STAMP%.bit
echo PASS: method A CoreMark bitstream artifact generated.
exit /b 0
