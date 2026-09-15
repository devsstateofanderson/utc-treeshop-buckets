#!/bin/zsh
# Build Buckets.app from the CLI. Usage: Scripts/build.sh [Debug|Release]
# Prints the path of the built .app as its last line.
set -euo pipefail
ROOT="$(cd "$(dirname "${(%):-%x}")/.." && pwd)"
if [[ -z "${DEVELOPER_DIR:-}" && -d /Applications/Xcode.app/Contents/Developer ]]; then
  export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi
CONFIG="${1:-Debug}"
# DerivedData lives outside iCloud-synced folders (Desktop is synced; the file provider adds
# Finder xattrs inside the bundle and codesign refuses "detritus"). Override with BUCKETS_DERIVED_DATA.
DD="${BUCKETS_DERIVED_DATA:-$HOME/Library/Developer/Xcode/DerivedData/Buckets-cli}"
cd "$ROOT"
if [[ ! -d Buckets.xcodeproj || project.yml -nt Buckets.xcodeproj/project.pbxproj ]]; then
  xcodegen generate --quiet
fi
mkdir -p "$ROOT/build"
set +e
xcodebuild -project Buckets.xcodeproj -scheme Buckets -configuration "$CONFIG" \
  -derivedDataPath "$DD" -destination 'platform=macOS' build 2>&1 \
  | tee "$ROOT/build/build.log" \
  | grep -E "error:|warning: [^M]|BUILD (SUCCEEDED|FAILED)" || true
STATUS=${pipestatus[1]}
set -e
[[ $STATUS -eq 0 ]] || { echo "xcodebuild failed ($STATUS); see build/build.log" >&2; exit $STATUS; }
APP="$DD/Build/Products/$CONFIG/Buckets.app"
[[ -d "$APP" ]] || { echo "build failed: $APP missing" >&2; exit 1; }
mkdir -p "$ROOT/build"
rm -rf "$ROOT/build/Buckets.app"
cp -R "$APP" "$ROOT/build/Buckets.app"
xattr -cr "$ROOT/build/Buckets.app" 2>/dev/null || true
echo "$ROOT/build/Buckets.app"
