# Shared repository workflow

This public repository is the shared handoff surface between the UTC / TreeShop operating side and the Buckets implementation side. Mr. J. Anderson owns UTC, TreeShop, and Buckets. Alexander Satoski owns Sacred Tree Service, the first client company.

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

The repository contains the product and the operating contract. It is not the customer vault. Raw Jobber exports, SwiftData stores, documents, credentials, and populated access registers stay on the controlled company Mac or approved private storage. Public visibility makes this boundary mandatory.

## Branch and handoff model

1. `main` is the stable shared baseline.
2. Every agent pulls the latest `main` before starting.
3. The implementation agent creates a focused branch such as `claude/jobber-read-only-sync`.
4. The implementation agent updates code, tests, and the relevant spec together, then pushes the branch.
5. The management/review side checks scope, data ownership, failure behavior, tests, and customer impact through the branch and diff.
6. Mr. Anderson approves the product merge. Alexander approves consequential Sacred Tree customer changes. External writes follow their applicable approval.
7. After merge, the next piece of work starts from the updated `main` rather than from a stale local copy.

## Product and operations are connected but distinct

- The **product track** changes Buckets' models, views, calculators, connectors, tests, and release artifacts.
- The **customer track** establishes the company's real catalog, Jobber mappings, operating cadence, and evidence.
- The **management track** decides priorities, reviews outcomes, and keeps UTC's service promise measurable.

The normal loop is: pull latest `main` → implement one bounded change → run tests → push a branch → review the diff → merge → pull latest `main`.

One track may provide evidence to another, but a customer record is not automatically a product default and a proposed feature is not automatically a live operating procedure.

## Pull-request checklist

- [ ] The change is linked to a documented objective or bottleneck.
- [ ] External identities and source-of-truth boundaries are explicit.
- [ ] No secrets or raw customer data are included.
- [ ] Relevant tests pass; new behavior has a regression test where practical.
- [ ] Jobber mutations, if any, are approved, idempotent, checked for `userErrors`, and read back.
- [ ] The handoff states limitations, unresolved decisions, and next safe action.
