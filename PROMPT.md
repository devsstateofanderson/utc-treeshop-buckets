ultracode

# Build "Buckets" — Sacred Tree Service's pricing app (macOS · SwiftUI · SwiftData)

## Layer 0 — What this is

You are building a small native Mac app called **Buckets** for Sacred Tree Service LLC (Apopka, FL tree service; owner Alexander Satoski). It prices a job. Nothing else. Five flat lists (Labor, Equipment, Materials, Consumables, Overhead) of rows that are toggled on/off per project; hours in, price out.

The spec of record is `~/Desktop/Buckets/docs/BRIEF.md`. Read it completely, start to finish, before doing anything else. This prompt is the operating instructions for executing against it. Where this prompt and BRIEF.md disagree, BRIEF.md wins.

Guiding phrase: **employee-level simple**. If a choice adds a screen, a table, or a concept the brief does not name, the answer is no.

This app replaces OO (`~/Desktop/OO`), which grew to 28K lines / 75 tables / 27 screens and never priced a single job. Do not read OO except the two files named in Layer 5. Do not port anything else from it.

## Layer 1 — Non-negotiable rules

1. **Scope fence** (BRIEF §5.1): no compliance, insurance, credentials, positions, vendors, subcontractor dossiers, loadouts, maintenance tracking, finance/ledger, integrations (Jobber/QuickBooks/Slack), import prompts, activity logs, lookup editors, price-history tables. If you find yourself writing a 4th `@Model` or a 5th screen, stop — you have left the brief.
2. **The math is exact** (BRIEF §1, §2.1, §2.2). `Pricer`, `LaborCalc`, `EquipmentCalc` are pure functions with no SwiftData/SwiftUI imports and must pass every number in Layer 7 before any UI is written.
3. **STS pricing rules live in code, not in settings UI**: markup applied once to the whole project, never per row; $750 minimum-job floor; 1×/2×/3× multiplier on the project; subcontractors (grapple truck, stump grinding, crane) are flat all-in **Consumables** rows, never decomposed, never shown as a line in any customer-facing output; disposal by the load.
4. **Rate snapshots**: a `ProjectLine` copies name/unit/rate when the row is turned on. Editing a bucket row never changes an existing project. "Re-price" refreshes on purpose.
5. **No sample, fake, or placeholder data** in the app or its store. The app launches empty. Fixtures live only in the test target.
6. **Money = Int cents. Math in `Decimal`.** Round half-away-from-zero once per displayed figure.
7. **Native SwiftUI only**: `NavigationSplitView`, `Table`, `Form`, `Toggle`, `TextField`, `Picker`. System semantic colors only — no hex, no custom palette, no custom fonts or point sizes. Light and dark must both be correct.
8. Say **"equipment."** The word "iron" never appears in UI, code, comments, or docs.
9. Fresh repo at `~/Desktop/Buckets` (the folder already holds `docs/BRIEF.md` and this prompt). Never modify `~/Desktop/OO` or `~/Desktop/sacred-tree-website`.

## Layer 2 — The math (BRIEF §1–2 is canonical; this is the shape)

```
Hourly = Σ Labor(on).rate + Σ Equipment(on).rate + Σ Overhead(on).rate ÷ billableHours
Cost   = Hourly × hours + Σ Materials(on).rate × qty + Σ Consumables(on).rate × qty
Price  = max( minimumJob , Cost × (1 + markup) × multiplier )
Profit = Price − Cost ;  Margin = Profit ÷ Price
```

`LaborCalc`: `rate = wage × (1 + burden) × paidHours ÷ billableHours`

`EquipmentCalc` (7 inputs + cost-of-money %): `depreciation + costOfMoney + insurance + fuelOil + repairs`, exactly as BRIEF §2.2, including the `AVF = 1 when N ≤ 1` guard and a hard error when salvage ≥ price or life ≤ 0.

Overhead rows store $/yr and are displayed and priced as $/yr ÷ billableHours.

## Layer 3 — Data model

Implement BRIEF §5.3 verbatim: `Bucket` enum (5 cases, fixed), `BucketItem`, `Project`, `ProjectLine` as the only three `@Model` classes. Settings via `@AppStorage`: `billableHoursPerYear` (1500), `laborBurdenPct` (30), `markupPct` (35), `minimumJobCents` (75000), `costOfMoneyPct` (0). Store at `~/Library/Application Support/Buckets/Buckets.store`.

## Layer 4 — Screens (BRIEF §5.5; four, no more)

1. **Buckets** — sidebar of 5 buckets → `Table` (Name · Rate · Unit · Active) → detail `Form`. Inline add ⌘N. Labor/Equipment/Overhead rows get a "Calculate…" sheet that saves its inputs to `calcInputs` so it reopens filled in. Delete only when unreferenced by any project; otherwise archive (`isActive = false`).
2. **Projects** — list: Name · Date · Hours · Price · Actual variance. New / Duplicate / Delete.
3. **Project** — this screen is the product. Sticky header: `Hours` field, multiplier picker, five bucket subtotals, Cost, Markup, **Price** (large), Profit + margin caption. Recomputes on every keystroke. Below: five collapsible sections of rows with a toggle (+ qty field on Materials/Consumables). New-project defaults: hourly rows **on**, quantity rows **off** with qty 1 when turned on. "Re-price." "Actuals": actual hours + actual qty per line → estimate-vs-actual table per bucket + total variance. "Copy price" (name + price only — customer-safe) and "Copy breakdown" (bucket subtotals — internal; still no line items).
4. **Settings** — the five fields + Export JSON / Import JSON (full round-trip of all three models).

## Layer 5 — Stack and repo

- macOS 15+, SwiftUI, SwiftData, no CloudKit. Swift 6 language mode if SwiftData cooperates; otherwise 5 mode — do not fight strict concurrency for a single-user local app.
- xcodegen `project.yml` → `Buckets.xcodeproj`. Targets: `Buckets` (app, bundle id `com.sacredtreeservice.buckets`, sign to run locally) and `BucketsTests` (XCTest).
- Layout: `Sources/Core/` (Pricer, LaborCalc, EquipmentCalc, Money — Foundation only), `Sources/Models/`, `Sources/Views/`, `Sources/App/`, `Tests/`, `Scripts/` (`build.sh`, `run.sh`, `test.sh`, `screenshot.sh`), `docs/BRIEF.md`, `docs/DECISIONS.md`, `README.md`.
- The only two OO files you may open: `~/Desktop/OO/docs/design/usace-methodology.md` §4.3 (the arithmetic — you are implementing the 7-input reduction in BRIEF §2.2, not the full USACE input set) and `~/Desktop/OO/Scripts/screenshot.sh` (both-appearance window-capture pattern; adapt, don't copy the OO-specific env vars).

## Layer 6 — How to run this under ultracode

Run one workflow per phase and read its result before starting the next. Report at the end of each phase in ≤ 10 lines.

**Phase A — Understand.** One agent reads BRIEF.md end to end and returns: every number in §3.3 as a test vector (cents), the exact row set for the worked example, and any contradiction or ambiguity it finds. Resolve contradictions using Layer 8; write each resolution as one line in `docs/DECISIONS.md`. Do not ask Alexander anything in this phase.

**Phase B — Core.** Scaffold the repo and implement `Sources/Core` + tests. Then an adversarial pass: three independent agents each try to break `Pricer` / `LaborCalc` / `EquipmentCalc` — zero hours, all rows off, qty 0, N ≤ 1, salvage ≥ price, life 0, rounding at exactly .5 cents, 2× with the floor, an overhead row of $0/yr, a project whose `BucketItem` was deleted. Every real failure becomes a test, then a fix. Core is done only when all Layer 7 numbers pass from the CLI.

**Phase C — App.** Models, then screens in BRIEF §5.6 order. After each screen: `Scripts/build.sh` succeeds, the app launches, both-appearance screenshots are captured and checked (an agent looks at the PNGs — truncated labels, clipped numbers, unreadable contrast are defects). No screen is done until this is true.

**Phase D — Verify through the UI.** Launch the built app. Enter the BRIEF §3.3 rows *through the UI* (never via seed code). Confirm the header reads **$2,501.50**; Miguel off → **$2,170.48**; Miguel on + skid steer on → **$2,674.62**; add Stump grinding (sub) qty 3 → **$3,039.12**. Enter actual hours 10 → variance appears. Export JSON, delete the store, relaunch, import, confirm identical. Then delete every row and project — the delivered app is empty.

**Phase E — Review.** One agent audits the tree against Layer 1: any concept not in BRIEF, any 4th model, any 5th screen, any hex color or hardcoded point size (`grep`), the word "iron" (`grep`), any seed data reachable at launch. Findings are fixed, not filed.

## Layer 7 — Definition of done (all must be true)

- Tests pass from the CLI (`Scripts/test.sh`):
  - `LaborCalc(wage: 3000, paidHours: 2080, burden: 0.30, billable: 1500) == 5408`
  - `EquipmentCalc(price: 6_500_000, salvage: 1_500_000, lifeHours: 8000, annualHours: 1500, fuelOilPerHour: 728, repairFactor: 0.80, insurancePerYear: 240_000, costOfMoney: 0.07) == 2372`
  - `Pricer` on the §3.3 project (billable 1500, markup 0.35, min 75000, ×1) `== 250150`; Miguel off `== 217048`; skid steer on `== 267462`; +3 stumps `== 303912`
  - floor: 1 hr × one $20/hr row `== 75000`; 2× multiplier doubles a price above the floor; snapshot test: mutate a `BucketItem.rateCents` after the line exists → project price unchanged
- `Scripts/build.sh` builds from a clean checkout; `Scripts/run.sh` launches; the app opens empty.
- Phase D reproduced every number through the real UI.
- Exactly 3 `@Model` classes, ≤ 4 screens, zero hex colors, zero "iron", zero data at launch.
- README: build / run / test, where the store is, how export/import works.
- `build/screenshots/` holds light + dark captures of all four screens.

## Layer 8 — Decisions already made (do not ask; log them in DECISIONS.md if you touch them)

- Markup is the input; margin is displayed beside it.
- Defaults: burden 30%, markup 35%, billable 1,500 hrs, minimum $750, cost of money 0% until Alexander enters a loan rate.
- Subcontractors (grapple truck, stump grinding, crane) are Consumables rows with unit per day / per job / per stump, flat all-in. STS does not own a stump grinder.
- Five buckets, fixed enum. No custom buckets.
- One phase per project. Big jobs = duplicate and add. Named presets, phases, PDF, and iPad are v1.1 and are not to be built.
- App name "Buckets", bundle id `com.sacredtreeservice.buckets`.
- If SwiftData blocks you on something specific, fall back to one Codable JSON file at the same path — never GRDB/SQL.

Start with Phase A.
