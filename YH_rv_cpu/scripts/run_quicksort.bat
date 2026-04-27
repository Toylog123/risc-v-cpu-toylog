@echo off
REM ============================================================
REM run_quicksort.bat
REM Author: Toylog
REM Version: v1.2
REM Function: 运行快速排序仿真测试
REM Description: 编译并运行快速排序程序的仿真测试
REM ============================================================

echo ============================================================
echo YH_rv_cpu QuickSort 仿真测试
echo ============================================================
echo.

cd /d "%~dp0.."

REM 检查工具链
call scripts\check_toolchain.bat
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] 工具链检查失败
    exit /b 1
)

REM 编译快速排序程序
echo.
echo [1/3] 编译快速排序程序...
call scripts\build_quicksort.bat
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] 编译失败
    exit /b 1
)

REM 创建仿真配置文件
echo.
echo [2/3] 准备仿真环境...
echo.

REM 运行仿真
echo [3/3] 运行仿真...
echo.

REM 使用iverilog运行仿真
iverilog -o tb\quicksort_sim.vvp ^
    -I./rtl ^
    -I./tb ^
    tb\YH_rv_cpu_soc_tb.v ^
    rtl\YH_rv_cpu_soc.v ^
    rtl\YH_rv_cpu.v ^
    rtl\YH_rv_cpu_defs.vh ^
    rtl\YH_rv_cpu_if_stage.v ^
    rtl\YH_rv_cpu_id_stage.v ^
    rtl\YH_rv_cpu_ex_stage.v ^
    rtl\YH_rv_cpu_mem_stage.v ^
    rtl\YH_rv_cpu_wb_stage.v ^
    rtl\YH_rv_cpu_decoder.v ^
    rtl\YH_rv_cpu_alu.v ^
    rtl\YH_rv_cpu_regfile.v ^
    rtl\YH_rv_cpu_hazard_unit.v ^
    rtl\YH_rv_dmem_ram.v ^
    rtl\YH_rv_sync_imem_rom.v ^
    rtl\YH_rv_sync_rom32.v ^
    rtl\YH_rv_cpu_uart_tx.v

if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] 仿真编译失败
    exit /b 1
)

echo.
echo ============================================================
echo 仿真环境已准备好
echo ============================================================
echo.
echo 运行仿真:
echo   vvp tb\quicksort_sim.vvp
echo.
echo 或使用GTKWave查看波形:
echo   gtkwave quicksort_sim.vcd
echo.
