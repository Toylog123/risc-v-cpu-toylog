@echo off
setlocal

for %%I in ("%~dp0..") do set PROJECT_DIR=%%~fI
set BUILD_DIR=%PROJECT_DIR%\build\sim
set XVLOG=
set XELAB=
set XSIM=

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

pushd "%PROJECT_DIR%"

call %XVLOG% --sv -i rtl ^
    tb\YH_rv_cpu_xlen64_tb.v ^
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

call %XELAB% YH_rv_cpu_xlen64_tb -s YH_rv_cpu_xlen64_tb_snapshot
if errorlevel 1 goto :fail

call %XSIM% YH_rv_cpu_xlen64_tb_snapshot -runall
set RUN_STATUS=%ERRORLEVEL%
goto :done

:fail
set RUN_STATUS=%ERRORLEVEL%

:done
popd
call "%~dp0stage_runtime_to_tmp.bat" xlen64_smoke
exit /b %RUN_STATUS%


