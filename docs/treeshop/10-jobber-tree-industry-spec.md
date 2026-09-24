# Jobber + tree-service integration specification

**Status:** design baseline for Buckets Pro

**Prepared:** September 22, 2026

**Purpose:** define what Buckets must understand before it reads from or writes to Jobber, and define the minimum tree-service catalog structure that makes an estimate operationally useful.

This is an implementation specification, not a claim that Buckets is currently integrated with Jobber. The current app has no Jobber connector. The first implementation must prove the live account's schema, permissions, data quality, and workflow in Jobber's Developer Center before enabling write-back.

## 1. The operating boundary

Buckets and Jobber should not compete to be the same system.

| Responsibility | System of record | What Buckets does with it |
|---|---|---|
| Jobber account/tenant, clients, contacts, properties, requests, quotes, jobs, visits, team users, invoices, payment records | Jobber | Import a linked operational copy with the Jobber account ID, object ID, retrieval time, and source version. |
| Company catalog, cost assumptions, crew/equipment loadouts, target margin, minimum price, scenarios, standards references, unresolved assumptions | Buckets | Own, version, review, and use for estimating and operating decisions. |
| Scheduled execution time, visit completion, time-sheet entries, job expenses | Jobber, with Buckets as the analysis layer | Read the source record; classify coverage and use it for estimate-versus-actual analysis. Never silently replace a Jobber time entry with a Buckets guess. |
| Approved estimate and the resulting customer-facing quote | Shared, with explicit direction | Buckets prepares the commercial decision. Jobber is the customer workflow and billing execution surface. A write must identify who approved it and which Buckets estimate version produced it. |
| Objectives, variance explanations, recommendations, and operating actions | Buckets | Keep the management layer separate from Jobber's field execution records. |

The phrase **“Buckets controls Jobber”** should therefore mean: Buckets can prepare, validate, reconcile, and—after an explicit approval—issue supported Jobber commands. It does not mean that an AI process may freely mutate a live customer account.

## 2. What Jobber actually models

Jobber's own workflow documentation describes requests, quotes, jobs, invoices, and payment as the normal progression. Its API exposes more detail than that summary. The following names are the vocabulary Buckets should use.

| Jobber object | Literal meaning | Buckets interpretation | First release |
|---|---|---|---|
| `Account` | The service provider's Jobber business account | One external tenant/workspace connection | Import and identify |
| `Client` | The customer who pays the service provider | Customer/payer record; not necessarily the physical work location | Import and match |
| `Property` | A location where service is provided | Work site; the tree inventory and site conditions belong here or to a job linked to it | Import and match |
| `Request` | A work request/lead, optionally with an assessment | Intake and qualification; a request is not yet approved work | Import; later create only by approval |
| `Assessment` | A scheduled visit to assess and plan future work | Site-assessment appointment and evidence collection step | Import; map to assessment workflow |
| `Quote` | A cost estimate sent to the client before work | Job-specific commercial proposal generated from a versioned Buckets estimate | Read first; draft write later |
| `Job` | The overall accepted/scheduled scope of work | Approved work order; the parent of one or more visits | Import and link |
| `Visit` | Each calendar event where the crew goes to the property | One execution occurrence, phase, or return trip | Import and link |
| `TimeSheetEntry` | Recorded time for a Jobber user, potentially linked to a job/visit | Labor actual evidence; preserve approved/payable/category fields and source timestamps | Import and coverage analysis |
| `Expense` | A cost incurred by the service provider, optionally linked to a job | Job cost evidence; do not assume every field is complete or categorized like Buckets | Import and review |
| `Invoice` | Customer billing record for completed work | Revenue/billing status, not a substitute for cost or margin truth | Import status; no autonomous send |
| `PaymentRecord` | A payment/deposit/refund record associated with a quote or invoice | Cash-collection signal; keep separate from invoice issuance and job cost | Import status |
| `User` / team member | A Jobber account user or worker identity | Crew/member match for time, assignment, and permissions | Import and map manually |
| Line items / products and services | The priced work items on quotes, jobs, visits, and invoices | Customer-facing commercial detail; Buckets' internal cost drivers remain richer than a line item | Import; write only from approved estimate |
| Custom fields | Account-configured fields on supported Jobber objects | Stable bridge for Buckets IDs, version, and human review state | Configure after account review |

Jobber distinguishes the **job** from its **visits**: a job is the overall work and visits are the individual calendar events. A one-off removal may have one visit; a large removal, planting project, or recurring service can have several. Buckets must never count jobs as visits or visits as separate customers.

These definitions are grounded in Jobber's current API schema and help documentation: [Developer Center schema](https://developer.getjobber.com/docs/), [Jobber workflow overview](https://help.getjobber.com/en/articles/jobber-workflow-overview/), and [Visits](https://help.getjobber.com/en/articles/visits/).

### Jobber nuances Buckets must preserve

- A request can be created internally or submitted through a client-facing form. It can receive an assessment, be converted to a quote, or be converted directly to a job. A request is not automatically a scheduled job.
- An assessment is a scheduled opportunity to inspect and plan work. The request's client-availability information is not the same as a committed calendar visit.
- A visit can be scheduled with a date and time, be an anytime visit with a date but no time, or remain unscheduled. Buckets must preserve that distinction instead of filling in a fictitious start time.
- A job can be one-off or recurring. Recurring work may be invoiced per visit or at a fixed price, so revenue-to-cost comparisons need the job's billing basis.
- Jobber's time workflow distinguishes visit time, assessment time, and general time. General time may be useful for capacity analysis but must not be assigned to a tree job without evidence.
- A completed visit can lead to a follow-up visit or an invoice reminder. “Completed visit,” “requires invoicing,” and “paid” are separate states.

References: [Requests](https://help.getjobber.com/en/articles/request-basics/), [Visits](https://help.getjobber.com/en/articles/visits/), [Invoice reminders](https://help.getjobber.com/en/articles/invoice-reminders/), and [Timers and timesheets](https://help.getjobber.com/en/articles/timers-and-timesheets-in-the-jobber-app/).

## 3. The canonical tree-service workflow

Buckets should treat the following as the standard operating loop. A company may skip a stage, but skipping it must be visible rather than silently inferred.

```text
Inquiry/request
  -> qualification and service-area check
  -> site assessment / tree inventory
  -> scope and safety review
  -> Buckets estimate + scenario decision
  -> Jobber quote
  -> client approval / decline
  -> Jobber job
  -> one or more scheduled visits
  -> field execution, time, equipment, materials, disposal, photos
  -> completion and deviation review
  -> invoice and payment
  -> estimate-versus-actual review
  -> catalog, crew, or process improvement
```

### 3.1 Intake and assessment

The request is a lead and an explanation of desired work. It is not a price and it is not permission to perform work. Minimum intake fields for a tree company are:

- client identity and communication preference;
- property address and access notes;
- requested service family;
- urgency and reason for urgency;
- client-described targets or concerns;
- photos supplied by the client;
- utility, traffic, structure, neighbor, or access concerns known before the assessment;
- source of the request and next contact date.

An assessment is the scheduled opportunity to inspect the property and create a defensible work specification. The assessment record should capture:

- tree or plant identifier(s), even if temporary (`T-01`, `T-02`);
- species or “unknown,” without inventing identification;
- size observations appropriate to the service (for example, diameter/height estimate or a measured value);
- condition, defects, targets, access, and work-zone constraints;
- utilities and other hazards observed;
- photos and the person who collected them;
- whether a qualified arborist review is required;
- permit, utility, HOA, municipal, or customer approval dependency;
- proposed service type and whether the work is ready to estimate.

Do not make a risk determination from a photograph or language model alone. Buckets may organize evidence and flag missing fields; a qualified person must own the professional judgment.

### 3.2 Scope and work specification

Each priced service must have a human-readable work specification. It should say what will be done, to which tree/area, by what general method, what is included in cleanup/disposal, and what is excluded. It should also point to the applicable standards reference and edition without copying copyrighted standards text.

The scope template should ask, as applicable:

- tree IDs or planting/treatment areas;
- objective and service method;
- measurable limits or acceptance criteria;
- access, staging, traffic, utility, and property-protection requirements;
- crew/equipment assumptions;
- disposal, chipping, hauling, stump treatment/grinding, or material removal;
- restoration and cleanup;
- customer responsibilities and exclusions;
- permit or utility-clearance dependency;
- safety review flags and required qualified-person approval.

### 3.3 Estimate and quote

Buckets calculates the internal cost model from the company catalog. A quote-ready result must preserve:

- estimate version and date;
- source confidence for every material assumption;
- crew, hours, equipment, subcontractor, disposal, and material quantities;
- price, tax treatment, target margin, minimum-price rule, and scenario selected;
- scope text and exclusions;
- standards references and local-code/permit notes;
- approval identity and approval time.

Jobber receives the customer-facing quote representation. Buckets must keep the detailed internal assumptions even when Jobber only needs a smaller set of customer-facing line items.

### 3.4 Job, visit, and field execution

After approval, the Jobber job is the parent scope. Every visit is an execution event. A production review should collect or reconcile:

- assigned people and equipment;
- planned versus actual arrival/start/end;
- visit status and completion time;
- time-sheet entries, including whether approved and payable;
- equipment use and rental/subcontractor charges;
- materials and consumables used;
- dump loads, haul distance, disposal fees, and green-waste destination;
- change in scope, return trip, weather delay, access issue, or customer decision;
- completion photos and notes;
- customer sign-off or unresolved punch item.

Jobber's mobile workflow supports visit timers and timesheets. Buckets should report the coverage of those records, not pretend that an absent timer is zero labor.

### 3.5 Completion, invoice, and learning

Completion is not the same as invoicing and invoicing is not the same as payment. Buckets should show the distinctions:

- visit completed;
- job completed;
- invoice created/issued;
- payment received/partially received;
- variance reviewed;
- follow-up or maintenance recommendation created.

For recurring work, Jobber supports per-visit and fixed-price billing patterns. Buckets must record which billing basis was used before comparing revenue to a single visit's cost.

## 4. Exact integration rules

### 4.1 Authentication and API versioning

Jobber's API is GraphQL over HTTPS at `https://api.getjobber.com/api/graphql`. Requests use OAuth 2.0 access tokens and the `X-JOBBER-GRAPHQL-VERSION` header. Access tokens expire; refresh-token rotation means that the newly returned refresh token must replace the old one immediately and concurrent refreshes must be guarded.

Implementation rules:

1. Use Authorization Code + PKCE for the connected account.
2. Store tokens in the Mac's Keychain or the future server-side secret store, never in the Buckets JSON export, notes, or source control.
3. Store the connected Jobber `account.id`, granted scopes, token timestamps, API version, and connection status.
4. Select an active API version at build time from Jobber's Developer Center/changelog. Do not treat a version shown in a documentation example as permanently current.
5. Treat disconnect, revoked access, account downgrade, deactivated admin, and regenerated client secret as a reconnection state—not as an empty account.

References: [Jobber authorization](https://developer.getjobber.com/docs/building_your_app/app_authorization/), [refresh-token rotation](https://developer.getjobber.com/docs/building_your_app/refresh_token_rotation/), and [API versioning](https://developer.getjobber.com/docs/using_jobbers_api/api_versioning/).

### 4.2 Read path: backfill, webhook, repair

The reliable read path is three pieces:

1. **Backfill:** paginated queries with explicit `first`/`last` and cursors for the initial account import.
2. **Webhook trigger:** subscribe to relevant object events. A webhook identifies the topic, account ID, item ID, and time; it does not contain the full object. Fetch the object after acknowledging the request.
3. **Repair poll:** periodically query changed records using the supported schema so missed webhooks or temporary failures are corrected.

Webhook handling must be idempotent. Store the event key, topic, item ID, received time, fetch result, and processing status. Verify the signature when configured, acknowledge quickly, and do the GraphQL fetch and reconciliation asynchronously.

References: [API queries and mutations](https://developer.getjobber.com/docs/using_jobbers_api/api_queries_and_mutations/), [webhooks](https://developer.getjobber.com/docs/using_jobbers_api/setting_up_webhooks/), and [rate limits](https://developer.getjobber.com/docs/using_jobbers_api/api_rate_limits/).

### 4.3 Identity and matching

Never match records by customer name alone. Every relationship needs:

```text
externalSystem = Jobber
accountId       = connected Jobber account ID
objectType      = Client | Property | Request | Quote | Job | Visit | Invoice | ...
objectId        = Jobber encoded ID
bucketsId       = local Buckets record ID
linkedAt        = timestamp
linkMethod      = manual | exact-field | reviewed-match
lastCheckedAt   = timestamp
```

The property is the work location and the client is the payer. A single client may have multiple properties. A job may have a property but an invoice may be associated with multiple jobs/properties. The UI must show these distinctions.

### 4.4 Write policy

Write access is staged, with no hidden escalation:

| Stage | Permitted action | Approval |
|---|---|---|
| 0 — observe | Read account, clients, properties, requests, quotes, jobs, visits, time, expenses, invoices, and payments | Connection owner authorizes OAuth |
| 1 — identify | Create/update Buckets custom-field configuration or values for external IDs and estimate version, after account review | Operator approval; test account first |
| 2 — prepare | Create a draft quote or update quote line items from a selected Buckets estimate, only if the live schema and granted scope support it | Human approval per quote |
| 3 — approved execution | Convert/update the approved work representation and carry the Buckets link into the Jobber job | Human approval; idempotency key and read-back verification |
| 4 — scheduling/billing | Change visits, complete work, create/send invoices, or trigger payment actions | Explicit separate policy; not part of initial autonomy |

Every mutation must:

- include `userErrors` in the response and stop on any error;
- record the exact mutation name, input summary, operator, estimate version, response, and read-back result;
- be safe to retry without creating a duplicate;
- fail closed when the external record changed since the approval;
- never silently overwrite a Jobber user edit.

Jobber supports custom fields on clients, properties, quotes, jobs, invoices, team members, and products/services. The initial bridge should use a small, documented set:

- `Buckets Workspace ID` — read-only link;
- `Buckets Estimate ID` — read-only link;
- `Buckets Estimate Version` — read-only text/number;
- `Buckets Scope Status` — editable dropdown only if the operator wants Jobber users to signal a decision;
- `Buckets Review URL` — link field to the relevant Buckets/TreeShop record if the deployment has a reachable URL.

Do not create dozens of custom fields before confirming the account's plan, existing field names, transfer behavior, and API scope. Reference: [Jobber custom fields](https://developer.getjobber.com/docs/using_jobbers_api/custom_fields/).

### 4.5 Rate, pagination, and query design

The connector must use small, bounded queries, explicit connection limits, cursor pagination, caching, retry/backoff, and a request log. Jobber documents both account/app request protection and GraphQL query-cost limits. A deeply nested “everything for every job” query is specifically the wrong design.

The connector should prefer:

- a narrow list query for changed top-level records;
- a second query for details required by a current review;
- a queue of unresolved IDs for retry;
- local freshness timestamps instead of repeated full imports.

## 5. Tree-service catalog: standards-backed, not standards-copied

The catalog should be a pricing and execution model that references the relevant standards. It must not reproduce or imply ownership of the ANSI/ISA text. Store the edition, clause/part reference, link or licensed document reference, and the date reviewed.

### 5.1 Default references

- **ANSI A300 Tree Care Standards (2023):** work-practice and work-specification reference. Its consolidated clauses cover general information, pruning, soil management, supplemental support systems, lightning protection, site development/construction, planting/transplanting, integrated vegetation management, root management, tree risk assessment, integrated pest management, and industry definitions. The English edition is the authoritative reference when a translation differs. See [ISA's A300-2023 description](https://www.isa-arbor.com/Newsroom/discover-the-ansi-a300-2023-tree-care-standards-in-english-and-spanish-1) and [the ISA store entry](https://www.isa-arbor.com/store/product/4645).
- **ANSI Z133-2026:** safety and health requirements for arboricultural operations. Use it to drive safety gates, training/qualification prompts, hazard controls, and field checklists—not as a pricing formula. The 2026 edition became available in May 2026; the older 2017 edition was transitional only until the stated effective date. See [ISA's Z133-2026 notice](https://www.isa-arbor.com/Newsroom/the-z133-2026-standard-is-now-available) and [TCIA's Z133 product page](https://treecareindustryassociation.org/products/ansi-z133-arboricultural-safety-standards/).
- **ISA Best Management Practices:** companion practice guidance for particular A300 subjects. Store a reference to the applicable BMP when the company has access to the current edition; do not paste the publication into the catalog.
- **Local law and utility requirements:** a separate layer. Florida permits, municipal tree ordinances, utility clearance, pesticide labels, traffic control, worker rules, and customer/HOA requirements are not replaced by A300 or Z133.

### 5.2 Initial service families

The first catalog should begin with service families, then add company-specific variants. It should not start as a flat list of vague products.

| Family | Typical catalog variants | A300 reference | Z133/safety gate |
|---|---|---|---|
| Pruning | structural, deadwood, clearance, reduction, palm/frond work, storm cleanup pruning | Clause 5; exact specification and limits must be selected by the qualified estimator | climbing/aerial, chainsaw, electrical, traffic, drop-zone, rescue |
| Removal | sectional removal, technical removal, crane-assisted removal, storm-damaged removal | General/definitions and applicable work specification; do not imply A300 alone defines every removal method | felling/rigging, crane, chainsaw, electrical, traffic, targets, rescue |
| Stump and root-zone work | stump grinding, stump treatment, root-zone cleanup/management | Root management when applicable; otherwise reference the chosen work method and local requirements | machine guarding, underground utility locate, flying debris, traffic |
| Supplemental support | cabling, bracing, guying, inspection/re-tensioning | Clause 7 | climbing/aerial, hardware specification, inspection interval |
| Lightning protection | install, inspect, repair | Clause 8 | qualified design/installation, electrical interface, inspection |
| Soil and root management | soil test, amendment, mulching, aeration, root-zone treatment | Clauses 6 and 12 | product label, application safety, underground utilities |
| Planting/transplanting | tree selection, site preparation, planting, establishment care | Clause 10 | lifting, excavation, utilities, watering/establishment plan |
| Vegetation and pest management | monitoring, IVM, IPM, treatment, follow-up | Clauses 11 and 14 | licensed applicator where required, label, drift/exposure, notification |
| Risk assessment | basic assessment, advanced assessment, monitoring/review | Clause 13; use qualified assessor and current TRAQ/BMP guidance where applicable | site access, targets, documentation, professional review |
| Construction/site protection | tree protection plan, root-zone protection, monitoring, restoration | Clause 9 | site coordination, exclusion zones, inspection cadence |
| Recurring maintenance | scheduled inspection/pruning/treatment visits | relevant A300 clause(s) per service | recurring crew/equipment/seasonal safety review |

This is an operating taxonomy, not a claim that every service is automatically compliant. The exact specification, qualifications, local requirements, and safety controls remain part of the job approval.

### 5.3 Catalog record required fields

Every active service definition should carry:

```text
serviceId                  stable Buckets ID
customerName               customer-facing label
internalName               operator label
family                     pruning | removal | ...
variant                    company-specific subtype
defaultUnit                tree | hour | crew-hour | visit | load | cubic-yard | each | allowance
quantityBasis              how the quantity is measured and by whom
pricingModel               fixed | unit | time-and-material | crew-day | recurring
costDrivers                labor, equipment, material, disposal, subcontractor, overhead
standardReferences         A300 clause/part, Z133 applicability, BMP reference
editionReviewed            edition/year
specificationPrompts       required scope and acceptance fields
safetyFlags                hazards and required review gates
crewRequirements           competency/qualification prompts, not invented credentials
equipmentRequirements      owned/rented/subcontracted assumptions
jobberMapping              product/service or line-item mapping, if used
localRequirementPrompts    permit, utility, municipal, HOA, label, or traffic checks
sourceAndEvidence          link/document, checked date, confidence, approver
activeState                draft | active | retired
```

The pricing engine must not price a service as “tree removal” without asking for the variables that actually drive cost: tree count/size, access, targets, rigging or crane need, crew composition, disposal, stump scope, travel, and uncertainty. The UI may use defaults, but the estimate must show which defaults were accepted.

## 6. Data model changes Buckets needs

The current `Project`, `ProjectLine`, and `BucketItem` models are enough for a local pricing prototype but not for a Jobber-connected tree operation. Add these concepts without breaking existing project snapshots:

### `ExternalLink`

`system`, `accountId`, `objectType`, `objectId`, `bucketsRecordId`, `linkMethod`, `linkedAt`, `lastCheckedAt`, `status`.

### `ServiceDefinition`

The catalog record described above. Existing `BucketItem` rows can remain cost inputs; a service definition composes those inputs into a quoteable work package.

### `WorkSpec`

`serviceDefinitionId`, tree/site IDs, scope text, measurable limits, inclusions, exclusions, photos/evidence, standards references, local dependencies, safety flags, qualified-review state.

### `EstimateVersion`

Immutable snapshot of assumptions, quantities, rates, selected scenario, customer price, margin, source confidence, approver, and timestamp. A Jobber quote must link to one version, never to mutable live rows.

### `ExecutionRecord`

One linked Jobber job/visit with planned and observed hours, people, equipment, materials, disposal, expenses, completion evidence, and coverage state.

### `ReconciliationIssue`

`severity`, `record`, `field`, `sourceValues`, `proposedResolution`, `owner`, `status`, `createdAt`, `resolvedAt`.

This makes a mismatch actionable. It avoids silently “fixing” customer data during an import.

## 7. Build sequence for the first client

### Gate 1 — inventory the real Jobber account

Before coding mutations, record:

- current Jobber plan and enabled features;
- account timezone and service area;
- clients, properties, requests, quotes, jobs, visits, invoices, payments, users, products/services, custom fields, forms, and tags actually in use;
- current job statuses and billing patterns;
- whether team members use visit timers and timesheets consistently;
- representative examples of pruning, removal, stump, recurring, emergency, and subcontracted work;
- one completed job with a clean time record and one with known missing data.

Deliverable: a schema/data dictionary with real IDs and redacted examples.

### Gate 2 — read-only connector

Implement OAuth, account identification, paginated backfill, webhook intake, repair polling, external links, staging, and a read-only reconciliation screen. No estimate or schedule write-back yet.

Exit criteria:

- every imported record has account/object identity and freshness;
- duplicate clients/properties are visible;
- a Jobber job can be linked to exactly one Buckets estimate version;
- webhook replay does not create duplicate records;
- a revoked connection is visible as disconnected, not as “no data.”

### Gate 3 — tree catalog and estimate composition

Load only the first client's verified service families, cost inputs, crew/equipment loadouts, disposal rules, and standards-reference metadata. Build one complete estimate each for pruning, removal, stump work, and a recurring service. Compare the outputs with the owner's current quoting practice.

Exit criteria:

- no active service has an unknown unit or unreviewed price hidden from the estimator;
- every quote-ready service has scope prompts and an applicable reference;
- an estimator can explain price from cost inputs and scenario selection;
- output can be represented as Jobber line items without losing Buckets' internal detail.

### Gate 4 — approved quote preparation

Add a “prepare Jobber quote” action. Show the exact customer, property, scope, line items, total, and linked Buckets estimate version. Require a human approval, perform the mutation, check `userErrors`, then read the quote back and display the Jobber ID.

Do not send, schedule, invoice, or charge automatically in this gate.

### Gate 5 — execution and learning

Import visits, time-sheet entries, expenses, completion state, invoices, and payments. Show coverage and variance. Run a weekly review that produces one catalog correction or operating action from evidence.

## 8. Acceptance tests

The first working integration is complete only when it can pass these tests against a test account and then a controlled production sample:

1. OAuth connection identifies the intended Jobber account, not merely a successful token response.
2. A client with two properties remains one client with two work sites.
3. A quote with multiple line items links to one immutable Buckets estimate version.
4. A job with three visits produces three execution records under one job.
5. A visit timer and a manually entered time-sheet entry are not double-counted.
6. A completed visit with no time entry is reported as missing coverage, not zero labor.
7. An invoice is not marked paid merely because it was issued.
8. A webhook replay is idempotent and a missed webhook is recovered by repair polling.
9. A mutation with a `userErrors` response does not appear successful in Buckets.
10. A Jobber-side edit after estimate approval creates a reconciliation issue rather than being silently overwritten.
11. A service definition with no standards reference, scope prompts, or source confidence cannot be marked production-ready.
12. A Florida/local requirement can be attached as a separate dependency without being mislabeled as an ANSI/ISA requirement.

## 9. Product decision

The first valuable Jobber feature is not “write everything.” It is **truthful operational reconciliation**:

> Given a real request, quote, job, visit, time record, expense, invoice, and payment, Buckets can show what was intended, what was scheduled, what happened, what was paid, which facts are missing, and what decision should change next.

Once that is reliable for five to ten companies, write-back and agentic execution become safer to scale. Before that point, the product should earn trust by being precise about identity, scope, standards references, and variance.
