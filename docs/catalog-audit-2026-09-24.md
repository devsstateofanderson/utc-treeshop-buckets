# Default catalog audit - 2026-09-24

Audit of `Scripts/catalog/data/Buckets-default-catalog.json` (the product default that a fresh install merges through Settings > Add or Update Rows / `BUCKETS_MERGE_FILE`). Per-row recommendations are in `Scripts/catalog/data/audit-2026-09-24.json` so a later branch can apply them mechanically. Nothing in the catalog has been changed by this audit.

Scope: this is the **product default**, not Sacred Tree's live rows. Sacred Tree's own labor, equipment and overhead live in the local store on the company Mac and are not in this repository.

## Summary

- 192 rows; 173 carry a link.
- Link check (curl, browser UA, redirects followed): 86x 200, 86x 403, 1x 404.
- Trees + Palms: 48 rows. Verdicts: 33 keep, 3 caution, 8 review, 4 remove.
- 36 of 48 plant rows are homeowner container sizes (1-7 gal, 6-in/10-in pots, boxed). Only the 12 wholesale rows are install sizes, and all of those are `ESTIMATE` rows sourced from one Creek Nursery PDF.
- 17 rows cite a price guide, article, or category page instead of a product page.
- 22 rows are marked ESTIMATE in their notes.
- The default catalog ships `settings` (markup 35%, labor burden 30%, minimum job $750, 1,500 billable hours). Those look like one company's numbers, not neutral product defaults - decision needed below.

## 1. Species suitability (Central Florida, USDA 9b)

References used by name only: UF/IFAS Florida-Friendly Landscaping plant list; UF/IFAS Assessment of Non-Native Plants; FISC invasive plant list. Verify before applying.

| Verdict | Row | Price | Why |
|---|---|---|---|
| **remove** | Majesty Palm (outdoor/patio size) – 10 in decor pot | $44.98 | Sold as an indoor/patio decor-pot plant. Not a landscape install item. Homeowner container size; tree-service installs are 15/30/45/65 gal or B&B. |
| **remove** | Weeping Willow – 5 gal | $87.29 | Not a Central Florida landscape tree: short-lived in 9b heat/humidity, aggressive water-seeking roots, IFAS treats it as a North Florida species at best. Homeowner container size; tree-service installs are 15/30/45/65 gal or B&B. |
| **remove** | Windmill Palm – 14 in (boxed, ship-to-home) | $129.98 | Cold-hardy palm that declines in Central Florida heat and humidity; IFAS recommends it for North Florida. Both rows. Homeowner container size; tree-service installs are 15/30/45/65 gal or B&B. |
| **remove** | Windmill Palm – 3 gal | $89.98 | Cold-hardy palm that declines in Central Florida heat and humidity; IFAS recommends it for North Florida. Both rows. Homeowner container size; tree-service installs are 15/30/45/65 gal or B&B. |
| **review** | Lemon Tree (Improved Meyer) – 1 gal | $32.97 | Citrus: HLB/greening pressure and FDACS nursery-stock rules. A 1-gal citrus is not a tree-service install item. Homeowner container size; tree-service installs are 15/30/45/65 gal or B&B. |
| **review** | Ligustrum (Wax Leaf Japanese Privet) – 3 gal | $36.35 | Hedge shrub, not a tree-service planting. Ligustrum spp. carry IFAS Assessment cautions and two relatives are FISC Category I. Verify species before keeping. Homeowner container size; tree-service installs are 15/30/45/65 gal or B&B. |
| **review** | Ligustrum (tree form / standard) – 2.5 gal | $36.98 | Same as above; the listed product is a privet shrub, not a standard-form tree. Homeowner container size; tree-service installs are 15/30/45/65 gal or B&B. |
| **review** | Loquat (Bronze Loquat) – 6 in pot (starter) | $70.70 | Suitable species, but a 6-inch starter pot is not an installable size. Homeowner container size; tree-service installs are 15/30/45/65 gal or B&B. |
| **review** | Orange Tree (Calamondin) – 1 gal (3-plant bundle) | $220.06 | Citrus, see above. Also a 3-plant bundle price, not a per-tree price. Homeowner container size; tree-service installs are 15/30/45/65 gal or B&B. |
| **review** | River Birch (multi-stem) – 5 gal | $82.99 | Marginal in 9b: IFAS lists it for zones 8-9a; heat-stressed and short-lived in Central Florida. All three rows. Homeowner container size; tree-service installs are 15/30/45/65 gal or B&B. |
| **review** | River Birch (multi-trunk) – 1 gal | $44.98 | Marginal in 9b: IFAS lists it for zones 8-9a; heat-stressed and short-lived in Central Florida. All three rows. Homeowner container size; tree-service installs are 15/30/45/65 gal or B&B. |
| **review** | River Birch – 2.5 gal | $38.76 | Marginal in 9b: IFAS lists it for zones 8-9a; heat-stressed and short-lived in Central Florida. All three rows. Homeowner container size; tree-service installs are 15/30/45/65 gal or B&B. |
| **caution** | Foxtail Palm – 3 gal | $190.53 | Zone 10a+. Apopka is 9b; expect cold damage in hard freezes. Keep only with a frost note. Homeowner container size; tree-service installs are 15/30/45/65 gal or B&B. |
| **caution** | Tabebuia (Pink Trumpet Tree) – 3 gal | $204.37 | Zone 10 flowering tree; cold-tender in Apopka. Keep only with a frost note. Both rows. Homeowner container size; tree-service installs are 15/30/45/65 gal or B&B. |
| **caution** | Tabebuia (Yellow Trumpet Tree) – 3 gal | $196.51 | Zone 10 flowering tree; cold-tender in Apopka. Keep only with a frost note. Both rows. Homeowner container size; tree-service installs are 15/30/45/65 gal or B&B. |
| **keep** | Bald Cypress – 30 gal | $185.00 | Suitable for Central Florida. |
| **keep** | Bald Cypress – 5 gal | $47.70 | Suitable for Central Florida. Homeowner container size; tree-service installs are 15/30/45/65 gal or B&B. |
| **keep** | Bismarck Palm (Silver Bismarck) – 5 gal | $251.55 | Suitable for Central Florida. Homeowner container size; tree-service installs are 15/30/45/65 gal or B&B. |
| **keep** | Bottlebrush (Red Flowering) – 1 gal | $38.46 | Suitable for Central Florida. Homeowner container size; tree-service installs are 15/30/45/65 gal or B&B. |
| **keep** | Cabbage Tree Palm (Livistona australis) – 3 gal | $180.79 | Livistona australis is fine in 9b, but the common name collides with Sabal palmetto (the actual cabbage palm and state tree). Rename to 'Australian Cabbage Palm (Livistona australis)'. Homeowner container size; tree-service installs are 15/30/45/65 gal or B&B. |
| **keep** | Crape Myrtle (Muskogee) – 7 gal | $94.48 | Suitable for Central Florida. Homeowner container size; tree-service installs are 15/30/45/65 gal or B&B. Link is a price guide, article, or category page, not a product page. Price cannot be re-verified from it. |
| **keep** | Crape Myrtle (Tuscarora - dark pink) – 3 gal | $65.46 | Suitable for Central Florida. Homeowner container size; tree-service installs are 15/30/45/65 gal or B&B. |
| **keep** | Crape Myrtle, multi-trunk – 30 gal | $195.00 | Suitable for Central Florida. |
| **keep** | Crape Myrtle, multi-trunk – 45 gal | $250.00 | Suitable for Central Florida. |
| **keep** | Dahoon Holly – 1 gal | $44.98 | Suitable for Central Florida. Homeowner container size; tree-service installs are 15/30/45/65 gal or B&B. |
| **keep** | Drake Elm – 5 gal | $73.94 | Suitable for Central Florida. Homeowner container size; tree-service installs are 15/30/45/65 gal or B&B. |
| **keep** | Drake Elm – 7 gal | $95.98 | Suitable for Central Florida. Homeowner container size; tree-service installs are 15/30/45/65 gal or B&B. |
| **keep** | Eagleston Holly – 30 gal | $230.00 | Suitable for Central Florida. |
| **keep** | Eagleston Holly – 7 gal | $84.62 | Suitable for Central Florida. Homeowner container size; tree-service installs are 15/30/45/65 gal or B&B. |
| **keep** | European Fan Palm – 10 in pot | $92.72 | Suitable for Central Florida. Homeowner container size; tree-service installs are 15/30/45/65 gal or B&B. |
| **keep** | Little Gem Magnolia – 25 gal | $150.00 | Suitable for Central Florida. |
| **keep** | Little Gem Magnolia – 3 gal | $50.49 | Suitable for Central Florida. Homeowner container size; tree-service installs are 15/30/45/65 gal or B&B. |
| **keep** | Little Gem Magnolia – 7 gal (5-6 ft) | $195.62 | Suitable for Central Florida. Homeowner container size; tree-service installs are 15/30/45/65 gal or B&B. |
| **keep** | Live Oak – 1 gal | $44.98 | Suitable for Central Florida. Homeowner container size; tree-service installs are 15/30/45/65 gal or B&B. |
| **keep** | Live Oak – 30 gal | $225.00 | Suitable for Central Florida. |
| **keep** | Live Oak – 45 gal | $325.00 | Suitable for Central Florida. |
| **keep** | Live Oak – 7 gal | $93.97 | Suitable for Central Florida. Homeowner container size; tree-service installs are 15/30/45/65 gal or B&B. |
| **keep** | Pygmy Date (Robellini) Palm – 2 gal | $43.65 | Suitable for Central Florida. Homeowner container size; tree-service installs are 15/30/45/65 gal or B&B. |
| **keep** | Pygmy Date (Robellini) Palm – 25 gal | $299.00 | Suitable for Central Florida. |
| **keep** | Queen Palm – 10 in pot (~3 gal equiv) | $218.14 | Common in Central Florida; IFAS notes heavy nutrient needs. Keep with a palm-fertilizer note. Homeowner container size; tree-service installs are 15/30/45/65 gal or B&B. |
| **keep** | Queen Palm – 25 gal | $115.00 | Common in Central Florida; IFAS notes heavy nutrient needs. Keep with a palm-fertilizer note. |
| **keep** | Red Maple – 45 gal | $300.00 | Native; specify a Florida seed source or 'Florida Flame' so northern stock is not installed. |
| **keep** | Red Maple – 5 gal | $69.98 | Native; specify a Florida seed source or 'Florida Flame' so northern stock is not installed. Homeowner container size; tree-service installs are 15/30/45/65 gal or B&B. |
| **keep** | Sabal Minor (Dwarf Palmetto) – 10 in pot | $163.49 | Suitable for Central Florida. Homeowner container size; tree-service installs are 15/30/45/65 gal or B&B. |
| **keep** | Sabal Palm – 10-18 ft trunk, B&B | $160.00 | Suitable for Central Florida. |
| **keep** | Southern Magnolia (Teddy Bear) – 7 gal | $101.35 | Suitable for Central Florida. Homeowner container size; tree-service installs are 15/30/45/65 gal or B&B. |
| **keep** | Sylvester Date Palm – 3 gal | $143.72 | Suitable for Central Florida. Homeowner container size; tree-service installs are 15/30/45/65 gal or B&B. |
| **keep** | Sylvester Palm – 6 ft clear trunk | $650.00 | Suitable for Central Florida. |

Missing from the default that a Central Florida tree service installs routinely: containerized Sabal palmetto (only the B&B wholesale row exists), full-size Southern Magnolia, Slash Pine, Sweetbay Magnolia, Winged Elm, Bald Cypress above 30 gal, and any 65/100-gal specimen sizes.

## 2. Sizes: retail vs. install

36 plant rows are Home Depot container sizes. They price what a homeowner buys, not what a crew plants. Recommendation: keep the small sizes only under a clearly named category (e.g. `Trees - retail small sizes`) or drop them, and make 15/30/45/65 gal and B&B from wholesale the default. The wholesale rows currently all point at one Creek Nursery availability PDF and are ESTIMATEs; a Cherrylake or A Quality Plant quote would make them real.

## 3. Links

| HTTP | Row | Link | Note |
|---|---|---|---|
| 403 | Contractor trash bags, 42 gal – 50-count | https://www.homedepot.com/p/Husky-42-Gal-Contractor-Bags-50-Count-HK42WC050B/202973825 |  |
| 403 | Ear plugs – 200-pack (pairs) | https://homedepot.com/p/Cordova-Encore-Disposable-Ear-Plugs-200-per-Box-EPFU01/202593530 | redirected to https://www.homedepot.com/p/Cordova-Encore-Disposable-Ear-Plugs-200-pe |
| 403 | Flagging tape – 1-3/16in x 300ft roll (sold as 12-pack) | https://www.homedepot.com/b/Tools-Hand-Tools-Marking-Tools-Layout-Tools-Flagging-Tape/N-5y |  |
| 403 | M18 battery – HIGH OUTPUT HD 12.0 (48-11-1812) | https://www.homedepot.com/p/Milwaukee-M18-18-Volt-Lithium-Ion-High-Output-12-0Ah-Battery-P |  |
| 403 | M18 battery – HIGH OUTPUT XC 8.0 (48-11-1880) | https://www.homedepot.com/p/Milwaukee-M18-18-Volt-Lithium-Ion-HIGH-OUTPUT-XC-8-0-Ah-Batter |  |
| 403 | Marking paint – 15-17 oz inverted spray can | https://homedepot.com/p/Rust-Oleum-Industrial-Choice-17-oz-M1600-White-Inverted-Marking-Sp | redirected to https://www.homedepot.com/p/Rust-Oleum-Industrial-Choice-17-oz-M1600-W |
| 403 | Safety glasses – 12-pack | https://www.homedepot.com/p/Milwaukee-Safety-Glasses-with-Gray-Anti-Scratch-Lenses-12-Pack |  |
| 403 | Tarp, 20x30 – 20 ft x 30 ft, heavy duty | https://www.homedepot.com/p/Everbilt-20-ft-x-30-ft-Brown-and-Silver-Heavy-Duty-Tarp-PYHD20 |  |
| 403 | Traffic cone – 28in, weighted base | https://www.homedepot.com/p/PLASTICADE-28-in-Orange-Traffic-Cone-with-Black-Base-10-lbs-6- |  |
| 403 | Work gloves – 12-pack, large | https://www.homedepot.com/p/Milwaukee-Large-Red-Nitrile-Level-1-Cut-Resistant-Dipped-Work- |  |
| 403 | Backflow Preventer (Pressure Vacuum Breaker) – 1 in | https://www.homedepot.com/p/Febco-1-in-Bronze-Pressure-Vacuum-Breaker-Backflow-Preventer-w |  |
| 403 | Bald Cypress – 5 gal | https://www.homedepot.com/p/Bald-Cypress-Shade-Tree-CYPBAL05G/315948264 |  |
| 403 | Biochar – 1 cu ft bag | https://homedepot.com/p/WAKEFIELD-Biochar-with-CarbonBoost-Soil-Amendment-1-cu-ft-Bag-4213 | redirected to https://www.homedepot.com/p/WAKEFIELD-Biochar-with-CarbonBoost-Soil-Am |
| 403 | Bismarck Palm (Silver Bismarck) – 5 gal | https://www.homedepot.com/p/Wekiva-Foliage-Silver-Bismarck-Palm-Live-Plant-in-a-5-gal-Grow |  |
| 403 | Bottlebrush (Red Flowering) – 1 gal | https://www.homedepot.com/p/1-Gal-Red-Flowering-Bottlebrush-Tree-BOTRED01G/329903650 |  |
| 403 | Cabbage Tree Palm (Livistona australis) – 3 gal | https://www.homedepot.com/p/Wekiva-Foliage-Cabbage-Tree-Palm-Live-Plant-in-a-3-gal-Growers |  |
| 403 | Concrete Mix – 80 lb | https://www.homedepot.com/p/Quikrete-80-lb-Concrete-Mix-110180/100318511 |  |
| 403 | Crape Myrtle (Muskogee) – 7 gal | https://www.homedepot.com/b/Outdoors-Garden-Center-Outdoor-Plants-Trees/Crape-Myrtle/N-5yc |  |
| 403 | Crape Myrtle (Tuscarora - dark pink) – 3 gal | https://www.homedepot.com/p/3-Gal-Tuscarora-Dark-Pink-Crape-Myrtle-Tree-CRMTUS03G/31361558 |  |
| 403 | Crushed Limestone / Lime Rock (bagged) – bag (size unco | https://www.homedepot.com/b/Outdoors-Garden-Center-Landscaping-Supplies/Limestone/N-5yc1vZ |  |
| 403 | Dahoon Holly – 1 gal | https://www.homedepot.com/p/1-Gal-Dahoon-Holly-Evergreen-Tree-HOLDAH01G/315948341 |  |
| 403 | Distribution/Drip Tubing – 1/2 in x 100 ft | https://www.homedepot.com/p/Rain-Bird-1-2-in-x-100-ft-Distribution-Tubing-for-Drip-Irrigat |  |
| 403 | Drake Elm – 5 gal | https://www.homedepot.com/p/5-Gal-Drake-Elm-Deciduous-Shade-Tree-ELMDRA05G/326575374 |  |
| 403 | Drake Elm – 7 gal | https://www.homedepot.com/p/7-Gal-Drake-Elm-Shade-Tree-ELMDRA07G/330185521 |  |
| 403 | Drip tubing, 1/2 in poly | https://www.angi.com/articles/drip-irrigation-cuts-down-yard-work-water-usage.htm |  |
| 403 | Eagleston Holly – 7 gal | https://www.homedepot.com/p/7-Gal-Eagleston-Holly-Evergreen-Tree-HOLEAG07G/329903643 |  |
| 403 | European Fan Palm – 10 in pot | https://www.homedepot.com/p/Wekiva-Foliage-European-Fan-Palm-Live-Plant-in-a-10-in-Growers |  |
| 403 | Foxtail Palm – 3 gal | https://www.homedepot.com/p/Wekiva-Foliage-Foxtail-Palm-Live-Plant-in-a-3-gal-Growers-Pot- |  |
| 403 | Hunter PGP-ADJ Gear-Drive Rotor – 4 in pop-up rotor | https://www.homedepot.com/p/Hunter-Industries-Pop-Up-Rotary-PGP-Gear-Drive-Rotor-Sprinkler |  |
| 403 | LESCO 15-0-15 Turfgrass Fertilizer, 50 lb | https://www.homedepot.com/b/Outdoors-Garden-Center-Lawn-Care-Lawn-Fertilizers/LESCO/N-5yc1 |  |
| 403 | Landscape Fabric (Weed Barrier) – 3 ft x 100 ft | https://www.homedepot.com/p/3-ft-x-100-ft-Heavy-Duty-Weed-Barrier-Landscape-Fabric-for-Out |  |
| 403 | Landscape Timber (Recycled Plastic, Brown) – 4 in x 4 i | https://www.homedepot.com/p/BestPLUS-4-in-x-4-in-x-8-ft-Brown-Recycled-Plastic-Lumber-Land |  |
| 403 | Lemon Tree (Improved Meyer) – 1 gal | https://www.homedepot.com/p/BELL-NURSERY-1-Gal-Improved-Meyer-Lemon-Tree-Live-Tropical-Tre |  |
| 403 | Ligustrum (Wax Leaf Japanese Privet) – 3 gal | https://www.homedepot.com/p/Perfect-Plants-3-Gal-Wax-Ligustrum-Shrub-with-Wax-Leaf-Japanes |  |
| 403 | Ligustrum (tree form / standard) – 2.5 gal | https://www.homedepot.com/p/Vigoro-2-5-Gal-Recurve-Ligustrum-Evergreen-Privet-Shrub-Dark-G |  |
| 403 | Little Gem Magnolia – 3 gal | https://www.homedepot.com/p/3-Gal-Little-Gem-Southern-Magnolia-Tree-MAGLIT03G/313393694 |  |
| 403 | Little Gem Magnolia – 7 gal (5-6 ft) | https://www.homedepot.com/p/Brighter-Blooms-7-Gal-5-ft-to-6-ft-Little-Gem-Magnolia-Floweri |  |
| 403 | Live Oak – 1 gal | https://www.homedepot.com/p/1-Gal-Live-Oak-Shade-Tree-OAKLIV01G/300109830 |  |
| 403 | Live Oak – 7 gal | https://www.homedepot.com/p/7-Gal-Live-Oak-Shade-Tree-OAKLIV07G/330185532 |  |
| 403 | Loquat (Bronze Loquat) – 6 in pot (starter) | https://www.homedepot.com/p/Bronze-Loquat-Live-6-Inch-Plant-Eriobotrya-Japonica-Edible-Fru |  |
| 403 | Majesty Palm (outdoor/patio size) – 10 in decor pot | https://www.homedepot.com/p/Majesty-Palm-Live-Indoor-Outdoor-Plant-in-10-inch-Premium-Sust |  |
| 403 | Milorganite Slow-Release Fertilizer – 32 lb | https://www.homedepot.com/p/Milorganite-32-lbs-Slow-Release-Nitrogen-Fertilizer-100539618/ |  |
| 403 | Milorganite – 32 lb bag | https://www.homedepot.com/p/Milorganite-32-lbs-2-500-sq-ft-Plant-Fertilizer-Slow-Release-N |  |
| 403 | Orange Tree (Calamondin) – 1 gal (3-plant bundle) | https://www.homedepot.com/p/Wekiva-Foliage-Calamondin-Orange-Tree-Calamansi-3-Live-Plants- |  |
| 403 | Orbit Professional Pop-Up Spray Head – 4 in pop-up | https://www.homedepot.com/p/Orbit-4-in-Professional-Pop-Up-Spray-Head-Sprinkler-with-Brass |  |
| 403 | Organic Garden Soil – 1.5 cu ft | https://www.homedepot.com/p/Head-River-Organics-1-5-cu-ft-38-5-Qts-Organic-Garden-Soil-HRG |  |
| 403 | PVC Cement and Primer Combo Pack – 8 oz each | https://www.homedepot.com/p/Oatey-8-oz-Purple-Primer-and-Rain-R-Shine-Medium-Blue-PVC-Ceme |  |
| 403 | PVC Schedule 40 Elbow (90-degree, slip x slip) – 1 in | https://www.homedepot.com/p/1-in-Schedule-40-PVC-Pipe-90-Degree-Slip-x-Slip-Elbow-Fitting- |  |
| 403 | PVC Schedule 40 Pipe – 1 in x 10 ft | https://www.homedepot.com/b/Plumbing-Pipe-Fittings-Pipe-PVC-Pipe-PVC-Schedule-40-Pipe/10-f |  |
| 403 | PVC Schedule 40 Pipe – 3/4 in x 10 ft | https://www.homedepot.com/p/Charlotte-Pipe-3-4-in-x-10-ft-PVC-Schedule-40-Pressure-Plain-E |  |
| 403 | PVC Schedule 40 fittings (ell/tee/coupling), 1 in | https://www.supplyhouse.com/PVC-Schedule-40-Fittings-14952000 |  |
| 403 | Palm, Ixora and Ornamental Plant Food (8-4-8) – 3.5 lb | https://www.homedepot.com/p/Vigoro-3-5-lb-All-Season-Palm-Ixora-and-Ornamental-Plant-Food- |  |
| 403 | Paver Base – 0.5 cu ft (52.86 lb) | https://www.homedepot.com/p/Pavestone-52-86-lb-0-5-cu-ft-Paver-Base-98001/100580973 |  |
| 403 | Pine Straw Bale (Long Leaf) – bale | https://www.homedepot.com/p/FLOWERWOOD-Long-Leaf-Pine-Straw-Bale-Fert-008/335540649 |  |
| 403 | Pine Straw Bale (Long Leaf) – bale (national PLANT NETW | https://www.homedepot.com/p/national-PLANT-NETWORK-Long-Leaf-Pine-Straw-Bale-HD1379/320898 |  |
| 403 | Potting Soil Mix – 32 qt (0.85 cu ft) | https://www.homedepot.com/p/Vigoro-32-qt-Potting-Soil-Mix-74177925/305731376 |  |
| 403 | Pygmy Date (Robellini) Palm – 2 gal | https://www.homedepot.com/p/national-PLANT-NETWORK-2-Gal-Robellini-Palm-Tree-HD7473/313960 |  |
| 403 | Pygmy Date (Robellini) Palm – 25 gal | https://www.homedepot.com/p/The-Plant-Stand-of-Arizona-25-Gal-Phoenix-Roebelenii-Pygmy-Dat |  |
| 403 | Queen Palm – 10 in pot (~3 gal equiv) | https://www.homedepot.com/p/Wekiva-Foliage-Queen-Palm-Live-Plant-in-a-10-in-Growers-Pot-Sy |  |
| 403 | Rain Bird 1804 4-in Pop-Up Spray Head – 4 in pop-up | https://www.homedepot.com/p/Rain-Bird-Adjustable-Pattern-4-in-Pop-Up-Spray-Head-1804AP-25/ |  |
| 403 | Rain Bird 5000 Series 4-in Pop-Up Gear-Drive Rotor (500 | https://www.homedepot.com/p/Rain-Bird-5000-Series-4-in-Pop-Up-Gear-Drive-Rotor-Non-potable |  |
| 403 | Rain Bird Adjustable Spray Nozzle – 12-15 ft radius | https://www.homedepot.com/p/Rain-Bird-12-ft-to-15-ft-Adjustable-Spray-Pattern-Nozzle-15AP/ |  |
| 403 | Rain Bird Anti-Siphon Irrigation Valve – 1 in FPT | https://www.homedepot.com/p/Rain-Bird-1-in-Anti-Siphon-Irrigation-Valve-With-Flow-Control- |  |
| 403 | Red Maple – 5 gal | https://www.homedepot.com/p/Red-Maple-Shade-Tree-MAPRED05G/315948272 |  |
| 403 | River Birch (multi-stem) – 5 gal | https://www.homedepot.com/p/5-Gal-River-Birch-Shade-Tree-Multi-Stem-BIRDHT05G/313396790 |  |
| 403 | River Birch (multi-trunk) – 1 gal | https://www.homedepot.com/p/1-Gal-River-Birch-Multi-Trunk-Shade-Tree-BIRDUR01G/313020338 |  |
| 403 | River Birch – 2.5 gal | https://www.homedepot.com/p/FLOWERWOOD-2-5-Gal-River-Birch-Deciduous-Tree-04503FL/31830629 |  |
| 403 | River Rock / Pea Gravel – 0.5 cu ft | https://www.homedepot.com/p/314096667 |  |
| 403 | Root Barrier (Root Shield Water Barrier) – 2 ft x 25 ft | https://www.homedepot.com/p/Century-Products-2-ft-x-25-ft-Root-Shield-Water-Barrier-60-mil |  |
| 403 | Roundup PRO Concentrate Herbicide, 2.5 gal | https://www.keystonepestsolutions.com/index.php?main_page=product_info&products_id=715 |  |
| 403 | Sabal Minor (Dwarf Palmetto) – 10 in pot | https://www.homedepot.com/p/Wekiva-Foliage-Sabal-Minor-Dwarf-Blue-Stem-Palmetto-Palm-Live- |  |
| 403 | Southern Magnolia (Teddy Bear) – 7 gal | https://www.homedepot.com/p/7-Gal-Teddy-Bear-Southern-Magnolia-Evergreen-Tree-MAGTED07G/32 |  |
| 403 | St. Augustine Sod (Floratam) | https://www.homeguide.com/costs/sod-prices |  |
| 403 | St. Augustine Sod – 400 sq ft | https://www.homedepot.com/p/Harmony-400-sq-ft-St-Augustine-Sod-1-Pallet-HH400SA1/331567534 |  |
| 403 | St. Augustine Sod, single piece/slab | https://www.homeguide.com/costs/sod-prices |  |
| 403 | Sylvester Date Palm – 3 gal | https://www.homedepot.com/p/Sylvester-Palm-Live-Plant-in-a-3-Gal-Growers-Pot-Phoenix-Sylve |  |
| 403 | Tabebuia (Pink Trumpet Tree) – 3 gal | https://www.homedepot.com/p/Wekiva-Foliage-Pink-Tabebuia-Trumpet-Tree-Live-Plant-in-a-3-Ga |  |
| 403 | Tabebuia (Yellow Trumpet Tree) – 3 gal | https://www.homedepot.com/p/Wekiva-Foliage-Yellow-Tabebuia-Trumpet-Tree-Live-Plant-in-a-3- |  |
| 403 | Threaded rod, 1/2in bracing – 1/2in-13, 10 ft, hot-dip  | https://www.homedepot.com/p/Everbilt-1-2-in-x-10-ft-Hot-Dip-Galvanized-Steel-Coarse-Thread |  |
| 403 | Tree Watering Bag – 15 gal | https://www.homedepot.com/p/King-Innovation-15-Gal-Tree-Irrigation-Watering-Bag-1-Pack-440 |  |
| 403 | Tree watering bag – 20 gallon | https://homedepot.com/p/Vigoro-20-Gal-Tree-Watering-Bag-410-878-0111/330509941 | redirected to https://www.homedepot.com/p/Vigoro-20-Gal-Tree-Watering-Bag-410-878-01 |
| 403 | Vigoro Premium Mulch – 2 cu ft | https://www.homedepot.com/p/Vigoro-Vigoro-2-cu-ft-Premium-Brown-Wood-Shredded-Bagged-Mulch |  |
| 403 | Weeping Willow – 5 gal | https://www.homedepot.com/p/5-Gal-Weeping-Willow-Shade-Tree-WILWEE05G/313397447 |  |
| 403 | Windmill Palm – 14 in (boxed, ship-to-home) | https://www.homedepot.com/p/14-Windmill-Palm-Tree-with-Beautiful-Green-Fronds-15530/315743 |  |
| 403 | Windmill Palm – 3 gal | https://www.homedepot.com/p/Brighter-Blooms-3-Gal-Windmill-Palm-Tree-in-Pot-PAL-WIN3/31611 |  |
| 403 | Zoysia Sod | https://www.homeguide.com/costs/sod-prices |  |
| 404 | Premixed fuel – STIHL MotoMix | https://www.walmart.com/ip/STIHL-MotoMix-Pre-Mixed-Full-Synthetic-Motor-Oil-4-qt/492421160 |  |

`403` from homedepot.com and similar is bot-blocking, not a dead page. Home Depot also blocks an automated browser session from this Mac (bot-protection interstitial), so its 80 rows cannot be verified by automation here at all; they need a human click or a different source. `404`, `410`, and `000` (no response) are dead as far as curl can tell. Confirmed dead so far: the Walmart STIHL MotoMix page (404).

Practical consequence for the default catalog: 80 of 173 links point at one retailer that cannot be re-verified without a person. Arborist suppliers (WesSpur, TreeStuff, Bailey's, SiteOne, DoMyOwn) all answered 200 and are re-verifiable; moving retail-grade rows to those sources where an equivalent exists would make the whole catalog checkable.

## 4. Non-vendor sources

| Row | Source | Link |
|---|---|---|
| Pump gas, regular – per gallon, FL average | Arborist supply | https://gasprices.aaa.com/?state=FL |
| Diesel – per gallon, FL average | Arborist supply | https://gasprices.aaa.com/?state=FL |
| Flagging tape – 1-3/16in x 300ft roll (sold as 12-pack) | Arborist supply | https://www.homedepot.com/b/Tools-Hand-Tools-Marking-Tools-Layout-Tools-Flagging-Tape/N-5y |
| Compost tea / soil amendment – 1 gallon, liquid concent | Arborist supply | https://www.walmart.com/c/kp/worm-compost-tea |
| Mulch, bulk – per cubic yard | Arborist supply | https://www.mulchforyou.com/products-and-pricing |
| Pine straw – per bale | Arborist supply | https://www.mulchforyou.com/products-and-pricing |
| Topsoil, bulk – per cubic yard | Arborist supply | https://www.mulchforyou.com/products-and-pricing |
| Porta-potty rental – standard unit, monthly | Arborist supply | https://orlandoportapotties.com/what-is-the-monthly-cost-of-a-porta-potty-in-orlando-fl/ |
| St. Augustine Sod (Floratam) | SiteOne (Apopka) | https://www.homeguide.com/costs/sod-prices |
| St. Augustine Sod, single piece/slab | SiteOne (Apopka) | https://www.homeguide.com/costs/sod-prices |
| Bahia Sod | SiteOne (Apopka) | https://www.osceolasod.com/blog/how-much-is-a-pallet-of-bahia-or-zoysia-sod-in-florida-202 |
| Zoysia Sod | SiteOne (Apopka) | https://www.homeguide.com/costs/sod-prices |
| Drip tubing, 1/2 in poly | SiteOne (Apopka) | https://www.angi.com/articles/drip-irrigation-cuts-down-yard-work-water-usage.htm |
| LESCO 15-0-15 Turfgrass Fertilizer, 50 lb | SiteOne (Apopka) | https://www.homedepot.com/b/Outdoors-Garden-Center-Lawn-Care-Lawn-Fertilizers/LESCO/N-5yc1 |
| Crape Myrtle (Muskogee) – 7 gal | Home Depot (Apopka) | https://www.homedepot.com/b/Outdoors-Garden-Center-Outdoor-Plants-Trees/Crape-Myrtle/N-5yc |
| Crushed Limestone / Lime Rock (bagged) – bag (size unco | Home Depot (Apopka) | https://www.homedepot.com/b/Outdoors-Garden-Center-Landscaping-Supplies/Limestone/N-5yc1vZ |
| PVC Schedule 40 Pipe – 1 in x 10 ft | Home Depot (Apopka) | https://www.homedepot.com/b/Plumbing-Pipe-Fittings-Pipe-PVC-Pipe-PVC-Schedule-40-Pipe/10-f |

A price guide or blog post gives a number that cannot be re-verified next quarter. Each of these needs a product page, a supplier quote, or an explicit `ESTIMATE` note with a date.

## 5. Duplicates

- Milorganite 32 lb is listed twice (same product number, two Home Depot URLs).
- Long Leaf Pine Straw bale is listed twice plus a third generic 'Pine straw - per bale'.
- Tree watering bag 15 gal and 20 gal are different products but should share one naming convention.
- St. Augustine sod appears four times across pallet, 400 sq ft, single piece, and Floratam rows with three different sources.
- Propiconazole quart and gallon share one product page; the quart price should be verified separately.

## 6. Decisions needed (owner)

1. Should the default catalog ship `settings` at all, or should markup/burden/minimum be blank until a company sets them? (Today's defaults look like Sacred Tree's.)
2. Apply the `remove` verdicts above to the default catalog?
3. Retail small sizes: separate category, or drop?
4. Approve adding `sourceConfidence` / `suitabilityNote` fields to catalog rows (kickoff step 7) so this audit becomes data instead of a document. That is a model change and needs its own branch and migration test.

