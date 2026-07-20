@echo off
REM ============================================================
REM YH_rv_cpu Cache模块测试脚本
REM Author: Toylog
REM Version: v1.2
REM Date: 2026-04-22
REM ============================================================

echo ============================================================
echo YH_rv_cpu Cache模块测试
echo ============================================================
echo.

cd /d "%~dp0.."

echo [1/4] 检查工具链...
call scripts\check_toolchain.bat
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] 工具链检查失败
    exit /b 1
)

echo.
echo [2/4] 编译I-Cache测试平台...
iverilog -o tb\YH_rv_cpu_icache_tb.vvp ^
    -I./rtl ^
    tb\YH_rv_cpu_icache_tb.v ^
    rtl\YH_rv_cpu_icache.v

if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] I-Cache测试平台编译失败
    exit /b 1
)
echo [OK] I-Cache测试平台编译成功

echo.
echo [3/4] 编译D-Cache测试平台...
iverilog -o tb\YH_rv_cpu_dcache_tb.vvp ^
    -I./rtl ^
    tb\YH_rv_cpu_dcache_tb.v ^
    rtl\YH_rv_cpu_dcache.v

if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] D-Cache测试平台编译失败
    exit /b 1
)
echo [OK] D-Cache测试平台编译成功

echo.
echo [4/4] 运行测试...
echo.
echo ============================================================
echo I-Cache 测试
echo ============================================================
vvp tb\YH_rv_cpu_icache_tb.vvp

echo.
echo ============================================================
echo D-Cache 测试
echo ============================================================
vvp tb\YH_rv_cpu_dcache_tb.vvp

echo.
echo ============================================================
echo 测试完成
echo ============================================================
