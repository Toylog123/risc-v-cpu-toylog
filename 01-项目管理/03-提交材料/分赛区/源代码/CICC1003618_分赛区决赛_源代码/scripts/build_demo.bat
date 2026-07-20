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
