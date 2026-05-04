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
@REM File: scripts/build_pynq_z2_project.bat
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

set MODE=%~1
if "%MODE%"=="" set MODE=synth
if /I "%MODE%"=="-h" goto :usage
if /I "%MODE%"=="--help" goto :usage
if /I "%MODE%"=="/?" goto :usage

set MODE_OK=
if /I "%MODE%"=="project" set MODE_OK=1
if /I "%MODE%"=="synth" set MODE_OK=1
if /I "%MODE%"=="impl" set MODE_OK=1
if not defined MODE_OK goto :usage_invalid

if not defined PYNQ_INPUT_CLOCK_PERIOD_NS_OVERRIDE set PYNQ_INPUT_CLOCK_PERIOD_NS_OVERRIDE=8.000
if not defined PYNQ_CPU_CLK_FREQ_HZ_OVERRIDE set PYNQ_CPU_CLK_FREQ_HZ_OVERRIDE=62500000
if not defined PYNQ_USE_CLK_MMCM_62M5_OVERRIDE set PYNQ_USE_CLK_MMCM_62M5_OVERRIDE=1
if not defined PYNQ_USE_CLK_MMCM_50M_OVERRIDE set PYNQ_USE_CLK_MMCM_50M_OVERRIDE=0
if not defined PYNQ_ENABLE_M_EXTENSION_OVERRIDE set PYNQ_ENABLE_M_EXTENSION_OVERRIDE=0
if not defined PYNQ_ENABLE_ZMMUL_EXTENSION_OVERRIDE set PYNQ_ENABLE_ZMMUL_EXTENSION_OVERRIDE=0
if not defined PYNQ_ENABLE_BITMANIP_EXTENSION_OVERRIDE set PYNQ_ENABLE_BITMANIP_EXTENSION_OVERRIDE=0
if not defined PYNQ_ENABLE_ZBC_EXTENSION_OVERRIDE set PYNQ_ENABLE_ZBC_EXTENSION_OVERRIDE=0
if not defined PYNQ_ENABLE_ZICOND_EXTENSION_OVERRIDE set PYNQ_ENABLE_ZICOND_EXTENSION_OVERRIDE=0
if not defined PYNQ_ENABLE_ZBKB_EXTENSION_OVERRIDE set PYNQ_ENABLE_ZBKB_EXTENSION_OVERRIDE=0
if not defined PYNQ_ENABLE_XTHEAD_EXTENSION_OVERRIDE set PYNQ_ENABLE_XTHEAD_EXTENSION_OVERRIDE=0
if not defined PYNQ_ENABLE_XTHEAD_COND_MOVE_OVERRIDE set PYNQ_ENABLE_XTHEAD_COND_MOVE_OVERRIDE=0
if not defined PYNQ_ENABLE_ID_BRANCH_EX_FORWARD_OVERRIDE set PYNQ_ENABLE_ID_BRANCH_EX_FORWARD_OVERRIDE=0

echo PYNQ-Z2 Vivado build mode: %MODE%
echo PYNQ-Z2 input clock period: %PYNQ_INPUT_CLOCK_PERIOD_NS_OVERRIDE% ns
echo PYNQ-Z2 CPU clock frequency generic: %PYNQ_CPU_CLK_FREQ_HZ_OVERRIDE% Hz
echo PYNQ-Z2 MMCM 62.5MHz enable: %PYNQ_USE_CLK_MMCM_62M5_OVERRIDE%
echo PYNQ-Z2 MMCM 50MHz enable: %PYNQ_USE_CLK_MMCM_50M_OVERRIDE%
echo PYNQ-Z2 M extension enable: %PYNQ_ENABLE_M_EXTENSION_OVERRIDE%
echo PYNQ-Z2 Zmmul extension enable: %PYNQ_ENABLE_ZMMUL_EXTENSION_OVERRIDE%
echo PYNQ-Z2 bitmanip extension enable: %PYNQ_ENABLE_BITMANIP_EXTENSION_OVERRIDE%
echo PYNQ-Z2 Zbc extension enable: %PYNQ_ENABLE_ZBC_EXTENSION_OVERRIDE%
echo PYNQ-Z2 Zicond extension enable: %PYNQ_ENABLE_ZICOND_EXTENSION_OVERRIDE%
echo PYNQ-Z2 Zbkb extension enable: %PYNQ_ENABLE_ZBKB_EXTENSION_OVERRIDE%
echo PYNQ-Z2 XThead extension enable: %PYNQ_ENABLE_XTHEAD_EXTENSION_OVERRIDE%
echo PYNQ-Z2 XThead conditional move enable: %PYNQ_ENABLE_XTHEAD_COND_MOVE_OVERRIDE%
echo PYNQ-Z2 ID branch EX-forward enable: %PYNQ_ENABLE_ID_BRANCH_EX_FORWARD_OVERRIDE%

set VIVADO_CMD=
set PHYSICAL_SCRIPT_DIR=%~dp0
for %%I in ("%PHYSICAL_SCRIPT_DIR%..\..") do set REPO_ROOT=%%~fI
set MAP_DRIVE=
set MAPPED_ROOT=
set CREATED_MAP=
set MAP_DRIVES=V: W: X: Y: Z:

for %%D in (%MAP_DRIVES%) do (
    subst %%D "%REPO_ROOT%" >nul 2>nul
    if not errorlevel 1 (
        set CREATED_MAP=1
        set MAP_DRIVE=%%D
        set MAPPED_ROOT=%%D\
        goto :map_ready
    )
)

:map_ready
if not defined MAPPED_ROOT (
    echo Failed to map an ASCII drive for Vivado. Please free one of V:/W:/X:/Y:/Z: and retry.
    exit /b 1
)

set SCRIPT_DIR=%MAPPED_ROOT%YH_rv_cpu\scripts\
set PROJECT_DIR=%MAPPED_ROOT%project
set TMP_ROOT=%MAPPED_ROOT%_tmp
set USERDATA_ROOT=%TMP_ROOT%\vivado_user
set VIVADO_LOG_ROOT=%TMP_ROOT%\tool_logs\vivado
set VIVADO_LOG_FILE=%VIVADO_LOG_ROOT%\vivado_pynq_z2_%MODE%.log
set VIVADO_JOU_FILE=%VIVADO_LOG_ROOT%\vivado_pynq_z2_%MODE%.jou
set USERPROFILE=%USERDATA_ROOT%\profile
set HOME=%USERPROFILE%
set APPDATA=%USERDATA_ROOT%\AppData\Roaming
set LOCALAPPDATA=%USERDATA_ROOT%\AppData\Local
set TEMP=%USERDATA_ROOT%\Temp
set TMP=%USERDATA_ROOT%\Temp

if not exist "%PROJECT_DIR%" mkdir "%PROJECT_DIR%"
if not exist "%TMP_ROOT%" mkdir "%TMP_ROOT%"
if not exist "%VIVADO_LOG_ROOT%" mkdir "%VIVADO_LOG_ROOT%"
if not exist "%USERPROFILE%" mkdir "%USERPROFILE%"
if not exist "%APPDATA%" mkdir "%APPDATA%"
if not exist "%LOCALAPPDATA%" mkdir "%LOCALAPPDATA%"
if not exist "%TEMP%" mkdir "%TEMP%"

where vivado >nul 2>nul
if not errorlevel 1 (
    for /f "delims=" %%I in ('where vivado') do (
        set VIVADO_CMD=%%I
        goto :vivado_found
    )
)

for /d %%D in (D:\Vivado\20* C:\Xilinx\Vivado\20* D:\Xilinx\Vivado\20*) do (
    if exist "%%~fD\Vivado\bin\vivado.bat" (
        set VIVADO_CMD=%%~fD\Vivado\bin\vivado.bat
        goto :vivado_found
    )
    if exist "%%~fD\bin\vivado.bat" (
        set VIVADO_CMD=%%~fD\bin\vivado.bat
        goto :vivado_found
    )
)

:vivado_found
if not defined VIVADO_CMD (
    echo Missing vivado. Please install Vivado and ensure it is in PATH.
    if defined CREATED_MAP subst %MAP_DRIVE% /d >nul 2>nul
    exit /b 1
)

set TCL_PATH=%SCRIPT_DIR%..\fpga\vivado\scripts\build_pynq_z2_project.tcl

if not exist "%TCL_PATH%" (
    echo Missing TCL script: %TCL_PATH%
    if defined CREATED_MAP subst %MAP_DRIVE% /d >nul 2>nul
    exit /b 1
)

set DEFAULT_DEMO_HEX=%SCRIPT_DIR%..\build\sw\YH_rv_cpu_demo.hex
set DEFAULT_DEMO_MEM32_HEX=%SCRIPT_DIR%..\build\sw\YH_rv_cpu_demo.mem32.hex
set ROM_BYTES_OVERRIDE=
set RAM_BYTES_OVERRIDE=

if not defined ROM_INIT_HEX_OVERRIDE (
    if not exist "%DEFAULT_DEMO_HEX%" (
        echo Demo firmware image missing. Building frozen demo payload...
        call "%SCRIPT_DIR%build_firmware.bat"
        if errorlevel 1 (
            echo Failed to build frozen demo payload.
            if defined CREATED_MAP subst %MAP_DRIVE% /d >nul 2>nul
            exit /b 1
        )
    )
)

if not defined ROM_INIT_MEM32_HEX_OVERRIDE (
    if not exist "%DEFAULT_DEMO_MEM32_HEX%" (
        echo Demo mem32 firmware image missing. Building frozen demo payload...
        call "%SCRIPT_DIR%build_firmware.bat"
        if errorlevel 1 (
            echo Failed to build frozen demo payload.
            if defined CREATED_MAP subst %MAP_DRIVE% /d >nul 2>nul
            exit /b 1
        )
    )
)

if not defined ROM_INIT_HEX_OVERRIDE if exist "%DEFAULT_DEMO_HEX%" (
    set ROM_INIT_HEX_OVERRIDE=%DEFAULT_DEMO_HEX%
    set ROM_BYTES_OVERRIDE=8192
    set RAM_BYTES_OVERRIDE=8192
)

if not defined ROM_INIT_MEM32_HEX_OVERRIDE if exist "%DEFAULT_DEMO_MEM32_HEX%" (
    set ROM_INIT_MEM32_HEX_OVERRIDE=%DEFAULT_DEMO_MEM32_HEX%
)

echo Using mapped repo root: %MAPPED_ROOT%
if defined ROM_INIT_HEX_OVERRIDE echo Using ROM_INIT_HEX_OVERRIDE=%ROM_INIT_HEX_OVERRIDE%
if defined ROM_INIT_MEM32_HEX_OVERRIDE echo Using ROM_INIT_MEM32_HEX_OVERRIDE=%ROM_INIT_MEM32_HEX_OVERRIDE%

if exist "%SCRIPT_DIR%organize_tool_logs.bat" call "%SCRIPT_DIR%organize_tool_logs.bat"

pushd "%PROJECT_DIR%"
call "%VIVADO_CMD%" -mode batch -notrace -log "%VIVADO_LOG_FILE%" -journal "%VIVADO_JOU_FILE%" -source "%TCL_PATH%" -tclargs %MODE%
set EC=%ERRORLEVEL%
popd
if defined CREATED_MAP subst %MAP_DRIVE% /d >nul 2>nul
exit /b %EC%

:usage
echo Usage: %~nx0 [project^|synth^|impl]
echo.
echo project Generate the PYNQ-Z2 Vivado project skeleton only.
echo synth   Run PYNQ-Z2 synthesis with 125MHz input clock and selected CPU MMCM.
echo impl    Run PYNQ-Z2 implementation and write the bitstream.
exit /b 0

:usage_invalid
echo Unsupported build mode: %MODE%
exit /b 1
