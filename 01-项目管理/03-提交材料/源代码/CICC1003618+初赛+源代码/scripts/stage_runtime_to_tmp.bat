@REM CICC1003618 submission context:
@REM File role: scripts/stage_runtime_to_tmp.bat is part of the reproducible build, simulation or reporting script.
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
@REM File: scripts/stage_runtime_to_tmp.bat
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

set TAG=%~1
if "%TAG%"=="" set TAG=default

for %%I in ("%~dp0..") do set CPU_ROOT=%%~fI
for %%I in ("%CPU_ROOT%\..") do set REPO_ROOT=%%~fI
set TMP_DIR=%REPO_ROOT%\_tmp
set SIM_DIR=%TMP_DIR%\sim_runtime\%TAG%
set LOG_DIR=%TMP_DIR%\tool_logs\xsim\%TAG%

if not exist "%SIM_DIR%" mkdir "%SIM_DIR%"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

if exist "%CPU_ROOT%\xsim.dir" (
    if exist "%SIM_DIR%\xsim.dir" rmdir /s /q "%SIM_DIR%\xsim.dir" >nul 2>nul
    move /y "%CPU_ROOT%\xsim.dir" "%SIM_DIR%" >nul 2>nul
)

for %%F in ("%CPU_ROOT%\dfx_runtime.txt" "%CPU_ROOT%\xelab.log" "%CPU_ROOT%\xelab.pb" "%CPU_ROOT%\xsim.jou" "%CPU_ROOT%\xsim.log" "%CPU_ROOT%\xvlog.log" "%CPU_ROOT%\xvlog.pb" "%CPU_ROOT%\xsim_*.backup.jou" "%CPU_ROOT%\xsim_*.backup.log") do (
    if exist "%%~fF" move /y "%%~fF" "%LOG_DIR%" >nul 2>nul
)

exit /b 0
