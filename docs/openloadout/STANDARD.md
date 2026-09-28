# OpenLoadout — Tree Service Baseline 0.1

**The open operating standard for service crews. Edition: Tree Service Baseline 0.1 (draft, 2026-09-28). Baseline 1 ships with Buckets 1.0.**

*OpenLoadout* is a working name (a "loadout" is what the crew puts on the truck). Each numbered release is a **Baseline**. The reference point of truth for building Buckets (a macOS pricing and operations app for tree service) and for running the first company live on it, Sacred Tree Service LLC (Apopka, Florida), which serves as the worked example. It carries no serial numbers, VINs, policy numbers, wages or personal names. Corrections, evidence and internal to-do items live in the companion file **FINDINGS.md** (IDs F-…).

## Contents

| # | Section | # | Section |
|---|---|---|---|
| 0 | Day one on the crew | 9 | Audit-ready data (documents, security, storage) |
| 1 | What this is and how to use it | 10 | Baseline plant selection (Central Florida) |
| 2 | The three lists | 11 | The record types |
| 3 | The connection model | 12 | Compliance gates |
| 4 | The standard saw line (4.0 saw cards) | 13 | How this maps onto Buckets |
| 5 | Costing | 14 | Versioning, community, license |
| 6 | Inventory (6.3 counts, 6.4 locations) | 15 | Open questions |
| 7 | Lifecycle SOPs (7.0 the records, 7.4 truck card) | A | Saw line reference (A.0 order sheet, A.1 parts, A.2 intervals) |
| 8 | Decision rules | B | Vocabulary · C Documents checklist · D Owner's notes: chain math · E Sources |

**Start here.**

| You are… | Read |
|---|---|
| New to the crew | Section 0, then rules 1, 3, 6, 7, 8 in Section 8 |
| Crew leader loading a truck | 4.0 Saw cards · 7.4 Truck card and daily check sheet · 6.5 Issuing |
| Office manager | A.0 Order sheet · 6.3 Counts · 7.0 The records · Appendix C Documents checklist |
| Owner adopting this at another company | 2.3, 2.4, 14, then "Using this without Buckets" (top of Section 5) |
| Buckets developer | 5, 11, 13, 9.3 |

**How figures are marked.**

| Tag | Meaning |
|---|---|
| **[V date]** | Verified: read on the cited page on that date. Prices are USD as seen. |
| **[M]** | Manufacturer instruction: from the maker's manual or parts list, section cited. |
| **[owner baseline]** | The owner's stated starting figure, to be replaced by logged data. |
| **[rule of thumb]** | An industry planning figure with no manufacturer source. |
| **[illustrative]** | A placeholder used to show the arithmetic. Replace it. |
| **[unverified]** | Could not be checked. Do not price from it. |

---

## 0. Day one on the crew

This standard is not training. Your crew leader trains you; this page tells you the words and the rules you will meet on the first day.

**What you wear (issued to you; sign for it):** helmet with face screen and ear muffs, safety glasses, chainsaw chaps, gloves, boots. The helmet and chaps are equipment with a retire date; gloves and earplugs are consumables. Both are issued to you by name and written down.

**What you never do:**
- Run a saw you have not been trained and signed off on.
- Put a chain from one saw on another. Each saw has its own chain size; the wrong one will not fit or is unsafe (rules 3, 6, 7).
- Take a part off the shelf without the crew leader writing it on the Parts issue log (rule 8).
- Leave the yard with a unit that is not on the daily check sheet (rule 1).

**Words you will hear:** *loop* = one chain, joined in a circle, sized to one bar. *Bar* = the metal blade the chain runs on. *Sprocket* = the toothed wheel that drives the chain. *Kickback* = the saw jumping back at you; the reason only approved bar-and-chain combinations are used. *Unit code* = the short name painted on a saw or truck (SAW-01, TRK-02). *Loadout* = which people and which units go on which truck today. More in Appendix B.

---

## 1. What this is and how to use it

A tree company sells hours. Everything it buys falls into a short list of kinds, and each kind has one home, one way of becoming money on a job, and one record that proves it.

This standard defines **three lists**:

1. **EQUIPMENT**: durable things the company keeps and tracks as units.
2. **CONSUMABLES**: things used up or worn out by running the equipment and the crews.
3. **MATERIALS**: things bought for a project and left at the customer's site.

```
   EMPLOYEES  ──use──▶  EQUIPMENT  ──uses──▶  CONSUMABLES
   (each company's own)   (units with codes)     (stock on the shelf)

   PROJECTS   ──use──▶  MATERIALS
   (one priced job)       (bought to the takeoff, left on site)

   SUBCONTRACTORS ── a separate section: another company's people or machine, one flat bill
```

- **Employees use the equipment.** Employees are unique to every company. There is no master employee list in this standard, and none is planned here. An employee's protective gear is either EQUIPMENT (durable, with a retire date: helmet, saddle, chaps, harness) or CONSUMABLES (used up: gloves, earplugs, glasses), marked "issued to a person".
- **The equipment uses the consumables.** A chain belongs to a saw. A knife set belongs to a chipper. Fuel belongs to whatever burns it.
- **Projects use the materials.** A palm, a yard of mulch, a roll of root barrier: bought for that job, left behind.
- **Subcontractors stay a separate section.** Most businesses need them. Buckets already has them as their own bucket.

Labor and overhead exist in Buckets as their own buckets. This standard mentions them only as places cost goes.

**Five steps.**

| Step | Who | What |
|---|---|---|
| 1. Read Sections 2 and 3 | Owner, office, crew leader | The three lists, the one-question tests, and how they connect. Twenty minutes. |
| 2. Make your company's list | Owner or manager | Start from the Baseline. Pick rows, set brand defaults, add and remove (Section 2.4). |
| 3. Enter units and configurations | Owner or office manager | Every saw, truck, machine gets a unit code and its configuration written down (Section 4). |
| 4. Run the records | Crew leader and office manager | Issue parts against a unit, count stock, check the truck (Sections 6 and 7). |
| 5. Let the numbers replace the guesses | Owner, monthly | Logged usage replaces every [rule of thumb] and [owner baseline] figure (Sections 5 and 6). |

This is a MASTER open-source standard: a default starting point with opinionated defaults (the STIHL professional saw line, Cherry Lake as nursery) that any company can swap. Each company creates its own list from it according to its style, location and work.

---

## 2. The three lists

### 2.1 The one-question test for each list

Ask in this order. The first "yes" wins.

| List | The one question | Examples | How it becomes money |
|---|---|---|---|
| **Subcontractor** (separate section) | Does another company bring its own people or machine and hand us one bill? | Crane, grapple truck, stump grinding, ready-mix pour | Flat all-in price × quantity. Never shown to the customer. |
| **MATERIALS** | When the crew drives away, is it still on the customer's property? | Trees, palms, sod, mulch, soil, root barrier, drain pipe, injected plant-health product | Unit price × quantity, from the takeoff. |
| **EQUIPMENT** | Is it a durable thing the company keeps, that we could tag, inspect, retire and re-price as *this specific one*? | Saws, pole saws, trucks, trailers, mini skid, chipper, ropes, saddles, helmets, Porta-Wraps, cones, mats, fuel cans, extinguishers | An hourly rate × project hours (priced units), or tracked at $0 (track-only units). |
| **CONSUMABLES** | Is it used up or worn out by running the equipment and the crews, or by the job itself? | Chains, bars, sprockets, files, filters, plugs, chipper knives, fuel and oil, gloves, earplugs, marking paint, tarps, dump fees, permits | Wear parts: inside the unit's hourly rate. Fuel: inside the unit's rate. Job supplies: unit cost × quantity on the project. |

Two boundary rules that catch most mistakes:

- **If it has a date, it is equipment.** Anything with an inspection cadence or a retire-by date (rope, saddle, lanyard, helmet, chaps, extinguisher, first-aid kit) gets a unit code and a row, track-only if it is under the cost threshold.
- **If it comes back on the truck, it is not a material.** Ground protection mats, cones, tarps and barriers return; they are equipment (kit), not materials.

Definitions used from here on:

- **Unit**: one physical piece of equipment with a **unit code** (SAW-01, TRK-02, PSW-01). The code is the crew's short name for it.
- **Unit hours**: the project's door-to-door hours for every project where that unit is on the loadout. Not engine hours; nobody times the saw. Every hour input on an equipment row (life, annual hours, fuel $/h, wear "every N h") uses this basis.
- **Configuration**: what a unit is set up with. For a saw: bar length and part, chain code and drive-link count, sprocket, file size.
- **Wear part**: a consumable bought only because a specific unit wears it out (chain, bar, sprocket, knife, tooth, filter, plug, belt, tire, battery).
- **Wear line**: the entry on a unit's row that spreads a wear part's cost over the unit hours.
- **Takeoff**: the list of materials and quantities a project needs, measured from the site.
- **Par**: the stock level to reorder up to. **Min**: the stock level at which to reorder.

### 2.2 One thing, several roles, one home

A single physical thing can play up to four roles. It gets exactly **one canonical record**, and every other list refers to it by ID rather than carrying a second price.

| Role | Where it lives | Example: an 18-inch chain loop for an MS 500i |
|---|---|---|
| **Spec** | On the parent unit's row | SAW-01 runs 3/8 in pitch, .050 in gauge, 66 drive links, 33 RS. |
| **Cost** | A wear line on the unit's row (or a project line when the job, not a unit, consumes it) | $36.99 every N hours on SAW-01. |
| **Inventory** | A consumables stock record | Item "STIHL 33 RS 66 loop, 3623 005 0066", min/par, count, location. |
| **Asset** | Only for equipment | Not applicable to a chain; applicable to the saw. |

The tie-break order when two rules fire: Subcontractor > left on site (Material) > unit and its wear part (Equipment) > fuel (on the unit) > issued to a person > consumed by the job > overhead.

### 2.3 What is universal and what is a company choice

| Universal (the standard) | Company profile (each company sets it) |
|---|---|
| The three lists and their one-question tests | Which services it offers (pruning only, removal, planting, plant health) |
| One record per thing; spec on the unit; wear on the unit's line; fuel on the unit's line | Brand defaults (STIHL, Milwaukee, Toro) and the approved-equivalent list |
| Unit identity: code, make, model, year, serial (serial kept private) | Unit-code prefixes beyond the defaults |
| The costing formula (one division, rounded once) and the Confidence levels | Target margin, minimum job, multipliers, billable hours |
| Counts start at zero; par is derived from logged usage | Min and par per item, from *this* fleet's log |
| The lifecycle steps and the record each leaves | Whether records live on paper, in the workbook, or in Buckets |
| The compliance gates as questions | The answers |
| The Baseline plant list method (zone fit, invasive status, disease hosts) | Which species it sells, and its nursery |

### 2.4 How a company makes its list from the Baseline (Sacred Tree as the worked example)

Four moves: **pick**, **set brand defaults**, **add**, **remove**.

| Move | Sacred Tree Service, 2026-09-28 |
|---|---|
| **Pick** | Ground saws, top-handle saws, compact top-handle saws, battery pole saws, a diesel mini skid (Toro Dingo TX 525, Kubota diesel), a dump trailer, pickups, Porta-Wraps, fuel cans. Subcontractors: grapple truck, stump grinding, crane. Materials: the Baseline palm and tree list. |
| **Set brand defaults** | Saws: the STIHL professional line (Section 4). Chain: the professional option, and the larger approved size when the saw offers a choice. Bars: stock STIHL pro bar; light bars allowed. Nursery: Cherry Lake (Cherrylake, Inc., Groveland FL), wholesale account. Stone and aggregate: Pebble Junction (Sanford FL). |
| **Add** | Its own units as they are entered, each at the current standard model's replacement cost. Inventory rows as stock is bought (counts start at zero). |
| **Remove** | Stump-grinder wear parts (it subcontracts grinding). Plant-health chemicals until the licence gate is answered. Queen palm and the other removed species (Section 10). "Manpower Nursery" (unknown vendor). The draft source lists' "Customer View" tab and its marketing claims. Technology rows (nothing is being bought; tech cost is $0 today and goes to overhead when it arrives). |

---

## 3. The connection model

### 3.1 The chain from project to shelf

```
PROJECT ─▶ CREW (employees) ─▶ TRUCK / LOADOUT ─▶ UNIT (unit code)
        ─▶ CONFIGURATION (saw + bar + chain + sprocket + file)
        ─▶ WEAR PARTS (exact SKUs, on the unit's wear lines)
        ─▶ STOCK ON THE SHELF (consumables count, issued against the unit code)

PROJECT ─▶ MATERIALS by takeoff ─▶ nursery / yard quote ─▶ receipt attached to the project
PROJECT ─▶ SUBCONTRACTOR services ─▶ sub's invoice matched to the project
```

A **loadout** is a named crew formation (which people, which units) applied to a project; a **truck** is itself a unit (TRK-nn) that carries other units.

### 3.2 The links, one line each

| From | To | Link | Quantity rule |
|---|---|---|---|
| Project | Crew (loadout) | applies | one loadout per project; it turns labor and equipment lines on |
| Loadout | Unit | carries | the units that go with that crew (e.g. SAW-01, SAW-04, PSW-01, TRK-02) |
| Unit | Configuration | is set up as | written on the row; never remembered |
| Configuration | Wear part SKU | wears out | one wear line per SKU with price, interval and evidence |
| Wear part SKU | Stock record | is counted as | one stock item per exact spec, never "chainsaw chain" |
| Stock record | Unit | is issued to | every issue names a unit code, never a person |
| Project | Material | takes off | quantity from the site; receipt is the evidence |
| Project | Consumable (job supply) | consumes | dump loads, permits, marking paint, a chain destroyed on a nail |
| Project | Subcontractor service | buys | flat unit as the sub bills it (load, stump, day) |

### 3.3 The connection for SAW-01, end to end (worked example, unit codes [illustrative])

| Level | Record |
|---|---|
| Project | "Oak removal, 8 h, removal crew" |
| Loadout | Removal crew: two climbers, one ground; SAW-01, SAW-02 (MS 500i), SAW-04 (MS 201 T C-M), PSW-01, TRK-02, MCH-01 |
| Unit | SAW-01 · STIHL MS 500i · replacement cost $1,759.99 **[V 2026-09-28]** stihlusa.com |
| Configuration | Short: 18 in bar 3003 008 8917, chain 33 RS 66 (3/8 in, .050 in, 66 DL), rim sprocket 3/8 in 7T 0000 642 1223, file 5.2 mm (13/64 in) |
| Wear lines | Chain $36.99, bar $56.99, sprocket $12.99, plug $6.24, air filter $21.99, fuel pickup $7.49 (Section 5.2) |
| Stock | "33 RS 66 loop" reserve min 1 / par 2 plus a rotation of 3 loops per saw (Section 6) |
| Parts issue log [illustrative] | 2026-10-06 · SAW-01 · 33 RS 66 · loop tag 14 · qty 1 · reason: sharpen · initials |

---

## 4. The standard saw line

**The line.** Three STIHL gas saws, one per role. This is the Baseline default; any company may swap brands, but the *method* (approved combinations only, largest approved professional chain, short and long option per saw) is universal.

| Role | Standard model | List price **[V 2026-09-28]** | Kit as sold | Source |
|---|---|---|---|---|
| Ground saw | STIHL MS 500i | $1,759.99 | 18 in bar, 33 RS 66, part 1147 200 0029 | https://www.stihlusa.com/en/p/chainsaws-ms-500i-1027221 |
| Top-handle (climbing) | STIHL MS 201 T C-M | $949.99 | 12 in bar, 3/8 in P PS3 chain, part 1145 200 0296 | https://www.stihlusa.com/en/p/chainsaws-ms-201-gasoline-chainsaw-1027365 |
| Compact top-handle | STIHL MS 194 T | $509.99 | 16 in bar, 63 PS3 55, part 1137 200 0343 | https://www.stihlusa.com/products/chain-saws/in-tree-saws/ms194t/ |

Every combination below comes from STIHL's current **US** instruction manuals, not the EU editions (the EU MS 500i manual lists only .063 in chain; the US manual lists both gauges). Manual document numbers: MS 500i 0458-809-8621-B; MS 201 T C-M 0458-599-8621-C; MS 194 T 0458-568-8621-B, all at ssc.stihl.com (links in Appendix A). Prices and vendors for every part are in Appendix A.

### 4.0 Saw cards (what goes on this saw; no prices)

| Saw | Short (default) | Long | Carry per saw | File and guide | Spares on the truck |
|---|---|---|---|---|---|
| **MS 500i** | 18 in bar 3003 008 8917 · chain **33 RS 66** (3/8 · .050 · 66 DL) | 25 in bar 3003 000 4030 · chain **33 RS 84** (3/8 · .050 · 84 DL) | 1 loop on + 2 sharp per bar length in use | 13/64 in (5.2 mm) round file · 2-in-1 guide 5605 750 4305 | plug 0000 400 7011; rim sprocket 0000 642 1223 |
| **MS 201 T C-M** | 12 in bar 3005 000 4805 · chain **63 PS3 44** (3/8 P · .050 · 44 DL) | 16 in bar 3005 000 4813 · chain **63 PS3 55** (3/8 P · .050 · 55 DL) | 1 on + 2 sharp | 5/32 in (4.0 mm) round file · 2-in-1 guide 5605 750 4303 | plug 0000 400 7011; spur sprocket 1145 640 2010 |
| **MS 194 T** (and the MS 193 T recorded as one) | 12 in 3005 000 4805 · **63 PS3 44** | 16 in 3005 000 4813 · **63 PS3 55** | 1 on + 2 sharp | 5/32 in (4.0 mm) · guide 5605 750 4303 | plug 0000 400 7011; spur sprocket 1137 640 2005 |
| **Milwaukee 3016-21PS pole saw** | 10 in bar · Milwaukee **49-16-2723** (3/8 LP · .043 · 40 DL) | none | 1 on + 1 sharp | **11/64 in (4.5 mm)**, not 5/32 | battery FORGE XC8.0 48-11-1881 |
| **Milwaukee 3013-21 telescoping pole saw** | 9 in bar · Milwaukee **49-16-2759** (.325 LP · .043 · 46 DL) | none | 1 on + 1 sharp | 5/32 in (4.0 mm) | battery FORGE HD12.0 48-11-1813 |

The card is the whole answer to "which chain, how many, which file". A 14 in alternate exists for both climbing saws (bar 3005 000 4809, chain 63 PS3 50). A 20 in alternate exists for the MS 500i (bar 3003 008 8921, chain 33 RS 72).

### 4.1 MS 500i (ground saw)

Chain pitch: 3/8 in is the only pitch approved. Sprocket: the 7-tooth 3/8 in rim, 0000 642 1223, is the only sprocket listed (manual §23.3 **[M]**; parts list 01.04.2021 items 80–81). File: 5.2 mm (13/64 in) round.

| Option | Bar | Chain | Drive links | Sprocket | Approval |
|---|---|---|---|---|---|
| **Short (default, stock US kit)** | 18 in laminated STIHL bar 3003 008 8917 (sold as Rollomatic E or "Light 04"), 10-tooth nose | 33 RS 66 RAPID Super full chisel, 3623 005 0066, 3/8 in · .050 in | 66 | 3/8 in 7T rim 0000 642 1223 | Manual §24.1 **[M]** |
| **Long** | 25 in Rollomatic ES (solid, replaceable nose) 3003 000 4030 | 33 RS 84, 3623 005 0084 | 84 | same, no change | Manual §24.1 **[M]** |
| Alternate | 20 in laminated 3003 008 8921 | 33 RS 72, 3623 005 0072 | 72 | same | Manual §24.1 **[M]** |
| Light option (long) | 25 in Rollomatic ES Light 3003 000 2231 | 33 RS 84 | 84 | same | Manual §24.1 **[M]** |

Notes that matter:

- The green-labeled (low-kickback) alternate for the short bar is 33 RS3 66 (3624 005 0066). The manual says every §24.1 combination meets the ANSI/OPEI B175.1 §5.15 computed-kickback requirement on this saw **[M]**. Run one chain family per saw so loops interchange.
- STIHL's 20 in and 25 in dealer kits ship RAPID HEXA chain (33 RH). HEXA is not in the §24.1 list and needs a hex file. Do not adopt it; run 33 RS on those bars.
- **Never buy bar 3003 000 5221 for this system**: it is a .063 in bar **[V 2026-09-28]** (F-CAT-02).
- A 25 ft reel of Oregon 72LPX is **standard** 3/8 in pitch, .050 in gauge, full chisel, not low-kickback approved (Bailey's, **[V 2026-09-28]**): it is MS 500i-class chain and can never be spun into loops for the 3/8 P top-handles or the .043 pole saws (F-CAT-10). A spun loop of any non-green-label chain is not in the manual's §24.1 low-kickback list.
- **Gauge, flagged for the owner (Q-GAUGE).** "Run the larger chain" could mean .063 in. The US manual approves 3/8 in .063 (36 RS, 36 RS3, 36 RSF, 36 RM3) on 16–36 in bars **[M]**. The Baseline stays on .050 because every STIHL US kit ships .050, the green-labeled 25 in ES is .050 only, and mixing gauges on one crew puts .050 chain in a .063 groove. Moving to .063 needs a new bar plus loops per saw.

### 4.2 MS 201 T C-M (top-handle)

Only 3/8 in P (PICCO) chain at 1.3 mm (.050 in) or 1.1 mm (.043 in) is approved; the only sprocket is the 6-tooth 3/8 in P spur (manual §29.8 **[M]**). File: 4.0 mm (5/32 in) round.

| Option | Bar | Chain | Drive links | Sprocket | Approval |
|---|---|---|---|---|---|
| **Short (default, stock US kit)** | 12 in Rollomatic E 3005 000 4805, 9-tooth nose | 63 PS3 44 PICCO Super 3 full chisel, 3616 005 0044, 3/8 in P · .050 in | 44 | 3/8 in P 6T spur 1145 640 2010 | Manual §29.8 **[M]** |
| **Long** | 16 in Rollomatic E 3005 000 4813 | 63 PS3 55, 3616 005 0055 | 55 | same, no change | Manual §29.8 **[M]**; 16 in is the longest approved |
| Alternate | 14 in Rollomatic E 3005 000 4809 | 63 PS3 50, 3616 005 0050 | 50 | same | Manual §29.8 **[M]** |

- A STIHL 16 in 3/8 in P bar takes 55 drive links; a 56 DL loop will not fit (F-CAT-11).
- 14 in is the length recorded for Sacred Tree's MS 193 T; its MS 201 T's bar length is unrecorded and is confirmed at re-entry.
- Light bars: the US manual lists Light 04 for this saw only at 1.1 mm, so a light bar would force the narrow 61 PS3 Pro or 61 PH3 chain **[M]**. The larger-chain preference therefore keeps the stock 1.3 mm Rollomatic E on this saw.
- Approved for sandy or dirty wood (palm boots): 63 PM3 semi-chisel, or carbide 63 PD3 (needs a diamond wheel, not a file).
- 63 PS (Type 3617, non-low-kickback) is sold by STIHL USA but is not in this saw's approved list. Do not use it.

### 4.3 MS 194 T (compact top-handle)

Only 3/8 in P (1.3 or 1.1 mm) or the smaller 1/4 in P is approved; sprockets are the 6-tooth 3/8 in P spur or the 8-tooth 1/4 in P spur (manual §29.8 **[M]**). The Baseline uses the same bars, chains, file and guide as the MS 201 T C-M, so the whole climbing fleet shares two bars, two loops, one file size and one guide.

| Option | Bar | Chain | Drive links | Sprocket | Approval |
|---|---|---|---|---|---|
| **Short** | 12 in Rollomatic E 3005 000 4805 | 63 PS3 44, 3616 005 0044 | 44 | 3/8 in P 6T spur 1137 640 2005 (parts list 02/08/2023 item 8) | Manual §29.8 **[M]** |
| **Long (stock US kit)** | 16 in Rollomatic E 3005 000 4813 | 63 PS3 55, 3616 005 0055 | 55 | same | Manual §29.8 **[M]** |
| Alternate | 14 in Rollomatic E 3005 000 4809 | 63 PS3 50 | 50 | same | Manual §29.8 **[M]** |
| Light option | Rollomatic E Light 3005 000 7409 (14 in) or 3005 000 7413 (16 in); approved at 1.3 mm on this saw only | 63 PS3 50 / 55 | 50 / 55 | same | Manual §29.8 **[M]** |

- The stihlusa.com spec line says "1/4 in PM3 saw chain", which contradicts the variant name "16 in | 63PS3 55". Trust the variant name and the manual.
- **Honorary upgrade of the MS 193 T.** An MS 193 T row is recorded and priced as an MS 194 T ($509.99). The physical saw keeps its own serial number. Read the bar-tail stamp first: a 1.1 stamp means .043 in; run 61 PMM3 until that bar wears out, then fit the Baseline 1.3 mm bar. Air filter 1137 120 1604 and plug 0000 400 7011 serve both models (parts list **[M]**).

### 4.4 The PICCO answer, plainly

**No.** STIHL approves only 3/8 in P (PICCO) chain on the MS 201 T C-M, and only 3/8 in P or the even smaller 1/4 in P on the MS 194 T. Neither saw is approved for .325 in or full-size 3/8 in chain, and each lists only the 6-tooth 3/8 in P spur sprocket (plus an 8-tooth 1/4 in P spur on the 194 T).

Sources: MS 201 T C-M US manual 0458-599-8621-C §29.8 Cutting Attachments (https://ssc.stihl.com/tsa/techdoc-documents/DVS_STIHL/ZBA/ZBA/0458-599-8621-C_ZBA_09_01.pdf); MS 194 T US manual 0458-568-8621-B §29.8 (https://ssc.stihl.com/tsa/techdoc-documents/DVS_STIHL/ZBA/ZBA/0458-568-8621-B_ZBA_03_01.pdf). Section 3 of both manuals warns that non-listed bar and chain combinations "may increase kickback forces and the risk of kickback injury" and restricts saws under 62 cc to the listed combinations under the chain saw kickback standard **[M]**.

What the owner *can* have: **63 PS3, PICCO Super 3 full chisel, on a 1.3 mm (.050 in) Rollomatic E bar.** That is the largest professional chain STIHL approves on both climbing saws, instead of the narrow 1.1 mm (.043 in) "Micro Mini" 61 PMM3 / 61 PS3 Pro or the 1/4 in P. If "no PICCO" meant "no narrow Micro Mini chain", the Baseline meets it. If it meant "no 3/8 in P at all", no STIHL-approved setup on these two saws can meet it; only a different saw model could, and the saw line is fixed. **The Baseline recommends no unapproved conversion.** These are life-safety climbing tools.

### 4.5 The replacement and "honorary upgrade" rule

1. Each saw role has one current standard model. Ground saw = MS 500i. Top-handle = MS 201 T C-M. Compact top-handle = MS 194 T.
2. A saw that leaves service is replaced only by the current standard model for its role. Never by an older, cheaper or off-list model.
3. Existing saws are honorarily upgraded now: every saw row carries its standard model's name and is priced at that model's current STIHL USA list price as replacement cost. An MS 193 T is an MS 194 T row at $509.99. Serial numbers stay with the physical saw.
4. Bars, chains and sprockets are wear lines, not saws. Each unit is set up with the Baseline short and long bar on the stock STIHL pro bar and the approved chain for that saw. Existing approved bars and chains stay in service until worn, then are replaced with Baseline parts.
5. No unit ever gets an unapproved conversion (pitch, gauge, sprocket or bar family outside the manual's list).
6. If STIHL supersedes a standard model, the next full Baseline names the successor, reprices every row in that role, and marks the old model honorary.
7. When to retire a unit (repair cost versus replacement) is the owner's call and is not set here.

### 4.6 The pole-saw position

Pole saws are not honorarily upgraded to a STIHL model. They are their own equipment rows, priced at current replacement cost, each with its own bar, chain and battery wear lines. Chainsaws and pole saws share one equipment class, "Saws & power tools", with unit-code prefixes SAW and PSW.

| Unit | Chain | Drive links | File | Kit price | Battery (wear line) | Reach |
|---|---|---|---|---|---|---|
| Milwaukee M18 FUEL 10 in pole saw 3016-21PS | 3/8 in LOW PROFILE · .043 in, Milwaukee 49-16-2723, $27.97 **[V 2026-09-28]** ohiopowertool.com; Oregon equivalent 90PX040G (40 DL, never the 34 DL 90PX034G: F-CAT-12) | 40 | **11/64 in (4.5 mm)**, 30°, .025 in depth gauge per Milwaukee **[M]**; not 5/32 in | $429.00 sale / $529.00 regular **[V 2026-09-28]** | FORGE XC8.0 48-11-1881, $229.00 **[V 2026-09-28]** ohiopowertool.com (the HIGH OUTPUT 48-11-1880 is discontinued: F-CAT-13) | 7–10 ft with the included extension (Milwaukee **[M]**) |
| Milwaukee M18 FUEL telescoping pole saw 3013-21 | .325 in LOW PROFILE · .043 in, Milwaukee 49-16-2759, $27.97 **[V 2026-09-28]** | 46 | 5/32 in, 25°, .025 in **[M]** | $799.00 **[V 2026-09-28]** | FORGE HD12.0 48-11-1813, $279.00 **[V 2026-09-28]** ohiopowertool.com (48-11-1812 discontinued) | 9–13 ft |

Both chains are narrow .043 in low-profile, the small-chain class the owner dislikes, and Milwaukee offers no larger chain for either tool. That is fixed by the tool; the no-PICCO rule was about climbing saws. The two do not share a chain, and neither shares with any STIHL saw, so the fleet needs three round-file sizes (13/64, 5/32, 11/64). Adding a STIHL HT 135 pole pruner would bring 3/8 in P .043 (61 PMM3) chain back into the fleet **[V 2026-09-28]** stihlusa.com. Open question Q-POLESAW.

### 4.7 The MS 500i chain baseline

**Until the Parts issue log has 4–6 weeks of data: keep 3 loops per MS 500i in rotation (1 on, 2 sharp) plus 2 in reserve on the shelf; tag every loop; write every swap on the Parts issue log. The owner's 3–5 chains per week per saw [owner baseline] is a starting guess, not a price input.**

Cost of the baseline at the verified loop price ($36.99, Bailey's **[V 2026-09-28]**): **$110.97–$184.95 per saw per week** on the 18 in bar ($140.97–$234.95 on the 25 in bar, 33 RS 84 at $46.99). Full table in Appendix D.

**The tension, in one paragraph.** At the Buckets plan default of 300 saw-hours a year (about 6 h/week), 3–5 chains a week is a chain every 1.2–2.0 saw-hours, 20–33 times the usual 40-hours-per-loop [rule of thumb]. Read literally it is about 1,334 loops and roughly $49,300 over a 2,000-hour saw life, which is not credible as loops thrown away. Either the 500i runs far more than 300 h a year, or "go through" counts chains swapped out for sharpening, or the figure covers all three saws. The three readings and their costs per saw-hour are worked in Appendix D.

**The log that settles it: the Parts issue log, filtered by unit code.** Tag each loop (paint mark or number). For every swap write: date · unit code · part · loop tag · qty · reason (sharpen / damaged / worn out) · initials. At retirement write the loop's sharpening count. Unit hours come from the projects the saw went on. After 4–6 weeks: retired loops per unit hour sets the chain wear line; swaps per hour sets sharpening labor and truck stock; hours per week settles the 300 h/yr default.

---

## 5. Costing, following the Buckets model

**Using this without Buckets.** The three lists, the one-question tests, Section 6 counting and Section 7 records work in any spreadsheet. Sections 5, 11 and 13 describe how Buckets computes rates; the formulas are complete here. Citations in the form "DECISIONS n" or "BRIEF §n" point at the Buckets repository's decision log and specification and are for Buckets developers; "plan" means the equipment-classes plan (Section 13.2). The company workbook referred to throughout ships as **openloadout-workbook-0.1.xlsx** with tabs Issues, Counts, Locations, Gates, Documents, Vendors.

### 5.1 How each list reaches a job price

Buckets prices a job from six buckets. Three are hourly (Labor, Equipment, Overhead); three are quantity rows (Materials, Consumables, Subcontractors).

| List or section | Buckets bucket | Becomes money as |
|---|---|---|
| EQUIPMENT (priced units) | Equipment (hourly) | stored rate ($/h) × project hours; the rate already includes wear parts and fuel |
| EQUIPMENT (track-only units: ropes, helmets, cones) | Equipment, $0 | tracked with a code and dates; costed through overhead ("Small tools", "PPE & uniforms") |
| CONSUMABLES (wear parts) | inside the unit's Equipment rate | a wear line: cost × whole parts bought over the life ÷ life hours |
| CONSUMABLES (fuel and oil) | inside the unit's Equipment rate | fuel + oil $/h |
| CONSUMABLES (job supplies: dump fee, permit, paint, a destroyed chain) | Consumables (quantity) | unit cost × qty, toggled on per project |
| CONSUMABLES (issued to a person: gloves, glasses) | Overhead ("PPE & uniforms" $/yr) | $/yr ÷ billable hours × project hours |
| MATERIALS | Materials (quantity) | unit cost × qty from the takeoff |
| Subcontractors | Subcontractors (quantity) | flat all-in price × qty; never shown to the customer |
| Technology, software, phones | Overhead | $0 today; $/yr when bought |
| Employees | Labor (hourly) | wage × (1 + burden) × paid hours ÷ billable hours (BRIEF §2.1); not defined by this standard |

**The price.** Cost = the sum of the bucket subtotals, each rounded once. Price = max(minimum job, round(Cost × 100 × multiplier ÷ (100 − target margin))), one division, rounded once (DECISIONS 70). At a 50% target margin the price is exactly twice the cost. Worked from the Buckets spec's 8-hour removal (labor $995.12 + equipment $563.84 + overhead $144.00 + consumables $150.00): Cost $1,852.96, Price $3,705.92 at 50% [illustrative, from BRIEF §3.3 and DECISIONS 70].

### 5.2 Wear parts on the equipment row

An equipment row's hourly rate has six components (BRIEF §2.2 plus the wear component from the plan):

1. Depreciation = (price − salvage) ÷ life hours
2. Cost of money = interest on the money tied up ÷ annual hours (0 when bought with cash)
3. Insurance + storage = annual $ ÷ annual hours
4. Fuel + oil = $/h as entered
5. Repairs = price × repair factor ÷ life hours
6. Wear parts = Σ (part cost × ceil(life hours ÷ interval)) ÷ life hours

The rate is one sum and **one division, rounded once** to the cent (DECISIONS 7). Two rules stop double counting: with wear lines itemised, the saw repair factor drops from the blanket 2.50 to the repairs-only 1.00 (plan decision 7); and bar oil lives either in fuel + oil or as a wear line, never both. All hours are unit hours as defined in 2.1.

**Worked example 1: STIHL MS 194 T** (from the plan; all inputs [illustrative] except as marked). Replacement $500, salvage $50, 2,000 h life, 400 h/yr, mix $1.40/h, repair factor 1.00. Wear: bar $45 every 300 h (7 over life, $315); chain $25 every 60 h (34 over life, $850); bar oil $0.60/h ($1,200). Wear over life $2,365 → $1.1825/h. Base components $1.875/h. **Rate $3.06/h** (305.75¢ → 306). Lifetime cost = $500 + $500 + $2,365 = **$3,365**, crossing $1,000 at hour 349, inside the saw's first year. At the verified $509.99 replacement price the rate is 307¢.

That is the owner's $1,000 rule as arithmetic: lifetime = price + price × repair factor + Σ wear over life. A $500 saw is tracked because its chains and bars take it past $1,000.

**Worked example 2: STIHL MS 500i** with the owner's chain baseline and verified prices. Inputs: price $1,759.99 **[V 2026-09-28]**; salvage $176 [illustrative, 10%]; life 2,000 h; 300 h/yr [plan default]; fuel + oil $4.50/h [illustrative: pump gas + 2-stroke oil + bar oil]; repair factor 1.00 (wear itemised); cost of money 0; insurance 0.

| Wear line | Part | Price | Interval | Evidence for the interval |
|---|---|---|---|---|
| Chain loop | 33 RS 66, 3623 005 0066 | $36.99 **[V]** | 1.5 h [owner baseline, midpoint 4/week at 6 h/week] or 40 h [rule of thumb] | Owner 2026-09-28; STIHL publishes no hour life |
| Guide bar | 18 in 3003 008 8917 | $56.99 **[V]** | 200 h [rule of thumb] | STIHL gives a condition: replace below 6 mm groove depth; flip at each chain change (manual §21.4, §23.4 **[M]**) |
| Rim sprocket | 3/8 in 7T 0000 642 1223 | $12.99 **[V]** | two loops: 80 h at the rule of thumb, 3 h at the owner baseline | New sprocket after two chains, or at 0.5 mm wear marks (manual §21.3 **[M]**) |
| Spark plug | NGK CMR6H, 0000 400 7011 | $6.24 **[V]** sawagain.com | 100 h **[M]** | Manual §21.2: new plug after about 100 operating hours |
| Air filter | HD2 1144 140 4402 | $21.99 **[V]** baileysonline.com | 300 h [rule of thumb, about one a year] | Manual says clean, not replace on a schedule |
| Fuel pickup body | 0000 350 3518 (parts list position 58, English list) | $7.49 **[V 2026-09-28]** baileysonline.com | yearly (300 h at 300 h/yr), dealer **[M]** | Manual §21.1 chart |

Two rates come out, and the difference is the whole point (full arithmetic in Appendix D):

| | Chain at 40 h [rule of thumb] | Chain at 1.5 h [owner baseline at 300 h/yr] |
|---|---|---|
| Depreciation | $0.79 | $0.79 |
| Repairs (factor 1.00) | $0.88 | $0.88 |
| Fuel + oil | $4.50 | $4.50 |
| Wear parts over 2,000 h | $3,075.31 → $1.54/h | $58,910.05 → $29.46/h |
| **Rate** | **$7.71/h** | **$35.63/h** |
| Lifetime cost | $6,595.29 | $62,430.03 |

Entered literally at 300 h/yr, the owner's baseline adds about $28/h to the saw's rate and prices a saw-hour above a mini skid. Reading (a) or (b) in Appendix D brings it back to earth: at 1,000 h/yr and 5 h per loop the chain line is about $7.40/h; at reading (b) it is $1–3/h. **Nobody should type either number as fact. Carry the owner's baseline, label it, and let the Parts issue log replace it.** On an 8-hour job at $7.71/h, SAW-01 contributes $61.68 to the Equipment bucket, and a chain ruined on a fence nail that day is a separate Consumables line, qty 1.

### 5.3 Consumables

- Wear parts and fuel are priced on the unit's row. Their consumables rows are the **price and stock source** (one row per exact SKU with price, link, date) and are never toggled onto a project once wear lines exist, except for extraordinary loss (a chain destroyed by embedded metal).
- Job supplies (dump fees by the load, permits, marking paint, tarps used up, injection tips per tree) are quantity rows, OFF on a new project with qty 1, toggled on when the job uses them.
- Items issued to a person (gloves, earplugs, glasses) are counted as stock and costed on the overhead line "PPE & uniforms", not on projects.
- A rented unit prices as rental ÷ hours per period + fuel (plan decision 4), never as a consumable.

### 5.4 Materials by takeoff

- Bought to the takeoff, never to stock (except small support kits, ties and repair parts the company chooses to hold).
- Each row has one estimating unit (each, pallet, cubic yard, ton, linear foot, roll, kit) and one unit price with a source, link and date. A row with no price is not a priced row.
- Plants are specified by species, size band and grade (Section 10), from the default nursery's quote. Wholesale-account prices are **[unverified]** until a quote is on file; public retail prices from the nursery's consumer store are the interim evidence.
- The receipt attached to the project is the evidence for actuals.

### 5.5 Overhead spread

Each overhead line is an annual figure. Buckets adds up the $/yr of the ON rows, multiplies by project hours, divides by billable hours, and rounds once (DECISIONS 4). Lines this standard sends to overhead: "PPE & uniforms", "Small tools & equipment under the threshold", "Shop & fleet maintenance supplies", "Computers & devices" ($0 today), "Software" ($0 today). Fuel is never overhead; it is on the unit.

### 5.6 Subcontractors

One record per sub, its services as flat all-in quantity rows in the unit the sub bills (load, stump, day, pick). The sub's fuel, travel and minimum are inside the flat price. The customer sees one price, never a "sub" line (DECISIONS 41, 60). For the worked example: grapple truck, stump grinding, crane.

---

## 6. Inventory

### 6.1 It starts at zero

Counts start at zero and rows are added as stock is bought. No par level is typed from a template: the draft source lists' class-wide "min 2 / par 4" on every cutting row (and 2/6, 1/3, 2/8 on the others) is a placeholder, not a decision, and is blanked.

Inventory lives in the standard and the company workbook, outside the Buckets app, for now (BRIEF §5.1 scope fence). The app holds prices; the workbook holds counts.

### 6.2 Par and min come from logged usage

Par and min are outputs, not inputs. For each item at each location:

- **d** = expected demand per day, from the Parts issue log against crew-hours (or unit hours for saw wear parts).
- **L** = replenishment lead time in days (online order about 7; a local dealer can be same-day).
- **R** = review period in days (weekly count → 7).
- **Min** (reorder point) = d × L + safety stock. **Par** (order-up-to) = d × (L + R) + safety stock.
- For slow, lumpy items (fewer than about 5 per period) take the Poisson 95% quantile as the safety-stocked figure; for fast movers use z × σ × √t with z = 1.65 (Appendix B).
- **Rotation stock** (the sharp spares that let a crew swap a dull chain in the field) is a fixed quantity per unit, separate from the reorder buffer: 1 on the bar + 2 sharp spares per saw.
- Reorder quantity = round up to the pack size (Par − (on hand + on order − allocated)), placed only when position ≤ Min.
- Recompute monthly from actual issues.

**Worked example: 33 RS 66 loops for three MS 500i.**

| Assumption set | Demand per week | Min (reserve) | Par (reserve) | Rotation | Reserve cost at $36.99 |
|---|---|---|---|---|---|
| One loop retired per 60 unit-hours at 300 h/yr/saw [rule of thumb] | 0.30 loops | 1 | 2 | 9 loops (3 per saw) | $73.98 |
| One loop per 40 h (dirty storm wood) [rule of thumb] | 0.45 | 2 | 3 | 9 | $110.97 |
| Owner's baseline read literally: 4 loops retired per saw per week [owner baseline] | 12 | about 18 | about 32 | 9 | about $1,183 |

The last row is what the shelf must hold if the baseline means retired loops. It is 16 times the first row. The Parts issue log decides which row is real; until then buy to the middle row and count weekly.

### 6.3 Count cadence

| Cadence | Items | Who | Record |
|---|---|---|---|
| Every use | Life-safety gear (ropes, saddles, lanyards) and chemicals | The person using it | Daily check sheet initials (7.4) |
| Weekly (Monday, 30 minutes) | Chains, bars, 2-stroke mix, bar oil, gloves, marking paint, throwline, first-aid refills, cleanup supplies | Office manager, with the crew leader present; the office manager also checks the week's Parts issue log | Count sheet (workbook tab Counts), dated and initialed |
| Monthly (1 hour) | Maintenance stock, rigging backups, traffic control, labels, plant-health supplies | Office manager; owner signs | Count sheet, signed by the owner |
| Annually | Everything, reconciled to purchase receipts | Owner with the accountant | Count sheet reconciled to receipts; the accountant's copy filed in Buckets > Company > Documents, category Tax |

### 6.4 Locations and the count sheet

One row per item per location. Stock units are single (EA, GAL, LF), never "each/gal/case". New locations are added by the owner only.

| Location code | Physical place | What lives there | Who counts it |
|---|---|---|---|
| SHOP_SAW_CABINET | Locked cabinet in the shop | Chains, bars, sprockets, files, guides, plugs, filters | Office manager, Monday |
| SHOP_FLUIDS | Flammables cabinet | 2-stroke oil, premix, bar oil, hydraulic oil, grease (SDS binder beside it) | Office manager, Monday |
| SHOP_MACHINE_PARTS | Shelf in the shop | Mini-skid and trailer filters, belts, pins, tires | Office manager, monthly |
| SHOP_PPE | Shelf in the office | Gloves, earplugs, glasses, first-aid refills | Office manager, Monday |
| TRUCK:TRK-nn | That truck's saw box | Rotation loops, files, plug, mix, bar oil for the day | Crew leader, on the daily check sheet |

Reorder status on the count sheet:

| Status | Rule |
|---|---|
| NOT COUNTED | Current qty is blank. Never treat blank as zero. |
| STOCKOUT (n on order) | On hand = 0. On-order stock is not on the truck. |
| REORDER | On hand + on order − allocated ≤ Min. Reorder qty = round up to pack (Par − position). |
| LOW | Position < Par. No order until REORDER. |
| OK | Position ≥ Par. |
| PAR ≤ MIN | A data error; fix the policy row. |

### 6.5 Issuing against a unit

Every wear part leaves the shelf against a **unit code**, never against a person's name, and the crew leader writes it on the Parts issue log (7.0). A chain is three numbers (pitch · gauge · drive links) or it is not a stock item. The old part goes in the scrap bucket, not back on the truck; the crew leader writes Reason = worn out and, for a loop, its sharpening count; the scrap bucket is emptied at the Monday count.

---

## 7. Lifecycle SOPs

The rule for every step: **one step, one record, three fields (who, when, what).** If a step leaves no record, it did not happen for audit purposes.

### 7.0 The records (the only names used in this standard)

| Record | What it is | Where | Who writes it | Who checks it |
|---|---|---|---|---|
| **Equipment register** | The equipment rows in Buckets, one per unit code: make, model, year, serial (private), configuration, in-service and retire-by dates, wear lines | Buckets > Equipment | Office manager at intake | Owner at the monthly review |
| **Parts issue log** | Every part that leaves the shelf. Columns: Date · Unit code · Part (exact spec) · Loop tag · Qty · Reason (sharpen / damaged / worn out / fitted new) · Initials. The per-saw chain log is this log filtered by unit code. | Workbook tab Issues (or the clipboard sheet in the saw cabinet, typed in on Monday) | Crew leader | Office manager, weekly at the Monday count |
| **Count sheet** | On-hand count per item per location with the reorder status (6.4) | Workbook tab Counts | Office manager | Owner monthly; accountant yearly |
| **Daily check sheet** | The truck card (7.4): which units left, pre-use checks, defects | Paper on the truck clipboard; photographed into the project in Buckets, or filed in the office binder; kept 1 year | Crew leader; each operator initials | Office manager, Monday |
| **Service invoices** | Dealer work orders and shop receipts | Buckets > Company > Documents, filed against the unit code | Crew leader books the service; office manager files | Owner at the annual review |

### 7.1 Hours-life units (saws, pole saws, trucks, trailers, machines, chipper, grinder)

| Step | Who | When | What is done | The record |
|---|---|---|---|---|
| Buy | Owner approves; office manager orders from the order sheet (A.0) | Before the unit is needed | Purchase the current standard model at delivered replacement cost | Invoice filed under the future unit code in Documents: make, model, serial, price, dealer, date |
| Receive | Crew leader or office manager | Day of delivery | Confirm serial matches the invoice; note the delivered configuration (bar, chain, sprocket, tires) | Equipment register row opened: unit code assigned (next free SAW-nn), in-service date |
| Tag | Crew leader | Before first use | Engrave or label the unit code on the powerhead, bar, truck door; serial into the row (private) | Equipment register: code, make, model, year, serial, Confidence "owner confirmed" |
| Assign | Owner or crew leader | When it joins a crew | Add to a loadout (which truck, which crew) | Loadout membership |
| Inspect | Operator | Before each use | Chain brake, throttle lock, chain tension; tires, lights, hitch | Daily check sheet initials. A failed check = the unit stays in the yard and a defect is written on the sheet |
| Maintain | Crew leader books it; the dealer or shop does it | Manufacturer interval (plug at 100 h; chain brake service every 3/6/12 months by use; fuel pickup yearly) | Scheduled service | Service invoice filed against the unit code |
| Replace wear parts | Crew leader | When worn to the maker's condition (groove depth, sprocket wear marks) or damaged | Fit the Baseline part from stock, issued against the unit code | Parts issue log line |
| Retire | Owner | When repair cost exceeds replacement (owner's call) or the unit is sold | Archive the row (never delete while a project references it); replace only with the current standard model | Equipment register row archived; disposal date and sale price in notes; salvage becomes evidence for the next calculation |

### 7.2 Years-life units (ropes, saddles, lanyards, helmets, chaps, blocks, Porta-Wraps)

Same eight steps, with three differences: the identity is a rope marker or the written serial on the label; inspection is before every use with the climber's initials on the daily check sheet plus a documented inspection by a competent person on a fixed cadence; retirement is a date (retire-by), or damage or overload, whichever comes first. Retired ropes are cut so they cannot come back. These are usually track-only rows: $0/h under the threshold rule, but with a code and dates so the "overdue" signal works.

### 7.3 Wear parts, consumables, materials, subs

| Kind | Steps | The one record |
|---|---|---|
| Wear parts | Buy at par → count in → issue against a unit code → fitted → worn → scrapped | Parts issue log; price and interval on the unit's wear line |
| Job consumables | Buy at par → count in → drawn against a project → toggled on with qty → actual qty after the job | The project line; the count sheet proves the level |
| Issued-to-a-person consumables | Buy at par → count in → issued to a named person (size, date) → returned or retired | The company's own PPE issue sheet (not part of this standard's lists) |
| Materials | Takeoff → nursery or yard quote → order → delivered to site → installed → project line with qty → warranty note | Receipt attached to the project; plants refused if species, size and root-ball condition are not on the ticket. Warranty note = the nursery's warranty terms and the install date, filed in Buckets > Company > Documents against the project |
| Subcontractor services | Quote on file → service row → used on a project → invoice matched to the line qty → paid | The invoice cross-referenced to the project |

### 7.4 Truck card and daily check sheet (printable)

Truck ______ (TRK-nn) · Date ______ · Crew leader ______ · Project ______

| Unit code | Present (Y/N) | Chain brake / throttle lock / tension OK (saws) · tires / lights / hitch OK (trucks, trailers) | Defect written (Y/N) | Operator initials |
|---|---|---|---|---|
| SAW-__ | | | | |
| SAW-__ | | | | |
| PSW-__ | | | | |
| MCH-__ | | | | |
| TRL-__ | | | | |
| CLM-__ (saddles, ropes: inspected before use) | | | | |

**Every truck carries:** 2-stroke mix (premix or mixed can, labelled) · bar oil · one round file per file size on the truck (13/64 for MS 500i, 5/32 for the climbing saws, 11/64 for the 3016 pole saw) · 2-in-1 guide per pitch · spare plug per saw model · rotation loops per the saw cards (4.0) · wedges · first-aid kit (checked, dated) · 5 B:C extinguisher, mounted, tag current · 3 warning triangles · cones · scrench and bar wrench · SDS binder copy. Completed sheet: photo into the project in Buckets, or the office binder; kept 1 year.

---

## 8. Decision rules that replace human error

Rules a new person can apply without judgment. Each names what it protects.

1. **No unit leaves the yard without its unit code on the daily check sheet.** (The register and the daily check.)
2. **A saw is replaced only by the current standard model for its role**, priced at that model's current list price. (The replacement rule.)
3. **Only manual-approved bar and chain combinations, ever.** No pitch, gauge, sprocket or bar family outside the maker's list. (Kickback safety, warranty.)
4. **Run the professional chain, and the larger approved size when the saw offers a choice.** On the climbing saws that is 63 PS3 on a 1.3 mm bar; nothing larger is approved. (Section 4.4.)
5. **Every standard saw carries a short and a long bar option** with the correct chain for each; bars and chains may vary at setup, but the row says which. (Fitment, stock.)
6. **Read the bar-tail stamp, not the box.** The gauge on the bar decides the chain: 33 RS is .050; 36 RS is .063; a .043 pole-saw chain never runs on a .050 bar. (Against the wrong loop on a truck.)
7. **A chain is three numbers or it is not a stock item: pitch · gauge · drive links.** (Fitment and the count sheet.)
8. **Chains, bars and sprockets are issued against a saw, not a person**, and written on the Parts issue log. (The wear lines.)
9. **Fuel and oil are never a project line.** They live on the unit's row. (No double counting.)
10. **Routine wear is never a project line; damage on the job is.** (The variance table and the rate.)
11. **One repair factor or itemised wear lines, never both at full strength.** (No double counting.)
12. **A unit's hours are the door-to-door hours of the jobs it went on.** Nobody times the saw. (One hour basis everywhere.)
13. **If it has a date, it is equipment.** (The overdue signal.)
14. **If it stays at the customer's, it is a material; if it comes back, it is not.** (Materials bucket integrity.)
15. **Materials are bought to the takeoff, never to stock.** (Cash, nursery relationship.)
16. **Subs are flat and all-in, in the unit the sub bills, and never shown to the customer.** (BRIEF §2.5, DECISIONS 41, 60.)
17. **Disposal is sold by the load.** (Standing rule of the worked example.)
18. **Rates are snapshotted the moment a line is turned on; only Re-price changes them.** (Every past quote.)
19. **Hours are door to door.** Drive out, work, cleanup, dump run, drive back.
20. **Every number has evidence and a date or it is not verified.** A hand-edited file cannot make a row verified. (DECISIONS 72, 74.)
21. **A price is never blocked by an unresolved row, but the row is flagged and counted.** Fix it on Monday, not in front of the customer.
22. **Par is derived from the log, never copied down a column.** (Section 6.)
23. **Counted stock reorders on the sheet's formula, not on memory.** Blank is NOT COUNTED, not zero.
24. **Nothing is deleted; rows are archived.** A retired unit keeps its code forever.
25. **A receipt names a unit code or a project, or it is overhead.** The monthly review watches the overhead line grow.
26. **Serials, VINs, EINs, policy numbers, wages and personal data stay in the app's private fields or the locked vault**, never in chat, screenshots, catalog files, merge files, or this standard.
27. **A species on the removed list is never quoted, whatever the nursery has in stock.** (Section 10.)
28. **A gate question unanswered is a question, not a "no".** Do not offer the service until it is answered. (Section 12.)

---

## 9. Audit-ready data

**Audit-ready data** is one step up from audit-ready financials: every price, rate, unit and quantity that reaches a quote traces to a document with a date, and every document the company must hold is present, current and findable.

**Today, file every document in Buckets > Company > Documents (it already exists: title, category, expiration, notes, and a file copy; expired shows red, expiring within 30 days orange).** The full checklist of what to get, from where, and when to renew is **Appendix C**. Section 9.3 is a planned improvement, for developers.

### 9.1 The register in one paragraph

Sixty document types in eight scopes: Company (21), Equipment unit (10), Consumable (6: an SDS for every chemical kept), Material (4), Project (8), Subcontractor (4), Vendor (2), People (5: **kept outside Buckets** with the payroll provider or a locked HR folder). Each is a row in Appendix C with its gate, source, owner, renewal and filing place; citations are in Section 12; statute edition 2025; ANSI Z133-2026 (effective 2026-05-26) supersedes the 2017 edition.

### 9.2 Security rules

**For the office**

1. Keep FileVault (full-disk encryption) on for every Mac that holds the store or documents. The readiness screen shows whether it is on.
2. Never paste a policy number, EIN, VIN or serial into an email, an estimate, a note or an AI chat. Send the agent's PDF instead.
3. Share with the accountant, a consultant, support or the public only through "Export for sharing", which strips EIN, policy numbers, serials, sensitive document records and original file names.
4. People documents (I-9, W-4, driver records, training, credentials) never go into Buckets or any shared folder.
5. Remove a document only after its legal retention ends; archive to the vault first, because Remove deletes the copy.
6. Off-machine copies go only to an encrypted disk, never to a cloud-synced folder or a shared drive.

**For developers**

7. Documents live in the app's local Application Support folder next to the store; directory mode 0700, files 0600. Encrypted backups include the Documents folder as well as the store.
8. Never in git: store files, exports, backups, documents, company-profile files with real values, EIN, policy numbers, VINs and serials, TINs, ID numbers, customer names, addresses, photos, wages. A guard test greps VIN, EIN and "policy + digits" patterns over catalog data and docs.
9. Catalog and merge files carry rows only. A company-profile merge file with real values is created in the vault, used once, and never committed.
10. Stored document file names are UUID-based so a file name never leaks a policy number; titles and notes of sensitive documents never repeat the number.

### 9.3 The Buckets storage design (developers; smallest change on what exists)

Buckets already has a Company screen with a documents shelf: a `CompanyDocument` record (title, category, expiration, notes) plus a file copy in the app's Documents folder (DECISIONS 65). It needs five things:

1. **Link documents to what they are about.** Four optional attributes on `CompanyDocument`: `requirementKey`, `issuedAt`, `sensitive`, and one optional subject (an equipment, consumable or material row; a project; or a subcontractor; nullify on delete so deleting a row never deletes evidence). Categories gain Company, Tax, Equipment, Safety, Supplier, Project, Subcontractor. Files are stored as `<UUID>.<ext>`; existing files are renamed in the migration because today's stored names carry the original file name.
2. **The list of documents to find and get is a bundled public Baseline file**, `document-requirements.json`: one entry per requirement with key, title, scope, category, citation, where-to-get URL, renewal rule, sensitive default, and an optional gate plus a match rule for per-row scopes (every Trucks/Trailers row needs title and registration; every active sub needs W-9 and COI). It carries no company data. The only per-company state is the gate answers.
3. **Checklist status, computed like Readiness:** have · expiring · expired · missing · not applicable (gate answered no) · gate unanswered (shown as the question, never as "missing"). A record whose file is gone from disk counts as missing.
4. **A "Documents" section on the readiness screen** with its own Audit-ready / Not audit-ready line and a FileVault line. It does not change the pricing readiness status.
5. **"Export for sharing"** with redaction; the backup export keeps everything and stays in the vault; the onboarding script backs up Documents/ with the store.

Decision numbers for these are assigned at merge time (the binding log ends at 79; the plan reserves 80–86 on its branch).

---

## 10. Baseline plant selection (Central Florida, USDA 9b)

Method: every species is checked against UF/IFAS EDIS fact sheets (zone fit, mature size, disease hosts), the FISC April 2026 invasive plant list, UF/IFAS Assessments, the Florida Grades and Standards for Nursery Plants (2022 edition), ANSI Z60.2-2025 sizing, and the default nursery's availability. Sources were read on 2026-09-28. This list has had one research pass and no adversarial check: carry its prices as [V 2026-09-28] on the nursery's public consumer store and its wholesale-account prices as [unverified]. The full list with prices, sizes and sources goes in the workbook.

### 10.1 Palms (17)

| Fit | Species | Why, in one line |
|---|---|---|
| Great | Dwarf palmetto (*Sabal minor*), saw palmetto (*Serenoa repens*), European fan palm (*Chamaerops humilis*) | Cold-proof here; two are natives; not lethal-bronzing hosts |
| Good | Cabbage palm (*Sabal palmetto*, the state tree), needle palm, paurotis palm, pindo palm, mule palm, lady palm, ribbon palm (*Livistona decora*), caranday palm | Grow well in Central Florida per UF EP020; several are lethal-bronzing hosts (Sabal, needle, pindo) so mix species |
| Caution | Bismarck palm (marginally hardy, huge), Sylvester, Medjool and Canary Island date palms (high lethal-bronzing risk; Canary also Fusarium wilt), foxtail and pygmy date palms (not reliably cold-hardy here: sell only with a signed no-cold-warranty note) | High-ticket losses; quote with a written disease or cold disclosure |
| Pending (Q-WINDMILL) | Windmill palm (*Trachycarpus fortunei*) | UF EP020 lists it for Central Florida; it was removed from the Buckets catalog on 2026-09-24 (DECISIONS 77) and returns only on the owner's yes |

Palm care rules for crews and quotes: all Central Florida soils are potassium-deficient for palms, so use an 8-2-12+4Mg palm fertilizer with micronutrients and never strip yellowing old fronds (UF EP020, EP261); never replant a palm where one died of Ganoderma (UF PP100); disassemble and soak chain and bar between Canary, queen or Washingtonia palms (UF PP278); hurricane-cut ("cropped") only Sabal, never other species (UF EP001). Lethal bronzing is confirmed in Orange, Lake, Seminole and Osceola counties (UF PP163); preventive injection is a licensed service (Section 12).

### 10.2 Trees (15)

Southern live oak (incl. 'Cathedral'), southern magnolia (Bracken's Brown Beauty, D.D. Blanchard, Little Gem), sweetbay magnolia, bald cypress, red maple 'Florida Flame' (moist sites only; Florida seed source), slash and longleaf pine, southern red cedar, East Palatka / Eagleston holly, dahoon holly, yaupon holly, winged elm, Shumard oak, Allee lacebark elm (re-check the UF/IFAS Assessment before each release), crape myrtle, Simpson's stopper. Every one is grown by the default nursery.

Crape myrtle stays with a note: UF ST342 gives zones 7A–9A for *L. indica* and Apopka is 9b, the same ceiling that removes river birch; it is kept because the Baseline sells only the mildew-resistant *indica × fauriei* hybrids UF names ('Natchez', 'Muskogee', 'Tuscarora'), UF's North and Central Florida tree guide includes it, and it is planted throughout Orange County. Never topped.

### 10.3 Removed from the Baseline (and why)

| Removed | Reason |
|---|---|
| Queen palm | FISC Category II invasive; primary Fusarium wilt host; lethal-bronzing host. Offer mule or pindo instead. The Buckets spec's example material row "Queen palm, 10 gal" should be swapped for a Sabal or pindo. |
| Mexican fan palm, Chinese fan palm, Senegal date palm (and its hybrid), bamboo palm, Alexander palm, coconut, Christmas palm | FISC Category II and/or lethal-disease hosts not on UF's Central Florida list |
| Royal palm | Not on UF's Central Florida palm list; severe potassium deficiency |
| Bottlebrush (both common species) | FISC Category II or UF/IFAS "not recommended" (this reverses a 2026-09-24 catalog audit "keep") |
| Ligustrum / Japanese privet | UF/IFAS "High Invasion Risk, not recommended" |
| Loquat | UF/IFAS "Caution"; supply only on written customer request |
| Citrus rows | Must come from certified structures (FDACS Rule 5B-62); homeowner sizes; not a tree-service install item |
| River birch | Zones 4A–9A per UF ST094; Apopka is 9b |
| Pink and golden trumpet trees | Zones 10A–11; cold-tender here |
| "Manpower Nursery" | Unknown to the owner; no positive identification; removed |

### 10.4 Sizing bands for quotes

Trees: STANDARD = Florida "30 gal" (about ANSI #25), 2 in caliper, 12–14 ft; SPECIMEN = 45 gal, 2.5–3 in; LARGE = 65 gal, 3–3.5 in; EXTRA-LARGE = 100 gal or field-grown 4 in and up (machine handling). A container class alone is an incomplete specification (ANSI Z60.2 §1.1.3.2); every quote names caliper or height plus container. Grade: Florida #1 or better. Retail 1–7 gal is never an install size.

Palms: SMALL container (7 / 15 / 30 / 45 gal by overall height) for shrub and clumping palms; FULL-SIZE field-grown by clear trunk in bands (4–6, 8–10, 12–14, 16–18, 20–22 ft CT). Say which measure the quote uses (Florida "clear trunk" differs from ANSI "trunk height"). Any symptom of Fusarium, phytoplasma, Ganoderma, Thielaviopsis or Phytophthora makes a palm a cull at delivery.

---

## 11. The record types (the minimal type system)

Fields marked **U** are universal; fields marked **C** are company-profile choices. IDs are opaque and permanent; legacy IDs from the draft source lists (EQ-001, CON-002, MAT-062) are kept as aliases. A retired ID is never reused.

**Confidence** (DECISIONS 72), on every priced row and every wear line: `missing` · `estimated` · `ownerConfirmed` · `verified`. Verified requires evidence (source, note or link) **and** a checked date; a review-due date is set a year out. An unresolved row never blocks a price; it is flagged and counted.

| Record | Fields (compact) | Vocabularies | Relations |
|---|---|---|---|
| **Item** (U) | item_id · kind · name · category · stock_unit · spec (pitch, gauge, drive_links, diameter, length, container, caliper…) · catalog_status · buying_mode · notes | kind {equipment, consumable, wear_part, material, service}; catalog_status {core, conditional, future, retired}; buying_mode {stock, job_takeoff, kit, subcontract} | aliases; vendor prices; configurations |
| **Unit** (asset) (U; values C) | unit_code · item_id/config_id · make · model · year · serial (private) · ownership · class · track_only · in_service · retire_by · owner_confirmed | ownership {owned, rented}; class {TRK, TRL, MCH, PBH, AER, ATT, SAW/PSW, CLM/RIG, KIT, PPE} (Appendix B) | calc inputs; wear lines; loadouts; documents |
| **Configuration** (U; values C) | config_id · item_id · make · model · spec (bar part, chain code, DL, sprocket, file) · oem_url | | wear parts via config_part |
| **WearLine** (U) | unit_code · part_item_id · cost · every_hours · evidence · confidence · checked | evidence_level {manufacturer, rule_of_thumb, owner_baseline, logged} | copied from the consumables price row, never linked live |
| **VendorPrice / PriceObservation** (U; vendors C) | vendor_id · item_id · vendor_sku · mfr_part · purchase_unit · pack_qty · price · price_basis · seen_date · source_url · lead_time_days | price_basis {unit, pack, case, kit, pail, complete_build, subscription, planning_range} | append-only history; price_per_stock_unit = price ÷ pack_qty |
| **StockPolicy / StockCount** (U; values C) | item_id · location_id · method · usage_per_hour · lead_time · review_period · service_level · min · par · rotation_qty · rationale; count: on_hand · counted_at · by · lot · expiry | method {derived, manual, unset}; location type {shop, truck, machine, jobsite} | CHECK par > min; one row per item × location |
| **Project line** (Buckets) | snapshot of name · unit · rate at line creation · on/off · qty · actual | | never recomputed; Re-price refreshes on purpose |
| **Subcontractor service** (Buckets) | sub · service · unit · flat price · evidence | | never in customer output |
| **Document** (U) | requirement_key · title · scope · category · issued_at · expires_at · sensitive · subject | scope {company, equipment_unit, consumable, material, project, subcontractor, vendor}; status {have, expiring, expired, missing, not_applicable, gate_unanswered} | subject → row, project or sub |
| **Gate** (U; answers C) | gate_key · answer · answered_on · answered_by | {hasEmployees, appliesPesticidesForHire, appliesFertilizerForHire, installsPlants, cmvCombination, ownsCraneOrAerial, sellsPondErosionDrainage, resellsTaxableGoods} | drives document requirements and service offers |

Other controlled vocabularies: `stock_unit` set (EA, PR, LF, SF, SY, CY, GAL, QT, OZ, LB, TON, BAG, BALE, ROLL, BOX, PACK, CASE, PAIL, KIT, PAL, LOOP, REEL, HR, DAY, MO, YR); `requirement_status` for lane guidance {required, optional_upgrade, lane_dependent, specialty_shared, rental_subcontract, not_recommended}; `per_basis` {company, crew, climber, truck, machine, saw, vehicle, office, user}. "Unit code" means only the SAW-01 style tag.

What Buckets stores today versus what stays in the workbook: Buckets holds Item (as bucket rows), Unit (equipment rows with codes), the calc inputs and, once the plan lands, WearLines; Project lines; Subcontractor services; Documents. VendorPrice history, StockPolicy, StockCount and the lane guidance stay in the workbook (BRIEF §5.1: no vendor tables, no inventory).

---

## 12. Compliance gates

"If you offer X, you need Y." The owner answers each gate yes / no / not yet; the office manager records the answer and the date on the Gates tab of the workbook (later: Buckets > Company). An unanswered gate is a question, not a "no". **These gates are Florida and Orange County law; a company elsewhere replaces the Citation column with its own state's rules.** Citations were checked on 2026-09-28 unless marked.

| If you… | You need… | Citation | Answered (date, by) |
|---|---|---|---|
| Apply pesticides for hire (tree injections, soil drenches such as imidacloprid, sprays, herbicides) | An FDACS pest control business licence with a certified operator in Lawn & Ornamental ($300 per location per year plus $10 per employee ID card, proof of insurance) or, for a narrow scope only (caution-label products, handheld or backpack equipment, plant beds and ornamentals, no turf), an individual Limited Commercial Landscape Maintenance certificate | Fla. Stat. 482.071, 482.156; https://www.fdacs.gov/Business-Services/Pest-Control/Licensing-and-Certification | |
| Apply fertilizer for hire | An FDACS Limited Certification for Urban Landscape Commercial Fertilizer Application for each applicator (4-year, GI-BMP training first); and in Orange County no nitrogen or phosphorus June 1–Sept 30, no phosphorus year-round, 25 ft water-body setback, proof of certification filed with the county before June 1 | Fla. Stat. 482.1562, 403.9338; Orange County Code ch. 15 art. XVII (Ord. 2022-03) https://www.ocfl.net/Portals/0/Library/Environment/docs/ORA20220211_Ordinance2022_03_0-CERT.pdf | |
| Buy plants from nurseries for professional landscaping | FDACS nursery stock dealer registration ($25 or $69 per location per year); wholesale nurseries commonly ask for it | Fla. Stat. 581.131; https://www.fdacs.gov/Agriculture-Industry/Plants-and-Nurseries/Nursery-and-Stock-Dealer-Registration | |
| Tow a trailer with a truck | Read the truck's door-jamb GVWR and the trailer's plate GVWR. Truck + trailer of 26,001 lb or more with a trailer over 10,000 lb = Class A CDL and, in Florida intrastate, a USDOT number, medical card and annual inspection; any out-of-state trip at 10,001 lb or more triggers USDOT rules. Florida defines a CMV at GVWR 10,000 lb or more, so a one-ton pickup already needs the extinguisher and triangles even below 26,001 | 49 CFR 383.91 (https://www.law.cornell.edu/cfr/text/49/383.91), 390.5; Fla. Stat. 316.302, 316.003; https://www.flhsmv.gov/florida-highway-patrol/commercial-vehicle-enforcement/safety-enforcement/florida-usdot-numbers/ | |
| Carry extinguishers on trucks | One extinguisher rated 5 B:C or more (or two at 4 B:C) securely mounted on each CMV power unit, plus three warning triangles; monthly visual check and annual maintenance recorded; annual service by a Florida-licensed firm | 49 CFR 393.95; 29 CFR 1910.157(e); Fla. Stat. 633.304 | |
| Grind stumps, root-prune with machines, or dig planting holes by machine | A Sunshine 811 locate ticket at least 2 full business days before, valid 30 days (a sub calls its own; record the sub's ticket number) | Fla. Stat. 556.105; https://sunshine811.com/law | |
| Remove a tree | The jurisdiction's permit or the written reason none is needed. Unincorporated Orange County exempts developed single-family lots of 2 acres or less; the City of Apopka exempts non-specimen trees on developed single-family or duplex lots, dead, diseased or fallen trees, and emergencies (specimen = native 24 in DBH or more); anywhere in Florida a residential single-family lot needs no permit when documentation from an ISA Certified Arborist **or a Florida licensed landscape architect** says removal is the only means of practically mitigating its risk below moderate | Orange County https://www.orangecountyfl.net/PermitsLicenses/Permits/TreeRemovalPermit.aspx; Apopka LDC §5.3.2–5.3.3; Fla. Stat. 163.045(1)–(2) https://www.flsenate.gov/Laws/Statutes/2025/163.045 **[V 2026-09-28]** | |
| Employ anyone and also plant (or excavate) | Workers' compensation from the first employee, because landscape gardening (0042) and excavation (6217) are construction class codes and any portion counts; up to three LLC members with 10% ownership may hold a 2-year $50 exemption | Fla. Stat. 440.02(10), 440.02(20)(b)2, 440.05; Fla. Admin. Code 69L-6.021 | |
| Employ anyone who handles fuels or chemicals | A written HazCom program, SDS access every shift, and a written PPE hazard assessment | 29 CFR 1910.1200(e), (g); 1910.132(d)(2) | |
| Have more than 10 employees in a year | OSHA 300 / 300A / 301 logs (tree services, NAICS 561730, are not exempt); every employer reports a fatality within 8 hours and a hospitalization, amputation or eye loss within 24 hours | 29 CFR 1904.1, 1904 Subpart B App. A, 1904.39 | |
| Sign a residential direct contract over $2,500 for an "improvement" (planting, excavation) | The construction-lien notice in the contract; whether pure tree removal counts is a question for counsel | Fla. Stat. 713.015, 713.01 | |
| Sign an estimate at the customer's home | The three-day right-to-cancel notice (check the exclusions with counsel) | Fla. Stat. 501.021–501.055 | |
| Sell plants, mulch or goods without installation | Sales-tax registration; a resale certificate is normally not used by a contractor improving real property; confirm with the CPA | Fla. Stat. ch. 212; Fla. Admin. Code 12A-1.051 | |
| Own a crane, knuckleboom or bucket truck | Documented annual inspections (and dielectric tests for insulated aerial devices) | 29 CFR 1910.180(d), 1910.67; ASME B30.5; ANSI A92.2 | |
| Operate at all | City (if inside city limits) and county business tax receipts, valid Oct 1–Sept 30, renewed by Sept 30; the Sunbiz annual report Jan 1–May 1 | Fla. Stat. ch. 205, 205.053; 605.0212, 605.0714 | |

---

## 13. How this maps onto Buckets, today and later

### 13.1 Fits today (no app change)

- **Equipment rows** for owned units worth $1,000 or more (BRIEF §2.2 today; the "$1,000 over its life" rule arrives with plan slice 1): saws, pole pruner, GRCS, chippers, loaders, mini excavator, trucks, trailers. Seven inputs plus cost of money → one stored rate in cents, snapshotted into each project and multiplied by project hours (DECISIONS 7, 13, 14, 17). Each unit needs one delivered price with evidence, not a planning range.
- **Materials rows** for nearly all 51 source material rows, each becoming a priced row only once a quote or product page gives a unit price. Reusable ground mats and barriers are not materials.
- **Consumables rows** for job supplies (tarps, plywood, flagging, paint, tape, bags, injection tips, cones used up), disposal by the load, and permits.
- **Overhead lines** for devices and software ($0 checklist lines today), routine PPE, and shop supplies.
- **Subcontractors** for stump grinding, crane, grapple truck, concrete and drainage structures.
- **Loadouts** (crew formations) for the lanes; **Packages** (saved projects) for the lanes' material and consumable composition. Neither ships in the default edition (DECISIONS 64).

### 13.2 Planned (the equipment-classes plan, `docs/treeshop/12-equipment-classes-plan.md`; not merged as of 2026-09-28)

- **Wear parts as the sixth rate component**, inside the row's calc inputs as a list; no schema change; the rate stays one division (slice 1). Chain, bar, sprocket, files, pole-saw chain and bar, chipper knives, grinder teeth, filters, plugs, belts, batteries become wear lines on their units.
- **Ten equipment classes with prefixes**, owned/rented, track-only rows, in-service and retire-by dates, transfer format 3 (slice 2).
- **The fleet sheet** (a CSV, one row per unit, blank cells take class defaults) as the way a whole fleet enters Buckets remotely; the standard's equipment rows become that template's per-class examples, never default catalog rows (slice 3).
- **Bulk review** (slice 4).
- **The documents shelf extension** (Section 9.3).

**Picking a saw brings its bar and chain** with no new model: the saw row's wear lines carry the bar and chain, copied (not linked) from the consumables price rows; a loadout turns the saw on; the project line snapshot keeps the priced rate; Re-price refreshes it on purpose; a later price change only flags the row for review.

### 13.3 Phased path

| Phase | What | Gate |
|---|---|---|
| 0 (now, no app code) | Freeze the three lists as this Baseline; fix the list and catalog errors (FINDINGS.md); drop the Customer View tab; move devices to overhead; add disposal and permits; apply catalog fixes through a merge file with evidence and dates | none |
| 1 | Wear lines, the lifetime-cost line, repair-factor and bar-oil double-count help, "Add from catalog…" copy picker; re-enter the company's saws with wear lines | owner confirms which units are owned |
| 2 | Classes, prefixes, owned/rented, track-only, dates, format 3 | plan merged and DECISIONS written |
| 3 | Fleet-sheet CSV and bulk review; lanes as an optional merge file | slice 2 shipped |
| 4 | Optional per-project equipment cost report; a stable standard-ID field if re-merging becomes routine | after about 20 real jobs priced |
| Out unless the owner amends the scope fence | Inventory counts, par and reorder; inspection logs; maintenance intervals; employee issue; vendor tables; multi-branch ownership | BRIEF §5.1 |

Where the source lists wanted more than the scope fence allows (inventory control, supplier triplets, inspection schedules, lanes, price ranges, technology as equipment), the resolutions are recorded in FINDINGS.md section 6.

---

## 14. Versioning and community

**Two numbers, kept separate.**

- **Schema** (the file format: columns, IDs, wear lines, connection rules) follows semantic versioning (Appendix B), e.g. schema 1.0.0. A breaking column change bumps the major, and Buckets declares which schema majors it can import.
- **Baseline** (the data) is numbered "Baseline N.M". N is the Buckets major it ships with (Baseline 1 ships inside Buckets 1.0). M is a dated point release for community additions and price refreshes between majors (Baseline 1.1, 1.2), each tagged in git and carrying a published date and a prices-seen date. Buckets minor releases bundle the newest Baseline available and record it in the About panel and on every exported quote ("priced against Baseline 1.3, 2027-02-14"). **This document is Baseline 0.1**: Buckets is at 0.2.x, so the first numbered edition sits under major 0 until Buckets 1.0 freezes Baseline 1.
- Row IDs are permanent across Baselines; a retired row is marked retired, never renumbered, so a company's edits survive upgrades. Buckets shows a diff when a new Baseline arrives and lets the owner accept per row.

**How anyone proposes a change.** Open a pull request against the `next` branch with: the row or rule; the evidence URL and the date seen; the proposed Confidence level (a contributor may propose `estimated` or `verified`; `verified` requires the URL and date; `ownerConfirmed` is reserved for the adopting company); and a one-line reason. Price refreshes and new rows are routine; changes to a Baseline *default* (the saw line, the nursery, a removed species, a boundary rule) also need the owner's yes.

**Who reviews.** The maintainers (Buckets' developers) review for evidence and schema; a point release is cut when a Buckets build ships or when enough has changed; the major is frozen only with the Buckets major. Companies override any row locally; the Baseline never overwrites a company's rows without the owner accepting the diff.

**License (recommendation for the owner to confirm; have a lawyer sanity-check before the first public release).** CC BY 4.0 for the data (the three lists and the rules) and the docs; MIT for any code (schemas, validators, import scripts). CC BY 4.0 covers database rights and requires attribution, which is the marketing point, while letting other tools and companies copy freely. CC0 would drop the credit; ODbL's share-alike deters adoption and is heavier to police. Caveats: individual facts (a part number, a price) are not copyrightable, so credit will come mostly from goodwill; and a license does not stop a fork from rebranding, so name protection comes from the project (org, domain, trademark search on the working name). Add a CONTRIBUTING file (contributions are CC BY 4.0), a CITATION file, and a note that vendor prices remain the vendors' own, recorded as seen on a date. Runner-up names and why they lost are in FINDINGS.md section 7.

---

## 15. Open questions for the owner

Each has a stable key; nothing is assumed until the owner answers and the office manager writes the answer on the Gates tab.

| Key | Question | What it switches |
|---|---|---|
| Q-TOWING | What are the door-jamb GVWR of each truck and the plate GVWR of the trailer? | 26,001 lb or more with the trailer over 10,000 lb switches on Class A CDL, USDOT, medical cards and annual inspections (Section 12) |
| Q-PHC | Do you do plant-health treatments for hire? | The FDACS Chapter 482 licence gate and the injection and drench consumables rows |
| Q-FERT | Do you apply fertilizer for hire? | The LUCF / GI-BMP gate and the Orange County June 1–Sept 30 blackout |
| Q-POND | Do you do pond, erosion or drainage work? | The erosion and drainage materials rows and the excavation class code |
| Q-GAUGE | MS 500i chain gauge: stay on .050 (the Baseline) or move to the approved .063 (36 RS family) with new bars and loops per saw? | Section 4.1 |
| Q-POLESAW | One standard pole saw: the 3016 family (cheaper, shares M18 batteries, 7–10 ft) or the 3013 telescoping (9–13 ft)? Until decided, replace like-for-like. | Section 4.6 |
| Q-OWNED | Which listed units are actually owned (the compact top-handle, the telescoping pole saw, how many ground saws)? | Phase 1 re-entry; archive rows not owned |
| Q-DINGO | Which engine is in the Dingo TX 525 (Kubota D902 on current units; D1105 on older ones: read the data plate)? | Filter and oil wear lines; hydraulic oil is Toro HYPR-Oil or a UTHF per the manual, never AW46 |
| Q-WINDMILL | Restore windmill palm (UF EP020 lists it for Central Florida) after DECISIONS 77 removed it? | Section 10.1; needs a new DECISIONS entry |
| Q-NAME | Confirm "OpenLoadout" (after a trademark search) and CC BY 4.0 + MIT, or choose otherwise. | Section 14 |
| Q-RESALE | Resale of taxable goods (plants or mulch sold without installation)? A CPA question. | The sales-tax registration row |
| Q-THRESHOLD | Track-only threshold: $1,000 over life everywhere, or a company setting? | Section 13.1 |
| Q-CHAINLOG | Who tags loops for the first six weeks? (The Parts issue log itself is the crew leader's; 7.0.) | Section 4.7 |

---

## Appendix A. Saw line reference (parts, prices, files, intervals)

Prices seen 2026-09-28 unless noted. Bailey's states it is not an authorized STIHL dealer; warranty parts and service go through an authorized dealer, which is also the first place to order from.

**Manuals (US editions):**
- MS 500i 0458-809-8621-B: https://ssc.stihl.com/tsa/techdoc-documents/DVS_STIHL/ZBA/ZBA/0458-809-8621-B_ZBA_02_01.pdf
- MS 201 T C-M 0458-599-8621-C: https://ssc.stihl.com/tsa/techdoc-documents/DVS_STIHL/ZBA/ZBA/0458-599-8621-C_ZBA_09_01.pdf
- MS 194 T 0458-568-8621-B: https://ssc.stihl.com/tsa/techdoc-documents/DVS_STIHL/ZBA/ZBA/0458-568-8621-B_ZBA_03_01.pdf
- MS 500i parts list (01.04.2021): https://www.chainsawpartsworld.com/wp-content/uploads/2022/11/Stihl-MS500i.pdf
- MS 201 TC-M parts list (12/15/2023): https://barryfrancisshop.com.au/wp-content/uploads/2023/12/MS201TC.pdf
- MS 194 T parts list (02/08/2023): https://indokita.co.id/wp-content/uploads/2022/07/MS-194-T-11370113050_id_en.pdf

**A.0 Order sheet (office manager)**

Order from the local authorized STIHL dealer first (warranty, same-day); the online fallback is the vendor whose price is cited in A.1. Starting quantities are for a fleet with three MS 500i and two climbing saws; scale by saw count.

| Part (exact spec) | Fits | Order from | Pack | Starting order qty | Last price + date |
|---|---|---|---|---|---|
| 33 RS 66 loop, 3623 005 0066 | MS 500i short bar | STIHL dealer; fallback Bailey's | 1 | 3 per saw + 2 reserve | $36.99, 2026-09-28 |
| 33 RS 84 loop, 3623 005 0084 | MS 500i long bar | STIHL dealer; fallback Bailey's | 1 | 3 per saw running the 25 in | $46.99, 2026-09-28 |
| 18 in bar 3003 008 8917 | MS 500i | STIHL dealer; fallback Foard's | 1 | 1 spare per two saws | $56.99, 2026-09-28 |
| 25 in Rollomatic ES 3003 000 4030 | MS 500i | STIHL dealer; fallback Foard's | 1 | 1 per saw that runs long | $101.99, 2026-09-28 |
| Rim sprocket 3/8 7T 0000 642 1223 | MS 500i | STIHL dealer; fallback Bailey's | 1 | 1 per saw | $12.99, 2026-09-28 |
| 63 PS3 44 loop, 3616 005 0044 | 201 T / 194 T 12 in | STIHL dealer; fallback stihlusa.com list | 1 | 3 per saw + 2 reserve | $22.99, 2026-09-28 |
| 63 PS3 55 loop, 3616 005 0055 | 201 T / 194 T 16 in | STIHL dealer; fallback Bailey's | 1 | 3 per saw running 16 in | $27.99, 2026-09-28 |
| 12 in Rollomatic E 3005 000 4805 | 201 T / 194 T | STIHL dealer; fallback Russo | 1 | 1 spare | $45.99, 2026-09-28 |
| 16 in Rollomatic E 3005 000 4813 | 201 T / 194 T | STIHL dealer; fallback Foard's | 1 | 1 spare | $53.99, 2026-09-28 |
| Spur sprocket 3/8 P 6T 1145 640 2010 | MS 201 T C-M | STIHL dealer; fallback Forester Shop | 1 | 1 per saw | $32.99, 2026-09-28 |
| Spark plug NGK CMR6H 0000 400 7011 | all STIHL saws | STIHL dealer; fallback SawAgain | 1 | 1 per saw + 2 | $6.24, 2026-09-28 |
| Air filter HD2 1144 140 4402 | MS 500i | STIHL dealer; fallback Bailey's | 1 | 1 per saw per year | $21.99, 2026-09-28 |
| Air filter 1137 120 1604 / 1145 140 4404 | 194 T (193 T) / 201 T | STIHL dealer; fallback Bailey's | 1 | 1 per saw per year | $10.29 / $10.69, 2026-09-28 |
| 2-in-1 guide 5605 750 4305 (3/8) and 5605 750 4303 (3/8 P) | per pitch | STIHL dealer; fallback Ohio Power Tool | 1 | 1 per pitch per truck | $54.99 each, 2026-09-28 |
| Round files 13/64 in and 5/32 in (Pferd dozen) | per pitch | TreeStuff | 12 | 1 dozen per size | $31.99 per dozen ($2.67 each), 2026-09-28 |
| Milwaukee chain 49-16-2723 (40 DL) | 3016-21PS | Ohio Power Tool | 1 | 2 | $27.97, 2026-09-28 |
| Milwaukee chain 49-16-2759 (46 DL) | 3013-21 | Ohio Power Tool | 1 | 2, only if the 3013 is owned | $27.97, 2026-09-28 |
| Round file 11/64 in (4.5 mm) | 3016-21PS | any | 1 | 2 | unverified |

**A.1 Parts, prices and evidence**

| Saw | Part | Number | Price | Evidence URL |
|---|---|---|---|---|
| MS 500i | 18 in bar | 3003 008 8917 | $56.99 | https://www.foards.com/products/3003-008-8917 |
| MS 500i | 25 in Rollomatic ES | 3003 000 4030 | $101.99 | https://www.foards.com/products/3003-000-4030 |
| MS 500i | 20 in bar | 3003 008 8921 | $67.99 | https://www.ohiopowertool.com/stihl-3003-008-8921 |
| MS 500i | 25 in ES Light | 3003 000 2231 | $174.99 | https://pandpsmallengines.com/products/stihl-3003-000-2231 |
| MS 500i | 33 RS 66 | 3623 005 0066 | $36.99 | https://www.baileysonline.com/stihl-18-chainsaw-chain-loop-33rs-66-drive-links-3623-005-0066.html |
| MS 500i | 33 RS3 66 (green label) | 3624 005 0066 | $36.99 | https://www.baileysonline.com/stihl-18-chainsaw-chain-loop-33rs3-66-drive-links-3624-005-0066.html |
| MS 500i | 33 RS 84 | 3623 005 0084 | $46.99 | https://www.baileysonline.com/stihl-24-chainsaw-chain-loop-33rs-84-drive-links-3623-005-0084.html |
| MS 500i | 33 RS 72 | 3623 005 0072 | $39.89 | https://www.baileysonline.com/stihl-20-chainsaw-chain-loop-33rs-72-drive-links-3623-005-0072.html |
| MS 500i | Rim sprocket 3/8 in 7T | 0000 642 1223 | $12.99 | https://www.baileysonline.com/stihl-rim-sprocket-sd7-375-x-7-tooth.html |
| MS 500i | Air filter HD2 | 1144 140 4402 | $21.99 | https://www.baileysonline.com/chainsaws/chainsaw-parts/air-filters.html |
| MS 500i | Fuel pickup body | 0000 350 3518 | $7.49 | baileysonline.com (per the 2026-09-28 fleet-saw check; parts list position 58) |
| MS 500i | 18 in bar + two 33 RS3 66 kit (Florida dealer) | 3003 005 9903 | $117.99 | https://www.mainstreetmower.com/products/stihl-bar-chain-kit-18-guide-bar-33-rs3-66-3003-005-9903 |
| MS 500i | 2-in-1 guide 3/8 in | 5605 750 4305 | $54.99 | https://www.ohiopowertool.com/stihl-5605-750-4305 |
| All | Spark plug NGK CMR6H | 0000 400 7011 | $6.24 | https://www.sawagain.com/products/ngk-cmr6h-spark-plug |
| 201 T / 194 T | 12 in Rollomatic E | 3005 000 4805 | $45.99 (Bailey's $79.99) | https://russopower.com/products/stihl-3005-000-4805-rollomatic-e-chain-saw-bar-12 |
| 201 T / 194 T | 14 in Rollomatic E | 3005 000 4809 | $52.99 ($48.99 Foard's) | https://www.ohiopowertool.com/stihl-3005-000-4809 |
| 201 T / 194 T | 16 in Rollomatic E | 3005 000 4813 | $53.99 | https://www.foards.com/products/3005-000-4813 |
| 201 T / 194 T | 63 PS3 44 | 3616 005 0044 | $22.99 | https://www.stihlusa.com/en/ap/picco-super-3-ps3-3-8%22-050%22-1027153 |
| 201 T / 194 T | 63 PS3 50 | 3616 005 0050 | $25.99 | https://www.baileysonline.com/stihl-14-chainsaw-chain-loop-63ps3-50-drive-links-3616-005-0050.html |
| 201 T / 194 T | 63 PS3 55 | 3616 005 0055 | $27.99 | https://www.baileysonline.com/stihl-16-chainsaw-chain-loop-63ps3-55-drive-links-3616-005-0055.html |
| 201 T / 194 T | Carbide 63 PD3 50 (diamond wheel) | 3612 005 0050 | $73.99 | https://www.baileysonline.com/stihl-14-carbide-saw-chain-loop-63pd3-50-drive-links-3612-005-0050.html |
| 201 T | Spur sprocket 3/8 in P 6T | 1145 640 2010 | $32.99 | https://forestershop.com/stihl-3-8-picco-6-tooth-spur-sprocket-kit-ms201-ms201t/ |
| 201 T | Fleece air filter | 1145 140 4404 | $10.69 | https://www.baileysonline.com/chainsaws/chainsaw-parts/air-filters.html |
| 194 T | Spur sprocket 3/8 in P 6T | 1137 640 2005 | bare part unverified; OEM drum kit $48.98 | https://sawagain.com/products/stihl-ms-192t-193t-194t-020t-ms-200t-3-8-pitch-clutch-drum-spur-sprocket-new-oem-11376402007 |
| 194 T | Fleece air filter (also 193 T) | 1137 120 1604 | $10.29 | https://www.baileysonline.com/chainsaws/chainsaw-parts/air-filters.html |
| 194 T | Rollomatic E Light 14 in / 16 in | 3005 000 7409 / 7413 | $98.99 / $105.99 | https://www.foards.com/products/3005-000-7413 |
| 201 T / 194 T | 2-in-1 guide 3/8 in P | 5605 750 4303 | $54.99 | https://www.ohiopowertool.com/stihl-5605-750-4303 |
| Files | Pferd round files, dozen (13/64 or 5/32) | — | $31.99 | https://www.treestuff.com/pferd-dozen-round-chainsaw-files/ |
| Milwaukee 3016 | Chain 3/8 LP .043 40 DL | 49-16-2723 | $27.97 | https://www.ohiopowertool.com/milwaukee-tools-49-16-2723 |
| Milwaukee 3013 | Chain .325 LP .043 46 DL | 49-16-2759 | $27.97 | https://www.ohiopowertool.com/milwaukee-tool-49-16-2759 |
| Milwaukee 3016 | Battery FORGE XC8.0 | 48-11-1881 | $229.00 | https://www.ohiopowertool.com/milwaukee-tools-48-11-1881 |
| Milwaukee 3013 | Battery FORGE HD12.0 | 48-11-1813 | $279.00 | https://www.ohiopowertool.com/milwaukee-tools-48-11-1813 |

STIHL file table (manual 0458-599-8621-C §26): 3/8 in → 5.2 mm (13/64 in) file 5605 772 5206, holder 5605 750 4329; 3/8 in P → 4.0 mm (5/32 in) file 5605 772 4006, holder 5605 750 4327; file gauge 1110 893 4000; flat file 0814 252 3356. Depth gauge setting 0.65 mm (0.026 in) on both. Minimum groove depth: 6 mm for 3/8 in bars; 5 mm for 3/8 in P bars.

**A.2 Wear intervals for costing (all saws)**

| Part | Interval | Level | Basis |
|---|---|---|---|
| Chain loop | 40 h, or the owner's baseline on the 500i | rule of thumb / owner baseline | No STIHL hour figure; calibrate from the Parts issue log |
| Guide bar | 200 h | rule of thumb | STIHL condition: groove depth minimum; flip at every chain change |
| Sprocket | two loops (80 h at the rule of thumb) | manufacturer condition | New sprocket after two chains or at 0.5 mm wear marks (all three manuals) |
| Spark plug | 100 h | manufacturer | All three manuals |
| Air filter | 300 h | rule of thumb | Manuals say clean; one a year is a costing allowance |
| Fuel pickup body (500i) | yearly, dealer | manufacturer | $7.49 [V 2026-09-28] Bailey's |
| Chain brake service | every 3 / 6 / 12 months by heavy / part-time / occasional use, dealer | manufacturer | Cost unverified |
| Pole-saw battery | 2–3 years or 500 charge cycles [rule of thumb] | rule of thumb | Milwaukee publishes no hour life; log replacement dates |

## Appendix B. Vocabulary

| Term | Meaning |
|---|---|
| Baseline | A frozen, numbered edition of this standard that ships with a Buckets release |
| Bucket | One of Buckets' six cost groups: Labor, Equipment, Materials, Consumables, Subcontractors, Overhead |
| Row | One line in a bucket: a priced thing |
| Unit / unit code | One physical piece of equipment and its short crew name (SAW-01) |
| Class prefixes | TRK truck · TRL trailer · MCH machine (mini skid, chipper, grinder) · PBH pole and battery hand tools · AER aerial device · ATT attachment · SAW chainsaw / PSW pole saw · CLM climbing gear / RIG rigging gear · KIT kits (first aid, traffic, ground protection) · PPE issued protective gear |
| Unit hours | The door-to-door hours of the projects a unit went on; the only hour basis in this standard |
| Configuration | What a unit is set up with (bar, chain, sprocket, file) |
| Loop | One chain, joined in a circle, sized to one bar |
| Bar / sprocket | The blade the chain rides on / the toothed wheel that drives it; rim sprockets are replaceable rings, spur sprockets are one piece with the drum |
| Drive links (DL) | The count of links that ride in the bar groove; with pitch and gauge it defines a loop |
| Pitch / gauge | Half the distance between three rivets (3/8 in, 3/8 in P, .325 in) / the drive-link thickness (.043, .050, .063 in) |
| PICCO (3/8 in P) | STIHL's low-profile 3/8 in pitch chain family for small saws |
| Full chisel / semi-chisel | Square-cornered cutters (faster, dull sooner in dirt) / rounded cutters (slower, tougher in dirty wood) |
| Green-labeled | STIHL's marking for chains and bars that meet the low-kickback requirement of ANSI B175.1 |
| Rollomatic | STIHL's bar family (E laminated with a sprocket nose; ES solid with a replaceable nose; Light versions weigh less) |
| Depth gauge | The raker in front of each cutter; filed to 0.65 mm (0.026 in) below the cutter |
| Flip the bar | Turn the bar over at each chain change so both rails wear evenly |
| Kickback | The saw's bar jumping up and back at the operator when the nose tip catches; the reason for approved combinations and chain brakes |
| Wear part / wear line | A consumable a specific unit wears out / the cost-spreading entry on that unit's row |
| Track-only | An equipment row kept for identity and dates, priced at $0/h |
| Loadout | A named crew formation of people and units applied to a project |
| Lane | A service type (pruning, removal, planting, plant health) with its usual crew and kit |
| Package | A saved project used as a starting point |
| Takeoff | The measured list of materials a project needs |
| Par / Min | Order-up-to level / reorder point |
| Rotation stock | Sharp spares per saw, separate from the reorder buffer |
| Poisson 95% quantile; z × σ × √t | Two safety-stock formulas: the first for items used a few times a period, the second (z = 1.65, σ = the spread of daily usage, t = lead time + review days) for fast movers |
| Snapshot / Re-price | The copy of a row's rate taken when a project line is created / refreshing a project's snapshots on purpose |
| Confidence | missing · estimated · ownerConfirmed · verified |
| Gate | A yes/no question that switches services, rows and documents on or off |
| Scope fence | The list of things Buckets deliberately does not do (BRIEF §5.1): inventory, vendor tables, scheduling, HR |
| Merge file | A JSON file of rows that Buckets adds or updates; it never deletes |
| Fleet sheet | The planned CSV, one row per unit, for entering a whole fleet |
| Transfer format 3 | The planned export/import file version that carries classes and dates |
| Calc inputs | The seven numbers on an equipment row that make its rate |
| Vault | The encrypted backup folder outside the app |
| Readiness | The Buckets screen that says whether the company can price (identity, rows, gates) |
| Workbook | openloadout-workbook-0.1.xlsx: Issues, Counts, Locations, Gates, Documents, Vendors |
| Porta-Wrap | A friction device bolted to the trunk that lets the ground worker lower a cut limb under control |
| GRCS | Good Rigging Control System: a winch-and-bollard lowering device mounted on the tree |
| Mini skid | A stand-on compact track loader (the Toro Dingo) that carries a grapple, bucket or grinder |
| DBH | Trunk diameter at breast height, 4.5 ft above grade |
| CT | Clear trunk: a palm's trunk height below the fronds |
| Semantic versioning | major.minor.patch; a breaking change bumps the major |
| SDS / HazCom | Safety Data Sheet, the maker's hazard sheet for a chemical / OSHA's hazard-communication rule that requires them |
| COI | Certificate of insurance (ACORD 25) |
| LUCF / GI-BMP | FDACS fertilizer applicator certificate / the UF Green Industries training that precedes it |
| FISC | Florida Invasive Species Council; publishes the Category I and II invasive plant list |
| EDIS | UF/IFAS Electronic Data Information Source, the fact-sheet library |
| BTR | Business tax receipt (city or county) |
| NAICS | Federal industry code; tree services are 561730 |
| GVWR / GCWR | A vehicle's rated maximum weight / a combination's rated maximum weight |
| CMV | Commercial motor vehicle as defined by the regulation cited |

## Appendix C. Documents checklist (office manager)

File in: **Buckets > Company > Documents** (category in brackets). "Always" = every company. Gates are Section 12 questions. Sensitive documents are never emailed as numbers (9.2). Sources: Florida statutes 2025, FDACS, FLHSMV, FMCSA, OSHA, IRS; checked 2026-09-28 unless noted; Sunbiz and FMCSA pages must be opened by hand.

| Document | Needed if | Get it from | Who fetches | Renew by | File in |
|---|---|---|---|---|---|
| Articles of organization and operating agreement | Always | sunbiz.org entity page; the signed copy | Owner | On amendment | Company |
| Sunbiz LLC annual report | Always | https://efile.sunbiz.org/llc_ar_help.html | Office manager | May 1 yearly (dissolved the fourth Friday of September if unfiled; last filing cutoff the third Friday: Fla. Stat. 605.0714) | Company |
| EIN letter (CP 575 or 147C) | Always | Company records; IRS 800-829-4933 for a 147C | Owner | Never | Company (sensitive) |
| City business tax receipt | Office inside city limits (Apopka: https://www.apopka.gov/1092/Apply-or-Renew) | City portal | Office manager | Sept 30 yearly | Company |
| County business tax receipt | Always | https://www.octaxcol.com/taxes/business-taxes/ **[V 2026-09-28]** | Office manager | Sept 30 yearly; penalties from Oct 1 | Company |
| General liability policy (declarations, endorsements) | Always | Agent / carrier portal | Owner | Policy renewal | Company (sensitive) |
| Commercial auto policy, schedule of autos, ID cards | Always | Agent | Owner | Policy renewal; reprint when units change | Company (sensitive) |
| Inland marine / equipment policy and schedule | If equipment is insured | Agent | Owner | Renewal; update schedule when a unit is added | Company (sensitive) |
| Workers' comp policy or DFS exemption certificates | Always (policy with any employee; exemption per exempt member) | Agent; https://myfloridacfo.com/division/wc/employer/exemptions/construction | Owner | Policy yearly; exemption every 2 years, $50 | Company (sensitive) |
| Certificates of insurance issued (ACORD 25) and request log | When a customer or GC asks | Agent | Office manager | Reissue at renewal for open accounts | Company (sensitive) |
| FDACS LUCF fertilizer certificate + GI-BMP certificate, per applicator | Gate Q-FERT | https://aeslicensing.fdacs.gov/; GI-BMP via https://ffl.ifas.ufl.edu | Office manager | 4 years, 4 CEU | Company |
| FDACS pest control business licence (Ch. 482) or LCLM certificates | Gate Q-PHC | https://aeslicensing.fdacs.gov/ | Owner | Yearly ($300 per location) | Company |
| FDACS nursery stock dealer registration | If plants are bought and installed | https://www.fdacs.gov/Agriculture-Industry/Plants-and-Nurseries/Nursery-and-Stock-Dealer-Registration | Office manager | Yearly ($25 or $69) | Company |
| USDOT number and MCS-150 | Gate Q-TOWING | https://www.fmcsa.dot.gov/registration (by hand) | Owner | Biennial update | Company |
| ISA Certified Arborist (and TRAQ) certificates | If held or relied on | https://www.isa-arbor.com | Office manager | 3 years, 30 CEU | Company |
| Equipment loans, UCC-1 filings, payoff and lien releases | Any financed unit | Lender; https://www.floridaucc.com | Owner | Until release + IRS period | Company (sensitive) |
| Bank statements, year-end books, tax returns | Always | Bank portal; CPA | Owner | Monthly / yearly | Outside Buckets (accounting) |
| Reemployment tax (RT-6) and new-hire reports | Any employee | https://floridarevenue.com or payroll provider | Payroll provider | Quarterly; new hire within 20 days | Outside Buckets (payroll) |
| Sales-tax registration / resale certificate DR-13 | Gate Q-RESALE | https://floridarevenue.com | CPA | Yearly | Tax (sensitive) |
| HazCom program, chemical inventory, PPE hazard assessment | Any employee | Company-written; https://www.osha.gov/hazcom | Owner | Yearly and on each new chemical | Safety |
| OSHA 300 / 300A / 301 | More than 10 employees | https://www.osha.gov/recordkeeping/forms | Office manager | 300A posted Feb 1–Apr 30; keep 5 years | Outside Buckets (medical) |
| Bill of sale and a dated replacement quote | Every owned unit | Dealer | Office manager | Quote refreshed yearly | Equipment, against the unit code (sensitive) |
| Title and registration | Every truck; trailers of 2,000 lb or more (Fla. Stat. 319.20) | https://www.octaxcol.com; https://www.flhsmv.gov | Office manager | Registration yearly | Equipment (sensitive) |
| Serial / VIN record with data-plate photo | Every unit with a serial | Photograph at intake | Crew leader | Never | Equipment row, private field |
| Owner's manual and approved bar-and-chain table | Every unit | stihlusa.com, toro.com, milwaukeetool.com | Office manager | On revision | Equipment |
| Warranty registration | Every new unit (STIHL professional saws: 3 months **[V 2026-09-28]**) | Manufacturer registration page | Office manager | Set expiry | Equipment (sensitive) |
| Service records | Every unit (mandatory for a CMV) | Dealer / shop; service invoices | Crew leader books; office manager files | Unit's life | Equipment |
| DOT annual inspection | Gate Q-TOWING (CMV) | Qualified inspector | Crew leader | 12 months | Equipment |
| Life-safety equipment log (ropes, saddles, lanyards, Porta-Wraps, blocks) | Every life-support device | Company log; maker's instructions (samsonrope.com, teufelberger.com, petzl.com); ANSI Z133-2026 | Crew leader | Before each use; retire per maker | Equipment (retire-by date on the row) |
| Crane / aerial annual inspection and dielectric test | If owned | Third-party inspector | Owner | Yearly | Equipment |
| Extinguisher service tags | Each extinguisher | Licensed service firm | Crew leader | Monthly visual; yearly service | Equipment |
| SDS: MotoMix, HP Ultra, Platinum bar oil (2025-7 revisions) | If stocked | https://www.stihlusa.com/safety/data-sheets/ **[V 2026-09-28]** | Office manager | On revision | Safety, against the consumable row |
| SDS: diesel engine oil, pump gasoline and diesel, every other chemical (hydraulic oil, grease, paint, herbicides) | Each chemical on hand | Maker's SDS page | Office manager | On revision; chemical list kept 30 years | Safety |
| Supplier quotes and invoices | Every purchase and price update | Vendor portal / email | Office manager | At the row's review date | Supplier, against the material row |
| Nursery grade statement (Florida #1 or better) on the ticket | Every plant bought | Nursery invoice | Crew leader at delivery | Per purchase | Project |
| Plant warranty terms (vendor's and the company's) | Every planting job | Nursery (request in writing with the wholesale account; unverified) | Office manager | Per warranty period | Supplier; copy against the project |
| Delivery and dump tickets | Every load in or out | Driver / scale house | Crew leader | Per load | Project |
| Signed estimate or contract (lien notice if over $2,500 and an improvement: Fla. Stat. 713.015) | Every job | Company template | Office manager | Per job | Project (sensitive) |
| Three-day right-to-cancel notice (Fla. Stat. 501.021) | Estimate signed at the home | Contract template | Office manager | Per job | Project (sensitive) |
| Change orders | Any scope or price change | Company template | Office manager | Per change | Project (sensitive) |
| Tree removal permit or the written reason none is needed | Every removal | Orange County Fast Track; Apopka OpenGov | Office manager | Per job | Project |
| Tree risk assessment (ISA Certified Arborist or Florida licensed landscape architect, Fla. Stat. 163.045) | Removal relying on 163.045 | The assessor | Office manager | Per job | Project (sensitive) |
| Sunshine 811 ticket number | Any grinding, digging, planting or anchoring | https://sunshine811.com | Crew leader | Per job; renew after 30 days | Project notes |
| Before / after photos | Every job | Crew phones | Crew leader | Per job | Project |
| Sign-off and final invoice | Every job | Company template | Office manager | Per job | Project (sensitive) |
| Sub's W-9 | Every sub before first payment (1099-NEC threshold $2,000 for payments after 2025-12-31) | https://www.irs.gov/forms-pubs/about-form-w-9 | Office manager | On change; keep 4 years | Subcontractor (sensitive) |
| Sub's COI with WC or DFS exemption | Every sub before work starts | Sub's agent; verify at https://myfloridacfo.com/division/wc/ | Office manager | Sub's policy renewal | Subcontractor (sensitive) |
| Sub's licences (crane inspection and operator cert; USDOT; BTR) | Per service | The sub | Office manager | Per document | Subcontractor |
| Subcontract agreement | Every regular sub | Company template | Owner | Yearly review | Subcontractor |
| Vendor account terms and wholesale approval | Each vendor account | Vendor | Owner | On change | Supplier (sensitive) |
| Resale certificate given to a vendor; nursery registration copy | Gate Q-RESALE; nursery request | Florida DOR; FDACS | Office manager | Yearly | Tax (sensitive) |
| I-9, W-4, driver records and MVR, CDL and medical card, training records, individual credentials | Every employee (CDL items on gate Q-TOWING) | USCIS, IRS, FLHSMV, TCIA, Red Cross | Payroll provider / owner | Per rule | **Outside Buckets**: payroll provider or locked HR folder |

## Appendix D. Owner's notes: the MS 500i chain math

**Cost per week per saw** at the verified 18 in loop price ($36.99, Bailey's **[V 2026-09-28]**):

| Chains per week | Per saw per week | Per saw per year (50 weeks) | Three MS 500i per week | On the 25 in bar (33 RS 84, $46.99) |
|---|---|---|---|---|
| 3 | $110.97 | $5,548.50 | $332.91 | $140.97 |
| 4 | $147.96 | $7,398.00 | $443.88 | $187.96 |
| 5 | $184.95 | $9,247.50 | $554.85 | $234.95 |

At 6 h/week (300 h/yr) that is $18.50–$30.83 per saw-hour, against $0.92 per hour, 7.5 loops and $277 a year at the 40-hour [rule of thumb].

**Three readings reconcile it:**

| Reading | What it implies | Cost per saw-hour |
|---|---|---|
| (a) The 500i runs far more than 300 h/yr | At 1,000 h/yr (20 h/week): a chain every 4–6.7 h, $5.55–$9.25/h. At 1,500 h/yr (30 h/week, the Buckets billable-hours default): every 6–10 h, $3.70–$6.17/h. | as shown |
| (b) "Go through" counts chains swapped out for sharpening | At 10–15 sharpenings per loop [rule of thumb], 3–5 swaps a week retire only 0.2–0.5 loops: $7.40–$18.50 per saw per week. | about $1.23–$3.08/h at 6 h/week |
| (c) 3–5 is for all three 500i together | One third per saw. | one third of the table above |

**The two-rate arithmetic (Section 5.2), part by part over 2,000 h.** Rule of thumb: chain 50 × $36.99 = $1,849.50; bar 10 × $56.99 = $569.90; sprocket 25 × $12.99 = $324.75; plug 20 × $6.24 = $124.80; filter 7 × $21.99 = $153.93; pickup 7 × $7.49 = $52.43; total $3,075.31 → $1.5377/h; rate 0.7920 + 0.8800 + 4.50 + 1.5377 = $7.71/h (771¢); lifetime $1,759.99 + $1,759.99 + $3,075.31 = $6,595.29. Owner baseline read literally: chain 1,334 × $36.99 = $49,344.66; sprocket at the manual's two-loops rule, every 3 h, 667 × $12.99 = $8,664.33; the other lines as before; total $58,910.05 → $29.455/h; rate $35.63/h (3,563¢); lifetime $62,430.03. (Holding the sprocket at 80 h in that column instead gives $50,570.47, $31.46/h and $54,090.45; the two-loops rule is the manual's and is used.)

## Appendix E. Principal sources

- STIHL USA product pages (prices, 2026-09-28): MS 500i https://www.stihlusa.com/en/p/chainsaws-ms-500i-1027221 · MS 201 T C-M https://www.stihlusa.com/en/p/chainsaws-ms-201-gasoline-chainsaw-1027365 · MS 194 T https://www.stihlusa.com/products/chain-saws/in-tree-saws/ms194t/ · STIHL 2026 warranty https://www.stihlusa.com/content/dam/stihl/vu/us/en/download-files/pdf-files/warranty/handheld_goods_warranty_final26_VU_D_2025-1.pdf · SDS index https://www.stihlusa.com/safety/data-sheets/
- STIHL US instruction manuals and parts lists: Appendix A.
- Milwaukee: https://www.milwaukeetool.com/products/details/10-inch-3-8-low-profile-pitch-043-gauge-saw-chain/49-16-2723 · https://www.milwaukeetool.com/products/details/10-inch-325-low-profile-pitch-saw-chain/49-16-2759 · https://www.milwaukeetool.com/products/details/m18-fuel-pole-saw-w-quik-lok-kit/3016-21PS · batteries https://www.milwaukeetool.com/products/details/m18-redlithium-forge-xc8-0-battery-pack/48-11-1881 · https://www.milwaukeetool.com/products/details/m18-redlithium-forge-hd12-0-battery-pack/48-11-1813
- Oregon 72LPX reel (Bailey's): https://www.baileysonline.com/oregon-25-chainsaw-chain-reel-72lpx-410-drive-links-72lpx025u-orf-72lpx025r.html
- Toro Dingo TX 525 Wide, model 22324 (Kubota D902E3B diesel, 553 lb ROC, $32,976.00 **[V 2026-09-28]**): https://www.toro.com/en/product/22324
- Cherrylake: https://cherrylake.com/ · availability https://cherrylake.com/products/ · public retail https://cherrylakecommunities.com/ · Pebble Junction: https://www.pebblejunction.com/
- UF/IFAS: EP020 Ornamental Palms for Central Florida https://ask.ifas.ufl.edu/publication/EP020 · ST342 crape myrtle https://ask.ifas.ufl.edu/publication/ST342 · PP163 lethal bronzing https://ask.ifas.ufl.edu/publication/PP163 · PP146 lethal yellowing https://ask.ifas.ufl.edu/publication/PP146 · PP100 Ganoderma https://ask.ifas.ufl.edu/publication/PP100 · PP278 Fusarium wilt https://ask.ifas.ufl.edu/publication/PP278 · EP001 palm transplanting https://ask.ifas.ufl.edu/publication/EP001 · EP261 palm fertilization https://ask.ifas.ufl.edu/publication/EP261
- FISC 2026 invasive plant list: https://www.floridainvasives.org/wp-content/uploads/2026/07/FISC-2026-Plant-List-Cat-I-II_April2026.pdf · UF/IFAS Assessment https://assessment.ifas.ufl.edu/
- Florida Grades and Standards for Nursery Plants (2022 ed.): https://ccmedia.fdacs.gov/content/download/103635/file/Grades-and-Standards-for-Nursery-Plants-2025.pdf · ANSI Z60.2-2025: https://americanhort.org/wp-content/uploads/2026/02/nursery-stock-standards.pdf
- Florida statutes (2025): 163.045, 205.053, 319.20, 316.302, 316.646, 440.02, 440.05, 440.10, 482.071, 482.156, 482.1562, 501.021, 556.105, 556.108, 581.131, 605.0714, 633.304, 713.01, 713.015 at https://www.flsenate.gov/Laws/Statutes/2025/ · Fla. Admin. Code 69L-6.021 https://flrules.org/gateway/ruleno.asp?id=69L-6.021
- FDACS: pest control https://www.fdacs.gov/Business-Services/Pest-Control/Licensing-and-Certification · nursery stock dealer https://www.fdacs.gov/Agriculture-Industry/Plants-and-Nurseries/Nursery-and-Stock-Dealer-Registration
- Orange County: fertilizer ordinance 2022-03 https://www.ocfl.net/Portals/0/Library/Environment/docs/ORA20220211_Ordinance2022_03_0-CERT.pdf · tree removal permit https://www.orangecountyfl.net/PermitsLicenses/Permits/TreeRemovalPermit.aspx · business tax https://www.octaxcol.com/taxes/business-taxes/ · City of Apopka BTR https://www.apopka.gov/236/Business-Tax-Receipt
- Federal: 49 CFR 383.91 https://www.law.cornell.edu/cfr/text/49/383.91 · 390.5 https://www.law.cornell.edu/cfr/text/49/390.5 · 393.95 https://www.law.cornell.edu/cfr/text/49/393.95 · 396.3 https://www.law.cornell.edu/cfr/text/49/396.3 · 29 CFR 1910.157 https://www.osha.gov/laws-regs/regulations/standardnumber/1910/1910.157 · 1910.1200 https://www.osha.gov/laws-regs/regulations/standardnumber/1910/1910.1200 · 1904 App. A https://www.osha.gov/laws-regs/regulations/standardnumber/1904/1904SubpartBAppA · IRS recordkeeping https://www.irs.gov/businesses/small-businesses-self-employed/how-long-should-i-keep-records · 1099-NEC instructions https://www.irs.gov/instructions/i1099mec
- ANSI Z133-2026: https://www.isa-arbor.com/Publications/Z133-2026 · Sunshine 811: https://sunshine811.com/law
- Buckets repository (read-only): `utc-treeshop-buckets` on GitHub: docs/BRIEF.md, docs/DECISIONS.md (1–79), docs/treeshop/12-equipment-classes-plan.md. The project-organization URL is set before public release; the current location is recorded in FINDINGS.md.
- License references: https://wiki.creativecommons.org/wiki/License_Versions · https://wiki.openmod-initiative.org/wiki/Choosing_a_license

---

## Revision log (2026-09-28, after the readability and accuracy critiques)

- Retitled to Baseline 0.1 (draft); Section 14 and the title now agree; Baseline 1 ships with Buckets 1.0.
- Added a contents table, a "Start here" reader table, Section 0 (day one on the crew), 4.0 saw cards, 6.4 locations table, 7.0 the five named records with owners and places, 7.4 truck card and daily check sheet, A.0 order sheet, an expanded Appendix B glossary (class prefixes, loop, kickback, lanes, SDS, DBH and the rest), and Appendix C as a documents checklist table (document · needed if · get it from · who fetches · renew by · file in).
- Defined "unit hours" once (2.1) and rewrote rule 12; renamed the stock-unit vocabulary to `stock_unit`; "unit code" now means only the SAW-01 tag.
- Replaced every loose record name (register line, wear-part log line, issue line, chain log, loadout check sheet) with Equipment register, Parts issue log, Count sheet, Daily check sheet or Service invoices; the per-saw chain log is the Parts issue log filtered by unit code; roles are owner, office manager, crew leader, operator.
- 4.7 now leads with the instruction (3 loops in rotation + 2 reserve, tag, log); the weekly-cost table, the three readings and the part-by-part arithmetic moved to Appendix D.
- Section 5.2 worked example 2 recomputed with the fuel pickup body at $7.49 (upheld by the fleet-saw check) and the manual's two-loops sprocket rule in the owner-baseline column: rule of thumb $3,075.31 wear, $7.71/h, lifetime $6,595.29; owner baseline $58,910.05 wear, $35.63/h, lifetime $62,430.03. The 8-hour job contribution is $61.68.
- Corrected the Oregon 72LPX reel note (standard 3/8 .050, MS 500i class, never the top-handles), the 90PX pole-saw loop (40 DL, not the 34 DL SKU), the 56-DL top-handle loop, the discontinued Milwaukee batteries (now FORGE 48-11-1881 $229.00 and 48-11-1813 $279.00, verified at Ohio Power Tool), and the 2-in-1 guide price; all carried as FINDINGS IDs.
- Toro Dingo: the worked example's mini skid is repriced to the TX 525 Wide 22324 at $32,976.00 with diesel fuel (FINDINGS F-FLEET-04); engine model and hydraulic oil are open question Q-DINGO.
- Windmill palm is no longer "restored": it is pending Q-WINDMILL because DECISIONS 77 removed it and the palm research had no adversarial check. Palm count is 17 until answered. Crape myrtle carries the UF ST342 zone note and the reason it stays.
- Fla. Stat. 163.045 now names both providers (ISA Certified Arborist or Florida licensed landscape architect) in Section 12 and Appendix C.
- 4.2: 14 in is the recorded MS 193 T length; the MS 201 T's bar length is unrecorded. 13.1: the $1,000 rule is BRIEF §2.2's sticker rule today; the over-life rule arrives with plan slice 1.
- Section 12 gained the owner-answers / office-records line, the Florida-only note and an "Answered" column; Section 15 uses stable keys (Q-…); the gauge cross-reference is fixed.
- Section 9 opens with where to file today; 9.2 is split into office rules and developer rules; the open security finding, the customer-bid mention, live-store counts, the stored rate, the branch name and the personal GitHub handle were removed from the public text (kept in FINDINGS.md).
- Removed process history (refutation-pass notes, recomputation notes, naming-study scores, decision-number housekeeping). Old Appendix C (corrections), Appendix D (names) and 13.4 (scope-fence tensions) moved to FINDINGS.md. The illustrative issue line is tagged.
- Named the workbook openloadout-workbook-0.1.xlsx and added a "Using this without Buckets" box at the top of Section 5.
- Length: the public text grew from 911 to about 1,040 lines. The growth is the documents checklist (Appendix C, replacing a titles-only list), the glossary, the saw cards, the truck card and the order sheet, each answering a high-severity findability issue; the process history, the old corrections appendix, the name study and 13.4 were removed to offset it.
