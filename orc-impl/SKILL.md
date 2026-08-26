---
name: orc-impl
description: Orchestrate one project-local spec through ticket-level implementation agents and final code review.
disable-model-invocation: true
---

# Orchestrate implementation

Main owns one spec from a pinned starting commit through integrated ticket commits and final review. Each ticket gets a fresh implementation agent that owns only that ticket and follows the installed `implement` skill. Keep one writer active at a time by default. Deployment remains outside this workflow unless the user requests it separately.

## 1. Pin the run

1. Read the named `.scratch/<feature>/spec.md` and every ticket under its `issues/` directory.
2. Record the current branch and starting `HEAD`. Require a clean tracked worktree before dispatch; preserve ignored or untracked project-local planning files.
3. Build the complete dependency graph from ticket status and `Blocked by:` fields. A ticket is ready only when every blocker is integrated and verified.
4. Resolve the installed `implement` and `code-review` skill paths so their exact absolute paths can be given to agents.

**Done when:** the fixed point, requested ticket set, dependency graph, initial frontier, and excluded deployment work are explicit.

## 2. Plan a wave

A serial wave is the default: dispatch one ready ticket, verify and integrate it, then give the next ticket to a fresh writer. A shared frontier contains parallel candidates, not automatically parallel-safe work. Parallelize only when the tickets have independently verifiable outcomes, write ownership can be assigned to disjoint paths or modules before dispatch, integration order cannot change behaviour, and the wall-clock saving clearly justifies the integration overhead. Serialize work that overlaps or changes a shared schema, migration, generated contract, central registry, or API consumed by another ticket.

Use one current-workspace writer for a serial wave. For a parallel wave, create one temporary Git worktree per ticket from the same pinned wave commit and give each agent its worktree's absolute path. Use the smallest useful fan-out.

Keep at most four child agents active at once. Writer agents consume this budget. Use remaining slots only when useful for an optional planner, a bounded researcher, or one or two auditors; these support roles inspect and report but never write, commit, or integrate. Code-review's reviewer agents also count toward the four-agent limit. Close agents whose work is complete before opening slots for another role.

**Done when:** every ticket in the wave has one workspace and explicit write ownership, no writer paths overlap, and the active-agent topology has at most four members.

## 3. Dispatch ticket agents

Spawn a fresh writer when its ticket enters the current wave. Normally dispatch only one writer; an exceptional parallel-safe wave may dispatch its writers together. Use `model: luna` for writers by default and explicitly ask for maximum reasoning effort in the task. Use `model: selected` only when the ticket is exceptionally difficult and materially needs stronger reasoning; size alone is insufficient.

Every writer task must include:

- the spec path, one ticket number/path, and any completed dependency tickets needed for context;
- the pinned starting commit and exact workspace path;
- the absolute `implement/SKILL.md` path and an instruction to read it completely before implementing the ticket;
- exclusive allowed write ownership and an instruction to stop and report before editing outside it;
- the ticket acceptance criteria and required repository checks;
- confirmation that code review and deployment are excluded from the worker's scope;
- a requirement to create one scoped Conventional Commit and report its SHA, changed paths, acceptance evidence, and test results.

Project-local `.scratch` files may be absent from temporary worktrees. Pass their absolute main-workspace paths as read-only inputs; Main alone updates ticket status.

Give planner, researcher, and auditor agents narrow read-only questions with an explicit output schema. They may recommend changes to Main or the writer, but the ticket writer remains the only owner of implementation edits.

## 4. Wait, verify, and integrate

Wait for all active agents together with `wait_agent({ agent_ids, timeout_ms: 290000 })`. Repeat the same bounded wait for agents that remain active. A wait timeout is a progress checkpoint, not a worker failure. Give every healthy agent at least 30 minutes, and continue waiting beyond that while it is making progress; elapsed time alone is never grounds to interrupt or close it.

For each terminal worker:

1. Treat failed, interrupted, uncommitted, or unverifiable work as an incomplete ticket.
2. Confirm its single commit relative to the pinned wave commit, actual changed paths, acceptance evidence, and checks.
3. Stop automatic integration if actual paths cross assigned ownership or overlap another worker.
4. Integrate successful disjoint commits in ticket-number order, then run the smallest checks covering their combined contracts.
5. Mark a ticket done only after its commit is integrated and its acceptance criteria pass on Main.
6. Clean up successful temporary worktrees and branches only after integration. Preserve failed work until useful evidence is recovered or the user chooses to discard it.

Continue independent frontier work when one ticket fails. Recompute blockers after every wave; report failed tickets and all tickets they block. Never describe partial coverage as a completed spec.

**Done when:** every successful ticket is verified on Main, temporary successful workspaces are cleaned up, and the next frontier or real blockers are known.

## 5. Review the complete spec

After every requested ticket is integrated:

1. Run the final relevant repository suite once and verify every spec acceptance criterion from Main.
2. Close support agents that are no longer needed, then invoke `code-review` against the pinned starting commit and the spec path, leaving enough of the four-agent budget for its reviewers. The review covers the complete integrated diff.
3. Fix deterministic findings with the smallest proportionate change, rerun affected checks, and repeat `code-review`.
4. When review identifies a judgement call, stop the fix loop and ask the user. Include the evidence already checked, the unresolved external-usage or deployment-history question, the recommended choice, and the compatibility or migration code that can be removed if the user confirms it is unnecessary.
5. Continue until review has no merge blockers, or a real blocker or user decision remains.

At completion, report ticket-to-agent and ticket-to-commit mapping, planner/researcher/auditor use, peak active-agent count, integration state, verification evidence, review iterations, judgement calls, retries, changed-LOC variance required by the spec, and remaining blockers.
