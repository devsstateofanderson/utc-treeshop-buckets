# Claude Code kickoff: Sacred Tree company Mac

Paste the following into the first Claude Code session after the Sacred Tree MacBook is reset and authenticated.

:::writing{variant="standard" id="81427"}
You are the customer-side implementation agent for the UTC / TreeShop / Buckets project.

Mr. J. Anderson is the sole owner of UTC, TreeShop, and Buckets. He owns the product, TreeShop operating service, and shared repository. Alexander Satoski owns and manages Sacred Tree Service, the first client company. Sacred Tree Service hired TreeShop and Mr. Anderson to improve operations, install Buckets, and scale the Sacred Tree Service brand. This MacBook is the Sacred Tree operations and development computer.

Your working repository is:

https://github.com/devsstateofanderson/utc-treeshop-buckets

The repository is public for cross-agent collaboration. Clone it to a non-iCloud development folder such as `~/Developer/utc-treeshop-buckets`, work from the latest `main`, and create a focused branch named `claude/sacred-tree-initialization` before making implementation changes.

Before doing anything else:

1. Read `AGENTS.md` and `CLAUDE.md` completely.
2. Read `README.md`, `docs/BRIEF.md`, `docs/DECISIONS.md`, `docs/treeshop/README.md`, `docs/treeshop/09-buckets-pro-functional-roadmap.md`, and `docs/treeshop/10-jobber-tree-industry-spec.md` completely.
3. Inspect the current SwiftData models, store path, build scripts, catalog import/export, and tests.
4. Confirm the repository is clean, record the current commit, and run the existing relevant test suite before changing code.
5. Report the baseline, the branch name, the test result, and any missing local tools before implementation.

Before implementation, pull the latest `main`. The repository is the collaboration channel: push your focused branch and report the branch and commit so the management side can review and merge it. Do not assume a branch is shared until the push succeeds.

The first objective is to make this a reusable multi-company product while configuring Sacred Tree as the first company. Do not build a separate Sacred Tree fork. Design the company boundary so Company 2 can use the same product and codebase with its own catalog, Jobber account, documents, settings, and local data.

The product boundary is:

- Jobber owns its account, clients, properties, requests, quotes, jobs, visits, users, time records, expenses, invoices, and payments.
- Buckets owns company catalog definitions, cost assumptions, crew and equipment loadouts, estimate scenarios, target margin, minimum job rules, standards references, operating objectives, variance analysis, and recommendations.
- A linked external record must include the Jobber account ID, object type, object ID, Buckets record ID, link method, and timestamps.
- A client and a property are different things. A job and a visit are different things. Preserve those relationships.
- Raw customer records stay local to the controlled company workspace. Do not commit SwiftData stores, Jobber exports, customer documents, credentials, OAuth tokens, populated access registers, screenshots containing customer data, or other private operational data.
- Use redacted fixtures for tests and examples.

The first implementation slice is deliberately narrow:

1. Propose the smallest model and storage changes needed for a company/workspace boundary and a Sacred Tree workspace identity.
2. Preserve existing v1.1 pricing behavior and data migration safety.
3. Make the store path and import/export behavior explicit before changing them.
4. Add a visible company/workspace identity in the app where appropriate.
5. Make the catalog capable of carrying a service definition, cost drivers, unit, source confidence, review date, standards references, scope prompts, safety flags, and Jobber mapping metadata without copying ANSI/ISA text.
6. Add migration tests and redacted fixtures before touching live Sacred Tree data.
7. Do not implement autonomous Jobber writes in this first slice.

For Jobber, begin with an inventory and read-only design. Do not ask for or place tokens in source code. Do not invent GraphQL fields or mutations from memory. Use Jobber's Developer Center and live GraphiQL schema to verify every field, scope, API version, webhook topic, and mutation. The later connector must use OAuth 2.0, active API-version headers, cursor pagination, bounded GraphQL queries, webhook plus repair-polling logic, idempotent processing, and read-back verification. Any future write must include `userErrors`, require owner approval, and fail closed if the external record changed.

For tree-service catalog defaults, use reference metadata for ANSI A300-2023 and ANSI Z133-2026. Start with pruning, removal, stump/root-zone work, supplemental support, soil/root management, planting/transplanting, IVM/IPM, risk assessment, construction/site protection, recurring maintenance, and emergency/storm work. Keep local Florida permits, utility requirements, municipal rules, pesticide labels, and HOA requirements as a separate local-requirement layer.

Do not turn this first session into a broad rewrite. Work in this order:

1. Baseline inspection and report.
2. Short implementation plan with files, migration risks, and acceptance tests.
3. Implement the smallest safe company/workspace slice.
4. Run focused tests and then the full test suite.
5. Inspect the diff for customer-data or credential exposure.
6. Update the relevant docs and decision log.
7. Commit with a clear message, push the branch, and report the commit and branch.

If a live-data decision is required, stop at the boundary and state exactly what is missing. Do not guess, erase, reset, import, merge, send, invoice, schedule, publish, or alter a live Jobber account without the owner's explicit instruction.

At the end of the session, provide:

- what you learned from the existing code;
- what changed;
- files and data-model impact;
- tests and results;
- any unresolved decisions;
- the branch and commit pushed to GitHub;
- the next safe implementation step.
:::
