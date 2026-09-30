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
- Addendum (same evening, Mr. Anderson: "the system has to handle itself so we can remotely operate other companies"): **onboarding is now a file and a script** (DECISIONS 79). `Scripts/onboard.sh <profile.json> [catalog.json …]` quits the app, backs up the store, applies the profile and catalogs through the merge hook, exports, prints the readiness picture, relaunches; `Scripts/catalog/data/company-profile-template.json` is the profile to copy. Proven on the baseline: Sacred Tree's public identity applied through it — 5844 Round Lake Rd, Apopka, FL 32712 (public listing; the address is shared with Green's Nursery), (321) 204-8459, sacredtreeservice@gmail.com, sacredtreeservice.com, and the 50-mile radius over seven counties the website itself states. `Scripts/catalog/data/archive-2026-09-24-removed-species.json` archives the four audit-removed rows in any store that merged the old default; applied here (materials 116 → 112 active). Live readiness: Needs review, 8 of 8 setup inputs resolved, 193 active rows unresolved — labor 1, equipment 1, overhead 19 are the ones that gate pricing and are the owner's to enter at replacement cost.
- Branch/commit: `claude/company-service-area`; hashes on the PR. Installed build is the first commit (0.2.1); the second commit is scripts and docs only.

## 2026-09-24 — Claude Code — merged #4, #5, #6 on the owner's instruction

- Context read: Mr. Anderson in chat ("I gave you push ability so you can self-manage the repo too"), then his explicit answer to a direct question: merge now, he approves. `AGENTS.md` (Codex reviews and merges; Mr. Anderson approves product merges); Codex's review checkpoint above; no Codex activity on #4 since the fixture fix was pushed.
- Work completed: merged in order with merge commits and deleted the branches — #4 (v0.2.0: catalog trust metadata, readiness, review workflow, estimate warnings; fixture finding fixed with a test-only `VersionedSchema`), #5 (default catalog: no company settings, four species removed; DECISIONS 76–77 — the owner's two decisions, approved by him in chat), #6 (service area radius and growing zone, company profile by merge, onboarding script; DECISIONS 78–79). `main` is byte-identical to the stacked tree the suite ran on.
- Evidence/tests: 276 executed, 3 skipped, 0 failures on that tree. No `.store` tracked on `main`. Customer Mac runs 0.2.1 (build 3) with its identity set and the four species archived; readiness Needs review, 8/8 setup inputs, 193 rows unresolved.
- Decisions: the owner exercised his merge authority directly rather than through Codex for this batch; the contract's normal loop (Claude implements → Codex reviews → merge) resumes from here. Codex's two open asks are answered: the raw-store fixture is gone (#4 rev 2) and the owner's #5 decisions are recorded in this log and in DECISIONS 76–77.
- Open questions: none on the repository. Product: the owner's next priorities are faster labor/equipment entry (roadmap §3), a readiness report a remote operator can read without the app, and website/marketing managed through Buckets.
- Next owner/action: Codex — review `main` (post-merge), then write the next issue and a comms entry. Owner — labor and equipment rows at replacement cost, marked owner confirmed. Claude — the overnight shift on whatever the next issue says.
- Branch/commit: `main`, this commit.

## 2026-09-28 — Claude Code — OpenLoadout Baseline 0.1: catalog corrections, privacy guard, standard in the repository

- Context read: `AGENTS.md`, `CLAUDE.md`, `docs/REPOSITORY-WORKFLOW.md`, `docs/BRIEF.md`, `docs/DECISIONS.md` (to 79; 80–86 are reserved by the unmerged `claude/equipment-classes-plan`), the entries above; the OpenLoadout Tree Service Baseline 0.1 standard and its corrections register (now `docs/openloadout/`), the saw-line research and its adversarial check (the two overturned claims were not used); `Scripts/catalog/build_catalog.py`, `Transfer.mergeItems`, every catalog data file.
- Work completed: branch `claude/operating-standard-baseline-1` from `origin/main` `b4582d0`, three commits. (1) The redaction that was sitting uncommitted in the working tree: the starter catalog, `rows-all.json` and `rows-pnl-2025.json` no longer carry the three VINs or the auto-policy number. (2) Catalog corrections from FINDINGS section 1. Default catalog: chain, bar and sprocket rows now match the Baseline saw cards, one row per exact spec (33 RS 66 / 72 / 84, 63 PS3 44 / 55, Milwaukee 49-16-2723 / 2759; STIHL 18, 20 and 25 in bars for the MS 500i and 12 and 16 in for the climbing saws; rim sprocket 0000 642 1223, spur sprockets 1145 640 2010 and 1137 640 2005), each chain named by pitch, gauge and drive links; the 72LPX reel renamed as standard 3/8 in; files priced per dozen ($31.99 pack); two 2-in-1 file guides at $54.99; FORGE batteries; saw wear parts recategorised "Saw wear parts (priced on saw rows)"; pump gas and diesel removed; MotoMix flagged for re-verification; PPE costing and imidacloprid Chapter 482 gate notes; three Cherry Lake rows re-cited to Cherrylake's public prices and the rest flagged for a quote; 13 removed-species rows removed; "Computers & devices" and "Shop & fleet maintenance supplies" at $0. The same corrections in `sts-arborist-additions.json`, `rows-arborist-supply.json`, `rows-all.json`, `rows-equipment-consumables.json`, `rows-siteone-cherrylake.json` and `rows-homedepot.json` (each rewritten in its own JSON style; the dated `research-*` and `audit-*` files untouched). Company edition: the same row corrections plus MS 201 T C-M at $949.99, the MS 193 T row honorarily upgraded to an MS 194 T at $509.99 (renamed "Stihl 194T (MS 193 T unit, honorary upgrade)", the physical-saw note kept), the Toro Dingo TX 525 diesel at $32,976.00 with diesel fuel ($6.33/h), and the 3016-21PS reach corrected to 7–10 ft; rates recomputed with `equipment_rate_cents` (201 T 367 → 361, 194 T honorary 268 → 287, Toro 1165 → 1436 cents/h). New `archive-2026-09-28-baseline-0.1.json` (27 old default names, archived) and `corrections-2026-09-28.json` (239 entries: ID, file, old and new name, field changes, evidence URL, date seen). (3) `docs/openloadout/` (STANDARD, README, CONTRIBUTING, CHANGELOG verbatim; FINDINGS without its two internal sections), DECISIONS 87–88, README counts, this entry.
- Evidence/tests: `Scripts/test.sh` — 281 executed, 3 skipped (the same three), 0 failures; +5 tests: `DefaultCatalogTests` pins the new counts (materials 99, consumables 63, overhead 21; 183 rows merge into an empty store), the saw cards and prices, the archive (every old name absent from the default, all inactive, a merge archives a matching row and nothing else) and the company edition's fleet rates against `EquipmentCalc`; `PrivacyGuardTests` scans every UTF-8 file under `Scripts/catalog/data` and `docs` for VIN-, EIN- and policy-number-shaped tokens and checks the patterns on synthetic values (run against `main`'s versions of the three redacted files it finds the VINs and the policy number in each). The env-gated `StarterCatalogTests` fails its "updated == 1" count on the starter file both on `main` and on this branch (the starter already names the test's "Porta Wrap 15'" row); not a regression, not fixed here.
- Decisions: DECISIONS 87 (Baseline 0.1 is the reference for catalog content; default corrected; archive file for merged stores) and 88 (privacy guard). Calls worth review: the 20 in bar 3003 008 8921 (F-CAT-02) keeps its matching 33 RS 72 loop, so the default carries seven chain loops, not the six on the saw cards; the MS 194 T spur sprocket is a $0 row marked price unverified rather than an invented price; the 5 gal bar-oil pail keeps its old figure, marked unverified; the company edition's own royal palm row and the Toro's salvage value are unchanged.
- Open questions: (a) **Repository visibility.** This branch is committed locally and NOT pushed, pending the owner's decision on repository visibility: `main` and its history still hold the numbers the first commit redacts, so the redaction does not remove them from the public history. (b) The starter still carries two personal names in a subcontractor row (they predate this branch). (c) F-CAT-14 (saddle straps), F-LIST-05 (climbing and rigging gear as track-only equipment, which needs plan slice 2) and the lone felling wedge left in "Chains & bars" were not changed. (d) The Baseline's own open questions (Q-OWNED, Q-PHC, Q-GAUGE, Q-POLESAW, Q-WINDMILL, Q-DINGO) stand.
- Next owner/action: owner — decide repository visibility and the history clean-up before anything is pushed. Codex — review the three commits once they are pushed. Customer Mac — after merge, merge `archive-2026-09-28-baseline-0.1.json` and the corrected default into the live store through `Scripts/onboard.sh`.
- Branch/commit: `claude/operating-standard-baseline-1`, local only: `784e25e` (redaction), `dcdd1db` (catalog corrections, archive, audit trail, tests), and this commit (docs).

## 2026-09-28 — Claude Code — OpenLoadout Baseline 0.1: review fixes

- Context read: the review of the three commits above (verdict: issues found, none blocking, two medium); FINDINGS F-CAT-05, F-CAT-14, F-FLEET-02/03 and section 2; STANDARD §4.3 and §4.5 rule 3; DECISIONS 55, 67, 87–88.
- Work completed: (1) Medium: the subcontractor row named after two people is now "Grapple truck (sub)", source "Grapple-truck subcontractor", in the starter, `rows-all.json` and `rows-pnl-2025.json`; `sts-subcontractors-migration.json` names the subcontractor by role with a null contact and deactivates the renamed consumables row. The corrections file records these as PRIVACY entries without repeating the old values. (2) Medium: the real "Stihl 194T" row is repriced to the $509.99 STIHL USA list (stihlusa.com, seen 2026-09-28; Baseline 0.1 §4.5 rule 3), rate 285 → 287 by `equipment_rate_cents`, so both MS 194 T rows agree; it keeps "archive if you don't own one" (F-FLEET-03). (3) The 5 gal bar-oil pail follows the spur sprocket's rule: $0, source "(quote needed)", with the last figure named in the note. (4) New `archive-2026-09-28-baseline-0.1-starter.json` archives the company edition's seven renamed rows under their 09-16 names. (5) The 12 appended notes (and their mirrors and corrections entries) have their sentence break. (6) DECISIONS 87 basis now reads F-CAT-01…13 and 15…19 (14 pending re-verification) and states the unverified-price rule and the starter archive; DECISIONS 88 separates the rule (every identifier, every tracked file) from what `PrivacyGuardTests` enforces (three patterns, two folders). README names the starter archive.
- Evidence/tests: `Scripts/test.sh` — 282 executed, 3 skipped (the same three), 0 failures; +1 test (starter archive), and `DefaultCatalogTests` now also pins the pail at $0 with a quote needed and the second MS 194 T row through the calculator. No personal name, VIN, EIN or policy number in the working tree.
- Decisions: DECISIONS 87 and 88 amended as above; no new number. The renamed grapple-truck row is deliberately not archived, because the archive would have to carry the old name.
- Open questions: (a) repository visibility, unchanged: `main`'s history still holds the redacted VINs, the policy number and now the two names. (b) The live store was reset to the default edition on 09-16 (DECISIONS 67), so the starter archive matters only for a store that later merged the company edition; if one did, rename its grapple-truck row by hand.
- Next owner/action: owner — repository visibility and history clean-up before anything is pushed. Codex — review the five commits once pushed.
- Branch/commit: `claude/operating-standard-baseline-1`, committed locally and NOT pushed: `55024da` (review fixes) and this commit (log).

## 2026-09-28 — Claude Code — OpenLoadout Baseline 0.1: second review fixes

- Context read: the second review of the five commits above (verdict: issues found, none high; all mandatory checks pass; six low); the saw-line research and its adversarial check (49-16-2759 upheld as a 10 in chain, bar 49-16-2760); STANDARD §4.0 and §10.3; FINDINGS F-CAT-12 and F-CAT-16; DECISIONS 87–88.
- Work completed: `697221d`. (1) The 49-16-2759 pole-saw chain row is named for the 3013-21's 10 in bar in the default, starter, `rows-all.json`, `rows-equipment-consumables.json` and the corrections file; the note cites Milwaukee's product page (seen 2026-09-28) and says 9 in is the kit's cut capacity. (2) The honorary MS 194 T row takes the real row's $50 salvage, so the two rows have identical inputs (rate stays 287). (3) The company edition's royal palm row, and `rows-own.json`, carry a note that Baseline 0.1 §10.3 removes it and keeping it is the owner's call. (4) DECISIONS 87 names the equal inputs; 88 says a store that merged the 09-16 company edition renames its grapple-truck row by hand before merging `sts-subcontractors-migration.json`. (5) The repository FINDINGS intro no longer claims to carry the internal sections. (6) `PrivacyGuardTests` uses a 555 number. Correction to the first 09-28 entry: `corrections-2026-09-28.json` had 246 entries after the first fix round and has 248 now (two F-CAT-16 royal palm notes).
- Evidence/tests: `Scripts/test.sh` — 282 executed, 3 skipped (the same three), 0 failures; `DefaultCatalogTests` now also pins equal MS 194 T inputs, the royal palm row's §10.3 note and the 2759 row's 10 in bar.
- Decisions: no new number; DECISIONS 87 and 88 amended as above. STANDARD.md stays verbatim: its §4.0 "9 in bar" for the 3013-21 is flagged here for the next FINDINGS revision.
- Open questions: (a) repository visibility, unchanged. (b) Royal palm in the company edition: keep or archive (owner).
- Next owner/action: owner — repository visibility and the royal palm call. Codex — review the seven commits once pushed.
- Branch/commit: `claude/operating-standard-baseline-1`, committed locally and NOT pushed: `697221d` (fixes) and this commit (log).

## 2026-09-29 — Claude Code — Baseline 0.1 and the Sacred Tree layer installed on the live store; branch pushed

- Context read: Mr. Anderson in chat on 09-29. The repository stays public ("it doesn't need to be private"), so the branch is pushed. He wants Buckets updated on this Mac, with the Sacred Tree data layer installed on top so the company can start getting value. Also read the live store as exported today, `Scripts/onboard.sh`, and DECISIONS 55 and 68 (merge matching).
- Work completed:
  - **Rehearsal first.** The whole install ran twice on copies of the live store (`BUCKETS_STORE`), and the exports were diffed.
  - **Two problems caught and fixed before the live run.** (1) The company edition would have overwritten the owner's own "Stihl 500i" row: $1,800, 1,500 h life, 1,500 h/yr, repair 0.8, $0.40/h fuel, 256¢/h, entered 09-27. (2) Its 2025 P&L overhead lines would have landed beside the default checklist lines under different names ("Office / shop rent" next to "Shop / office rent").
  - **The Sacred Tree layer as its own file.** Built as the company edition minus the owner's 500i row, with units #2 and #3 copying the owner's inputs. Nine P&L lines are renamed onto their checklist names (the old name is kept in notes), and the three "(sub)" consumables rows are dropped because the store already has its own Subcontractors rows. The file is `~/Developer/sacred-tree-local-vault/sacred-tree-layer-2026-09-29.json`: company data, in the vault, not in the repository.
  - **The live apply.** `Scripts/onboard.sh` ran with the vault profile, `Buckets-default-catalog.json`, `archive-2026-09-28-baseline-0.1.json` and the layer. `archive-2026-09-28-baseline-0.1-starter.json` was not applied, because this store never merged the old starter and it would only add seven inactive rows.
- Evidence/tests:
  - Backup: `~/Developer/sacred-tree-local-vault/onboard-2026-09-29-134534/`.
  - Merge counts matched the rehearsal: default added 22, updated 26, unchanged 135; archive updated 27; layer added 27, updated 16, unchanged 85.
  - Live export: labor 1 (the owner's row, unchanged), equipment 19 (the owner's 500i unchanged; 18 new rows), materials 100, consumables 68, subcontractors 3 (unchanged), overhead 24 lines with no duplicate names at $87,453.81/yr ($58.30 per billable hour at 1,500 h). Both projects, both subs, the loadout, the settings and the company profile are unchanged.
  - Readiness: NEEDS REVIEW, 215 active rows unresolved (honest: nothing is owner-confirmed yet). App 0.2.1 relaunched.
- Decisions: none new. For the repository's company edition (`Buckets-starter-catalog.json`): its overhead lines should carry the default checklist names, and its "(sub)" consumables rows conflict with the Subcontractors bucket (DECISIONS 60). Fix both in the repository before another company uses it as a template.
- Open questions:
  - (a) Crew labor rows: only the owner's row exists. Owner to enter the crew, each with wage, paid hours and burden.
  - (b) Hours basis on saws: the owner's 500i uses 1,500 h/yr and repair 0.8, while the other saws came in at BRIEF §2.2 defaults (300 h/yr, repair 2.50). Pick one basis and conform in one pass.
  - (c) Royal palm row: keep or archive.
- Next owner/action: owner — enter the crew, then review the equipment rows (Show → Needs review). Codex — review PR for `claude/operating-standard-baseline-1` (seven commits plus this log). Claude — conform the company edition's overhead names and sub rows on request.
- Branch/commit: `claude/operating-standard-baseline-1`, pushed; this commit (log).

## 2026-09-29 — Claude Code — merge files carry packages (0.2.2, build 4)

- Context read: Mr. Anderson's instruction (relayed through the workflow on 09-29): a company data-layer merge file should carry packages as well as rows, subcontractors and loadouts. Also read `AGENTS.md`, `CLAUDE.md`, `docs/REPOSITORY-WORKFLOW.md`, DECISIONS 17, 55, 61–63, 66, 74–79 and 87–88, `Transfer.mergeItems`, `Project.make` / `duplicate` / `asPackage`, and the `BUCKETS_MERGE_FILE` hook.
- Work completed: branch `claude/merge-packages`, stacked on `claude/operating-standard-baseline-1` (PR #8, unmerged).
  - `Transfer.mergeItems` merges the file's projects with `isTemplate: true` as packages, matched by name (case- and whitespace-insensitive) against packages only. A new name creates the package, with the file's date and client. An existing package has its lines and header fields (hours, notes, crew name, multiplier, minimum job, markup, target margin) replaced; its name, date and client are kept.
  - Package lines resolve through the same file-position-to-merged-row mapping as loadout members. They snapshot name, bucket, unit and rate from the merged row, with `isOn` and `qty` from the file. Lines that cannot be resolved are skipped and counted.
  - Ordinary projects in a merge file are still ignored.
  - `MergeResult` gains `packages`, `packagesUpdated` and `packageLinesSkipped`. The `BUCKETS_MERGE_FILE` stderr line and the Settings message report them.
  - **Fix.** A file row skipped as ambiguous (an uncoded name matching several coded units) was not appended to the merged list, so every later loadout member shifted by one. It now holds its position as nil.
  - Version 0.2.2, build 4 (`project.yml`). DECISIONS 89; README Settings line.
- Evidence/tests:
  - `Scripts/test.sh`: 285 executed, 3 skipped (the same three), 0 failures. Three new `TransferMergeTests` cases: two packages created with correct snapshots and `isOn`/`qty`, ordinary projects ignored, and a same-named ordinary project untouched; a re-merge updates rather than duplicates and deletes the replaced lines; a skipped coded-duplicate row shifts neither loadout members nor package lines. With the fix reverted, the last test fails 3 assertions.
  - `Scripts/build.sh Release` built `build/Buckets.app` (0.2.2, build 4, codesign verified).
  - Not installed; the live store was not touched.
- Decisions: DECISIONS 89. Package line snapshots come from the merged row, not from the file's line copy, so a package always prices from the catalog as merged.
- Open questions:
  - (a) A package's `nil` notes, crew or target margin in the file clears the store's value on update ("replace"). This differs from rows and the company profile, where nil leaves a field alone. Keep it, or switch to nil-leaves-alone?
  - (b) Two store packages with the same name: the first one found is updated.
- Next owner/action: caller rehearses 0.2.2 on a copy of the live store (`BUCKETS_STORE`), then installs it and merges the Sacred Tree packages file. Codex reviews `claude/merge-packages` after PR #8.
- Branch/commit: `claude/merge-packages`, pushed: `2348e08` (change) and this commit (log). No PR opened.

## 2026-09-29 — Claude Code — merge-packages review fixes (0.2.2, build 4)

- Context read: the review of `claude/merge-packages` (2348e08, 6705b01), relayed through the workflow on 09-29. The review found no blocking issues, five low ones and two open questions. `Transfer.mergeItems`, `Project.setPricing` / `make`, `SettingsScreen.chooseMerge`, the `BUCKETS_MERGE_FILE` hook and DECISIONS 66, 70 and 78 were read too.
- Work completed (branch `claude/merge-packages`, new commit, nothing rewritten):
  - **Open question (a) resolved: nil leaves the store's value alone.** On update, a package's notes, crew name and target margin change only where the file carries a value, as for rows, subcontractors, loadouts and the company profile. Hours, multiplier, markup and minimum job are required fields in the file and are always replaced.
  - **Pricing for a new package without a margin.** If a new package's file entry has no target margin, it is priced from the company defaults (`setPricing`, DECISIONS 70), not from the legacy markup rule. `mergeItems` takes `settings:`, which defaults to `AppSettings.current()`.
  - **Open question (b) resolved: an ambiguous name is skipped.** If a file package's name matches more than one store package, it is skipped whole, touching neither. It is counted in the new `MergeResult.packagesSkipped`, the same way an ambiguous row is (66).
  - **Skips are reported.** The Settings message now reports packages skipped and package lines skipped when either is not zero. The `BUCKETS_MERGE_FILE` stderr line adds `packages skipped N`.
  - **Tests.** The ordinary project now has a line of its own and must keep it. The line-count check is scoped by adding a second project with two lines. Four new cases: nil fields on update, a new package without a margin, duplicate store package names, and a line to a row that the same file archives (kept and linked).
  - DECISIONS 89 now states all of these rules.
- Evidence/tests:
  - `Scripts/test.sh`: 289 executed, 3 skipped (the same three), 0 failures.
  - `Scripts/build.sh Release`: `build/Buckets.app`, 0.2.2 (4), codesign verified.
  - Not installed and not merged; the live store was not touched.
- Decisions: DECISIONS 89 amended as above (no new number).
- Open questions: none new. The review's reminder still applies: the rehearsal on a store copy should include `export-final.json` itself. Merging it now replaces the live "New package" (197 lines) with the file's copy.
- Next owner/action: Codex reviews `claude/merge-packages` after PR #8. The caller rehearses on a store copy, then installs.
- Branch/commit: `claude/merge-packages`, pushed: 1e552bb (fixes) and this commit (log).

## 2026-09-29 — Claude Code — 0.2.2 installed; Sacred Tree layer v2 (crew, kits, packages, subs) applied live

- Context read: Mr. Anderson in chat on 09-29.
  - Pole saws: one standard, the telescoping 3013-21.
  - Price the standard crew, not today's truck: "charge for it and then go get it".
  - Clean up and flesh out the Sacred Tree layer with a loadout and default packages.
  - Employees come from the 2025-26 insurance audit record (six W-2 leased employees, a PEO), and the subcontractors from the same record, with public business profiles.
- Work completed:
  - **Workflow sts-layer-v2.**
    - Subcontractor profiles: 4 researchers (Opus) plus identity checks (Fable). Businesses only; private individuals were not researched.
    - Wages from BLS OEWS May 2025 for the Orlando MSA (Opus).
    - A crew-kit, loadout and packages design (Fable), then an adversarial design review (Opus). It found 4 high-severity issues:
      - renames would duplicate rows;
      - "Use Package" would re-add every row switched ON;
      - the owner's 500i would be touched;
      - labor would come in at $0.
      All were fixed in assembly.
    - This branch (0.2.2) with its code review and fixes.
  - **The layer file.** `~/Developer/sacred-tree-local-vault/sacred-tree-layer-v2-2026-09-29.json` is company data with employee names, so it lives in the vault and not in the repository. It carries:
    - every active live row, copied exactly;
    - 13 renamed rows, archived under their old names and re-added with unit codes (SAW, PSW, MCH, TRK, TRL, RIG, KIT, PPE);
    - the 3016 pole saw honorarily upgraded to a 3013-21;
    - priced to-acquire kits: rigging, 2 climbing kits with a hand saw, traffic control;
    - $0 track-only PPE kits (x6) and truck safety kits (x3), with their cost on "PPE & uniforms" ($1,447.40/yr, formula in the row's notes);
    - "Small tools" flagged for an overlap review;
    - six labor rows at an ESTIMATED $20.20/h wage (3,501¢/h; confidence estimated, needs owner confirmation);
    - 11 new subcontractors (3 archived with "COI pending"), and corrected contact details on the 2 existing subs;
    - the loadout "STS Standard Crew" (23 members);
    - 9 packages, each with a line for every active row, so Use Package adds nothing unexpected.
  - **Rehearsed** on a store copy with 0.2.2, including a second merge to prove idempotence (0 changes; packages updated, not duplicated).
- Evidence/tests:
  - This branch: 289 executed, 3 skipped, 0 failures (see the entries above).
  - Live: 0.2.1 parked at `~/Developer/sacred-tree-local-vault/Buckets-0.2.1.app`. 0.2.2 (build 4) installed at `/Applications/Buckets.app`, codesign verified.
  - `onboard.sh` backup: `onboard-2026-09-29-143040/`.
  - Merge counts: added 32, updated 20, unchanged 195, packages added 9, lines skipped 0, identical to the rehearsal. The live export's rows are byte-identical to the rehearsal's.
  - Active rows: labor 7, equipment 32, materials 100, consumables 68, sub services 3, overhead 24 ($88,592.99/yr = $59.06/h at 1,500 h). Subs 13. The owner's labor row and Stihl 500i are unchanged.
  - Readiness: NEEDS REVIEW, 234 rows unresolved (honest; nothing is owner-confirmed yet).
- Decisions: none new (DECISIONS 89 covers the package merge). The company-layer pattern: each company keeps its profile and layer file in its own vault, and `onboard.sh` applies them on top of the Baseline catalog.
- Open questions (owner):
  - (a) Employees' real wages and roles; the loadout's three names are placeholders.
  - (b) Two crews? If so, overhead is spread over 3,000 h, which roughly halves the $59.06/h.
  - (c) Who ran the "65 yard" grapple loads: Gaston, or J&J's Grapple Service?
  - (d) The legal payee behind "Florida Stump Grind (TreeShop)", plus its W-9 and COI.
  - (e) Standard stump sub and its per-size prices; the crane sub.
  - (f) A gloves, plugs and glasses budget.
  - (g) The saw assumption basis (the owner's 500i vs BRIEF defaults on the other saws).
  - (h) Clean-up: the old "New project", "New package" and the unnamed loadout; typos in the sub and service names ("Recylcing", "walksing").
- Next owner/action:
  - Owner: open Projects → Packages and use one; enter the real wages.
  - Codex: review the PR for `claude/merge-packages` (stacked on PR #8).
- Branch/commit: `claude/merge-packages`, this commit (log).

## 2026-09-30 — Claude Code — Planning section reserved; merge can remove or archive a subcontractor (0.2.3, build 5)

- Context read: Mr. Anderson's instructions, relayed through the workflow on 09-30. He wants a place for business planning and operating documents, marked under construction for now, which he will build with Fable 5.1. He also wants a merge file to be able to take out a subcontractor. Also read `AGENTS.md`, `CLAUDE.md`, `docs/REPOSITORY-WORKFLOW.md`, DECISIONS 22, 55, 60, 66 and 89, `Transfer.mergeItems`, `Subcontractor`, `AppState`, `RootView` and `Scripts/screenshot.sh`.
- Work completed: branch `claude/planning-and-sub-removal`, stacked on `claude/merge-packages` (PR #9, unmerged).
  - **Planning (DECISIONS 90).** A new sidebar section, Business, with one item: Planning.
    - `PlanningScreen` shows "Under construction" and five planned tools as plain text, each marked "Coming soon": revenue forecast; cash flow, 30/60/90 days; annual budget and break-even; crew capacity and utilization; business plan and operating documents.
    - The detail column is empty. The screen has no model, reads no data and shows no figures. ⌘N and ⌘D do nothing on it (new `AppState.canCreate`).
    - `BUCKETS_SCREEN=planning` opens it.
    - The header doc comment marks it as the reserved seam for the section.
  - **Subcontractor removal (DECISIONS 91).** `SubcontractorRecord.remove: Bool?` is new; the format stays 2 and export never writes the key.
    - A matching sub with `remove: true` is deleted with its services when none of them is on a project. Otherwise it is archived, and project lines keep their snapshots.
    - A matching sub with `isActive: false` is archived. A file never un-archives a sub.
    - A `remove` for a name the store lacks does nothing and creates nothing.
    - File rows under a removed or never-created sub are skipped, and their file position is held so later references stay aligned. New rows under a sub the same file archives are added archived.
    - `MergeResult` gains `subcontractorsRemoved` and `subcontractorsArchived`. The `BUCKETS_MERGE_FILE` stderr line reports both, and the Settings message reports each one that is not zero.
  - README, DECISIONS 90–91, version 0.2.3, build 5.
- Evidence/tests:
  - `Scripts/test.sh`: 298 executed, 3 skipped (the same three), 0 failures.
  - New `SubcontractorMergeRemovalTests` (6 tests):
    - remove deletes an unreferenced sub and its services;
    - remove archives a referenced sub, and the line keeps its snapshot and the price;
    - `isActive: false` archives and never un-archives;
    - an unknown remove creates nothing;
    - an old file without the key merges as before;
    - export never writes `remove`.
  - New `PlanningScreenTests` (3 tests): the screen hook and no creation; the planned-tools list; the screen hosts in light and dark.
  - `Scripts/build.sh Release`: `build/Buckets.app`, 0.2.3 (5), codesign verified.
  - Screenshots: Planning rendered with `--fixture --render` in light and dark. In the first render, `ContentUnavailableView` inside a grouped Form drew nothing offscreen, so it was replaced with a plain header row.
  - Not installed; the live store was not touched.
- Decisions: DECISIONS 90 and 91.
- Open questions: none new. From the owner's 09-30 notes, for the next data layer (not this branch):
  - Florida Stump Grind is not TreeShop, and TreeShop is never a sub or vendor. With 91, a layer file can now remove or archive that sub.
  - The crane sub is deferred.
  - One crew for now.
- Next owner/action: Codex reviews `claude/planning-and-sub-removal` after PR #9. The caller rehearses on a store copy before installing.
- Branch/commit: `claude/planning-and-sub-removal`, pushed: 8d4d5b5 (change) and this commit (log). No PR opened.

## 2026-09-30 — Claude Code — Sub removal review fixes (0.2.3, build 5)

- Context read: the review of `claude/planning-and-sub-removal` (8d4d5b5, ed46da5): one medium, three low, one note.
- Work completed (9e4f6e9):
  - **Medium, fixed.** The Settings help for Add or Update Rows no longer says "nothing is deleted". It now says a file may remove a subcontractor it names, and one whose services are on a project is archived instead.
  - **Low, fixed.** A new sub that a file adds with `isActive: false` now adds its new services archived. It was not in `archivedByFile`, so its services came in active.
  - **Low, documented.** A sub archived instead of removed keeps its file position, so rows under it still merge and new ones are added archived. Skipping them would break loadout members that reference those services. This is now stated in DECISIONS 91 and the merge comment.
  - **Note, documented.** DECISIONS 91 now says that deleting a sub also takes its services out of any loadout, the same as deleting it in the app does.
  - **Tests.** The removal test now checks that a second sub and its services survive. New tests: a new archived sub archives its new services; rows under a removed sub or an unknown sub hold their file positions, so a loadout member and a package line after them resolve to the right rows.
- Evidence/tests:
  - `Scripts/test.sh`: 300 executed, 3 skipped (the same three), 0 failures.
  - `Scripts/build.sh Release`: `build/Buckets.app`.
  - The Planning screen is unchanged, so its screenshot was not retaken.
  - Not installed; the live store was not touched.
- Decisions: DECISIONS 91 amended (clarifications only; no version change).
- Next owner/action: Codex re-reviews `claude/planning-and-sub-removal` after PR #9.
- Branch/commit: `claude/planning-and-sub-removal`, pushed: 9e4f6e9 (fixes) and this commit (log). No PR opened.

## 2026-09-30 — Claude Code — 0.2.3 installed; Sacred Tree layer v3 applied (sales manager, single crew, sub corrections)

- Context read: Mr. Anderson in chat on 09-30.
  - New Sales Manager, Noah Aquinas: $200/day salary on a 5-day week, plus 7% commission on revenue he creates.
  - One crew for now, lean. The wage estimates stand until he edits them.
  - Gaston and J&J both run 50 and 65 yd grapple trucks, so treat them as equivalent.
  - **Correction:** "Florida Stump Grind" is NOT TreeShop. TreeShop is Mr. Anderson's own company and must never appear as a subcontractor or vendor. He believes Florida Stump Grind was a demo entry.
  - Cranes are deferred (billed as a flat add plus an hourly increase; no data yet).
  - Reserve a Planning section (this branch).
- Work completed: layer v3 (`~/Developer/sacred-tree-local-vault/sacred-tree-layer-v3-2026-09-30.json`, built from the live export with `tools/build_layer_v2.py` and `tools/layer-v3-overrides.json`):
  - **Noah Aquinas as a labor row** (Sales, $25/h over 2,080 paid h, 30% burden, 4,507¢/h; owner confirmed). Off in every package, so he is never double-counted.
  - **His salary as an overhead line:** "Sales manager salary – Noah Aquinas", $67,600/yr = $52,000 + 30% burden, which is +$45.07 per crew hour at 1,500 h.
  - **PPE budgeted for one crew:** "PPE & uniforms" goes to $1,118.71/yr, and PPE-04..06 are archived.
  - **Grapple subs:** Gaston's notes corrected, with its public Lake/Orange phone; J&J's Grapple Service added as a sub with no rate row yet.
  - **The "Florida Stump Grind (TreeShop)" sub removed** through DECISIONS 91; the older vault files were scrubbed of it too.
  - All 9 packages regenerated.
  - Rehearsed on a store copy with 0.2.3, including a second merge to prove idempotence.
- Evidence/tests:
  - This branch: 300 executed, 3 skipped, 0 failures (see the entries above).
  - Live: 0.2.2 parked at `~/Developer/sacred-tree-local-vault/Buckets-0.2.2.app`. 0.2.3 (build 5) installed, codesign verified.
  - `onboard.sh` backup: `onboard-2026-09-30-054709/`.
  - Merge counts: added 2, updated 4, unchanged 230, packages updated 9, subcontractors removed 1. The live rows and subs are identical to the rehearsal's.
  - Active rows: labor 8, equipment 29, overhead 25 ($155,864.30/yr = $103.91/h at 1,500 h). Subs 13. No store row or sub mentions TreeShop.
- Decisions: none new beyond 90–91. The earlier log entry's open question "(d) the legal payee behind 'Florida Stump Grind (TreeShop)'" is withdrawn: the record was a demo entry, not TreeShop.
- Open questions (owner):
  - (a) The 7% commission comes out of the 50% target margin (about 43% net). Setting the target margin to 57% keeps 50% net after commission (price = cost / 0.43).
  - (b) Real wages, and the crew roster (the audit list is dated).
  - (c) The Sales manager burden (30% assumed).
  - (d) Crane pricing later.
- Next owner/action: owner — review the Planning placeholder and the package prices. Codex — review this branch after PR #9.
- Branch/commit: `claude/planning-and-sub-removal`, this commit (log).

## 2026-09-30 — Claude Code — Commission-aware pricing, Sold by, rows not on the crew (0.2.4, build 6)

- Context read: the reviewed plan "Sales and marketing in Buckets" (now `docs/treeshop/13-sales-marketing-plan.md`, reworded so it names nobody and states pay only as example figures, DECISIONS 88), `AGENTS.md`, `CLAUDE.md`, `docs/REPOSITORY-WORKFLOW.md`, BRIEF, DECISIONS. Scope: slice 1a only.
- Work completed: branch `claude/sales-commission`, stacked on `claude/planning-and-sub-removal` (PRs #8 → #9 → #10, unmerged).
  - **Price rule (DECISIONS 92).** A company sales allowance A and payroll tax on commission B (Company → Pricing defaults; defaults 0 and 7.65) sit in the one price division; margin means after commission. A = 0 prices exactly as 0.2.3, so no price moves on install. The Company screen refuses a margin, allowance or tax over the 95% share and offers **Re-price packages** when packages were priced under an older allowance.
  - **Sold by (DECISIONS 94).** A project names its salesperson (a Labor row with a commission %), with name and % snapshots and a per-job override. The header shows the commission, its payroll tax, and the profit and margin after commission (orange when under the target or a loss). Copy breakdown adds the same lines and never a name.
  - **Not on the crew (DECISIONS 83, 93).** A Labor row can be marked not on the crew: new projects, Re-price, loadouts and the member picker skip it; readiness counts priced rows only.
  - **Format 3 (DECISIONS 95).** Exports carry the new keys; formats 1–3 read; 0.2.3 refuses format 3. Merge sets `trackOnly` and never clears it.
  - BRIEF §1, §2.1, §5.1 amended; README; `onboard.sh` readiness gates count priced rows.
- Evidence/tests:
  - `Scripts/test.sh`: 333 executed, 3 skipped (the same three), 0 failures.
  - New: `PricerCommissionTests` (the A = 0 loop over every pinned fixture; 522,921 / 516,409 / 1,045,843 / 1,568,764; 36,604 + 2,800 → 261,461; floor 75,000 with 5,250 / 402 / 39,356; −5,927; the 864.5 → 865 tie), `ProjectSalespersonTests`, `RepriceTemplatesTests`, `TransferFormat3Tests`, `StoreMigrationV023Tests` (`BucketsSchemaV023`: nine packages, an empty package, a legacy project and a salary line keep every price).
  - `Scripts/build.sh Release`: `build/Buckets.app`, 0.2.4 (6), codesign verified. Project, Labor and Company screens rendered from the screenshot fixture (now with a synthetic salesperson on the Oak removal).
  - Not installed; the live store and the vault were not touched.
- Decisions: 83 (shared text), 92, 93 (first paragraph), 94, 95.
- Not done here (the plan's other 1a items, vault side): `tools/build_layer_v2.py` learning `trackOnly`, `commissionPct` and the two settings keys; data layer v4; the rehearsal on a store copy.
- Open questions: the plan's ten, unchanged. The first is the owner's: turn on a 7% allowance (prices rise 17.75%) or keep today's prices at about 42.5% after commission.
- Next owner/action: Codex reviews `claude/sales-commission` after PR #10. Then the vault layer v4 and the rehearsal before any install.
- Branch/commit: `claude/sales-commission`, 9e2c113 (change) and this commit (log). No PR opened.

## 2026-09-30 — Claude Code — Sales commission review fixes (0.2.4, build 6)

- Context read: the review of `claude/sales-commission` (slice 1a): no High or Medium issues, six Low.
- Work completed (7ab3679):
  - (1) The plan's Copy breakdown clause now matches DECISIONS 92: "Profit after commission" follows Profit.
  - (2) The plan's store table is retitled "Shape of the store … example rates" and keeps only the loaded rates ($35.01, $86.67, $45.07); the hourly wage inputs are gone. The worked-examples heading no longer says "live export".
  - (3) Re-price packages reports "Re-priced N stale packages" (or none stale) beside the banner, and a failed save in red; cleared when the margin, allowance or tax changes.
  - (4) Sold by shows only when an active Labor row carries a %, the same rows the menu lists.
  - (5) Import refuses a `salespersonIndex` that points outside Labor (`TransferError.salespersonNotLabor`); the out-of-range refusal is now tested.
  - (6) Import and merge apply a file's `trackOnly` to Labor rows only until Equipment has its own toggle; DECISIONS 95 says so.
- Evidence/tests: `Scripts/test.sh`: 335 executed, 3 skipped (the same three), 0 failures. `Scripts/build.sh Release`: `build/Buckets.app`, 0.2.4 (6), codesign verified. Not installed; the live store and the vault were not touched.
- Decisions: 95 amended (non-Labor salesperson refused; `trackOnly` Labor-only from files for 0.2.4).
- Next owner/action: Codex re-reviews `claude/sales-commission`.
- Branch/commit: `claude/sales-commission`, 7ab3679 (fixes) and this commit (log). No PR opened.

## 2026-09-30 — Claude Code — Salary calculator on overhead rows, Projects list columns (0.2.5, build 7)

- Context read: `docs/treeshop/13-sales-marketing-plan.md` (slice 1b), `AGENTS.md`, `CLAUDE.md`, `docs/REPOSITORY-WORKFLOW.md`, BRIEF, DECISIONS, the entries above. Scope: slice 1b only, on `claude/sales-commission` after slice 1a.
- Work completed:
  - **Salary calculator (DECISIONS 93, second paragraph; amends 34 for this case).** `Sources/Core/SalaryCalc.swift`: `SalaryPeriod` (day · week · biweekly · semimonthly · month · year), `SalaryCalcInputs {amountCents, period, daysPerWeek, weeksPerYear, burdenPct}`, `SalaryCalc.annualCents` = `round(amount × periods a year × (100 + burden) ÷ 100)`, one division, rounded once; throws on negatives (as 9) and on a result above the $9,999,999.99 rate bound (30).
  - **Overhead Form.** "Calculate…" beside "Cost per year" opens `SalaryCalcSheet`: pay and period, days per week (day rate), weeks per year (day and week rates), burden (default from Settings), billable hours read-only, and "= $67,600.00 per year · $45.07 per hour at 1,500 billable hours" over its formula. Save stores `rateCents` and `calcInputs`; `BucketItem.salaryInputs` reads them back (derived, no new attribute). Other overhead lines are typed as before.
  - **Projects list.** "Sold by" (the project's name snapshot) and "Profit after" (the header's profit after commission and its payroll tax; a loss in orange) columns. Every column of the Projects list sorts, newest first by default. Packages unchanged. DECISIONS 94 records it.
  - `BUCKETS_SCREEN=salarycalc` opens the sheet (first overhead row with salary inputs); the screenshot fixture gains a synthetic salary line added after its two projects.
  - BRIEF §2.3; README; the plan's status line; `docs/treeshop/README.md`.
- Evidence/tests:
  - `Scripts/test.sh`: 347 executed, 3 skipped (the same three), 0 failures.
  - New: `SalaryCalcTests` (20,000/day × 5 × 52 at 30% → 6,760,000, at 10% → 5,720,000; the period table; the 4,212,344.5 → 4,212,345 tie and the 4,212,260 two-step figure; negatives and the bound throw; `salaryInputs` round-trips through `calcInputs` and through export/import; the sheet's draft; the calculator moves no price, before and after Re-price; the screen hook). `ProjectsListTests`: the two columns match the header's figures (157,370 / 145,402 / 185,296) and sort both ways; ties fall back to newest first.
  - `PricerCommissionTests.testZeroAllowanceReproducesEveryPinnedPrice` (A = 0 loop over every pinned fixture) still passes.
  - `Scripts/build.sh Release`: `build/Buckets.app`, 0.2.5 (7), codesign verified. The sheet and the list were rendered from a synthetic fixture store in the scratch area (light and dark).
  - Not installed; the live store and the vault were not touched.
- Decisions: 93 (second paragraph, amending 34); 94 (one sentence on the list columns). No format change: `calcInputs` already travels (43, 95).
- Known limits: at the default 1,180-point window the Projects list's Name and Sold by cells truncate long names; widening the list pane shows them. The Project header's figure row was already cramped at that width before this change.
- Not done here (vault side): data layer v5 (the salary overhead row's `calcInputs` through `tools/build_layer_v2.py`) and its rehearsal.
- Next owner/action: Codex reviews slice 1b on `claude/sales-commission`. Then vault layers v4 and v5 and the rehearsal before any install.
- Branch/commit: `claude/sales-commission`, cd6b36e (change) and this commit (log). No PR opened.
