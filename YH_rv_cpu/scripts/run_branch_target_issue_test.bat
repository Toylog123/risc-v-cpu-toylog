@echo off
setlocal EnableDelayedExpansion

for %%I in ("%~dp0..") do set PROJECT_DIR=%%~fI
set SCRIPT_DIR=%~dp0
set XVLOG=
set XELAB=
set XSIM=
set XSIM_RUN_DIR=
set LOG_DIR=%PROJECT_DIR%\build\tests
set LOG_FILE=%LOG_DIR%\branch_target_issue.log

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

call "%SCRIPT_DIR%prepare_xsim_runtime.bat" branch_target_issue XSIM_RUN_DIR
if not defined XSIM_RUN_DIR exit /b 1
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

pushd "%XSIM_RUN_DIR%"

call %XVLOG% --sv -i "%PROJECT_DIR%\rtl" ^
    "%PROJECT_DIR%\tb\YH_rv_cpu_branch_target_issue_tb.v" ^
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

call %XELAB% YH_rv_cpu_branch_target_issue_tb -s YH_rv_cpu_branch_target_issue_tb_snapshot
if errorlevel 1 goto :fail

call %XSIM% YH_rv_cpu_branch_target_issue_tb_snapshot -runall -onerror quit > "%LOG_FILE%" 2>&1
type "%LOG_FILE%"
findstr /c:"FAIL:" "%LOG_FILE%" >nul
if not errorlevel 1 goto :fail
findstr /c:"PASS:" "%LOG_FILE%" >nul
if errorlevel 1 goto :fail
set RUN_STATUS=0
goto :done

:fail
set RUN_STATUS=%ERRORLEVEL%
if "%RUN_STATUS%"=="0" set RUN_STATUS=1

:done
popd
exit /b %RUN_STATUS%
