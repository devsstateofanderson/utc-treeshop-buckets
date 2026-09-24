# UTC / TreeShop / Buckets communications log

This append-only log is the shared coordination surface for Mr. J. Anderson, Claude Code, and Codex. It records what each side learned, changed, decided, and left for the next side.

## Operating rule

Every agent checks these items before work:

1. `git fetch origin` and the current branch status.
2. The latest `main` commit and changed files.
3. The latest entries in this log.
4. `AGENTS.md`, `CLAUDE.md`, and the relevant product or operating specification.

Every agent appends an entry when its work reaches a handoff point. Never rewrite another agent's entry. If a correction is needed, append a correction that links to the earlier entry.

## Roles

- **Mr. J. Anderson:** sole owner of UTC, TreeShop, and Buckets; final product, service, and merge authority.
- **Claude Code:** customer-side implementation agent on the Sacred Tree Mac; performs the detailed build work, runs tests, and pushes focused branches.
- **Codex / ChatGPT:** management, architecture, review, merge, GitHub administration, and cross-agent coordination from the primary development computer.
- **Alexander Satoski:** owner and manager of Sacred Tree Service, the first client company; approves consequential Sacred Tree customer and business decisions.

The agents collaborate through GitHub. Claude proposes and implements. Codex reviews and merges. Mr. Anderson resolves product and ownership decisions. A live customer action still needs the applicable human owner's approval.

## Entry format

Append entries using this structure:

```markdown
## YYYY-MM-DD — Agent — short subject

- Context read:
- Work completed:
- Evidence/tests:
- Decisions:
- Open questions:
- Next owner/action:
- Branch/commit:
```

## 2026-09-24 — Codex — collaboration protocol

- Context read: Claude's first Sacred Tree handoff, current repository workflow, and current GitHub state.
- Work completed: clarified UTC / TreeShop / Buckets ownership, made the public repository history free of reachable customer backup files, documented the shared update command, and established `main` as the review baseline.
- Evidence/tests: repository `main` is pushed at commit `908bd64`; no `Backups/` paths are reachable from `main`; local customer backup files remain outside Git tracking.
- Decisions: use the simplest GitHub authentication already available on each computer. The communications log is the shared coordination mechanism. Claude implements and pushes; Codex reviews, merges, and manages GitHub.
- Open questions: confirm the existing GitHub push path on the Sacred Tree Mac when Claude begins.
- Next owner/action: Claude checks the latest `main`, reads this log, and continues from the current repository state.
- Branch/commit: `main` / `908bd64`.

## 2026-09-24 — Claude Code — baseline on rewritten main, default-catalog audit, push path

- Context read: `main` at `7bba80c` and the eight commits since `6401626`; the Codex entry above; `AGENTS.md`, `CLAUDE.md`, `docs/REPOSITORY-WORKFLOW.md`, `docs/BRIEF.md`, `docs/DECISIONS.md` (71), `docs/treeshop/11-sacred-tree-claude-kickoff.md`; `Sources/Models/Store.swift`, `Sources/Models/Company.swift`, `Scripts/catalog/build_catalog.py` and the catalog data.
- Work completed: fresh checkout at `~/Developer/utc-treeshop-buckets` per DECISIONS 71 (not `~/Desktop`; the old `~/Desktop/Buckets` checkout and running `Buckets.app` were left untouched). The pre-rewrite local branch was saved as a patch in the local vault; its only commit (untracking `Backups/`) is superseded by `77b3a60`. Baseline inspection done. Audited the product default catalog: `docs/catalog-audit-2026-09-24.md` (review) and `Scripts/catalog/data/audit-2026-09-24.json` (per-row verdicts a later branch can apply). No catalog data was changed.
- Evidence/tests: `Scripts/test.sh` on `7bba80c`: 254 executed, 3 skipped, 0 failures. Link check of 154 unique catalog URLs with curl (browser UA, redirects followed): 86 × 200, 86 × 403, 1 × 404. All 80 Home Depot links return 403 to curl and an automated browser alike, so they are unverifiable by automation from this Mac. Confirmed dead: Walmart STIHL MotoMix (404). Species review: 4 remove (Weeping Willow, Majesty Palm, both Windmill Palm rows), 8 review, 3 caution, 33 keep; 36 of 48 plant rows are homeowner container sizes; 17 rows cite price guides or category pages instead of product pages.
- Decisions: none taken. Six owner decisions are listed in the audit §6, the two that gate Monday's pricing data being (a) whether the default catalog should ship `settings` at all (today it carries markup 35 %, burden 30 %, minimum $750, 1,500 billable hours, which look like one company's numbers) and (b) whether to apply the `remove` verdicts.
- Open questions: (1) **Push path is not confirmed.** The GitHub identity on this Mac is `sacredtreeservice`, which has `pull` only on this repository (`push: false`, no pending invitation). Direct push returns 403 and forking is not an option Claude will take unilaterally. A Write collaborator grant for `sacredtreeservice` is the smallest fix. (2) `Company` is a singleton (`Company.current(in:)` fetches `.first`) and `BucketItem`, `Project`, `Subcontractor`, `Loadout` carry no company identity, so the multi-company objective is a SwiftData migration, not a field. (3) Sacred Tree's live store (`~/Library/Application Support/Buckets`) was last written 2026-09-17 11:42 with ~0.9 MB in the WAL, newer than any backup, and the app is running; an export through the app is needed before any schema change touches it.
- Next owner/action: Codex / Mr. Anderson — grant push, review the audit, answer §6 (a) and (b). Claude — the moment push works, push this branch for review; then, whichever is approved first: apply the approved catalog verdicts (data-only, low risk) or add `sourceConfidence` / `suitabilityNote` catalog metadata (kickoff step 7; model change, own branch, migration test).
- Branch/commit: `claude/sacred-tree-initialization`, local only until push access is granted; commit hash reported in the next entry.

## 2026-09-24 — Codex — v0.2.0 implementation handoff

- Context read: PR #2 audit, the Buckets Pro functional roadmap, current SwiftData models, and the live GitHub branch state.
- Work completed: opened GitHub issue #3 for the first functional Pro slice and handed it to Claude for implementation on the Sacred Tree MacBook.
- Scope: catalog trust metadata and review filters; company setup/readiness counts; non-blocking unresolved-input warnings on estimates; export/import compatibility; version `0.2.0`; backup, package, install, launch, and smoke-test on the customer Mac.
- Decisions: this release is deliberately before Jobber OAuth or any live Jobber mutation. No automatic catalog removals/merges, scenarios, scorecards, or AI actions in this slice.
- Open questions: Claude must report the live-store export/backup path and any migration limitation before replacement; the owner remains the approval authority for customer data and live operations.
- Next owner/action: Claude pulls latest `main`, preserves customer data outside Git, implements issue #3 on a focused branch, runs the full suite, installs the release build, and opens a PR. Codex reviews and merges.
- Branch/commit: `main` / pending documentation handoff commit; issue [#3](https://github.com/devsstateofanderson/utc-treeshop-buckets/issues/3).

## 2026-09-24 — Claude Code — v0.2.0 implemented, installed and running on the Sacred Tree Mac

- Context read: issue #3; the Codex v0.2.0 handoff entry above; `AGENTS.md`, `CLAUDE.md`, `docs/REPOSITORY-WORKFLOW.md`, `docs/BRIEF.md`, `docs/DECISIONS.md`, `docs/treeshop/09-buckets-pro-functional-roadmap.md`; every model, view and test the slice touches.
- Work completed: issue #3 in full on branch `claude/v0.2.0-catalog-trust`. (1) Seven review fields on `BucketItem` with `Confidence` (missing · estimated · owner confirmed · verified), one-group-per-row unresolved precedence, and the rule that verified needs evidence plus a checked date (DECISIONS 72). (2) Setup & readiness section at the top of the Company screen, with `Company.serviceArea`, catalog completion per bucket, the four unresolved counts with Show buttons, and a status that is never Ready while a setup input is unresolved (DECISIONS 73). (3) Review section on the row Form, a Review column and Show filter on the Buckets table, and a Review sheet on subcontractor services. (4) Non-blocking warnings on the Project screen: a per-line caption and a header count; pricing untouched. (5) Transfer format 2 reading formats 1–2, merge carrying review fields without vouching for a row (DECISIONS 74). (6) Version 0.2.0 build 2 (DECISIONS 75), `Dist/Buckets-0.2.0.dmg`, installed and launched here. `Scripts/test.sh` also gained `mkdir -p build` (it failed to `tee` on a fresh checkout). Rebased onto `main` `5c6665f` after PR #2 merged.
- Evidence/tests: `Scripts/test.sh` — 271 executed, 3 skipped (the same three as before), 0 failures; 17 new tests in `CatalogReviewTests`, `ReadinessTests`, `TransferFormat2Tests`, `StoreMigrationTests`. The migration test declares the v1.1 models as a test-only `VersionedSchema`, writes the §3.3 rows and two projects with it, then opens the file with the app's schema and checks every row, project and price — no store file in the repository (Codex's review finding on PR #4, fixed). Live customer store: raw backup of all three store files to the local vault (`~/Developer/sacred-tree-local-vault/live-store-2026-09-24-pre-0.2.0/`, sha256 recorded), format-1 export written by the v1.1 app, then the first 0.2.0 launch migrated the store and wrote a format-2 export; the two exports are identical in every row (197), project (2), line snapshot, toggle, quantity, margin, subcontractor (2), loadout (1) and setting, and no review key appears yet. Offscreen renders of the live Company and Labor screens are in the vault (not the repository); fixture-data screenshots are in `docs/screenshots/v0.2.0/`.
- Decisions: DECISIONS 72–75 as above. Two calls worth Codex's eye: the unresolved-group precedence (missing → owner confirmation → overdue → estimated) so counts add up, and treating a v1.1 store's rows as `missing` rather than inventing a confidence for them — the live store now reports 197 Missing, which is honest.
- Open questions: (a) `Company name` and `Service area` are unset on the live store, so readiness reads Not ready until Alexander (or Mr. Anderson) fills them in — a two-field task on the Company screen. (b) 197 rows sit in Missing; the review workflow is the Monday pricing-data path (filter → evidence → Today → Verified). (c) The Review column can fall off the right edge of the Buckets table at the default window width; columns are resizable, but a narrower default for Rate would help. (d) The audit's `remove` verdicts remain unapplied by design (out of scope for this slice).
- Next owner/action: Codex — review and merge PR (branch `claude/v0.2.0-catalog-trust`). Then, in order: set company name and service area on the live store; start verifying Sacred Tree's labor, equipment and overhead rows (the three buckets that gate readiness) ahead of Monday; decide the audit §6 questions so the default catalog cleanup can be its own data-only branch.
- Branch/commit: `claude/v0.2.0-catalog-trust`; the commit hash is on the PR. App installed at `/Applications/Buckets.app` (0.2.0, build 2); v1.1 parked at `~/Developer/sacred-tree-local-vault/Buckets-1.1.app`.

## 2026-09-24 — Codex — review checkpoint after audit merge

- Context read: PR #2 audit, PR #4 v0.2.0 implementation, PR #5 stacked catalog baseline, and the repository contract in `AGENTS.md`.
- Work completed: corrected PR #2's URL denominator wording and merged the audit baseline with merge commit `79bbc4f`.
- Evidence/tests: PR #2 remains documentation/data-audit only; its reported outcomes are now labeled as 173 linked rows and 154 unique URLs. The primary environment cannot run the suite because `xcodegen` is not installed; Claude reported 254 passing tests on the baseline.
- Decisions: PR #4 is not merged yet because it commits a raw SwiftData `.store` fixture and un-ignores store files, which violates `AGENTS.md`. PR #5 remains a separate, stacked data decision and is not merged until Mr. Anderson's approval of the settings removal and four species removals is directly confirmed.
- Open questions: Claude must replace the raw-store migration fixture with a repository-safe test strategy, rerun the full suite, and update PR #4. The owner must confirm or reject PR #5's two catalog decisions.
- Next owner/action: after the fixture cleanup, Codex re-reviews and merges PR #4; then the owner decision determines whether PR #5 merges. The next product checkpoint remains Sacred Tree readiness: set company identity/service area and verify labor, equipment, and overhead rows before beginning Jobber read-only staging.
- Branch/commit: `main` / pending review-checkpoint commit; PR #4 and PR #5 remain open.

## 2026-09-24 — Claude Code — default catalog baseline: settings stripped, audit removes applied

- Context read: audit §6 (a) and (b); Mr. Anderson's approval of both in chat; `Scripts/catalog/build_catalog.py` and the `rows-*.json` sources it builds from; `Transfer.swift`.
- Work completed: branch `claude/default-catalog-baseline`, stacked on `claude/v0.2.0-catalog-trust`. (a) The default and starter catalogs carry no `settings`; `build_catalog.py` no longer emits them; `TransferDocument.settings` is optional and Import keeps the company's settings when a file has none (DECISIONS 76). (b) Weeping Willow, Majesty Palm and both Windmill Palm rows removed from the default and starter catalogs and from `rows-all.json` / `rows-homedepot.json`; research notes and the audit JSON kept as the record (DECISIONS 77). Files rewritten in their original JSON style so the diff is only the removed rows and the settings blocks. README updated (112 materials, 57 consumables, 19 overhead).
- Evidence/tests: `Scripts/test.sh` — 274 executed, 3 skipped, 0 failures. New `DefaultCatalogTests` pins the catalog as neutral (no settings, no removed rows, bucket counts, $0 overhead, merges 188 rows into an empty store, import keeps settings); `TransferFormat2Tests` gains a settings-absent import test.
- Decisions: DECISIONS 76–77. `review` and `caution` rows from the audit (River Birch, Ligustrum, citrus, Foxtail, Tabebuia, Loquat starter) are untouched pending the owner.
- Open questions: none for this slice. The live Sacred Tree store already merged the old default on 09-16; a merge never deletes, so those four rows, if present there, stay until archived by hand — the readiness Show filter will surface them as Missing like every other row.
- Next owner/action: Codex — merge in order #2 → #4 → #5 (each stacks on the previous), delete branches, pull main. Then the next issue.
- Branch/commit: `claude/default-catalog-baseline`; hash on the PR.

## 2026-09-24 — Claude Code — service area as a radius; company profile by merge; live store now has its identity

- Context read: Mr. Anderson's direction in chat (service area = mileage radius around the company address, also the horticultural zone; company name is the company name; he enters labor and equipment himself at replacement cost, no AI seeding); the readiness inputs on the live store; the merge and launch-hook code.
- Work completed: branch `claude/company-service-area`, stacked on #5. `Company` gains `serviceRadiusMiles` and `growingZone` beside the `serviceArea` description; the Company screen edits all three; readiness resolves Service area by description or radius and shows "Apopka and Central Florida · 30-mile radius · USDA 9b". Add or Update Rows (and so `BUCKETS_MERGE_FILE`) applies a `company` record when a file has one — non-nil fields only, a blank name never blanks, documents untouched — because nothing scriptable could set the two identity inputs a customer Mac needs first (DECISIONS 78). Version 0.2.1, build 3. No data seeding beyond identity, per the owner.
- Evidence/tests: `Scripts/test.sh` — 276 executed, 3 skipped, 0 failures (+2: readiness by radius; merge applies the profile without blanking). Customer Mac: 0.2.0 quit, store backed up to the vault, 0.2.1 installed at `/Applications/Buckets.app`, launched once with `BUCKETS_MERGE_FILE` carrying only the profile, export written: company name "Sacred Tree Service LLC", owner, service area, 30-mile radius, USDA 9b; 197 rows, both projects, 2 subs, 1 loadout and every setting identical to the 0.2.0 export. Offscreen render of the live Company screen in the vault. 0.2.1 is running.
- Decisions: DECISIONS 78. The 30-mile radius is a placeholder the owner can change on the Company screen; the street address is still blank (not known to me), so "around the address" has nothing to anchor to until it is typed in.
- Open questions: none new. Readiness on the live store now reads **Needs review** (all identity inputs resolved; 197 rows Missing) — the honest state until labor, equipment and overhead rows are entered and verified.
- Next owner/action: Codex — merge #4 → #5 → #6 in order. Owner — street address on the Company screen; then labor and equipment rows at replacement cost, marked owner confirmed, using the Show filter. Product — the next slice should make that entry faster (the roadmap's §3 catalog review tools: bulk archive, unit codes, owned/rented/subbed).
- Branch/commit: `claude/company-service-area`; hash on the PR. Installed build is this commit.
