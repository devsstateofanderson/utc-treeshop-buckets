# Changelog

All notable changes to OpenLoadout. Each release is a **Baseline**. Row IDs are permanent: a retired row is marked retired and never renumbered. "F-…" IDs point to the corrections register in FINDINGS.md, where each correction has its evidence URL and date.

## Baseline 0.1 (2026-09-28): first edition, the draft of Baseline 1

This is the first numbered edition. It becomes **Baseline 1** when Buckets 1.0 ships. It was built from three AI-drafted master lists: an equipment catalog, a consumables list and a materials list. Every row was checked against manufacturer, supplier, university and statute sources, each finding got an independent adversarial pass, and overturned findings were discarded.

### What changed from the source lists

- **Three lists, one owner model.** The standard keeps exactly three lists: Equipment, Consumables and Materials.
  - Employees use the equipment, the equipment uses the consumables, and projects use the materials.
  - Subcontractors are a separate section.
  - "Employee program" items were folded into Equipment (helmet, saddle, chaps, harness) or Consumables (gloves, earplugs, glasses), marked "issued to a person". There is no fourth list.
- **Permanent IDs.** The equipment catalog had no IDs. All 220 source rows now carry permanent IDs: 49 EQ, 120 CON and 51 MAT. The MAT numbering keeps the source's gaps.
- **Dropped the "Customer View" tab** and its marketing claims (F-LIST-03).
- **Re-homed rows by the one-question tests.**
  - 11 equipment catalog rows that were really consumables moved to Consumables: bar oil, 2-stroke oil, filters, engine oil, files, chains, slings, masks and gloves (EQ-022..032).
  - Kits and a $0 subscription left the equipment list.
  - Ropes, saddles, lanyards, mats, barriers, cones, kits and extinguishers moved from Consumables to Equipment, with retire-by dates (F-LIST-05).
- **Fuel, 2-stroke oil and bar oil are no longer project consumables.** They are costed on the unit's hourly rate. Their rows remain as price and stock sources (F-LIST-04, F-CAT-06).
- **Technology moved to overhead.** Apple devices and a software workspace were removed from Equipment and became overhead lines at $0 until something is bought (F-LIST-03, F-CAT-18).
- **Adopted the standard saw line.** The ground saw is the STIHL MS 500i, the top-handle is the MS 201 T C-M and the compact top-handle is the MS 194 T.
  - Each saw has a short and a long option on the stock STIHL pro bar, with chain from the US manual's approved list.
  - The replacement rule and the "honorary upgrade" rule were added. An MS 193 T is recorded and priced as an MS 194 T.
  - The catalog's model string "MS 201 C-M" names the rear-handle saw and was corrected to the top-handle MS 201 T C-M (EQ-001; F-FLEET-01, F-FLEET-02).
- **Answered the PICCO question with manual citations.** STIHL approves only 3/8 in P chain on both climbing saws. The largest professional chain allowed is 63 PS3 on a 1.3 mm (.050 in) bar, and no unapproved conversion is recommended (STANDARD.md §4.4).
- **One chain row per exact spec.** Three identical "Chainsaw chain" rows became one row per pitch · gauge · drive-link combination (F-LIST-01). Chain errors fixed:
  - a 56-DL loop that cannot fit a 16 in 3/8 in P bar is now 55 DL (F-CAT-11);
  - a 34-DL pole-saw loop is now the 40-DL part (F-CAT-12);
  - an Oregon 72LPX reel wrongly labelled "low-profile" is now marked as standard 3/8 in chain (F-CAT-10);
  - a 33 RS3 loop mislabelled as .063 in is now .050 in (F-CAT-01).
- **Blanked the inventory placeholders.** The source lists copied "min 2 / par 4" (and 2/6, 1/3, 2/8) down whole columns; those values are now blank.
  - Counts start at zero.
  - Min and par are derived from the Parts issue log.
  - The count sheet now treats a blank as NOT COUNTED rather than zero, excludes on-order stock from on-hand, rejects par ≤ min, and rounds to pack size (F-LIST-06, F-LIST-08).
- **Merged duplicate materials.** Silt fence, fill, mulch, sod and replacement-plant rows appeared twice and were merged. Concrete, structures and specialty inlets moved to subcontractor services (F-LIST-09, F-LIST-10).
- **Corrected the vendors** (F-LIST-02, F-LIST-07):
  - "Cary Lake" is now Cherrylake, Inc. (Groveland, FL), the default nursery;
  - "Gravel Junction" is now Pebble Junction (Sanford, FL);
  - "Manpower Nursery" was removed;
  - supplier triplets copied from one class to another were replaced by per-item vendor prices.
- **Fixed equipment-catalog data errors** (F-LIST-11):
  - a one-column shift from column P;
  - a blanket review date stamped on every row;
  - Low/High planning ranges that were being read as rates. A row now carries one rate with evidence, and ranges go in its notes.
- **Added the Baseline plant selection for Central Florida (USDA 9b).** It covers 17 palms and 15 trees, sizing bands for quotes and palm care rules.
  - Removed: queen palm (FISC Category II invasive), Washingtonia, Chinese fan, Senegal date, bottlebrush, ligustrum, river birch, trumpet trees, citrus and others, each with a reason (F-CAT-16). Plant rows are now cited to Cherrylake's public prices until a wholesale quote is on file (F-CAT-15).
  - This list has not yet had an independent check.
- **Added the audit-ready documents register.** It lists 60 document types in eight scopes, with an office-manager checklist and security rules. A planned Buckets storage design links each document to the row, project or subcontractor it is about.
- **Added 15 compliance gates** that cite Florida and Orange County law. Outdated citations were corrected:
  - ANSI Z133-2026 replaces the 2017 edition (F-DOC-01);
  - the FDACS pest-control licence fee is $300 per location, not $100 (F-DOC-03);
  - the 1099-NEC threshold is $2,000 for payments after 2025-12-31 (F-DOC-07);
  - fixes to Fla. Stat. 440.02, 605.0714 and 163.045 (F-DOC-02, F-DOC-04, F-DOC-05).
- **Added evidence rules, Confidence levels and 28 decision rules.** Every figure is tagged verified, manufacturer instruction, owner baseline, rule of thumb, illustrative or unverified. Every priced row carries a Confidence level (`missing`, `estimated`, `ownerConfirmed`, `verified`).
- **Recorded the first company's chain baseline honestly.** The MS 500i figure of 3–5 chains per saw per week is carried as an owner baseline, costed at $110.97–$184.95 per saw per week, and shown against the 300 h/yr default it strains. The Parts issue log is named as the record that settles it.
- **Fixed errors in the Buckets default catalog** (F-CAT-01..19). Among them:
  - a .063 in bar part cited for a .050 in system;
  - file prices quoted per pack that were really per file;
  - discontinued Milwaukee batteries, replaced by the FORGE 48-11-1881 and 48-11-1813;
  - pump gas and diesel stored as consumable rows;
  - the pole-saw reach note (7–10 ft, not 13 ft).
- **Added naming, versioning and a license recommendation.**
  - "OpenLoadout" is the working name, pending a trademark search.
  - A release is called a Baseline N.M, and the schema carries its own semantic version.
  - The recommended license is CC BY 4.0 for data and docs and MIT for code, pending the owner's confirmation and a lawyer's check.

### Known open items

- These questions are open and are not assumed either way:
  - towing weights and CDL;
  - plant-health treatments for hire;
  - fertilizer application;
  - pond, erosion and drainage work;
  - MS 500i chain gauge;
  - pole-saw standard;
  - Toro Dingo engine;
  - windmill palm;
  - the name and license (STANDARD.md §15).
- Unverified items, which must not be priced from, are listed in FINDINGS.md §2.
- Final per-list row counts after re-homing and merging will be stated with the data-file release.
