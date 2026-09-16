#!/bin/zsh
# Package Buckets.app as a drag-to-Applications disk image. Usage: Scripts/package.sh [Release|Debug]
# Writes Dist/Buckets-<version>.dmg and prints its path as the last line.
set -euo pipefail
ROOT="$(cd "$(dirname "${(%):-%x}")/.." && pwd)"
CONFIG="${1:-Release}"
APP="$("$ROOT/Scripts/build.sh" "$CONFIG" | tail -1)"
[[ -d "$APP" ]] || { echo "no app at $APP" >&2; exit 1; }
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP/Contents/Info.plist")"
# Stage outside iCloud-synced folders (see build.sh) so the copy inside the image carries no Finder detritus.
DD="${BUCKETS_DERIVED_DATA:-$HOME/Library/Developer/Xcode/DerivedData/Buckets-cli}"
STAGE="$DD/dmg-stage"
rm -rf "$STAGE"; mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/Buckets.app"
xattr -cr "$STAGE/Buckets.app"
codesign --verify --deep --strict "$STAGE/Buckets.app"
ln -s /Applications "$STAGE/Applications"
mkdir -p "$ROOT/Dist"
DMG="$ROOT/Dist/Buckets-$VERSION.dmg"
rm -f "$DMG"
hdiutil create -volname "Buckets $VERSION" -srcfolder "$STAGE" -ov -format UDZO -quiet "$DMG"
rm -rf "$STAGE"
echo "$DMG"
