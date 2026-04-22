@echo off
setlocal

for %%I in ("%~dp0..") do set PROJECT_DIR=%%~fI
rem This smoke run validates timer interrupt delivery and handler return sequencing.
set XVLOG=
set XELAB=
set XSIM=
set XSIM_RUN_DIR=

rem Rebuild the timer-IRQ firmware first so the simulation image is fresh.
call "%~dp0build_firmware.bat" timer_irq_smoke
if errorlevel 1 exit /b 1

rem Resolve simulator tools from the active PATH configuration.
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

call "%~dp0prepare_xsim_runtime.bat" timer_irq_smoke XSIM_RUN_DIR
if not defined XSIM_RUN_DIR exit /b 1

rem Stage the timer-IRQ image into the disposable xsim runtime tree.
if not exist "%XSIM_RUN_DIR%\build\sw" mkdir "%XSIM_RUN_DIR%\build\sw"
copy /y "%PROJECT_DIR%\build\sw\YH_rv_cpu_timer_irq_smoke.hex" "%XSIM_RUN_DIR%\build\sw\YH_rv_cpu_timer_irq_smoke.hex" >nul
if errorlevel 1 exit /b 1

pushd "%XSIM_RUN_DIR%"

rem Compile the timer-IRQ bench with the same SoC RTL used by the other smoke tests.
call %XVLOG% --sv -i "%PROJECT_DIR%\rtl" ^
    "%PROJECT_DIR%\tb\YH_rv_cpu_timer_irq_tb.v" ^
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

call %XELAB% YH_rv_cpu_timer_irq_tb -s YH_rv_cpu_timer_irq_tb_snapshot
if errorlevel 1 goto :fail

call %XSIM% YH_rv_cpu_timer_irq_tb_snapshot -runall
set RUN_STATUS=%ERRORLEVEL%
goto :done

:fail
set RUN_STATUS=%ERRORLEVEL%

:done
popd
exit /b %RUN_STATUS%


