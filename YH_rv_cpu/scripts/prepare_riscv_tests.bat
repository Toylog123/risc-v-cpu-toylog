@echo off
setlocal

for %%I in ("%~dp0..") do set PROJECT_DIR=%%~fI
set EXTERNAL_DIR=%PROJECT_DIR%\build\external\riscv-tests

where git >nul 2>nul
if errorlevel 1 (
    echo Missing git.
    exit /b 1
)

if exist "%EXTERNAL_DIR%\.git" (
    echo riscv-tests already prepared:
    echo   %EXTERNAL_DIR%
    exit /b 0
)

if not exist "%PROJECT_DIR%\build\external" mkdir "%PROJECT_DIR%\build\external"

git clone --depth 1 https://github.com/riscv-software-src/riscv-tests.git "%EXTERNAL_DIR%"
if errorlevel 1 exit /b 1

echo Prepared:
echo   %EXTERNAL_DIR%
exit /b 0
