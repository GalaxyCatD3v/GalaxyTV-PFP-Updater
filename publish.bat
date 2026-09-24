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

set "VERSION="
if exist "jprm.yaml" (
    for /f "tokens=1,2*" %%A in ('findstr /r /c:"^[ ]*version:" jprm.yaml') do (
        if /i "%%A"=="version:" (
            set "VERSION=%%B"
        )
    )
)

if defined VERSION (
    set "VERSION=!VERSION:"=!"
)

if "!VERSION!"=="" (
    for /f "tokens=2 delims=_" %%V in ("%ZIP_NAME%") do (
        set "TEMP_VER=%%~nV"
        set "VERSION=!TEMP_VER!"
    )
)

if "!VERSION!"=="" (
    echo Error: Could not determine release version.
    exit /b 1
)

if "!VERSION:~0,1!"=="v" (
    set "TAG=!VERSION!"
) else if "!VERSION:~0,1!"=="V" (
    set "TAG=v!VERSION:~1!"
) else (
    set "TAG=v!VERSION!"
)

set "PLUGIN_URL=https://github.com/GalaxyCatD3v/GalaxyTV-PFP-Updater/releases/download/!TAG!/%ZIP_NAME%"

echo Publishing %ZIP_FILE% to repository (release URL: !PLUGIN_URL!)...
python -m jprm repo add . "%ZIP_FILE%" -u "https://github.com/GalaxyCatD3v/GalaxyTV-PFP-Updater" -U "!PLUGIN_URL!"
if %ERRORLEVEL% neq 0 (
    echo Error: Publishing failed with error level %ERRORLEVEL%.
    exit /b %ERRORLEVEL%
)

endlocal
