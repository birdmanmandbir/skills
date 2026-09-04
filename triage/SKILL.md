---
name: triage
description: Move local request files in the workspace's `.scratch/` tracker through a state machine of triage roles — categorise, verify, grill if needed, and write agent-ready briefs.
disable-model-invocation: true
---

# Triage

Move request files in the project-local Markdown tracker through a small state machine of triage roles. The tracker lives only under `.scratch/`: each raw request is one file at `.scratch/inbox/<slug>.md`. Do not create or update remote tracker issues or PRs.

## Reference docs

- [AGENT-BRIEF.md](AGENT-BRIEF.md) — how to write durable agent briefs
- [OUT-OF-SCOPE.md](OUT-OF-SCOPE.md) — how the `.scratch/out-of-scope/` knowledge base works

## Roles

Two **category** roles:

- `bug` — something is broken
- `enhancement` — new feature or improvement

Five **state** roles:

- `needs-triage` — maintainer needs to evaluate
- `needs-info` — waiting on reporter for more information
- `ready-for-agent` — fully specified, ready for an AFK agent
- `ready-for-human` — needs human implementation
- `wontfix` — will not be actioned

Every triaged request file must carry exactly one `Category:` and one `Status:` field. If state roles conflict, flag it and ask the maintainer before doing anything else.

State transitions: an unlabeled issue normally goes to `needs-triage` first; from there it moves to `needs-info`, `ready-for-agent`, `ready-for-human`, or `wontfix`. `needs-info` returns to `needs-triage` once the reporter replies. The maintainer can override at any time — flag transitions that look unusual and ask before proceeding.

## Invocation

The maintainer invokes `/triage` and describes what they want in natural language. Interpret the request and act. Examples:

- "Show me anything that needs my attention"
- "Let's look at .scratch/inbox/import-timeout.md"
- "Move .scratch/inbox/import-timeout.md to ready-for-agent"
- "What's ready for agents to pick up?"

## Show what needs attention

Scan `.scratch/inbox/` and present three buckets, oldest first:

1. **Unlabeled** — never triaged.
2. **`needs-triage`** — evaluation in progress.
3. **`needs-info` with new material in the request file since the last triage notes** — needs re-evaluation.

Show counts and a one-line summary per item. Let the maintainer pick.

## Triage a specific request

1. **Gather context.** Read the full request file, including prior triage notes and agent briefs, so you don't re-ask resolved questions. Explore the codebase using the project's domain glossary, respecting ADRs in the area. Run two checks against the codebase: (a) **redundancy** — search for an existing implementation of the requested behavior by domain concept (not just the request's wording), and report where you looked. If found, it's an already-implemented `wontfix` (step 5). (b) **prior rejection** — read `.scratch/out-of-scope/*.md` and surface any that resembles this request.

2. **Recommend.** Tell the maintainer your category and state recommendation with reasoning, plus a brief codebase summary relevant to the request — including whether it's already implemented. Wait for direction.

3. **Verify the claim.** Before any grilling, check that the claim holds up. For a bug, reproduce it from the request's steps. Report what happened: confirmed (with code path), failed, or insufficient detail (a strong `needs-info` signal). A confirmed verification makes a much stronger agent brief.

4. **Grill (if needed).** If the request needs fleshing out, run the `/grilling` and `/domain-modeling` skills together — grill it into shape a round of questions at a time, sharpening domain terms and updating `CONTEXT.md`/ADRs inline as decisions land.

5. **Apply the outcome:**
   - `ready-for-agent` — write an `## Agent Brief` section in the request file ([AGENT-BRIEF.md](AGENT-BRIEF.md)).
   - `ready-for-human` — write the same structure, but note why it can't be delegated (judgment calls, external access, design decisions, manual testing).
   - `needs-info` — write triage notes in the request file (template below).
   - `wontfix` — set `Status: wontfix` and record the reason in the request file:
     - **Already implemented** — point to where it lives; do **not** write to `.scratch/out-of-scope/` (that KB is for *rejected* requests, not built ones).
     - **Rejected (bug)** — record a concise explanation.
     - **Rejected (enhancement)** — write to `.scratch/out-of-scope/` and link it from the request file ([OUT-OF-SCOPE.md](OUT-OF-SCOPE.md)).
   - `needs-triage` — set the status. Add a note if there is partial progress.

## Quick state override

If the maintainer says "move <request path> to ready-for-agent", trust them and update the fields directly. Confirm what you're about to change in the request file, then act. Skip grilling. If moving to `ready-for-agent` without a grilling session, ask whether they want to write an agent brief.

## Needs-info template

```markdown
## Triage Notes

**What we've established so far:**

- point 1
- point 2

**What we still need from you (@reporter):**

- question 1
- question 2
```

Capture everything resolved during grilling under "established so far" so the work isn't lost. Questions must be specific and actionable, not "please provide more info".

## Resuming a previous session

If prior triage notes exist in the request file, read them, check whether new material answers any outstanding questions, and present an updated picture before continuing. Don't re-ask resolved questions.
