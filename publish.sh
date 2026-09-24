#!/usr/bin/env bash
set -e

ZIP_FILE=$(ls -t artifacts/*.zip 2>/dev/null | head -n 1)

if [ -z "$ZIP_FILE" ]; then
    echo "Error: No zip artifact found in artifacts/. Run ./build.sh first."
    exit 1
fi

echo "Publishing $ZIP_FILE to repository..."
python -m jprm repo add . "$ZIP_FILE" -u "https://github.com/GalaxyCatD3v/GalaxyTV-PFP-Updater"
