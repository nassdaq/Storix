#!/usr/bin/env bash
#
# Package Storix.app into a drag-to-Applications DMG.
# Depends on bundle-app.sh having produced build/Storix.app first.
#
# Usage:   ./Scripts/bundle-dmg.sh [version]
# Output:  build/Storix-<version>.dmg
#
set -euo pipefail

VERSION="${1:-$(date +%Y%m%d)}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT/build"
APP_BUNDLE="$BUILD_DIR/Storix.app"
DMG_PATH="$BUILD_DIR/Storix-$VERSION.dmg"
STAGING="$BUILD_DIR/dmg-staging"

if [[ ! -d "$APP_BUNDLE" ]]; then
    echo "==> Storix.app missing — running bundle-app.sh first"
    "$ROOT/Scripts/bundle-app.sh" release
fi

echo "==> Staging"
rm -rf "$STAGING" "$DMG_PATH"
mkdir -p "$STAGING"
cp -R "$APP_BUNDLE" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

echo "==> Creating DMG"
hdiutil create \
    -volname "Storix $VERSION" \
    -srcfolder "$STAGING" \
    -ov \
    -format UDZO \
    "$DMG_PATH" >/dev/null

rm -rf "$STAGING"

SIZE=$(du -h "$DMG_PATH" | cut -f1)
echo ""
echo "Built:  $DMG_PATH ($SIZE)"
