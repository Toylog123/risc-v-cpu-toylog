@echo off
setlocal

set PHYSICAL_SCRIPT_DIR=%~dp0
set MODE_HINT=%~1
if /I "%MODE_HINT%"=="-h" goto :usage
if /I "%MODE_HINT%"=="--help" goto :usage
if /I "%MODE_HINT%"=="/?" goto :usage
for %%I in ("%PHYSICAL_SCRIPT_DIR%..") do set CPU_ROOT=%%~fI
for %%I in ("%CPU_ROOT%\..") do set REPO_ROOT=%%~fI
set PROJECT_NAME=YH_rv_cpu_nexys_a7_100
set PROJECT_DIR=%REPO_ROOT%\project
set PROJECT_FILE=%PROJECT_DIR%\%PROJECT_NAME%.xpr
set TMP_ROOT=%REPO_ROOT%\_tmp
set USERDATA_ROOT=%TMP_ROOT%\vivado_user
set VIVADO_LOG_ROOT=%TMP_ROOT%\tool_logs\vivado
set VIVADO_LOG_FILE=%VIVADO_LOG_ROOT%\vivado_gui.log
set VIVADO_JOU_FILE=%VIVADO_LOG_ROOT%\vivado_gui.jou
set VIVADO_CMD=
set MAP_DRIVE=
set MAPPED_ROOT=
set MAP_DRIVES=V: W: X: Y: Z:

if not exist "%VIVADO_LOG_ROOT%" mkdir "%VIVADO_LOG_ROOT%"
if not exist "%USERDATA_ROOT%\profile" mkdir "%USERDATA_ROOT%\profile"
if not exist "%USERDATA_ROOT%\AppData\Roaming" mkdir "%USERDATA_ROOT%\AppData\Roaming"
if not exist "%USERDATA_ROOT%\AppData\Local" mkdir "%USERDATA_ROOT%\AppData\Local"
if not exist "%USERDATA_ROOT%\Temp" mkdir "%USERDATA_ROOT%\Temp"

set USERPROFILE=%USERDATA_ROOT%\profile
set HOME=%USERPROFILE%
set APPDATA=%USERDATA_ROOT%\AppData\Roaming
set LOCALAPPDATA=%USERDATA_ROOT%\AppData\Local
set TEMP=%USERDATA_ROOT%\Temp
set TMP=%USERDATA_ROOT%\Temp

for %%D in (%MAP_DRIVES%) do (
    subst %%D "%REPO_ROOT%" >nul 2>nul
    if not errorlevel 1 (
        set MAP_DRIVE=%%D
        set MAPPED_ROOT=%%D\
        goto :map_ready
    )
)

:map_ready
if not defined MAPPED_ROOT (
    echo Failed to map an ASCII drive for Vivado GUI. Please free one of V:/W:/X:/Y:/Z: and retry.
    exit /b 1
)

where vivado >nul 2>nul
if not errorlevel 1 (
    for /f "delims=" %%I in ('where vivado') do (
        set VIVADO_CMD=%%I
        goto :vivado_found
    )
)

for /d %%D in (D:\Vivado\20* C:\Xilinx\Vivado\20* D:\Xilinx\Vivado\20*) do (
    if exist "%%~fD\Vivado\bin\vivado.bat" (
        set VIVADO_CMD=%%~fD\Vivado\bin\vivado.bat
        goto :vivado_found
    )
    if exist "%%~fD\bin\vivado.bat" (
        set VIVADO_CMD=%%~fD\bin\vivado.bat
        goto :vivado_found
    )
)

:vivado_found
if not defined VIVADO_CMD (
    echo Missing vivado. Please install Vivado and ensure it is in PATH.
    exit /b 1
)

if not exist "%PROJECT_FILE%" (
    echo Local Vivado project missing. Generating project skeleton first...
    call "%PHYSICAL_SCRIPT_DIR%build_vivado_project.bat" project
    if errorlevel 1 exit /b 1
)

set PROJECT_FILE=%MAPPED_ROOT%project\%PROJECT_NAME%.xpr
if not exist "%PROJECT_FILE%" (
    echo Missing Vivado project file: %PROJECT_FILE%
    exit /b 1
)

call "%PHYSICAL_SCRIPT_DIR%organize_tool_logs.bat"

pushd "%MAPPED_ROOT%project"
start "Vivado GUI" "%VIVADO_CMD%" -log "%VIVADO_LOG_FILE%" -journal "%VIVADO_JOU_FILE%" "%PROJECT_FILE%"
popd

if defined MODE_HINT echo Requested flow hint: %MODE_HINT%
echo Vivado GUI started from %MAPPED_ROOT%project

echo Vivado logs: %VIVADO_LOG_ROOT%
echo Keep %MAP_DRIVE% mapped while Vivado is open. If needed, close Vivado first and then run: subst %MAP_DRIVE% /d
exit /b 0

:usage
echo Usage: %~nx0 [flow_hint]
echo.
echo The GUI always opens the Vivado project skeleton in the repository project\ directory.
echo flow_hint is optional and is only echoed back for operator context.
exit /b 0
