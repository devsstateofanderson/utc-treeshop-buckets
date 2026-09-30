# Sales and marketing in Buckets: commission, salary, offers and reports — plan

Planning session, 2026-09-30, revised after review the same day (see "Review log" at the end). Four planners (compensation math, offers and deals, pipeline and attribution, scope critique) worked the owner's brief in parallel against `claude/planning-and-sub-removal` (0.2.3, build 5); this document is the reconciliation and the build order. Binding once the DECISIONS entries named below (92–98) are written. Read-only against the repository, the live export `onboard-2026-09-30-054709/export-final.json`, and OpenLoadout Baseline 0.1.

> **Status.** Slice 1a is implemented on `claude/sales-commission` (0.2.4, build 6; DECISIONS 83, 92, 93's first paragraph, 94 and 95). The vault's data layer v4 and its rehearsal are not part of that branch. Slices 1b to 4 are plans.

> **Privacy (DECISIONS 88).** This committed copy names nobody. It says "the example salesperson" and "the owner" for the two people involved, and the pay figures it uses (an example salaried salesperson at $200/day on a 5-day week, 7% commission; example crew and owner-operator rates) are worked-example inputs chosen to match the shape of the first client's catalog, not any employee's pay. The company's real pay figures live in its vault. The data-layer file described under "Data layer v4 and rehearsal" belongs in `~/Developer/sacred-tree-local-vault`, never in `Scripts/catalog/data`.

## The brief (Mr. Anderson, condensed)

Combine marketing and sales in Buckets, at least somewhat, now. Marketing needs to know the packages and deals to promote, what they are worth to the customer, and what they cost and earn the company, so it can do the job correctly. Say we push palm installs for spring: presell, pre-order, let marketing drum up traction before ads run; the ad people use pixels for retargeting. A salesperson's commission (7% in the example) is tracked as a bonus. Upgrade Buckets to handle commissions and salary accurately while keeping a clear system of costs, profit and reports. Plan, then upgrade.

## What the store holds today (export 2026-09-30 05:47, format 2)

| Fact | Value |
|---|---|
| Settings | 1,500 billable h · 30% burden · 50% target margin · $750 minimum · 0% cost of money (six keys in the export's `settings`) |
| Hourly crew rows | 6 rows; example inputs $20.20/h, 2,000 paid h, 30%: `2020 × 1.30 × 2000 ÷ 1500 = 3501.33 → $35.01/h`; the standard crew = 3 of them = **$105.03/h** |
| An owner-operator labor row | example inputs $50/h, 2,000 h, 30% → $86.67/h; hourly, active, not on the crew loadout |
| The example salesperson's labor row | hourly, example inputs `2500 × 1.30 × 2080 ÷ 1500 = 4506.67 → $45.07/h`, off in every package, note says "do not turn this row on" |
| The sales salary overhead line | the example salary, typed by hand: `$200 × 5 × 52 = $52,000; × 1.30 = $67,600.00/yr`, estimated, owner confirmation pending |
| Overhead, 25 active lines | **$155,864.30/yr → $103.91/h** (`15,586,430 ÷ 1,500 = 10,390.95`); without the salary line $88,264.30 → $58.84/h |
| Advertising & lead services | $22,659.62/yr, the biggest overhead line after rent (2025 P&L); this is the fixed advertising cost every price already carries |
| Templates | **10**: 9 priced packages (all at 50%, all 25 overhead lines on, STS Standard Crew, 233 lines each) plus an empty "New package" (0 h, 197 lines, priced at the $750 floor) |
| Legacy project | 1: "New project" (markup 35, `targetMarginPct` nil, 197 lines) |
| Commission | nowhere: the salary line's note says "set the target margin to 57% to keep 50% after commission" |

**Two live defects this plan fixes.** (1) The example salesperson's pay exists twice, as a labor rate and as an overhead line, and only the note keeps one of them off: `Project.make` turns every active hourly row **on**, so ⌘N under Projects today prices the salesperson at $45.07/h as crew *and* $45.07/h as overhead, with the owner on at $86.67/h, until someone applies the Crew menu; and Re-price on the two projects that predate the salesperson's rows ("New package", "New project": 197 lines, no line for that row) appends the salesperson's labor line switched on. (2) On every job the example salesperson sells, 7% of the price leaves the 50% margin and nothing shows it: the Medium removal earns 42.5% after commission while the header says 50.0%.

## Decisions taken here

1. **Commission is priced in through one company-wide sales allowance, never per salesperson.** `Price = max(min, round(Cost × 10000 × k ÷ (10000 − 100·M − A·(100 + B))))`, one division, rounded once (DECISIONS 7, 70). M is the target margin **after commission**, A the allowance, B the employer payroll tax on commission, k the multiplier. Every package therefore has one price whoever closes it, which is what marketing promotes. With A = 0 the code keeps today's expression byte for byte, so nothing moves until the owner types an allowance. The per-salesperson denominator (`100 − m − c`) is rejected: it gives a customer a different price depending on who answered the phone.
2. **The commission paid is a term of the sale, on the project:** a **Sold by** salesperson (a Labor row), a snapshot of the person's name and commission % (`commissionPct`, refreshed by Re-price like every snapshot, DECISIONS 17–18) and a separate **override** (`commissionPctOverride`, never refreshed). Effective C = override ?? snapshot, and **C = 0 whenever there is no salesperson**; C and B are held to 0…100. The base is one figure, `soldPriceCents ?? price` (slice 3 adds the sold price; until then it is the price), passed into the Breakdown so the header and the Commissions report can never disagree. `Commission = round(Base × C ÷ 100)` and `CommissionTax = round(Base × C × B ÷ 10000)`, each rounded once from cents. **Profit after commission = Base − Cost − Commission − CommissionTax** by integer subtraction, so the header reconciles (DECISIONS 3). Margin in the header means *after commission*; the gross figure stays as a caption. A job the owner sells has C = 0 and keeps the allowance as profit.
3. **Salaried staff who are not on the crew are Overhead lines; their Labor row is marked "not on the crew" and the price never touches it.** Slice 1a adds the flag (`trackOnly`, the attribute the equipment-classes plan reserves in DECISIONS 83). 83's text is written once, bucket-neutral, by whichever branch lands first, and the other rebases onto it: *"A track-only row is not priced: new projects, Re-price, loadouts and the loadout member picker skip it; an existing project line for it keeps its snapshot (17); readiness counts priced rows and lists track-only rows separately; merge sets the flag and never clears it."* Each bucket keeps its own label: "Not on the crew" on Labor, "Track only" on Equipment. Slice 1b adds the Overhead Form's "Calculate…" → `SalaryCalc` (amount per day/week/month/year × periods × (1 + burden), one division, rounded once), which amends DECISIONS 34 for this one case. No `SalesRep` model, no pay-type enum, no package migration: the $67,600 line stays where it is (it is already right) and every package price is unchanged by construction.
4. **Payroll tax on commission is its own company figure, default 7.65% (employer FICA), not the crew's 30%.** A commission paid as a bonus is supplemental wages: FICA applies; FUTA and Florida reemployment tax add nothing once the salary has passed the $7,000 wage base (week 7 at $1,000/week); workers' comp applies at the sales class rate, and a PEO fee only if charged as a % of gross. Charging the crew's 30% (mostly class 0106 workers' comp) would overstate the cost by about 20 points of the commission. The owner raises 7.65 from the PEO invoice.
5. **The price decision is the owner's, and the default changes nothing.** Turning on a 7% allowance at a 50% target raises every price 17.75% (Medium removal $4,441.12 → $5,229.21). The alternative, keep today's prices and accept ≈42.5% after commission, is target 42.5 with allowance 7 ($4,444.28). Either way the header now shows the true profit after commission. Open question 1. Changing A or B in Company shows "N packages priced under an older allowance — Re-price packages", one action that re-prices every template, so marketing never reads a stale list price (DECISIONS 89 is extended so the data layer sets the two defaults the same way).
6. **Offers are the marketing face of a package (slice 2): one model, not two.** An `Offer` is a package plus customer-safe words, a **deal discount %**, a sales window, a delivery window, a target count in units, a marketing budget, a campaign code and a landing URL. Its economics (list, deal, saving, commission, contribution, profit after, margin after, floor, max discount, break-even units, totals at target) are computed live by a pure `OfferEconomics`, which prices the package exactly as `Project.instantiate` would (today's company defaults and rates), never from the template's snapshot. A project sold under an offer snapshots `dealDiscountPct` and `offerUnits` (a 3-palm order is one project of 3 units) and applies the discount to **its own** list price, one division, rounded once: `DealPrice = round(ListPrice × (100 − D) ÷ 100)`, the one price the rule does not set from the margin (amends DECISIONS 24 for this field). The floor, `Floor = max(min, Cost × 10000 ÷ (10000 − 100·F − C·(100 + B)))` with F the company's deal floor margin (default 0 = break-even after commission), is checked twice: at activation, against the package with the offer's assumed C, and **on every project**, against the project's own cost and effective C, where the header shows "Below floor by $X" in `.orange`. Marketing never sees a price under the floor at activation; a later re-price can move the floor, and then the header and the economics box say so. **Marketing money is contribution money:** `Contribution = DealPrice − direct cost (labor, equipment, materials, consumables, subcontractors) − Commission − CommissionTax`, no overhead in it; break-even units, return on spend and "after spend" are all computed on contribution, because offer and campaign budgets are extra to the Advertising & lead services overhead line that every price already carries. Profit after commission (with overhead) stays as its own column.
7. **Sale terms live on the project (slice 3); Buckets computes commission owed and never pays it.** Four dates and a figure, all typed until the Jobber bridge: `soldAt` (sold = set), `soldPriceCents` (Jobber's figure when it differs), `customerPaidAt` (the Jobber invoice's paid date), `commissionPaidAt`. **Earned** = the `soldAt` month (accrual). **Payable** = earned, with `customerPaidAt` set and `commissionPaidAt` nil. The **Commissions** report shows both, by salesperson and month; **Copy for payroll** copies the payable jobs grouped by `customerPaidAt` month; **Mark paid** sets `commissionPaidAt` and is the human step. Clearing a sale is refused once `commissionPaidAt` is set: a paid commission never vanishes from the report. No pipeline statuses, no lost reason, no lead source and no win rate here: those are Jobber's request and quote data (spec §1) and arrive with the read-only bridge (Gate 2) rather than being typed into two systems. No `Payment` ledger: Jobber owns cash, and BRIEF §5.1's "no expense ledger" is read as no ledger of any transactions. Buckets holds no cash figures; every monthly total is labelled "Bookings (sold, accrual)".
8. **Campaigns (slice 4) hand the ad people one string and take back one number.** `Campaign`: name, offer, channel, platform, budget, one spent figure typed from the platform's billing page, dates. The string is the offer's `code` (the UTM campaign value and the Jobber tag) with the channel as the UTM source; the Copy tagged link builds it from the offer's landing URL. `Project.campaign` is the single-touch credit. The Attribution report shows the figure the ad platforms cannot: contribution per sold job against spend. Buckets stores no pixel, tag, audience, click ID, token or ad-account ID and never fires anything; the website carries the pixel. Spend never enters project cost: the Advertising overhead line already does.
9. **Jobber stays the CRM.** No customer records beyond the free-text `client` (Jobber spec §1, §4.3: never match by name); no scheduling, invoicing, deposits or messages. The sold date, sold price and customer-paid date are typed until the read-only bridge (roadmap Release 2, spec Gate 2) fills them from Jobber's quote and `PaymentRecord` through an `ExternalLink`; pipeline status, lost reason, lead source and win rate wait for that bridge. Nothing here writes to Jobber.
10. **Planning (DECISIONS 90) reads; it is not built here.** Annual overhead including salaried staff, crew payroll, the commission actually paid as a share of bookings, bookings by month, package profit after commission, offer targets and crew-hours booked are all plain computed figures on existing models.
11. **Transfer format bumps** when slice 1a lands, because a 0.2.3 app reading a file that carries `salesAllowancePct` would drop it and silently price the project lower (DECISIONS 74 precedent): **format 3, or 4 if the equipment-classes slice 2 merges first**; `readableFormatVersions` widens. Version 0.2.4, build 6 for slice 1a (renumbered at merge as the format is).

## Where the four planners disagreed

| Topic | Compensation plan | Offers plan | Pipeline plan | Scope critique | Resolved here |
|---|---|---|---|---|---|
| Where the salary lives | Labor row with `payType: salary`, snapshotted into the Overhead bucket; the manual line archived; 9 packages re-sent | — | Stays an overhead line; new `SalesRep` model links to it and checks it | Salary calculator on the overhead row; labor row track-only | **Scope's**: overhead line + calculator; labor row not on the crew. Smallest change, no line-bucket semantics change, no package migration; no new model (employee-level simple). The calculator moves no price, so it ships in slice 1b |
| Commission in the price | Company allowance A + tax B in one denominator; C paid per project | Reads a company `salesCommissionPct` | Pricer unchanged; commission out of margin, optionally company-wide k | Per-project c in the denominator | **Compensation's** (decision 1). Scope's per-person denominator moves the price by seller; pipeline's "unchanged" leaves the 42.5% defect on the header |
| Payroll tax on commission | 7.65% company default | none | 30% (labor burden) until confirmed | none (Profit = Price − Cost − Commission) | **7.65%**, per person later if a 1099 rep appears |
| Re-price and the commission % | keeps the project's % (a sale term) | — | sold snapshot frozen | refreshes from the row | **Both, in two fields**: the snapshot refreshes from the row like every snapshot (17, 18); a negotiated override never does; in slice 3 Re-price is disabled once sold, so a sold job's terms never move |
| Deal / offer model | `dealPriceCents` in Pricer, `floorPrice` | `Offer` + `Deal`, `DealMath`, `PriceRule.fixed`, deposits, capacity, two briefs | minimal `Deal` + `Campaign` + `CampaignSpend` | one `Offer` with deal price, `OfferEconomics` | **One `Offer`** (decision 6) with a discount %, applied to each project's own price; the offers plan's floor rule, re-checked per project; two copies; capacity as a target in units; no deposits |
| Pipeline | `soldAt`, `commissionPaidAt` | preorder = project with fixed price | six stages, five dates, `Payment`, cumulative accrual, `CommissionPayout` | status + `soldPriceCents` + `closedAt` | **Four dates and the sold price** (decision 7): `soldAt`, `soldPriceCents`, `customerPaidAt`, `commissionPaidAt`; statuses, lost and lead source deferred to the Jobber bridge; no cash ledger |
| Tracking references | — | words only | pixel, GA4, GTM, ad-account IDs on `Company`; UTM builder | none | **A campaign code and a landing URL on the offer; a Copy tagged link; no IDs, no tracking notes** (decision 8) |
| Copy breakdown names the salesperson | never | — | never in customer output | "Commission: $361.49 (7%, <salesperson>)" | **Never a name** (it is pasted into Jobber notes; DECISIONS 41, 88); the Commissions report names people |
| Reports | Commissions | offer results | five reports + CSV writer | Commission, Pipeline, Margin, By offer, Attribution | **Commissions, Margin on sold work, By offer, Attribution**, each a pure struct with **Copy report** (tab-separated, pastes into Numbers); Pipeline and win rate wait for the bridge; CSV files later if the owner asks |
| Palm install example | Medium removal only | 4 h, Dingo on, $2,407.04 list | 3 h, no Dingo, $1,820.74 | 3 h, "Dingo on" but priced without it | **3 h, Dingo on** (the Tree Planting note says Dingo on; a B&B sabal needs it); 4 h is open question 8, every hour is +$250.07 of cost |

## What Buckets owns, and what it must not build

| Buckets owns | Stays out (and where it lives) |
|---|---|
| The price with commission in it; commission and profit after commission on every project; margin after vs target | Customer records, properties, contact details (Jobber) |
| Salaried pay as overhead, calculated once; who sells each job at what % | Scheduling, visits, deposits, invoices, payments, refunds (Jobber) |
| Offers: what to promote, at what discount, what it earns, the floor, break-even on a budget in contribution; a customer-safe copy and an internal copy | Sending anything: quotes, email, SMS (Jobber, the owner) |
| Sold date, sold price, customer-paid date; commission earned, payable and paid; Commissions, Margin on sold work, By offer and Attribution reports | Pipeline stages, lost reasons, lead source, win rate (Jobber's requests and quotes, until the bridge reads them) |
| A campaign code and a landing link on the offer; budget vs spent per channel | Pixels, tags, audiences, retargeting, ad accounts, spend imports (the website and the ad platforms) |
| | Positions, quotas, pay bands, a comp-plan engine (§5.1); payroll and withholding (the PEO) |

The test for anything new: does it change a price, a cost, a profit, or a report derived from them? If not, it is not Buckets. The second test: does Jobber already hold it? Then Buckets reads it later and never types it.

## Data model

### Slice 1a (pricing, salesperson, not-on-the-crew)

| Model | Attribute | Type | Meaning |
|---|---|---|---|
| `BucketItem` | `trackOnly` | `Bool = false` | DECISIONS 83's text (decision 3), written once for every bucket; Labor label "Not on the crew" |
| `BucketItem` | `commissionPct` | `Decimal?` | Whole percent of the base of jobs this person sells; Labor rows only in the Form; 0…100; nil = none |
| `BucketItem` | `soldProjects` | `[Project]`, inverse of `Project.salesperson`, nullify | Declared so a deleted row nullifies (DECISIONS 21); delete only when `referenceCount == 0 && soldProjects.isEmpty`; the "used in N projects" message counts sold projects too |
| `Project` | `salesAllowancePct`, `commissionBurdenPct` | `Decimal?` | Snapshots of the two company defaults, set by `setPricing(from:)`, refreshed by Re-price like `targetMarginPct`; nil = 0 |
| `Project` | `salesperson` | `BucketItem?` | Sold by; nullify |
| `Project` | `salespersonName` | `String?` | Snapshot when picked; survives archiving or deletion |
| `Project` | `commissionPct` | `Decimal?` | Snapshot of the person's % when picked; refreshed from the row by Re-price when the link exists |
| `Project` | `commissionPctOverride` | `Decimal?` | The negotiated %, typed on the project; never refreshed; disabled until Sold by is set. Effective C = override ?? snapshot, 0 without a salesperson |
| `AppSettings` | `salesAllowancePct` | `Double = 0` | Company → Pricing defaults: "Share of every price set aside for sales commission. Packages price with it, whoever closes the job." |
| `AppSettings` | `commissionBurdenPct` | `Double = 7.65` | "Employer cost on each commission dollar: FICA 7.65% plus workers' comp at the sales class rate and any PEO % fee. Read it off the PEO invoice." |

### Slice 1b (salary calculator, list columns)

| Model | Attribute | Type | Meaning |
|---|---|---|---|
| `BucketItem` | `salaryInputs` | `SalaryCalcInputs?` (derived) | Decoded from `calcInputs` for overhead rows, as `laborInputs` is for labor; no new stored attribute |

Lightweight migration only (optional or defaulted attributes and one optional to-one relationship with a declared inverse), the same class as 0.2.0–0.2.3.

### Later slices

| Slice | Model | Attributes |
|---|---|---|
| 2 | `Offer` (new) | `name`, `customerName`, `promise`, `includes` (multiline, customer-safe), `excludes?`, `package: Project?` (a template; nullify), `dealDiscountPct: Decimal?` (nil = list price; 0…100), `commissionPct?` (the % the economics assume; default the company allowance), `startsAt`, `endsAt`, `deliveryStart?`, `deliveryEnd?`, `targetUnits?`, `marketingBudgetCents?`, `code?`, `landingURL?`, `notes?`, `isActive`, `sortOrder` |
| 2 | `Project` | `offer: Offer?` (nullify), `dealDiscountPct: Decimal?` (snapshot; survives the offer's deletion), `offerUnits: Int = 1` |
| 2 | `AppSettings` | `dealFloorMarginPct: Double = 0` |
| 3 | `Project` | `soldAt: Date?` (sold = set), `soldPriceCents: Int?`, `customerPaidAt: Date?`, `commissionPaidAt: Date?` |
| 4 | `Campaign` (new) | `name`, `offer: Offer?` (nullify), `channel` (organic · social · email · referral · paidAds · repeat · other), `platform?`, `budgetCents`, `spentCents`, `startsAt`, `endsAt?`, `notes?`, `isActive`; the code and landing URL are the offer's |
| 4 | `Project` | `campaign: Campaign?` (nullify) |

Packages (`isTemplate`) never carry a salesperson, an override, a deal, units, sale dates or a campaign; `asPackage` clears them as it clears actuals (DECISIONS 61).

## The math

### The price with the allowance

Goal: at 1×, when the job pays the allowance (C = A), profit after commission and its payroll tax is exactly M% of the price.

```
P − Cost − P·A/100 − P·A·B/10000 = P·M/100
P · (10000 − 100·M − 100·A − A·B) = 10000·Cost
P = Cost × 10000 ÷ (10000 − 100·M − A·(100 + B))
```

With B = 0 this is `Cost ÷ (1 − margin − commission)`, the owner's own formula; with A = 0 it is DECISIONS 70 unchanged. The tempting `Cost ÷ (1 − M) ÷ (1 − A)` is wrong: it divides twice and multiplies where it should add (`1 ÷ ((1−m)(1−a)) = 1 ÷ (1 − m − a + m·a)`); for the Medium removal it gives $4,775.40, which earns 46.5% after commission at B = 0 (`477,540 − 222,056 − 33,428 = 222,056`) and 46.0% with the 7.65% tax (`477,540 − 222,056 − 33,428 − 2,557 = 219,499`, 45.96%), not 50%.

As code computes it (whole percents, DECISIONS 12):

```
share       = min( 100·M + A·(100 + B) , 9500 )                 M already held to 0…95 (DECISIONS 70); A, B, C held to 0…100
ListPrice   = round( Cost × 10000 × k ÷ (10000 − share) )       ONE division, rounded once; A = 0 keeps today's
                                                                Cost × 100 × k ÷ (100 − M) expression unchanged
DealPrice   = round( ListPrice × (100 − D) ÷ 100 )              slice 2; D = the project's dealDiscountPct; nil → ListPrice
Price       = max( MinimumJob , DealPrice )                     floor last, never multiplied (DECISIONS 5)
Base        = SoldPrice ?? Price                                 slice 3; one base for the header and the report
Commission  = round( Base × C ÷ 100 )                           rounded once, from cents; C = 0 without a salesperson
CommTax     = round( Base × C × B ÷ 10000 )                     rounded once
Profit      = Price − Cost                                      unchanged meaning (gross)
ProfitAfter = Base − Cost − Commission − CommTax                 integer subtraction; the header reconciles
MarginAfter = ProfitAfter ÷ Base × 100                          display, one decimal
```

- Rounding each displayed figure once can put MarginAfter a hair off the target (50.0001%); that is the trade DECISIONS 3 already accepts for price-from-rounded-cost.
- **Multiplier:** k is in the numerator and commission is paid on the multiplied price ("the revenue the salesperson creates"). At k×, `MarginAfter = 1 − A(1+B) − (1 − M − A(1+B)) ÷ k ≥ M`: the multiplier only widens the margin.
- **Minimum job:** a customer price, never grossed up; commission is paid on the $750; at the floor MarginAfter is above target when C ≤ A.
- **C ≠ A:** at 1× before rounding, `MarginAfter = M + (A − C)(1 + B/100)`: paying more than the allowance costs margin, paying less adds it, and the owner selling (C = 0) keeps the allowance as profit. In cents the kept allowance is `Commission + CommTax at C = A`, two figures each rounded once, so the header difference between the owner selling and the example salesperson selling reconciles to the cent.
- **Negative profit after commission** is possible whenever C > A + M's headroom (A 0, M 5, C 7 on the Medium removal: `222,056 × 100 ÷ 95 = 233,743`, commission 16,362, tax 1,252, profit after **−5,927**); the header says "loses $59.27 after commission" in `.orange` rather than a negative margin.
- **Legacy markup projects** (`targetMarginPct == nil`): the allowance is not applied (DECISIONS 70 keeps them on their snapshot markup); a named salesperson still yields Commission and ProfitAfter.
- **Display markup equivalent:** `share ÷ (10000 − share) × 100`; 50/7/7.65 → 135.49% (the header caption, as 50% → 100% today).

### Salary (slice 1b)

```
periods/yr = day: daysPerWeek × weeksPerYear · week: weeksPerYear · biweekly 26 · semimonthly 24 · month 12 · year 1
$/yr       = round( amount × periods/yr × (100 + burden) ÷ 100 )        one division, rounded once; throws on negatives (as DECISIONS 9)
$/hr       = $/yr ÷ billable hours                                        display only (DECISIONS 4)
```

### Offer economics and the floor (slice 2, pure `OfferEconomics`)

```
unitCost         = package Cost priced as instantiate would: today's rates, today's defaults, the package's hours and toggles
unitDirectCost   = labor + equipment + materials + consumables + subcontractors of that cost (no overhead)
listPrice        = the package's Price under the rule with today's A and B (never the template's snapshot)
dealPrice        = round( listPrice × (100 − D) ÷ 100 )                   one division, rounded once; refused below the floor
saving           = listPrice − dealPrice
unitCommission   = round( dealPrice × C ÷ 100 ) ;  unitTax = round( dealPrice × C × B ÷ 10000 )
unitContribution = dealPrice − unitDirectCost − unitCommission − unitTax   the marketing figure: no overhead in it
unitProfitAfter  = dealPrice − unitCost − unitCommission − unitTax          the accounting figure, with overhead; a separate column
marginAfter      = unitProfitAfter ÷ dealPrice × 100
floor            = max( minimum , round( unitCost × 10000 ÷ (10000 − 100·F − C·(100 + B)) ) )     one division
maxDiscountPct   = floor₁( (listPrice − floor) ÷ listPrice × 100 )        one decimal, rounded DOWN so the price it yields is never under the floor
breakEvenUnits   = ceil( marketingBudget ÷ unitContribution )            nil when the budget is nil or unitContribution ≤ 0
atTarget         = targetUnits × {dealPrice, unitDirectCost, unitCost, unitCommission, unitTax, unitContribution, unitProfitAfter}
                                                                          exact integer multiples, never 7% of a sum
```

The floor's one-division rounding can land a fraction of a cent under the stated margin (34.99955% shows as 35.0%); the DECISIONS entry records that, as 3 does. On a project the same floor is recomputed from the project's own cost and effective C, and the offer's economics box re-checks the package floor against the deal after every re-price, so a materials quote that rises between the presale and the planting is seen, not hidden.

## Worked examples (Sacred Tree, live export, recomputed by hand)

### Tree Removal – Medium, 8 h, 3-person crew, two dump loads

| Bucket | Calc | ¢ | $ |
|---|---|---|---|
| Labor | 3 × 3,501 = 10,503 × 8 | 84,024 | 840.24 |
| Equipment | 4,113/h on (2 × 500i 256, Silverado 1,100, 201 T 361, 194 T 287, pole saw 141, Dingo 1,436, dump trailer 180, rigging 23, climbing 27 × 2, traffic 19) × 8 | 32,904 | 329.04 |
| Consumables | 2 loads × 11,000 | 22,000 | 220.00 |
| Overhead | 15,586,430 × 8 ÷ 1,500 = 83,127.63 | 83,128 | 831.28 |
| **Cost** | | **222,056** | **2,220.56** |

The example salesperson's salary is inside the overhead figure: `6,760,000 × 8 ÷ 1,500 = 36,053` → $360.53. It is a fixed cost the company carries whoever sells; it is not commission, so nothing is counted twice.

**Scenarios** (M = 50, B = 7.65 unless stated; A = allowance, C = commission paid):

| # | Setup | Denominator | Price | Commission | Payroll tax | Profit after | Margin after |
|---|---|---|---|---|---|---|---|
| a | Today: A 0, no salesperson | 5000 | $4,441.12 | — | — | $2,220.56 | 50.0% |
| b | A 0, example salesperson sells at 7% (the live defect) | 5000 | $4,441.12 | $310.88 | $23.78 | $1,885.90 | **42.5%** |
| **c** | **A 7, C 7** | 4246.45 | **$5,229.21** | **$366.04** | **$28.00** | **$2,614.61** | **50.0%** |
| d | A 7, B 0 (the owner's plain formula), C 7 | 4300 | $5,164.09 | $361.49 | — | $2,582.04 | 50.0% |
| e | A 7, the owner sells (C 0) | 4246.45 | $5,229.21 | — | — | $3,008.65 | 57.5% |
| f | A 7, override C 10 | 4246.45 | $5,229.21 | $522.92 | $40.00 | $2,445.73 | 46.8% |
| g | A 7, C 7, 2× after-hours | 4246.45 | $10,458.43 | $732.09 | $56.00 | $7,449.78 | 71.2% |
| h | A 7, C 7, 3× emergency | 4246.45 | $15,687.64 | $1,098.13 | $84.01 | $12,284.94 | 78.3% |
| i | A 7, C 7, deal 10% off (slice 2) | 4246.45 | $4,706.29 | $329.44 | $25.20 | $2,131.09 | 45.3% |
| j | Keep today's price: M 42.5, A 7, C 7 | 4996.45 | $4,444.28 | $311.10 | $23.80 | $1,888.82 | 42.5% |
| k | A 7, C 7 but B = 30 (the crew's burden) | 4090 | $5,429.24 | $380.05 | $114.01 | $2,714.62 | 50.0% |

Hand checks:

- **(b)** `444,112 × 7 ÷ 100 = 31,087.84 → 31,088`; tax `444,112 × 53.55 ÷ 10,000 = 2,378.22 → 2,378`; `444,112 − 222,056 − 31,088 − 2,378 = 188,590` → 42.46%. This is what the Medium removal earns today whenever the example salesperson sells it.
- **(c)** share `5,000 + 7 × 107.65 = 5,753.55`; denominator `4,246.45`; `222,056 × 10,000 ÷ 4,246.45 = 522,921.4991…` → **522,921**. A near tie: `4,246.45 × 522,921.5 = 2,220,560,003.675`, above the numerator 2,220,560,000, so the exact quotient is under .5 and rounds down; this is the kind of value DECISIONS 7 and 70 demand one division for. Commission `522,921 × 7 ÷ 100 = 36,604.47 → 36,604`; tax `522,921 × 53.55 ÷ 10,000 = 2,800.24 → 2,800`; `522,921 − 222,056 − 36,604 − 2,800 = 261,461` → 50.0001%. The allowance kept when the owner sells is Commission + CommTax at C = A: `36,604 + 2,800 = 39,404` → **$394.04**, and (e) − (c) = `300,865 − 261,461 = 39,404` agrees (the unrounded `522,921 × 753.55 ÷ 10,000 = 39,404.7` would be a cent high, because commission and tax each round on their own).
- **(d)** `222,056 × 100 ÷ 43 = 516,409.30 → 516,409`; `× 7% = 36,148.63 → 36,149`; `516,409 − 222,056 − 36,149 = 258,204` → 49.9999%.
- **(f)** the override on the project: 10% of 522,921 = 52,292.1 → 52,292; tax 4,000.05 → 4,000; profit after 244,573 (the table's $2,445.73). Re-price after a fuel change leaves it at 10%: the override is its own field.
- **(g)** `222,056 × 20,000 ÷ 4,246.45 = 1,045,842.998 → 1,045,843`, not 2 × 522,921 = 1,045,842: rounded once (DECISIONS 6).
- **(i)** `round(522,921 × 90 ÷ 100) = round(470,628.9) = 470,629`; commission 32,944.03 → 32,944; tax 2,520.22 → 2,520; `470,629 − 222,056 − 32,944 − 2,520 = 213,109`.
- **(j)** denominator `10,000 − 4,250 − 753.55 = 4,996.45`; `222,056 × 10,000 ÷ 4,996.45 = 444,427.54 → 444,428`.
- **(k)** shows decision 4: the crew's 30% would charge $114.01 of payroll tax on a $380.05 bonus and lift the price another $200.

### The nine packages under a 7% allowance (M 50, B 7.65, C 7)

| Package | h | Cost | Price today | After 7% paid out of today's price | **Price with allowance** | Commission + tax | **Profit after** |
|---|---|---|---|---|---|---|---|
| Crown Cleaning / Pruning – mature shade tree | 5 | $1,288.55 | $2,577.10 | $1,094.35 (42.5%) | **$3,034.42** | $212.41 + $16.25 | $1,517.21 (50.0%) |
| Land / Lot Clearing – per crew-day with Dingo | 10 | $3,225.70 | $6,451.40 | $2,739.55 (42.5%) | **$7,596.23** | $531.74 + $40.68 | $3,798.11 (50.0%) |
| Palm Trimming – up to 6 palms | 3 | $817.13 | $1,634.26 | $693.98 (42.5%) | **$1,924.27** | $134.70 + $10.30 | $962.14 (50.0%) |
| Storm / Emergency Cleanup – per crew-day | 10 | $2,720.70 | $5,441.40 | $2,310.66 (42.5%) | **$6,407.00** | $448.49 + $34.31 | $3,203.50 (50.0%) |
| Stump Grinding – via sub (per stump) | 1 | $299.92 | $750.00 (floor) | $393.56 (52.5%) | **$750.00** (floor) | $52.50 + $4.02 | $393.56 (52.5%) |
| Tree Planting – 30 gal live oak, installed | 3 | $943.97 | $1,887.94 | $801.70 (42.5%) | **$2,222.96** | $155.61 + $11.90 | $1,111.48 (50.0%) |
| Tree Removal – Large (60–70 ft+) | 16 | $4,726.11 | $9,452.22 | $4,013.83 (42.5%) | **$11,129.56** | $779.07 + $59.60 | $5,564.78 (50.0%) |
| **Tree Removal – Medium (30–50 ft)** | 8 | **$2,220.56** | **$4,441.12** | $1,885.90 (42.5%) | **$5,229.21** | $366.04 + $28.00 | $2,614.61 (50.0%) |
| Tree Removal – Small (to ~30 ft) | 4.5 | $1,170.70 | $2,341.40 | $994.26 (42.5%) | **$2,756.89** | $192.98 + $14.76 | $1,378.45 (50.0%) |

Every priced package rises by the same factor, `5,000 ÷ 4,246.45 = 1.1775`; the stump grind sits on the floor either way. Costs are the export's line snapshots priced by DECISIONS 3–4 (each bucket rounded once); the "today" column matches the live app to the cent.

**The stale-package trap.** Packages snapshot A and B as they snapshot the target margin. The day the owner types A = 7, every package still says $4,441.12 while Use Package prices the new project at $5,229.21; marketing would read the old figure. Company therefore shows "9 packages priced under an older allowance — Re-price packages" the moment A or B changes, and `OfferEconomics` never reads a template's snapshot (decision 6). The data layer treats the two defaults as DECISIONS 89 treats the others: the file's value when present, company defaults on create, and nil leaves the store's value alone on update, so a package merged in later still gets the allowance.

**Stump grinding at the floor:** `29,992 × 10,000 ÷ 4,246.45 = 70,628.41 → 70,628` → floor **75,000**; commission `75,000 × 7 ÷ 100 = 5,250`; tax `75,000 × 53.55 ÷ 10,000 = 401.625 → 402`; profit after `75,000 − 29,992 − 5,250 − 402 = 39,356` (52.5%). The owner selling it: $450.08 (60.0%). Floor after the multiplier, commission after the floor.

### The salary line (slice 1b)

`20,000¢ × (5 × 52) × 130 ÷ 100 = 20,000 × 260 × 1.30 = 6,760,000¢ = $67,600.00/yr`, identical to the hand-typed line, so the calculator moves no price; that is why it can wait for slice 1b. `6,760,000 ÷ 1,500 = 4,506.67 → $45.07/h` (display). If the PEO invoice puts this position's burden at about 10% (FICA 7.65 + capped FUTA/RT ≈ 0.44% of $52,000 + a sales-class workers' comp rate + the PEO fee) the line is `20,000 × 260 × 110 ÷ 100 = $57,200` → $38.13/h: overhead drops $10,400/yr and $6.93/h, and the Medium removal's overhead goes `14,546,430 × 8 ÷ 1,500 = 77,580.96 → 77,581`, $55.47 off its cost. Open question 4; the data layer keeps 30 so nothing moves on the day it runs.

### Spring palm offer (slice 2): "Spring Sabal Palm Install"

There is no palm-install package. The offer needs **"Palm Planting – Sabal, field-grown 10–18 ft CT, installed"**, built from Tree Planting: the Sabal Palm 10–18 ft B&B row on ($160.00, an ESTIMATE from a Stuart wholesale list dated 9/9/26, Cherrylake quote pending), the live oak off, **Dingo on** (the package note says on; the export has it off, open question 8), stake kit as the bracing proxy, 1 yd mulch, 3 h door to door; the package note's "+1 h per extra tree" stays.

| Bucket | Calc | ¢ | $ |
|---|---|---|---|
| Labor | 10,503 × 3 | 31,509 | 315.09 |
| Equipment | (2,677 + 1,436 Dingo) = 4,113 × 3 | 12,339 | 123.39 |
| Materials | 16,000 + 1,199 + 3,125 | 20,324 | 203.24 |
| **Direct cost** | | **64,172** | **641.72** |
| Overhead | 15,586,430 × 3 ÷ 1,500 = 31,172.86 (of which advertising `2,265,962 × 3 ÷ 1,500 = 4,531.92` → $45.32) | 31,173 | 311.73 |
| **Unit cost** | | **95,345** | **953.45** |
| List price, A 7 | `95,345 × 10,000 ÷ 4,246.45 = 224,528.72` | **224,529** | **2,245.29** |
| (under today's rule, A 0) | `95,345 × 2` | 190,690 | 1,906.90 |
| Commission 7% at list | `224,529 × 7 ÷ 100 = 15,717.03` | 15,717 | 157.17 |
| Payroll tax at list | `224,529 × 53.55 ÷ 10,000 = 1,202.35` | 1,202 | 12.02 |
| Profit after at list | `224,529 − 95,345 − 15,717 − 1,202` | 112,265 | 1,122.65 (50.0%) |

The deal: `SPR27-PALM` · "Spring 2027 palm presale" · 10% off · sell Feb 1 – Mar 31, plant Apr 1 – Jun 30 · target 30 palms · marketing budget $3,500, **extra to** the $22,659.62 Advertising & lead services line (ad spend is authorized separately, docs/treeshop/02) · deal floor margin F = 35% as the placeholder.

| Figure | Calc | ¢ | $ |
|---|---|---|---|
| Deal price (one palm) | `224,529 × 90 ÷ 100 = 202,076.1` | 202,076 | **2,020.76** |
| Saving shown to the customer | `224,529 − 202,076` | 22,453 | 224.53 |
| Commission on the deal | `202,076 × 7 ÷ 100 = 14,145.32` | 14,145 | 141.45 |
| Payroll tax | `202,076 × 53.55 ÷ 10,000 = 1,082.12` | 1,082 | 10.82 |
| **Contribution** (marketing) | `202,076 − 64,172 − 14,145 − 1,082` | 122,677 | **1,226.77** |
| Profit after commission (accounting) | `202,076 − 95,345 − 14,145 − 1,082` | 91,504 | **915.04** (45.3%) |
| Floor at 35% after commission | `95,345 × 10,000 ÷ (10,000 − 3,500 − 753.55) = 95,345 × 10,000 ÷ 5,746.45 = 165,919.83` | 165,920 | **1,659.20** |
| Check the floor | commission 11,614, tax 889; `165,920 − 95,345 − 11,614 − 889 = 58,072`; ÷ 165,920 | | 35.00% |
| Headroom | `202,076 − 165,920` | 36,156 | 361.56 |
| Max discount | `(224,529 − 165,920) ÷ 224,529 = 26.10%` → down to one decimal | | 26.1% |
| Break-even units on $3,500 | `ceil(350,000 ÷ 122,677 = 2.85)` | | **3** |
| Check | `3 × 122,677 − 350,000 = +18,031` (+$180.31); `2 × 122,677 − 350,000 = −104,646` | | |
| At 30 palms | revenue 30 × 202,076 · commission 30 × 14,145 · tax 30 × 1,082 · contribution 30 × 122,677 · profit after 30 × 91,504 | | $60,622.80 · $4,243.50 · $324.60 · **$36,803.10** · $27,451.20 |
| After the $3,500 budget | `3,680,310 − 350,000` | 3,330,310 | **$33,303.10** contribution after spend; the overhead already carried is 30 × 31,173 = $9,351.90, and `36,803.10 − 9,351.90 = 27,451.20` reconciles to the profit-after column |
| Crew-hours at 30 palms sold one to a project | 30 × 3 h | | 90 h, 24% of the Apr–Jun share of 1,500 h (`1,500 × 91 ÷ 365 = 373.97`) |

Why contribution and not profit after: the $915.04 already carries $311.73 of overhead per palm, $45.32 of it the Advertising line; subtracting the $3,500 from it would charge advertising twice. Break-even on profit after would say 4 palms (`ceil(350,000 ÷ 91,504 = 3.82)`); the honest figure is 3. Per-unit figures are computed per project and summed (30 × 14,145), never as 7% of the sum, so the offer's commission equals what the Commissions report will show. At 4 h per palm the unit cost is 120,352 ($1,203.52: each hour adds `105.03 + 41.13 + 103.91 = $250.07`), the list price $2,834.18, the deal $2,550.76, and the contribution `255,076 − 78,788 − 17,855 − 1,366 = 157,067` ($1,570.67).

**A three-palm order is one project (slice 2 `offerUnits`).** The customer takes three: Use Offer makes one project with `offerUnits 3`, 3 + 2 × 1 = **5 h**, three Sabal, stake-kit and mulch lines, and the same 10% off its own price.

| Figure | Calc | ¢ | $ |
|---|---|---|---|
| Cost | labor 10,503 × 5 = 52,515 · equipment 4,113 × 5 = 20,565 · materials 3 × 20,324 = 60,972 · overhead `15,586,430 × 5 ÷ 1,500 = 51,954.77` → 51,955 | 186,007 | 1,860.07 |
| List price | `186,007 × 10,000 ÷ 4,246.45 = 438,029.41` | 438,029 | 4,380.29 |
| Deal price | `438,029 × 90 ÷ 100 = 394,226.1` | 394,226 | **3,942.26** |
| Commission, tax | `394,226 × 7 ÷ 100 = 27,595.82` → 27,596; `394,226 × 53.55 ÷ 10,000 = 2,111.08` → 2,111 | | $275.96 + $21.11 |
| Contribution | `394,226 − 134,052 − 27,596 − 2,111` | 230,467 | 2,304.67 |
| Profit after | `394,226 − 186,007 − 27,596 − 2,111` | 178,512 | 1,785.12 (45.3%) |
| Floor at 35%, this project | `186,007 × 10,000 ÷ 5,746.45 = 323,690.28` | 323,690 | 3,236.90; the deal is $705.36 above it |

Had the offer stored one palm's deal price and the project taken it whole, the three-palm job would have been priced at $2,020.76 against a $1,860.07 cost: profit after `202,076 − 186,007 − 14,145 − 1,082 = 842`, a 0.4% margin, and no floor check would have run. The offer's "sold 3 of 30" counts Σ `offerUnits`, and crew-hours booked is Σ project hours (5 h here, not 3 × 3).

**The floor rule in action.** The owner tries 30% off: `224,529 × 70 ÷ 100 = 157,170.3 → 157,170`, $87.50 under the floor; the Offer form shows "Below floor by $87.50 · max discount 26.1%" and will not activate the offer. With the company's floor margin at its default 0 the floor is break-even after commission, `95,345 × 10,000 ÷ 9,246.45 = 103,115`, so no deal is under water at activation; 35% is the owner's number to set. Later moves are caught per project: a negotiated override of C = 10 on a one-palm project lifts its floor to `95,345 × 10,000 ÷ (10,000 − 3,500 − 1,076.5) = 175,799.76` → $1,758.00, still $262.76 under the deal; the Cherrylake quote coming in at $200 (cost 99,345) lifts the package floor to `99,345 × 10,000 ÷ 5,746.45 = 172,880.65` → $1,728.81, headroom $291.95; the deal goes under the 35% floor only if the unit cost passes `202,076 × 5,746.45 ÷ 10,000 = 116,121.96`, a Sabal at $367.77. When it does, the economics box says "Floor $X is above the deal" and every re-priced project under the offer shows "Below floor by $X" in `.orange`.

**What the customer copy carries:** the customer name, the promise, the price and saving, the windows, "first 30", what is included and not, the service area and the code. **Never:** cost, contribution, profit, margin, commission, floor, crew-hours, a row name, a rate or the word "sub"; a test greps for each. The internal copy adds the tables above.

### A Commissions report month (slice 3)

Four jobs sold by the example salesperson in October, priced under c (A 7, C 7), with the Jobber invoice dates typed in as they are paid:

| Sold | Customer paid | Project | Base | Commission | Payroll tax | Profit after |
|---|---|---|---|---|---|---|
| Oct 3 | Oct 20 | Tree Removal – Medium | $5,229.21 | $366.04 | $28.00 | $2,614.61 (50.0%) |
| Oct 9 | Oct 30 | Tree Removal – Small | $2,756.89 | $192.98 | $14.76 | $1,378.45 (50.0%) |
| Oct 17 | Nov 5 | Palm Trimming – up to 6 palms | $1,924.27 | $134.70 | $10.30 | $962.14 (50.0%) |
| Oct 24 | Nov 12 | Stump Grinding – via sub | $750.00 | $52.50 | $4.02 | $393.56 (52.5%) |
| | | **Earned, October 2026 (sold, accrual)** | **$10,660.37** | **$746.22** | **$57.08** | |
| | | **Payable, October 2026 (customer paid Oct, commission unpaid)** | $7,986.10 | **$559.02** | $42.76 | |
| | | Payable, November 2026 | $2,674.27 | **$187.20** | $14.32 | |

**Copy for payroll — October** puts `<salesperson> — commission bonus, October 2026: $559.02 (2 jobs)` on the pasteboard for the PEO run; the other two jobs appear in November's once their invoices are paid, and `559.02 + 187.20 = 746.22` reconciles to the month earned. **Mark paid** stamps `commissionPaidAt` on those two; after that the sale on either cannot be cleared, so a paid commission never drops off the report. The ledger is the sum of what each job shows; 7% of the month's bookings would be `1,066,037 × 7 ÷ 100 = 74,622.59 → $746.23`, one cent off, and the per-job figures win because header and report compute from the same base (`soldPriceCents ?? price`). Salary in the month is informational: 22 weekdays × $200 = $4,400 gross, already in every price through overhead.

The presale is where the two dates matter most: 30 palms sold in February and March earn `30 × 14,145 = 424,350` = $4,243.50 of commission on those months' lines, but none of it is payable until the Jobber invoices are paid after planting in April to June. Under the old draft, February's payroll copy would have carried commission on work not yet performed.

**Margin on sold work** = (base − estimated cost − commission − tax) ÷ base, per job and per month, with an **actual cost** column read from `actuals.actual.cost` alone (never the price that `actuals` recomputes) when actuals are entered; under-target jobs listed.

### What Planning reads (DECISIONS 90; not built here)

| Figure | Source |
|---|---|
| Annual fixed overhead incl. salaried staff | Σ active overhead rows ($155,864.30 today); salaried staff = rows with `salaryInputs` (slice 1b) |
| Crew payroll at billable hours | Σ `rateCents × billableHours` over active labor rows that are not track-only (stored cents, DECISIONS 14): `(6 × 3,501 + 8,667) × 1,500 = 44,509,500` = $445,095.00 today, the owner's row included since it is not track-only |
| Commission allowance | `A × (100 + B) ÷ 10,000` = **7.5355% allowance** at 7/7.65: each $100,000 priced sets aside $7,000 + $535.50 = $7,535.50 |
| Commission paid, share of bookings | Σ (commission + tax) ÷ Σ sold base over the sold projects (slice 3); equals the allowance only when the example salesperson sells everything at 7% |
| Bookings (sold, accrual), commission earned, payable and paid, by month and person | the projects' `soldAt`, `soldPriceCents ?? price`, `customerPaidAt`, `commissionPaidAt` (slice 3); no cash figures |
| Package list price, contribution, profit after, floor and break-even | `Pricer` and `OfferEconomics` on each package and offer (slice 2) |
| Crew-hours booked and offer targets | Σ hours of sold projects; Σ `offerUnits` of sold projects under each offer against `targetUnits` |

## Screens

### Slice 1a

- **Labor Form:** "Not on the crew" toggle with the caption "Salary or sales: never priced as labor; a salary goes on an Overhead line", and a "Commission %" field (0…100). The Labor table adds a "Commission" column when any row has one and greys a not-on-crew row's rate.
- **Company → Pricing defaults:** two fields after the minimum job, with the §Data model captions, each 0…100; the field refuses `M + A(1 + B/100) > 95`. When A or B changes and any template's snapshot differs: "N packages priced under an older allowance — **Re-price packages**", one action over every template.
- **Project header:** a **Sold by** menu beside Crew (None, then every active Labor row with its %), shown once any Labor row carries a commission % or the project names someone; hidden on packages. Picking a person sets the link, the name and the snapshot %; a small "Commission %" field beside it is the override, disabled until Sold by is set, captioned "person's rate: 7%" when they differ. When A > 0 or C > 0 the figure row becomes: Cost · Target margin "50% · 7% allowance" · **Price** (`.largeTitle`) · Commission "$366.04 · 7%" with caption "+ $28.00 payroll tax" · Profit "$2,614.61" with caption "50.0% after commission · $3,008.65 before". Below target: the caption reads "below 50% target" in `.orange`; a negative profit after reads "loses $59.27 after commission". With A = 0 and C = 0 the header is today's, unchanged. Semantic styles only (DECISIONS 39).
- **Copy price** is unchanged. **Copy breakdown** adds, after Price: `Sales allowance: 7% (+7.65% payroll tax)` when A > 0, `Commission: $366.04 (7%)` and `Commission payroll tax: $28.00` when C > 0, and `Profit after commission: $2,614.61 (50.0% margin)`; never a person's name.
- **Loadouts:** the member picker lists labor rows that are on the crew.
- **Readiness:** the Labor and Equipment gates count priced (not track-only) rows and list track-only rows separately ("3 priced · 1 not on the crew"); a salaried manager does not make a crew.
- **Bucket table delete:** "used in N projects · sold M" and the guard.

### Slice 1b

- **Overhead Form:** "Calculate…" beside "Cost per year" → `SalaryCalcSheet`: amount, period picker (day · week · biweekly · semimonthly · month · year), days per week, weeks per year, burden % (default from Settings), read-only "= $67,600.00 per year · $45.07 per hour at 1,500 billable hours", Save. The one-field Form stays for every other overhead line (DECISIONS 34 amended for this case only).
- **Projects list:** "Sold by" and "Profit after" columns, sortable.

### Slice 2 additions

- **Project header** under an offer: "Deal $2,020.76 · 10% off list $2,245.29 · 1 unit", multiplier hidden; "Below floor by $X" in `.orange` when the project's own floor passes the deal. **Offers** economics box: the §Spring palm table with contribution and profit after as two columns, and "Floor $X is above the deal" after a re-price that lifts it.

## Slices

| # | Scope | Schema / format | Tests | Customer Mac after |
|---|---|---|---|---|
| **1a — Commission-aware pricing, salesperson on the project, not-on-the-crew** (one session; 0.2.4, build 6) | `Pricer` allowance/burden/commission and four `Breakdown` fields; `trackOnly` (83's text, bucket-neutral), `commissionPct`, `soldProjects`; the six `Project` fields; two company defaults; Sold by, the override and the header; Copy breakdown; Re-price packages; readiness and loadout filters; transfer format 3 and merge; data layer v4 (labor row only) | lightweight; **format 3** (or 4), reads 1–3 | §Tests, 1a | The example salesperson's labor row cannot be priced by mistake; every job shows commission and profit after it; the owner decides the allowance from a header that tells the truth; no package price moves on install |
| **1b — Salary calculator, list columns** (one short session; 0.2.5) | `SalaryCalc`, `SalaryCalcSheet`, `salaryInputs`; Projects-list columns; DECISIONS 34 amendment; data layer v5 (the overhead row's `calcInputs`) | none; format unchanged (`calcInputs` already travels) | §Tests, 1b | The $67,600 line is computed, not typed; the salary burden can be changed in one field when the PEO invoice is read |
| **2 — Offers** (0.3.x) | `Offer`, `Project.offer` / `dealDiscountPct` / `offerUnits`, `dealFloorMarginPct`; `Pricer` gains `dealDiscountPct` and `floorPrice`; `OfferEconomics` (prices as `instantiate` does; contribution); Business → **Offers** (list · form · economics box · Copy offer · Copy offer economics · Use Offer with units); Packages "Make Offer"; Project header deal line and per-project floor check; `offers[]` in transfer and merge; DECISIONS 90 amended (Business gains Offers) | lightweight; format unchanged | `OfferEconomicsTests` (every figure in §Spring palm; 30%/26.1%/26.2% boundary; break-even 3 on contribution and 4 if overhead were wrongly included; F + C ≥ 95 clamps; the economics ignore the template's snapshot A), `PricerDealTests` (discount on the project's own price, scenario i; floor wins; multiplier ignored; nil discount reproduces everything; units 3 → the 5 h project above; a C = 10 override recomputes the floor), `OfferTextTests` (forbidden words), `OfferMergeTests` | The owner makes offers for the nine packages and prices the spring palm presale; marketing gets a customer copy and an internal copy with contribution and break-even |
| **3 — Sale terms and reports** (0.3.x) | `soldAt`, `soldPriceCents`, `customerPaidAt`, `commissionPaidAt`; the project's Sale row; Re-price disabled while sold; Duplicate clears them; clearing a sale refused once commission is paid; Business → **Reports**: Commissions (by person × month; earned · payable · paid; Mark paid; Copy for payroll by customer-paid month), Margin on sold work (estimated and actual cost columns, vs target, under-target listed), By offer (Σ units of target, Σ hours); Copy report; `BUCKETS_SCREEN=reports`; DECISIONS 90 amended (Business gains Reports) | lightweight; format unchanged | `SalesReportTests` (the §October month: earned 746.22, payable 559.02 / 187.20; base = `soldPriceCents ?? price` in header and report; period edges at 23:59 on the 31st; nil salesperson → no commission; empty period → zero rows; the presale earns in Feb–Mar and is payable Apr–Jun), `ProjectSaleTests` (sold freezes Re-price, duplicate clears, clear-sale refused after Mark paid) | Payroll gets a bonus figure it can defend, on paid invoices; the owner sees bookings and margin after commission by month |
| **4 — Campaigns and attribution** (0.3.x or 0.4.0) | `Campaign`, `Project.campaign`; Business → **Campaigns** (offer, channel, budget, spent, Copy tagged link from the offer's code and URL); Attribution report (sold, bookings, direct cost, commission, contribution, spent, cost per sold job, return on spend = Σ contribution ÷ spent, contribution after spend; footer: spend is not project cost); DECISIONS 90 amended (Business gains Campaigns) | lightweight; format unchanged | `AttributionReportTests` (spent 0 or sold 0 → "—"; contribution, not profit after), `CampaignMergeTests` | The palm presale can be set up and measured, organic first and then ads, before any ad runs |
| **Later** | Jobber read-only bridge fills `soldAt`, `soldPriceCents`, `customerPaidAt` (from `PaymentRecord`), quote status, lost reason, lead source and the campaign tag through `ExternalLink` (spec Gate 2); then Pipeline and win rate (sold ÷ (sold + lost) over projects closed in the period) as read-only reports; a per-person commission tax for a 1099 rep; CSV export of the reports if the owner asks | | | Typing goes away |

### Slice 1a files

| File | Change |
|---|---|
| `Sources/Core/Pricer.swift` | `PriceRule.targetMargin(_, allowance: = 0, burden: = 0)` and its `markupPercent`; `CommissionTerms {pct, burdenPct, baseCents?}` with `.none`; `Breakdown` + `commission`, `commissionTax`, `profitAfterCommission`, `marginAfterCommissionPct` (`.zero` updated); `price(lines:hours:multiplier:rule:commission: = .none, minimumJobCents:billableHours:)`, existing signatures forward; the A = 0 branch keeps today's expression; A, B, C clamped to 0…100, negative or non-finite → 0 (DECISIONS 10) |
| `Sources/Models/BucketItem.swift` | `trackOnly`, `commissionPct`, `soldProjects` inverse; the delete guard |
| `Sources/Models/Project.swift` | the six fields; `effectiveCommissionPct` (override ?? snapshot; 0 without a salesperson); `pricingRule` passes A and B; `setPricing` snapshots them; `breakdown`/`actuals` pass `CommissionTerms`; `setSalesperson(_:)`; `reprice` refreshes the snapshot from the linked row and leaves the override; `make`/`reprice`/`apply` skip `trackOnly`; `duplicate` copies the sales fields; `asPackage` clears them; `repriceTemplates(in:)` |
| `Sources/Models/AppSettings.swift` | `salesAllowancePct` (0), `commissionBurdenPct` (7.65), keys, `register`, `current`, `save`, Decimal views; `pricingRule` carries them |
| `Sources/Models/Readiness.swift` | gates count `!trackOnly`; track-only rows listed separately |
| `Sources/Models/Transfer.swift` | `currentFormatVersion = 3`; `Item.trackOnly: Bool?` (written when true), `Item.commissionPct`; `ProjectRecord.salesAllowancePct`, `commissionBurdenPct`, `salespersonIndex`, `salespersonName`, `commissionPct`, `commissionPctOverride`; `SettingsRecord.salesAllowancePct?`, `commissionBurdenPct?` (absent → defaults; always written, as every setting is under 76); export/import round trip; merge sets `trackOnly` (never clears, as archiving), applies `commissionPct` when present, includes both in the `same` check; packages never carry a salesperson; 89's rule extended to the two settings |
| `Sources/Views/BucketItemDetail.swift` | Labor: Not on the crew, Commission % |
| `Sources/Views/BucketTableView.swift` | Labor Commission column; not-on-crew caption; the delete message counts sold projects |
| `Sources/Views/CompanyView.swift` | the two Pricing-defaults fields, the 95 guard, the "Re-price packages" banner and action |
| `Sources/Views/ProjectScreen.swift` | Sold by menu and override; the header figures; `ProjectText.breakdown` lines |
| `Sources/Views/LoadoutsView.swift` | member picker filter |
| `Tests/StoreMigrationTests.swift` | `BucketsSchemaV023` |
| `project.yml`, `README.md`, `docs/DECISIONS.md`, `docs/BRIEF.md` | 0.2.4 build 6; DECISIONS 83 (text), 92, 94, 95, and 93's first paragraph; the BRIEF lines below |
| vault `tools/build_layer_v2.py` | learns `trackOnly` and `commissionPct` on items (today it knows neither) and the two settings keys |
| vault `sacred-tree-layer-v4-…json` | §Data layer v4 |

### Slice 1b files

| File | Change |
|---|---|
| `Sources/Core/SalaryCalc.swift` (new) | `SalaryPeriod`, `SalaryCalcInputs {amountCents, period, daysPerWeek, weeksPerYear, burdenPct}`, `SalaryCalc.annualCents(_:) throws` |
| `Sources/Models/BucketItem.swift` | `salaryInputs` (derived from `calcInputs`) |
| `Sources/Views/BucketItemDetail.swift`, `SalaryCalcSheet.swift` (new) | Overhead: Calculate… |
| `Sources/Views/ProjectsListView.swift` | Sold by, Profit after |
| `docs/DECISIONS.md`, `docs/BRIEF.md` | 93's second paragraph (34 amended); BRIEF §2.3 |
| vault `tools/build_layer_v2.py`, `sacred-tree-layer-v5-…json` | `calcInputs` on the overhead row |

### Tests (XCTest, synthetic names and wages)

Slice 1a:

- `PricerCommissionTests`: A = 0 reproduces `PricerSpecFiguresTests` and `MarginPricingTests` bit for bit (a loop over the fixtures: 250,150 … 303,912; 370,592 … 450,240; the 2¢-at-20% tie → 3); 222,056 → **522,921** (50/7/7.65), **516,409** (50/7/0), **444,112** (A 0), **1,045,843** (2×), **1,568,764** (3×); commission **36,604**, tax **2,800**, profit after **261,461**; C = 0 → profit after 300,865 and `300,865 − 261,461 = 39,404`; 29,992 → floor **75,000** with 5,250 / 402 / 39,356; C 10 → 52,292 / 4,000 / 244,573; A 0, M 5, C 7 → **−5,927**; an exact half-cent tie in `Base × C ÷ 100` rounds away from zero (12,350¢ at 7% = 864.5 → 865); a base passed in (`soldPriceCents`) replaces the price for commission only; `share` clamps at 9,500; A, B, C over 100 clamp, negative or NaN → 0; a legacy markup project ignores A.
- `ProjectSalespersonTests`: pick → link, name and snapshot % set; Re-price refreshes the snapshot from the row and A/B from the defaults **and leaves `commissionPctOverride` alone** (scenario f survives a fuel change); effective C is the override when set, the snapshot otherwise, and 0 once the salesperson is cleared even if an override remains; `context.delete` on the row (bypassing the guard, to exercise the inverse) nullifies the link and keeps the name; the guard refuses a row with `soldProjects`; Duplicate copies; Use Package and Save as Package leave none; a `trackOnly` row is skipped by `make`, `reprice` and `apply(loadout)` while an existing line for it keeps pricing from its snapshot (17); Re-price on a template without a line for the track-only row appends nothing.
- `RepriceTemplatesTests`: after A changes, the banner count equals the templates whose snapshot differs; the action re-prices all of them and none of the projects; a second run reports 0.
- `ReadinessTests`: a store whose only labor row is `trackOnly` is Not ready on Labor rows and lists it as not on the crew.
- `TransferFormat3Tests`: round trip of every new key; a format-2 file reads with the fields nil and the defaults; a 0.2.3-shaped decoder refuses format 3 (mirrors 74's test); settings always carry the two keys; merge sets `trackOnly` and never clears it, applies `commissionPct`, applies the two settings when present and leaves them when absent (89), and a package line for a track-only row merges with `isOn` from the file.
- `StoreMigrationTests`: `BucketsSchemaV023` (today's seven `@Model` classes, nested as `BucketsSchemaV11` is); write nine package-shaped projects, the empty template, the legacy markup project and the salary line; open with the new schema; every price unchanged, `commissionPct == nil`, `commissionPctOverride == nil`, `salesperson == nil`, `trackOnly == false`.
- `ProjectScreenTests`: Commission shows only when > 0; the override field is disabled with no Sold by; Copy breakdown pinned with and without a salesperson and holds no name; Copy price unchanged.
- `PrivacyGuardTests`: unchanged; `Tests/` fixtures are synthetic.

Slice 1b:

- `SalaryCalcTests`: 20,000/day × 5 × 52 at 30% → 6,760,000; at 10% → 5,720,000; the period table; a tie; negatives throw; `salaryInputs` round-trips through `calcInputs`.
- `ProjectsListTests`: the two columns sort.

### Data layer v4 and rehearsal

The v4 file (vault, built by `tools/build_layer_v2.py`, which slice 1a first teaches `trackOnly`, `commissionPct` and the two settings keys, from the live export with a v4 overrides file):

1. The example salesperson's Labor row: `trackOnly: true`, `commissionPct: 7`; note rewritten ("Salesperson, not on the crew; salary on the Overhead line; 7% commission on the price of the jobs they sell").
2. The sales salary Overhead row: `rateCents 6760000` unchanged; note rewritten without the "set the target margin to 57%" advice, pointing at Company → Sales allowance; `needsOwnerConfirmation` stays until the burden is confirmed. The `calcInputs` come with v5 at slice 1b.
3. No settings changes (A stays 0; B's 7.65 is the default and is written by the app, not the layer), no package changes: the nine priced packages already have that labor line off and the salary line on, and the two 197-line projects now skip that row by the flag.

Rehearsal, as 0.2.1–0.2.3: copy the three store files from `onboard-2026-09-30-054709/` to a scratch folder; launch the 0.2.4 build with `BUCKETS_STORE` and `BUCKETS_EXPORT_FILE`; diff the export against `export-final.json`: the expected difference is `formatVersion: 3` and the two settings keys `salesAllowancePct: 0` and `commissionBurdenPct: 7.65` (settings are always written, DECISIONS 76), nothing else; price all **11 projects** (the nine packages, "New package" at $750, and the legacy "New project") — identical; apply v4 through `Scripts/onboard.sh` on the copy (updated 2 rows, every other row unchanged, no project touched; a second run reports 0 changes); Re-price "New package" and "New project" and confirm no line is appended for the salesperson; install with the script's backup (79); export and diff again. Rollback: the parked 0.2.3 app plus the backup folder.

## DECISIONS to write (92–98; 80–86 stay the equipment plan's; renumber at merge if a sibling lands first)

- **83 (shared text, written by the first branch to land).** The bucket-neutral definition of `trackOnly` in decision 3.
- **92 Sales allowance and commission in the price rule.** The formula and rounding of §The math; the allowance and its payroll tax are company pricing defaults snapshotted on the project beside the target margin (70) and treated by the data layer as 89 treats the others; changing them offers Re-price packages; margin in the header means after commission; the commission base is `soldPriceCents ?? price` everywhere; A, B, C held to 0…100; A = 0 keeps every pinned figure; legacy markup projects ignore A; Copy breakdown's added lines and what it never carries (41).
- **93 Salaried staff off the crew.** First paragraph (1a): salaried staff who are not on the crew are Overhead lines; their Labor row is not on the crew (83) and never priced; the BRIEF §2.1 line below. Second paragraph (1b): the Overhead salary calculator, amending 34 for this case; BRIEF §2.3.
- **94 Salesperson on a project.** Sold by; the name and % snapshots, refreshed by Re-price (17, 18); the override, never refreshed, disabled without a salesperson; effective C; Duplicate copies, packages carry none; the declared inverse and the delete guard (21, 22); never a person's name in customer or internal copies (41, 88).
- **95 Transfer format 3 (or 4) and merge.** The new keys; settings always written, so the two defaults appear in every export; `trackOnly` set by file, never cleared; older files read with defaults; an older app refuses the file (74), because it would otherwise drop `salesAllowancePct` and price lower.
- **96 Offers** (slice 2). One model on a package; a discount %, applied to each project's own list price, the one price the rule does not set from the margin (amends 24 for that field); `offerUnits`; the floor rule at activation and on every project, and the company deal floor margin; contribution as the marketing figure and budgets extra to the Advertising line; the customer copy's forbidden words; `offers[]` in transfer and merge; **amends 90**: the Business section gains Offers beside Planning.
- **97 Sale terms and the Commissions report** (slice 3). Four dates and the sold price; earned = sold month, payable = customer paid and commission unpaid; sold freezes Re-price; a paid commission is never cleared; commission owed = `round(base × C ÷ 100)`; Mark paid; Copy for payroll by customer-paid month; bookings, not revenue; no pipeline statuses, lost reasons, lead sources or win rate until the Jobber bridge; *Buckets computes commission owed; it does not run payroll, withhold tax or pay anyone* (the §5.1 fence, stated); **amends 90**: Business gains Reports.
- **98 Campaigns and attribution** (slice 4). Offer plus channel, one budget, one spent figure; the offer's code and URL make the tagged link; single-touch credit; return on spend on contribution; no pixel, tag, audience, click ID, token or ad-account ID is stored and nothing is fired; campaign spend never enters project cost; **amends 90**: Business gains Campaigns.

BRIEF amendments: §1 gains the allowance line under the formula ("Price = max(min, Cost × 10000 × mult ÷ (10000 − 100·margin − allowance·(100 + commission tax)))"); §2.1 "salaried staff who are not on the crew (sales, office) are Overhead lines; their Labor row is marked not on the crew and is never priced"; §2.3 "salaries are entered through the overhead Calculate… sheet" (1b); §5.1 adds "no CRM, no pipeline stages, no pixels, no email, no payroll" as words.

## Kept out

No `SalesRep`, `PayType`, `Deal`, `Payment`, `CommissionPayout`, `CampaignSpend` or `ExternalLink` models here. No cash ledger, deposits, refunds or cumulative accrual on payments (Jobber owns cash; `customerPaidAt` is one typed date, not a ledger). No customer records, addresses, phones or emails. No pipeline statuses, lost reasons, lead sources or win rate until the bridge reads them from Jobber. No pixel IDs, GA4, GTM or ad-account IDs, no click IDs, no tokens, no tracking notes, no spend import, no tag firing. No per-line discounts, coupon codes or stacked deals (the floor is on the whole project, as the margin is, 24). No two-person splits (an override on the lead seller plus a note). No commission on net-of-subs unless the owner says so (question 2). No CSV writer until asked. No activity log. No forecasts, charts or documents: Planning stays as DECISIONS 90 left it. No new rounding rule.

## Open questions for the owner (defaults in bold)

Block nothing: slice 1a ships with the allowance at 0 and prices unchanged.

1. **Price or margin?** Put the 7% allowance into every price (+17.75%: Medium $4,441.12 → $5,229.21, 50% after commission), or keep today's prices and accept 42.5% after commission (target 42.5, allowance 7 → $4,444.28)? **Default: allowance 7**, because the salary line's own note says the intent is 50% after commission; the owner types it in Company when he decides, then presses Re-price packages.
2. **Commission base:** 7% of the full price, including materials and subcontractor pass-through (the $725 grapple truck on a Large removal), or of the price net of subs? **Default: the full price** ("the revenue the salesperson creates"). Net changes the Core formula to a two-step solve.
3. **Payroll tax on commission:** 7.65% plus the sales-class workers' comp rate and any PEO % fee, from the PEO invoice. **Default 7.65.**
4. **The example salesperson's salary burden:** 30% as typed, or about 10% for a sales position? $10,400/yr of overhead, $6.93 per crew hour, $55.47 on the Medium removal. **Default: 30 until the invoice is read** (no price moves).
5. **When is commission payable:** on sale, on completion, or on customer payment? **Default: when the Jobber invoice is paid**: the report shows commission earned by sold month and payable by customer-paid month, and Copy for payroll copies only the payable jobs; the paid date is typed until the bridge reads it. If the answer is "on sale", payable = earned and `customerPaidAt` is not needed. Is a cancelled job's commission clawed back? **Default: a paid commission is never cleared in Buckets**; a clawback is a payroll matter noted on the project.
6. **Jobs the owner sells:** Sold by the owner at 0%, allowance kept as profit, or does the example salesperson earn on every job? **Default: 0%**; Planning may later earmark the unassigned allowance as the ad budget.
7. **Deal floor margin:** **default 0 (break-even after commission)**; 35% is the placeholder in the worked example.
8. **Palm package:** 3 h or 4 h per install (+$250.07 per hour), Dingo on, stake kit as the bracing proxy; Cherrylake quotes for Sabal, pindo and a field-grown European fan (only a 10 in pot row exists); and the Tree Planting package's Dingo, off in the export while its note says on. **Default: 3 h, Dingo on, one offer per species under one code.**
9. **Presale mechanics and multi-palm orders:** deposits and refund wording are Jobber's; a customer's 3-palm order is one project of 3 units, priced on its own hours (3 + 1 per extra palm) with the same 10% off, and counted as 3 of the 30. **Default: yes.** Is the marketing budget ($3,500) extra to the $22,659.62 Advertising line or carved out of it? **Default: extra**, which is why break-even is on contribution.
10. **Format number:** 3 unless the equipment-classes slice 2 merges first, then 4. **Default: first to merge takes 3.**

## Review log (2026-09-30, 22 issues: 3 high, 7 medium, 12 low; all applied)

- **H1** earned vs payable: `customerPaidAt` added (slice 3); Earned = sold month, Payable = customer paid and commission unpaid; Copy for payroll by customer-paid month; clearing a paid sale refused; October example split $559.02 / $187.20 = $746.22; Q5 rewritten.
- **H2** advertising double count: `unitContribution` (no overhead) defined; break-even 3, not 4 (`ceil(350,000 ÷ 122,677 = 2.85)`); at 30 palms contribution $36,803.10, after spend $33,303.10, reconciled to the $27,451.20 profit-after column; budgets stated extra to the Advertising line; Attribution on contribution.
- **H3** per-unit offer vs whole project: `dealDiscountPct` on the offer and project, `offerUnits`, discount applied to the project's own price; the 5 h, 3-palm worked example ($3,942.26 deal, floor $3,236.90); targets count Σ units; crew-hours Σ project hours.
- **M1** floor rechecked on every project from its own cost and effective C; economics box flags a re-priced floor above the deal; "never at activation"; C = 10, Sabal $200 and $367.77 threshold worked.
- **M2** `commissionPct` snapshot plus `commissionPctOverride`, never refreshed; test added.
- **M3** "Re-price packages" banner and action; `OfferEconomics` prices as `instantiate` does; 89 extended to the two settings.
- **M4** one commission base `soldPriceCents ?? price` in header and report; Margin on sold work formula with an actual-cost column from `actuals.actual.cost`; return on spend = Σ contribution ÷ spent; "Bookings (sold, accrual)"; win rate deferred.
- **M5** slice 3 reduced to `soldAt`, `soldPriceCents`, `customerPaidAt`, `commissionPaidAt`; statuses, lost reason, Pipeline, win rate and `leadSource` deferred to the Gate 2 bridge.
- **M6** slice 1 split: 1a (pricing, salesperson, `trackOnly`, format 3, v4) and 1b (SalaryCalc, sheet, 34 amendment, list columns, v5); `build_layer_v2.py` in the file list.
- **M7** 83's `trackOnly` text written once, bucket-neutral, labels per bucket.
- **L1** kept allowance = Commission + CommTax at C = A = 39,404 → $394.04. **L2** 46.5% at B = 0, 46.0% (45.96%) at 7.65. **L3** expected diff = `formatVersion 3` plus the two settings keys. **L4** 10 templates plus 1 legacy project; all 11 priced in the rehearsal; the Re-price append added to defect 1. **L5** effective C = 0 without a salesperson; override disabled until Sold by is set. **L6** A, B, C held to 0…100; "loses $59.27 after commission" (A 0, M 5, C 7 → −5,927); floor claim qualified "when C ≤ A". **L7** the delete test uses `context.delete`; the message counts sold projects. **L8** the name replaced with "<salesperson>". **L9** BRIEF §2.1 narrowed to salaried staff not on the crew. **L10** crew payroll = Σ `rateCents × billableHours` over active, not-track-only labor rows ($445,095.00); commission share = Σ (commission + tax) ÷ Σ sold base; 7.5355% labelled allowance. **L11** `code` and `landingURL` on the Offer only; Campaign = offer + channel + budget + spent; `trackingNotes` dropped. **L12** 90 amended in 96–98; the format-3 rationale names the dropped `salesAllowancePct`.
