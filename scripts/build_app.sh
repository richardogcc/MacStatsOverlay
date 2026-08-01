#!/bin/bash
# Builds MacStatsOverlay.app into build/ from a release build.
# Injects Resources/Info.plist (version from VERSION) and Resources/AppIcon.icns.
# Usage: scripts/build_app.sh [--install]
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION=$(cat VERSION)
APP_NAME="MacStatsOverlay"
APP="build/$APP_NAME.app"

echo "==> Building $APP_NAME v$VERSION (release)"
swift build -c release

echo "==> Assembling app bundle"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp ".build/release/$APP_NAME" "$APP/Contents/MacOS/$APP_NAME"
sed "s/__VERSION__/$VERSION/g" Resources/Info.plist > "$APP/Contents/Info.plist"
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

echo "==> Signing (ad-hoc)"
codesign --force --sign - "$APP"
echo "Built $APP (v$VERSION)"

if [[ "${1:-}" == "--install" ]]; then
    echo "==> Installing to /Applications (replacing any previous version)"
    osascript -e 'tell application "Mac Stats Overlay" to quit' 2>/dev/null || true
    pkill -x "$APP_NAME" 2>/dev/null || true
    sleep 1
    rm -rf "/Applications/$APP_NAME.app"
    ditto "$APP" "/Applications/$APP_NAME.app"
    open "/Applications/$APP_NAME.app"
    echo "Installed and launched /Applications/$APP_NAME.app"
fi
