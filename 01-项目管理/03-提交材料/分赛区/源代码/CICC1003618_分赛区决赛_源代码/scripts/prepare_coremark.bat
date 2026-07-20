@echo off
setlocal

for %%I in ("%~dp0..") do set PROJECT_DIR=%%~fI
set EXTERNAL_DIR=%PROJECT_DIR%\build\external\coremark

if exist "%EXTERNAL_DIR%\README.md" (
    echo coremark already prepared:
    echo   %EXTERNAL_DIR%
    git -C "%EXTERNAL_DIR%" diff --quiet -- core_list_join.c core_main.c core_matrix.c core_state.c core_util.c coremark.h
    if errorlevel 1 (
        echo ERROR: EEMBC CoreMark benchmark source is dirty.
        echo        Restore the official source before running performance tests.
        exit /b 1
    )
    exit /b 0
)

where git >nul 2>nul
if errorlevel 1 (
    echo Missing git.
    exit /b 1
)

if not exist "%PROJECT_DIR%\build\external" mkdir "%PROJECT_DIR%\build\external"

git clone https://github.com/eembc/coremark.git "%EXTERNAL_DIR%"
if errorlevel 1 exit /b 1

echo Prepared coremark:
echo   %EXTERNAL_DIR%
exit /b 0
