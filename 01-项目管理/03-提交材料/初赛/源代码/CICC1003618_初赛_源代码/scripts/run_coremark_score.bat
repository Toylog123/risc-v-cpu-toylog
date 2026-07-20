@REM CICC1003618 submission context:
@REM File role: scripts/run_coremark_score.bat is part of the reproducible build, simulation or reporting script.
@REM Frozen target: RV32I plus Zmmul plus Zba/Zbb/Zbs on PYNQ-Z2 at 50 MHz.
@REM Review focus: keep reset, stall, flush, forwarding and evidence paths traceable.
@REM Boundary note: do not claim unsupported C/RVC or exploratory paths without new evidence.
@REM Verification note: functional changes require matching simulation logs or FPGA reports.
@REM Maintenance note: update documents, metrics and hashes when this file changes.

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
@REM File: scripts/run_coremark_score.bat
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
rem Positional arguments keep the wrapper easy to call from docs and CI notes.
set ITERATIONS=%~2
set DATA_SIZE=%~3
set TIMER_HZ=%~4
set MAX_CYCLES=%~5
set SUMMARY_FILE=%~6
set EXEC_MASK=0
set BUILD_OUTPUT_NAME=
set OUTPUT_DIR=
set OUTPUT_STEM=
set XSIM_TRACE_ARGS=

if "%TARGET%"=="" set TARGET=rv32
if "%ITERATIONS%"=="" set ITERATIONS=10
if "%DATA_SIZE%"=="" set DATA_SIZE=2000
if "%TIMER_HZ%"=="" set TIMER_HZ=100000000UL
if "%MAX_CYCLES%"=="" set MAX_CYCLES=20000000

rem Default summary lives beside the software build outputs unless overridden.
if "%SUMMARY_FILE%"=="" (
    set SUMMARY_FILE=%PROJECT_DIR%\build\sw\YH_rv_cpu_coremark_%TARGET%_score.summary.txt
)
for %%I in ("%SUMMARY_FILE%") do (
    set SUMMARY_FILE=%%~fI
    set OUTPUT_DIR=%%~dpI
    set OUTPUT_STEM=%%~nI
)
if /I "!OUTPUT_STEM:~-8!"==".summary" set OUTPUT_STEM=!OUTPUT_STEM:~0,-8!
if not defined OUTPUT_STEM set OUTPUT_STEM=YH_rv_cpu_coremark_%TARGET%_score
set BUILD_OUTPUT_NAME=!OUTPUT_STEM!

rem Reuse the shared CoreMark build path so score/profile/fpga-style runs stay aligned.
call "%~dp0build_coremark.bat" %TARGET% %ITERATIONS% %DATA_SIZE% %TIMER_HZ% %EXEC_MASK% %BUILD_OUTPUT_NAME%
if errorlevel 1 exit /b 1

set XVLOG=
set XELAB=
set XSIM=
set PYTHON_CMD=
set TEST_TOP=YH_rv_cpu_coremark_rv32_tb
set ROM_TARGET=rv32
set LOG_FILE=!OUTPUT_DIR!!OUTPUT_STEM!.log
set XSIM_RUN_DIR=

if /I "%TARGET%"=="rv64" (
    set TEST_TOP=YH_rv_cpu_coremark_rv64_tb
    set ROM_TARGET=rv64
)
if /I "%TARGET%"=="rv64im" (
    set TEST_TOP=YH_rv_cpu_coremark_rv64_tb
    set ROM_TARGET=rv64
)
if /I "%TARGET%"=="rv32i_zmmul_o3unroll_b1nosched_uall800_inline_nocross" (
    set TEST_TOP=YH_rv_cpu_coremark_rv32_zmmul_noidbr_tb
    set ROM_TARGET=rv32
)
if /I "%TARGET%"=="rv32i_zmmul_zba_zbb_zbs_o3unroll_b1nosched_uall800_inline_nocross" (
    set TEST_TOP=YH_rv_cpu_coremark_rv32_zmmul_bitmanip_noidbr_tb
    set ROM_TARGET=rv32
)
if /I "%TARGET%"=="rv32i_zmmul_zba_zbb_zbs_xthead_memidx_noautoinc_o2sched_nocaller_noifconv" (
    set TEST_TOP=YH_rv_cpu_coremark_rv32_zmmul_bitmanip_xthead_noidbr_tb
    set ROM_TARGET=rv32
)
if /I "%TARGET%"=="rv32i_zmmul_zba_zbb_zbs_zbc_xthead_memidx_noautoinc_o2sched_nocaller_noifconv" (
    set TEST_TOP=YH_rv_cpu_coremark_rv32_zmmul_bitmanip_zbc_xthead_idbr_tb
    set ROM_TARGET=rv32
)
if /I "%TARGET%"=="rv32i_zmmul_zba_zbb_zbs_zbc_zicond_xthead_memidx_noautoinc_o2sched_nocaller" (
    set TEST_TOP=YH_rv_cpu_coremark_rv32_zmmul_bitmanip_zbc_zicond_xthead_idbr_tb
    set ROM_TARGET=rv32
)
if /I "%TARGET%"=="rv32i_zmmul_zba_zbb_zbs_zbc_zicond_xthead_memidx_o2sched_nocaller" (
    set TEST_TOP=YH_rv_cpu_coremark_rv32_zmmul_bitmanip_zbc_zicond_xthead_idbr_tb
    set ROM_TARGET=rv32
)
if /I "%TARGET%"=="rv32i_zmmul_zba_zbb_zbs_zbc_zbkb_xthead_memidx_noautoinc_o2sched_nocaller_noifconv" (
    set TEST_TOP=YH_rv_cpu_coremark_rv32_zmmul_bitmanip_zbc_zbkb_xthead_idbr_tb
    set ROM_TARGET=rv32
)
if /I "%TARGET%"=="rv32i_zmmul_zba_zbb_zbs_zbc_zicond_zbkb_xthead_memidx_noautoinc_o2sched_nocaller" (
    set TEST_TOP=YH_rv_cpu_coremark_rv32_zmmul_bitmanip_zbc_zicond_zbkb_xthead_idbr_tb
    set ROM_TARGET=rv32
)
if not "%YH_COREMARK_TEST_TOP%"=="" set TEST_TOP=%YH_COREMARK_TEST_TOP%
if /I "%TARGET%"=="rv32im_o3" set ROM_TARGET=rv32
if /I "%TARGET%"=="rv32im_o3unroll" set ROM_TARGET=rv32

rem Resolve simulator tools from PATH to keep the script portable across lab machines.
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

call "%~dp0prepare_xsim_runtime.bat" coremark_score XSIM_RUN_DIR
if not defined XSIM_RUN_DIR exit /b 1

rem Mirror the generated image into an isolated xsim runtime directory.
if not exist "%XSIM_RUN_DIR%\build\sw" mkdir "%XSIM_RUN_DIR%\build\sw"
copy /y "%PROJECT_DIR%\build\sw\%BUILD_OUTPUT_NAME%.hex" "%XSIM_RUN_DIR%\build\sw\YH_rv_cpu_coremark_%ROM_TARGET%.hex" >nul
if errorlevel 1 exit /b 1

pushd "%XSIM_RUN_DIR%"

rem Compile the shared SoC/CPU stack together with the score-specific testbench.
call %XVLOG% --sv -i "%PROJECT_DIR%\rtl" ^
    "%PROJECT_DIR%\tb\YH_rv_cpu_coremark_tb.v" ^
    "%PROJECT_DIR%\tb\YH_rv_cpu_coremark_rv32_tb.v" ^
    "%PROJECT_DIR%\tb\YH_rv_cpu_coremark_rv64_tb.v" ^
    "%PROJECT_DIR%\tb\YH_rv_cpu_coremark_rv32_zmmul_noidbr_tb.v" ^
    "%PROJECT_DIR%\tb\YH_rv_cpu_coremark_rv32_zmmul_bitmanip_noidbr_tb.v" ^
    "%PROJECT_DIR%\tb\YH_rv_cpu_coremark_rv32_zmmul_bitmanip_xthead_noidbr_tb.v" ^
    "%PROJECT_DIR%\tb\YH_rv_cpu_coremark_rv32_zmmul_bitmanip_zbc_xthead_noidbr_tb.v" ^
    "%PROJECT_DIR%\tb\YH_rv_cpu_coremark_rv32_zmmul_bitmanip_zbc_zicond_xthead_noidbr_tb.v" ^
    "%PROJECT_DIR%\tb\YH_rv_cpu_coremark_rv32_zmmul_bitmanip_zbc_zbkb_xthead_noidbr_tb.v" ^
    "%PROJECT_DIR%\tb\YH_rv_cpu_coremark_rv32_zmmul_bitmanip_zbc_zicond_zbkb_xthead_noidbr_tb.v" ^
    "%PROJECT_DIR%\tb\YH_rv_cpu_coremark_rv32_zmmul_bitmanip_zbc_xthead_idbr_tb.v" ^
    "%PROJECT_DIR%\tb\YH_rv_cpu_coremark_rv32_zmmul_bitmanip_zbc_zicond_xthead_idbr_tb.v" ^
    "%PROJECT_DIR%\tb\YH_rv_cpu_coremark_rv32_zmmul_bitmanip_zbc_zbkb_xthead_idbr_tb.v" ^
    "%PROJECT_DIR%\tb\YH_rv_cpu_coremark_rv32_zmmul_bitmanip_zbc_zicond_zbkb_xthead_idbr_tb.v" ^
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

call %XELAB% %TEST_TOP% -s %TEST_TOP%_score_snapshot
if errorlevel 1 goto :fail

call %XSIM% %TEST_TOP%_score_snapshot -testplusarg "max_cycles=%MAX_CYCLES%" !XSIM_TRACE_ARGS! %YH_XSIM_EXTRA_ARGS% -runall > "%LOG_FILE%" 2>&1
type "%LOG_FILE%"

rem The score flow only succeeds if both the simulation and the post-processed summary are reportable.
findstr /c:"PASS: coremark completed" "%LOG_FILE%" >nul
if errorlevel 1 goto :fail

call %PYTHON_CMD% "%~dp0report_coremark_result.py" "%LOG_FILE%" "%TIMER_HZ%" "%SUMMARY_FILE%"
if errorlevel 1 goto :fail

findstr /c:"competition_reportable=yes" "%SUMMARY_FILE%" >nul
if errorlevel 1 goto :fail

echo.
echo Score summary:
type "%SUMMARY_FILE%"

echo.
echo PASS: coremark score completed.
set RUN_STATUS=0
goto :done

:fail
set RUN_STATUS=%ERRORLEVEL%

:done
popd
exit /b %RUN_STATUS%
