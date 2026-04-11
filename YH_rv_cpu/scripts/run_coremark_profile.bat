@echo off
setlocal EnableDelayedExpansion

for %%I in ("%~dp0..") do set PROJECT_DIR=%%~fI
set TARGET=%~1
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

call "%~dp0build_coremark.bat" %TARGET% %ITERATIONS% %DATA_SIZE% %TIMER_HZ% %EXEC_MASK% %BUILD_OUTPUT_NAME%
if errorlevel 1 exit /b 1

set XVLOG=
set XELAB=
set XSIM=
set TEST_TOP=YH_rv_cpu_coremark_profile_rv32_tb
set LOG_FILE=%PROJECT_DIR%\build\sw\YH_rv_cpu_coremark_%TARGET%_profile.log
set XSIM_RUN_DIR=

if /I "%TARGET%"=="rv64" set TEST_TOP=YH_rv_cpu_coremark_profile_rv64_tb

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

if not exist "%XSIM_RUN_DIR%\build\sw" mkdir "%XSIM_RUN_DIR%\build\sw"
copy /y "%PROJECT_DIR%\build\sw\%BUILD_OUTPUT_NAME%.hex" "%XSIM_RUN_DIR%\build\sw\YH_rv_cpu_coremark_%TARGET%.hex" >nul
if errorlevel 1 exit /b 1
if exist "%PROJECT_DIR%\build\sw\%BUILD_OUTPUT_NAME%.mem32.hex" (
    copy /y "%PROJECT_DIR%\build\sw\%BUILD_OUTPUT_NAME%.mem32.hex" "%XSIM_RUN_DIR%\build\sw\YH_rv_cpu_coremark_%TARGET%.mem32.hex" >nul
    if errorlevel 1 exit /b 1
)

pushd "%XSIM_RUN_DIR%"

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

call %XELAB% %TEST_TOP% -s %TEST_TOP%_snapshot
if errorlevel 1 goto :fail

call %XSIM% %TEST_TOP%_snapshot -testplusarg "max_cycles=%MAX_CYCLES%" -runall > "%LOG_FILE%" 2>&1
type "%LOG_FILE%"

findstr /c:"PASS: coremark profile completed" "%LOG_FILE%" >nul
if errorlevel 1 goto :fail

echo.
echo Profile summary:
findstr /c:"PROFILE: total_cycles=" "%LOG_FILE%"
findstr /c:"PROFILE: stall_decode_cycles=" "%LOG_FILE%"
findstr /c:"PROFILE: mem_wait_cycles=" "%LOG_FILE%"
findstr /c:"PROFILE: ex_trap_valid_cycles=" "%LOG_FILE%"
findstr /c:"PROFILE: ex_mret_valid_cycles=" "%LOG_FILE%"
findstr /c:"PROFILE: ex_branch_redirect_cycles=" "%LOG_FILE%"
findstr /c:"PROFILE: ex_beq_redirect_cycles=" "%LOG_FILE%"
findstr /c:"PROFILE: ex_bne_redirect_cycles=" "%LOG_FILE%"
findstr /c:"PROFILE: ex_blt_redirect_cycles=" "%LOG_FILE%"
findstr /c:"PROFILE: ex_bge_redirect_cycles=" "%LOG_FILE%"
findstr /c:"PROFILE: ex_bltu_redirect_cycles=" "%LOG_FILE%"
findstr /c:"PROFILE: ex_bgeu_redirect_cycles=" "%LOG_FILE%"
findstr /c:"PROFILE: ex_jal_redirect_cycles=" "%LOG_FILE%"
findstr /c:"PROFILE: ex_jalr_redirect_cycles=" "%LOG_FILE%"
findstr /c:"PROFILE: ex_fetch_redirect_valid_cycles=" "%LOG_FILE%"
findstr /c:"PROFILE: fetch_queue_empty_cycles=" "%LOG_FILE%"
findstr /c:"PROFILE: fetch_redirect_reuse_cycles=" "%LOG_FILE%"
findstr /c:"PROFILE: fetch_redirect_reuse_miss_cycles=" "%LOG_FILE%"
findstr /c:"PROFILE: fetch_redirect_buf0_hit_cycles=" "%LOG_FILE%"
findstr /c:"PROFILE: fetch_redirect_buf1_hit_cycles=" "%LOG_FILE%"

echo.
echo PASS: coremark profile completed.
set RUN_STATUS=0
goto :done

:fail
set RUN_STATUS=%ERRORLEVEL%

:done
popd
exit /b %RUN_STATUS%
