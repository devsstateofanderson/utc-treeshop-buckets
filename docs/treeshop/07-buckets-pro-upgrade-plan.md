# Buckets Pro upgrade plan

Status: supervisor plan, September 2026. This document controls the first software upgrade cycle. The current Mac is the planning, review, and reference environment. The company Mac is the implementation environment where Claude Code builds against client data. Client data must stay out of the product repository.

## Operating arrangement

The work moves through four states:

1. **Observe here:** inspect the current code, live workflow, and failure evidence on the supervisor station.
2. **Specify here:** write a small build brief with the problem, user action, data change, acceptance checks, and rollback plan.
3. **Build there:** Claude Code implements the approved brief on the company Mac using the company-specific fixture or store.
4. **Review here:** review the diff, tests, screenshots, export shape, and operating result. Accept, revise, or reject the change before it becomes a release.

Claude Code may work quickly, but speed does not replace a review gate. Every change gets a commit, a short changelog entry, and an evidence record showing what was tested.

## Current product boundary

Buckets v1.1 is a local SwiftUI/SwiftData Mac application. It prices projects from six buckets, snapshots rates, supports actuals, packages, loadouts, company records, documents, JSON export/import, and catalog merge. It has roughly 4,600 source lines and a substantial test suite, but the repository currently has no Jobber connector, company operating log, goals, task workflow, scorecard, multi-company workspace, user permissions, or agent control surface.

The next product should become more useful to TreeShop while preserving the fast pricing path. Do not turn the first upgrade cycle into a full ERP. A feature earns priority when it improves a live business decision, catches a data error, completes repeated work faster, or makes the next client installation easier.

## Bottleneck map

| Priority | Bottleneck | Consequence | First product response |
|---|---|---|---|
| P0 | Build and release setup depends on local XcodeGen/Xcode state; current environment cannot run `Scripts/test.sh` without `xcodegen` | A change can look complete without a reproducible build | Pin the build prerequisites, add a clean-build check, record app version, and create a release checklist |
| P0 | Saves use many `try?` calls and the local store is the main source of truth | A failed save or damaged store can be silent | Centralize save/error reporting and add export/restore verification |
| P0 | Pricing rows have limited provenance: no first-seen date, verified date, confidence, or approval | A precise price can rest on an old or guessed input | Add source metadata and a review queue before adding sophisticated automation |
| P0 | Catalogs are broad but company fit is manual; generic rows and $0 overhead can enter the workflow | First-client setup is slow and can produce false completeness | Add company-specific active sets, review status, and an import preview |
| P1 | Jobber is the frontline record and Buckets is the pricing record, but transfer is manual | Re-entry wastes time and creates mismatches | Build read-only Jobber ingestion into a staging area; keep write-back out of the first connector |
| P1 | There is no operating intent, task, owner, budget, evidence, or result record | TreeShop work lives in notes and memory | Add a small operating log and scorecard, first manually testable and then modeled |
| P1 | Actuals depend on unreliable time capture | Variance analysis can be misleading | Add data-quality flags, coverage percentages, and confidence to actuals |
| P1 | A store is effectively one company | Multiple clients require separate copies and manual discipline | Add a workspace identity/export manifest before attempting a central server |
| P2 | No history of decisions and changes | The system cannot explain who changed a rate or policy | Add an append-only activity record for consequential changes |
| P2 | Credentials, documents, and AI actions have no product-level governance | Remote operation becomes difficult to audit or hand off | Add an access inventory link, approval record, and agent action log outside pricing calculations |
| P3 | No server, multi-user, or device fleet layer | Scaling beyond the first 5–10 clients will become manual | Design the boundary from observed installations; do not build the server before the local workflow stabilizes |

## Release sequence

### Release 1: dependable installation

Goal: make the current product safe to install, configure, back up, review, and recover.

Deliverables:

- Version and schema information visible in Settings
- A documented clean build and test command
- Central save/error reporting instead of silent persistence failures
- Automatic dated export after a configured change or on demand
- Restore verification against a disposable store
- Export manifest with company name, app version, schema version, source date, and row/project counts
- Import preview showing additions, updates, archives, conflicts, and destructive changes before confirmation
- A client-specific configuration record that identifies the active catalog and pricing policy
- Tests for export, restore, migration, and malformed input

Acceptance: a fresh Mac can install a release, create a company store, import a known fixture, export it, restore it to another store, and produce the same price and row counts.

### Release 2: trustworthy inputs and operating scorecard

Goal: make Buckets useful for TreeShop's baseline work before integrating Jobber.

Proposed input metadata on relevant rows and settings:

- Source or evidence description
- Source URL or document reference
- Checked date
- Next review date
- Confidence: verified, owner-confirmed, estimated, or missing
- Approved by
- Notes about assumptions

Proposed scorecard records:

- Metric name
- Period
- Value and unit
- Source
- Coverage/confidence
- Target
- Owner
- Decision or next action

Start with a narrow scorecard: quotes sent and accepted, quoted value, estimated cost and margin, estimated versus actual hours, revenue per crew day, lead source, open receivables, and data coverage.

Acceptance: the owner can see the baseline, identify which figures are provisional, and create an action from a metric without leaving the company workflow.

### Release 3: Jobber read-only bridge

Goal: remove repetitive re-entry while preserving a clear source-of-truth boundary.

Build an adapter outside the pricing core. It should:

- Authenticate through the client's approved Jobber OAuth flow
- Pull a bounded date range of clients, jobs, quotes, visits, invoices, and available time fields
- Store raw import batches with retrieval time and API version
- Map imported records to internal records without overwriting Buckets assumptions
- Show unmatched, duplicate, and changed records for review
- Re-run safely without creating duplicates
- Produce a reconciliation report

Start read-only. The Jobber API uses OAuth and scopes; the client's admin must authorize the connection. If the integration remains a private draft, Jobber's current documentation limits it to five paying accounts before approval is required. Plan the sixth-account decision in advance.

Acceptance: five known jobs reconcile with a repeatable report, and a failed or repeated sync does not corrupt pricing data.

### Release 4: operating intent and controlled action

Goal: turn TreeShop's management method into a reusable product surface.

The first operating record should support:

- Intent or objective
- Why it matters
- Owner
- Due/review date
- Budget or constraint
- Actions
- Approval state
- Evidence link
- Result
- Follow-up decision

Do not start with a general project-management suite. Test the structure manually in the first company, then implement the smallest recurring shape.

Acceptance: one owner can review current intent, open actions, budget, evidence, and next decisions in a single company view.

### Release 5: multi-company and agent-ready foundation

Goal: make 5–10 installations manageable without mixing clients.

- Explicit company/workspace identity on every export and local store
- Per-company settings, catalogs, integrations, documents, and backups
- No cross-company queries by default
- Operator role and owner role
- Approval required for external writes
- Agent action log with request, tool, target, result, and human approval where required
- Health view for stale backups, failed imports, expired credentials, and overdue reviews
- Central release channel with a per-client compatibility check

Acceptance: an operator can switch between two test companies, prove that their data and settings remain separate, and reconstruct every external action from the log.

## Architecture rules for the builder

- Keep pricing math pure and independent from integrations.
- Put Jobber, Google, marketing, and future agents behind adapters or services; do not spread vendor-specific code through SwiftUI views.
- Keep raw imported data separate from normalized operating records.
- Prefer stable external identifiers over array positions or display names for future integrations.
- Preserve existing project snapshots; never silently change historical prices.
- Make migrations explicit and test them with old export fixtures.
- Use one source of truth for each setting and expose when a value is derived.
- Do not store passwords, API tokens, recovery codes, or client secrets in Git, JSON exports, screenshots, prompts, or test fixtures.

## Supervisor review gate

Before Claude Code begins a feature, this station produces a build brief containing:

1. User problem and current workaround
2. Exact desired behavior
3. Data model and migration impact
4. Source-of-truth boundary
5. Acceptance tests
6. UI or export evidence required
7. Rollback or restore plan
8. Out-of-scope items

After implementation, review:

- Diff and changed files
- Test output
- Build output and app version
- Light/dark screenshots for UI changes
- Export/import round trip
- Client fixture behavior
- Error and backup behavior
- Any new permissions or external writes

The feature is ready for a client release only after the evidence is attached to its commit or release note.

## First three build briefs

1. **Installation safety:** release manifest, centralized save errors, dated export, and restore test.
2. **Input trust:** source/verified date/confidence/review queue for BucketItem and company pricing defaults.
3. **Jobber staging:** read-only import batch, external IDs, reconciliation screen, and duplicate-safe sync.

These three changes increase the quality of every later feature. They should be completed before a large dashboard, autonomous agent, or hardware work begins.
