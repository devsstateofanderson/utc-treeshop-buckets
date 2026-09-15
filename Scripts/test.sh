#!/bin/zsh
# Run the BucketsTests XCTest bundle from the CLI. Exit status is xcodebuild's.
set -euo pipefail
ROOT="$(cd "$(dirname "${(%):-%x}")/.." && pwd)"
if [[ -z "${DEVELOPER_DIR:-}" && -d /Applications/Xcode.app/Contents/Developer ]]; then
  export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi
cd "$ROOT"
if [[ ! -d Buckets.xcodeproj || project.yml -nt Buckets.xcodeproj/project.pbxproj ]]; then
  xcodegen generate --quiet
fi
set +e
xcodebuild -project Buckets.xcodeproj -scheme Buckets -configuration Debug \
  -derivedDataPath "${BUCKETS_DERIVED_DATA:-$HOME/Library/Developer/Xcode/DerivedData/Buckets-cli}" -destination 'platform=macOS' test 2>&1 \
  | tee "$ROOT/build/test.log" \
  | grep -E "error:|failed|Test Suite 'All tests'|Executed|TEST (SUCCEEDED|FAILED)" | grep -v "^$"
STATUS=${pipestatus[1]}
set -e
exit $STATUS
