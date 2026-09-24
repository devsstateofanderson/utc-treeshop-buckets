# Buckets agent contract

This repository is the shared product and operating workspace for UTC, DBA TreeShop, and the Buckets product.

## Read first

1. `README.md` — current application and build behavior.
2. `docs/BRIEF.md` and `docs/DECISIONS.md` — current product specification and decisions.
3. `docs/treeshop/README.md` — UTC / TreeShop operating package.
4. `docs/treeshop/09-buckets-pro-functional-roadmap.md` — functional product sequence.
5. `docs/treeshop/10-jobber-tree-industry-spec.md` — Jobber and tree-industry integration contract.
6. `docs/COMMUNICATIONS.md` — current cross-agent handoffs and decisions.

## Agent roles

- **Codex / management side:** clarify the operating model, review architecture, turn observations into bounded product work, inspect diffs, and protect the system from scope drift.
- **Claude Code / customer implementation side:** work on the assigned company Mac, inspect the live customer workflow with authorization, implement approved changes, run tests, and return a reviewable branch/diff.
- **UTC / TreeShop / Buckets owner:** Mr. J. Anderson is the sole owner of UTC, TreeShop, and Buckets, and is the product owner, operator, and final authority for the product and TreeShop service.
- **Sacred Tree Service client owner:** Alexander Satoski owns and manages Sacred Tree Service. Sacred Tree Service hired TreeShop and Mr. Anderson to improve operations, install Buckets, and scale the Sacred Tree Service brand.

The roles are complementary. Neither agent silently assumes authority to send customer communications, change billing, publish a website, alter live Jobber records, or expose customer data. Sacred Tree's owner retains authority over Sacred Tree's customer-facing decisions and live business records; Mr. Anderson retains authority over UTC, TreeShop, and Buckets.

## Working rules

- Keep `main` releasable. Use a focused feature branch for implementation.
- Read the relevant spec before changing models or workflows.
- Prefer small, reversible changes with tests and a clear acceptance condition.
- For Jobber, begin read-only. Any write must be explicitly approved, idempotent, checked for `userErrors`, and read back.
- Treat Jobber's account, client, property, job, and visit IDs as external identities. Never match customer records by name alone.
- Use ANSI/ISA references and edition metadata in the catalog; do not copy licensed standards text into the repository.
- Never commit passwords, passkeys, recovery codes, API tokens, OAuth refresh tokens, customer exports, raw SwiftData stores, or populated access registers.
- Keep raw customer data in the controlled customer workspace. Use redacted fixtures for tests and examples.
- Run the smallest relevant test set, then the full test suite before merging a model or pricing change.
- Update the applicable decision/spec document when implementation changes the operating contract.
- Read and append to `docs/COMMUNICATIONS.md` at every agent handoff.

## Handoff format

Every implementation handoff should state:

1. what changed;
2. why it changed;
3. files and data-model impact;
4. tests run and results;
5. known limitations or unresolved decisions;
6. the next safe action.
