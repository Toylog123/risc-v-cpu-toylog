@echo off
setlocal

for %%I in ("%~dp0..") do set PROJECT_DIR=%%~fI
set XVLOG=
set XELAB=
set XSIM=

call "%~dp0build_firmware.bat" trap_smoke
if errorlevel 1 exit /b 1

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

pushd "%PROJECT_DIR%"

%XVLOG% --sv -i rtl ^
    tb\toylog_cpu_trap_tb.v ^
    rtl\toylog_cpu_soc.v ^
    rtl\toylog_cpu.v ^
    rtl\toylog_cpu_if_stage.v ^
    rtl\toylog_cpu_id_stage.v ^
    rtl\toylog_cpu_ex_stage.v ^
    rtl\toylog_cpu_mem_stage.v ^
    rtl\toylog_cpu_wb_stage.v ^
    rtl\toylog_cpu_hazard_unit.v ^
    rtl\toylog_cpu_decoder.v ^
    rtl\toylog_cpu_regfile.v ^
    rtl\toylog_cpu_alu.v
if errorlevel 1 goto :fail

%XELAB% toylog_cpu_trap_tb -s toylog_cpu_trap_tb_snapshot
if errorlevel 1 goto :fail

%XSIM% toylog_cpu_trap_tb_snapshot -runall
set RUN_STATUS=%ERRORLEVEL%
goto :done

:fail
set RUN_STATUS=%ERRORLEVEL%

:done
popd
exit /b %RUN_STATUS%
