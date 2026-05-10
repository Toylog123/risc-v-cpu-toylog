@echo off
setlocal EnableDelayedExpansion

for %%I in ("%~dp0..") do set PROJECT_DIR=%%~fI
set BUILD_DIR=%PROJECT_DIR%\build\sw
set OUTPUT_NAME=%~1
set DHRYSTONE_RUNS=%~2
set TARGET=%~3
if "%OUTPUT_NAME%"=="" set OUTPUT_NAME=YH_rv_cpu_dhrystone
if "%DHRYSTONE_RUNS%"=="" set DHRYSTONE_RUNS=10
if "%TARGET%"=="" set TARGET=rv32im_zicsr
if "%DHRYSTONE_OPT_LEVEL%"=="" set DHRYSTONE_OPT_LEVEL=-O2
if "%DHRYSTONE_EXTRA_CFLAGS%"=="" set DHRYSTONE_EXTRA_CFLAGS=

set MARCH=
set MULTIDIR=
if /I "%TARGET%"=="rv32im_zicsr" (
    set MARCH=rv32im_zicsr
    set MULTIDIR=rv32im\ilp32
) else if /I "%TARGET%"=="rv32i_zmmul_zba_zbb_zbs_zicsr" (
    set MARCH=rv32i_zmmul_zba_zbb_zbs_zicsr
    set MULTIDIR=rv32i\ilp32
) else if /I "%TARGET%"=="rv32i_zmmul_zba_zbb_zbs" (
    set MARCH=rv32i_zmmul_zba_zbb_zbs_zicsr
    set MULTIDIR=rv32i\ilp32
) else if /I "%TARGET%"=="rv32i_zmmul_zba_zbb_zbs_idbr" (
    set MARCH=rv32i_zmmul_zba_zbb_zbs_zicsr
    set MULTIDIR=rv32i\ilp32
) else if /I "%TARGET%"=="rv32i_zmmul_zba_zbb_zbs_zbc_xthead" (
    set MARCH=rv32i_zmmul_zba_zbb_zbs_zbc_xtheadba_xtheadbb_xtheadbs_xtheadcondmov_xtheadmemidx_zicsr
    set MULTIDIR=rv32i\ilp32
) else if /I "%TARGET%"=="rv32i_zmmul_zba_zbb_zbs_zbc_xthead_nomemidx" (
    set MARCH=rv32i_zmmul_zba_zbb_zbs_zbc_xtheadba_xtheadbb_xtheadbs_xtheadcondmov_zicsr
    set MULTIDIR=rv32i\ilp32
) else if /I "%TARGET%"=="rv32i_zmmul_zba_zbb_zbs_zbc_xtheadmemidx_zicsr" (
    set MARCH=rv32i_zmmul_zba_zbb_zbs_zbc_xtheadba_xtheadbb_xtheadbs_xtheadcondmov_xtheadmemidx_zicsr
    set MULTIDIR=rv32i\ilp32
) else if /I "%TARGET%"=="rv32i_zmmul_zba_zbb_zbs_zbc_xthead_idbr" (
    set MARCH=rv32i_zmmul_zba_zbb_zbs_zbc_xtheadba_xtheadbb_xtheadbs_xtheadcondmov_xtheadmemidx_zicsr
    set MULTIDIR=rv32i\ilp32
) else if /I "%TARGET%"=="rv32i_zmmul_zba_zbb_zbs_zbc_zicond_xthead_idbr" (
    set MARCH=rv32i_zmmul_zba_zbb_zbs_zbc_zicond_xtheadba_xtheadbb_xtheadbs_xtheadcondmov_xtheadmemidx_zicsr
    set MULTIDIR=rv32i\ilp32
) else if /I "%TARGET%"=="rv32i_zmmul_zba_zbb_zbs_zicond_xthead_idbr" (
    set MARCH=rv32i_zmmul_zba_zbb_zbs_zicond_xtheadba_xtheadbb_xtheadbs_xtheadcondmov_xtheadmemidx_zicsr
    set MULTIDIR=rv32i\ilp32
) else if /I "%TARGET%"=="rv32i_zmmul_zba_zbb_zbs_zbc_xthead_nomemidx_idbr" (
    set MARCH=rv32i_zmmul_zba_zbb_zbs_zbc_xtheadba_xtheadbb_xtheadbs_xtheadcondmov_zicsr
    set MULTIDIR=rv32i\ilp32
) else if /I "%TARGET%"=="rv32im_zba_zbb_zbs_zbc_xthead_idbr" (
    set MARCH=rv32im_zba_zbb_zbs_zbc_xtheadba_xtheadbb_xtheadbs_xtheadcondmov_xtheadmemidx_zicsr
    set MULTIDIR=rv32im\ilp32
) else (
    echo Unsupported Dhrystone target: %TARGET%
    exit /b 1
)

set GCC=
set OBJDUMP=
set OBJCOPY=
set LIBGCC=
set USER_HOME=%USERPROFILE%
set RISCV_XPACK_ROOT=%USER_HOME%\AppData\Roaming\xPacks\@xpack-dev-tools\riscv-none-elf-gcc
set WORD_HEX_PY=%PROJECT_DIR%\scripts\make_word_hex.py
set GCC_TMP_DIR=%PROJECT_DIR%\..\_tmp\gcc_tmp
set PYTHON_CMD=

for %%T in (riscv-none-elf-gcc riscv32-unknown-elf-gcc riscv64-unknown-elf-gcc) do (
    where %%T >nul 2>nul
    if not errorlevel 1 (
        for /f "delims=" %%P in ('where %%T 2^>nul') do set GCC=%%P
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

for %%I in ("!GCC!") do set GCC_DIR=%%~dpI
set GCC_ROOT=!GCC_DIR:~0,-4!
for /d %%D in ("!GCC_ROOT!\lib\gcc\riscv-none-elf\*") do (
    set GCC_VERSION_DIR=%%~fD
    goto :gcc_version_done
)
:gcc_version_done

if not defined GCC_VERSION_DIR (
    echo Missing GCC multilib root under !GCC_ROOT!\lib\gcc\riscv-none-elf
    exit /b 1
)

set LIBGCC=!GCC_VERSION_DIR!\%MULTIDIR%\libgcc.a
if not exist "!LIBGCC!" (
    echo Missing libgcc for %MULTIDIR%: !LIBGCC!
    exit /b 1
)

if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"
if not exist "%GCC_TMP_DIR%" mkdir "%GCC_TMP_DIR%"
set TMP=%GCC_TMP_DIR%
set TEMP=%GCC_TMP_DIR%
set TMPDIR=%GCC_TMP_DIR%

set CRT0_OBJ=%BUILD_DIR%\%OUTPUT_NAME%_crt0.o
set MAIN_OBJ=%BUILD_DIR%\%OUTPUT_NAME%_main.o
set CORE_OBJ=%BUILD_DIR%\%OUTPUT_NAME%_core.o
set PORT_OBJ=%BUILD_DIR%\%OUTPUT_NAME%_port.o
set MAIN_SRC=%PROJECT_DIR%\build\external\riscv-tests\benchmarks\dhrystone\dhrystone_main.c
set CORE_SRC=%PROJECT_DIR%\build\external\riscv-tests\benchmarks\dhrystone\dhrystone.c

if /I "%DHRYSTONE_STRIP_NOINLINE%"=="1" (
    set GEN_DHRY_DIR=%BUILD_DIR%\generated_dhrystone
    if not exist "!GEN_DHRY_DIR!" mkdir "!GEN_DHRY_DIR!"
    findstr /V /C:"#pragma GCC optimize" "%PROJECT_DIR%\build\external\riscv-tests\benchmarks\dhrystone\dhrystone_main.c" > "!GEN_DHRY_DIR!\dhrystone_main.c"
    if errorlevel 1 exit /b 1
    findstr /V /C:"#pragma GCC optimize" "%PROJECT_DIR%\build\external\riscv-tests\benchmarks\dhrystone\dhrystone.c" > "!GEN_DHRY_DIR!\dhrystone.c"
    if errorlevel 1 exit /b 1
    set MAIN_SRC=!GEN_DHRY_DIR!\dhrystone_main.c
    set CORE_SRC=!GEN_DHRY_DIR!\dhrystone.c
)

echo Dhrystone target: %TARGET%
echo Dhrystone march: %MARCH%
echo Dhrystone opt level: %DHRYSTONE_OPT_LEVEL%
if defined DHRYSTONE_EXTRA_CFLAGS echo Dhrystone extra cflags: %DHRYSTONE_EXTRA_CFLAGS%
if /I "%DHRYSTONE_STRIP_NOINLINE%"=="1" echo Dhrystone source mode: generated without no-inline pragma

"%GCC%" -march=%MARCH% -mabi=ilp32 -c ^
    "%PROJECT_DIR%\sw\src\dhrystone_crt0.S" ^
    -o "%CRT0_OBJ%"
if errorlevel 1 exit /b 1

"%GCC%" -march=%MARCH% -mabi=ilp32 -msmall-data-limit=0 %DHRYSTONE_OPT_LEVEL% %DHRYSTONE_EXTRA_CFLAGS% -std=gnu89 -ffreestanding -fno-builtin ^
    -Wno-implicit-function-declaration -Wno-int-conversion ^
    -include "%PROJECT_DIR%\sw\dhrystone_port\dhrystone.h" ^
    -I "%PROJECT_DIR%\sw\dhrystone_port" ^
    -I "%PROJECT_DIR%\build\external\riscv-tests\benchmarks\dhrystone" ^
    -I "%PROJECT_DIR%\build\external\riscv-tests\benchmarks\common" ^
    -DYH_DHRYSTONE_TIMER_HZ=100000000L -DYH_DHRYSTONE_MIN_TICKS=1L -DYH_DHRYSTONE_RUNS=%DHRYSTONE_RUNS% ^
    -c "!MAIN_SRC!" ^
    -o "%MAIN_OBJ%"
if errorlevel 1 exit /b 1

"%GCC%" -march=%MARCH% -mabi=ilp32 -msmall-data-limit=0 %DHRYSTONE_OPT_LEVEL% %DHRYSTONE_EXTRA_CFLAGS% -std=gnu89 -ffreestanding -fno-builtin ^
    -Wno-implicit-function-declaration -Wno-int-conversion ^
    -include "%PROJECT_DIR%\sw\dhrystone_port\dhrystone.h" ^
    -I "%PROJECT_DIR%\sw\dhrystone_port" ^
    -I "%PROJECT_DIR%\build\external\riscv-tests\benchmarks\dhrystone" ^
    -I "%PROJECT_DIR%\build\external\riscv-tests\benchmarks\common" ^
    -DYH_DHRYSTONE_TIMER_HZ=100000000L -DYH_DHRYSTONE_MIN_TICKS=1L -DYH_DHRYSTONE_RUNS=%DHRYSTONE_RUNS% ^
    -c "!CORE_SRC!" ^
    -o "%CORE_OBJ%"
if errorlevel 1 exit /b 1

"%GCC%" -march=%MARCH% -mabi=ilp32 -msmall-data-limit=0 %DHRYSTONE_OPT_LEVEL% %DHRYSTONE_EXTRA_CFLAGS% -std=gnu89 -ffreestanding -fno-builtin ^
    -Wno-implicit-function-declaration -Wno-int-conversion ^
    -I "%PROJECT_DIR%\sw\dhrystone_port" ^
    -c "%PROJECT_DIR%\sw\dhrystone_port\yh_dhrystone_support.c" ^
    -o "%PORT_OBJ%"
if errorlevel 1 exit /b 1

"%GCC%" -march=%MARCH% -mabi=ilp32 -nostdlib ^
    -T "%PROJECT_DIR%\sw\linker\YH_rv_cpu_coremark.ld" ^
    -o "%BUILD_DIR%\%OUTPUT_NAME%.elf" ^
    "%CRT0_OBJ%" "%MAIN_OBJ%" "%CORE_OBJ%" "%PORT_OBJ%" "!LIBGCC!"
if errorlevel 1 exit /b 1

"%OBJDUMP%" -d "%BUILD_DIR%\%OUTPUT_NAME%.elf" > "%BUILD_DIR%\%OUTPUT_NAME%.dump"
if errorlevel 1 exit /b 1

"%OBJCOPY%" -O binary "%BUILD_DIR%\%OUTPUT_NAME%.elf" "%BUILD_DIR%\%OUTPUT_NAME%.bin"
if errorlevel 1 exit /b 1

"%OBJCOPY%" -O verilog "%BUILD_DIR%\%OUTPUT_NAME%.elf" "%BUILD_DIR%\%OUTPUT_NAME%.hex"
if errorlevel 1 exit /b 1

"%PYTHON_CMD%" "%WORD_HEX_PY%" "%BUILD_DIR%\%OUTPUT_NAME%.bin" "%BUILD_DIR%\%OUTPUT_NAME%.mem32.hex"
if errorlevel 1 exit /b 1

echo Built:
echo   %BUILD_DIR%\%OUTPUT_NAME%.elf
echo   %BUILD_DIR%\%OUTPUT_NAME%.dump
echo   %BUILD_DIR%\%OUTPUT_NAME%.bin
echo   %BUILD_DIR%\%OUTPUT_NAME%.hex
echo   %BUILD_DIR%\%OUTPUT_NAME%.mem32.hex
exit /b 0
