@echo off
setlocal enabledelayedexpansion

set "ZIP_NAME="
for /f "delims=" %%I in ('dir /b /a-d /o-d "artifacts\*.zip" 2^>nul') do (
    set "ZIP_NAME=%%I"
    goto :found_zip
)

:found_zip
if "%ZIP_NAME%"=="" (
    echo Error: No zip file found in artifacts\.
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

if "%VERSION%"=="" (
    for /f "tokens=2 delims=_" %%V in ("%ZIP_NAME%") do (
        set "TEMP_VER=%%~nV"
        set "VERSION=!TEMP_VER!"
    )
)

if "%VERSION%"=="" (
    echo Error: Could not determine release version.
    exit /b 1
)

if "%VERSION:~0,1%"=="v" (
    set "TAG=%VERSION%"
) else if "%VERSION:~0,1%"=="V" (
    set "TAG=v%VERSION:~1%"
) else (
    set "TAG=v%VERSION%"
)

echo Preparing release %TAG% with artifact %ZIP_FILE%...

git add manifest.json galaxytv-pfp-updater\ jprm.yaml >nul 2>nul
git diff --cached --quiet
if %ERRORLEVEL% neq 0 (
    git commit -m "chore: release %TAG%"
    git push origin main
)

where gh >nul 2>nul
if %ERRORLEVEL% equ 0 (
    echo Creating/uploading release on GitHub using gh CLI...
    gh release create "%TAG%" "%ZIP_FILE%" --title "GalaxyTV PFP Updater %TAG%" --generate-notes
    if !ERRORLEVEL! neq 0 (
        gh release upload "%TAG%" "%ZIP_FILE%" --clobber
    )
) else (
    echo gh CLI not available. Creating and pushing git tag...
    git tag -a "%TAG%" -m "Release %TAG%"
    git push origin "%TAG%"
)

echo Release %TAG% processing complete.

endlocal
