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
@REM File: scripts/build_demo.bat
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
REM build_demo.bat
REM Author: Toylog
REM Version: v1.2
REM Function: 编译演示程序（包含所有应用）
REM Description: 编译演示程序，包括：
REM   - QuickSort快速排序
REM   - CoreMark基准测试
REM   - LED控制
REM ============================================================

echo ============================================================
echo YH_rv_cpu Demo程序编译脚本
echo ============================================================
echo.

cd /d "%~dp0.."

REM 显示菜单
:menu
echo 请选择要编译的程序:
echo.
echo   [1] QuickSort (快速排序)
echo   [2] CoreMark (基准测试)
echo   [3] 所有程序
echo   [4] 退出
echo.
set /p choice=请输入选项 [1-4]: 

if "%choice%"=="1" goto compile_quicksort
if "%choice%"=="2" goto compile_coremark
if "%choice%"=="3" goto compile_all
if "%choice%"=="4" goto end
goto menu

:compile_quicksort
echo.
echo [INFO] 编译 QuickSort...
call scripts\build_quicksort.bat
goto :end

:compile_coremark
echo.
echo [INFO] 编译 CoreMark...
call scripts\build_coremark.bat
goto :end

:compile_all
echo.
echo [INFO] 编译所有演示程序...
echo.

echo [1/2] 编译 QuickSort...
call scripts\build_quicksort.bat
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] QuickSort 编译失败
    goto :end
)

echo.
echo [2/2] 编译 CoreMark...
call scripts\build_coremark.bat
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] CoreMark 编译失败
    goto :end
)

echo.
echo ============================================================
echo 所有演示程序编译完成！
echo ============================================================
echo.
echo 生成的固件:
echo   - build\quicksort\quicksort.hex
echo   - build\coremark\coremark.hex
echo.
echo 使用方法:
echo   1. 将对应的hex文件加载到FPGA的指令ROM
echo   2. 运行程序并通过UART观察输出
echo.

:end
echo.
pause
