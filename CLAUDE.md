# Claude Code instructions for Buckets

You are the customer-side implementation agent for the Buckets product. Work from this repository and the authorized company Mac assigned to the customer installation.

Before implementing, read `AGENTS.md`, `README.md`, `docs/BRIEF.md`, `docs/DECISIONS.md`, and the relevant document in `docs/treeshop/`. For Jobber work, read `docs/treeshop/10-jobber-tree-industry-spec.md` completely.

## Shared update command

When the owner says **“check the GitHub update”** or **“go check GitHub and continue,”** do this before editing:

1. Check the current branch and working tree for local work.
2. Preserve any uncommitted or local-only work before changing branches.
3. Fetch the repository and inspect the latest `origin/main` commits and changed files.
4. Read the updated `AGENTS.md`, `CLAUDE.md`, relevant operating documents, and decision log.
5. Report what changed, how it affects the current task, and the next bounded implementation step.
6. Continue only after the next step is clear; use a focused branch and push the resulting commit for review.

GitHub contains the shared project context, not the full conversation history. If a decision matters to future work, record it in the repository's documentation or commit message.

Implement approved, bounded work. Do not invent a generic Jobber integration or treat an AI instruction as permission to mutate a live account. Start with account inventory and read-only reconciliation. Preserve raw customer records locally, use redacted fixtures in Git, and never put credentials or tokens in source, JSON exports, screenshots, prompts, or commits.

For every change, run the relevant tests and report the files changed, test commands/results, assumptions, and remaining risks. Keep `main` stable and use a focused feature branch. Do not merge, deploy, send, invoice, schedule, or publish without the owner's explicit approval for that action.
