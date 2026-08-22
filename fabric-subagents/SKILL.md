---
name: fabric-subagents
description: Use when delegating work to Pi Fabric subagents, choosing common direct model routes, preserving the current trajectory, continuing a live agent, creating a resumable agent, or recovering a failed agent run.
---

# Fabric Subagents

Delegate with the right **context topology** before choosing a model. A Git branch preserves files; it does not preserve model context.

## 1. Resolve the model route

Call `tools.models()` at the start. Match the user's requested model to an exact current key; never infer a key from its display name.

Prefer first-party/direct providers over OpenRouter when both expose the requested model:

| User wording | Preferred key | Thinking |
| --- | --- | --- |
| Luna / Luna Max | `openai-codex/gpt-5.6-luna` | `max` for “Max”; otherwise `high` |
| Sol / Sol Max | `openai-codex/gpt-5.6-sol` | `max` for “Max”; otherwise `high` |
| Terra / Terra Max | `openai-codex/gpt-5.6-terra` | `max` for “Max”; otherwise `high` |
| DeepSeek Flash | `deepseek/deepseek-v4-flash` | `high` |
| DeepSeek Pro | `deepseek/deepseek-v4-pro` | `high` |

Use `openrouter/...` only when the user requests OpenRouter, the requested variant exists only there, or the direct route is unavailable. “Max” normally means reasoning effort, not an OpenRouter `-pro` model.

Report the exact key used and whether it is direct or routed through OpenRouter.

## 2. Choose the context topology

### Continue Main's exact trajectory: `agents.handoff`

Use this when the user says “continue,” asks another model to implement work already discussed, or the current conversation contains important discovery and decisions. The child receives a fork of Main's real Pi trajectory rather than a task-summary-only fresh context.

```ts
await agents.handoff({
  name: "implement-feature",
  model: "openai-codex/gpt-5.6-luna",
  thinking: "max",
  task: "Continue from the current context and implement the approved spec.",
});
return "handoff scheduled";
```

A handoff is blocking at the completed outer `fabric_exec` boundary. Do not mutate the same files after scheduling it. Use `compact` only when the inherited trajectory is too large and a bounded summary is safer than the raw branch.

### Independent one-shot: `agents.run`

Use for an isolated review, research task, or implementation whose full context fits in a self-contained task prompt. Every `agents.run` starts a fresh model context.

```ts
const result = await agents.run({
  name: "standards-review",
  model: "openai-codex/gpt-5.6-luna",
  thinking: "high",
  task: "Review the fixed diff against the listed standards. Do not edit.",
  tools: ["read", "grep", "find", "ls", "bash"],
});
return result;
```

Do not call a second `agents.run` and describe it as a resumed agent. It is a new context even when it reuses the same working tree or branch.

### Background one-shot: `agents.spawn`

Use when Main has independent work to do while the child runs. Use `agents.wait({ id })` for the result. While it is live, redirect it with `agents.steer` or queue its next turn with `agents.followUp` instead of replacing it.

Set `residency: "durable"` only when the run must survive the current Pi host shutting down. After the same root resumes, use `agents.status`, `agents.wait`, or `agents.log` on the durable handle. This resumes observation/control of the run; it does not turn a terminal one-shot into a new contextual turn.

### Resumable multi-turn specialist: actor

Use `agents.create` when later messages must retain the specialist's model context. Pi actors keep a Fabric-owned Pi session across activations; communicate through `agents.ask` or `agents.tell`.

```ts
const actor = await agents.create({
  name: "implementation-owner",
  runner: "pi",
  model: "openai-codex/gpt-5.6-luna",
  thinking: "max",
  instructions: "Own this implementation across review and remediation turns.",
  responseMode: "text",
  delivery: "mailbox",
  triggerTurn: false,
});

await agents.tell({ id: actor.id, message: "Implement the approved spec." });
const reply = await agents.ask({ id: actor.id, message: "Now remediate these review findings." });
return reply;
```

Use `residency: "durable"` when that actor must retain ownership across Main restarts. Remove the actor when the work is finished.

## 3. Delegate implementation correctly

Use these implementation profiles:

- **Spec/ticket implementation:** default to a fresh blocking `agents.run` in the current clean workspace. The spec and tickets are the context boundary; Main verifies the returned commit and evidence.
- **Trajectory continuation:** use `agents.handoff` only when the user asks another model to continue Main's work or consequential decisions remain outside the spec/tickets.
- **Parallel ticket frontier:** use concurrent `agents.run({ worktree: true })` calls only for independently verifiable tickets with explicit disjoint write ownership. Main integrates and verifies their commits; a shared frontier alone does not prove parallel safety.

For the complete multi-ticket dispatch, integration, cleanup, and frontier loop, use `/Users/neil/.agents/skills/orchestrate-implementation/SKILL.md`.

For every delegated implementation:

1. Pin the starting branch/commit and confirm a clean tracked worktree.
2. Point to the project-local spec or tickets.
3. Require the agent to read and follow `/Users/neil/.agents/skills/implement/SKILL.md`.
4. State the branch/PR boundary, write ownership, required checks, and whether deployment is excluded.
5. Let the implementer make routine technical decisions; ask only about unresolved user-facing tradeoffs.
6. Require observable verification, changed paths, and a final commit SHA.

A worktree isolates files, not credentials, processes, network access, or external services.

## 4. Recover without losing context

On failure, distinguish the failure before retrying:

- **Live agent:** inspect `agents.status`/`agents.log`, then use `steer` or `followUp`.
- **Durable run after Main restart:** use `status`/`wait`; do not spawn a duplicate.
- **Actor activation failure:** send the next message to the same actor so its persisted session continues.
- **Handoff failure:** Main still owns its original trajectory; fix the cause and hand off again.
- **Terminal `agents.run` failure:** the public one-shot API does not resume that finished context. Start a fresh run with a concise evidence-based handoff, or use an actor for work that needs future resumability.

Never equate these:

- same Git branch = same filesystem state
- same actor = same model context
- new `agents.run` = new context
- durable handle = run survives/reconnects across Main restart

## 5. Report provenance

At completion, report:

- exact model key and provider route
- topology used: handoff, run, spawn, or actor
- whether context was inherited, fresh, live-continued, or actor-resumed
- branch/worktree and commit state
- verification evidence
- provider/transport failures and whether any retry used a new context
