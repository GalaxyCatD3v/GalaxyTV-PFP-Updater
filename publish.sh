#!/usr/bin/env bash
set -e

ZIP_FILE=$(ls -t artifacts/*.zip 2>/dev/null | head -n 1)

if [ -z "$ZIP_FILE" ]; then
    echo "Error: No zip artifact found in artifacts/. Run ./build.sh first."
    exit 1
fi

VERSION=""
if [ -f "jprm.yaml" ]; then
    VERSION=$(grep -E "^version:" jprm.yaml | head -n 1 | awk '{print $2}' | tr -d '\r"')
fi

if [ -z "$VERSION" ]; then
    FILENAME=$(basename "$ZIP_FILE" .zip)
    VERSION=$(echo "$FILENAME" | sed 's/.*_//')
fi

TAG="v${VERSION#v}"
ZIP_NAME=$(basename "$ZIP_FILE")
PLUGIN_URL="https://github.com/GalaxyCatD3v/GalaxyTV-PFP-Updater/releases/download/${TAG}/${ZIP_NAME}"

echo "Publishing $ZIP_FILE to repository (release URL: $PLUGIN_URL)..."
python -m jprm repo add . "$ZIP_FILE" -u "https://github.com/GalaxyCatD3v/GalaxyTV-PFP-Updater" -U "$PLUGIN_URL"
