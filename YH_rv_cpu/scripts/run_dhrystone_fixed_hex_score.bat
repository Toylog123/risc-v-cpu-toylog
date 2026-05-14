@echo off
setlocal EnableDelayedExpansion

for %%I in ("%~dp0..") do set PROJECT_DIR=%%~fI
set TEST_TOP=%~1
set ROM_HEX=%~2
set CLOCK_HZ=%~3
set MAX_CYCLES=%~4
set DHRYSTONE_RUNS=%~5
set SUMMARY_FILE=%~6
set OUTPUT_DIR=
set OUTPUT_STEM=
set LOG_FILE=
set XSIM_RUN_DIR=
set XVLOG=
set XELAB=
set XSIM=
set PYTHON_CMD=

if "%TEST_TOP%"=="" set TEST_TOP=YH_rv_cpu_dhrystone_rv32_zmmul_zbc_xthead_idbr_tb
if "%ROM_HEX%"=="" (
    echo usage: run_dhrystone_fixed_hex_score.bat ^<test_top^> ^<rom_hex^> [clock_hz] [max_cycles] [runs] [summary_file]
    exit /b 2
)
if "%CLOCK_HZ%"=="" set CLOCK_HZ=100000000UL
if "%MAX_CYCLES%"=="" set MAX_CYCLES=250000000
if "%DHRYSTONE_RUNS%"=="" set DHRYSTONE_RUNS=10
if "%SUMMARY_FILE%"=="" set SUMMARY_FILE=%PROJECT_DIR%\build\sw\%TEST_TOP%_fixed_hex.summary.txt

for %%I in ("%ROM_HEX%") do set ROM_HEX=%%~fI
if not exist "%ROM_HEX%" (
    echo Missing ROM hex: %ROM_HEX%
    exit /b 1
)

for %%I in ("%SUMMARY_FILE%") do (
    set SUMMARY_FILE=%%~fI
    set OUTPUT_DIR=%%~dpI
    set OUTPUT_STEM=%%~nI
)
if /I "!OUTPUT_STEM:~-8!"==".summary" set OUTPUT_STEM=!OUTPUT_STEM:~0,-8!
if not exist "!OUTPUT_DIR!" mkdir "!OUTPUT_DIR!"
set LOG_FILE=!OUTPUT_DIR!!OUTPUT_STEM!.log

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

call "%~dp0prepare_xsim_runtime.bat" dhrystone_fixed_hex_score XSIM_RUN_DIR
if not defined XSIM_RUN_DIR exit /b 1

if not exist "%XSIM_RUN_DIR%\build\sw" mkdir "%XSIM_RUN_DIR%\build\sw"
copy /y "%ROM_HEX%" "%XSIM_RUN_DIR%\build\sw\YH_rv_cpu_dhrystone.hex" >nul
if errorlevel 1 exit /b 1

pushd "%XSIM_RUN_DIR%"

call %XVLOG% --sv -i "%PROJECT_DIR%\rtl" ^
    "%PROJECT_DIR%\tb\YH_rv_cpu_dhrystone_tb.v" ^
    "%PROJECT_DIR%\tb\YH_rv_cpu_dhrystone_rv32_zmmul_bitmanip_noidbr_tb.v" ^
    "%PROJECT_DIR%\tb\YH_rv_cpu_dhrystone_rv32_zmmul_bitmanip_idbr_tb.v" ^
    "%PROJECT_DIR%\tb\YH_rv_cpu_dhrystone_rv32_zmmul_zbc_xthead_noidbr_tb.v" ^
    "%PROJECT_DIR%\tb\YH_rv_cpu_dhrystone_rv32_zmmul_zbc_xthead_idbr_tb.v" ^
    "%PROJECT_DIR%\tb\YH_rv_cpu_dhrystone_rv32_zmmul_zbc_zicond_xthead_idbr_tb.v" ^
    "%PROJECT_DIR%\tb\YH_rv_cpu_dhrystone_rv32_zmmul_zicond_xthead_idbr_tb.v" ^
    "%PROJECT_DIR%\tb\YH_rv_cpu_dhrystone_rv32im_zbc_xthead_idbr_tb.v" ^
    "%PROJECT_DIR%\rtl\YH_rv_cpu_soc.v" ^
    "%PROJECT_DIR%\rtl\YH_rv_sync_imem_rom.v" ^
    "%PROJECT_DIR%\rtl\YH_rv_sync_rom32.v" ^
    "%PROJECT_DIR%\rtl\YH_rv_dmem_ram.v" ^
    "%PROJECT_DIR%\rtl\YH_rv_cpu_icache.v" ^
    "%PROJECT_DIR%\rtl\YH_rv_cpu_dcache.v" ^
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

call %XELAB% %TEST_TOP% -s %TEST_TOP%_fixed_hex_snapshot
if errorlevel 1 goto :fail

call %XSIM% %TEST_TOP%_fixed_hex_snapshot -testplusarg "max_cycles=%MAX_CYCLES%" -testplusarg "dhrystone_runs=%DHRYSTONE_RUNS%" -runall > "%LOG_FILE%" 2>&1
type "%LOG_FILE%"

findstr /c:"PASS: dhrystone completed" "%LOG_FILE%" >nul
if errorlevel 1 goto :fail

call %PYTHON_CMD% "%~dp0report_dhrystone_result.py" "%LOG_FILE%" "%CLOCK_HZ%" "%SUMMARY_FILE%"
if errorlevel 1 goto :fail

echo.
echo Dhrystone summary:
type "%SUMMARY_FILE%"
set RUN_STATUS=0
goto :done

:fail
set RUN_STATUS=%ERRORLEVEL%
if "%RUN_STATUS%"=="0" set RUN_STATUS=1

:done
popd
exit /b %RUN_STATUS%
