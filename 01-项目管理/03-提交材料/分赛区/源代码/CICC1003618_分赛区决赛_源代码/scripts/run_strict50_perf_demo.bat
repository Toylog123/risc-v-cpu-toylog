@echo off
setlocal EnableDelayedExpansion

for %%I in ("%~dp0..") do set PROJECT_DIR=%%~fI
set MAX_CYCLES=%~1
set BUILD_DIR=%PROJECT_DIR%\build\sim
set LOG_FILE=%PROJECT_DIR%\build\sw\YH_rv_cpu_strict50_perf_demo.log
set XVLOG=
set XELAB=
set XSIM=
set XSIM_RUN_DIR=

if "%MAX_CYCLES%"=="" set MAX_CYCLES=100000000

call "%~dp0build_firmware.bat" perf_demo
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

if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"

call "%~dp0prepare_xsim_runtime.bat" strict50_perf_demo XSIM_RUN_DIR
if not defined XSIM_RUN_DIR exit /b 1

if not exist "%XSIM_RUN_DIR%\build\sw" mkdir "%XSIM_RUN_DIR%\build\sw"
copy /y "%PROJECT_DIR%\build\sw\YH_rv_cpu_perf_demo.hex" "%XSIM_RUN_DIR%\build\sw\YH_rv_cpu_perf_demo.hex" >nul
if errorlevel 1 exit /b 1
copy /y "%PROJECT_DIR%\build\sw\YH_rv_cpu_perf_demo.mem32.hex" "%XSIM_RUN_DIR%\build\sw\YH_rv_cpu_perf_demo.mem32.hex" >nul
if errorlevel 1 exit /b 1

pushd "%XSIM_RUN_DIR%"

call %XVLOG% --sv -i "%PROJECT_DIR%\rtl" ^
    "%PROJECT_DIR%\tb\YH_rv_cpu_strict50_perf_demo_tb.v" ^
    "%PROJECT_DIR%\rtl\YH_rv_cpu_soc.v" ^
    "%PROJECT_DIR%\rtl\YH_rv_sync_imem_rom.v" ^
    "%PROJECT_DIR%\rtl\YH_rv_sync_rom32.v" ^
    "%PROJECT_DIR%\rtl\YH_rv_dmem_ram.v" ^
    "%PROJECT_DIR%\rtl\YH_rv_cpu_dcache.v" ^
    "%PROJECT_DIR%\rtl\YH_rv_cpu_icache.v" ^
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

call %XELAB% YH_rv_cpu_strict50_perf_demo_tb -s YH_rv_cpu_strict50_perf_demo_tb_snapshot
if errorlevel 1 goto :fail

call %XSIM% YH_rv_cpu_strict50_perf_demo_tb_snapshot -testplusarg "max_cycles=%MAX_CYCLES%" -runall > "%LOG_FILE%" 2>&1
set RUN_STATUS=%ERRORLEVEL%
type "%LOG_FILE%"
goto :done

:fail
set RUN_STATUS=%ERRORLEVEL%

:done
popd
exit /b %RUN_STATUS%
