@echo off
setlocal

echo [1/3] Building plugin...
call build.bat
if %ERRORLEVEL% neq 0 (
    echo Error: build.bat failed with exit code %ERRORLEVEL%.
    exit /b %ERRORLEVEL%
)

echo.
echo [2/3] Publishing repository manifest...
call publish.bat
if %ERRORLEVEL% neq 0 (
    echo Error: publish.bat failed with exit code %ERRORLEVEL%.
    exit /b %ERRORLEVEL%
)

echo.
echo [3/3] Uploading release...
call uploadrelease.bat
if %ERRORLEVEL% neq 0 (
    echo Error: uploadrelease.bat failed with exit code %ERRORLEVEL%.
    exit /b %ERRORLEVEL%
)

echo.
echo Deployment pipeline completed successfully.

endlocal
