# OpenLoadout

**What the truck carries. Open, versioned, shared.**

The open operating standard for service crews, starting with tree service. Each numbered release is a **Baseline**.

> **Status: Tree Service Baseline 0.1, draft, 2026-09-28.** This is the first numbered edition. It becomes **Baseline 1** when Buckets 1.0 ships. "OpenLoadout" is the working name until the owner confirms it after a trademark search (open question Q-NAME).

---

## What it is

1. OpenLoadout is a free, public master list of what a tree company runs on, sorted into three lists: **Equipment**, **Consumables** and **Materials**.
2. It sets the rules that connect those lists: a chain belongs to a saw, a saw belongs to a crew, and a palm belongs to the project it is planted on.
3. Every price and spec carries a source link and the date it was seen. A figure that could not be checked is labelled unverified, and nobody should price from it.
4. It is a default starting point with opinions (the STIHL professional saw line, a Central Florida plant list), and any company can swap brands, add rows or remove them.
5. Each full version of Buckets ships with the newest Baseline, so the list grows with every release and with every accepted contribution.

## Who it is for

- **Tree service owners** who want a vetted starting list instead of a blank spreadsheet.
- **Office managers** who order parts, count stock and keep the documents an auditor or insurer will ask for.
- **Crew leaders** who load trucks and need to know which chain, how many and which file.
- **Software builders and suppliers** who want a shared, citable vocabulary for tree-service gear. The data is meant to be reused, with credit.

You do not need Buckets to use it. The lists, the one-question tests, the counting method and the records work in any spreadsheet (STANDARD.md, top of Section 5).

## The three lists and how they connect

```
   EMPLOYEES  ──use──▶  EQUIPMENT  ──uses──▶  CONSUMABLES
   (each company's own)   (units with codes:      (stock on the shelf:
                          saws, trucks, ropes,    chains, bars, filters,
                          helmets, mini skid)     fuel, gloves, dump fees)

   PROJECTS   ──use──▶  MATERIALS
   (one priced job)       (bought to the takeoff, left on the customer's site:
                          palms, trees, mulch, sod, root barrier)

   SUBCONTRACTORS ── a separate section: another company's people or machine,
                     one flat bill (crane, grapple truck, stump grinding)
```

| List | The one question | How it becomes money |
|---|---|---|
| **Equipment** | Is it a durable thing we keep and could tag, inspect, retire and re-price as *this specific one*? | Hourly rate × project hours, or tracked at $0 below the cost threshold |
| **Consumables** | Is it used up or worn out by running the equipment, the crews or the job? | Wear parts and fuel sit inside the unit's hourly rate; job supplies are priced per job |
| **Materials** | When the crew drives away, is it still on the customer's property? | Unit price × quantity from the takeoff |
| Subcontractors (separate) | Does another company bring its own people or machine and hand us one bill? | Flat all-in price × quantity, never shown to the customer as a line |

Two rules catch most mistakes: **if it has a date, it is equipment** (ropes, saddles, helmets and extinguishers get a unit code and a retire-by date), and **if it comes back on the truck, it is not a material** (mats, cones and tarps are equipment).

Employees are unique to every company, so there is no employee list. Protective gear is filed by what it is and marked "issued to a person": helmets, saddles, chaps and harnesses are equipment; gloves, earplugs and glasses are consumables. Labor and overhead appear only as places where cost goes.

## What is in Baseline 0.1

| Part | Contents | Where |
|---|---|---|
| **The three lists** | 220 source rows under permanent IDs: 49 equipment (EQ-), 120 consumables (CON-), 51 materials (MAT-), each checked and re-homed by the one-question tests. The Buckets default catalog's 169 consumable and material rows were reconciled against them. Final per-list counts after re-homing and merging will be stated with the data-file release. | STANDARD.md §2, §11 |
| **The connection model** | Project → crew → truck → unit → configuration → wear part → shelf, with a quantity rule for every link | §3 |
| **The standard saw line** | Three STIHL saws, each with a short and a long bar on the stock STIHL pro bar, running STIHL professional chain from the US instruction manual's approved list | §4, Appendix A |
| **Costing** | The six-part hourly rate with wear parts itemised, two worked examples, and the owner's chain baseline with the math shown | §5, Appendix D |
| **Inventory** | Counts start at zero; min and par are derived from logged usage, never copied down a column | §6 |
| **Lifecycle records and 28 decision rules** | Receive, tag, check, issue, retire; rules a new hire can follow without judgment | §7, §8 |
| **Audit-ready data** | A register of 60 document types in eight scopes, an office-manager checklist of what to get and where, and security rules | §9, Appendix C |
| **Plant selection** | 17 palms and 15 trees for Central Florida (USDA zone 9b), plus the removed species and why | §10 |
| **Compliance gates** | 15 "if you offer X, you need Y" gates, with Florida and Orange County citations | §12 |

### The standard saw line

| Role | Model | Short bar and chain | Long bar and chain |
|---|---|---|---|
| Ground saw | STIHL MS 500i | 18 in, 33 RS 66 (3/8 in, .050 in, 66 DL) | 25 in, 33 RS 84 (84 DL) |
| Top-handle | STIHL MS 201 T C-M | 12 in, 63 PS3 44 (3/8 in P, .050 in, 44 DL) | 16 in, 63 PS3 55 (55 DL) |
| Compact top-handle | STIHL MS 194 T | 12 in, 63 PS3 44 | 16 in, 63 PS3 55 |

List prices were read on stihlusa.com on 2026-09-28: $1,759.99, $949.99 and $509.99. A saw is only ever replaced by the current standard model for its role, and existing saws are "honorarily upgraded", which means they are recorded and priced as that model. The chain preference is the professional option, in the larger size when the saw offers a choice. On both climbing saws the largest chain STIHL approves is 63 PS3 on a 1.3 mm (.050 in) bar. The manuals approve nothing larger than 3/8 in P for either saw, and the standard recommends no unapproved conversion. STANDARD.md §4.4 gives the manual citations.

### The plant selection

- **Palms (17):** grouped as *great* (dwarf palmetto, saw palmetto, European fan palm), *good* (cabbage palm and seven others) and *caution*. The caution group carries a written disease or cold disclosure.
- **Trees (15):** southern live oak, southern magnolia, bald cypress, 'Florida Flame' red maple, hollies, Shumard oak, crape myrtle (mildew-resistant hybrids only) and others.
- **Removed:** queen palm (a FISC Category II invasive and a Fusarium wilt host), plus other invasive, disease-prone or cold-tender species. The windmill palm is pending the owner's answer.
- **Sources:** checked against UF/IFAS fact sheets, the FISC 2026 invasive plant list, Florida Grades and Standards, and ANSI Z60.2-2025 sizing.
- **Still to do:** the plant list has had one research pass and has **not yet had an independent check**. Nursery wholesale prices are unverified until a quote is on file.

### The documents register

Sixty document types in eight scopes (Company, Equipment unit, Consumable, Material, Project, Subcontractor, Vendor, People). For each one the checklist gives who needs it, where to get it, who fetches it, when to renew it and where to file it. People documents (I-9, W-4, driver records) are kept outside Buckets. The goal is **audit-ready data**, one step up from audit-ready financials: every price, rate and quantity on a quote traces to a dated document, and every document the company must hold is present, current and findable.

### Honest limits of this edition

- It is a **draft**. Items that could not be checked are listed as unverified in FINDINGS.md §2.
- The compliance gates cite **Florida and Orange County** law. A company elsewhere replaces the citations with its own state's rules.
- The MS 500i chain figure of 3–5 chains per saw per week is **the first company's starting guess**, not a measured rate. The standard shows why it needs a log before anyone prices from it (§4.7, Appendix D).
- The source lists' marketing tab ("Customer View") was dropped. The standard makes no claims about outcomes for customers.

## How a company adopts it

Four moves: **pick** rows, **set brand defaults**, **add** your own, **remove** what you don't do.

1. **Read the three lists and the connection model** (STANDARD.md §2–3, about twenty minutes).
2. **Make your list.** Keep the services you offer, choose your brands and suppliers, and remove what you subcontract or don't sell.
3. **Enter your units.** Give every saw, truck and machine a unit code (SAW-01, TRK-02) and write its configuration down.
4. **Run the records.** Issue parts against a unit code, count stock weekly and check the truck daily.
5. **Let your numbers replace the guesses.** Logged usage replaces every rule-of-thumb and starting-guess figure, monthly.

**Worked example: Sacred Tree Service (Apopka, Florida).**

- **Brands and chain:** the STIHL professional saw line and the larger-chain preference.
- **Suppliers:** Cherrylake, Inc. (Groveland, FL) is the default nursery on a wholesale account. Pebble Junction (Sanford, FL) supplies stone and aggregate.
- **Machine:** a diesel Toro Dingo TX 525 mini skid.
- **Subcontracted:** crane, grapple truck and stump grinding.
- **Removed:** plant-health chemicals, pending a licence gate.
- **Starting point:** inventory at zero and technology spend at $0.

The details are in STANDARD.md §2.4.

## How it ships with Buckets

Buckets is a macOS pricing and operations app for tree service, maintained by UTC. STANDARD.md §13 maps the standard onto it.

- **Baseline N ships inside Buckets N.0.** Baseline 1 ships with Buckets 1.0. Buckets is at 0.2.x today, so this edition is numbered 0.1.
- **Point releases** (Baseline 1.1, 1.2, …) carry community additions and price refreshes between majors. Each one is tagged and dated, with the date its prices were seen.
- **The file format** has its own semantic version (schema 1.0.0). A breaking change bumps the major.
- **Row IDs are permanent.** A retired row is marked retired and never renumbered, so a company's edits survive upgrades.
- **Planned in Buckets:**
  - each exported quote records the Baseline it was priced against;
  - a new Baseline arrives as a diff that the owner accepts row by row, and it never overwrites a company's own rows;
  - the list of documents to find and get ships as a bundled `document-requirements.json`.
- **Available in Buckets today:** documents are filed under **Company > Documents**, which shows expiry dates.

## How to contribute

Anyone can propose adding, changing or removing a row or a rule. Open a pull request against the `next` branch with the change, a source URL and the date you saw it, a proposed Confidence level and a one-line reason. Manufacturer documentation beats retailer listings, and law beats practice. Changes to a Baseline *default* (the saw line, the nursery, a removed species, a boundary rule) also need the project owner's yes. The full rules are in **[CONTRIBUTING.md](CONTRIBUTING.md)**.

## Files

| File | What |
|---|---|
| `STANDARD.md` | The standard itself: the three lists, the rules, the saw line, plants, documents, gates |
| `FINDINGS.md` | Corrections register: every error found in the source lists and the Buckets catalog, with the corrected value, evidence URL and date |
| `CONTRIBUTING.md` | How to propose a change |
| `CHANGELOG.md` | What changed in each Baseline |
| Company workbook, `document-requirements.json` | Named in the standard; not yet published |

## License (recommendation, pending the owner's confirmation)

The recommended license is **CC BY 4.0** for the data (the three lists and the rules) and the documentation, and **MIT** for any code (schemas, validators, import scripts).

- **Why:** CC BY 4.0 lets anyone copy and build on the data while requiring credit, and version 4.0 covers database rights.
- **Caveat 1:** individual facts such as a part number or a price are not copyrightable, so the credit depends mostly on goodwill.
- **Caveat 2:** a license does not stop a fork from renaming itself.
- **Vendor prices:** prices quoted in the data remain the vendors' own, recorded as seen on a date.

This recommendation is not legal advice. It is to be confirmed by the owner and checked by a lawyer before the first public release. Until a `LICENSE` file is committed, no license has been granted.

## Credits

**Maintained by UTC**, the company behind Buckets.
**First company on the standard: Sacred Tree Service LLC**, Apopka, Florida, the worked example throughout.
Specs and prices are cited to their manufacturers, suppliers, UF/IFAS, FDACS and the Florida Statutes. Each source keeps its own rights.
