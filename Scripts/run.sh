#!/bin/zsh
# Build (if needed) and launch Buckets.app. Usage: Scripts/run.sh
set -euo pipefail
ROOT="$(cd "$(dirname "${(%):-%x}")/.." && pwd)"
APP="$ROOT/build/Buckets.app"
[[ -d "$APP" ]] || APP="$("$ROOT/Scripts/build.sh" | tail -1)"
open "$APP"
