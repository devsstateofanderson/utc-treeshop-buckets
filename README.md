# Buckets

Sacred Tree Service's pricing app for the Mac. One job: price a project. Five flat lists (Labor, Equipment, Materials, Consumables, Overhead) of rows toggled on and off per project; hours in, price out.

The spec of record is [docs/BRIEF.md](docs/BRIEF.md). Every resolution of an ambiguity in it is one line in [docs/DECISIONS.md](docs/DECISIONS.md).

## Requirements

- macOS 15 or later to run. Built and verified on macOS 26.4 with Xcode 26.6.
- To build: Xcode (command line tools alone are not enough for SwiftData) and [xcodegen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`).

## Build, run, test

```bash
Scripts/build.sh        # generates Buckets.xcodeproj from project.yml, builds Debug, prints build/Buckets.app
Scripts/run.sh          # builds if needed, then opens the app
Scripts/test.sh         # runs the BucketsTests XCTest bundle from the CLI; exit status is xcodebuild's
Scripts/screenshot.sh light|dark [screen] [out.png] [--fixture] [--render]   # screen: buckets, labor, equipment, materials, consumables, overhead, laborcalc, equipmentcalc, projects, project, settings
```

The scripts regenerate the Xcode project whenever `project.yml` or anything under `Sources/` or `Tests/` changes, so add files freely and never edit the `.xcodeproj` by hand (it is not committed).

DerivedData lives in `~/Library/Developer/Xcode/DerivedData/Buckets-cli` (override with `BUCKETS_DERIVED_DATA`). It cannot live under `~/Desktop`: that folder is iCloud-synced on this Mac and the file provider adds Finder attributes to bundles mid-build, which makes codesign refuse them.

`Scripts/screenshot.sh --fixture` runs the app against a throwaway store under `build/fixture/` holding the brief's worked-example rows. That data is written by a test in the test target; the app itself never seeds anything. If iCloud is holding that folder (SQLite then blocks in `open(2)` on the directory fsync), point `BUCKETS_FIXTURE_STORE` at a path outside `~/Desktop`, e.g. `~/Library/Developer/Xcode/DerivedData/Buckets-cli/fixture/Buckets.store`.

`--render` asks the app itself to draw its windows offscreen (`BUCKETS_SNAPSHOT_DIR`) instead of using `screencapture`; it works while the screen is locked and it captures the window with its toolbar, or an open "Calculate…" sheet (`laborcalc`, `equipmentcalc`). `BUCKETS_WINDOW_SIZE=1180x1560` makes the window taller first so a long screen (the Project screen) renders past the fold; the display still caps the height. The sidebar's translucent material does not draw offscreen, so it comes out solid in these renders.

## Where the data is

One SwiftData store file:

```
~/Library/Application Support/Buckets/Buckets.store
```

SQLite keeps two sidecar files next to it, `Buckets.store-wal` and `Buckets.store-shm`. "Delete the store" means all three. The five settings live in the app's UserDefaults (`com.sacredtreeservice.buckets`). The app launches empty; there is no sample data anywhere in it.

Set `BUCKETS_STORE=/some/path.store` in the environment to run against a different file (the screenshot script does this).

## Export / Import JSON

Settings → **Export JSON** writes one file: format version, the five settings, every row in every bucket, and every project with its lines. Lines point at rows by their position in the file's row list, so the models carry no ids. Calculator inputs are embedded as readable JSON.

Settings → **Import JSON** replaces everything: after one confirmation, every row and project is deleted, the file's rows and projects are loaded, and the file's settings are applied. There is no merge. Export before importing if the current data matters.

## Layout

```
Sources/Core/     Pricer, LaborCalc, EquipmentCalc, Money, Bucket — Foundation only, pure functions
Sources/Models/   the three @Model classes, AppSettings, Store, Transfer (JSON)
Sources/Views/    the four screens and the shared fields
Sources/App/      app entry, navigation state, menu commands
Tests/            XCTest: every number in BRIEF §3.3 and §5.4, plus model and transfer rules
Scripts/          build.sh, run.sh, test.sh, screenshot.sh, window-id.swift
docs/             BRIEF.md (spec of record), DECISIONS.md
```
