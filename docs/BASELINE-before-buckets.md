# Sacred Tree Service — baseline before Buckets

Snapshot taken 2026-09-15 from the Jobber exports and the 2025 P&L, so later periods can be compared as **before Buckets** (up to 2026-09-15) and **after Buckets**. Every figure below is from a report on file; nothing is estimated.

## 2025 (full year, cash basis P&L)

| | |
|---|---|
| Revenue | $408,158.87 |
| Cost of goods sold (subs, rentals, materials) | $60,503.79 |
| Gross profit | $347,655.08 (85.2%) |
| Expenses | $272,038.80 |
| Net income | $75,616.28 (18.5% of revenue) |
| Overhead lines now in Buckets (rent, insurance, phones, advertising, accounting, software, tools, fees, travel, wellness) | $87,453.81/yr |
| Payroll + wages + crew checks + sub labor | $103,261.66 |
| Fuel + auto maintenance + auto insurance | $47,388.80 |
| Disposal + stump sub + crane + grapple + equipment rental | $48,663.23 |

Overhead per billable hour at the current Settings value of 1,500 h: **$58.30/hr**. At 2,500 company project-hours it would be $34.98/hr. The brief's worked example assumed $18/hr. Decide which hours figure you want overhead spread over (see below).

## 2026 year to date (Jan 1 – Sep 8)

| | |
|---|---|
| Revenue (Jobber Insights) | $727.2K |
| Job revenue attributed to team members | $646,196.16 across 936 visits |
| Quotes drafted | 494 ($1.64M quoted) |
| Converted or approved | 230 of 470 priced quotes (49%), $535,674 |
| Median quote / median converted quote | $2,100 / $1,700 |
| Awaiting response | 104 quotes, $433,475 |
| August 2026 | 94 new leads, 26 converted quotes, $77.6K invoiced; revenue by lead source: Google 48%, referral 43% |
| Job hours tracked on jobs / general / total | 1,571 h / 3,690 h / 5,261 h (15 team members) |
| Past-due receivables | 9 invoices, $94,980 still owed |

Known data problems in the "before" period: about 47% of recent timesheet hours are missed clock-outs, and 8 of 15 team members log no job-specific time, so hours per job and $/hour are not trustworthy yet. Fixing clock-outs is the single biggest thing that makes the "after" comparison meaningful.

## What "after Buckets" should show

Compare the same table each quarter. The numbers Buckets adds that Jobber cannot:

1. **Estimate vs actual hours** per project (the Actuals section). Target: within ±10% on most jobs. Before Buckets this was never measured.
2. **Margin per job** (Profit ÷ Price in the project header) instead of a blanket 35% markup applied by feel. Target: know the margin on every quote before it goes out.
3. **Price per crew hour** = Price ÷ estimated hours. Before Buckets: median converted quote $1,700 at an unknown hour count.
4. Conversion rate should hold or rise (49% before) while margin becomes known.

How to pull the "after" numbers: Settings → Export JSON, then count projects, sum prices, and read `actualHours` vs `hours` per project. Keep each export in a dated folder.

## Settings recommendations from the reports

- **Labor burden**: still 30% (the brief's default). The 2026 workers-comp certificate on file has no rate on it; read the real percentage off the Southern Personnel Leasing invoice and enter it once.
- **Cost of money**: 0% unless the Toro or a truck is financed; the Western Equipment Finance application on file is blank, so no rate was found.
- **Billable hours per year**: the app has one number that both spreads overhead and sets labor rates. 1,500 is right for a single employee's project hours; if the whole company bills ~2,500 project hours a year, overhead is over-recovered at 1,500 (each job carries $58/hr of overhead instead of $35/hr). Simplest fix if jobs start pricing too high: leave 1,500 and cut each overhead row to the share one crew should carry.
- **Labor rows**: the rates you typed were from memory; the P&L has no per-person wages. Open each labor row, press Calculate…, and enter the real hourly wage; the app does the rest.
