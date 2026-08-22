---
name: orchestrate-implementation
description: Orchestrate a project-local spec and its tickets through implementation subagents.
disable-model-invocation: true
---

# Orchestrate Implementation

Main is the **orchestrator**; `/Users/neil/.agents/skills/implement/SKILL.md` is the worker contract. Implement one spec on one feature branch, using fresh one-shot agents and only the ticket frontier whose blockers are done. Do not start code review or deployment unless the user separately requests it.

Before dispatch, read `/Users/neil/.agents/skills/fabric-subagents/SKILL.md` and follow its model resolution, recovery, and provenance rules.

## 1. Pin the run

1. Read the feature's `spec.md` and every ticket under `.scratch/<feature>/issues/`.
2. Pin the current branch and `HEAD`; require a clean tracked worktree before the first child starts.
3. Build the dependency frontier from `Blocked by:` and ticket status. A ticket is ready only when every blocker is done.
4. Call `tools.models()` and resolve the exact requested or configured direct model key. Do not guess or silently substitute a provider.

**Done when:** the fixed point, complete ticket graph, current frontier, model, and excluded deployment work are explicit.

## 2. Choose serial or parallel execution

Use `agents.run` with a fresh context for implementation from a complete spec/ticket. Use `agents.handoff` only when the user explicitly asks another model to continue Main's trajectory or consequential decisions have not been captured in the spec/tickets.

A shared frontier makes tickets **parallel candidates**, not automatically parallel-safe. Use parallel worktrees only when all of these are true:

- each ticket has a complete independently verifiable outcome;
- write ownership can be partitioned into disjoint paths or modules before dispatch;
- neither ticket changes a shared schema, migration, generated contract, central registry, or API needed by another ticket in the wave;
- integration order cannot change either ticket's intended behaviour;
- the expected saved wall-clock time justifies parallel integration overhead.

Serialize tickets when ownership overlaps, is uncertain, or one ticket establishes a contract another consumes. Do not manufacture dependency edges merely to avoid evaluating safe parallelism, and do not parallelize merely because two tickets have no blockers.

**Done when:** the next wave is either one current-workspace writer or a bounded set of workers with explicit non-overlapping ownership.

## 3. Dispatch workers

Every worker task must include:

- pinned starting commit and one ticket number/path;
- spec path and any relevant dependency tickets;
- an instruction to read and follow `/Users/neil/.agents/skills/implement/SKILL.md`;
- the ticket's allowed write ownership;
- required repository checks and the statement that deployment and code review are excluded;
- a requirement to stop and report rather than edit outside assigned ownership;
- a requirement to produce one scoped Conventional Commit for the ticket and report its SHA, changed paths, acceptance evidence, and test results.

Project-local `.scratch` files may be ignored and therefore absent from a Git worktree. Give worktree agents the absolute main-workspace spec/ticket paths as read-only inputs; Main owns ticket-status updates.

### One writer

Run one blocking `agents.run` in the current workspace with write tools and `worktree: false`. After it returns, mechanically confirm its commit, changed paths, ticket acceptance criteria, and checks before advancing the frontier.

### Parallel writers

Run the parallel-safe wave concurrently with one `agents.run({ worktree: true })` per ticket. All workers start from the same pinned `HEAD`, receive exclusive write ownership, and create one commit on their Fabric branch. Do not let workers share a worktree or edit Main's workspace.

Use the smallest useful fan-out. Parallel workers isolate files, not credentials, processes, networks, or external services; tests must still use test-owned state.

## 4. Integrate a parallel wave

Wait for every worker in the wave, then integrate from Main:

1. Treat failed, timed-out, zero-turn, uncommitted, or unverifiable workers as failures, never as completed tickets.
2. For each successful result, inspect `result.branch`, its single commit relative to the pinned base, and `git diff --name-only <base>...<branch>`.
3. Recheck actual changed-path sets for overlap. If workers crossed ownership or overlap unexpectedly, stop automatic integration and inspect; do not blindly combine them.
4. Cherry-pick successful disjoint commits into the feature branch in ticket-number order.
5. Run the smallest integrated checks that cover cross-ticket contracts, then the full relevant suite after the final wave.
6. Mark ticket status done only after its commit is integrated and acceptance criteria are verified in Main.
7. After successful integration, call `agents.cleanup({ id, deleteBranch: true })`. Retain a failed worker's worktree for diagnosis until its useful evidence is recovered or the user chooses to discard it.

Never report partial fan-out as full coverage. Retry only a failed ticket when its result is still required, and state that a retry uses a fresh context.

**Done when:** every integrated ticket is present on Main's feature branch, verification passes, and successful temporary worktrees/branches are cleaned up.

## 5. Advance and finish

Recompute the frontier after each integrated wave and continue until the requested tickets are done or a real blocker remains. Do not start a ticket whose blockers failed or remain unintegrated.

At completion:

- verify every requested acceptance criterion from Main;
- run the final relevant repository suite once;
- compare actual changed LOC with the spec estimate as required by the worker contract;
- report exact model/provider, fresh run or handoff topology, ticket-to-agent mapping, worktree/branch/commit state, verification evidence, retries, and remaining blockers;
- leave code review and deployment to explicit user requests.
