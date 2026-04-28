@echo off
setlocal EnableDelayedExpansion

for %%I in ("%~dp0..") do set PROJECT_DIR=%%~fI
set TARGET=%~1

if "%TARGET%"=="" set TARGET=rv32

set XVLOG=
set XELAB=
set XSIM=
set TEST_TOP=YH_rv_cpu_m_extension_tb
set LOG_FILE=%PROJECT_DIR%\build\tests\m_extension\YH_rv_cpu_m_extension_%TARGET%.log
set XSIM_RUN_DIR=

rem Resolve simulator tools from the active Vivado install on PATH.
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

rem Create output directory
if not exist "%PROJECT_DIR%\build\tests\m_extension" mkdir "%PROJECT_DIR%\build\tests\m_extension"

call "%~dp0prepare_xsim_runtime.bat" m_extension XSIM_RUN_DIR
if not defined XSIM_RUN_DIR exit /b 1

pushd "%XSIM_RUN_DIR%"

rem Compile M extension testbench with the full SoC stack.
call %XVLOG% --sv -i "%PROJECT_DIR%\rtl" ^
    "%PROJECT_DIR%\tb\YH_rv_cpu_m_extension_tb.v" ^
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

call %XSIM% %TEST_TOP%_snapshot -runall > "%LOG_FILE%" 2>&1
type "%LOG_FILE%"

rem Check for pass/fail. Prefer ASCII tokens so this stays robust across codepages.
findstr /r /c:"^\[FAIL\]" "%LOG_FILE%" >nul
if not errorlevel 1 goto :m_fail
findstr /c:"11/11" "%LOG_FILE%" >nul
if not errorlevel 1 goto :m_pass

:fail
set RUN_STATUS=%ERRORLEVEL%
goto :done

:m_pass
echo.
echo ========================================
echo M extension test: PASS
echo ========================================
set RUN_STATUS=0
goto :done

:m_fail
echo.
echo ========================================
echo M extension test: FAIL
echo ========================================
set RUN_STATUS=1

:done
popd
exit /b %RUN_STATUS%
