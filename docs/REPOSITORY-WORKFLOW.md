# Shared repository workflow

This repository is the shared handoff surface between the UTC / TreeShop operating side and the Buckets implementation side.

## Source layout

```text
Sources/                 Swift application code
Tests/                   XCTest and redacted fixtures
Scripts/                 Build, packaging, catalog, and local tooling
docs/BRIEF.md            Product specification of record
docs/DECISIONS.md        Decisions that resolve ambiguity
docs/treeshop/           UTC, TreeShop, Buckets Pro, Jobber, and tree-industry operating documents
Backups/                 Local customer data; do not add new raw records to GitHub
```

The repository contains the product and the operating contract. It is not the customer vault. Raw Jobber exports, SwiftData stores, documents, credentials, and populated access registers stay on the controlled company Mac or approved private storage.

## Branch and handoff model

1. `main` is the stable shared baseline.
2. The implementation agent creates a focused branch such as `claude/jobber-read-only-sync`.
3. The implementation agent updates code, tests, and the relevant spec together.
4. The management/review side checks scope, data ownership, failure behavior, tests, and customer impact.
5. The owner approves the merge and any external write or deployment.
6. After merge, the next piece of work starts from the updated `main` rather than from a stale local copy.

## Product and operations are connected but distinct

- The **product track** changes Buckets' models, views, calculators, connectors, tests, and release artifacts.
- The **customer track** establishes the company's real catalog, Jobber mappings, operating cadence, and evidence.
- The **management track** decides priorities, reviews outcomes, and keeps UTC's service promise measurable.

One track may provide evidence to another, but a customer record is not automatically a product default and a proposed feature is not automatically a live operating procedure.

## Pull-request checklist

- [ ] The change is linked to a documented objective or bottleneck.
- [ ] External identities and source-of-truth boundaries are explicit.
- [ ] No secrets or raw customer data are included.
- [ ] Relevant tests pass; new behavior has a regression test where practical.
- [ ] Jobber mutations, if any, are approved, idempotent, checked for `userErrors`, and read back.
- [ ] The handoff states limitations, unresolved decisions, and next safe action.
