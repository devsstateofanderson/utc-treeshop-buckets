# Buckets Pro functional roadmap

This is the product plan for making Buckets materially more useful. It starts from the current local Mac pricing app and adds the workflows TreeShop will operate for a real service company. Installation, backups, permissions, and release discipline support the product; they are not the product's main value.

The detailed external-system and tree-industry model is maintained separately in [Jobber + tree-industry integration specification](10-jobber-tree-industry-spec.md). That document is the source of truth for Jobber object names, sync boundaries, write approvals, and standards-reference metadata.

## Product promise

Buckets Pro should let TreeShop answer five questions every working day:

1. What work is coming in and what should it be priced at?
2. Which cost assumptions make that price trustworthy or questionable?
3. What happened on completed jobs compared with the estimate?
4. What business constraint should the owner and team work on next?
5. Who is doing what, by when, with what evidence of completion?

The current app answers the first question partly and the third question in a limited way. The roadmap fills those gaps in that order.

## Current Buckets versus the Pro product

| Area | Current v1.1 | Pro outcome |
|---|---|---|
| Catalog | Rows, rates, categories, links, notes | Company-specific catalog with source, confidence, review date, history, and an unresolved-input queue |
| Estimate | One project with toggles, hours, quantities, packages, loadouts | Job type, crew scenario, assumptions, scope checklist, scenario comparison, reusable estimate templates, and a quote-ready result |
| Actuals | Actual hours and quantities entered manually | Jobber-linked actuals, coverage indicators, variance reasons, and learning recommendations |
| Jobber | Manual transfer | Read-only sync and reconciliation first; carefully approved write-back later |
| Operations | Notes and external work queues | Intent, goals, actions, owners, budgets, deadlines, evidence, and results |
| Reporting | Project list and individual breakdown | Owner scorecard, weekly review, trend views, and exceptions that need action |
| Company | One local company store | Explicit company workspace with clean export, future multi-company administration, and no cross-client data mixing |
| AI | External assistant operating beside the app | AI can explain, flag, summarize, and prepare actions from structured Buckets data, with a visible approval trail |

## Release 1: Field-ready estimating

This is the first functional upgrade. It should make the current pricing workflow faster and more reliable for a Florida tree-service company.

### 1. Company-specific setup profile

Add a setup view that shows:

- Company identity and service area
- Active service types
- Crew count
- Billable-hours assumption
- Target margin and minimum job
- Catalog completion percentage
- Missing labor, equipment, overhead, and subcontractor inputs
- Last verified date for each setup area

The screen should tell the operator what is still missing before claiming that pricing is ready.

Acceptance: a new company can open one screen and see the remaining setup work grouped by business area.

### 2. Row trust and review workflow

Add these fields to relevant catalog rows and company defaults:

- Evidence/source
- Source link or document name
- Checked date
- Review due date
- Confidence: verified, owner-confirmed, estimated, or missing
- Approved by
- Assumption note

Add filters for `missing`, `estimated`, `overdue`, and `owner confirmation needed`. A price using an unresolved input should show a small warning in the estimate without blocking the user from working.

Acceptance: an operator can find every unresolved cost input in under one minute and can mark it verified with a source and date.

### 3. Tree-service catalog corrections

The first-client edition needs a service-oriented catalog rather than a generic supply list. Add a company catalog review flow that can:

- Archive irrelevant categories in bulk
- Rename a row without breaking old project snapshots
- Merge duplicates with a preview
- Assign equipment unit codes
- Mark owned versus rented versus subcontracted
- Distinguish fuel, disposal, installed materials, consumables, and subcontracted services
- Record a vendor price and the date it was checked

Acceptance: Sacred Tree's live catalog can be reviewed and corrected without editing JSON by hand.

### 4. Better estimate composition

Extend projects with fields that describe the estimate:

- Service type: removal, pruning, planting, treatment, storm response, or custom
- Site or job address
- Scope summary
- Estimated crew days or phases
- Travel/dump assumptions
- Customer-facing scope notes
- Internal estimating assumptions
- Risk or uncertainty flags

Do not turn this into a full CRM. These fields exist to explain a price and improve future estimates.

### 5. Estimate scenarios

Let the estimator duplicate a project into named scenarios such as:

- Base crew
- Reduced crew
- Add crane
- Add grapple truck
- After-hours
- Conservative hours

Show the scenarios side by side with hours, cost, price, margin, and the changes between them. The estimator should be able to choose one scenario as the approved project.

Acceptance: an owner can see the cost and price consequence of changing crew, equipment, hours, or subcontractors before sending a quote.

## Release 2: Actuals and Jobber reconciliation

### 6. Read-only Jobber connection

Create a Jobber connector that imports:

- Clients and properties
- Quotes and quote status
- Jobs and visits
- Scheduled dates
- Team members
- Invoices and payment status where available
- Time fields where available

Every imported record needs the external ID, retrieved time, and source account. Imports go into a staging view first so a mismatch can be reviewed before it affects a Buckets project.

### 7. Match a Jobber job to a Buckets estimate

Provide a clear link action:

1. Search or select the Jobber job.
2. Select the Buckets estimate or create one from the job.
3. Review client, address, scope, quote value, and date differences.
4. Confirm the match.
5. Keep the link visible on both records.

Prevent duplicate links and show unmatched Jobber jobs in a queue.

### 8. Actuals coverage and reasons

Current actuals show a number but do not explain how trustworthy it is. Add:

- Actual source: manual, Jobber, imported timesheet, or reconstructed
- Coverage: complete, partial, or missing
- Variance reason: hours, crew, equipment, material, disposal, subcontractor, scope change, or data error
- Owner comment
- Review status

Show “estimated 8 hours / actual 10 hours / partial data” rather than treating every actual as equally reliable.

### 9. Learning recommendations

After enough completed jobs, produce simple recommendations:

- “Removal jobs in this service type average 18% more hours than estimated.”
- “Dump loads are consistently undercounted.”
- “This equipment is active in the catalog but missing from completed-job actuals.”
- “The current crew loadout is pricing below the observed crew cost.”

Recommendations must show the jobs and dates behind the pattern. Do not create an opaque score.

Acceptance: a weekly review can turn a variance pattern into a concrete catalog, crew, or estimating change.

## Release 3: The TreeShop operating cockpit

### 10. Objectives and actions

Add a small operating layer with:

- Objective
- Reason
- Owner
- Target date
- Budget or constraint
- Actions
- Status
- Evidence
- Result
- Next decision

Examples:

- “Reduce missed clock-outs below 10% by October 15.”
- “Increase quote acceptance while preserving a 50% target margin.”
- “Replace the generic materials catalog with verified Florida suppliers.”

The owner should be able to open Buckets and see the current objectives, overdue actions, and evidence waiting for review.

### 11. Metrics and scorecards

Create a scorecard view with period-over-period values for:

- Quotes sent and accepted
- Quote conversion rate
- Quoted revenue
- Revenue collected
- Target margin versus observed gross margin where data supports it
- Price per crew hour
- Estimated versus actual hours
- Revenue per crew day
- Lead source
- Open receivables
- Data completeness

Each metric needs a source, period, confidence, target, and next action. A chart without an action is decoration; the scorecard should highlight exceptions.

### 12. Weekly review mode

Create a guided weekly review:

1. What changed?
2. Which numbers are outside target?
3. Which data is missing or stale?
4. Which decisions are waiting on the owner?
5. What three actions happen next?
6. What evidence will close them?

Export the review as a plain-language owner report. This is an immediate TreeShop service deliverable and a future AI input.

## Release 4: AI-ready operating system

The AI layer comes after the data structures above exist. AI should be able to:

- Explain a price from its inputs
- Find stale or questionable assumptions
- Summarize weekly changes
- Draft an action plan from a scorecard exception
- Prepare a catalog update for approval
- Draft marketing work from approved business goals
- Identify repeated estimate misses
- Generate a client report from evidence already in Buckets

AI should not silently change rates, publish advertising, change a Jobber record, or send customer communication. It should prepare the action and identify the approval required.

## Functional data model direction

Do not add every future concept to the SwiftData schema at once. The likely next models are:

- `Workspace` or explicit company identity
- `CatalogReview` for source/confidence/review state
- `ExternalLink` for Jobber IDs and future integrations
- `ImportBatch` for raw sync and reconciliation
- `Objective`
- `Action`
- `MetricSnapshot`

The first release can place source and review fields directly on existing rows. Introduce separate models only when one record needs multiple sources, history, or relationships.

## Build order for the company Mac

1. Setup profile and missing-input queue
2. Source/confidence/review fields
3. Company catalog review and duplicate tools
4. Estimate service type, scope, and assumptions
5. Estimate scenarios
6. Jobber read-only staging and matching
7. Actuals coverage and variance reasons
8. Weekly scorecard and review mode
9. Objectives and actions
10. AI preparation and approvals

This sequence improves the daily product at every step. The first five changes make Buckets better before any API work begins.

## Definition of a mature first Pro release

The first Pro release is ready when TreeShop can onboard a company, identify missing pricing data, build a defensible estimate, compare scenarios, connect a completed job to its estimate, explain actual variance with confidence, review a small scorecard, and turn one exception into an owned action.
