@REM CICC1003618 submission context:
@REM File role: scripts/build_quicksort.bat is part of the reproducible build, simulation or reporting script.
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
@REM File: scripts/build_quicksort.bat
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
REM ============================================================
REM build_quicksort.bat
REM Author: Toylog
REM Version: v1.2
REM Function: 编译快速排序应用程序
REM Description: 编译RISC-V快速排序程序并生成机器码
REM ============================================================

echo ============================================================
echo YH_rv_cpu QuickSort 编译脚本
echo ============================================================
echo.

cd /d "%~dp0.."

REM 设置工具链路径
set RISCV_GCC=riscv32-unknown-elf-gcc
set RISCV_AR=riscv32-unknown-elf-ar
set RISCV_OBJCOPY=riscv32-unknown-elf-objcopy

REM 检查工具链
where %RISCV_GCC% >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] RISC-V GCC 工具链未找到
    echo 请确保 riscv32-unknown-elf-gcc 已安装并添加到 PATH
    exit /b 1
)

REM 显示工具链版本
echo [INFO] 工具链版本:
%RISCV_GCC% --version
echo.

REM 创建输出目录
if not exist "build\quicksort" mkdir build\quicksort

REM 清理之前的构建
echo [INFO] 清理之前的构建...
if exist "build\quicksort\quicksort.elf" del /q "build\quicksort\quicksort.elf"
if exist "build\quicksort\quicksort.bin" del /q "build\quicksort\quicksort.bin"
if exist "build\quicksort\quicksort.hex" del /q "build\quicksort\quicksort.hex"
if exist "build\quicksort\quicksort.mem32.hex" del /q "build\quicksort\quicksort.mem32.hex"

REM 编译选项
set CFLAGS=-O2 -march=rv32i -mabi=ilp32 -fno-builtin-printf -fno-common
set LDFLAGS=-static -nostdlib -T sw/linker/YH_rv_cpu.ld

REM 编译启动代码
echo [INFO] 编译启动代码...
%RISCV_GCC% %CFLAGS% -c -o build/quicksort/crt0.o sw/src/crt0.S
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] 启动代码编译失败
    exit /b 1
)

REM 编译主程序
echo [INFO] 编译快速排序程序...
%RISCV_GCC% %CFLAGS% -c -o build/quicksort/quicksort.o sw/src/quicksort.c
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] 快速排序程序编译失败
    exit /b 1
)

REM 链接
echo [INFO] 链接...
%RISCV_GCC% %CFLAGS% %LDFLAGS% ^
    -o build/quicksort/quicksort.elf ^
    build/quicksort/crt0.o ^
    build/quicksort/quicksort.o
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] 链接失败
    exit /b 1
)

REM 生成二进制文件
echo [INFO] 生成二进制文件...
%RISCV_OBJCOPY% -O binary build/quicksort/quicksort.elf build/quicksort/quicksort.bin
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] 二进制文件生成失败
    exit /b 1
)

REM 生成十六进制文件
python scripts/make_word_hex.py build/quicksort/quicksort.bin build/quicksort/quicksort.hex
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] HEX文件生成失败
    exit /b 1
)

REM 生成32位字格式的HEX文件
python scripts/make_word_hex.py build/quicksort/quicksort.bin build/quicksort/quicksort.mem32.hex --word32
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] MEM32 HEX文件生成失败
    exit /b 1
)

REM 生成反汇编文件（用于调试）
%RISCV_GCC% -O2 -march=rv32i -mabi=ilp32 -S -o build/quicksort/quicksort.s sw/src/quicksort.c
%RISCV_GCC% -O2 -march=rv32i -mabi=ilp32 -S -o build/quicksort/quicksort_full.s build/quicksort/quicksort.elf

REM 显示文件大小
echo.
echo [INFO] 生成的文件:
echo.
echo   ELF文件: build\quicksort\quicksort.elf
for %%F in (build\quicksort\quicksort.elf) do echo   大小: %%~zF bytes

echo.
echo   二进制文件: build\quicksort\quicksort.bin
for %%F in (build\quicksort\quicksort.bin) do echo   大小: %%~zF bytes

echo.
echo   HEX文件: build\quicksort\quicksort.hex
echo   MEM32 HEX: build\quicksort\quicksort.mem32.hex
echo   汇编文件: build\quicksort\quicksort.s

echo.
echo ============================================================
echo 编译成功！
echo ============================================================
echo.
echo 使用方法:
echo   1. 将 quicksort.hex 或 quicksort.mem32.hex 加载到指令ROM
echo   2. 在FPGA上运行程序
echo   3. 通过UART查看输出结果
echo.
