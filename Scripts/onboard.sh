#!/bin/zsh
# Onboard a company onto this Mac's Buckets install in one pass (DECISIONS 78, 79):
#   Scripts/onboard.sh <company-profile.json> [catalog.json ...]
# 1. quits the app if it is running and backs up the live store to the vault,
# 2. applies the profile (and each catalog, rows only) through the app's own merge hook — never raw SQL,
# 3. writes a fresh export and prints the readiness picture from it,
# 4. relaunches the app.
# Profile template: Scripts/catalog/data/company-profile-template.json. Nothing in the profile is blanked by a null.
set -euo pipefail
ROOT="$(cd "$(dirname "${(%):-%x}")/.." && pwd)"
[[ $# -ge 1 ]] || { echo "usage: Scripts/onboard.sh <company-profile.json> [catalog.json ...]" >&2; exit 2; }
PROFILE="$1"; shift
APP="${BUCKETS_APP:-/Applications/Buckets.app}"
[[ -x "$APP/Contents/MacOS/Buckets" ]] || { echo "no app at $APP (set BUCKETS_APP)" >&2; exit 1; }
STORE_DIR="$HOME/Library/Application Support/Buckets"
VAULT="${BUCKETS_VAULT:-$HOME/Developer/sacred-tree-local-vault}/onboard-$(date +%Y-%m-%d-%H%M%S)"
mkdir -p "$VAULT"
BIN="$APP/Contents/MacOS/Buckets"

# 1. Quit and back up. The app saves on every edit, so TERM is a clean stop; the backup is all three store files.
if pgrep -f "$BIN" >/dev/null; then
  pkill -TERM -f "$BIN" || true
  for _ in {1..40}; do pgrep -f "$BIN" >/dev/null || break; sleep 0.25; done
fi
if [[ -f "$STORE_DIR/Buckets.store" ]]; then
  cp -p "$STORE_DIR"/Buckets.store* "$VAULT/"
  echo "backup: $VAULT"
else
  echo "no store yet: a new company on a fresh install"
fi

# 2. Apply through the launch hooks. Each launch merges one file, writes nothing else, and is stopped once the export lands.
apply() {
  local file="$1" export="$2"
  rm -f "$export"
  BUCKETS_MERGE_FILE="$file" BUCKETS_EXPORT_FILE="$export" "$BIN" >"$VAULT/launch-$(basename "$file" .json).log" 2>&1 &
  local pid=$!
  for _ in {1..120}; do [[ -s "$export" ]] && break; sleep 0.5; done
  sleep 1; kill -TERM $pid 2>/dev/null || true; wait $pid 2>/dev/null || true
  [[ -s "$export" ]] || { echo "the app wrote no export after $file; see $VAULT" >&2; exit 1; }
  grep -h 'BUCKETS_MERGE_FILE' "$VAULT/launch-$(basename "$file" .json).log" || true
}
apply "$PROFILE" "$VAULT/export-after-profile.json"
for catalog in "$@"; do apply "$catalog" "$VAULT/export-after-$(basename "$catalog" .json).json"; done
FINAL="$VAULT/export-final.json"
cp "$(ls -t "$VAULT"/export-after-*.json | head -1)" "$FINAL"

# 3. Readiness from the export: identity, rows per bucket, and how many rows still carry no confidence.
python3 - "$FINAL" <<'PY'
import json, sys, collections
d = json.load(open(sys.argv[1])); c = d.get("company") or {}
print("\n== company ==")
for k in ("name", "owner", "address", "phone", "email", "website", "serviceArea", "serviceRadiusMiles", "growingZone"):
    print(f"  {k:19s} {c.get(k) if c.get(k) not in (None, '') else '— not set'}")
active = [i for i in d["items"] if i.get("isActive", True)]
by = collections.Counter(i["bucket"] for i in active)
unres = collections.Counter(i["bucket"] for i in active if i.get("confidence") not in ("verified", "ownerConfirmed"))
print("== catalog (active rows / still unresolved) ==")
for b in ("labor", "equipment", "materials", "consumables", "subcontractors", "overhead"):
    print(f"  {b:15s} {by.get(b,0):4d} / {unres.get(b,0):4d}")
gates = {"Company name": bool(c.get("name")), "Service area": bool(c.get("serviceArea")) or (c.get("serviceRadiusMiles") or 0) > 0,
         "Labor rows": by.get("labor",0) > 0, "Equipment rows": by.get("equipment",0) > 0, "Overhead rows": by.get("overhead",0) > 0}
missing = [k for k, ok in gates.items() if not ok]
print("== readiness ==")
print("  " + ("NOT READY — setup inputs unresolved: " + ", ".join(missing) if missing else
             ("NEEDS REVIEW — %d active rows unresolved" % sum(unres.values()) if sum(unres.values()) else "READY")))
print(f"  export: {sys.argv[1]}")
PY

# 4. Back to normal.
open "$APP"
