---
name: orc-impl
description: Orchestrate one existing project-local spec through a persistent Luna worker and whole-spec code review.
disable-model-invocation: true
---

# Orchestrate implementation

Use one persistent owner and one persistent worker to implement an existing spec. The owner normally runs Terra Max in one Herdr tab. The worker runs Luna Max in a second tab, implements every ticket in dependency order, and reports only after the complete spec is ready. Do not create parallel workers. Deployment is outside this workflow unless the user requests it separately.

## 1. Resolve the run

This skill is loaded through the skill MCP, not Tact's built-in skill catalog. Keep the absolute `path` returned for this skill and resolve `scripts/herdr-worker.sh` relative to its parent directory. Resolve the installed `implement` and `code-review` skills through the same MCP and retain their returned absolute `SKILL.md` paths.

Do not use `skill get` to discover paths; it returns the body only. Do not assume a `TACT_SESSION_ID` environment variable exists. When a Tact session ID is needed for scratchpad work, call the `current_session` tool. Do not treat `CODEX_THREAD_ID` as a Tact contract.

Before dispatch:

1. Require `HERDR_ENV=1` and the Herdr workspace, tab, and pane variables.
2. Read the named `.scratch/<feature>/spec.md` and every ticket under its `issues/` directory.
3. Record the current branch and starting `HEAD`. Require a clean tracked worktree; preserve ignored or untracked planning files.
4. Build the dependency order from ticket numbers, statuses, and `Blocked by:` fields.
5. Confirm that the spec and tickets contain enough information for one worker to finish without per-ticket owner acceptance.

Use absolute paths in the dispatch. Spec and ticket files are the main handoff; do not paste their contents into terminal messages. If additional long instructions are necessary, write them to the active session's scratchpad and send the absolute path.

## 2. Start the worker tab

Run the helper with the absolute path derived from this skill's MCP result:

```sh
bash <orc-impl-dir>/scripts/herdr-worker.sh start --label worker --cwd "$PWD"
```

The helper creates a separate Herdr tab without taking focus, starts `tact --model luna --thinking max`, waits only for startup readiness, and returns JSON containing the owner pane ID, worker pane ID, and worker tab ID. Retain those opaque IDs for the whole run. Never rediscover either side from focus, tab order, labels, or agent names.

Herdr currently receives Tact lifecycle reports but does not accept Tact through `herdr agent prompt`. Use the helper's pane-based `send` command for all owner-worker messages.

## 3. Dispatch the whole spec

Send one compact bootstrap message to the worker:

```sh
bash <orc-impl-dir>/scripts/herdr-worker.sh send \
  --pane <worker-pane-id> \
  --message "Read <implement-skill-path> completely, then implement the whole spec at <spec-path> and all tickets under <issues-path>. Work through tickets in dependency order without per-ticket owner acceptance. Owner pane: <owner-pane-id>. Report only after the complete spec is implemented and verified; code review and deployment are excluded."
```

The worker owns routine implementation decisions and the complete implementation work. Tickets remain execution units: finish and verify each ticket's acceptance criteria before advancing, but do not pause for owner acceptance between tickets. Follow the `implement` skill for repository work, verification, changed-LOC reporting, and commits.

The only allowed early report is a genuine blocker that cannot be resolved without user or owner judgement. A blocker report must state the evidence checked, the exact decision required, and the worker's recommendation.

After successful dispatch, the owner ends the current turn and becomes idle. Do not call `wait_agent`, poll the worker, or keep a model turn open while implementation runs. Herdr keeps both tabs and Tact sessions alive.

## 4. Worker completion callback

When all tickets and final relevant checks are complete, the worker:

1. Calls `current_session` for its own scratchpad if a detailed report file is useful.
2. Records completed acceptance criteria, commits, changed paths, test results, changed-LOC variance, and remaining concerns.
3. Sends a short callback to the retained owner pane ID, including the absolute report path when one exists:

```sh
bash <orc-impl-dir>/scripts/herdr-worker.sh send \
  --pane <owner-pane-id> \
  --message "IMPL_COMPLETE: whole spec implemented and verified. Report: <absolute-path-or-inline-summary>"
```

An idle owner receives this as a new turn. If the owner is already working, Tact may admit it as queued or steering input. The callback is the authoritative completion signal; Herdr `idle` or `done` alone does not prove the whole spec is complete.

## 5. Review, triage, and finish

After the completion callback, the owner:

1. Reads the worker report and verifies the repository state against the pinned starting `HEAD` and every spec acceptance criterion.
2. Invokes the resolved `code-review` skill against that fixed point and the complete spec. Review the whole integrated diff only after the worker's full-spec report.
3. Triages review findings. Send deterministic fixes back to the same worker as one consolidated batch, then end the owner turn again and wait for another explicit completion callback.
4. Ask the user about every judgement call whose correct resolution depends on unresolved external usage, prior deployment, retained data, public compatibility, cutover, or product behaviour. State what was checked, recommend the simplest supported choice, and identify migration or compatibility code that can be removed if the user confirms it is unnecessary.
5. Repeat review after fixes until there are no merge blockers, or a real blocker or user decision remains.

The owner owns triage, user decisions, final acceptance, and the final report. The worker owns implementation and deterministic review fixes. The owner should not take over routine code changes.

After final acceptance, close only the worker tab created for this run. Preserve it when the run is blocked or failed until useful evidence is recovered or the user chooses to discard it.

At completion, report the starting commit, worker pane/tab, ticket and commit coverage, verification evidence, review iterations, judgement calls, changed-LOC variance, and remaining blockers.
