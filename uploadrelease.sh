#!/usr/bin/env bash
set -e

ZIP_FILE=$(ls -t artifacts/*.zip 2>/dev/null | head -n 1)

if [ -z "$ZIP_FILE" ]; then
    echo "Error: No zip file found in artifacts/."
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

echo "Preparing release $TAG with artifact $ZIP_FILE..."

# Stage and commit repository manifest and distribution updates
git add manifest.json galaxytv-pfp-updater/ jprm.yaml 2>/dev/null || true
if ! git diff --cached --quiet; then
    git commit -m "chore: release $TAG"
    git push origin main || true
fi

# Create release and upload the zip artifact binary
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    echo "Creating/uploading release on GitHub using gh CLI..."
    gh release create "$TAG" "$ZIP_FILE" \
        --title "GalaxyTV PFP Updater $TAG" \
        --generate-notes || \
    gh release upload "$TAG" "$ZIP_FILE" --clobber || {
        echo "Warning: GitHub release upload failed, falling back to git tag."
        git tag -a "$TAG" -m "Release $TAG" 2>/dev/null || true
        git push origin "$TAG" 2>/dev/null || true
    }
else
    echo "gh CLI not available or not authenticated. Creating and pushing git tag..."
    git tag -a "$TAG" -m "Release $TAG" 2>/dev/null || true
    git push origin "$TAG" 2>/dev/null || true
fi

echo "Release $TAG processing complete."
