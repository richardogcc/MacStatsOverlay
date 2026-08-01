#!/bin/bash
# Builds the app, packages MacStatsOverlay-<VERSION>.dmg into dist/ and
# publishes a GitHub release for the version in VERSION.
# Usage: scripts/release.sh
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION=$(cat VERSION)
APP_NAME="MacStatsOverlay"
DMG="dist/$APP_NAME-$VERSION.dmg"

./scripts/build_app.sh

echo "==> Packaging $DMG"
mkdir -p dist
rm -f "$DMG"
STAGING=$(mktemp -d)
ditto "build/$APP_NAME.app" "$STAGING/$APP_NAME.app"
ln -s /Applications "$STAGING/Applications"
hdiutil create -volname "$APP_NAME" -srcfolder "$STAGING" -ov -format UDZO "$DMG"
rm -rf "$STAGING"

echo "==> Creating GitHub release v$VERSION"
NOTES=$(awk -v ver="$VERSION" '$0 ~ "^## "ver {flag=1; next} /^## / {flag=0} flag' CHANGELOG.md)
gh release create "v$VERSION" "$DMG" \
    --title "$APP_NAME $VERSION" \
    --notes "${NOTES:-Release $VERSION}"
echo "Release v$VERSION published."
