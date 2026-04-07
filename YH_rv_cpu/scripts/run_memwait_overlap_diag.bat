@echo off
setlocal EnableDelayedExpansion

for %%I in ("%~dp0") do set SCRIPT_DIR=%%~fI
for %%I in ("%~dp0..") do set PROJECT_DIR=%%~fI
set BUILD_DIR=%PROJECT_DIR%\build\sim
set XVLOG=
set XELAB=
set XSIM=
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
    echo Missing xvlog. Please install Vivado/xsim and ensure it is in PATH.
    exit /b 1
)

if not defined XELAB (
    echo Missing xelab. Please install Vivado/xsim and ensure it is in PATH.
    exit /b 1
)

if not defined XSIM (
    echo Missing xsim. Please install Vivado/xsim and ensure it is in PATH.
    exit /b 1
)

if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"

call "%SCRIPT_DIR%prepare_xsim_runtime.bat" memwait_overlap_diag XSIM_RUN_DIR
if not defined XSIM_RUN_DIR exit /b 1

pushd "%XSIM_RUN_DIR%"

call %XVLOG% --sv -i "%PROJECT_DIR%\rtl" ^
    "%PROJECT_DIR%\tb\YH_rv_cpu_memwait_overlap_tb.v" ^
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

call %XELAB% YH_rv_cpu_memwait_overlap_tb -s YH_rv_cpu_memwait_overlap_tb_snapshot
if errorlevel 1 goto :fail

set XSIM_TESTPLUSARGS=
:collect_plusargs
if "%~1"=="" goto :plusargs_done
set XSIM_TESTPLUSARGS=!XSIM_TESTPLUSARGS! --testplusarg "%~1"
shift
goto :collect_plusargs
:plusargs_done

set XSIM_LOG=%XSIM_RUN_DIR%\memwait_overlap_diag_xsim.log
call %XSIM% YH_rv_cpu_memwait_overlap_tb_snapshot --onerror quit -runall !XSIM_TESTPLUSARGS! > "%XSIM_LOG%" 2>&1
set RUN_STATUS=%ERRORLEVEL%
if exist "%XSIM_LOG%" (
    type "%XSIM_LOG%"
    findstr /c:"Fatal: FAIL:" "%XSIM_LOG%" >nul 2>nul
    if not errorlevel 1 set RUN_STATUS=1
)
goto :done

:fail
set RUN_STATUS=%ERRORLEVEL%

:done
popd
exit /b %RUN_STATUS%
