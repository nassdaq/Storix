#!/usr/bin/env bash
#
# Build Storix as a proper macOS .app bundle from the SwiftPM executable output.
# Ad-hoc codesigns the bundle so it can load entitlements (Full Disk Access prompt).
#
# Usage:  ./Scripts/bundle-app.sh [debug|release]
# Output: build/Storix.app
#
set -euo pipefail

CONFIG="${1:-release}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Storix"
BUNDLE_ID="galacha.industries.Storix"
BUILD_DIR="$ROOT/build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

echo "==> Building Swift package ($CONFIG)"
cd "$ROOT"
swift build -c "$CONFIG"

BIN_DIR="$(swift build -c "$CONFIG" --show-bin-path)"
EXECUTABLE="$BIN_DIR/$APP_NAME"

if [[ ! -x "$EXECUTABLE" ]]; then
    echo "ERROR: executable not found at $EXECUTABLE" >&2
    exit 1
fi

echo "==> Assembling $APP_BUNDLE"
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$EXECUTABLE" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
cp "$ROOT/App/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

# PkgInfo — traditional macOS marker.
printf "APPL????" > "$APP_BUNDLE/Contents/PkgInfo"

echo "==> Ad-hoc codesigning with entitlements"
codesign --force --deep \
    --sign - \
    --entitlements "$ROOT/App/Storix.entitlements" \
    --options runtime \
    "$APP_BUNDLE"

echo "==> Verifying signature"
codesign --verify --verbose "$APP_BUNDLE"

echo ""
echo "Built:    $APP_BUNDLE"
echo "Bundle:   $BUNDLE_ID"
echo "Launch:   open $APP_BUNDLE"
echo ""
echo "Note: on first launch, grant Full Disk Access:"
echo "  System Settings → Privacy & Security → Full Disk Access → add Storix"
