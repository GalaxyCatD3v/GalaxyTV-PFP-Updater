@echo off
setlocal enabledelayedexpansion

set "ZIP_NAME="
for /f "delims=" %%I in ('dir /b /a-d /o-d "artifacts\*.zip" 2^>nul') do (
    set "ZIP_NAME=%%I"
    goto :found_zip
)

:found_zip
if "%ZIP_NAME%"=="" (
    echo Error: No zip artifact found in artifacts\. Run build.bat first.
    exit /b 1
)

set "ZIP_FILE=artifacts\%ZIP_NAME%"

echo Publishing %ZIP_FILE% to repository...
python -m jprm repo add . "%ZIP_FILE%" -u "https://github.com/GalaxyCatD3v/GalaxyTV-PFP-Updater"
if %ERRORLEVEL% neq 0 (
    echo Error: Publishing failed with error level %ERRORLEVEL%.
    exit /b %ERRORLEVEL%
)

endlocal
