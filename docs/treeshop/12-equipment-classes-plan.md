# Equipment classes, wear parts and the $1,000-over-life rule — plan

Planning session, 2026-09-24 evening. Four planners (data model, rules per class, rate math, intake UX) worked the owner's brief in parallel; this document is the reconciliation and the build order. Nothing here is implemented yet. Binding once the DECISIONS entries named below are written.

## The brief (Mr. Anderson, condensed)

A tree business runs many kinds of non-human things: trucks, trailers, heavy and pull-behind equipment, cranes, attachments, saws, ropes, truck gear, tool kits, first-aid kits, helmets. One intake form for all of them is wrong — the rules for tires on the road are not the rules for safety chaps. Anything over **$1,000 over its lifespan** is tracked for audit-ready financials: a $500 saw counts, because bars, chains and maintenance take it past $1,000. Those consumables belong **on the equipment's line**. Do not get lost in the weeds; do not dilly-dally either. The hourly price, how it is tracked, and how it lands on a project is why the quotes are defensible. That pricing is the foundation.

## Decisions taken here

1. **Wear parts become the sixth component of the hourly rate**, beside depreciation, cost of money, insurance, fuel + oil and repairs (BRIEF §2.2). They live inside `calcInputs` as a list on the equipment row — no new model, no schema change — and they are inputs to one number, the stored `rateCents`, so `Pricer`, snapshots and Re-price are untouched (DECISIONS 7, 14, 17).
2. **The $1,000 rule is arithmetic, not a sticker price:** `lifetime = price + price × repairFactor + Σ wear over life`. Fuel and insurance are excluded (consumption while working, not the cost of owning the unit); salvage is not netted. The app shows the figure and the hour at which the unit crosses $1,000; it never blocks and never moves a row.
3. **Class is a stored attribute** (`equipmentClassRaw`, ten cases, nil = unclassified, suggested from the existing `category` the way the unit-code prefix is today). Class drives defaults, unit-code prefix, the regime hint and the suggested wear lines; `category` stays the display grouping.
4. **Two ownership states, owned and rented.** A rented unit prices as rental ÷ hours per period + fuel. Anything a vendor operates is a Subcontractors service (DECISIONS 60). No third state.
5. **Track-only rows.** Any row can be track-only: it stays in the fleet list with its code, serial and review trail, and is skipped by new projects and Re-price like an archived row. Under-$1,000 items (rakes, cones, helmets) are the obvious case; a years-based kit that does cross $1,000 can still be priced.
6. **Rules per class are a hint line and two dates, not a compliance system.** `inServiceDate` and `retireByDate` (ropes, helmets, saddles) feed the existing *overdue* signal in readiness (DECISIONS 72–73). Governing regimes are named, never quoted. No GVWR field, no inspection log (Notes carries what a row needs).
7. **Repair factor and wear do not double count.** A class default repair factor applies when there are no wear lines (chainsaw 2.50); with wear lines itemised the sheet suggests the repairs-only figure (saw 1.00) and records the choice in `assumption`.

## Classes

| Class | Prefix | Belongs | Life basis · defaults | Regime (named) | Typical wear lines |
|---|---|---|---|---|---|
| Trucks | TRK | pickups, chip and dump trucks, grapple trucks without a boom | hours · 10,000 h, repair 0.70, salvage 20% | FMCSA/USDOT for CMVs by GVWR; FL DHSMV | oil + filters, tires, brakes |
| Trailers | TRL | dump, equipment, chip trailers | hours · 10,000 h, repair 0.50, no fuel | as the combination's GCWR | tires, bearings/brakes, lights |
| Machines | MCH | mini skid, skid steer, loader, spider lift | hours · 7,500 h, repair 0.80 | OSHA 1910, ANSI Z133-2026 | tracks/tires, filters, hydraulic oil |
| Pull-behind | PBH | chipper, stump grinder, splitter | hours · chipper 8,000 / grinder 5,000, repair 0.90 | OSHA 1910.212, Z133 chipper/grinder sections | knives + anvil, belts; teeth + pockets |
| Aerial & cranes | AER | bucket trucks, crane trucks, knuckleboom, lifts | hours · 10,000 h, repair 0.80; annual inspection $/yr as a caption | ANSI A92.2 / ASME B30.5 (annual inspection, dielectric test); also a truck on the road | hydraulic oil/filters, tires, boom pads |
| Attachments | ATT | grapple, forks, bucket, auger | hours · host's life, repair 0.40, no fuel or insurance | host machine's regime | teeth, hoses/pins, cutting edge |
| Saws & power tools | SAW / PSW | chainsaws, pole saws, blowers, battery tools | hours · 2,000 h, 300 h/yr, repair 2.50 → 1.00 with wear lines | Z133 chainsaw sections; no state licence | chain, bar, sprocket, filter/plug, battery |
| Climbing & rigging | CLM / RIG | ropes, saddles, lanyards, blocks, Porta-Wraps, slings | years · rope 3, saddle 5, hardware 10 | Z133 inspect-before-use; ASTM F887; manufacturer retirement | prusiks, friction savers |
| Truck gear & site kit | KIT | shovels, rakes, mats, cones, tarps, fuel cans, tool kits | years · 4 | 49 CFR 393.95 extinguisher/triangles on a CMV | cones, tarps |
| PPE & safety | PPE | helmets, chaps, eye/ear, gloves, first-aid | years · helmet 5, chaps replace on cut | OSHA 1910.132/.135; ANSI Z89.1, Z87.1; ASTM F1897 | gloves, glasses, first-aid restock |

Class-specific *fields* beyond what a row already has: none. Class-specific *behaviour*: defaults, prefix, hint, suggested wear lines, and whether the calculator asks for life in hours or years. Sacred Tree's existing rows keep working unclassified until someone picks a class.

## The math

Wear over life is whole units bought: `wearOverLife = Σ cost_i × ceil(lifeHours ÷ every_i)` — an integer, so it joins the existing numerator as `2·A·W` over the same denominator `2·L·A`, and the rate is still **one division, rounded once** (DECISIONS 7).

Worked: STIHL MS 194 T at replacement cost — $500, salvage $50, 2,000 h life, 400 h/yr, mix $1.40/h, repair 1.00. Wear: bar $45 every 300 h (7 over life, $315); chain $25 every 60 h (34, $850); bar oil $0.60/h ($1,200). Wear over life $2,365 → $1.1825/h. Base components $1.875/h. **Rate $3.06/h** (305.75 ¢ → 306). **Lifetime cost $500 + $500 + $2,365 = $3,365**, crossing $1,000 at hour 349 — inside its first year. That is the owner's rule as arithmetic: the saw is tracked, and the chains are on its line, not on a project someone forgot to toggle.

Pinned figures never move: the bucket truck stays $23.72/h with no wear lines. Tie discipline gets a dedicated test (a wear set that sums to an exact half-cent).

Rented: `rate = rental ÷ hours per period + fuel`, one division, evidence "rental quote and date".

## Audit trail

Per wear line: `evidence` (price and life are two claims). Row level: the seven review fields as today; `markVerified` also refuses when a wear line lacks evidence. New **Copy rate sheet** on the calculator: inputs, six components, each wear line as `name · $cost / every N h = $/h · evidence`, lifetime cost. Customer-facing output is unchanged: bucket subtotals only (DECISIONS 41). A per-project equipment cost report comes later and needs `ProjectLine` to carry `calcInputs` at snapshot time; until then it is captioned "components from current inputs".

## Intake

`⌘N` on Equipment opens **New Equipment**: Class (remembers the last), Name, Make · Model · Year, Replacement price, Serial, Owner-confirmed toggle, Track-only toggle (auto-checked under $1,000 lifetime, editable). Live on the right: the suggested unit code and the rate the class defaults produce. **Add & Next (⌘⏎)** keeps class/make/model/year and clears name/serial — the speed run. **Add & Calculate…** opens the sheet prefilled for units whose fuel and insurance are known. `⌘D` still makes a twin with the next code. The Form's Category field becomes the class picker with an "Other…" escape; the calculator gets Reset to class defaults, a Wear parts list, the sixth component, the lifetime line and the tracking footer ("Under $1,000 over its life ($640) — fold into a kit row or the small-tools overhead line; it still prices from its rate.").

Fleet sheet: `Scripts/catalog/build_catalog.py` reads CSV; `Scripts/catalog/data/fleet-sheet-template.csv` has one example row per class with defaults filled; blank cells take class defaults; blank unit codes are assigned at merge; `Scripts/onboard.sh` accepts CSV. Forty units pasted in Numbers → one command → rows in the app with `calcInputs`, review fields and codes.

## Slices

| # | Scope | Schema / format | Tests | Customer Mac after |
|---|---|---|---|---|
| **1 — Wear parts and lifetime cost** (one overnight) | `WearItem`, `EquipmentCalcInputs.wearItems`, `lifeYears`; sixth component; `lifetimeCostCents`; tracking status on the Form; repair-factor help; Copy rate sheet; `build_catalog.py` optional wear | none (inside `calcInputs`); format stays 2 | 194 T = 306 ¢ and $3,365; 2372 unchanged; exact tie; legacy JSON decodes with `wearItems == nil`; spec figures untouched | same app, saws can be priced honestly; install optional |
| **2 — Classes, ownership, track-only, dates** | `EquipmentClass`; `equipmentClassRaw`, `ownershipRaw`, `hostUnitCode`, `trackOnly`, `inServiceDate`, `retireByDate` on `BucketItem`; New Equipment sheet; class picker; rental mode; Kind column; overdue via retire-by; regime hint; readiness "priced · track-only"; version 0.3.0 build 4 | lightweight migration (six optional/defaulted attributes); **format 3**, reads 1–3 | migration test on a v0.2 store; format-3 round trip; new project skips track-only; rental $650/day ÷ 8 h + $7.28 = $88.53; prefixes unchanged | fleet entry in an evening; backup by `onboard.sh` before install |
| **3 — Fleet sheet** | CSV in `build_catalog.py`, template, `onboard.sh` CSV | none | template converts and merges: counts per class, codes, rates equal `EquipmentCalc` | remote onboarding of a whole fleet |
| **4 — Bulk review** | multi-select Mark Owner Confirmed / Mark Track Only / Archive / Set Class; Show filter "Track only"; Overhead "From fleet list" | none | `AppState` bulk functions | 193 unresolved rows cleared by class in minutes |

DECISIONS to write as each lands: 80 wear component and lifetime rule; 81 classes and prefixes (supersedes 36's "no type picker" the way 60 superseded the model count); 82 ownership; 83 track-only; 84 in-service/retire-by and the regime hint; 85 format 3; 86 fleet sheet. BRIEF §2.2 gets a one-paragraph amendment ("≥ $1,000 over its life; wear parts on the row").

## Kept out

No `Equipment`, `Asset`, `Consumable`, `MaintenanceInterval` or `Inspection` models. No hour meters, service intervals, odometers, plates, loans, depreciation schedules, photos, rental vendor records, inspection logs, operator qualifications, per-class field tables or a defaults editor. Wear intervals are cost-spreading, never due dates. Readiness gains no new group. The app says "overdue"; the owner decides.

## Open questions for the owner

1. Saws: 300 h/yr as the default, or the company's billable hours?
2. Track-only threshold: $1,000 everywhere, or a Company setting?
3. Rental hours per period: 8 h/day default?
4. Owner-confirmed on by default when you type it yourself; off for a remote operator?
5. Does Sacred Tree own anything in Aerial & cranes, or is every crane a sub today?
6. CSV (Numbers/Excel) or JSON for remote fleet onboarding?
7. Small-tools overhead line: a two-year replacement cycle as the default divisor?
