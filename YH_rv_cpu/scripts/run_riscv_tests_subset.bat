@echo off
setlocal EnableDelayedExpansion

for %%I in ("%~dp0..") do set PROJECT_DIR=%%~fI
for %%I in ("%PROJECT_DIR%\..") do set REPO_DIR=%%~fI
set BUILD_DIR=%PROJECT_DIR%\build\tests\riscv-tests
set EXTERNAL_DIR=%PROJECT_DIR%\build\external\riscv-tests
set TARGET=%~1
set TEST_OVERRIDE=%~2
set DEBUG_CYCLES=%~3
set MAX_CYCLES=%~4
set MANIFEST_OVERRIDE=%~5
set MARCH_OVERRIDE=%~6
set CONTINUE_ON_FAIL=%~7
set LINKER_SCRIPT_OVERRIDE=%~8
set TOHOST_ADDR_OVERRIDE=%~9
set TEST_MANIFEST=
set SUMMARY_FILE=
set CURRENT_TEST=
set TOTAL_TESTS=0
set PASSED_TESTS=0
set FAILED_TESTS=0
set FAILED_NAMES=
set START_TS=
set END_TS=
set FAIL_FAST=1
set LINKER_SCRIPT=
set TOHOST_ADDR=

if "%TARGET%"=="" set TARGET=rv32
if "%MAX_CYCLES%"=="" set MAX_CYCLES=40000
if "%TEST_OVERRIDE%"=="-" set TEST_OVERRIDE=
if "%DEBUG_CYCLES%"=="-" set DEBUG_CYCLES=
if "%MANIFEST_OVERRIDE%"=="-" set MANIFEST_OVERRIDE=
if "%MARCH_OVERRIDE%"=="-" set MARCH_OVERRIDE=
if "%LINKER_SCRIPT_OVERRIDE%"=="-" set LINKER_SCRIPT_OVERRIDE=
if "%TOHOST_ADDR_OVERRIDE%"=="-" set TOHOST_ADDR_OVERRIDE=
if /I "%CONTINUE_ON_FAIL%"=="continue" set FAIL_FAST=0
if /I "%CONTINUE_ON_FAIL%"=="0" set FAIL_FAST=0
if /I "%CONTINUE_ON_FAIL%"=="false" set FAIL_FAST=0

call "%~dp0prepare_riscv_tests.bat"
if errorlevel 1 exit /b 1

set GCC=
set OBJCOPY=
set XVLOG=
set XELAB=
set XSIM=
set PYTHON_CMD=
set USER_HOME=%USERPROFILE%
set RISCV_XPACK_ROOT=%USER_HOME%\AppData\Roaming\xPacks\@xpack-dev-tools\riscv-none-elf-gcc
set WORD_HEX_PY=%PROJECT_DIR%\scripts\make_word_hex.py
set XSIM_STAGE_DIR=%REPO_DIR%\_tmp\sim_runtime\%TARGET%
set XSIM_RUN_DIR=

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

call "%~dp0resolve_python.bat" PYTHON_CMD
if not defined PYTHON_CMD (
    echo Missing Python.
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
    set TEST_MANIFEST=%~dp0riscv_tests_rv64_baseline.txt
) else (
    set XLEN=32
    set MARCH=rv32i_zicsr
    set MABI=ilp32
    set TEST_TOP=YH_rv_cpu_riscv_tests_rv32_tb
    set TEST_MANIFEST=%~dp0riscv_tests_rv32_baseline.txt
)

if not "%MANIFEST_OVERRIDE%"=="" set TEST_MANIFEST=%MANIFEST_OVERRIDE%
if not "%MARCH_OVERRIDE%"=="" set MARCH=%MARCH_OVERRIDE%
set LINKER_SCRIPT=%PROJECT_DIR%\sw\linker\YH_rv_cpu_riscv_tests.ld
if not "%LINKER_SCRIPT_OVERRIDE%"=="" (
    set LINKER_SCRIPT=%LINKER_SCRIPT_OVERRIDE%
    if not "!LINKER_SCRIPT:~1,1!"==":" (
        for %%I in ("%REPO_DIR%\%LINKER_SCRIPT_OVERRIDE%") do set LINKER_SCRIPT=%%~fI
    )
)
set TOHOST_ADDR=0x00001000
if not "%TOHOST_ADDR_OVERRIDE%"=="" set TOHOST_ADDR=%TOHOST_ADDR_OVERRIDE%

call :load_test_manifest "%TEST_MANIFEST%" TEST_LIST
if errorlevel 1 exit /b 1

if not "%TEST_OVERRIDE%"=="" set TEST_LIST=%TEST_OVERRIDE%

if not exist "%BUILD_DIR%\%TARGET%" mkdir "%BUILD_DIR%\%TARGET%"
set SUMMARY_FILE=%BUILD_DIR%\%TARGET%\summary.txt
call :timestamp START_TS
> "%SUMMARY_FILE%" echo target=%TARGET%
>> "%SUMMARY_FILE%" echo manifest=%TEST_MANIFEST%
>> "%SUMMARY_FILE%" echo march=%MARCH%
>> "%SUMMARY_FILE%" echo linker_script=%LINKER_SCRIPT%
>> "%SUMMARY_FILE%" echo tohost_addr=%TOHOST_ADDR%
>> "%SUMMARY_FILE%" echo tests=%TEST_LIST%
if not "%TEST_OVERRIDE%"=="" >> "%SUMMARY_FILE%" echo override=%TEST_OVERRIDE%
if not "%DEBUG_CYCLES%"=="" >> "%SUMMARY_FILE%" echo debug_cycles=%DEBUG_CYCLES%
>> "%SUMMARY_FILE%" echo max_cycles=%MAX_CYCLES%
>> "%SUMMARY_FILE%" echo fail_fast=%FAIL_FAST%
>> "%SUMMARY_FILE%" echo started=%START_TS%

call "%~dp0prepare_xsim_runtime.bat" riscv_tests_%TARGET% XSIM_RUN_DIR
if not defined XSIM_RUN_DIR exit /b 1

pushd "%XSIM_RUN_DIR%"

call %XVLOG% --sv -i "%PROJECT_DIR%\rtl" ^
    "%PROJECT_DIR%\tb\YH_rv_cpu_riscv_tests_tb.v" ^
    "%PROJECT_DIR%\tb\YH_rv_cpu_riscv_tests_%TARGET%_tb.v" ^
    "%PROJECT_DIR%\rtl\YH_rv_cpu.v" ^
    "%PROJECT_DIR%\rtl\YH_rv_cpu_if_stage.v" ^
    "%PROJECT_DIR%\rtl\YH_rv_cpu_id_stage.v" ^
    "%PROJECT_DIR%\rtl\YH_rv_cpu_ex_stage.v" ^
    "%PROJECT_DIR%\rtl\YH_rv_cpu_mem_stage.v" ^
    "%PROJECT_DIR%\rtl\YH_rv_cpu_wb_stage.v" ^
    "%PROJECT_DIR%\rtl\YH_rv_cpu_hazard_unit.v" ^
    "%PROJECT_DIR%\rtl\YH_rv_cpu_decoder.v" ^
    "%PROJECT_DIR%\rtl\YH_rv_cpu_regfile.v" ^
    "%PROJECT_DIR%\rtl\YH_rv_cpu_alu.v"
if errorlevel 1 goto :fail

for %%N in (%TEST_LIST%) do (
    set /a TOTAL_TESTS+=1
    set CURRENT_TEST=%%N
    set TEST_OK=1
    set TEST_SRC=%EXTERNAL_DIR%\isa\%TARGET%ui\%%N.S
    set TEST_ELF=%BUILD_DIR%\%TARGET%\%%N.elf
    set TEST_BIN=%BUILD_DIR%\%TARGET%\%%N.bin
    set TEST_HEX=%BUILD_DIR%\%TARGET%\%%N.hex
    set TEST_MEM32_HEX=%BUILD_DIR%\%TARGET%\%%N.mem32.hex
    set TEST_PREP_LOG=%BUILD_DIR%\%TARGET%\%%N.xelab.log
    set TEST_LOG=%BUILD_DIR%\%TARGET%\%%N.log

    echo Running %TARGET%ui/%%N ...

    %GCC% -march=%MARCH% -mabi=%MABI% -mno-relax -nostdlib -static -mcmodel=medany -ffreestanding -Os ^
        -I "%PROJECT_DIR%\sw\riscv-tests-env" ^
        -I "%EXTERNAL_DIR%\isa\macros\scalar" ^
        -T "%LINKER_SCRIPT%" ^
        -o "!TEST_ELF!" ^
        "!TEST_SRC!"
    if errorlevel 1 set TEST_OK=0

    if "!TEST_OK!"=="1" (
        %OBJCOPY% -O verilog "!TEST_ELF!" "!TEST_HEX!"
        if errorlevel 1 set TEST_OK=0
    )

    if "!TEST_OK!"=="1" (
        %OBJCOPY% -O binary "!TEST_ELF!" "!TEST_BIN!"
        if errorlevel 1 set TEST_OK=0
    )

    if "!TEST_OK!"=="1" (
        %PYTHON_CMD% "%WORD_HEX_PY%" "!TEST_BIN!" "!TEST_MEM32_HEX!"
        if errorlevel 1 set TEST_OK=0
    )

    if "!TEST_OK!"=="1" (
        copy /y "!TEST_HEX!" "%BUILD_DIR%\current.hex" >nul
        if errorlevel 1 set TEST_OK=0
    )

    if "!TEST_OK!"=="1" (
        copy /y "!TEST_MEM32_HEX!" "%BUILD_DIR%\current.mem32.hex" >nul
        if errorlevel 1 set TEST_OK=0
    )

    if "!TEST_OK!"=="1" (
        call %XELAB% %TEST_TOP% -s %TEST_TOP%_snapshot > "!TEST_PREP_LOG!" 2>&1
        if errorlevel 1 set TEST_OK=0
    )

    if "!TEST_OK!"=="1" (
        if not "%DEBUG_CYCLES%"=="" (
            if not exist "build\tests\riscv-tests\%TARGET%" mkdir "build\tests\riscv-tests\%TARGET%"
            copy /y "!TEST_HEX!" "build\tests\riscv-tests\%TARGET%\%%N.hex" >nul
            if errorlevel 1 set TEST_OK=0
            if "!TEST_OK!"=="1" call %XSIM% %TEST_TOP%_snapshot -testplusarg "hex=build/tests/riscv-tests/%TARGET%/%%N.hex" -testplusarg "test_name=%%N" -testplusarg "max_cycles=%MAX_CYCLES%" -testplusarg "debug_cycles=%DEBUG_CYCLES%" -testplusarg "tohost_addr=%TOHOST_ADDR%" -runall > "!TEST_LOG!" 2>&1
        ) else (
            if not exist "build\tests\riscv-tests\%TARGET%" mkdir "build\tests\riscv-tests\%TARGET%"
            copy /y "!TEST_HEX!" "build\tests\riscv-tests\%TARGET%\%%N.hex" >nul
            if errorlevel 1 set TEST_OK=0
            if "!TEST_OK!"=="1" call %XSIM% %TEST_TOP%_snapshot -testplusarg "hex=build/tests/riscv-tests/%TARGET%/%%N.hex" -testplusarg "test_name=%%N" -testplusarg "max_cycles=%MAX_CYCLES%" -testplusarg "tohost_addr=%TOHOST_ADDR%" -runall > "!TEST_LOG!" 2>&1
        )
        if "!TEST_OK!"=="1" (
            type "!TEST_LOG!"
            findstr /c:"PASS: riscv-tests finished" "!TEST_LOG!" >nul
            if errorlevel 1 set TEST_OK=0
        )
    )

    if "!TEST_OK!"=="1" (
        set /a PASSED_TESTS+=1
        >> "%SUMMARY_FILE%" echo PASS %%N
    ) else (
        set /a FAILED_TESTS+=1
        if defined FAILED_NAMES (
            set FAILED_NAMES=!FAILED_NAMES! %%N
        ) else (
            set FAILED_NAMES=%%N
        )
        >> "%SUMMARY_FILE%" echo FAIL %%N
        if "!FAIL_FAST!"=="1" goto :fail
    )
)

if "!FAILED_TESTS!"=="0" (
    echo PASS: all %TARGET% subset tests completed.
    >> "%SUMMARY_FILE%" echo result=PASS
    >> "%SUMMARY_FILE%" echo passed=!PASSED_TESTS!/!TOTAL_TESTS!
    call :timestamp END_TS
    >> "%SUMMARY_FILE%" echo finished=!END_TS!
    echo Summary:
    echo   %SUMMARY_FILE%
    set RUN_STATUS=0
) else (
    echo FAIL: %TARGET% subset tests failed !FAILED_TESTS!/!TOTAL_TESTS! tests.
    >> "%SUMMARY_FILE%" echo result=FAIL
    >> "%SUMMARY_FILE%" echo passed=!PASSED_TESTS!/!TOTAL_TESTS!
    >> "%SUMMARY_FILE%" echo failed_tests=!FAILED_NAMES!
    call :timestamp END_TS
    >> "%SUMMARY_FILE%" echo finished=!END_TS!
    echo Summary:
    echo   %SUMMARY_FILE%
    set RUN_STATUS=1
)
goto :done

:fail
set RUN_STATUS=%ERRORLEVEL%
if "%RUN_STATUS%"=="0" set RUN_STATUS=1
if defined CURRENT_TEST (
    >> "%SUMMARY_FILE%" echo FAIL !CURRENT_TEST!
)
>> "%SUMMARY_FILE%" echo result=FAIL
>> "%SUMMARY_FILE%" echo passed=!PASSED_TESTS!/!TOTAL_TESTS!
if defined FAILED_NAMES >> "%SUMMARY_FILE%" echo failed_tests=!FAILED_NAMES!
call :timestamp END_TS
>> "%SUMMARY_FILE%" echo finished=%END_TS%
echo Summary:
echo   %SUMMARY_FILE%

:done
popd
exit /b %RUN_STATUS%

:timestamp
setlocal
set TS_VALUE=
for /f "usebackq delims=" %%T in (`powershell -NoProfile -Command "(Get-Date).ToString('yyyy-MM-ddTHH:mm:ssK')"`) do set TS_VALUE=%%T
endlocal & set "%~1=%TS_VALUE%"
exit /b 0

:load_test_manifest
setlocal EnableDelayedExpansion
set "MANIFEST_PATH=%~1"
set "MANIFEST_TESTS="
if not exist "%MANIFEST_PATH%" (
    echo Missing test manifest: %MANIFEST_PATH%
    endlocal & exit /b 1
)
for /f "usebackq eol=# delims=" %%L in ("%MANIFEST_PATH%") do (
    if defined MANIFEST_TESTS (
        set "MANIFEST_TESTS=!MANIFEST_TESTS! %%L"
    ) else (
        set "MANIFEST_TESTS=%%L"
    )
)
endlocal & set "%~2=%MANIFEST_TESTS%"
exit /b 0

