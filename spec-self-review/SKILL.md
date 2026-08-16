---
name: spec-self-review
description: Review and revise an implementation spec before tickets or coding, especially when asked to self-review a spec, find omissions, test readiness, or remove over-engineering.
---

Review an existing spec against the product decision, repository reality, and the smallest safe implementation. Revise the spec in place; do not implement it or create tickets.

## Process

### 1. Pin the review target

Use the path the user supplied. Otherwise locate the one spec clearly identified by the conversation or current feature under `.scratch/`, `specs/`, or `docs/`. Ask for the path only when more than one candidate remains plausible.

Read the entire spec. If tickets already exist for it, read them only to detect drift; the spec remains the authority.

**Done when:** one exact spec and its stated delivery boundary are pinned.

### 2. Check repository reality

Inspect only the code, contracts, ADRs, configuration, and existing test seams needed to verify the spec's assumptions. Resolve current platform or library claims from primary documentation when correctness depends on them.

Confirm:

- the described current behaviour is real;
- named domain concepts match repository vocabulary;
- proposed data is available at the claimed seam;
- existing capabilities are reused before adding new ones;
- external consumers or multi-deployment boundaries actually exist before preserving compatibility;
- migrations, generated artifacts, secrets, routes, and deployment work are acknowledged when required.

**Done when:** every consequential implementation claim is supported, corrected, or explicitly marked as an assumption.

### 3. Trace outcome coverage

Build a private ledger from problem → solution → user stories → implementation decisions → tests → out of scope. Each promised outcome must have one coherent path and one observable verification seam.

Review for:

- contradictions, duplicated requirements, undefined terms, and accidental alternatives;
- missing loading, empty, failure, stale, retry, cancellation, authorization, privacy, accessibility, and responsive behaviour where applicable;
- identity, ownership, idempotency, concurrency, money, time, and immutable-snapshot semantics where the domain makes them relevant;
- behaviour that changes across browser, mobile, channel, provider, or deployment boundaries;
- user-visible wording that exposes provider, queue, schema, or internal state unnecessarily;
- acceptance criteria that cannot distinguish complete from partial implementation.

Add only edge cases that can plausibly occur in the promised workflow. A checklist item is not a requirement by itself.

**Done when:** every core story is implementable and externally verifiable, and every added edge case protects a plausible user outcome or correctness boundary.

### 4. Demand a complexity proof

Every mechanism must earn its complexity through at least one of:

1. a current user story;
2. a documented repository constraint;
3. a verified external consumer or real independent deployment boundary;
4. a plausible correctness, security, data-loss, or operational failure in the promised path.

Simplify or remove mechanisms without that proof. Look especially for:

- abstractions, interfaces, factories, plugins, state machines, or configuration added for one fixed case;
- generalized frameworks where one capability-local function or type is enough;
- expand–migrate–contract or compatibility layers inside an atomically deployable repository;
- schema or persistence for values that can remain derived, transient, or local;
- duplicated APIs, read paths, caches, sources of truth, or old/new forms;
- custom infrastructure where a project capability or maintained dependency already fits;
- capability detection when progressive enhancement, CSS, or a static fallback is sufficient;
- platform breadth, browser matrices, provider adapters, and feature flags unsupported by the current target;
- prefactors and wide cleanup that do not directly unlock the feature;
- exactly-once machinery where the external boundary cannot provide exactly once and a truthful uncertain state is safer;
- tests repeated at every layer, assertions on source shape or exact prose, exhaustive matrices, and new seams when one high seam covers the behaviour;
- implementation prescriptions that constrain file shape or private helpers without protecting a contract.

Do not trade away authorization, transaction boundaries, immutable records, owner isolation, exact money, or ambiguity guards merely to reduce line count. Safe simplicity removes accidental complexity, not required correctness.

**Done when:** every remaining non-trivial mechanism has a written reason traceable to the ledger, and lower-cost alternatives have been considered.

### 5. Classify and revise

Classify findings before editing:

- **Blocker** — contradictory, infeasible, unsafe, or missing a user-facing decision needed to implement correctly.
- **Simplify now** — complexity removable with no meaningful user-visible cost.
- **Clarify now** — ambiguity the repository or prior decisions can resolve.
- **Ask** — a low-confidence user-facing tradeoff whose answer materially changes the experience or removes disproportionate complexity.
- **Defer** — valuable optional work outside this PR.

Apply **Simplify now** and **Clarify now** directly. Keep one PR as the delivery boundary. Remove speculative optional work rather than moving it into the implementation plan; record only concrete follow-ups through the project's approved defer mechanism when one exists.

Ask only **Ask** findings. Present the tradeoff, recommendation, and concrete complexity removed, then wait. Decide technical implementation, error classification, locking, platform mechanics, and test strategy yourself.

Set `Status: draft` while unresolved blockers or user decisions remain. Set `Status: ready-for-agent` only after they are resolved and the revised spec passes the completion gate.

### 6. Completion gate

Before declaring the review complete, mechanically confirm:

- one PR can coherently deliver the spec;
- every core user story maps to implementation decisions and an observable test;
- public contracts, registrations, migrations, secrets, routes, and deployment steps are named when applicable;
- no requirement depends on an unverified repository or platform assumption;
- no compatibility path lacks an external consumer or deployment-boundary reason;
- no optional mechanism survives without a complexity proof;
- tests use the highest practical seam and representative cases;
- out-of-scope statements prevent likely scope creep without restating the whole spec;
- the status matches actual readiness.

If tickets already exist, report that they must be regenerated or updated when the revised spec changes their behaviour or dependencies.

## Output

Report concisely:

1. **Blockers** — unresolved items, or none.
2. **Simplifications applied** — what was removed or narrowed and why.
3. **Corrections applied** — factual, contract, edge-case, or test-seam fixes.
4. **Remaining assumptions/deferred work** — only concrete items.
5. **Readiness** — `ready-for-agent` or what prevents it.

Show the spec path. Do not begin implementation or ticket publication.
