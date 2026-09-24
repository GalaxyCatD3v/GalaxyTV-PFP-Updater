@echo off
setlocal

echo Building plugin artifact...
python -m jprm plugin build .
if %ERRORLEVEL% neq 0 (
    echo Error: Build failed with error level %ERRORLEVEL%.
    exit /b %ERRORLEVEL%
)

endlocal
