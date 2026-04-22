@echo off
setlocal

for %%I in ("%~dp0..") do set CPU_ROOT=%%~fI
for %%I in ("%CPU_ROOT%\..") do set REPO_ROOT=%%~fI
set TMP_DIR=%REPO_ROOT%\_tmp
rem Consolidate simulator and Vivado logs under _tmp so the workspace root stays clean.
set SIM_ROOT=%TMP_DIR%\sim_runtime
set XSIM_LOG_ROOT=%TMP_DIR%\tool_logs\xsim
set VIVADO_LOG_ROOT=%TMP_DIR%\tool_logs\vivado
set CLOCK_DEBUG_ROOT=%VIVADO_LOG_ROOT%\clock_debug
set OUTER_PROJECT_DIR=%REPO_ROOT%\project

if not exist "%TMP_DIR%" mkdir "%TMP_DIR%"
if not exist "%XSIM_LOG_ROOT%" mkdir "%XSIM_LOG_ROOT%"
if not exist "%VIVADO_LOG_ROOT%" mkdir "%VIVADO_LOG_ROOT%"
if not exist "%CLOCK_DEBUG_ROOT%" mkdir "%CLOCK_DEBUG_ROOT%"

rem Sweep per-run xsim outputs into a stable archive directory keyed by runtime folder name.
for /d %%D in ("%SIM_ROOT%\*") do (
    if not exist "%XSIM_LOG_ROOT%\%%~nxD" mkdir "%XSIM_LOG_ROOT%\%%~nxD"
    for %%F in ("%%~fD\dfx_runtime.txt" "%%~fD\xelab.log" "%%~fD\xelab.pb" "%%~fD\xsim.jou" "%%~fD\xsim.log" "%%~fD\xvlog.log" "%%~fD\xvlog.pb" "%%~fD\xsim_*.backup.jou" "%%~fD\xsim_*.backup.log") do (
        if exist "%%~fF" move /y "%%~fF" "%XSIM_LOG_ROOT%\%%~nxD\" >nul
    )
)

rem Move root-level Vivado logs emitted by GUI or batch runs into the shared log directory.
for %%F in ("%CPU_ROOT%\vivado.log" "%CPU_ROOT%\vivado.jou" "%CPU_ROOT%\vivado_*.backup.log" "%CPU_ROOT%\vivado_*.backup.jou" "%REPO_ROOT%\vivado.log" "%REPO_ROOT%\vivado.jou" "%REPO_ROOT%\vivado_*.backup.log" "%REPO_ROOT%\vivado_*.backup.jou") do (
    if exist "%%~fF" move /y "%%~fF" "%VIVADO_LOG_ROOT%\" >nul
)

if exist "%OUTER_PROJECT_DIR%" (
    for %%F in ("%OUTER_PROJECT_DIR%\vivado.log" "%OUTER_PROJECT_DIR%\vivado.jou" "%OUTER_PROJECT_DIR%\vivado_*.backup.log" "%OUTER_PROJECT_DIR%\vivado_*.backup.jou") do (
        if exist "%%~fF" move /y "%%~fF" "%VIVADO_LOG_ROOT%\" >nul
    )
)

rem Preserve ad-hoc clock debug dumps separately so timing triage stays easy to navigate.
for %%F in ("%CPU_ROOT%\clockInfo.txt" "%REPO_ROOT%\clockInfo.txt" "%OUTER_PROJECT_DIR%\clockInfo.txt") do (
    if exist "%%~fF" move /y "%%~fF" "%CLOCK_DEBUG_ROOT%\" >nul
)

rem Some tool runs still drop runtime breadcrumbs at repo root; collect them into one place.
for %%F in ("%CPU_ROOT%\dfx_runtime.txt" "%REPO_ROOT%\dfx_runtime.txt") do (
    if exist "%%~fF" (
        if not exist "%XSIM_LOG_ROOT%\root_runtime" mkdir "%XSIM_LOG_ROOT%\root_runtime"
        move /y "%%~fF" "%XSIM_LOG_ROOT%\root_runtime\" >nul
    )
)

exit /b 0
