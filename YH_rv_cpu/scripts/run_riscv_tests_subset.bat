@echo off
setlocal EnableDelayedExpansion

for %%I in ("%~dp0..") do set PROJECT_DIR=%%~fI
set BUILD_DIR=%PROJECT_DIR%\build\tests\riscv-tests
set EXTERNAL_DIR=%PROJECT_DIR%\build\external\riscv-tests
set TARGET=%~1
set TEST_OVERRIDE=%~2
set DEBUG_CYCLES=%~3

if "%TARGET%"=="" set TARGET=rv32

call "%~dp0prepare_riscv_tests.bat"
if errorlevel 1 exit /b 1

set GCC=
set OBJCOPY=
set XVLOG=
set XELAB=
set XSIM=
set USER_HOME=%USERPROFILE%
set RISCV_XPACK_ROOT=%USER_HOME%\AppData\Roaming\xPacks\@xpack-dev-tools\riscv-none-elf-gcc

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

for %%T in (xvlog.bat xvlog) do (
    where %%T >nul 2>nul
    if not errorlevel 1 (
        set XVLOG=%%T
        goto :xvlog_done
    )
)
:xvlog_done

for %%T in (xelab.bat xelab) do (
    where %%T >nul 2>nul
    if not errorlevel 1 (
        set XELAB=%%T
        goto :xelab_done
    )
)
:xelab_done

for %%T in (xsim.bat xsim) do (
    where %%T >nul 2>nul
    if not errorlevel 1 (
        set XSIM=%%T
        goto :xsim_done
    )
)
:xsim_done

if not defined GCC (
    echo Missing RISC-V compiler.
    exit /b 1
)

if not defined OBJCOPY (
    echo Missing RISC-V objcopy.
    exit /b 1
)

if not defined XVLOG (
    echo Missing xvlog.
    exit /b 1
)

if not defined XELAB (
    echo Missing xelab.
    exit /b 1
)

if not defined XSIM (
    echo Missing xsim.
    exit /b 1
)

if /I "%TARGET%"=="rv64" (
    set XLEN=64
    set MARCH=rv64i_zicsr
    set MABI=lp64
    set TEST_TOP=YH_rv_cpu_riscv_tests_rv64_tb
    set TEST_LIST=add addi addiw addw ld lwu sd sll slli slliw sllw sra srai sraiw sraw srl srli srliw srlw sub subw
) else (
    set XLEN=32
    set MARCH=rv32i_zicsr
    set MABI=ilp32
    set TEST_TOP=YH_rv_cpu_riscv_tests_rv32_tb
    set TEST_LIST=add addi and andi auipc beq bne jal jalr lb lbu lh lhu lui lw or ori sb sh sll slli slt slti sltiu sltu sra srai srl srli sub sw xor xori
)

if not "%TEST_OVERRIDE%"=="" (
    set TEST_LIST=%TEST_OVERRIDE%
)

if not exist "%BUILD_DIR%\%TARGET%" mkdir "%BUILD_DIR%\%TARGET%"

pushd "%PROJECT_DIR%"

call %XVLOG% --sv -i rtl ^
    tb\YH_rv_cpu_riscv_tests_tb.v ^
    tb\YH_rv_cpu_riscv_tests_%TARGET%_tb.v ^
    rtl\YH_rv_cpu.v ^
    rtl\YH_rv_cpu_if_stage.v ^
    rtl\YH_rv_cpu_id_stage.v ^
    rtl\YH_rv_cpu_ex_stage.v ^
    rtl\YH_rv_cpu_mem_stage.v ^
    rtl\YH_rv_cpu_wb_stage.v ^
    rtl\YH_rv_cpu_hazard_unit.v ^
    rtl\YH_rv_cpu_decoder.v ^
    rtl\YH_rv_cpu_regfile.v ^
    rtl\YH_rv_cpu_alu.v
if errorlevel 1 goto :fail

call %XELAB% %TEST_TOP% -s %TEST_TOP%_snapshot
if errorlevel 1 goto :fail

for %%N in (%TEST_LIST%) do (
    set TEST_SRC=%EXTERNAL_DIR%\isa\%TARGET%ui\%%N.S
    set TEST_ELF=%BUILD_DIR%\%TARGET%\%%N.elf
    set TEST_HEX=%BUILD_DIR%\%TARGET%\%%N.hex
    set TEST_LOG=%BUILD_DIR%\%TARGET%\%%N.log

    echo Running %TARGET%ui/%%N ...

    %GCC% -march=%MARCH% -mabi=%MABI% -mno-relax -nostdlib -static -mcmodel=medany -ffreestanding -Os ^
        -I "%PROJECT_DIR%\sw\riscv-tests-env" ^
        -I "%EXTERNAL_DIR%\isa\macros\scalar" ^
        -T "%PROJECT_DIR%\sw\linker\YH_rv_cpu_riscv_tests.ld" ^
        -o "!TEST_ELF!" ^
        "!TEST_SRC!"
    if errorlevel 1 goto :fail

    %OBJCOPY% -O verilog "!TEST_ELF!" "!TEST_HEX!"
    if errorlevel 1 goto :fail

    copy /y "!TEST_HEX!" "%BUILD_DIR%\current.hex" >nul
    if errorlevel 1 goto :fail

    if not "%DEBUG_CYCLES%"=="" (
        call %XSIM% %TEST_TOP%_snapshot -testplusarg "hex=build/tests/riscv-tests/%TARGET%/%%N.hex" -testplusarg "max_cycles=40000" -testplusarg "debug_cycles=%DEBUG_CYCLES%" -runall > "!TEST_LOG!" 2>&1
    ) else (
        call %XSIM% %TEST_TOP%_snapshot -testplusarg "hex=build/tests/riscv-tests/%TARGET%/%%N.hex" -testplusarg "max_cycles=40000" -runall > "!TEST_LOG!" 2>&1
    )
    type "!TEST_LOG!"
    findstr /c:"PASS: riscv-tests finished" "!TEST_LOG!" >nul
    if errorlevel 1 goto :fail
)

echo PASS: all %TARGET% subset tests completed.
set RUN_STATUS=0
goto :done

:fail
set RUN_STATUS=%ERRORLEVEL%

:done
popd
exit /b %RUN_STATUS%
