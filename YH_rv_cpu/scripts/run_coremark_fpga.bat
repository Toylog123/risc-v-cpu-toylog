@echo off
setlocal EnableDelayedExpansion

for %%I in ("%~dp0..") do set PROJECT_DIR=%%~fI
set TARGET=%~1
set ITERATIONS=%~2
set DATA_SIZE=%~3
set TIMER_HZ=%~4
set MAX_CYCLES=%~5
set SUMMARY_FILE=%~6
set EXEC_MASK=%~7
set BUILD_OUTPUT_NAME=
set OUTPUT_DIR=
set OUTPUT_STEM=
set XSIM_TRACE_ARGS=
set XSIM_RUN_DIR=
set EXPECTED_COREMARK_SIZE=
set EXEC_ALGO_COUNT=
set EXEC_MASK_NUM=

if "%TARGET%"=="" set TARGET=rv32
if "%ITERATIONS%"=="" set ITERATIONS=1
if "%DATA_SIZE%"=="" set DATA_SIZE=400
if "%TIMER_HZ%"=="" set TIMER_HZ=100000000UL
if "%MAX_CYCLES%"=="" set MAX_CYCLES=20000000
if "%EXEC_MASK%"=="" set EXEC_MASK=1

if "%EXEC_MASK%"=="0" (
    set EXEC_ALGO_COUNT=3
) else (
    set /a EXEC_MASK_NUM=%EXEC_MASK%
    set /a EXEC_ALGO_COUNT=^(EXEC_MASK_NUM ^& 1^) + ^(^(EXEC_MASK_NUM ^>^> 1^) ^& 1^) + ^(^(EXEC_MASK_NUM ^>^> 2^) ^& 1^)
    if "!EXEC_ALGO_COUNT!"=="0" set EXEC_ALGO_COUNT=3
)
set /a EXPECTED_COREMARK_SIZE=%DATA_SIZE% / !EXEC_ALGO_COUNT!

if "%SUMMARY_FILE%"=="" (
    set SUMMARY_FILE=%PROJECT_DIR%\build\sw\YH_rv_cpu_coremark_%TARGET%_fpga.summary.txt
)
for %%I in ("%SUMMARY_FILE%") do (
    set SUMMARY_FILE=%%~fI
    set OUTPUT_DIR=%%~dpI
    set OUTPUT_STEM=%%~nI
)
if /I "!OUTPUT_STEM:~-8!"==".summary" set OUTPUT_STEM=!OUTPUT_STEM:~0,-8!
if not defined OUTPUT_STEM set OUTPUT_STEM=YH_rv_cpu_coremark_%TARGET%_fpga
set BUILD_OUTPUT_NAME=!OUTPUT_STEM!

call "%~dp0build_coremark.bat" %TARGET% %ITERATIONS% %DATA_SIZE% %TIMER_HZ% %EXEC_MASK% %BUILD_OUTPUT_NAME%
if errorlevel 1 exit /b 1

set XVLOG=
set XELAB=
set XSIM=
set PYTHON_CMD=
set TEST_TOP=YH_rv_cpu_coremark_fpga_tb
set LOG_FILE=!OUTPUT_DIR!!OUTPUT_STEM!.log
set ROM_TARGET=rv32
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
set ENABLE_ID_BRANCH_NOT_TAKEN_LOAD_FOLD=0
set ENABLE_ID_ALU_PAIR_FOLD=0
set ENABLE_ID_ALU_DEP_FOLD=0
set ENABLE_DYNAMIC_BRANCH_PREDICT=0
set BRANCH_BHT_ENTRIES=64
set BRANCH_STATIC_PREDICT_MODE=0
set BRANCH_BHT_STRONG_ONLY=0
set ENABLE_REDIRECT_CACHE_REGULAR_LOOKUP=1
set ENABLE_FETCH_REDIRECT_REUSE=0
set REDIRECT_CACHE_ENTRIES=1024
set REDIRECT_CACHE_XOR_INDEX=0
set DMEM_NEGEDGE_READ=0
set ICACHE_EN=0

if not "%YH_COREMARK_FPGA_DMEM_NEGEDGE_READ%"=="" (
    set DMEM_NEGEDGE_READ=%YH_COREMARK_FPGA_DMEM_NEGEDGE_READ%
)
if not "%YH_COREMARK_FPGA_ICACHE_EN%"=="" (
    set ICACHE_EN=%YH_COREMARK_FPGA_ICACHE_EN%
)
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
if not "%YH_COREMARK_FPGA_ID_BRANCH_NOT_TAKEN_LOAD_FOLD%"=="" (
    set ENABLE_ID_BRANCH_NOT_TAKEN_LOAD_FOLD=%YH_COREMARK_FPGA_ID_BRANCH_NOT_TAKEN_LOAD_FOLD%
)
if not "%YH_COREMARK_FPGA_ID_ALU_PAIR_FOLD%"=="" (
    set ENABLE_ID_ALU_PAIR_FOLD=%YH_COREMARK_FPGA_ID_ALU_PAIR_FOLD%
)
if not "%YH_COREMARK_FPGA_ID_ALU_DEP_FOLD%"=="" (
    set ENABLE_ID_ALU_DEP_FOLD=%YH_COREMARK_FPGA_ID_ALU_DEP_FOLD%
)

if /I "%TARGET%"=="rv64" set ROM_TARGET=rv64
if /I "%TARGET%"=="rv64im" set ROM_TARGET=rv64
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

if not "%YH_XSIM_DEBUG_TRACE%"=="" (
    set XSIM_TRACE_ARGS=!XSIM_TRACE_ARGS! -testplusarg debug_trace
)
if not "%YH_XSIM_TRACE_CYCLES%"=="" (
    set XSIM_TRACE_ARGS=!XSIM_TRACE_ARGS! -testplusarg "trace_cycles=%YH_XSIM_TRACE_CYCLES%"
)
if not "%YH_XSIM_TRACE_START%"=="" (
    set XSIM_TRACE_ARGS=!XSIM_TRACE_ARGS! -testplusarg "trace_start=%YH_XSIM_TRACE_START%"
)
if not "%YH_XSIM_TRACE_END%"=="" (
    set XSIM_TRACE_ARGS=!XSIM_TRACE_ARGS! -testplusarg "trace_end=%YH_XSIM_TRACE_END%"
)
if not "%YH_XSIM_TRACE_STRIDE%"=="" (
    set XSIM_TRACE_ARGS=!XSIM_TRACE_ARGS! -testplusarg "trace_stride=%YH_XSIM_TRACE_STRIDE%"
)

call "%~dp0prepare_xsim_runtime.bat" coremark_fpga XSIM_RUN_DIR
if not defined XSIM_RUN_DIR exit /b 1

if not exist "%XSIM_RUN_DIR%\build\sw" mkdir "%XSIM_RUN_DIR%\build\sw"
copy /y "%PROJECT_DIR%\build\sw\%BUILD_OUTPUT_NAME%.hex" "%XSIM_RUN_DIR%\build\sw\YH_rv_cpu_coremark_%ROM_TARGET%.hex" >nul
if errorlevel 1 exit /b 1
if exist "%PROJECT_DIR%\build\sw\%BUILD_OUTPUT_NAME%.mem32.hex" (
    copy /y "%PROJECT_DIR%\build\sw\%BUILD_OUTPUT_NAME%.mem32.hex" "%XSIM_RUN_DIR%\build\sw\YH_rv_cpu_coremark_%ROM_TARGET%.mem32.hex" >nul
    if errorlevel 1 exit /b 1
)

pushd "%XSIM_RUN_DIR%"

call %XVLOG% --sv -i "%PROJECT_DIR%\rtl" ^
    "%PROJECT_DIR%\tb\YH_rv_cpu_coremark_fpga_tb.v" ^
    "%PROJECT_DIR%\rtl\YH_rv_cpu_soc.v" ^
    "%PROJECT_DIR%\rtl\YH_rv_sync_imem_rom.v" ^
    "%PROJECT_DIR%\rtl\YH_rv_sync_rom32.v" ^
    "%PROJECT_DIR%\rtl\YH_rv_dmem_ram.v" ^
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

call %XELAB% %TEST_TOP% ^
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
    -generic_top "ENABLE_ID_BRANCH_NOT_TAKEN_LOAD_FOLD=%ENABLE_ID_BRANCH_NOT_TAKEN_LOAD_FOLD%" ^
    -generic_top "ENABLE_ID_ALU_PAIR_FOLD=%ENABLE_ID_ALU_PAIR_FOLD%" ^
    -generic_top "ENABLE_ID_ALU_DEP_FOLD=%ENABLE_ID_ALU_DEP_FOLD%" ^
    -generic_top "ENABLE_REDIRECT_CACHE_REGULAR_LOOKUP=%ENABLE_REDIRECT_CACHE_REGULAR_LOOKUP%" ^
    -generic_top "ENABLE_FETCH_REDIRECT_REUSE=%ENABLE_FETCH_REDIRECT_REUSE%" ^
    -generic_top "REDIRECT_CACHE_ENTRIES=%REDIRECT_CACHE_ENTRIES%" ^
    -generic_top "REDIRECT_CACHE_XOR_INDEX=%REDIRECT_CACHE_XOR_INDEX%" ^
    -generic_top "ENABLE_DYNAMIC_BRANCH_PREDICT=%ENABLE_DYNAMIC_BRANCH_PREDICT%" ^
    -generic_top "BRANCH_BHT_ENTRIES=%BRANCH_BHT_ENTRIES%" ^
    -generic_top "BRANCH_STATIC_PREDICT_MODE=%BRANCH_STATIC_PREDICT_MODE%" ^
    -generic_top "BRANCH_BHT_STRONG_ONLY=%BRANCH_BHT_STRONG_ONLY%" ^
    -generic_top "DMEM_NEGEDGE_READ=%DMEM_NEGEDGE_READ%" ^
    -generic_top "ICACHE_EN=%ICACHE_EN%" ^
    -s %TEST_TOP%_snapshot
if errorlevel 1 goto :fail

call %XSIM% %TEST_TOP%_snapshot -testplusarg "max_cycles=%MAX_CYCLES%" !XSIM_TRACE_ARGS! %YH_XSIM_EXTRA_ARGS% -runall > "%LOG_FILE%" 2>&1
type "%LOG_FILE%"

findstr /c:"PASS: coremark completed" "%LOG_FILE%" >nul
if errorlevel 1 goto :fail

call %PYTHON_CMD% "%~dp0report_coremark_result.py" "%LOG_FILE%" "%TIMER_HZ%" "%SUMMARY_FILE%" "%EXPECTED_COREMARK_SIZE%" "%ITERATIONS%"
if errorlevel 1 goto :fail

echo.
echo FPGA-like score summary:
type "%SUMMARY_FILE%"

echo.
echo PASS: coremark fpga-style run completed.
set RUN_STATUS=0
goto :done

:fail
set RUN_STATUS=%ERRORLEVEL%

:done
popd
exit /b %RUN_STATUS%
