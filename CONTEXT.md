# Skill workspace

Language for the Owner–Implementation worker workflow provided by `orc-impl`.

## ORC roles

**Owner**:
The interactive agent that starts an ORC run, accepts its result, and owns review,
triage, and user decisions.
_Avoid_: orchestrator worker, implementation agent

**Implementation worker**:
The separate Codex agent that executes one complete spec and reports its result
to its Owner. It owns implementation and deterministic fixes, not orchestration.
_Avoid_: orchestrator, owner, nested worker

**Completion callback**:
The Implementation worker's final message to its Owner that identifies the
implementation report and signals completed work. It is the worker's only
coordination action.
_Avoid_: handoff, status message
