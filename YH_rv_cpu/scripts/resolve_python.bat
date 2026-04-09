@echo off
setlocal

set PYTHON_CMD=

for %%T in (python.exe python) do (
    for /f "delims=" %%I in ('where %%T 2^>nul') do (
        echo %%~fI | find /i "WindowsApps" >nul
        if errorlevel 1 (
            "%%~fI" --version >nul 2>nul
            if not errorlevel 1 (
                set PYTHON_CMD=%%~fI
                goto :done
            )
        )
    )
)

for %%I in (D:\APP\Anaconda\python.exe C:\Python311\python.exe C:\Python310\python.exe C:\Python39\python.exe) do (
    if exist "%%~fI" (
        "%%~fI" --version >nul 2>nul
        if not errorlevel 1 (
            set PYTHON_CMD=%%~fI
            goto :done
        )
    )
)

:done
endlocal & set "%~1=%PYTHON_CMD%"
exit /b 0
