@echo off
setlocal EnableDelayedExpansion

for %%I in ("%~dp0..") do set PROJECT_DIR=%%~fI
set CLOCK_HZ=%~1
set MAX_CYCLES=%~2
set SUMMARY_FILE=%~3
set DHRYSTONE_RUNS=%~4
set TARGET=%~5

if "%CLOCK_HZ%"=="" set CLOCK_HZ=100000000UL
if "%MAX_CYCLES%"=="" set MAX_CYCLES=250000000
if "%SUMMARY_FILE%"=="" set SUMMARY_FILE=%PROJECT_DIR%\build\sw\YH_rv_cpu_dhrystone.summary.txt
if "%DHRYSTONE_RUNS%"=="" set DHRYSTONE_RUNS=10
if "%TARGET%"=="" set TARGET=rv32im_zicsr

for %%I in ("%SUMMARY_FILE%") do (
    set SUMMARY_FILE=%%~fI
    set OUTPUT_DIR=%%~dpI
)
set OUTPUT_NAME=YH_rv_cpu_dhrystone
set TEST_TOP=YH_rv_cpu_dhrystone_tb
if /I "%TARGET%"=="rv32i_zmmul_zba_zbb_zbs_zicsr" (
    set OUTPUT_NAME=YH_rv_cpu_dhrystone_zmmul_bitmanip_noidbr
    set TEST_TOP=YH_rv_cpu_dhrystone_rv32_zmmul_bitmanip_noidbr_tb
)
if /I "%TARGET%"=="rv32i_zmmul_zba_zbb_zbs" (
    set OUTPUT_NAME=YH_rv_cpu_dhrystone_zmmul_bitmanip_noidbr
    set TEST_TOP=YH_rv_cpu_dhrystone_rv32_zmmul_bitmanip_noidbr_tb
)
if /I "%TARGET%"=="rv32i_zmmul_zba_zbb_zbs_idbr" (
    set OUTPUT_NAME=YH_rv_cpu_dhrystone_zmmul_bitmanip_idbr
    set TEST_TOP=YH_rv_cpu_dhrystone_rv32_zmmul_bitmanip_idbr_tb
)
if /I "%TARGET%"=="rv32i_zmmul_zba_zbb_zbs_zbc_xthead" (
    set OUTPUT_NAME=YH_rv_cpu_dhrystone_zmmul_zbc_xthead_noidbr
    set TEST_TOP=YH_rv_cpu_dhrystone_rv32_zmmul_zbc_xthead_noidbr_tb
)
if /I "%TARGET%"=="rv32i_zmmul_zba_zbb_zbs_zbc_xthead_nomemidx" (
    set OUTPUT_NAME=YH_rv_cpu_dhrystone_zmmul_zbc_xthead_noidbr
    set TEST_TOP=YH_rv_cpu_dhrystone_rv32_zmmul_zbc_xthead_noidbr_tb
)
if /I "%TARGET%"=="rv32i_zmmul_zba_zbb_zbs_zbc_xtheadmemidx_zicsr" (
    set OUTPUT_NAME=YH_rv_cpu_dhrystone_zmmul_zbc_xthead_noidbr
    set TEST_TOP=YH_rv_cpu_dhrystone_rv32_zmmul_zbc_xthead_noidbr_tb
)
if /I "%TARGET%"=="rv32i_zmmul_zba_zbb_zbs_zbc_xthead_idbr" (
    set OUTPUT_NAME=YH_rv_cpu_dhrystone_zmmul_zbc_xthead_idbr
    set TEST_TOP=YH_rv_cpu_dhrystone_rv32_zmmul_zbc_xthead_idbr_tb
)
if /I "%TARGET%"=="rv32i_zmmul_zba_zbb_zbs_zbc_zicond_xthead_idbr" (
    set OUTPUT_NAME=YH_rv_cpu_dhrystone_zmmul_zbc_zicond_xthead_idbr
    set TEST_TOP=YH_rv_cpu_dhrystone_rv32_zmmul_zbc_zicond_xthead_idbr_tb
)
if /I "%TARGET%"=="rv32i_zmmul_zba_zbb_zbs_zbc_zicond_xthead_mac_idbr" (
    set OUTPUT_NAME=YH_rv_cpu_dhrystone_zmmul_zbc_zicond_xthead_mac_idbr
    set TEST_TOP=YH_rv_cpu_dhrystone_rv32_zmmul_zbc_zicond_xthead_idbr_tb
)
if /I "%TARGET%"=="rv32i_zmmul_zba_zbb_zbs_zbc_zicond_xthead_mac_idbr_fold" (
    set OUTPUT_NAME=YH_rv_cpu_dhrystone_zmmul_zbc_zicond_xthead_mac_idbr
    set TEST_TOP=YH_rv_cpu_dhrystone_rv32_zmmul_zbc_zicond_xthead_idbr_fold_tb
)
if /I "%TARGET%"=="rv32i_zmmul_zba_zbb_zbs_zicond_xthead_idbr" (
    set OUTPUT_NAME=YH_rv_cpu_dhrystone_zmmul_zicond_xthead_idbr
    set TEST_TOP=YH_rv_cpu_dhrystone_rv32_zmmul_zicond_xthead_idbr_tb
)
if /I "%TARGET%"=="rv32i_zmmul_zba_zbb_zbs_xthead_idbr" (
    set OUTPUT_NAME=YH_rv_cpu_dhrystone_zmmul_xthead_idbr
    set TEST_TOP=YH_rv_cpu_dhrystone_rv32_zmmul_xthead_idbr_tb
)
if /I "%TARGET%"=="rv32i_zmmul_zba_zbb_zbs_zbc_xthead_nomemidx_idbr" (
    set OUTPUT_NAME=YH_rv_cpu_dhrystone_zmmul_zbc_xthead_idbr
    set TEST_TOP=YH_rv_cpu_dhrystone_rv32_zmmul_zbc_xthead_idbr_tb
)
if /I "%TARGET%"=="rv32im_zba_zbb_zbs_zbc_xthead_idbr" (
    set OUTPUT_NAME=YH_rv_cpu_dhrystone_rv32im_zbc_xthead_idbr
    set TEST_TOP=YH_rv_cpu_dhrystone_rv32im_zbc_xthead_idbr_tb
)
set LOG_FILE=!OUTPUT_DIR!!OUTPUT_NAME!.log
set XSIM_EXTRA_ARGS=
if defined DHRYSTONE_XSIM_EXTRA_PLUSARGS set XSIM_EXTRA_ARGS=%DHRYSTONE_XSIM_EXTRA_PLUSARGS%

call "%~dp0build_dhrystone.bat" %OUTPUT_NAME% %DHRYSTONE_RUNS% %TARGET%
if errorlevel 1 exit /b 1

set XVLOG=
set XELAB=
set XSIM=
set PYTHON_CMD=
set XSIM_RUN_DIR=

for %%T in (xvlog.bat xvlog) do (
    where %%T >nul 2>nul
    if not errorlevel 1 (
        set XVLOG=%%T
        goto :xvlog_done
    )
)
:xvlog_done

for %%T in (xelab.bat xelab) do (
    where %%T >nul 2>nul
    if not errorlevel 1 (
        set XELAB=%%T
        goto :xelab_done
    )
)
:xelab_done

for %%T in (xsim.bat xsim) do (
    where %%T >nul 2>nul
    if not errorlevel 1 (
        set XSIM=%%T
        goto :xsim_done
    )
)
:xsim_done

if not defined XVLOG (
    echo Missing xvlog.
    exit /b 1
)

if not defined XELAB (
    echo Missing xelab.
    exit /b 1
)

if not defined XSIM (
    echo Missing xsim.
    exit /b 1
)

call "%~dp0resolve_python.bat" PYTHON_CMD
if not defined PYTHON_CMD (
    echo Missing Python.
    exit /b 1
)

call "%~dp0prepare_xsim_runtime.bat" dhrystone_score XSIM_RUN_DIR
if not defined XSIM_RUN_DIR exit /b 1

if not exist "%XSIM_RUN_DIR%\build\sw" mkdir "%XSIM_RUN_DIR%\build\sw"
copy /y "%PROJECT_DIR%\build\sw\%OUTPUT_NAME%.hex" "%XSIM_RUN_DIR%\build\sw\YH_rv_cpu_dhrystone.hex" >nul
if errorlevel 1 exit /b 1

pushd "%XSIM_RUN_DIR%"

call %XVLOG% --sv -i "%PROJECT_DIR%\rtl" ^
    "%PROJECT_DIR%\tb\YH_rv_cpu_dhrystone_tb.v" ^
    "%PROJECT_DIR%\tb\YH_rv_cpu_dhrystone_rv32_zmmul_bitmanip_noidbr_tb.v" ^
    "%PROJECT_DIR%\tb\YH_rv_cpu_dhrystone_rv32_zmmul_bitmanip_idbr_tb.v" ^
    "%PROJECT_DIR%\tb\YH_rv_cpu_dhrystone_rv32_zmmul_zbc_xthead_noidbr_tb.v" ^
    "%PROJECT_DIR%\tb\YH_rv_cpu_dhrystone_rv32_zmmul_zbc_xthead_idbr_tb.v" ^
    "%PROJECT_DIR%\tb\YH_rv_cpu_dhrystone_rv32_zmmul_zbc_zicond_xthead_idbr_tb.v" ^
    "%PROJECT_DIR%\tb\YH_rv_cpu_dhrystone_rv32_zmmul_zbc_zicond_xthead_idbr_fold_tb.v" ^
    "%PROJECT_DIR%\tb\YH_rv_cpu_dhrystone_rv32_zmmul_zicond_xthead_idbr_tb.v" ^
    "%PROJECT_DIR%\tb\YH_rv_cpu_dhrystone_rv32_zmmul_xthead_idbr_tb.v" ^
    "%PROJECT_DIR%\tb\YH_rv_cpu_dhrystone_rv32im_zbc_xthead_idbr_tb.v" ^
    "%PROJECT_DIR%\rtl\YH_rv_cpu_soc.v" ^
    "%PROJECT_DIR%\rtl\YH_rv_sync_imem_rom.v" ^
    "%PROJECT_DIR%\rtl\YH_rv_sync_rom32.v" ^
    "%PROJECT_DIR%\rtl\YH_rv_dmem_ram.v" ^
    "%PROJECT_DIR%\rtl\YH_rv_cpu_icache.v" ^
    "%PROJECT_DIR%\rtl\YH_rv_cpu_dcache.v" ^
    "%PROJECT_DIR%\rtl\YH_rv_cpu.v" ^
    "%PROJECT_DIR%\rtl\YH_rv_cpu_if_stage.v" ^
    "%PROJECT_DIR%\rtl\YH_rv_cpu_id_stage.v" ^
    "%PROJECT_DIR%\rtl\YH_rv_cpu_ex_stage.v" ^
    "%PROJECT_DIR%\rtl\YH_rv_cpu_mem_stage.v" ^
    "%PROJECT_DIR%\rtl\YH_rv_cpu_wb_stage.v" ^
    "%PROJECT_DIR%\rtl\YH_rv_cpu_hazard_unit.v" ^
    "%PROJECT_DIR%\rtl\YH_rv_cpu_decoder.v" ^
    "%PROJECT_DIR%\rtl\YH_rv_cpu_regfile.v" ^
    "%PROJECT_DIR%\rtl\YH_rv_cpu_alu.v"
if errorlevel 1 goto :fail

call %XELAB% %TEST_TOP% -s %TEST_TOP%_snapshot
if errorlevel 1 goto :fail

call %XSIM% %TEST_TOP%_snapshot -testplusarg "max_cycles=%MAX_CYCLES%" -testplusarg "dhrystone_runs=%DHRYSTONE_RUNS%" %XSIM_EXTRA_ARGS% -runall > "%LOG_FILE%" 2>&1
type "%LOG_FILE%"

findstr /c:"PASS: dhrystone completed" "%LOG_FILE%" >nul
if errorlevel 1 goto :fail

call %PYTHON_CMD% "%~dp0report_dhrystone_result.py" "%LOG_FILE%" "%CLOCK_HZ%" "%SUMMARY_FILE%"
if errorlevel 1 goto :fail

echo.
echo Dhrystone summary:
type "%SUMMARY_FILE%"

echo.
echo PASS: dhrystone score completed.
set RUN_STATUS=0
goto :done

:fail
set RUN_STATUS=%ERRORLEVEL%

:done
popd
exit /b %RUN_STATUS%
