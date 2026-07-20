@echo off
setlocal EnableDelayedExpansion

for %%I in ("%~dp0..") do set PROJECT_DIR=%%~fI
set XVLOG=
set XELAB=
set XSIM=
set TEST_TOP=YH_rv_cpu_bitmanip_fast_subset_tb
set LOG_DIR=%PROJECT_DIR%\build\tests\bitmanip_fast_subset
set LOG_FILE=%LOG_DIR%\YH_rv_cpu_bitmanip_fast_subset.log
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

if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

call "%~dp0prepare_xsim_runtime.bat" bitmanip_fast_subset XSIM_RUN_DIR
if not defined XSIM_RUN_DIR exit /b 1

pushd "%XSIM_RUN_DIR%"

call %XVLOG% --sv -i "%PROJECT_DIR%\rtl" ^
    "%PROJECT_DIR%\tb\YH_rv_cpu_bitmanip_fast_subset_tb.v" ^
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

call %XSIM% %TEST_TOP%_snapshot -runall > "%LOG_FILE%" 2>&1
type "%LOG_FILE%"

findstr /c:"PASS: bitmanip fast subset diagnostic completed" "%LOG_FILE%" >nul
if errorlevel 1 goto :fail

echo.
echo Bitmanip fast subset diagnostic: PASS
set RUN_STATUS=0
goto :done

:fail
set RUN_STATUS=%ERRORLEVEL%
if "%RUN_STATUS%"=="0" set RUN_STATUS=1

:done
popd
exit /b %RUN_STATUS%
