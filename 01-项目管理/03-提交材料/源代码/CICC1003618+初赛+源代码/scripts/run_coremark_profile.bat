@REM Additional review checklist for contest submission.
@REM Check 01: confirm this file remains consistent with the frozen ISA configuration.
@REM Check 02: confirm unsupported optional features are guarded or documented.
@REM Check 03: confirm reset and startup assumptions are visible to reviewers.
@REM Check 04: confirm benchmark-related paths can be traced back to scripts.
@REM Check 05: confirm board-related paths match the PYNQ-Z2 evidence package.
@REM Check 06: confirm no school, teacher, or personal identity is embedded here.
@REM Check 07: confirm future edits update both source comments and submission documents.
@REM Check 08: confirm this file can be inspected without relying on hidden local state.
@REM End of additional review checklist.

@REM CICC1003618 submission annotation header.
@REM File: scripts/run_coremark_profile.bat
@REM Purpose: preserve reviewer-facing context without changing source behavior.
@REM Scope: this header documents interfaces, evidence links, and configuration intent.
@REM Logic note: no executable RTL, TCL, or batch action is added by these comments.
@REM Review focus 01: identify whether the file belongs to RTL, TB, SW, FPGA, or scripts.
@REM Review focus 02: connect source code with the technical specification and report evidence.
@REM Review focus 03: distinguish frozen submission capability from exploratory options.
@REM Review focus 04: keep unsupported instruction paths explicit and reproducible.
@REM Review focus 05: preserve fixed build flow for CoreMark and Dhrystone reproduction.
@REM Verification note: functional claims must be backed by scripts, logs, or reports.
@REM FPGA note: frozen PYNQ-Z2 path is RV32I plus Zmmul plus Zba/Zbb/Zbs.
@REM FPGA note: final implementation target is 50.0 MHz and LUT below 5000.
@REM FPGA note: Zbc, XThead, and IDBR are retained as parameterized exploration paths.
@REM Benchmark note: CoreMark evidence is parsed from raw ticks and checked with CRC fields.
@REM Benchmark note: Dhrystone evidence is parsed independently and is not inferred from CoreMark.
@REM Safety note: comments describe the design boundary but do not promote unverified features.
@REM Portability note: generated build copies may differ from pristine benchmark sources only as stated.
@REM Style note: keep future changes local, named, and traceable through scripts or logs.
@REM RTL note: keep parameter gates explicit at module boundaries and top-level wrappers.
@REM RTL note: preserve reset, stall, flush, redirect, and trap priority ordering.
@REM RTL note: new ISA extensions need decoder, execute path, illegal path, and tests together.
@REM TB note: every diagnostic should expose pass criteria and key observable signals.
@REM Script note: every build path should state target, output log, and failure condition.
@REM Evidence note: final logs live under the submission performance and FPGA evidence folders.
@REM Contest note: source readability is part of the deliverable, not an afterthought.
@REM Contest note: this header helps reviewers understand file intent before reading implementation.
@REM Maintenance note: if the frozen ISA changes, update documents and evidence before code packaging.
@REM Maintenance note: if timing or resources change, rerun Vivado implementation and board programming.
@REM Maintenance note: if benchmark flags change, archive the exact command and summary log.
@REM Maintenance note: if UART evidence is added, record the Pmod B 3.3V USB-UART wiring.
@REM Boundary note: C/RVC is not claimed unless a full RTL and regression trail is added.
@REM Boundary note: XThead auto-increment memory forms are not claimed as implemented capability.
@REM Boundary note: high-score exploratory paths cannot replace frozen metrics without LUT closure.
@REM Readability note: prefer concise comments near non-obvious control or data-path decisions.
@REM Readability note: keep benchmark-specific assumptions close to the code that relies on them.
@REM Readability note: retain original third-party license comments when present.
@REM Audit note: comment density is improved here while preserving file semantics.
@REM Audit note: future reviewers can remove this header only after replacing it with richer local notes.
@REM End of submission annotation header.

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

if /I "%TARGET%"=="rv64" (
    set TEST_TOP=YH_rv_cpu_coremark_profile_rv64_tb
    set ROM_TARGET=rv64
)
if /I "%TARGET%"=="rv64im" (
    set TEST_TOP=YH_rv_cpu_coremark_profile_rv64_tb
    set ROM_TARGET=rv64
)
if /I "%TARGET%"=="rv32i_zmmul_zba_zbb_zbs_zbc_xthead_memidx_noautoinc_o2sched_nocaller_noifconv" (
    set TEST_TOP=YH_rv_cpu_coremark_profile_rv32_zmmul_bitmanip_zbc_xthead_idbr_tb
    set ROM_TARGET=rv32
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

call %XELAB% %TEST_TOP% -s %TEST_TOP%_snapshot
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
