@echo off
setlocal EnableDelayedExpansion

for %%I in ("%~dp0..") do set PROJECT_DIR=%%~fI
set TARGET=%~1
set ITERATIONS=%~2
set DATA_SIZE=%~3
set TIMER_HZ=%~4
set EXEC_MASK=%~5
set OUTPUT_NAME=%~6

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
set GCC_TMP_DIR=%PROJECT_DIR%\..\_tmp\gcc_tmp
set OPT_FLAGS=-O2
set OPT_DEFINE=YH_COREMARK_OPT_O2
if "%OUTPUT_NAME%"=="" set OUTPUT_NAME=YH_rv_cpu_coremark_%TARGET%

if /I "%TARGET%"=="rv64" (
    set MARCH=rv64i_zicsr
    set MABI=lp64
) else if /I "%TARGET%"=="rv64im" (
    set MARCH=rv64im_zicsr
    set MABI=lp64
) else if /I "%TARGET%"=="rv32im" (
    set MARCH=rv32im_zicsr
    set MABI=ilp32
) else if /I "%TARGET%"=="rv32im_o2unroll" (
    set MARCH=rv32im_zicsr
    set MABI=ilp32
    set OPT_FLAGS=-O2 -funroll-loops
    set OPT_DEFINE=YH_COREMARK_OPT_O2UNROLL
) else if /I "%TARGET%"=="rv32im_o3" (
    set MARCH=rv32im_zicsr
    set MABI=ilp32
    set OPT_FLAGS=-O3
    set OPT_DEFINE=YH_COREMARK_OPT_O3
) else if /I "%TARGET%"=="rv32im_o3unroll" (
    set MARCH=rv32im_zicsr
    set MABI=ilp32
    set OPT_FLAGS=-O3 -funroll-loops
    set OPT_DEFINE=YH_COREMARK_OPT_O3UNROLL
) else if /I "%TARGET%"=="rv32im_o3unroll_b1nosched" (
    set MARCH=rv32im_zicsr
    set MABI=ilp32
    set OPT_FLAGS=-O3 -funroll-loops -mbranch-cost=1 -fno-schedule-insns -fno-schedule-insns2
    set OPT_DEFINE=YH_COREMARK_OPT_O3UNROLL_B1NOSCHED
) else if /I "%TARGET%"=="rv32im_o3unroll_b1nosched_uall800" (
    set MARCH=rv32im_zicsr
    set MABI=ilp32
    set OPT_FLAGS=-O3 -funroll-loops -mbranch-cost=1 -fno-schedule-insns -fno-schedule-insns2 -funroll-all-loops --param max-unrolled-insns=800 --param max-average-unrolled-insns=320
    set OPT_DEFINE=YH_COREMARK_OPT_O3UNROLL_B1NOSCHED_UALL800
) else if /I "%TARGET%"=="rv32im_o3unroll_b1nosched_uall800_inline_nocross" (
    set MARCH=rv32im_zicsr
    set MABI=ilp32
    set OPT_FLAGS=-O3 -funroll-loops -mbranch-cost=1 -fno-schedule-insns -fno-schedule-insns2 -funroll-all-loops --param max-unrolled-insns=800 --param max-average-unrolled-insns=320 -finline-functions --param max-inline-insns-single=1000 --param max-inline-insns-auto=1000 --param inline-unit-growth=500 -fno-crossjumping
    set OPT_DEFINE=YH_COREMARK_OPT_O3UNROLL_B1NOSCHED_UALL800_INLINE_NOCROSS
) else if /I "%TARGET%"=="rv32i_zmmul_o3unroll_b1nosched_uall800_inline_nocross" (
    set MARCH=rv32i_zmmul_zicsr
    set MABI=ilp32
    set OPT_FLAGS=-O3 -funroll-loops -mbranch-cost=1 -fno-schedule-insns -fno-schedule-insns2 -funroll-all-loops --param max-unrolled-insns=800 --param max-average-unrolled-insns=320 -finline-functions --param max-inline-insns-single=1000 --param max-inline-insns-auto=1000 --param inline-unit-growth=500 -fno-crossjumping
    set OPT_DEFINE=YH_COREMARK_OPT_RV32I_ZMMUL_O3UNROLL_B1NOSCHED_UALL800_INLINE_NOCROSS
) else if /I "%TARGET%"=="rv32i_zmmul_zba_zbb_zbs_o3unroll_b1nosched_uall800_inline_nocross" (
    set MARCH=rv32i_zmmul_zba_zbb_zbs_zicsr
    set MABI=ilp32
    set OPT_FLAGS=-O3 -funroll-loops -mbranch-cost=1 -fno-schedule-insns -fno-schedule-insns2 -funroll-all-loops --param max-unrolled-insns=800 --param max-average-unrolled-insns=320 -finline-functions --param max-inline-insns-single=1000 --param max-inline-insns-auto=1000 --param inline-unit-growth=500 -fno-crossjumping
    set OPT_DEFINE=YH_COREMARK_OPT_RV32I_ZMMUL_ZBA_ZBB_ZBS_INLINE_NOCROSS
) else if /I "%TARGET%"=="rv32i_zmmul_zba_zbb_zbs_xthead_memidx_noautoinc_o2sched_nocaller_noifconv" (
    set MARCH=rv32i_zmmul_zba_zbb_zbs_xtheadba_xtheadbb_xtheadbs_xtheadcondmov_xtheadmemidx_zicsr
    set MABI=ilp32
    set OPT_FLAGS=-O3 -funroll-loops -mbranch-cost=1 -fno-schedule-insns -fno-schedule-insns2 -funroll-all-loops --param max-unrolled-insns=800 --param max-average-unrolled-insns=320 -finline-functions --param max-inline-insns-single=1000 --param max-inline-insns-auto=1000 --param inline-unit-growth=500 -fno-crossjumping -O2 -fschedule-insns -fschedule-insns2 -fno-caller-saves -fno-if-conversion -fno-if-conversion2 -fno-auto-inc-dec
    set OPT_DEFINE=YH_COREMARK_OPT_RV32I_ZMMUL_ZB_XTHEAD_MEMIDX_NOAUTOINC_O2SCHED_NOCALLER_NOIFCONV
) else if /I "%TARGET%"=="rv32i_zmmul_zba_zbb_zbs_zbc_xthead_memidx_noautoinc_o2sched_nocaller_noifconv" (
    set MARCH=rv32i_zmmul_zba_zbb_zbs_zbc_xtheadba_xtheadbb_xtheadbs_xtheadcondmov_xtheadmemidx_zicsr
    set MABI=ilp32
    set OPT_FLAGS=-O3 -funroll-loops -mbranch-cost=1 -fno-schedule-insns -fno-schedule-insns2 -funroll-all-loops --param max-unrolled-insns=800 --param max-average-unrolled-insns=320 -finline-functions --param max-inline-insns-single=1000 --param max-inline-insns-auto=1000 --param inline-unit-growth=500 -fno-crossjumping -O2 -fschedule-insns -fschedule-insns2 -fno-caller-saves -fno-if-conversion -fno-if-conversion2 -fno-auto-inc-dec
    set OPT_DEFINE=YH_COREMARK_OPT_RV32I_ZMMUL_ZBC_XTHEAD_MEMIDX_NOAUTOINC_O2SCHED_NOCALLER_NOIFCONV
) else if /I "%TARGET%"=="rv32i_zmmul_zba_zbb_zbs_zbc_zicond_xthead_memidx_noautoinc_o2sched_nocaller" (
    set MARCH=rv32i_zmmul_zba_zbb_zbs_zbc_zicond_xtheadba_xtheadbb_xtheadbs_xtheadcondmov_xtheadmemidx_zicsr
    set MABI=ilp32
    set OPT_FLAGS=-O3 -funroll-loops -mbranch-cost=1 -fno-schedule-insns -fno-schedule-insns2 -funroll-all-loops --param max-unrolled-insns=800 --param max-average-unrolled-insns=320 -finline-functions --param max-inline-insns-single=1000 --param max-inline-insns-auto=1000 --param inline-unit-growth=500 -fno-crossjumping -O2 -fschedule-insns -fschedule-insns2 -fno-caller-saves -fno-auto-inc-dec
    set OPT_DEFINE=YH_COREMARK_OPT_RV32I_ZMMUL_ZBC_ZICOND_XTHEAD_MEMIDX_NOAUTOINC_O2SCHED_NOCALLER
) else if /I "%TARGET%"=="rv32i_zmmul_zba_zbb_zbs_zicond_xthead_memidx_noautoinc_o2sched_nocaller" (
    set MARCH=rv32i_zmmul_zba_zbb_zbs_zicond_xtheadba_xtheadbb_xtheadbs_xtheadcondmov_xtheadmemidx_zicsr
    set MABI=ilp32
    set OPT_FLAGS=-O3 -funroll-loops -mbranch-cost=1 -fno-schedule-insns -fno-schedule-insns2 -funroll-all-loops --param max-unrolled-insns=800 --param max-average-unrolled-insns=320 -finline-functions --param max-inline-insns-single=1000 --param max-inline-insns-auto=1000 --param inline-unit-growth=500 -fno-crossjumping -O2 -fschedule-insns -fschedule-insns2 -fno-caller-saves -fno-auto-inc-dec
    set OPT_DEFINE=YH_COREMARK_OPT_RV32I_ZMMUL_ZICOND_XTHEAD_MEMIDX_NOAUTOINC_O2SCHED_NOCALLER
) else if /I "%TARGET%"=="rv32i_zmmul_zba_zbb_zbs_zbc_zicond_xthead_memidx_o2sched_nocaller" (
    set MARCH=rv32i_zmmul_zba_zbb_zbs_zbc_zicond_xtheadba_xtheadbb_xtheadbs_xtheadcondmov_xtheadmemidx_zicsr
    set MABI=ilp32
    set OPT_FLAGS=-O3 -funroll-loops -mbranch-cost=1 -fno-schedule-insns -fno-schedule-insns2 -funroll-all-loops --param max-unrolled-insns=800 --param max-average-unrolled-insns=320 -finline-functions --param max-inline-insns-single=1000 --param max-inline-insns-auto=1000 --param inline-unit-growth=500 -fno-crossjumping -O2 -fschedule-insns -fschedule-insns2 -fno-caller-saves
    set OPT_DEFINE=YH_COREMARK_OPT_RV32I_ZMMUL_ZBC_ZICOND_XTHEAD_MEMIDX_O2SCHED_NOCALLER
) else if /I "%TARGET%"=="rv32i_zmmul_zba_zbb_zbs_zbc_zbkb_xthead_memidx_noautoinc_o2sched_nocaller_noifconv" (
    set MARCH=rv32i_zmmul_zba_zbb_zbs_zbc_zbkb_xtheadba_xtheadbb_xtheadbs_xtheadcondmov_xtheadmemidx_zicsr
    set MABI=ilp32
    set OPT_FLAGS=-O3 -funroll-loops -mbranch-cost=1 -fno-schedule-insns -fno-schedule-insns2 -funroll-all-loops --param max-unrolled-insns=800 --param max-average-unrolled-insns=320 -finline-functions --param max-inline-insns-single=1000 --param max-inline-insns-auto=1000 --param inline-unit-growth=500 -fno-crossjumping -O2 -fschedule-insns -fschedule-insns2 -fno-caller-saves -fno-if-conversion -fno-if-conversion2 -fno-auto-inc-dec
    set OPT_DEFINE=YH_COREMARK_OPT_RV32I_ZMMUL_ZBC_ZBKB_XTHEAD_MEMIDX_NOAUTOINC_O2SCHED_NOCALLER_NOIFCONV
) else if /I "%TARGET%"=="rv32i_zmmul_zba_zbb_zbs_zbc_zicond_zbkb_xthead_memidx_noautoinc_o2sched_nocaller" (
    set MARCH=rv32i_zmmul_zba_zbb_zbs_zbc_zicond_zbkb_xtheadba_xtheadbb_xtheadbs_xtheadcondmov_xtheadmemidx_zicsr
    set MABI=ilp32
    set OPT_FLAGS=-O3 -funroll-loops -mbranch-cost=1 -fno-schedule-insns -fno-schedule-insns2 -funroll-all-loops --param max-unrolled-insns=800 --param max-average-unrolled-insns=320 -finline-functions --param max-inline-insns-single=1000 --param max-inline-insns-auto=1000 --param inline-unit-growth=500 -fno-crossjumping -O2 -fschedule-insns -fschedule-insns2 -fno-caller-saves -fno-auto-inc-dec
    set OPT_DEFINE=YH_COREMARK_OPT_RV32I_ZMMUL_ZBC_ZICOND_ZBKB_XTHEAD_MEMIDX_NOAUTOINC_O2SCHED_NOCALLER
) else if /I "%TARGET%"=="rv32im_zba_zbb_zbs_o3unroll_b1nosched_uall800_inline_nocross" (
    set MARCH=rv32im_zba_zbb_zbs_zicsr
    set MABI=ilp32
    set OPT_FLAGS=-O3 -funroll-loops -mbranch-cost=1 -fno-schedule-insns -fno-schedule-insns2 -funroll-all-loops --param max-unrolled-insns=800 --param max-average-unrolled-insns=320 -finline-functions --param max-inline-insns-single=1000 --param max-inline-insns-auto=1000 --param inline-unit-growth=500 -fno-crossjumping
    set OPT_DEFINE=YH_COREMARK_OPT_RV32IM_ZBA_ZBB_ZBS_INLINE_NOCROSS
) else if /I "%TARGET%"=="rv32im_zba_zbb_zbs_zbc_zbkb_zicond_o3unroll_b1nosched_uall800_inline_nocross" (
    set MARCH=rv32im_zba_zbb_zbs_zbc_zbkb_zicond_zicsr
    set MABI=ilp32
    set OPT_FLAGS=-O3 -funroll-loops -mbranch-cost=1 -fno-schedule-insns -fno-schedule-insns2 -funroll-all-loops --param max-unrolled-insns=800 --param max-average-unrolled-insns=320 -finline-functions --param max-inline-insns-single=1000 --param max-inline-insns-auto=1000 --param inline-unit-growth=500 -fno-crossjumping
    set OPT_DEFINE=YH_COREMARK_OPT_RV32IM_STD_EXT_INLINE_NOCROSS
) else if /I "%TARGET%"=="rv32im_stdext_o2sched_nocaller" (
    set MARCH=rv32im_zba_zbb_zbs_zbc_zbkb_zicond_zicsr
    set MABI=ilp32
    set OPT_FLAGS=-O3 -funroll-loops -mbranch-cost=1 -fno-schedule-insns -fno-schedule-insns2 -funroll-all-loops --param max-unrolled-insns=800 --param max-average-unrolled-insns=320 -finline-functions --param max-inline-insns-single=1000 --param max-inline-insns-auto=1000 --param inline-unit-growth=500 -fno-crossjumping -O2 -fschedule-insns -fschedule-insns2 -fno-caller-saves
    set OPT_DEFINE=YH_COREMARK_OPT_RV32IM_STD_EXT_O2SCHED_NOCALLER
) else if /I "%TARGET%"=="rv32im_zb_xthead_o2sched_nocaller" (
    set MARCH=rv32im_zba_zbb_zbs_zbc_zbkb_zicond_xtheadba_xtheadbb_xtheadbs_xtheadcondmov_zicsr
    set MABI=ilp32
    set OPT_FLAGS=-O3 -funroll-loops -mbranch-cost=1 -fno-schedule-insns -fno-schedule-insns2 -funroll-all-loops --param max-unrolled-insns=800 --param max-average-unrolled-insns=320 -finline-functions --param max-inline-insns-single=1000 --param max-inline-insns-auto=1000 --param inline-unit-growth=500 -fno-crossjumping -O2 -fschedule-insns -fschedule-insns2 -fno-caller-saves
    set OPT_DEFINE=YH_COREMARK_OPT_RV32IM_ZB_XTHEAD_O2SCHED_NOCALLER
) else if /I "%TARGET%"=="rv32im_zb_xthead_o2sched_nocaller_noifconv" (
    set MARCH=rv32im_zba_zbb_zbs_zbc_zbkb_zicond_xtheadba_xtheadbb_xtheadbs_xtheadcondmov_zicsr
    set MABI=ilp32
    set OPT_FLAGS=-O3 -funroll-loops -mbranch-cost=1 -fno-schedule-insns -fno-schedule-insns2 -funroll-all-loops --param max-unrolled-insns=800 --param max-average-unrolled-insns=320 -finline-functions --param max-inline-insns-single=1000 --param max-inline-insns-auto=1000 --param inline-unit-growth=500 -fno-crossjumping -O2 -fschedule-insns -fschedule-insns2 -fno-caller-saves -fno-if-conversion -fno-if-conversion2
    set OPT_DEFINE=YH_COREMARK_OPT_RV32IM_ZB_XTHEAD_O2SCHED_NOCALLER_NOIFCONV
) else if /I "%TARGET%"=="rv32im_zb_xthead_memidx_o2sched_nocaller_noifconv" (
    set MARCH=rv32im_zba_zbb_zbs_zbc_zbkb_zicond_xtheadba_xtheadbb_xtheadbs_xtheadcondmov_xtheadmemidx_zicsr
    set MABI=ilp32
    set OPT_FLAGS=-O3 -funroll-loops -mbranch-cost=1 -fno-schedule-insns -fno-schedule-insns2 -funroll-all-loops --param max-unrolled-insns=800 --param max-average-unrolled-insns=320 -finline-functions --param max-inline-insns-single=1000 --param max-inline-insns-auto=1000 --param inline-unit-growth=500 -fno-crossjumping -O2 -fschedule-insns -fschedule-insns2 -fno-caller-saves -fno-if-conversion -fno-if-conversion2
    set OPT_DEFINE=YH_COREMARK_OPT_RV32IM_ZB_XTHEAD_MEMIDX_O2SCHED_NOCALLER_NOIFCONV
) else if /I "%TARGET%"=="rv32im_zb_xthead_memidx_noautoinc_o2sched_nocaller_noifconv" (
    set MARCH=rv32im_zba_zbb_zbs_zbc_zbkb_zicond_xtheadba_xtheadbb_xtheadbs_xtheadcondmov_xtheadmemidx_zicsr
    set MABI=ilp32
    set OPT_FLAGS=-O3 -funroll-loops -mbranch-cost=1 -fno-schedule-insns -fno-schedule-insns2 -funroll-all-loops --param max-unrolled-insns=800 --param max-average-unrolled-insns=320 -finline-functions --param max-inline-insns-single=1000 --param max-inline-insns-auto=1000 --param inline-unit-growth=500 -fno-crossjumping -O2 -fschedule-insns -fschedule-insns2 -fno-caller-saves -fno-if-conversion -fno-if-conversion2 -fno-auto-inc-dec
    set OPT_DEFINE=YH_COREMARK_OPT_RV32IM_ZB_XTHEAD_MEMIDX_NOAUTOINC_O2SCHED_NOCALLER_NOIFCONV
) else if /I "%TARGET%"=="rv32im_ofast" (
    set MARCH=rv32im_zicsr
    set MABI=ilp32
    set OPT_FLAGS=-Ofast
    set OPT_DEFINE=YH_COREMARK_OPT_OFAST
) else if /I "%TARGET%"=="rv32im_ofast_unroll" (
    set MARCH=rv32im_zicsr
    set MABI=ilp32
    set OPT_FLAGS=-Ofast -funroll-loops
    set OPT_DEFINE=YH_COREMARK_OPT_OFAST_UNROLL
) else if /I "%TARGET%"=="rv32im_o3lto" (
    set MARCH=rv32im_zicsr
    set MABI=ilp32
    set OPT_FLAGS=-O3 -flto
    set OPT_DEFINE=YH_COREMARK_OPT_O3LTO
) else if /I "%TARGET%"=="rv32im_o3unroll_lto" (
    set MARCH=rv32im_zicsr
    set MABI=ilp32
    set OPT_FLAGS=-O3 -funroll-loops -flto
    set OPT_DEFINE=YH_COREMARK_OPT_O3UNROLL_LTO
) else (
    set MARCH=rv32i_zicsr
    set MABI=ilp32
)

if not "%YH_COREMARK_EXTRA_OPT%"=="" (
    set OPT_FLAGS=!OPT_FLAGS! %YH_COREMARK_EXTRA_OPT%
)

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

set LIBGCC_REF=
set LIBM_REF=
set MULTIDIR=
set GCC_VERSION_DIR=

for %%I in ("!GCC!") do set GCC_DIR=%%~dpI
set GCC_ROOT=!GCC_DIR:~0,-4!

if /I "%TARGET%"=="rv64" (
    set MULTIDIR=rv64i\lp64
) else if /I "%TARGET%"=="rv64im" (
    set MULTIDIR=rv64im\lp64
) else if /I "%TARGET%"=="rv32im" (
    set MULTIDIR=rv32im\ilp32
) else if /I "%TARGET%"=="rv32im_o2unroll" (
    set MULTIDIR=rv32im\ilp32
) else if /I "%TARGET%"=="rv32im_o3" (
    set MULTIDIR=rv32im\ilp32
) else if /I "%TARGET%"=="rv32im_o3unroll" (
    set MULTIDIR=rv32im\ilp32
) else if /I "%TARGET%"=="rv32im_o3unroll_b1nosched" (
    set MULTIDIR=rv32im\ilp32
) else if /I "%TARGET%"=="rv32im_o3unroll_b1nosched_uall800" (
    set MULTIDIR=rv32im\ilp32
) else if /I "%TARGET%"=="rv32im_o3unroll_b1nosched_uall800_inline_nocross" (
    set MULTIDIR=rv32im\ilp32
) else if /I "%TARGET%"=="rv32i_zmmul_o3unroll_b1nosched_uall800_inline_nocross" (
    set MULTIDIR=rv32i\ilp32
) else if /I "%TARGET%"=="rv32i_zmmul_zba_zbb_zbs_o3unroll_b1nosched_uall800_inline_nocross" (
    set MULTIDIR=rv32i\ilp32
) else if /I "%TARGET%"=="rv32i_zmmul_zba_zbb_zbs_xthead_memidx_noautoinc_o2sched_nocaller_noifconv" (
    set MULTIDIR=rv32i\ilp32
) else if /I "%TARGET%"=="rv32i_zmmul_zba_zbb_zbs_zbc_xthead_memidx_noautoinc_o2sched_nocaller_noifconv" (
    set MULTIDIR=rv32i\ilp32
) else if /I "%TARGET%"=="rv32i_zmmul_zba_zbb_zbs_zbc_zicond_xthead_memidx_noautoinc_o2sched_nocaller" (
    set MULTIDIR=rv32i\ilp32
) else if /I "%TARGET%"=="rv32i_zmmul_zba_zbb_zbs_zicond_xthead_memidx_noautoinc_o2sched_nocaller" (
    set MULTIDIR=rv32i\ilp32
) else if /I "%TARGET%"=="rv32i_zmmul_zba_zbb_zbs_zbc_zicond_xthead_memidx_o2sched_nocaller" (
    set MULTIDIR=rv32i\ilp32
) else if /I "%TARGET%"=="rv32i_zmmul_zba_zbb_zbs_zbc_zbkb_xthead_memidx_noautoinc_o2sched_nocaller_noifconv" (
    set MULTIDIR=rv32i\ilp32
) else if /I "%TARGET%"=="rv32i_zmmul_zba_zbb_zbs_zbc_zicond_zbkb_xthead_memidx_noautoinc_o2sched_nocaller" (
    set MULTIDIR=rv32i\ilp32
) else if /I "%TARGET%"=="rv32im_zba_zbb_zbs_o3unroll_b1nosched_uall800_inline_nocross" (
    set MULTIDIR=rv32im\ilp32
) else if /I "%TARGET%"=="rv32im_zba_zbb_zbs_zbc_zbkb_zicond_o3unroll_b1nosched_uall800_inline_nocross" (
    set MULTIDIR=rv32im\ilp32
) else if /I "%TARGET%"=="rv32im_stdext_o2sched_nocaller" (
    set MULTIDIR=rv32im\ilp32
) else if /I "%TARGET%"=="rv32im_zb_xthead_o2sched_nocaller" (
    set MULTIDIR=rv32im\ilp32
) else if /I "%TARGET%"=="rv32im_zb_xthead_o2sched_nocaller_noifconv" (
    set MULTIDIR=rv32im\ilp32
) else if /I "%TARGET%"=="rv32im_zb_xthead_memidx_o2sched_nocaller_noifconv" (
    set MULTIDIR=rv32im\ilp32
) else if /I "%TARGET%"=="rv32im_zb_xthead_memidx_noautoinc_o2sched_nocaller_noifconv" (
    set MULTIDIR=rv32im\ilp32
) else if /I "%TARGET%"=="rv32im_ofast" (
    set MULTIDIR=rv32im\ilp32
) else if /I "%TARGET%"=="rv32im_ofast_unroll" (
    set MULTIDIR=rv32im\ilp32
) else if /I "%TARGET%"=="rv32im_o3lto" (
    set MULTIDIR=rv32im\ilp32
) else if /I "%TARGET%"=="rv32im_o3unroll_lto" (
    set MULTIDIR=rv32im\ilp32
) else (
    set MULTIDIR=rv32i\ilp32
)

for /d %%D in ("!GCC_ROOT!\lib\gcc\riscv-none-elf\*") do (
    set GCC_VERSION_DIR=%%~fD
    goto :gcc_version_resolved
)
:gcc_version_resolved

if not defined GCC_VERSION_DIR (
    echo Missing GCC multilib root under !GCC_ROOT!\lib\gcc\riscv-none-elf
    exit /b 1
)

set LIBGCC_REF=!GCC_VERSION_DIR!\!MULTIDIR!\libgcc.a
set LIBM_REF=!GCC_ROOT!\riscv-none-elf\lib\!MULTIDIR!\libm.a

if not exist "!LIBGCC_REF!" (
    echo Missing libgcc for !MARCH!/!MABI!: !LIBGCC_REF!
    exit /b 1
)

if not exist "!LIBM_REF!" (
    echo Missing libm for !MARCH!/!MABI!: !LIBM_REF!
    exit /b 1
)

echo DEBUG: GCC=!GCC!
echo DEBUG: MARCH=!MARCH! MABI=!MABI!
echo DEBUG: OPT_FLAGS=!OPT_FLAGS!
echo DEBUG: MULTIDIR=!MULTIDIR!
echo DEBUG: LIBGCC_REF=!LIBGCC_REF!
echo DEBUG: LIBM_REF=!LIBM_REF!

if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"
if not exist "%GCC_TMP_DIR%" mkdir "%GCC_TMP_DIR%"
set TMP=%GCC_TMP_DIR%
set TEMP=%GCC_TMP_DIR%
set TMPDIR=%GCC_TMP_DIR%

%GCC% -march=%MARCH% -mabi=%MABI% -msmall-data-limit=0 !OPT_FLAGS! -ffreestanding -fno-builtin -nostdlib ^
    -Wl,--gc-sections ^
    -I "%PORT_DIR%" ^
    -I "%COREMARK_DIR%" ^
    -D!OPT_DEFINE! ^
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
    !LIBM_REF! !LIBGCC_REF!
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

