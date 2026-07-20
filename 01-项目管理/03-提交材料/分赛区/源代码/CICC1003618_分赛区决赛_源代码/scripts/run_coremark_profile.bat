@echo off
setlocal EnableDelayedExpansion

for %%I in ("%~dp0..") do set PROJECT_DIR=%%~fI
set TARGET=%~1
rem The optional exec mask lets us keep profiling scenarios reproducible.
set ITERATIONS=%~2
set DATA_SIZE=%~3
set TIMER_HZ=%~4
set MAX_CYCLES=%~5
set EXEC_MASK=%~6
set BUILD_OUTPUT_NAME=

if "%TARGET%"=="" set TARGET=rv32
if "%ITERATIONS%"=="" set ITERATIONS=10
if "%DATA_SIZE%"=="" set DATA_SIZE=2000
if "%TIMER_HZ%"=="" set TIMER_HZ=100000000UL
if "%MAX_CYCLES%"=="" set MAX_CYCLES=20000000
if "%EXEC_MASK%"=="" set EXEC_MASK=0
set BUILD_OUTPUT_NAME=YH_rv_cpu_coremark_%TARGET%_profile

rem Generate a dedicated image so profile logs never overwrite score runs.
call "%~dp0build_coremark.bat" %TARGET% %ITERATIONS% %DATA_SIZE% %TIMER_HZ% %EXEC_MASK% %BUILD_OUTPUT_NAME%
if errorlevel 1 exit /b 1

set XVLOG=
set XELAB=
set XSIM=
set TEST_TOP=YH_rv_cpu_coremark_profile_rv32_tb
set LOG_FILE=%PROJECT_DIR%\build\sw\YH_rv_cpu_coremark_%TARGET%_profile.log
set XSIM_RUN_DIR=
set ROM_TARGET=rv32
set XLEN_GENERIC=32
set SYNC_IMEM=1
set IMEM_OUTPUT_REG=0
set ENABLE_M_EXTENSION=1
set ENABLE_ZMMUL_EXTENSION=0
set ENABLE_BITMANIP_EXTENSION=1
set ENABLE_ZBC_EXTENSION=0
set ENABLE_ZICOND_EXTENSION=0
set ENABLE_ZBKB_EXTENSION=0
set ENABLE_XTHEAD_EXTENSION=1
set ENABLE_XTHEAD_COND_MOVE=1
set ENABLE_ID_BRANCH_EX_FORWARD=1
set ENABLE_ID_BRANCH_FOLD=0
set ENABLE_DYNAMIC_BRANCH_PREDICT=0
set BRANCH_BHT_ENTRIES=64
set BRANCH_STATIC_PREDICT_MODE=0
set BRANCH_BHT_STRONG_ONLY=0
set ENABLE_BRANCH_BHT_ID_UPDATE=1
set ENABLE_REDIRECT_CACHE_REGULAR_LOOKUP=1
set ENABLE_FETCH_REDIRECT_REUSE=0
set REDIRECT_CACHE_ENTRIES=1024
set REDIRECT_CACHE_XOR_INDEX=0

if /I "%TARGET%"=="rv64" (
    set TEST_TOP=YH_rv_cpu_coremark_profile_rv64_tb
    set ROM_TARGET=rv64
    set XLEN_GENERIC=64
)
if /I "%TARGET%"=="rv64im" (
    set TEST_TOP=YH_rv_cpu_coremark_profile_rv64_tb
    set ROM_TARGET=rv64
    set XLEN_GENERIC=64
)
if /I "%TARGET%"=="rv32i_zmmul_zba_zbb_zbs_zbc_xthead_memidx_noautoinc_o2sched_nocaller_noifconv" (
    set TEST_TOP=YH_rv_cpu_coremark_profile_rv32_zmmul_bitmanip_zbc_xthead_idbr_tb
    set ROM_TARGET=rv32
)
if /I "%TARGET%"=="rv32i_zmmul_zba_zbb_zbs_zbc_zicond_xthead_memidx_noautoinc_o2sched_nocaller" (
    set TEST_TOP=YH_rv_cpu_coremark_profile_rv32_zmmul_bitmanip_zbc_zicond_xthead_idbr_tb
    set ROM_TARGET=rv32
)
if /I "%TARGET%"=="rv32i_zmmul_zba_zbb_zbs_zicond_xthead_memidx_noautoinc_o2sched_nocaller" (
    set TEST_TOP=YH_rv_cpu_coremark_profile_rv32_zmmul_bitmanip_zicond_xthead_idbr_tb
    set ROM_TARGET=rv32
)
if not "%YH_COREMARK_PROFILE_TEST_TOP%"=="" set TEST_TOP=%YH_COREMARK_PROFILE_TEST_TOP%

echo %TARGET% | findstr /I "rv32i_zmmul" >nul
if not errorlevel 1 (
    set ENABLE_M_EXTENSION=0
    set ENABLE_ZMMUL_EXTENSION=1
)
echo %TARGET% | findstr /I "zba zbb zbs bitmanip" >nul
if not errorlevel 1 set ENABLE_BITMANIP_EXTENSION=1
echo %TARGET% | findstr /I "zbc" >nul
if not errorlevel 1 set ENABLE_ZBC_EXTENSION=1
echo %TARGET% | findstr /I "zicond" >nul
if not errorlevel 1 set ENABLE_ZICOND_EXTENSION=1
echo %TARGET% | findstr /I "zbkb" >nul
if not errorlevel 1 set ENABLE_ZBKB_EXTENSION=1
echo %TARGET% | findstr /I "xthead" >nul
if not errorlevel 1 (
    set ENABLE_XTHEAD_EXTENSION=1
    set ENABLE_XTHEAD_COND_MOVE=1
)
echo %TARGET% | findstr /I "noidbr" >nul
if not errorlevel 1 set ENABLE_ID_BRANCH_EX_FORWARD=0

if not "%YH_COREMARK_FPGA_DYNAMIC_BRANCH_PREDICT%"=="" (
    set ENABLE_DYNAMIC_BRANCH_PREDICT=%YH_COREMARK_FPGA_DYNAMIC_BRANCH_PREDICT%
)
if not "%YH_COREMARK_FPGA_BRANCH_BHT_ENTRIES%"=="" (
    set BRANCH_BHT_ENTRIES=%YH_COREMARK_FPGA_BRANCH_BHT_ENTRIES%
)
if not "%YH_COREMARK_FPGA_BRANCH_STATIC_PREDICT_MODE%"=="" (
    set BRANCH_STATIC_PREDICT_MODE=%YH_COREMARK_FPGA_BRANCH_STATIC_PREDICT_MODE%
)
if not "%YH_COREMARK_FPGA_BRANCH_BHT_STRONG_ONLY%"=="" (
    set BRANCH_BHT_STRONG_ONLY=%YH_COREMARK_FPGA_BRANCH_BHT_STRONG_ONLY%
)
if not "%YH_COREMARK_FPGA_ENABLE_BRANCH_BHT_ID_UPDATE%"=="" (
    set ENABLE_BRANCH_BHT_ID_UPDATE=%YH_COREMARK_FPGA_ENABLE_BRANCH_BHT_ID_UPDATE%
)
if not "%YH_COREMARK_FPGA_REDIRECT_CACHE_ENTRIES%"=="" (
    set REDIRECT_CACHE_ENTRIES=%YH_COREMARK_FPGA_REDIRECT_CACHE_ENTRIES%
)
if not "%YH_COREMARK_FPGA_REDIRECT_CACHE_XOR_INDEX%"=="" (
    set REDIRECT_CACHE_XOR_INDEX=%YH_COREMARK_FPGA_REDIRECT_CACHE_XOR_INDEX%
)
if not "%YH_COREMARK_FPGA_REDIRECT_CACHE_REGULAR_LOOKUP%"=="" (
    set ENABLE_REDIRECT_CACHE_REGULAR_LOOKUP=%YH_COREMARK_FPGA_REDIRECT_CACHE_REGULAR_LOOKUP%
)
if not "%YH_COREMARK_FPGA_FETCH_REDIRECT_REUSE%"=="" (
    set ENABLE_FETCH_REDIRECT_REUSE=%YH_COREMARK_FPGA_FETCH_REDIRECT_REUSE%
)
if not "%YH_COREMARK_FPGA_ID_BRANCH_FOLD%"=="" (
    set ENABLE_ID_BRANCH_FOLD=%YH_COREMARK_FPGA_ID_BRANCH_FOLD%
)

rem Resolve simulator tools dynamically to avoid hard-coded Vivado install paths.
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

call "%~dp0prepare_xsim_runtime.bat" coremark_profile XSIM_RUN_DIR
if not defined XSIM_RUN_DIR exit /b 1

rem Copy the program image into the throwaway runtime directory expected by the testbench.
if not exist "%XSIM_RUN_DIR%\build\sw" mkdir "%XSIM_RUN_DIR%\build\sw"
copy /y "%PROJECT_DIR%\build\sw\%BUILD_OUTPUT_NAME%.hex" "%XSIM_RUN_DIR%\build\sw\YH_rv_cpu_coremark_%ROM_TARGET%.hex" >nul
if errorlevel 1 exit /b 1
if exist "%PROJECT_DIR%\build\sw\%BUILD_OUTPUT_NAME%.mem32.hex" (
    copy /y "%PROJECT_DIR%\build\sw\%BUILD_OUTPUT_NAME%.mem32.hex" "%XSIM_RUN_DIR%\build\sw\YH_rv_cpu_coremark_%ROM_TARGET%.mem32.hex" >nul
    if errorlevel 1 exit /b 1
)

pushd "%XSIM_RUN_DIR%"

rem Compile the profile bench with the same RTL set used by the score flow.
call %XVLOG% --sv -i "%PROJECT_DIR%\rtl" ^
    "%PROJECT_DIR%\tb\YH_rv_cpu_coremark_profile_tb.v" ^
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

if /I "%TEST_TOP%"=="YH_rv_cpu_coremark_profile_tb" (
    call %XELAB% %TEST_TOP% ^
        -generic_top "XLEN=%XLEN_GENERIC%" ^
        -generic_top "SYNC_IMEM=%SYNC_IMEM%" ^
        -generic_top "IMEM_OUTPUT_REG=%IMEM_OUTPUT_REG%" ^
        -generic_top "ENABLE_M_EXTENSION=%ENABLE_M_EXTENSION%" ^
        -generic_top "ENABLE_ZMMUL_EXTENSION=%ENABLE_ZMMUL_EXTENSION%" ^
        -generic_top "ENABLE_BITMANIP_EXTENSION=%ENABLE_BITMANIP_EXTENSION%" ^
        -generic_top "ENABLE_ZBC_EXTENSION=%ENABLE_ZBC_EXTENSION%" ^
        -generic_top "ENABLE_ZICOND_EXTENSION=%ENABLE_ZICOND_EXTENSION%" ^
        -generic_top "ENABLE_ZBKB_EXTENSION=%ENABLE_ZBKB_EXTENSION%" ^
        -generic_top "ENABLE_XTHEAD_EXTENSION=%ENABLE_XTHEAD_EXTENSION%" ^
        -generic_top "ENABLE_XTHEAD_COND_MOVE=%ENABLE_XTHEAD_COND_MOVE%" ^
        -generic_top "ENABLE_ID_BRANCH_EX_FORWARD=%ENABLE_ID_BRANCH_EX_FORWARD%" ^
        -generic_top "ENABLE_ID_BRANCH_FOLD=%ENABLE_ID_BRANCH_FOLD%" ^
        -generic_top "ENABLE_REDIRECT_CACHE_REGULAR_LOOKUP=%ENABLE_REDIRECT_CACHE_REGULAR_LOOKUP%" ^
        -generic_top "ENABLE_FETCH_REDIRECT_REUSE=%ENABLE_FETCH_REDIRECT_REUSE%" ^
        -generic_top "REDIRECT_CACHE_ENTRIES=%REDIRECT_CACHE_ENTRIES%" ^
        -generic_top "REDIRECT_CACHE_XOR_INDEX=%REDIRECT_CACHE_XOR_INDEX%" ^
        -generic_top "ENABLE_DYNAMIC_BRANCH_PREDICT=%ENABLE_DYNAMIC_BRANCH_PREDICT%" ^
        -generic_top "BRANCH_BHT_ENTRIES=%BRANCH_BHT_ENTRIES%" ^
        -generic_top "BRANCH_STATIC_PREDICT_MODE=%BRANCH_STATIC_PREDICT_MODE%" ^
        -generic_top "BRANCH_BHT_STRONG_ONLY=%BRANCH_BHT_STRONG_ONLY%" ^
        -generic_top "ENABLE_BRANCH_BHT_ID_UPDATE=%ENABLE_BRANCH_BHT_ID_UPDATE%" ^
        -s %TEST_TOP%_snapshot
) else (
    call %XELAB% %TEST_TOP% -s %TEST_TOP%_snapshot
)
if errorlevel 1 goto :fail

call %XSIM% %TEST_TOP%_snapshot -testplusarg "max_cycles=%MAX_CYCLES%" -runall > "%LOG_FILE%" 2>&1
type "%LOG_FILE%"

rem Keep the report explicit so bottleneck breakdowns are easy to lift into docs.
findstr /c:"PASS: coremark profile completed" "%LOG_FILE%" >nul
if errorlevel 1 goto :fail

echo.
echo Profile summary:
findstr /c:"PROFILE:" "%LOG_FILE%"

echo.
echo PASS: coremark profile completed.
set RUN_STATUS=0
goto :done

:fail
set RUN_STATUS=%ERRORLEVEL%

:done
popd
exit /b %RUN_STATUS%
