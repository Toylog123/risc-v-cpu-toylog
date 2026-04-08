@echo off
setlocal

set SCRIPT_DIR=%~dp0
for %%I in ("%SCRIPT_DIR%..") do set PROJECT_DIR=%%~fI
set BUILD_DIR=%PROJECT_DIR%\build\sim
set XVLOG=
set XELAB=
set XSIM=
set XSIM_RUN_DIR=
set XSIM_TESTPLUSARGS=
set RAW_TESTPLUSARGS=

:parse_args
if "%~1"=="" goto :args_done
if defined RAW_TESTPLUSARGS (
    set RAW_TESTPLUSARGS=%RAW_TESTPLUSARGS% %~1
) else (
    set RAW_TESTPLUSARGS=%~1
)
shift
goto :parse_args
:args_done

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

if not defined XVLOG (
    echo Missing xvlog. Please install Vivado/xsim and ensure it is in PATH.
    exit /b 1
)

if not defined XELAB (
    echo Missing xelab. Please install Vivado/xsim and ensure it is in PATH.
    exit /b 1
)

if not defined XSIM (
    echo Missing xsim. Please install Vivado/xsim and ensure it is in PATH.
    exit /b 1
)

if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"

call "%SCRIPT_DIR%prepare_xsim_runtime.bat" fetch_prefetch_diag XSIM_RUN_DIR
if not defined XSIM_RUN_DIR exit /b 1

pushd "%XSIM_RUN_DIR%"

for /f "usebackq delims=" %%A in (`
    powershell -NoProfile -Command ^
        "$raw = $env:RAW_TESTPLUSARGS; " ^
        "if ([string]::IsNullOrWhiteSpace($raw)) { exit 0 } " ^
        "$out = @(); " ^
        "foreach ($token in ($raw -split '\s+')) { if ($token) { $out += '--testplusarg'; $out += $token } } " ^
        "$out -join ' '"
`) do set XSIM_TESTPLUSARGS=%%A

call %XVLOG% --sv -i "%PROJECT_DIR%\rtl" ^
    "%PROJECT_DIR%\tb\YH_rv_cpu_fetch_prefetch_tb.v" ^
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

call %XELAB% YH_rv_cpu_fetch_prefetch_tb -s YH_rv_cpu_fetch_prefetch_tb_snapshot
if errorlevel 1 goto :fail

call %XSIM% YH_rv_cpu_fetch_prefetch_tb_snapshot -runall %XSIM_TESTPLUSARGS%
set RUN_STATUS=%ERRORLEVEL%
goto :done

:fail
set RUN_STATUS=%ERRORLEVEL%

:done
popd
exit /b %RUN_STATUS%
