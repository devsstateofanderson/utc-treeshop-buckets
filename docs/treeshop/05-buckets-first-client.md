# Buckets first-client configuration

Working installation sheet for Sacred Tree Service, subject to live confirmation. This is a manual setup procedure for Buckets v1.1. Buckets Pro capabilities in the operating model are future work.

## Protect the starting point

Before editing a live store, record app version, store location, settings, and row/project counts. Export JSON. Copy the complete `Buckets.store` file set and the `Documents/` folder while the app is closed. Store a second copy away from the operating Mac and verify it can be opened or restored. Keep dated before-and-after exports during the pilot.

The repository has a September 16 Sacred Tree backup with 223 rows (5 labor, 20 equipment, 117 materials, 62 consumables, 3 subcontractor services, 16 overhead), three subcontractors, one loadout, and no projects. The current default catalog has 192 rows (116 materials, 57 consumables, 19 zero-dollar overhead lines) and no company labor or equipment. Neither is automatically the correct live company configuration. Compare them to current records; import replaces data, while “Add or Update Rows” merges rows.

## Company settings

| Field | Starting value | Verification required |
|---|---:|---|
| Target margin | 50% | Confirm owner pricing policy and whether different job types need a future policy |
| Minimum job | $750 | Confirm current market and operational floor |
| Billable hours per year | 1,500 | Reconcile employee billable hours versus company overhead recovery; one number currently influences both |
| Labor burden | 30% | Replace with payroll, workers compensation, and benefit evidence |
| Cost of money | 0% | Enter a financed-equipment rate only with loan evidence |

Existing projects snapshot margin and minimum; Re-price changes them. Changing billable hours changes overhead on existing projects. Record such changes in the operating log and preserve exports before changing policy.

## Build the buckets in this order

1. **Labor:** Verify the active employee roster, hourly wage, paid hours, burden, and whether each person participates in the priced crew. Use the labor calculator. Flag missing payroll evidence instead of inventing a wage.
2. **Equipment:** Inventory each owned, job-relevant unit. Confirm unit code, make/model/year/serial, purchase cost, salvage, life hours, annual use, fuel/oil, repairs, and insurance/storage. Separate owned equipment from rentals and subcontracted services. Archive rows for equipment not owned or used.
3. **Overhead:** Build annual expenses from current accounting records. Avoid double-counting workers compensation, vehicle insurance, fuel, or repairs already captured in labor/equipment. Review the denominator used to allocate overhead across one or multiple crews.
4. **Subcontractors:** Verify each provider and its flat service price, unit, and current availability. Keep services hidden from customer-facing price text.
5. **Consumables:** Keep disposal by load and real job consumables that vary with the job. Review catalog fuel/oil rows: the original pricing method puts equipment fuel in equipment rates, so using both can double-count it.
6. **Materials:** Keep commonly installed items active and verify vendor prices and units. Archive items that do not match the company's services or geography. A product link is evidence of a source, not proof of today's purchase price.
7. **Loadouts and packages:** Create only the crew formations and repeat jobs that the estimator actually uses. Test one package at today's rates.

For each row, keep: source, date checked, owner/approver, confidence level, and next review date in the working source ledger until Buckets can store those fields. The app's current row notes can hold a short source note; the full ledger should live outside the app.

## Prove a real quote

Select a completed job with a known Jobber quote and enough supporting records. Enter door-to-door crew time, selected labor/equipment, quantities, disposal, and subs. Compare Buckets' cost and price with the old quote, then compare estimated and actual time. Explain the difference by input, policy, or data quality. Repeat on at least five jobs before treating the model as calibrated.

For new work, the practical flow is: estimate in Buckets → owner/estimator approves → enter the customer quote in Jobber → complete the job in Jobber → enter actuals in Buckets → review variance. This transfer is manual until an integration exists.

## First scorecard

| Measure | Source | First use |
|---|---|---|
| Quotes sent, accepted, and value | Jobber | Sales conversion and pricing response |
| Quoted price and estimated cost | Buckets | Expected contribution and price per crew hour |
| Estimated vs actual hours | Buckets plus verified Jobber/time records | Locate recurring estimating error |
| Revenue per crew/day | Jobber plus crew calendar | Capacity and schedule decisions |
| Lead source and cost | Website, Ads, Jobber attribution | Allocate marketing budget |
| Open invoices and age | Jobber/accounting | Collections priority |

Date each metric and state coverage. A metric with missing clock-outs or incomplete job attribution is marked provisional. The 2025/2026 [pre-Buckets baseline](../BASELINE-before-buckets.md) already documents this time-data problem; do not silently turn those figures into current performance claims.

## First development bottlenecks to log

- One billable-hours setting serves labor and overhead allocation, which may misprice a multi-crew company.
- Current Buckets has no native data-source date, confidence label, approval trail, or goal/action record.
- Jobber transfer is manual; design a read-only import before write-back.
- The catalog needs company and region filtering, row review dates, and duplicate detection.
- JSON includes records but company document files require a separate copy.

Each bottleneck should be scored by lost money or time, frequency, and whether the fix can be reused for the next client.
