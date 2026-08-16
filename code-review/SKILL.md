---
name: code-review
description: Review a branch or work-in-progress diff against the repository's default branch, or an explicit fixed point, along separate Standards and Spec axes; then assess how far it is from merge.
---

Two-axis review of the diff between `HEAD` and the repository's default branch, unless the user supplies another fixed point:

- **Standards** — does the code conform to this repo's documented coding standards?
- **Spec** — does the code faithfully implement the originating issue / spec?

Both axes run as **parallel sub-agents** so they don't pollute each other's context, then this skill aggregates their findings.

The issue tracker should have been provided to you — run `/setup-matt-pocock-skills` if `docs/agents/issue-tracker.md` is missing.

## Process

### 1. Pin the fixed point

Use a fixed point the user explicitly supplied. Otherwise review against the repository's default branch.

Resolve the default branch from the current branch's remote (falling back to `origin`) and its remote `HEAD`:

```sh
remote=$(git config --get "branch.$(git branch --show-current).remote" || printf '%s\n' origin)
git symbolic-ref --quiet --short "refs/remotes/$remote/HEAD"
```

The result, such as `origin/main`, is the fixed point. If that local symbolic ref is absent, query the remote with `git ls-remote --symref "$remote" HEAD`, fetch the reported branch, and use `<remote>/<branch>`. If the repository has no remote, use local `main` or `master` when one exists; ask the user only when no default can be discovered.

Capture the diff command once: `git diff <fixed-point>...HEAD` (three-dot, so the comparison is against the merge-base). Also note the list of commits via `git log <fixed-point>..HEAD --oneline`.

Before going further, confirm the fixed point resolves (`git rev-parse <fixed-point>`) and the diff is non-empty. A bad ref or empty diff should fail here — not inside two parallel sub-agents.

### 2. Identify the spec source

Look for the originating spec, in this order:

1. Issue references in the commit messages (`#123`, `Closes #45`, GitLab `!67`, etc.) — fetch via the workflow in `docs/agents/issue-tracker.md`.
2. A path the user passed as an argument.
3. A spec file under `docs/`, `specs/`, or `.scratch/` matching the branch name or feature.
4. If nothing is found, ask the user where the spec is. If they say there isn't one, the **Spec** sub-agent will skip and report "no spec available".

### 3. Identify the standards sources

Anything in the repo that documents how code should be written, such as `CODING_STANDARDS.md` or `CONTRIBUTING.md`.

On top of whatever the repo documents, the Standards axis always carries the **smell baseline** below — a fixed set of Fowler code smells (_Refactoring_, ch.3) that applies even when a repo documents nothing. Two rules bind it:

- **The repo overrides.** A documented repo standard always wins; where it endorses something the baseline would flag, suppress the smell.
- **Always a judgement call.** Each smell is a labelled heuristic ("possible Feature Envy"), never a hard violation — and, like any standard here, skip anything tooling already enforces.

Each smell reads *what it is* → *how to fix*; match it against the diff:

- **Mysterious Name** — a function, variable, or type whose name doesn't reveal what it does or holds. → rename it; if no honest name comes, the design's murky.
- **Duplicated Code** — the same logic shape appears in more than one hunk or file in the change. → extract the shared shape, call it from both.
- **Feature Envy** — a method that reaches into another object's data more than its own. → move the method onto the data it envies.
- **Data Clumps** — the same few fields or params keep travelling together (a type wanting to be born). → bundle them into one type, pass that.
- **Primitive Obsession** — a primitive or string standing in for a domain concept that deserves its own type. → give the concept its own small type.
- **Repeated Switches** — the same `switch`/`if`-cascade on the same type recurs across the change. → replace with polymorphism, or one map both sites share.
- **Shotgun Surgery** — one logical change forces scattered edits across many files in the diff. → gather what changes together into one module.
- **Divergent Change** — one file or module is edited for several unrelated reasons. → split so each module changes for one reason.
- **Speculative Generality** — abstraction, parameters, or hooks added for needs the spec doesn't have. → delete it; inline back until a real need shows.
- **Message Chains** — long `a.b().c().d()` navigation the caller shouldn't depend on. → hide the walk behind one method on the first object.
- **Middle Man** — a class or function that mostly just delegates onward. → cut it, call the real target direct.
- **Refused Bequest** — a subclass or implementer that ignores or overrides most of what it inherits. → drop the inheritance, use composition.

### 4. Select reviewer models and spawn both sub-agents in parallel

Call `tools.models()` and resolve the exact currently available keys before spawning. Prefer direct providers; use OpenRouter only when the user explicitly requests it or a required direct route is unavailable. Never silently fall back to an unrelated configured model.

Model size is not a review-quality ordering. Use independent contexts, narrow evidence, and a task-appropriate reviewer rather than automatically choosing a model far stronger than the coder. Apply this default policy:

| Change risk | Standards reviewer | Spec reviewer |
| --- | --- | --- |
| Normal | `deepseek/deepseek-v4-flash`, thinking `high` | `openai-codex/gpt-5.6-luna`, thinking `high` |
| High | `openai-codex/gpt-5.6-luna`, thinking `high` | `openai-codex/gpt-5.6-terra`, thinking `high` |

Treat a change as high risk when it materially changes authentication or authorization, owner isolation, money, persistence or migrations, transactions, concurrency, queues or delivery guarantees, state machines, cross-runtime contracts, or a broad architectural execution path. Make this technical classification yourself. A large diff alone raises review difficulty but does not automatically justify stronger models; first narrow the evidence supplied to each reviewer.

Use fresh `agents.run` contexts for both axes. Do not use an actor or handoff: independence from the implementer and from the other axis is part of the review design. Run the two calls in parallel. If the requested direct model is unavailable, report that blocker rather than substituting an unconfigured provider.

**Standards sub-agent prompt** — include:

- The full diff command and commit list.
- The list of standards-source files you found in step 3, **plus the smell baseline from step 3** pasted in full — the sub-agent has no other access to it.
- The brief: "Report — per file/hunk where relevant — (a) every place the diff violates a documented standard: cite the standard (file + the rule); and (b) any baseline smell you spot: name it and quote the hunk. Distinguish hard violations from judgement calls — documented-standard breaches can be hard, but baseline smells are always judgement calls, and a documented repo standard overrides the baseline. Skip anything tooling enforces. Under 400 words."

**Spec sub-agent prompt** — include:

- The diff command and commit list.
- The path or fetched contents of the spec.
- The brief: "Report: (a) requirements the spec asked for that are missing or partial; (b) behaviour in the diff that wasn't asked for (scope creep); (c) requirements that look implemented but where the implementation looks wrong. Quote the spec line for each finding. Under 400 words."

If the spec is missing, skip the Spec sub-agent and note this in the final report.

**Focused adjudication** — do not run a third full review or ensemble reviewers. When a potential merge blocker remains materially uncertain, first use deterministic evidence when available. If model judgement is still required, send only that finding, its cited hunk, the governing requirement, and relevant test evidence to `openai-codex/gpt-5.6-terra` at thinking `high`. Keep the result under the finding's original axis; adjudication confirms or rejects evidence and never reranks Standards against Spec.

### 5. Aggregate

Present the two reports under `## Standards` and `## Spec` headings, verbatim or lightly cleaned. Keep the axes separate so neither masks the other.

Then add `## Merge readiness` and answer: **How far is this version from merge?** Use the user's language and this structure:

```text
My assessment

- Merge blockers: <count and concise severity/behaviour summary, or none>
- Recommended reinforcement: <valuable non-blocking work, especially representative tests, or none>
- Estimated effort: <one focused iteration / several focused iterations / substantial work>
- Path to merge: <what to fix and the exact repository checks/builds to rerun before PR or merge>

Approximately <range>% complete.
```

Keep blockers separate from recommended reinforcement. Name repository-specific verification commands when they are discoverable, rather than writing a generic “run tests.” Use a narrow percentage range, normally five points, as a directional completion estimate rather than false precision. Calibrate it from remaining risk and work:

- **95–100%** — ready or only final verification remains.
- **85–95%** — a focused iteration of small fixes or representative tests remains.
- **70–85%** — several bounded changes remain.
- **Below 70%** — core behaviour or substantial correctness, security, data, or design work remains.

A judgement-call smell is not automatically a blocker; place it under recommended reinforcement unless it materially affects safe or correct merging.

End with a one-line count of findings per axis and the worst issue within each axis, if any.

## Why two axes

A change can pass one axis and fail the other:

- Code that follows every standard but implements the wrong thing → **Standards pass, Spec fail.**
- Code that does exactly what the issue asked but breaks the project's conventions → **Spec pass, Standards fail.**

Reporting them separately stops one axis from masking the other.
