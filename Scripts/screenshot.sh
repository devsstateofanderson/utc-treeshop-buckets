#!/bin/zsh
# Launch the built app with a forced appearance, capture its window, quit.
# Usage: Scripts/screenshot.sh light|dark [screen] [output.png]
#   screen: optional name passed to the app as BUCKETS_SCREEN so it opens on that screen
#           (buckets | projects | project | settings); default is the app's normal start.
# Requires Screen Recording permission for the terminal host.
set -euo pipefail
ROOT="$(cd "$(dirname "${(%):-%x}")/.." && pwd)"
if [[ -z "${DEVELOPER_DIR:-}" && -d /Applications/Xcode.app/Contents/Developer ]]; then
  export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi
MODE="${1:-light}"
SCREEN="${2:-}"
OUT="${3:-$ROOT/build/screenshots/${SCREEN:-app}-$MODE.png}"
APP="$ROOT/build/Buckets.app"
[[ -d "$APP" ]] || APP="$("$ROOT/Scripts/build.sh" | tail -1)"
mkdir -p "$(dirname "$OUT")" "$ROOT/build"
WIDTOOL="$ROOT/build/window-id"
if [[ ! -x "$WIDTOOL" || "$ROOT/Scripts/window-id.swift" -nt "$WIDTOOL" ]]; then
  swiftc -O "$ROOT/Scripts/window-id.swift" -o "$WIDTOOL"
fi
env BUCKETS_APPEARANCE="$MODE" ${SCREEN:+BUCKETS_SCREEN="$SCREEN"} "$APP/Contents/MacOS/Buckets" &
PID=$!
WID=""
for _ in {1..60}; do
  WID="$("$WIDTOOL" Buckets 2>/dev/null || true)"
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
  WID="$("$WIDTOOL" Buckets 2>/dev/null || echo "$WID")"
done
kill "$PID" 2>/dev/null || true; wait "$PID" 2>/dev/null || true
if [[ "${HEIGHT:-0}" -lt 100 ]]; then echo "capture is ${HEIGHT:-0} px tall; rerun" >&2; exit 1; fi
echo "$OUT"
