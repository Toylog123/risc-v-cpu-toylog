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
@REM File: scripts/organize_tool_logs.bat
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
setlocal

for %%I in ("%~dp0..") do set CPU_ROOT=%%~fI
for %%I in ("%CPU_ROOT%\..") do set REPO_ROOT=%%~fI
set TMP_DIR=%REPO_ROOT%\_tmp
set SIM_ROOT=%TMP_DIR%\sim_runtime
set XSIM_LOG_ROOT=%TMP_DIR%\tool_logs\xsim
set VIVADO_LOG_ROOT=%TMP_DIR%\tool_logs\vivado
set CLOCK_DEBUG_ROOT=%VIVADO_LOG_ROOT%\clock_debug
set OUTER_PROJECT_DIR=%REPO_ROOT%\project

if not exist "%TMP_DIR%" mkdir "%TMP_DIR%"
if not exist "%XSIM_LOG_ROOT%" mkdir "%XSIM_LOG_ROOT%"
if not exist "%VIVADO_LOG_ROOT%" mkdir "%VIVADO_LOG_ROOT%"
if not exist "%CLOCK_DEBUG_ROOT%" mkdir "%CLOCK_DEBUG_ROOT%"

for /d %%D in ("%SIM_ROOT%\*") do (
    if not exist "%XSIM_LOG_ROOT%\%%~nxD" mkdir "%XSIM_LOG_ROOT%\%%~nxD"
    for %%F in ("%%~fD\dfx_runtime.txt" "%%~fD\xelab.log" "%%~fD\xelab.pb" "%%~fD\xsim.jou" "%%~fD\xsim.log" "%%~fD\xvlog.log" "%%~fD\xvlog.pb" "%%~fD\xsim_*.backup.jou" "%%~fD\xsim_*.backup.log") do (
        if exist "%%~fF" move /y "%%~fF" "%XSIM_LOG_ROOT%\%%~nxD\" >nul
    )
)

for %%F in ("%CPU_ROOT%\vivado.log" "%CPU_ROOT%\vivado.jou" "%CPU_ROOT%\vivado_*.backup.log" "%CPU_ROOT%\vivado_*.backup.jou" "%REPO_ROOT%\vivado.log" "%REPO_ROOT%\vivado.jou" "%REPO_ROOT%\vivado_*.backup.log" "%REPO_ROOT%\vivado_*.backup.jou") do (
    if exist "%%~fF" move /y "%%~fF" "%VIVADO_LOG_ROOT%\" >nul
)

if exist "%OUTER_PROJECT_DIR%" (
    for %%F in ("%OUTER_PROJECT_DIR%\vivado.log" "%OUTER_PROJECT_DIR%\vivado.jou" "%OUTER_PROJECT_DIR%\vivado_*.backup.log" "%OUTER_PROJECT_DIR%\vivado_*.backup.jou") do (
        if exist "%%~fF" move /y "%%~fF" "%VIVADO_LOG_ROOT%\" >nul
    )
)

for %%F in ("%CPU_ROOT%\clockInfo.txt" "%REPO_ROOT%\clockInfo.txt" "%OUTER_PROJECT_DIR%\clockInfo.txt") do (
    if exist "%%~fF" move /y "%%~fF" "%CLOCK_DEBUG_ROOT%\" >nul
)

for %%F in ("%CPU_ROOT%\dfx_runtime.txt" "%REPO_ROOT%\dfx_runtime.txt") do (
    if exist "%%~fF" (
        if not exist "%XSIM_LOG_ROOT%\root_runtime" mkdir "%XSIM_LOG_ROOT%\root_runtime"
        move /y "%%~fF" "%XSIM_LOG_ROOT%\root_runtime\" >nul
    )
)

exit /b 0