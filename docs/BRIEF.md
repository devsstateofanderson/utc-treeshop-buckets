# Buckets — Sacred Tree Service pricing app
## Spec of record (rules + Mac app build spec). Replaces OO.

---

## 0. What this is

One job: price a project. Five flat lists — **Labor, Equipment, Materials, Consumables, Overhead** — of rows that are toggled on/off per project. Hours in, price out. Employee-level simple: adding a row is like adding a contact; pricing a job is flipping switches and typing hours.

Every row is `{name, rate, unit, on/off}`. Only two kinds of rows exist:

| Row kind | Buckets | Contribution to a project |
|---|---|---|
| **Hourly** | Labor, Equipment, Overhead | `rate/hr × project hours` when on |
| **Quantity** | Materials, Consumables | `unit cost × qty` when on |

OO (`~/Desktop/OO`) needed 75 tables and 27 screens and never priced a job. This needs 3 models and 4 screens.

---

## 1. The pricing formula

```
Hourly   = Σ Labor(on) + Σ Equipment(on) + Σ Overhead(on)          $/hr
Cost     = Hourly × Hours + Σ Materials(on × qty) + Σ Consumables(on × qty)
Price    = max( MinimumJob , Cost × (1 + Markup%) × Multiplier )
Profit   = Price − Cost
Margin   = Profit ÷ Price          (display only)
```

Settings (set once):

| Setting | Default | Rule |
|---|---|---|
| Billable hours / year | 1,500 | crew project-hours per year; divides labor and overhead |
| Labor burden % | 30 | payroll tax + workers comp + benefits, as % of wage |
| Markup % | 35 | applied **once**, to the whole project, never per row (STS standing rule) |
| Minimum job | $750 | hard floor (STS standing rule) |
| Cost of money % | 0 | loan rate for financed equipment; 0 if cash |

Per project: `Multiplier` = 1× normal / 2× after-hours / 3× emergency (STS standing rule; one picker).

Markup vs margin: 35% markup = 25.9% margin. The input is markup ("add 35% on top"); the screen shows margin next to it so profit as a % of price is always visible.

---

## 2. Bucket rules

### 2.0 One number drives three buckets

`Billable hours / year` (1,500) is the crew's project-hours per year. It converts annual costs into $/hr in three places:

- Labor: annual burdened pay ÷ 1,500
- Overhead: annual cost ÷ 1,500
- Equipment: cost of money + insurance ÷ *that unit's* annual hours (default 1,500, override per row — a unit that runs 300 hrs/yr is under-recovered 5× at 1,500)

If STS goes to two crews this becomes 3,000 for overhead but stays 1,500 per employee. Not a v1 concern.

### 2.1 Labor

Row = employee name + rate per **project hour**. No titles, no positions, no ladder, no descriptions of what they do. They show up every day, so they get paid every day; the row's rate is the annual cost spread over the hours that can be billed:

```
Rate/project-hr = Wage × (1 + Burden%) × PaidHours/yr ÷ BillableHours/yr
Marcus: $30 × 1.30 × 2,080 ÷ 1,500 = $54.08/hr
```

The row stores `$54.08`. A "Calculate…" sheet on the row does the math from wage / paid hours (default 2,080) / burden (default from Settings). Day-to-day nobody sees the math.

Tree-service workers comp (FL class 0106) is heavy — burden of 25–45% is normal. Read the real number off the Southern Personnel Leasing invoice once.

| Labor | Wage | Rate/hr | On |
|---|---|---|---|
| Marcus | $30 | $54.08 | ✓ |
| David | $22 | $39.66 | ✓ |
| Miguel | $17 | $30.65 | ✓ |
| **Sum (all on)** | | **$124.39/hr** | |

### 2.2 Equipment

Row = anything STS **owns** worth ≥ $1,000 that goes to a jobsite. Under $1,000 is a consumable or overhead. Group small identical items into one row ("Chainsaws (3)"). Subcontracted equipment (grapple truck, crane, stump grinder) is **not** here — see §2.5.

Rate is computed from 7 inputs on a "Calculate…" sheet. This is the USACE EP 1110-1-8 core that OO researched and validated to the cent (`~/Desktop/OO/docs/design/usace-methodology.md` §4.3), with the 13 federal-contract index devices dropped and FOG folded into fuel:

| Input | Example (bucket truck) |
|---|---|
| Purchase price (delivered) | $65,000 |
| Salvage value | $15,000 |
| Economic life (hours) | 8,000 |
| Annual use (hours) | 1,500 (default; override per unit) |
| Fuel + oil ($/hr) | $7.28 |
| Repair factor (share of price spent on repairs over life) | 0.80 |
| Insurance + storage ($/yr) | $2,400 |

Plus Settings → cost of money % (7% in this example).

```
Depreciation = (Price − Salvage) ÷ LifeHours                        = $6.25
CostOfMoney  = Price × AVF × Rate ÷ AnnualHours                     = $2.09
               N = LifeHours ÷ AnnualHours
               AVF = ((N−1)(1 + Salvage/Price) + 2) ÷ 2N ;  AVF = 1 if N ≤ 1
Insurance    = Annual$ ÷ AnnualHours                                = $1.60
Fuel+oil     = as entered                                           = $7.28
Repairs      = Price × RepairFactor ÷ LifeHours                     = $6.50
Rate/hr      = sum                                                  = $23.72
```

Repair-factor defaults by type (USACE App. D, average conditions): trucks 0.65–0.75, chipper 0.90, skid steer 0.80, chainsaw 2.50 (saws cost more to repair than to buy), trailer 0.50. Economic life: saws 2,000 h, chipper 8,000, truck ≤10k GVW 8,000, bigger truck 10,000–12,000, skid steer 7,500.

Fuel lives here, not in Consumables. Diesel is never a consumable row.

| Equipment | Rate/hr | On |
|---|---|---|
| Bucket truck (50 ft) | $23.72 | ✓ |
| Chip truck (F-550) | $22.15 | ✓ |
| Chipper (12") — 1,000 hrs/yr | $17.11 | ✓ |
| Chainsaws (3) | $7.50 | ✓ |
| Mini skid steer — 500 hrs/yr | $16.03 | ○ |
| **Sum (on)** | **$70.48/hr** | |

Maintenance scheduling (odometer, hour meter, service intervals) is **not pricing** and is not in this app. Optional: one "current meter" field per row so a unit past its economic life is visible.

### 2.3 Overhead

Row = one annual cost. The app shows it as $/hr = annual ÷ billable hours. Enter the year's budget line by line so one line can be updated when it changes.

Goes here: GL/umbrella insurance, phones, internet, website, marketing, software (Jobber, Workspace), accounting, shop rent, licenses.
Does **not**: workers comp (in labor burden), vehicle insurance (on the vehicle row), fuel (on equipment).

| Overhead | $/yr | $/hr |
|---|---|---|
| General liability | $6,000 | $4.00 |
| Shop rent | $9,600 | $6.40 |
| Website + marketing | $3,600 | $2.40 |
| Phones + internet | $2,400 | $1.60 |
| Accounting + legal | $2,400 | $1.60 |
| Software | $1,800 | $1.20 |
| Licenses + misc | $1,200 | $0.80 |
| **Sum** | **$27,000** | **$18.00/hr** |

### 2.4 Materials

Row = something installed and left on the customer's property, with a known unit price. Free-text "source" field (Cherry Lake, Royal, Home Depot). No vendor table.

| Materials | Unit | Cost |
|---|---|---|
| Queen palm, 10 gal | each | $85 |
| Root barrier | 20 ft roll | $45 |
| Mulch | yard | $32 |
| Stakes + ties kit | each | $12 |

### 2.5 Consumables (includes disposal and all subcontractors)

Row = used up on the job, not installed, not fuel. Disposal and **every subcontracted vendor** live here as quantity rows.

STS standing rules that apply unchanged: disposal is sold **by the load**; subcontractors are **flat, all-in** — one number per day/job/stump as the sub charges it, never broken into parts, never shown to the customer as a "sub" line (the app's customer-safe output shows only the price).

| Consumables | Unit | Cost |
|---|---|---|
| Dump fee | load | $75 |
| Grapple truck (sub) | day | $650 |
| Stump grinding (sub) | stump | $90 |
| Crane (sub) | day | $1,800 |
| Cambistat | application | $120 |
| Permit | each | $50 |

---

## 3. Project rules

### 3.1 Hours
Hours = crew clock time for this job, door to door: drive out, work, cleanup, drive back, dump run. This is where under-pricing hides. A "4-hour job" is usually 6.

### 3.2 Toggle defaults on a new project
- Labor, Equipment, Overhead rows: **on** (the whole crew shows up)
- Materials, Consumables rows: **off**, qty 1 when turned on
- "Duplicate project" copies everything — that is the v1 preset mechanism

### 3.3 Worked example — 8-hr removal, full crew, no skid steer, 2 dump loads

| Bucket | Calc | $ |
|---|---|---|
| Labor | $124.39 × 8 | $995.12 |
| Equipment | $70.48 × 8 | $563.84 |
| Overhead | $18.00 × 8 | $144.00 |
| Materials | — | $0 |
| Consumables | 2 × $75 | $150.00 |
| **Cost** | | **$1,852.96** |
| **Price** | × 1.35, 1× multiplier, ≥ $750 | **$2,501.50** |
| Profit | | $648.54 (25.9% margin) |

Toggle Miguel off → **$2,170.48**. Miguel back on, toggle skid steer on → **$2,674.62**. Add 3 stumps ground by the sub → +$270 cost → $3,039.12. This is the accuracy tool: flip things and watch what the job actually needs.

### 3.4 Rate snapshots
A project copies every row's name/unit/rate the moment the row is turned on. Marcus's raise next month does not change last month's bid. A "Re-price" button refreshes the copies on purpose.

### 3.5 Actuals (the accuracy loop)
After the job: enter actual hours, and actual qty on any quantity row. The project shows estimate vs actual per bucket and total variance. Over 20 jobs the pattern ("we always miss hours by 20%") is obvious and the estimate gets fixed, not the rates.

### 3.6 Big jobs / bidding
Hours = total crew hours across all days; turn on everything that shows up any day. If a piece of equipment is only there some days, duplicate the project into "Days 1–3" / "Days 4–5" and add them. Phases inside one project = v1.1, not now.

---

## 4. Workflows

**Onboarding (~1 hour, once)**
1. Settings: 1,500 · burden % · markup % · $750 · loan rate
2. Labor: each employee, wage → Calculate → rate
3. Equipment: each owned unit ≥ $1,000, 7 inputs → Calculate → rate
4. Overhead: each annual line
5. Consumables: dump/load, each sub (grapple, stump, crane), treatments
6. Materials: as needed (can be empty day 1)

~25 rows total.

**Daily (2 minutes per estimate)**
New project → name, hours → flip toggles → read Price → type it into Jobber.

**After the job (1 minute)**
Enter actual hours → read variance.

**Reviews**
- Labor: on hire/raise
- Equipment: on buy/sell; fuel $/hr when prices move
- Overhead: once a year with the accountant
- Materials/Consumables/Subs: when a vendor changes price

---

## 5. Mac app spec

### 5.1 Scope fence — what killed OO, and is not in this app
No compliance, insurance, credentials, verification queue, flags. No positions, ladders, pay bands. No vendors, subcontractor dossiers. No loadouts or inheritance. No maintenance profiles. No expense ledger, assets, loans. No Jobber / QuickBooks / Slack, no Connections screen. No import prompts, no activity log. No lookup editors. No price-history tables. No sample data ever.

OO: 28K lines, 228 files, 75 tables, 27 screens, production DB never created. Target: ~2,000 lines, 3 models, 4 screens.

### 5.2 Stack
- macOS 15+, SwiftUI, **SwiftData** (3 `@Model` classes, one store file, no CloudKit). Not GRDB — the direct-SQL access OO wanted is covered by Export JSON.
- Xcode project via xcodegen (`project.yml`), buildable with `xcodebuild` from the CLI; one app target, one test target.
- Money as Int cents, math in `Decimal`, round half-away-from-zero once per displayed figure.
- System semantic colors and native controls only, both appearances.

### 5.3 Models
```swift
enum Bucket: String, Codable, CaseIterable { case labor, equipment, materials, consumables, overhead }
// rowKind: labor/equipment/overhead → hourly; materials/consumables → quantity

@Model final class BucketItem {
  var bucket: Bucket
  var name: String
  var rateCents: Int          // $/hr for labor & equipment; $/yr for overhead (shown as $/hr); unit cost for materials & consumables
  var unit: String            // "hr" | "yr" | "each" | "yard" | "load" | "day" | "stump" | "application" | "roll" …
  var isActive: Bool          // archived rows stay for old projects, hidden from new ones
  var source: String?         // free text (vendor, supplier, sub name)
  var notes: String?
  var calcInputs: Data?       // JSON of the Labor or Equipment calculator inputs so "Calculate…" reopens filled in
  var sortOrder: Int
}

@Model final class Project {
  var name: String; var client: String?; var date: Date
  var hours: Decimal
  var multiplier: Int         // 1 | 2 | 3
  var markupPct: Decimal      // snapshot from Settings at creation
  var minimumJobCents: Int    // snapshot
  var actualHours: Decimal?
  var notes: String?
  @Relationship(deleteRule: .cascade) var lines: [ProjectLine]
}

@Model final class ProjectLine {
  var item: BucketItem?       // nil if the row was deleted later
  var bucket: Bucket; var name: String; var unit: String; var rateCents: Int   // snapshots
  var isOn: Bool
  var qty: Decimal            // ignored for hourly rows; user-entered for quantity rows
  var actualQty: Decimal?
}
```
Settings: `billableHoursPerYear`, `laborBurdenPct`, `markupPct`, `minimumJobCents`, `costOfMoneyPct` — `@AppStorage`.

### 5.4 The one thing that must be correct: `Pricer`
A pure struct, no SwiftData import, ~60 lines:
```swift
struct Breakdown { labor, equipment, overhead, materials, consumables, cost, price, profit: Int /*cents*/; marginPct: Decimal }
struct Pricer { static func price(_ p: Project, billableHours: Decimal) -> Breakdown }
```
Tests (all must pass before any UI):
- `Pricer` on the §3.3 project → `price == 250150`; Miguel off → `217048`; skid steer on → `267462`
- Minimum-job floor: a 1-hour job with one $20/hr row → `75000`
- 2× multiplier doubles the price; floor applies after
- Snapshot: change a `BucketItem.rateCents` after the line exists → project price unchanged
- `LaborCalc(wage: 3000, paidHours: 2080, burden: 0.30, billable: 1500) == 5408`
- `EquipmentCalc(bucket-truck inputs, costOfMoney: 0.07) == 2372`; N ≤ 1 → AVF = 1; salvage ≥ price → error

### 5.5 Screens (4)
1. **Buckets** — sidebar of the 5 buckets; content is a `Table` (Name · Rate · Unit · Active) with inline add (⌘N) and a detail `Form` on selection. Labor/Equipment/Overhead rows have a "Calculate…" sheet. Delete only when no project references the row; otherwise archive.
2. **Projects** — list (Name · Date · Hours · Price · Actual variance). New / Duplicate / Delete.
3. **Project** — sticky header: `Hours` field, multiplier picker, five bucket subtotals, Cost, Markup, **Price** (large), Profit + margin caption. Below: five collapsible sections, each a list of rows with a toggle (and a qty field on quantity rows). Recomputes on every keystroke. "Re-price" button. "Actuals" section: actual hours + actual qty per line, estimate-vs-actual table per bucket. "Copy price" (name + price — customer-safe) and "Copy breakdown" (bucket subtotals — internal; never line items).
4. **Settings** — five fields + Export JSON / Import JSON.

### 5.6 Build order
1. Models + `Pricer` + `LaborCalc` + `EquipmentCalc` + tests
2. Buckets screen
3. Project screen with live header
4. Projects list, duplicate, settings, export/import
5. Actuals + variance
6. Light/dark screenshot pass

Fresh repo at `~/Desktop/Buckets`. Carry over from OO only: the USACE arithmetic (usace-methodology.md §4.3), cents convention, semantic-color rule, build/screenshot script patterns, and the STS standing rules ($750, 2×/3×, margin once, subs flat, disposal per load). Nothing else. There is no OO data to migrate.

### 5.7 v1.1 (only after v1 has priced 20 real jobs)
Named presets ("Standard removal crew") · phases within a project · PDF of the summary · iPad via CloudKit.

---

## 6. Defaults in use until Alexander confirms

1. Markup is the input (margin displayed).
2. Burden 30% — replace with the Southern Personnel Leasing number.
3. Cost of money 0% — replace with the actual loan rate if trucks are financed.
4. $750 floor and 2×/3× multipliers are in.
5. Subs are Consumables rows (grapple, stump grinding, crane). Five buckets, fixed.
