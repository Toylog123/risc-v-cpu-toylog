@echo off
setlocal

set STATUS=0
set RISCV_GCC=
set RISCV_OBJDUMP=
set RISCV_OBJCOPY=
set RTL_SIM=
set VIVADO_CMD=
set IVL_CMD=
set USER_HOME=%USERPROFILE%
set RISCV_XPACK_ROOT=%USER_HOME%\AppData\Roaming\xPacks\@xpack-dev-tools\riscv-none-elf-gcc
set IVL_SCOOP_ROOT=%USER_HOME%\scoop\apps\iverilog

echo [Required] RTL syntax tool
where iverilog >nul 2>nul
if errorlevel 1 (
    for /d %%D in ("%IVL_SCOOP_ROOT%\*") do (
        if exist "%%~fD\bin\iverilog.exe" (
            set IVL_CMD=%%~fD\bin\iverilog.exe
            goto :iverilog_done
        )
    )
    echo   MISSING: iverilog
    set STATUS=1
) else (
    for /f "delims=" %%I in ('where iverilog') do (
        set IVL_CMD=%%I
        goto :iverilog_done
    )
)
:iverilog_done
if defined IVL_CMD echo   FOUND: %IVL_CMD%

echo [Required] RISC-V compiler
for %%T in (riscv-none-elf-gcc riscv32-unknown-elf-gcc riscv64-unknown-elf-gcc) do (
    where %%T >nul 2>nul
    if not errorlevel 1 (
        set RISCV_GCC=%%T
        goto :gcc_done
    )
)
:gcc_done
if not defined RISCV_GCC (
    for /d %%D in ("%RISCV_XPACK_ROOT%\*") do (
        if exist "%%~fD\.content\bin\riscv-none-elf-gcc.exe" (
            set RISCV_GCC=%%~fD\.content\bin\riscv-none-elf-gcc.exe
            goto :gcc_echo
        )
    )
    echo   MISSING: riscv32-unknown-elf-gcc or riscv64-unknown-elf-gcc
    set STATUS=1
)
:gcc_echo
if defined RISCV_GCC echo   FOUND: %RISCV_GCC%

echo [Recommended] Binary utilities
for %%T in (riscv-none-elf-objdump riscv32-unknown-elf-objdump riscv64-unknown-elf-objdump) do (
    where %%T >nul 2>nul
    if not errorlevel 1 (
        set RISCV_OBJDUMP=%%T
        goto :objdump_done
    )
)
:objdump_done
if not defined RISCV_OBJDUMP (
    for /d %%D in ("%RISCV_XPACK_ROOT%\*") do (
        if exist "%%~fD\.content\bin\riscv-none-elf-objdump.exe" (
            set RISCV_OBJDUMP=%%~fD\.content\bin\riscv-none-elf-objdump.exe
            goto :objdump_echo
        )
    )
    echo   MISSING objdump
)
:objdump_echo
if defined RISCV_OBJDUMP echo   FOUND objdump: %RISCV_OBJDUMP%

for %%T in (riscv-none-elf-objcopy riscv32-unknown-elf-objcopy riscv64-unknown-elf-objcopy) do (
    where %%T >nul 2>nul
    if not errorlevel 1 (
        set RISCV_OBJCOPY=%%T
        goto :objcopy_done
    )
)
:objcopy_done
if not defined RISCV_OBJCOPY (
    for /d %%D in ("%RISCV_XPACK_ROOT%\*") do (
        if exist "%%~fD\.content\bin\riscv-none-elf-objcopy.exe" (
            set RISCV_OBJCOPY=%%~fD\.content\bin\riscv-none-elf-objcopy.exe
            goto :objcopy_echo
        )
    )
    echo   MISSING objcopy
)
:objcopy_echo
if defined RISCV_OBJCOPY echo   FOUND objcopy: %RISCV_OBJCOPY%

echo [Recommended] Functional simulator
for %%T in (xsim vsim) do (
    where %%T >nul 2>nul
    if not errorlevel 1 (
        set RTL_SIM=%%T
        goto :sim_done
    )
)
for /d %%D in (D:\Vivado\20* C:\Xilinx\Vivado\20* D:\Xilinx\Vivado\20*) do (
    if exist "%%~fD\Vivado\bin\xsim.bat" (
        set RTL_SIM=%%~fD\Vivado\bin\xsim.bat
        goto :sim_done
    )
    if exist "%%~fD\bin\xsim.bat" (
        set RTL_SIM=%%~fD\bin\xsim.bat
        goto :sim_done
    )
)
:sim_done
if defined RTL_SIM (
    echo   FOUND simulator: %RTL_SIM%
) else (
    echo   MISSING xsim / vsim
)

echo [Recommended] FPGA tool
where vivado >nul 2>nul
if not errorlevel 1 (
    for /f "delims=" %%I in ('where vivado') do (
        set VIVADO_CMD=%%I
        goto :vivado_done
    )
)
for /d %%D in (D:\Vivado\20* C:\Xilinx\Vivado\20* D:\Xilinx\Vivado\20*) do (
    if exist "%%~fD\Vivado\bin\vivado.bat" (
        set VIVADO_CMD=%%~fD\Vivado\bin\vivado.bat
        goto :vivado_done
    )
    if exist "%%~fD\bin\vivado.bat" (
        set VIVADO_CMD=%%~fD\bin\vivado.bat
        goto :vivado_done
    )
)
:vivado_done
if defined VIVADO_CMD (
    echo   FOUND: %VIVADO_CMD%
) else (
    echo   MISSING: vivado
)

exit /b %STATUS%
