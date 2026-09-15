#!/bin/zsh
# Run the BucketsTests XCTest bundle from the CLI. Exit status is xcodebuild's.
set -euo pipefail
ROOT="$(cd "$(dirname "${(%):-%x}")/.." && pwd)"
if [[ -z "${DEVELOPER_DIR:-}" && -d /Applications/Xcode.app/Contents/Developer ]]; then
  export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi
cd "$ROOT"
# Regenerate the project when project.yml or any file/folder under Sources or Tests changed.
if [[ ! -d Buckets.xcodeproj ]] || \
   [[ -n "$(find project.yml Sources Tests UITests -newer Buckets.xcodeproj/project.pbxproj -print -quit)" ]]; then
  xcodegen generate --quiet
fi
set +e
xcodebuild -project Buckets.xcodeproj -scheme Buckets -configuration Debug \
  -derivedDataPath "${BUCKETS_DERIVED_DATA:-$HOME/Library/Developer/Xcode/DerivedData/Buckets-cli}" -destination 'platform=macOS' test -skip-testing:BucketsUITests 2>&1 \
  | tee "$ROOT/build/test.log" \
  | grep -E "error:|failed|Test Suite 'All tests'|Executed|TEST (SUCCEEDED|FAILED)" | grep -v "^$"
STATUS=${pipestatus[1]}
set -e
exit $STATUS
