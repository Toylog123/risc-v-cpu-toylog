@echo off
setlocal

set TAG=%~1
if "%TAG%"=="" set TAG=default

for %%I in ("%~dp0..") do set CPU_ROOT=%%~fI
for %%I in ("%CPU_ROOT%\..") do set REPO_ROOT=%%~fI
set TMP_DIR=%REPO_ROOT%\_tmp
set SIM_DIR=%TMP_DIR%\sim_runtime\%TAG%
set LOG_DIR=%TMP_DIR%\tool_logs\xsim\%TAG%

if not exist "%SIM_DIR%" mkdir "%SIM_DIR%"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

if exist "%CPU_ROOT%\xsim.dir" move /y "%CPU_ROOT%\xsim.dir" "%SIM_DIR%" >nul

for %%F in ("%CPU_ROOT%\dfx_runtime.txt" "%CPU_ROOT%\xelab.log" "%CPU_ROOT%\xelab.pb" "%CPU_ROOT%\xsim.jou" "%CPU_ROOT%\xsim.log" "%CPU_ROOT%\xvlog.log" "%CPU_ROOT%\xvlog.pb" "%CPU_ROOT%\xsim_*.backup.jou" "%CPU_ROOT%\xsim_*.backup.log") do (
    if exist "%%~fF" move /y "%%~fF" "%LOG_DIR%" >nul
)

exit /b 0
