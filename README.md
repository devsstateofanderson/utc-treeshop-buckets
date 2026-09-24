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

`--render` asks the app itself to draw its windows offscreen (`BUCKETS_SNAPSHOT_DIR`) instead of using `screencapture`; it works while the screen is locked and it captures the window with its toolbar, an open "Calculate…" sheet (`laborcalc`, `equipmentcalc`), or the Settings window (`settings`; drawn through a classic `NSHostingView` in a stand-in window, because the Settings scene's own window has nothing to draw offscreen while the app is in the background). `BUCKETS_WINDOW_SIZE=1180x1560` makes the window taller first so a long screen (the Project screen) renders past the fold; the display still caps the height. The sidebar's translucent material does not draw offscreen, so it comes out solid in these renders.

## What is in it (v0.2.0)

- **Company**: **Setup & readiness** first — the required setup inputs, catalog completion per bucket, and the unresolved rows grouped by reason with a jump to each (DECISIONS 73); then the profile (name, service area with its mileage radius and growing zone, address, licenses, three insurance policies with expirations), the pricing defaults (target margin, minimum job) and a documents shelf for COIs, policies and certifications with expiry warnings.
- **Buckets**: Labor, Equipment (with unit codes, make, model, year, serial), Materials, Consumables, Subcontractors (each sub with its own priced services), Overhead. Every row has a category, a product link, and a **Review** section — evidence, checked and review-due dates, confidence (missing · estimated · owner confirmed · verified), who approved it, an owner-confirmation flag and an assumption note (DECISIONS 72). Verified needs evidence and a checked date. Tables are searchable, sortable, and filter to the unresolved rows.
- **Projects**: the pricing screen. An enabled line whose row is unresolved carries a small warning and the header counts them; the price never changes because of it. **Packages** are saved projects to start jobs from; **Loadouts** are crew formations applied from the project's Crew menu.
- **Settings**: billable hours, labor burden and cost of money, plus Export JSON, Import JSON (replace) and Add or Update Rows (merge; a file may also carry the company profile, DECISIONS 78). Files are format 2; format-1 files from v1.x still read (DECISIONS 74). The target margin (default 50%) and the minimum job (default $750) are company defaults, set under Company → Pricing defaults; every new project and every Re-price copies them (DECISIONS 70).

Version numbering restarted at 0.2.0 with the first Buckets Pro release, after v1.1 (DECISIONS 75).

## TreeShop operating package

The current Buckets repository also contains the working launch package for the UTC / TreeShop operating model: [docs/treeshop/README.md](docs/treeshop/README.md). It covers the organization model, service packages, first-client launch, company MacBook setup, first-client Buckets configuration, and an access-register template. These documents are operational drafts for the first live installation and should be updated from evidence as the client is onboarded.

## Shared collaboration repository

The public repository is [devsstateofanderson/utc-treeshop-buckets](https://github.com/devsstateofanderson/utc-treeshop-buckets). Mr. J. Anderson owns UTC, TreeShop, and Buckets. Sacred Tree Service, owned by Alexander Satoski, is the first client installation. Codex handles planning and review; Claude Code handles customer-side implementation on the Sacred Tree Mac. Pull the latest `main` before work, use a focused branch, push the branch, and report the commit for review.

## Installing on another Mac

`Scripts/package.sh` builds the Release app and writes `Dist/Buckets-<version>.dmg` (the app plus an Applications shortcut). On the other Mac, open the image and drag Buckets to Applications.

The app is ad-hoc signed (no Apple Developer ID, so it is not notarized). The first launch on a Mac that did not build it is blocked by Gatekeeper: either open System Settings → Privacy & Security and click **Open Anyway** under the Buckets message, or clear the quarantine flag once from Terminal:

```bash
xattr -cr /Applications/Buckets.app
```

Data lives outside the app, in `~/Library/Application Support/Buckets/` (the store and the Documents folder). To carry the company's data over, copy that folder, or Export JSON here and Import JSON there (documents must be copied alongside; see DECISIONS 65).

## Editions and backups

- `Scripts/catalog/data/Buckets-default-catalog.json`: the blank commercial starting point (no labor or equipment, overhead as a $0 checklist, 112 materials and 57 consumables for professional tree work with links, and no company settings — DECISIONS 76–77). Load it with Add or Update Rows, or run the app once with `BUCKETS_MERGE_FILE` pointing at it.
- `Backups/`: dated folders with an Export JSON and the raw store files; see `Backups/README.txt`.

## Where the data is

One SwiftData store file:

```
~/Library/Application Support/Buckets/Buckets.store
```

SQLite keeps two sidecar files next to it, `Buckets.store-wal` and `Buckets.store-shm`. "Delete the store" means all three. Company documents are copied into `Documents/` next to the store. The five settings live in the app's UserDefaults (`com.sacredtreeservice.buckets`). The app launches empty; there is no sample data anywhere in it.

Launch hooks for scripting (the app never seeds data on its own): `BUCKETS_STORE=<path>` uses another store file, `BUCKETS_MERGE_FILE=<json>` runs Add or Update Rows on launch, `BUCKETS_EXPORT_FILE=<json>` writes an export on launch.

Set `BUCKETS_STORE=/some/path.store` in the environment to run against a different file (the screenshot script does this).

## Export / Import JSON

Settings → **Export JSON** writes one file: format version, the settings (including the target margin), every row in every bucket, and every project with its lines. Lines point at rows by their position in the file's row list, so the models carry no ids. Calculator inputs are embedded as readable JSON.

Settings → **Import JSON** replaces everything: after one confirmation, every row and project is deleted, the file's rows and projects are loaded, and the file's settings are applied. There is no merge. Export before importing if the current data matters.

## Layout

```
Sources/Core/     Pricer, LaborCalc, EquipmentCalc, Money, Bucket — Foundation only, pure functions
Sources/Models/   the three @Model classes, AppSettings, Store, Transfer (JSON)
Sources/Views/    the four screens and the shared fields
Sources/App/      app entry, navigation state, menu commands
Tests/            XCTest: every number in BRIEF §3.3 and §5.4, plus model, review, readiness, migration and transfer rules
Scripts/          build.sh, run.sh, test.sh, screenshot.sh, window-id.swift
docs/             BRIEF.md (spec of record), DECISIONS.md
```
