#!/bin/zsh
# Launch the built app with a forced appearance, capture its window, quit.
# Usage: Scripts/screenshot.sh light|dark [screen] [output.png] [--fixture] [--render]
#   screen: optional name passed to the app as BUCKETS_SCREEN so it opens on that screen
#           (buckets | labor | equipment | materials | consumables | overhead | laborcalc | equipmentcalc |
#           projects | project | settings); default is the app's normal start.
#   --render: instead of screencapture, have the app render its windows offscreen (BUCKETS_SNAPSHOT_DIR)
#           and write the sheet if one is open, else the main window's content. Works with the screen locked.
#   --fixture: run the app against a throwaway store holding the BRIEF §3.3 rows, written by the
#           FixtureStoreWriter test (test target only; the app never seeds data). Reused if present;
#           set BUCKETS_FIXTURE=fresh to rewrite it.
# Requires Screen Recording permission for the terminal host.
set -euo pipefail
ROOT="$(cd "$(dirname "${(%):-%x}")/.." && pwd)"
if [[ -z "${DEVELOPER_DIR:-}" && -d /Applications/Xcode.app/Contents/Developer ]]; then
  export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi
FIXTURE=0
RENDER=0
ARGS=()
for a in "$@"; do
  if [[ "$a" == "--fixture" ]]; then FIXTURE=1
  elif [[ "$a" == "--render" ]]; then RENDER=1
  else ARGS+=("$a"); fi
done
MODE="${ARGS[1]:-light}"
SCREEN="${ARGS[2]:-}"
OUT="${ARGS[3]:-$ROOT/build/screenshots/${SCREEN:-app}-$MODE.png}"
APP="$ROOT/build/Buckets.app"
[[ -d "$APP" ]] || APP="$("$ROOT/Scripts/build.sh" | tail -1)"
mkdir -p "$(dirname "$OUT")" "$ROOT/build"
WIDTOOL="$ROOT/build/window-id"
if [[ ! -x "$WIDTOOL" || "$ROOT/Scripts/window-id.swift" -nt "$WIDTOOL" ]]; then
  swiftc -O "$ROOT/Scripts/window-id.swift" -o "$WIDTOOL"
fi
STORE_ENV=()
if [[ $FIXTURE -eq 1 ]]; then
  FIXTURE_STORE="$ROOT/build/fixture/Buckets.store"
  if [[ ! -f "$FIXTURE_STORE" || "${BUCKETS_FIXTURE:-}" == "fresh" ]]; then
    mkdir -p "$(dirname "$FIXTURE_STORE")"
    ( cd "$ROOT" && TEST_RUNNER_BUCKETS_FIXTURE_STORE="$FIXTURE_STORE" xcodebuild -project Buckets.xcodeproj -scheme Buckets \
        -configuration Debug -derivedDataPath "${BUCKETS_DERIVED_DATA:-$HOME/Library/Developer/Xcode/DerivedData/Buckets-cli}" \
        -destination 'platform=macOS' test -only-testing:BucketsTests/FixtureStoreWriter 2>&1 \
        | grep -E "error:|TEST (SUCCEEDED|FAILED)" ) || true
    [[ -f "$FIXTURE_STORE" ]] || { echo "fixture store was not written" >&2; exit 1; }
  fi
  STORE_ENV=(BUCKETS_STORE="$FIXTURE_STORE")
fi
if [[ $RENDER -eq 1 ]]; then
  SNAP="$ROOT/build/snapshot"
  rm -rf "$SNAP"; mkdir -p "$SNAP"
  env BUCKETS_APPEARANCE="$MODE" ${SCREEN:+BUCKETS_SCREEN="$SCREEN"} "${STORE_ENV[@]}" BUCKETS_SNAPSHOT_DIR="$SNAP" \
    "$APP/Contents/MacOS/Buckets" &
  PID=$!
  for _ in {1..80}; do kill -0 "$PID" 2>/dev/null || break; sleep 0.25; done
  kill "$PID" 2>/dev/null || true; wait "$PID" 2>/dev/null || true
  if [[ -f "$SNAP/sheet.png" ]]; then mv "$SNAP/sheet.png" "$OUT"
  elif [[ -f "$SNAP/main.png" ]]; then mv "$SNAP/main.png" "$OUT"
  else echo "the app wrote no snapshot" >&2; exit 1; fi
  echo "$OUT"
  exit 0
fi
env BUCKETS_APPEARANCE="$MODE" ${SCREEN:+BUCKETS_SCREEN="$SCREEN"} "${STORE_ENV[@]}" "$APP/Contents/MacOS/Buckets" &
PID=$!
WID=""
for _ in {1..60}; do
  WID="$("$WIDTOOL" "$PID" 2>/dev/null || true)"
  [[ -n "$WID" ]] && break
  sleep 0.25
done
if [[ -z "$WID" ]]; then kill "$PID" 2>/dev/null || true; echo "no Buckets window appeared" >&2; exit 1; fi
sleep "${BUCKETS_SCREENSHOT_SETTLE:-1.5}"
HEIGHT=0
for _ in {1..5}; do
  screencapture -x -o -l"$WID" "$OUT"
  HEIGHT="$(sips -g pixelHeight "$OUT" 2>/dev/null | awk '/pixelHeight/ { print $2 }')"
  [[ "${HEIGHT:-0}" -ge 100 ]] && break
  sleep 0.5
  WID="$("$WIDTOOL" "$PID" 2>/dev/null || echo "$WID")"
done
kill "$PID" 2>/dev/null || true; wait "$PID" 2>/dev/null || true
if [[ "${HEIGHT:-0}" -lt 100 ]]; then echo "capture is ${HEIGHT:-0} px tall; rerun" >&2; exit 1; fi
echo "$OUT"
