﻿@echo off
setlocal

for %%I in ("%~dp0..") do set PROJECT_DIR=%%~fI
set TARGET=%~1
set ITERATIONS=%~2
set DATA_SIZE=%~3
set TIMER_HZ=%~4
set EXEC_MASK=%~5

if "%TARGET%"=="" set TARGET=rv32
if "%ITERATIONS%"=="" set ITERATIONS=200
if "%DATA_SIZE%"=="" set DATA_SIZE=2000
if "%TIMER_HZ%"=="" set TIMER_HZ=1000UL
if "%EXEC_MASK%"=="" set EXEC_MASK=0

call "%~dp0prepare_coremark.bat"
if errorlevel 1 exit /b 1

set GCC=
set OBJDUMP=
set OBJCOPY=
set LIBGCC=
set LIBM=
set PYTHON_CMD=
set USER_HOME=%USERPROFILE%
set RISCV_XPACK_ROOT=%USER_HOME%\AppData\Roaming\xPacks\@xpack-dev-tools\riscv-none-elf-gcc
set WORD_HEX_PY=%PROJECT_DIR%\scripts\make_word_hex.py
set COREMARK_DIR=%PROJECT_DIR%\build\external\coremark
set PORT_DIR=%PROJECT_DIR%\sw\coremark_port
set BUILD_DIR=%PROJECT_DIR%\build\sw
set OUTPUT_NAME=YH_rv_cpu_coremark_%TARGET%

if /I "%TARGET%"=="rv64" (
    set MARCH=rv64i_zicsr
    set MABI=lp64
) else (
    set MARCH=rv32i_zicsr
    set MABI=ilp32
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

set LIBGCC_SEARCH=
for /f "delims=" %%I in ('"%GCC%" -march=%MARCH% -mabi=%MABI% -print-libgcc-file-name 2^>nul') do set LIBGCC_SEARCH=%%I
for %%I in ("%LIBGCC_SEARCH%") do set LIBGCC_PATH=%%~fI
if exist "%LIBGCC_PATH%" (
    set LIBGCC_REF=%LIBGCC_PATH%
) else (
    set LIBGCC_REF=
)

set LIBM_SEARCH=
for /f "delims=" %%I in ('"%GCC%" -march=%MARCH% -mabi=%MABI% -print-file-name=libm.a 2^>nul') do set LIBM_SEARCH=%%I
for %%I in ("%LIBM_SEARCH%") do set LIBM_PATH=%%~fI
if exist "%LIBM_PATH%" (
    set LIBM_REF=%LIBM_PATH%
) else (
    set LIBM_REF=
)

if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"

%GCC% -march=%MARCH% -mabi=%MABI% -msmall-data-limit=0 -O2 -ffreestanding -fno-builtin -nostdlib ^
    -Wl,--gc-sections ^
    -I "%PORT_DIR%" ^
    -I "%COREMARK_DIR%" ^
    -DITERATIONS=%ITERATIONS% ^
    -DTOTAL_DATA_SIZE=%DATA_SIZE% ^
    -DYH_COREMARK_TIMER_HZ=%TIMER_HZ% ^
    -DYH_COREMARK_EXEC_MASK=%EXEC_MASK% ^
    -T "%PROJECT_DIR%\sw\linker\YH_rv_cpu_coremark.ld" ^
    -o "%BUILD_DIR%\%OUTPUT_NAME%.elf" ^
    "%PROJECT_DIR%\sw\src\coremark_crt0.S" ^
    "%COREMARK_DIR%\core_list_join.c" ^
    "%COREMARK_DIR%\core_main.c" ^
    "%COREMARK_DIR%\core_matrix.c" ^
    "%COREMARK_DIR%\core_state.c" ^
    "%COREMARK_DIR%\core_util.c" ^
    "%PORT_DIR%\core_portme.c" ^
    "%PORT_DIR%\ee_printf.c" ^
    "%COREMARK_DIR%\barebones\cvt.c" ^
    %LIBM_REF% %LIBGCC_REF%
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

