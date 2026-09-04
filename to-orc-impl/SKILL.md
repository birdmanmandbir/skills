---
name: to-orc-impl
description: Turn the current discussion into a documented spec and tickets, then orchestrate its implementation. Use after the work is agreed and ready to ship.
---

# Discussion to implementation

Turn an agreed discussion into one implementation run. This is the composed path:

`to-spec → to-tickets → orc-impl`

Run it only after the conversation already supplies the product decisions. Do not restart discovery as an interview.

## One repository

1. Read `to-spec` completely and produce a ready spec at `.scratch/<feature>/spec.md`.
2. In the spec, add a **Documentation and agent guidance** decision. Identify the user, operator, and agent-facing documentation affected by the change.
3. Read `to-tickets` completely and create `.scratch/<feature>/issues/`.
4. Add one final documentation ticket, blocked by every implementation ticket. Its acceptance criteria must:
   - update the affected project documentation;
   - inspect `README.md` and update it when the user-facing or operator-facing contract changed;
   - inspect `AGENTS.md` and update it when the agent-facing workflow, commands, or conventions changed;
   - record why either file needs no update when its contract is unchanged or it is absent.
5. Read `orc-impl` completely and run it for the named feature. Its single worker implements the whole spec, including the documentation ticket, then completes the whole-spec review.

The documentation ticket is part of the same PR, not follow-up work.

## Multiple repositories

Treat each repository as an atomic delivery unit: one local spec, one ticket set, one worker, and one PR **per repository**. Use the same feature slug and a shared cross-repository acceptance summary in every spec's **Further Notes**.

Workers may run in parallel across repositories when their tickets have no cross-repository blocker. If one repository depends on a contract, artifact, or release from another, express that dependency in both specs and finish the blocking repository first. Within each repository, use only the one worker started by `orc-impl`.

Each worker follows the same `orc-impl` contract: it owns the complete ticket set and deterministic review fixes, calls back only after the complete spec is implemented and verified, and its owner performs the final whole-spec review. Do not merge a repository's PR until its cross-repository acceptance criteria are satisfied.
