@echo off
setlocal

set MODE=%~1
if "%MODE%"=="" set MODE=impl

set PYNQ_CPU_CLK_FREQ_HZ_OVERRIDE=30000000
set PYNQ_USE_CLK_MMCM_25M_OVERRIDE=0
set PYNQ_USE_CLK_MMCM_30M_OVERRIDE=1
set PYNQ_USE_CLK_MMCM_33M_OVERRIDE=0
set PYNQ_USE_CLK_MMCM_62M5_OVERRIDE=0
set PYNQ_USE_CLK_MMCM_50M_OVERRIDE=0

echo === PYNQ-Z2 CPU30 RC128 BFNext no-ZBKB timing-driven CoreMark %MODE% ===
call "%~dp0build_pynq_z2_cpu25_rc128_bfnext_nozbkb_timingdriven_coremark.bat" %MODE%
exit /b %ERRORLEVEL%
