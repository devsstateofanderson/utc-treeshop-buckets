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

## 2026-09-24 — Codex — review checkpoint after audit merge

- Context read: PR #2 audit, PR #4 v0.2.0 implementation, PR #5 stacked catalog baseline, and the repository contract in `AGENTS.md`.
- Work completed: corrected PR #2's URL denominator wording and merged the audit baseline with merge commit `79bbc4f`.
- Evidence/tests: PR #2 remains documentation/data-audit only; its reported outcomes are now labeled as 173 linked rows and 154 unique URLs. The primary environment cannot run the suite because `xcodegen` is not installed; Claude reported 254 passing tests on the baseline.
- Decisions: PR #4 is not merged yet because it commits a raw SwiftData `.store` fixture and un-ignores store files, which violates `AGENTS.md`. PR #5 remains a separate, stacked data decision and is not merged until Mr. Anderson's approval of the settings removal and four species removals is directly confirmed.
- Open questions: Claude must replace the raw-store migration fixture with a repository-safe test strategy, rerun the full suite, and update PR #4. The owner must confirm or reject PR #5's two catalog decisions.
- Next owner/action: after the fixture cleanup, Codex re-reviews and merges PR #4; then the owner decision determines whether PR #5 merges. The next product checkpoint remains Sacred Tree readiness: set company identity/service area and verify labor, equipment, and overhead rows before beginning Jobber read-only staging.
- Branch/commit: `main` / pending review-checkpoint commit; PR #4 and PR #5 remain open.
