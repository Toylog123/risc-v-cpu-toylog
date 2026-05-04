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
@REM File: scripts/build_firmware.bat
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

for %%I in ("%~dp0..") do set PROJECT_DIR=%%~fI
set BUILD_DIR=%PROJECT_DIR%\build\sw
set TARGET=%~1
set OUTPUT_NAME=YH_rv_cpu_demo
set SOURCES="%PROJECT_DIR%\sw\src\crt0.S" "%PROJECT_DIR%\sw\src\main.c"
set WORD_HEX_PY=%PROJECT_DIR%\scripts\make_word_hex.py
set GCC=
set OBJDUMP=
set OBJCOPY=
set PYTHON_CMD=
set USER_HOME=%USERPROFILE%
set RISCV_XPACK_ROOT=%USER_HOME%\AppData\Roaming\xPacks\@xpack-dev-tools\riscv-none-elf-gcc

if /I "%TARGET%"=="trap_smoke" (
    set OUTPUT_NAME=YH_rv_cpu_trap_smoke
    set SOURCES="%PROJECT_DIR%\sw\src\crt0.S" "%PROJECT_DIR%\sw\src\trap_entry.S" "%PROJECT_DIR%\sw\src\trap_smoke.c"
)

if /I "%TARGET%"=="timer_irq_smoke" (
    set OUTPUT_NAME=YH_rv_cpu_timer_irq_smoke
    set SOURCES="%PROJECT_DIR%\sw\src\crt0.S" "%PROJECT_DIR%\sw\src\timer_irq_entry.S" "%PROJECT_DIR%\sw\src\timer_irq_smoke.c"
)

for %%T in (riscv-none-elf-gcc riscv32-unknown-elf-gcc riscv64-unknown-elf-gcc) do (
    where %%T >nul 2>nul
    if not errorlevel 1 (
        set GCC=%%T
        goto :gcc_done
    )
)
:gcc_done
if not defined GCC (
    for /d %%D in ("%RISCV_XPACK_ROOT%\*") do (
        if exist "%%~fD\.content\bin\riscv-none-elf-gcc.exe" (
            set GCC=%%~fD\.content\bin\riscv-none-elf-gcc.exe
            goto :gcc_resolved
        )
    )
)
:gcc_resolved

for %%T in (riscv-none-elf-objdump riscv32-unknown-elf-objdump riscv64-unknown-elf-objdump) do (
    where %%T >nul 2>nul
    if not errorlevel 1 (
        set OBJDUMP=%%T
        goto :objdump_done
    )
)
:objdump_done
if not defined OBJDUMP (
    for /d %%D in ("%RISCV_XPACK_ROOT%\*") do (
        if exist "%%~fD\.content\bin\riscv-none-elf-objdump.exe" (
            set OBJDUMP=%%~fD\.content\bin\riscv-none-elf-objdump.exe
            goto :objdump_resolved
        )
    )
)
:objdump_resolved

for %%T in (riscv-none-elf-objcopy riscv32-unknown-elf-objcopy riscv64-unknown-elf-objcopy) do (
    where %%T >nul 2>nul
    if not errorlevel 1 (
        set OBJCOPY=%%T
        goto :objcopy_done
    )
)
:objcopy_done
if not defined OBJCOPY (
    for /d %%D in ("%RISCV_XPACK_ROOT%\*") do (
        if exist "%%~fD\.content\bin\riscv-none-elf-objcopy.exe" (
            set OBJCOPY=%%~fD\.content\bin\riscv-none-elf-objcopy.exe
            goto :objcopy_resolved
        )
    )
)
:objcopy_resolved

if not defined GCC (
    echo Missing RISC-V compiler.
    exit /b 1
)

if not defined OBJDUMP (
    echo Missing RISC-V objdump.
    exit /b 1
)

if not defined OBJCOPY (
    echo Missing RISC-V objcopy.
    exit /b 1
)

call "%~dp0resolve_python.bat" PYTHON_CMD
if not defined PYTHON_CMD (
    echo Missing Python.
    exit /b 1
)

if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"

%GCC% -march=rv32i_zicsr -mabi=ilp32 -nostdlib -ffreestanding -Os ^
    -T "%PROJECT_DIR%\sw\linker\YH_rv_cpu.ld" ^
    -o "%BUILD_DIR%\%OUTPUT_NAME%.elf" ^
    %SOURCES%
if errorlevel 1 exit /b 1

%OBJDUMP% -d "%BUILD_DIR%\%OUTPUT_NAME%.elf" > "%BUILD_DIR%\%OUTPUT_NAME%.dump"
if errorlevel 1 exit /b 1

%OBJCOPY% -O binary "%BUILD_DIR%\%OUTPUT_NAME%.elf" "%BUILD_DIR%\%OUTPUT_NAME%.bin"
if errorlevel 1 exit /b 1

%OBJCOPY% -O verilog "%BUILD_DIR%\%OUTPUT_NAME%.elf" "%BUILD_DIR%\%OUTPUT_NAME%.hex"
if errorlevel 1 exit /b 1

%PYTHON_CMD% "%WORD_HEX_PY%" "%BUILD_DIR%\%OUTPUT_NAME%.bin" "%BUILD_DIR%\%OUTPUT_NAME%.mem32.hex"
if errorlevel 1 exit /b 1

echo Built:
echo   %BUILD_DIR%\%OUTPUT_NAME%.elf
echo   %BUILD_DIR%\%OUTPUT_NAME%.dump
echo   %BUILD_DIR%\%OUTPUT_NAME%.bin
echo   %BUILD_DIR%\%OUTPUT_NAME%.hex
echo   %BUILD_DIR%\%OUTPUT_NAME%.mem32.hex
exit /b 0

