---
name: orc-impl
description: Orchestrate one existing project-local spec through a persistent Implementation worker and whole-spec code review.
disable-model-invocation: true
---

# Orchestrate implementation

Use one Owner and one Implementation worker to implement an existing spec. The Implementation worker runs in a second tab, implements every ticket in dependency order, and reports after the complete spec is ready. Do not create parallel workers. Deployment is outside this workflow unless the user requests it separately.

The Owner is the sole orchestrator: it starts the run, accepts the result, and owns review, triage, and user decisions. The Implementation worker owns the complete implementation and deterministic fixes, then sends one accepted Completion callback identifying its report. The Implementation worker does not start or recover another worker.

## 1. Prepare the run

1. Require the exact Herdr variables `HERDR_ENV=1`, `HERDR_WORKSPACE_ID`, `HERDR_TAB_ID`, and `HERDR_PANE_ID`. When diagnosing their presence, inspect those exact names; a prefix check that expects `HERDR_WORKSPACE=` or `HERDR_PANE=` does not test the injected `_ID` variables.
2. Read the named `.scratch/<feature>/spec.md` and every ticket under its `issues/` directory.
3. Require a clean tracked worktree; preserve ignored or untracked planning files.
4. Build the dependency order from ticket numbers, statuses, and `Blocked by:` fields.
5. Resolve absolute paths to this skill's `scripts/herdr-worker.sh`, `implement/SKILL.md`, and `code-review/SKILL.md`.

Use absolute paths in the dispatch. Pass long context by file path instead of pasting it into terminal messages.

## 2. Start the Implementation worker tab

From the project workspace, pass the feature name as the only start argument:

```sh
bash <orc-impl-dir>/scripts/herdr-worker.sh start <feature-name>
```

The helper uses the current directory as the Implementation worker workspace and the feature name as both branch name and worker label. On the repository's default branch, it requires a clean tracked worktree, runs `og pull`, creates the named branch, and only then creates the Herdr tab. If the named branch already exists, it fails before pulling or creating a tab. On a feature branch, the current branch must already equal the feature name. After startup succeeds, record the current branch and starting `HEAD` as the fixed point for implementation and review.

The helper creates one separate tab without taking focus, injects the fixed `ORC_WORKER_ROLE=implementation-worker` marker, and reports the pane's display identity as `Implementation worker` on a best-effort basis. A display-metadata failure does not block startup. It then starts Codex with `gpt-5.6-luna` at `max` reasoning and returns the Owner pane ID, Implementation worker pane ID, and worker tab ID. It waits for the new pane's shell by retrying `agent_pane_busy` against that same pane; it never creates a second worker to recover a startup race. Retain those opaque IDs for the whole run. Use the helper's `send` and `steer` commands for all Owner–Implementation worker messages.

If a marked Implementation worker invokes `start` or `resume`, the helper returns a role guard before any repository or Herdr lifecycle operation. The worker must continue the assigned implementation and reserve coordination for its Completion callback; `send` remains available for that callback.

Before the initial dispatch, treat `bash <helper> status --pane <worker-pane-id>` as the readiness check. A `started: true` response followed by `agent_not_found` means the launched Codex exited during startup (for example, after a self-update); preserve that pane and use `resume --pane <worker-pane-id> --label <feature-name>`, then repeat the status check. Do not create a replacement tab.

If startup exhausts its bounded retry, the helper returns `started: false`, the retained pane/tab IDs, a structured error, and whether the failure is recoverable. Preserve that tab and resume it instead of creating another:

```sh
bash <orc-impl-dir>/scripts/herdr-worker.sh resume \
  --pane <worker-pane-id> \
  --label <feature-name>
```

## 3. Dispatch the whole spec

Send one compact bootstrap message to the Implementation worker:

```sh
bash <orc-impl-dir>/scripts/herdr-worker.sh send \
  --pane <worker-pane-id> \
  --message "You are the Implementation worker. Read <implement-skill-path> completely, then implement the whole spec at <spec-path> and all tickets under <issues-path>. Work through tickets in dependency order without per-ticket Owner acceptance. The Owner is the sole orchestrator; do not start or recover another worker. Implement and verify the work, then use only the Completion callback to coordinate. Owner pane: <owner-pane-id>. Callback helper: <absolute-helper-path>. When the whole spec is implemented and verified, write the required Markdown report, then run: bash <absolute-helper-path> send --wait-ready --pane <owner-pane-id> --message \"IMPL_COMPLETE: whole spec implemented and verified. Report: <absolute-markdown-path>\". Do not finish until that command returns accepted: true and status: working. Code review and deployment are excluded."
```

Keep the role boundary explicit: the Owner follows `orc-impl`; the Implementation worker follows only `implement`. The bootstrap is the Implementation worker's orchestration contract and must directly provide the absolute helper path, Owner pane ID, callback command, and callback success condition. Knowing only the Owner pane ID is insufficient. The helper uses Herdr's Agent API to submit the prompt atomically and waits for an observed non-working-to-`working` transition. A low-level input acknowledgement or a helper result such as `sent: true` does not prove dispatch. Only `accepted: true` with `status: working` is a successful dispatch; otherwise preserve the worker and recover the reported error. Dispatch only while the target is `idle` or `done`, because prompting an already-working agent cannot prove which turn caused the observed state.

### Steer the active worker

When the user adds or corrects an in-scope requirement while the Implementation worker is `working`, steer that active turn instead of waiting for a new turn:

```sh
bash <orc-impl-dir>/scripts/herdr-worker.sh steer \
  --pane <worker-pane-id> \
  --message "<concise added requirement>"
```

`steer` is valid only while the target is `working`. It submits through Herdr's Agent API without waiting for a state transition, because the message belongs to the active turn. Treat only `accepted: true`, `mode: "steer"`, and `status: "working"` as successful acceptance. The Implementation worker's next completion report must account for the steered requirement; the report and Owner verification establish implementation completion. Use `send`, not `steer`, to start initial work or a deterministic review-fix turn from `idle` or `done`.

The Implementation worker owns routine implementation decisions and the complete implementation work. Tickets remain execution units: finish and verify each ticket's acceptance criteria before advancing, without pausing for Owner acceptance. Follow the `implement` skill for repository work, verification, changed-LOC reporting, and commits.

The only allowed early report is a genuine blocker that cannot be resolved without user or Owner judgement. A blocker report must state the evidence checked, the exact decision required, and the Implementation worker's recommendation.

Only after the Implementation worker is observed as `working` does the Owner end the current turn.

## 4. Implementation worker Completion callback

When all tickets and final relevant checks are complete, the Implementation worker writes a Markdown report at a location it chooses. The report records completed acceptance criteria, commits, changed paths, test results, changed-LOC variance, and remaining concerns. The Implementation worker then sends its absolute path to the retained Owner pane ID:

```sh
bash <orc-impl-dir>/scripts/herdr-worker.sh send \
  --wait-ready \
  --pane <owner-pane-id> \
  --message "IMPL_COMPLETE: whole spec implemented and verified. Report: <absolute-markdown-path>"
```

`--wait-ready` waits until the Owner is `idle` or `done`, rechecks readiness to close the wait/prompt race, and only then submits through the verified Agent API. The Implementation worker must use the exact absolute helper path received in bootstrap and must not finish until the helper returns `accepted: true` with `status: working`. The accepted Completion callback is the completion signal; Herdr `idle` or `done` alone does not prove the whole spec is complete.

## 5. Review, triage, and finish

After the Completion callback, the Owner:

1. Reads the Implementation worker report and verifies the repository state against the pinned starting `HEAD` and every spec acceptance criterion.
2. Invokes `code-review` against that fixed point and the complete spec. Review the whole integrated diff only after the worker's full-spec report.
3. Triages review findings. Send deterministic fixes back to the same worker as one consolidated batch using `send --wait-ready`. End the owner turn again only after the helper confirms `accepted: true` and `status: working`, then wait for another explicitly accepted completion callback.
   If the user adds an in-scope requirement while that fix turn is already `working`, deliver it with `steer` and require the next Completion callback report to account for it.
4. Ask the user about every judgement call whose correct resolution depends on unresolved external usage, prior deployment, retained data, public compatibility, cutover, or product behaviour. State what was checked, recommend the simplest supported choice, and identify migration or compatibility code that can be removed if the user confirms it is unnecessary.
5. Repeat review after fixes until there are no merge blockers, or a real blocker or user decision remains.

The Owner owns triage, user decisions, final acceptance, and the final report. The Implementation worker owns implementation and deterministic review fixes.

After final acceptance, close only the Implementation worker tab created for this run. Preserve it when the run is blocked or failed until useful evidence is recovered or the user chooses to discard it.

At completion, report the starting commit, worker pane/tab, ticket and commit coverage, verification evidence, review iterations, judgement calls, changed-LOC variance, and remaining blockers.
