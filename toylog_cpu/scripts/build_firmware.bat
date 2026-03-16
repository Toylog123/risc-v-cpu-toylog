@echo off
setlocal

for %%I in ("%~dp0..") do set PROJECT_DIR=%%~fI
set BUILD_DIR=%PROJECT_DIR%\build\sw
set TARGET=%~1
set OUTPUT_NAME=toylog_cpu_demo
set SOURCES="%PROJECT_DIR%\sw\src\crt0.S" "%PROJECT_DIR%\sw\src\main.c"
set GCC=
set OBJDUMP=
set OBJCOPY=

if /I "%TARGET%"=="trap_smoke" (
    set OUTPUT_NAME=toylog_cpu_trap_smoke
    set SOURCES="%PROJECT_DIR%\sw\src\crt0.S" "%PROJECT_DIR%\sw\src\trap_entry.S" "%PROJECT_DIR%\sw\src\trap_smoke.c"
)

if /I "%TARGET%"=="timer_irq_smoke" (
    set OUTPUT_NAME=toylog_cpu_timer_irq_smoke
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

for %%T in (riscv-none-elf-objdump riscv32-unknown-elf-objdump riscv64-unknown-elf-objdump) do (
    where %%T >nul 2>nul
    if not errorlevel 1 (
        set OBJDUMP=%%T
        goto :objdump_done
    )
)
:objdump_done

for %%T in (riscv-none-elf-objcopy riscv32-unknown-elf-objcopy riscv64-unknown-elf-objcopy) do (
    where %%T >nul 2>nul
    if not errorlevel 1 (
        set OBJCOPY=%%T
        goto :objcopy_done
    )
)
:objcopy_done

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

if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"

%GCC% -march=rv32i_zicsr -mabi=ilp32 -nostdlib -ffreestanding -Os ^
    -T "%PROJECT_DIR%\sw\linker\toylog_cpu.ld" ^
    -o "%BUILD_DIR%\%OUTPUT_NAME%.elf" ^
    %SOURCES%
if errorlevel 1 exit /b 1

%OBJDUMP% -d "%BUILD_DIR%\%OUTPUT_NAME%.elf" > "%BUILD_DIR%\%OUTPUT_NAME%.dump"
if errorlevel 1 exit /b 1

%OBJCOPY% -O binary "%BUILD_DIR%\%OUTPUT_NAME%.elf" "%BUILD_DIR%\%OUTPUT_NAME%.bin"
if errorlevel 1 exit /b 1

%OBJCOPY% -O verilog "%BUILD_DIR%\%OUTPUT_NAME%.elf" "%BUILD_DIR%\%OUTPUT_NAME%.hex"
if errorlevel 1 exit /b 1

echo Built:
echo   %BUILD_DIR%\%OUTPUT_NAME%.elf
echo   %BUILD_DIR%\%OUTPUT_NAME%.dump
echo   %BUILD_DIR%\%OUTPUT_NAME%.bin
echo   %BUILD_DIR%\%OUTPUT_NAME%.hex
exit /b 0
