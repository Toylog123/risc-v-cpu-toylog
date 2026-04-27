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
