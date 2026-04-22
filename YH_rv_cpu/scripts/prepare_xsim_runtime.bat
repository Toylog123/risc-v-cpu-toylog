@echo off
setlocal

set TAG=%~1
if "%TAG%"=="" set TAG=default

rem Build the runtime path under the repo-level temp tree so tool outputs stay contained.
for %%I in ("%~dp0..") do set CPU_ROOT=%%~fI
for %%I in ("%CPU_ROOT%\..") do set REPO_ROOT=%%~fI
set SIM_ROOT=%REPO_ROOT%\_tmp\sim_runtime\%TAG%

if not exist "%SIM_ROOT%" mkdir "%SIM_ROOT%"

rem Use a timestamp plus randomness so repeated runs do not collide.
call :timestamp RUN_STAMP
set RUNTIME_DIR=%SIM_ROOT%\run_%RUN_STAMP%_%RANDOM%

mkdir "%RUNTIME_DIR%" >nul 2>nul
if errorlevel 1 (
    echo Failed to create xsim runtime directory: %RUNTIME_DIR%
    endlocal & exit /b 1
)

endlocal & set "%~2=%RUNTIME_DIR%"
exit /b 0

:timestamp
setlocal
set TS_VALUE=
rem PowerShell gives us a stable millisecond-resolution timestamp format on Windows.
for /f "usebackq delims=" %%T in (`powershell -NoProfile -Command "(Get-Date).ToString('yyyyMMdd_HHmmss_fff')"`) do set TS_VALUE=%%T
endlocal & set "%~1=%TS_VALUE%"
exit /b 0
