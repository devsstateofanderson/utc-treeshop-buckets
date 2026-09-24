# Claude Code implementation brief

This is the handoff format for the company Mac. The supervisor station plans and reviews work; Claude Code implements only an approved brief against a client-safe fixture or the local company environment.

## Session header

- Feature:
- Brief ID:
- Repository commit:
- Buckets version:
- Company/workspace:
- Data mode: fixture / disposable copy / live with explicit approval
- Builder model/session:
- Date:
- Supervisor approval:

## Required brief

### Problem

What repeated decision, error, or delay is being addressed? Include one observed example and its cost in time, money, accuracy, or repeatability.

### Desired behavior

Describe the user-visible flow from start to finish. Name what the user enters, what the system calculates or stores, and what evidence confirms completion.

### Data impact

List new fields, models, relationships, external IDs, migrations, export keys, and default behavior. State whether old projects and old exports remain readable.

### Source boundary

For each value, identify whether it comes from Buckets, Jobber, a client document, a user decision, an AI proposal, or a derived calculation. No adapter may silently overwrite a user-owned pricing snapshot.

### Acceptance checks

- Unit tests for new calculation or normalization rules
- Model/export/import test for persistent data
- UI test or screenshot for visible behavior
- Duplicate, retry, malformed-input, and missing-data behavior
- Restore or rollback check when the feature touches client data

### Constraints

- Keep client credentials and client stores out of the repository.
- Do not change historical project prices silently.
- Do not add a vendor integration without explicit scopes, ownership, and failure behavior.
- Do not expand the feature into a general workflow suite without a new brief.

### Completion report

Return the commit, changed files, tests run, screenshots or export evidence, known limitations, and the next smallest follow-up. A feature is incomplete when it only compiles; it must demonstrate the decision it was built to support.

## First brief to implement

Use [09-buckets-pro-functional-roadmap.md](09-buckets-pro-functional-roadmap.md), Release 1, as the product source. Start with the setup profile, missing-input queue, source/confidence fields, and company catalog review. Use [07-buckets-pro-upgrade-plan.md](07-buckets-pro-upgrade-plan.md) for the reliability and review gates that accompany the feature. Do not begin Jobber, goals, agents, or dashboard work in the same session.
