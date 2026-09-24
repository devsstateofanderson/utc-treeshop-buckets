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

## 2026-09-24 — Codex — v0.2.0 implementation handoff

- Context read: PR #2 audit, the Buckets Pro functional roadmap, current SwiftData models, and the live GitHub branch state.
- Work completed: opened GitHub issue #3 for the first functional Pro slice and handed it to Claude for implementation on the Sacred Tree MacBook.
- Scope: catalog trust metadata and review filters; company setup/readiness counts; non-blocking unresolved-input warnings on estimates; export/import compatibility; version `0.2.0`; backup, package, install, launch, and smoke-test on the customer Mac.
- Decisions: this release is deliberately before Jobber OAuth or any live Jobber mutation. No automatic catalog removals/merges, scenarios, scorecards, or AI actions in this slice.
- Open questions: Claude must report the live-store export/backup path and any migration limitation before replacement; the owner remains the approval authority for customer data and live operations.
- Next owner/action: Claude pulls latest `main`, preserves customer data outside Git, implements issue #3 on a focused branch, runs the full suite, installs the release build, and opens a PR. Codex reviews and merges.
- Branch/commit: `main` / pending documentation handoff commit; issue [#3](https://github.com/devsstateofanderson/utc-treeshop-buckets/issues/3).
