@echo off
setlocal EnableDelayedExpansion

for %%I in ("%~dp0..") do set PROJECT_DIR=%%~fI
set TARGET=%~1
set ITERATIONS=%~2
set DATA_SIZE=%~3
set TIMER_HZ=%~4
set MAX_CYCLES=%~5
set SUMMARY_FILE=%~6
set EXEC_MASK=0

if "%TARGET%"=="" set TARGET=rv32
if "%ITERATIONS%"=="" set ITERATIONS=10
if "%DATA_SIZE%"=="" set DATA_SIZE=2000
if "%TIMER_HZ%"=="" set TIMER_HZ=100000000UL
if "%MAX_CYCLES%"=="" set MAX_CYCLES=20000000

if "%SUMMARY_FILE%"=="" (
    set SUMMARY_FILE=%PROJECT_DIR%\build\sw\YH_rv_cpu_coremark_%TARGET%_score.summary.txt
)

call "%~dp0build_coremark.bat" %TARGET% %ITERATIONS% %DATA_SIZE% %TIMER_HZ% %EXEC_MASK%
if errorlevel 1 exit /b 1

set XVLOG=
set XELAB=
set XSIM=
set PYTHON_CMD=
set TEST_TOP=YH_rv_cpu_coremark_rv32_tb
set LOG_FILE=%PROJECT_DIR%\build\sw\YH_rv_cpu_coremark_%TARGET%_score.log

if /I "%TARGET%"=="rv64" set TEST_TOP=YH_rv_cpu_coremark_rv64_tb

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

pushd "%PROJECT_DIR%"

call %XVLOG% --sv -i rtl ^
    tb\YH_rv_cpu_coremark_tb.v ^
    tb\YH_rv_cpu_coremark_rv32_tb.v ^
    tb\YH_rv_cpu_coremark_rv64_tb.v ^
    rtl\YH_rv_cpu_soc.v ^
    rtl\YH_rv_sync_imem_rom.v ^
    rtl\YH_rv_sync_rom32.v ^
    rtl\YH_rv_dmem_ram.v ^
    rtl\YH_rv_cpu.v ^
    rtl\YH_rv_cpu_if_stage.v ^
    rtl\YH_rv_cpu_id_stage.v ^
    rtl\YH_rv_cpu_ex_stage.v ^
    rtl\YH_rv_cpu_mem_stage.v ^
    rtl\YH_rv_cpu_wb_stage.v ^
    rtl\YH_rv_cpu_hazard_unit.v ^
    rtl\YH_rv_cpu_decoder.v ^
    rtl\YH_rv_cpu_regfile.v ^
    rtl\YH_rv_cpu_alu.v
if errorlevel 1 goto :fail

call %XELAB% %TEST_TOP% -s %TEST_TOP%_score_snapshot
if errorlevel 1 goto :fail

call %XSIM% %TEST_TOP%_score_snapshot -testplusarg "max_cycles=%MAX_CYCLES%" -runall > "%LOG_FILE%" 2>&1
type "%LOG_FILE%"

findstr /c:"PASS: coremark completed" "%LOG_FILE%" >nul
if errorlevel 1 goto :fail

call %PYTHON_CMD% "%~dp0report_coremark_result.py" "%LOG_FILE%" "%TIMER_HZ%" "%SUMMARY_FILE%"
if errorlevel 1 goto :fail

findstr /c:"competition_reportable=yes" "%SUMMARY_FILE%" >nul
if errorlevel 1 goto :fail

echo.
echo Score summary:
type "%SUMMARY_FILE%"

echo.
echo PASS: coremark score completed.
set RUN_STATUS=0
goto :done

:fail
set RUN_STATUS=%ERRORLEVEL%

:done
popd
call "%~dp0stage_runtime_to_tmp.bat" coremark_score
exit /b %RUN_STATUS%
