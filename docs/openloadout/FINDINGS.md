# FINDINGS — companion to OpenLoadout Tree Service Baseline 0.1 (2026-09-28)

The corrections register for the standard, the Buckets default catalog and the worked-example fleet. This repository copy leaves out the internal notes (sections 3 and 4), which are kept outside the repository. Every correction carries an ID that STANDARD.md cites. Prices are USD as seen on the date given. "Overturned" upstream findings were not used. No serials, VINs, policy numbers, wages or personal data appear here.

## 1. Index

| ID | What was wrong | Corrected value | Evidence URL | Date |
|---|---|---|---|---|
| F-CAT-01 | Buckets row "Chain loop – 3/8 RS3 .063, 24-25in" calls 33 RS3 84 a .063 chain | 33 RS3 84 (3624 005 0084) is .050; the .063 3/8 in RS3 is "36 RS3". Rename the row | https://www.baileysonline.com/stihl-24-chainsaw-chain-loop-33rs-84-drive-links-3623-005-0084.html | 2026-09-28 |
| F-CAT-02 | Buckets row "Chainsaw bar, 20in – 3/8 .050, 72DL, Rollomatic" cites STIHL 3003 000 5221 | 3003 000 5221 is a .063 in bar. Replace with 3003 008 8921 (20 in, .050), $67.99 | https://www.ohiopowertool.com/stihl-3003-008-8921 | 2026-09-28 |
| F-CAT-03 | "Round chainsaw file 5/32 in – 12-pack" and "13/64 in – 12-pack" priced $2.67 per pack | $2.67 is per file; the dozen is $31.99. Set unit "each" at $2.67 or "pack" at $31.99 | https://www.treestuff.com/pferd-dozen-round-chainsaw-files/ | 2026-09-28 |
| F-CAT-04 | "Chain sharpening kit – STIHL 2-in-1 file guide" at $15.99 ("estimate", bmproturf link) | One row per pitch: 5605 750 4305 (3/8) $54.99 and 5605 750 4303 (3/8 P) $54.99; replace the link | https://www.ohiopowertool.com/stihl-5605-750-4305 · https://www.ohiopowertool.com/stihl-5605-750-4303 | 2026-09-28 |
| F-CAT-05 | "Bar and chain oil – 5 gallon pail" unit "gal" at $141.99 | Unit is "pail"; the price is unverified (the cited page shows no price) | https://www.shforestrysupplies.com/451a-0781-516-5006-stihl-platinum-bar-and-chain-oil-5-gallon-pail.html | 2026-09-28 |
| F-CAT-06 | Pump gas ($4.20/gal) and diesel ($6.33/gal) as consumables rows | Archive both (fuel is never a consumable row); keep the AAA link as evidence for equipment fuel inputs | https://gasprices.aaa.com/?state=FL | seen 2026-09-16 |
| F-CAT-07 | Premixed fuel (MotoMix) row links a dead page | Re-verify before use; the current SDS is at stihlusa.com | https://www.stihlusa.com/safety/data-sheets/ | 2026-09-28 |
| F-CAT-08 | Chains, bars, sharpening, bar-oil and 2-stroke rows categorised as project consumables | Recategorise as "Saw wear parts (priced on saw rows)"; toggle on only for extraordinary loss | STANDARD 5.3 | 2026-09-28 |
| F-CAT-09 | PPE rows (helmet, chaps, glasses, earplugs, gloves) with no costing note | Routine issue is the overhead line "PPE & uniforms"; helmet and chaps are track-only equipment with retire dates | STANDARD 2.1, 5.3 | 2026-09-28 |
| F-CAT-10 | "25 ft reel of 3/8 chain – 3/8in low-profile .050" (Oregon 72LPX, $135.99 sale / $159.99) labelled low-profile | 72LPX is **standard** 3/8 in (.375) pitch, .050 in gauge, chisel, not low-kickback approved: MS 500i-class chain (loops of 66/72/84 DL). It never serves the 3/8 P top-handles or the .043 pole saws. Rename the row; note that a spun loop of a non-green-label chain is not in the MS 500i manual's §24.1 list | https://www.baileysonline.com/oregon-25-chainsaw-chain-reel-72lpx-410-drive-links-72lpx025u-orf-72lpx025r.html | 2026-09-28 |
| F-CAT-11 | "Chainsaw chain loop, 3/8 low-profile .050 16in (top-handle) – 56 drive links" (Oregon 91VXL, $20.99) | The STIHL 16 in 3/8 P bar 3005 000 4813 takes 55 DL; a 56 DL loop will not fit. Spec the 55 DL variant ($26.99 per the row's own note) or STIHL 63 PS3 55 ($27.99) | https://www.treestuff.com/oregon-91vxl-chain/ · https://www.baileysonline.com/stihl-16-chainsaw-chain-loop-63ps3-55-drive-links-3616-005-0055.html | 2026-09-28 |
| F-CAT-12 | "Pole saw chain loop (Oregon 90PX)" $23.75 cites 90PX034G | 90PX034G is the 34 DL loop for an 8 in bar; the Milwaukee 3016-21PS takes 40 DL: Milwaukee 49-16-2723 $27.97 or Oregon 90PX040G. The 3013-21 takes 49-16-2759 (.325 LP .043, 46 DL). Neither is .050 | https://www.ohiopowertool.com/milwaukee-tools-49-16-2723 · https://www.ohiopowertool.com/milwaukee-tool-49-16-2759 | 2026-09-28 |
| F-CAT-13 | Battery rows "HIGH OUTPUT XC 8.0 48-11-1880" $199 and "HD 12.0 48-11-1812" $279 | Both are marked "no longer available" by Milwaukee. Replace with FORGE XC8.0 48-11-1881 $229.00 and FORGE HD12.0 48-11-1813 $279.00 (Ohio Power Tool, no sale price shown). They are pole-saw battery wear lines, not stand-alone rows | https://www.ohiopowertool.com/milwaukee-tools-48-11-1881 · https://www.ohiopowertool.com/milwaukee-tools-48-11-1813 · https://www.milwaukeetool.com/products/48-11-1880 | 2026-09-28 |
| F-CAT-14 | "Saddle replacement leg straps" may be a full saddle | Re-verify; if a saddle, it is a CLM equipment row with a retire-by date | STANDARD 7.2 | 2026-09-28 |
| F-CAT-15 | Plant rows labelled "Cherry Lake" carrying another nursery's prices | Re-cite to Cherrylake's public prices pending a wholesale quote: live oak 30 gal $193.60; bald cypress 30 gal $148.50; crape myrtle 30 gal $143.00 | https://cherrylakecommunities.com/ | 2026-09-28 |
| F-CAT-16 | Species on the removed list still in the catalog (queen palm, Washingtonia, Chinese fan, Senegal date, bottlebrush, ligustrum, loquat, river birch, trumpet trees, citrus) | Remove per STANDARD 10.3. Windmill palm stays removed (DECISIONS 77) until Q-WINDMILL is answered | https://ask.ifas.ufl.edu/publication/EP020 · https://www.floridainvasives.org/wp-content/uploads/2026/07/FISC-2026-Plant-List-Cat-I-II_April2026.pdf | 2026-09-28 |
| F-CAT-17 | Imidacloprid drench (Dominion 2L, $34.98) ungated | Labelled for landscape trees by soil drench: keep, mark verified, gate behind the Chapter 482 licence (Q-PHC) | https://www.fdacs.gov/Business-Services/Pest-Control/Licensing-and-Certification | 2026-09-28 |
| F-CAT-18 | No overhead lines for devices or shop supplies | Add "Computers & devices" and "Shop & fleet maintenance supplies" as $0 overhead checklist lines | STANDARD 5.5 | 2026-09-28 |
| F-CAT-19 | Fleet note "~13 ft reach" on the 3016-21PS | 7–10 ft with the included extension; 13 ft is the 3013-21 | https://www.milwaukeetool.com/products/details/m18-fuel-pole-saw-w-quik-lok-kit/3016-21PS | 2026-09-28 |
| F-FLEET-01 | Fleet row "Stihl 201T" priced $984.99 from a dealer page that now errors | MS 201 T C-M list $949.99; bar length unrecorded on the row ("12-16in"), confirm at re-entry | https://www.stihlusa.com/en/p/chainsaws-ms-201-gasoline-chainsaw-1027365 | 2026-09-28 |
| F-FLEET-02 | Fleet row "Stihl 193" priced $399.95 (superseded model) | Honorary upgrade: record and price as MS 194 T $509.99; 14 in bar recorded; read the bar-tail stamp (1.1 = .043) | https://www.stihlusa.com/products/chain-saws/in-tree-saws/ms194t/ | 2026-09-28 |
| F-FLEET-03 | Fleet rows for the MS 194 T and the 3013-21 pole saw carry "archive if you don't own one" | Ownership unconfirmed (Q-OWNED); the 09-16 entry lists three MS 500i while the live store today holds one equipment row | sacred_tree_fleet.json (internal) | 2026-09-28 |
| F-FLEET-04 | Fleet row "Toro Mini Skid" priced $32,400.50 (midpoint of the gas TX 427 and diesel TX 525) with pump-gas fuel at $3.75/h | The owner's Dingo is the diesel: Toro Dingo TX 525 Wide, model 22324, Kubota D902E3B, 553 lb ROC, **$32,976.00**. Fuel = diesel (AAA FL $6.33/gal × about 1 gal/h ≈ $6.33/h, not $3.75/h gas). Record the engine from the data plate (older TX 525 units carry a Kubota D1105) before choosing filter and oil wear lines. Hydraulic oil = Toro HYPR-Oil / HYPR-Oil Plus or a UTHF per the operator's manual, never AW46 | https://www.toro.com/en/product/22324 · https://gasprices.aaa.com/?state=FL · https://www.manualslib.com/manual/1856737/Toro-Tx-427.html | 2026-09-28 |
| F-FLEET-05 | Fleet row for the MS 500i stores a blanket 2.50 repair factor and no wear lines | Keep until plan slice 1 ships; then repair factor 1.00 with the Section 5.2 wear lines; the stored rate is the interim | STANDARD 5.2 | 2026-09-28 |
| F-LIST-01 | Three identical "Chainsaw chain" rows (CON-001..003) in the draft consumables list | One row per exact spec: 33 RS 66; 33 RS 84; 63 PS3 44; 63 PS3 55; Milwaukee 49-16-2723; 49-16-2759 | STANDARD 4.0 | 2026-09-28 |
| F-LIST-02 | Vendors "Cary Lake", "Gravel Junction", "Manpower Nursery" | Cherrylake, Inc., Groveland FL; Pebble Junction, Sanford FL; Manpower Nursery removed (unknown to the owner) | https://cherrylake.com/ · https://www.pebblejunction.com/ | 2026-09-28 |
| F-LIST-03 | Customer View tab; Apple devices and a software workspace listed as equipment | Tab dropped; devices and software to overhead at $0 | STANDARD 2.4, 5.5 | 2026-09-28 |
| F-LIST-04 | Fuel, 2-stroke oil and bar oil as project consumables | Moved to the unit's fuel + oil; rows kept as stock-count and price sources | STANDARD 5.3 | 2026-09-28 |
| F-LIST-05 | Ropes, saddles, lanyards, mats, barriers, cones, kits, extinguishers as consumables | Equipment (track-only where under the threshold) with retire-by dates | STANDARD 2.1 | 2026-09-28 |
| F-LIST-06 | Class-wide min/par (2/4, 2/6, 1/3, 2/8) copied down every column | Blank; policy "unset"; derive from the Parts issue log | STANDARD 6.2 | 2026-09-28 |
| F-LIST-07 | Class-copied supplier triplets and brand families | Per-item vendor prices where the vendor actually lists the item (injection plugs at SiteOne or Sherrilltree, not a janitorial distributor) | STANDARD 11 (VendorPrice) | 2026-09-28 |
| F-LIST-08 | Inventory sheet treats blank as zero, counts on-order as on hand, allows par ≤ min, ignores pack size | Blank = NOT COUNTED; on-order is not on hand; CHECK par > min; round to pack; one row per item per location | STANDARD 6.4 | 2026-09-28 |
| F-LIST-09 | Duplicate material rows: silt fence (MAT-062/081), fill (MAT-025/056), mulch (MAT-022/072), sod (MAT-008..010/070), replacement plants (MAT-073) | Merge; tag species rows for replacements | STANDARD 5.4 | 2026-09-28 |
| F-LIST-10 | Concrete, structures and specialty inlets as materials | Subcontractor services | STANDARD 2.1 | 2026-09-28 |
| F-LIST-11 | Equipment catalog: one-column data shift from column P; blanket "2026-09-27" review date; Low/High prices as rates | Fix the shift; never import the blanket date per row; treat ranges as planning notes, never rates | STANDARD 11 | 2026-09-28 |
| F-SAW-01 | Earlier claim that the STIHL 25 in dealer kit ships 33 RS3 84 on bar 3003 000 4030 | The cited dealer page shows 33 RH 84 (HEXA); the shipped bar is unverified. Costing unaffected; run 33 RS on that bar | STANDARD 4.1 | 2026-09-28 |
| F-SAW-02 | Fuel pickup body 0000 350 3518 marked "price unverified"; parts list position given as 55 | $7.49 at Bailey's, upheld by the fleet-saw check; position 58 in the English parts list (55 in the French) | https://www.baileysonline.com/chainsaws/chainsaw-parts/ | 2026-09-28 |
| F-SAW-03 | Sprocket held at 80 h in the owner-baseline column of the two-rate table | Manual §21.3: new sprocket after two chains, so 3 h at a 1.5 h chain interval; the column now reads $58,910.05 / $35.63/h / $62,430.03 | STANDARD Appendix D | 2026-09-28 |
| F-DOC-01 | ANSI Z133-2017 cited | Z133-2026, effective 2026-05-26; section numbers to be re-checked against the new text | https://www.isa-arbor.com/Publications/Z133-2026 | 2026-09-28 |
| F-DOC-02 | Fla. Stat. 440.02 subsections cited wrongly | (10) and (20)(b)2 in the 2025 statutes | https://www.flsenate.gov/Laws/Statutes/2025/440.02 | 2026-09-28 |
| F-DOC-03 | FDACS pest-control business licence fee $100 | $300 per location per year | https://www.fdacs.gov/Business-Services/Pest-Control/Licensing-and-Certification | 2026-09-28 |
| F-DOC-04 | Sunbiz last filing cutoff described as the fourth Friday | Dissolved the fourth Friday of September; the last filing cutoff is the third Friday (Fla. Stat. 605.0714) | https://www.flsenate.gov/Laws/Statutes/2025/605.0714 | 2026-09-28 |
| F-DOC-05 | Fla. Stat. 163.045 documentation attributed to an ISA arborist only | 163.045(1)(a): "an arborist certified by the International Society of Arboriculture (ISA) or a Florida licensed landscape architect"; (2): removal is "the only means of practically mitigating its risk below moderate" | https://www.flsenate.gov/Laws/Statutes/2025/163.045 | 2026-09-28 |
| F-DOC-06 | Dead links: IRS lost-EIN page, USCIS I-9 retention page | Re-link before public release; Sunbiz and FMCSA pages refuse automated access and are opened by hand | — | 2026-09-28 |
| F-DOC-07 | 1099-NEC threshold | $2,000 for payments made after 2025-12-31 | https://www.irs.gov/instructions/i1099mec | 2026-09-28 |

## 2. Unverified items (do not price from these)

| Item | Status |
|---|---|
| MS 194 T bare spur sprocket 1137 640 2005 | Price unverified; OEM drum kit $48.98 (sawagain.com, 2026-09-28) |
| STIHL chain-brake service cost | Unverified |
| 11/64 in round file price | Unverified |
| Bar and chain oil 5 gal pail price | Unverified (F-CAT-05) |
| Cherrylake wholesale-account prices | Unverified until a quote is on file; public retail at cherrylakecommunities.com is the interim evidence |
| Cherry Lake plant warranty terms | Unverified; request in writing with the wholesale account |
| Palm and tree Baseline (STANDARD 10) | One research pass, no adversarial check; run one before public release |
| Pole-saw battery life | Rule of thumb only; log replacement dates |
| STIHL 25 in dealer-kit bar | Unverified (F-SAW-01) |

Sections 3 and 4 are internal and are kept outside the repository.

## 5. Owner answers applied (2026-09-28, binding)

Saw line MS 500i / MS 201 T C-M / MS 194 T with honorary upgrades and the replacement rule; short and long bar per saw on the stock STIHL pro bar; professional chain, larger approved size, no unapproved conversion (the PICCO answer in STANDARD 4.4 with manual citations); Toro Dingo is the diesel TX 525; MS 500i chain baseline 3–5 per week per saw to be dialled in by the Parts issue log; inventory starts at zero; tech cost $0; Customer View tab dropped; Cherry Lake default nursery; Pebble Junction regional stone vendor; Manpower Nursery removed; a good palm selection for Central Florida; public, open-source, community-contributed standard shipped with each Buckets version; audit-ready data with a secure document store and a list of documents to get. Defaults applied without objection: brand-neutral schema with opinionated defaults; unit hours = door-to-door project hours; wear rows as price and stock source; inventory outside the app for now; devices and software to overhead; queen palm removed. Still open: STANDARD Section 15.

## 6. Scope-fence tensions (moved from STANDARD 13.4)

| The source lists want | Buckets says | Resolution |
|---|---|---|
| Inventory control (counts, min, par, reorder status, lot, expiry) | Not pricing; outside the fence | Workbook, with the corrected formulas (STANDARD 6.4) |
| Three preferred suppliers per row and a supplier directory | One free-text source, a link and evidence per row; no vendor table | Vendor prices live in the workbook; the row carries the source and link of the price it uses |
| "Inspect every use / monthly" schedules | Wear intervals spread cost and are never due dates; only in-service and retire-by dates | Cadence lives in the SOPs (STANDARD 7) |
| Service-interval filter kits, "min/max by fleet count" | Maintenance scheduling is not pricing | Wear lines spread cost; service invoices live in Documents |
| Employee issue records | No positions, no credentials | The company's own PPE issue sheet; not a standard list |
| Chains, bars, knives, ropes as stocked consumables | Routine wear is on the unit's line | Consumables rows are the price and stock source, never a project toggle |
| Fuel and oil as consumables | Fuel is an equipment rate input | Archive the pump-gas and diesel rows; keep the price link (F-CAT-06) |
| Crew-owned / branch-owned / enterprise ownership | Owned or rented; vendor-operated is a sub | Assignment level is a loadout, not an ownership model |
| Lanes with requirement status, tiers and an "AI operating rule" | Loadouts add no pricing; no lookup editors; no loadouts in the default | Lane guidance stays as documentation or an optional merge file |
| Low/High planning price ranges | One rate per row with evidence and confidence | Ranges may sit in notes, never as the rate |
| Apple devices and a ChatGPT workspace as equipment | Technology is overhead; brand mandates are not a standard | Overhead lines at $0; brand choices are company profile |
| A Customer View tab | Customer output is the price only | Dropped |

## 7. Name candidates (2026-09-28 study; moved from STANDARD Appendix D)

| Name | Score | Why it lost |
|---|---|---|
| **OpenLoadout** (recommended; releases called Baselines) | 8 | Names the thing (what goes on the truck), trade-neutral, org and .org/.com free on 2026-09-28; USPTO status unverified; "loadout" is a common gaming word |
| Tailboard / OpenTailboard | 6 | Trade-authentic (the daily tailboard briefing) but a fire/EMS operations platform already uses "Tailboard" |
| Buckets Baseline / OpenBaseline | 6 | Tied to the product name; "baseline" is crowded in software; kept as the release word instead |
| TradeSpec | 5 | Generic; near-identical finance marks (TRADESPEX); domains taken |
| Specbook | 4 | Two construction products already use it |
| Fieldbook | 4 | At least four unrelated apps, two in adjacent spaces |
| Rootstock | 3 | An established ERP vendor |
| Heartwood | 3 | Several tree companies and a field-service training vendor |
| Standard Issue | — | A registered Class 9 mark |

## 8. Method

Eleven verification domains, each with an independent adversarial pass; three owner-research tasks (saw line, documents, naming) with adversarial passes on the first two; one palm research pass without one. Overturned corrections were discarded; the refuter's value was used where it gave one with evidence. Everything re-fetched for this revision (72LPX reel, Toro 22324, Fla. Stat. 163.045, Milwaukee FORGE batteries, Orange County business tax page) was read on 2026-09-28.
