@echo off
setlocal

for %%I in ("%~dp0..\..") do set REPO_ROOT=%%~fI
for %%I in ("%~dp0..") do set CPU_ROOT=%%~fI
for %%I in ("%REPO_ROOT%\project") do set PROJECT_DIR=%%~fI
set TMP_ROOT=%REPO_ROOT%\_tmp

rem Exit quietly when the generated project tree does not exist yet.
if not exist "%PROJECT_DIR%" (
    echo Missing local Vivado project directory: %PROJECT_DIR%
    exit /b 0
)

rem Remove known Vivado scratch directories but leave reports and checkpoints intact.
for %%D in (".Xil" "2025.2" "tclapp" "reportstrategies" "strategies") do (
    if exist "%PROJECT_DIR%\%%~D" (
        rmdir /s /q "%PROJECT_DIR%\%%~D"
    )
)

rem Clean transient backup files from the generated project directory.
del /q "%PROJECT_DIR%\dfx_runtime.txt" >nul 2>nul
del /q "%PROJECT_DIR%\vivado_*.backup.jou" >nul 2>nul
del /q "%PROJECT_DIR%\vivado_*.backup.log" >nul 2>nul
del /q "%PROJECT_DIR%\vivado_synth_latest.log" >nul 2>nul

rem Clear temporary GUI user data that can grow across runs.
if exist "%TMP_ROOT%\vivado_user\Temp" (
    rmdir /s /q "%TMP_ROOT%\vivado_user\Temp"
)

rem Remove simulator scratch state from the CPU repo root.
if exist "%CPU_ROOT%\xsim.dir" (
    rmdir /s /q "%CPU_ROOT%\xsim.dir"
)

del /q "%CPU_ROOT%\dfx_runtime.txt" >nul 2>nul
del /q "%CPU_ROOT%\xelab.log" >nul 2>nul
del /q "%CPU_ROOT%\xelab.pb" >nul 2>nul
del /q "%CPU_ROOT%\xsim.jou" >nul 2>nul
del /q "%CPU_ROOT%\xsim.log" >nul 2>nul
del /q "%CPU_ROOT%\xvlog.log" >nul 2>nul
del /q "%CPU_ROOT%\xvlog.pb" >nul 2>nul
del /q "%CPU_ROOT%\xsim_*.backup.jou" >nul 2>nul
del /q "%CPU_ROOT%\xsim_*.backup.log" >nul 2>nul

echo Cleaned local Vivado and simulator temporary files.
echo Kept project reports, checkpoints, and _tmp tool logs for review.
exit /b 0
