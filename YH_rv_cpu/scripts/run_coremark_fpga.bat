@echo off
setlocal EnableDelayedExpansion

for %%I in ("%~dp0..") do set PROJECT_DIR=%%~fI
set TARGET=%~1
set ITERATIONS=%~2
set DATA_SIZE=%~3
set TIMER_HZ=%~4
set MAX_CYCLES=%~5
set SUMMARY_FILE=%~6
set EXEC_MASK=%~7
set BUILD_OUTPUT_NAME=
set XSIM_RUN_DIR=

if "%TARGET%"=="" set TARGET=rv32
if "%ITERATIONS%"=="" set ITERATIONS=1
if "%DATA_SIZE%"=="" set DATA_SIZE=400
if "%TIMER_HZ%"=="" set TIMER_HZ=100000000UL
if "%MAX_CYCLES%"=="" set MAX_CYCLES=20000000
if "%EXEC_MASK%"=="" set EXEC_MASK=1
set BUILD_OUTPUT_NAME=YH_rv_cpu_coremark_%TARGET%_fpga

if "%SUMMARY_FILE%"=="" (
    set SUMMARY_FILE=%PROJECT_DIR%\build\sw\YH_rv_cpu_coremark_%TARGET%_fpga.summary.txt
)

call "%~dp0build_coremark.bat" %TARGET% %ITERATIONS% %DATA_SIZE% %TIMER_HZ% %EXEC_MASK% %BUILD_OUTPUT_NAME%
if errorlevel 1 exit /b 1

set XVLOG=
set XELAB=
set XSIM=
set PYTHON_CMD=
set TEST_TOP=YH_rv_cpu_coremark_fpga_tb
set LOG_FILE=%PROJECT_DIR%\build\sw\YH_rv_cpu_coremark_%TARGET%_fpga.log

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

call "%~dp0prepare_xsim_runtime.bat" coremark_fpga XSIM_RUN_DIR
if not defined XSIM_RUN_DIR exit /b 1

if not exist "%XSIM_RUN_DIR%\build\sw" mkdir "%XSIM_RUN_DIR%\build\sw"
copy /y "%PROJECT_DIR%\build\sw\%BUILD_OUTPUT_NAME%.hex" "%XSIM_RUN_DIR%\build\sw\YH_rv_cpu_coremark_%TARGET%.hex" >nul
if errorlevel 1 exit /b 1
if exist "%PROJECT_DIR%\build\sw\%BUILD_OUTPUT_NAME%.mem32.hex" (
    copy /y "%PROJECT_DIR%\build\sw\%BUILD_OUTPUT_NAME%.mem32.hex" "%XSIM_RUN_DIR%\build\sw\YH_rv_cpu_coremark_%TARGET%.mem32.hex" >nul
    if errorlevel 1 exit /b 1
)

pushd "%XSIM_RUN_DIR%"

call %XVLOG% --sv -i "%PROJECT_DIR%\rtl" ^
    "%PROJECT_DIR%\tb\YH_rv_cpu_coremark_fpga_tb.v" ^
    "%PROJECT_DIR%\rtl\YH_rv_cpu_soc.v" ^
    "%PROJECT_DIR%\rtl\YH_rv_sync_imem_rom.v" ^
    "%PROJECT_DIR%\rtl\YH_rv_sync_rom32.v" ^
    "%PROJECT_DIR%\rtl\YH_rv_dmem_ram.v" ^
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

call %XSIM% %TEST_TOP%_snapshot -testplusarg "max_cycles=%MAX_CYCLES%" -runall > "%LOG_FILE%" 2>&1
type "%LOG_FILE%"

findstr /c:"PASS: coremark completed" "%LOG_FILE%" >nul
if errorlevel 1 goto :fail

call %PYTHON_CMD% "%~dp0report_coremark_result.py" "%LOG_FILE%" "%TIMER_HZ%" "%SUMMARY_FILE%"
if errorlevel 1 goto :fail

echo.
echo FPGA-like score summary:
type "%SUMMARY_FILE%"

echo.
echo PASS: coremark fpga-style run completed.
set RUN_STATUS=0
goto :done

:fail
set RUN_STATUS=%ERRORLEVEL%

:done
popd
exit /b %RUN_STATUS%
