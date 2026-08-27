---
name: orc-impl
description: Orchestrate one existing project-local spec through a persistent Codex worker and whole-spec code review.
disable-model-invocation: true
---

# Orchestrate implementation

Use one owner and one Codex worker to implement an existing spec. The worker runs in a second tab, implements every ticket in dependency order, and reports after the complete spec is ready. Do not create parallel workers. Deployment is outside this workflow unless the user requests it separately.

## 1. Prepare the run

1. Require `HERDR_ENV=1` and the Herdr workspace, tab, and pane variables.
2. Read the named `.scratch/<feature>/spec.md` and every ticket under its `issues/` directory.
3. Record the current branch and starting `HEAD`. Require a clean tracked worktree; preserve ignored or untracked planning files.
4. Build the dependency order from ticket numbers, statuses, and `Blocked by:` fields.
5. Resolve absolute paths to this skill's `scripts/herdr-worker.sh`, `implement/SKILL.md`, and `code-review/SKILL.md`.

Use absolute paths in the dispatch. Pass long context by file path instead of pasting it into terminal messages.

## 2. Start the worker tab

Run the helper from this skill directory:

```sh
bash <orc-impl-dir>/scripts/herdr-worker.sh start --label worker --cwd "$PWD"
```

The helper creates one separate tab without taking focus, starts Codex in the requested working directory using the user's Codex configuration, and returns the owner pane ID, worker pane ID, and worker tab ID. It waits for the new pane's shell by retrying `agent_pane_busy` against that same pane; it never creates a second worker to recover a startup race. Retain those opaque IDs for the whole run. Use the helper for all owner-worker messages.

If startup exhausts its bounded retry, the helper returns `started: false`, the retained pane/tab IDs, a structured error, and whether the failure is recoverable. Preserve that tab and resume it instead of creating another:

```sh
bash <orc-impl-dir>/scripts/herdr-worker.sh resume --pane <worker-pane-id>
```

## 3. Dispatch the whole spec

Send one compact bootstrap message to the worker:

```sh
bash <orc-impl-dir>/scripts/herdr-worker.sh send \
  --pane <worker-pane-id> \
  --message "Read <implement-skill-path> completely, then implement the whole spec at <spec-path> and all tickets under <issues-path>. Work through tickets in dependency order without per-ticket owner acceptance. Owner pane: <owner-pane-id>. Callback helper: <absolute-helper-path>. When the whole spec is implemented and verified, write the required Markdown report, then run: bash <absolute-helper-path> send --wait-ready --pane <owner-pane-id> --message \"IMPL_COMPLETE: whole spec implemented and verified. Report: <absolute-markdown-path>\". Do not finish until that command returns accepted: true and status: working. Code review and deployment are excluded."
```

Keep the role boundary explicit: the owner follows `orc-impl`; the worker follows only `implement`. The bootstrap is the worker's orchestration contract and must directly provide the absolute helper path, owner pane ID, callback command, and callback success condition. Knowing only the owner pane ID is insufficient. The helper uses Herdr's Agent API to submit the prompt atomically and waits for an observed non-working-to-`working` transition. A low-level input acknowledgement or a helper result such as `sent: true` does not prove dispatch. Only `accepted: true` with `status: working` is a successful dispatch; otherwise preserve the worker and recover the reported error. Dispatch only while the target is `idle` or `done`, because prompting an already-working agent cannot prove which turn caused the observed state.

The worker owns routine implementation decisions and the complete implementation work. Tickets remain execution units: finish and verify each ticket's acceptance criteria before advancing, without pausing for owner acceptance. Follow the `implement` skill for repository work, verification, changed-LOC reporting, and commits.

The only allowed early report is a genuine blocker that cannot be resolved without user or owner judgement. A blocker report must state the evidence checked, the exact decision required, and the worker's recommendation.

Only after the worker is observed as `working` does the owner end the current turn.

## 4. Worker completion callback

When all tickets and final relevant checks are complete, the worker writes a Markdown report at a location it chooses. The report records completed acceptance criteria, commits, changed paths, test results, changed-LOC variance, and remaining concerns. The worker then sends its absolute path to the retained owner pane ID:

```sh
bash <orc-impl-dir>/scripts/herdr-worker.sh send \
  --wait-ready \
  --pane <owner-pane-id> \
  --message "IMPL_COMPLETE: whole spec implemented and verified. Report: <absolute-markdown-path>"
```

`--wait-ready` waits until the owner is `idle` or `done`, rechecks readiness to close the wait/prompt race, and only then submits through the verified Agent API. The worker must use the exact absolute helper path received in bootstrap and must not finish until the helper returns `accepted: true` with `status: working`. The accepted callback is the completion signal; Herdr `idle` or `done` alone does not prove the whole spec is complete.

## 5. Review, triage, and finish

After the completion callback, the owner:

1. Reads the worker report and verifies the repository state against the pinned starting `HEAD` and every spec acceptance criterion.
2. Invokes `code-review` against that fixed point and the complete spec. Review the whole integrated diff only after the worker's full-spec report.
3. Triages review findings. Send deterministic fixes back to the same worker as one consolidated batch using `send --wait-ready`. End the owner turn again only after the helper confirms `accepted: true` and `status: working`, then wait for another explicitly accepted completion callback.
4. Ask the user about every judgement call whose correct resolution depends on unresolved external usage, prior deployment, retained data, public compatibility, cutover, or product behaviour. State what was checked, recommend the simplest supported choice, and identify migration or compatibility code that can be removed if the user confirms it is unnecessary.
5. Repeat review after fixes until there are no merge blockers, or a real blocker or user decision remains.

The owner owns triage, user decisions, final acceptance, and the final report. The worker owns implementation and deterministic review fixes.

After final acceptance, close only the worker tab created for this run. Preserve it when the run is blocked or failed until useful evidence is recovered or the user chooses to discard it.

At completion, report the starting commit, worker pane/tab, ticket and commit coverage, verification evidence, review iterations, judgement calls, changed-LOC variance, and remaining blockers.
