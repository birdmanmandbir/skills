---
name: to-tickets
description: Break a plan, spec, or the current conversation into project-local Markdown tickets, each declaring its blocking edges.
disable-model-invocation: true
---

# To Tickets

Break a plan, spec, or conversation into a set of **tickets** — tracer-bullet vertical slices, each declaring the tickets that **block** it. When the source is a spec, every ticket belongs to that spec's single PR; tickets are execution units on one feature branch, not PR boundaries.

Use the project-local Markdown tracker exclusively. Do NOT run `/setup-matt-pocock-skills` and do NOT create or update remote tracker issues. Choose a concise feature slug from the work, then write one ticket per file under `.scratch/<feature-slug>/issues/<NN>-<slug>.md`, numbered from `01` in dependency order. Record dependencies as `Blocked by:` and use `Status: ready-for-agent` for newly published tickets.

## Process

### 1. Gather context

Work from whatever is already in the conversation context. If the user passes a `.scratch/` spec path, read it. For an issue number, URL, or other external reference, ask them to provide its relevant content or turn it into a local spec; do not fetch it.

### 2. Explore the codebase (optional)

If you have not already explored the codebase, do so to understand the current state of the code. Ticket titles and descriptions should use the project's domain glossary vocabulary, and respect ADRs in the area you're touching.

Prefactor only when it directly unlocks the requested slice. Fold it into that ticket when feasible rather than creating preparatory architecture work.

### 3. Draft vertical slices

Break the work into **tracer bullet** tickets.

<vertical-slice-rules>

- Each slice cuts a narrow but COMPLETE path through every layer (schema, API, UI, tests) — vertical, NOT a horizontal slice of one layer
- A completed slice is demoable or verifiable on its own
- Each slice is sized to fit in a single fresh context window
- Any necessary prefactoring is the minimum needed to unlock a requested slice

</vertical-slice-rules>

Give each ticket its **blocking edges** — the other tickets that must complete before it can start. A ticket with no blockers can start immediately. Do not add a blocking edge merely to force a comfortable execution order: independent tickets should remain on the same frontier so an implementation orchestrator can evaluate whether disjoint worktrees make them safely parallel.

Treat the current repository — monorepo or otherwise — as the default atomic change boundary. For a cross-cutting mechanical edit, prefer one ticket or independently green end-to-end slices. Introduce temporary old/new forms only when there is evidence of an external consumer or a real multi-deployment boundary that cannot change atomically.

### 4. Finalize the breakdown

Choose the granularity and blocking edges yourself from the vertical-slice rules. Do not ask the user to approve, merge, or split routine ticket boundaries. Ask only when an unresolved product decision changes what the tickets deliver; otherwise proceed directly to publication.

### 5. Publish the tickets as local Markdown

Write the approved tickets under `.scratch/<feature-slug>/issues/`, one file per ticket and never a combined ticket file. Number files from `01` in dependency order (blockers first). Each file's `Blocked by:` lists the ticket numbers/titles it depends on and its `Status:` starts as `ready-for-agent`. Keep all tickets for one spec on the same feature branch for one PR.

Work the **frontier**: any ticket whose blockers are all done. For a purely linear chain that means top to bottom.

<local-ticket-template>

# <NN> — <Ticket title>

**What to build:** the end-to-end behaviour this ticket makes work, from the user's perspective — not a layer-by-layer implementation list.

**Blocked by:** the numbers/titles of the tickets that gate this one, or "None — can start immediately".

Status: ready-for-agent

- [ ] Acceptance criterion 1
- [ ] Acceptance criterion 2

</local-ticket-template>

In either form, avoid specific file paths or code snippets — they go stale fast. Exception: if a prototype produced a snippet that encodes a decision more precisely than prose can (state machine, reducer, schema, type shape), inline it and note briefly that it came from a prototype. Trim to the decision-rich parts — not a working demo, just the important bits.
