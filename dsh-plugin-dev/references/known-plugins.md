# Known packaged DSH plugins

Use these repositories as secondary examples after checking the current
`deepseek-harness` contract. Resolve each alias with the project tool instead
of assuming a path.

## `web`

Package: `@guionai/dsh-web` under `packages/dsh-web`.

Read it for:

- replacing one stock Web provider row while leaving the rest of the profile
  intact;
- registering a Web provider and model-facing tools over a shared core;
- resolving provider credentials per operation;
- packed-artifact tests that import the shipped Host entry and exercise tools
  with faked Host packages.

## `kepos-hindsight`

Package: `@lamplitisles/kepos-hindsight`.

Read it for:

- agent lifecycle events and waterfall delegation;
- best-effort recall versus awaited retain behavior;
- serializing per-session background writes and handling idempotency;
- a settings-backed adapter that intentionally replaces one stock row.

Audit mutable session maps especially carefully: the desired reusable rule is
explicit plugin/session ownership and cleanup, not merely copying the current
module layout.

## `kepos-imagegen`

Package: `@lamplitisles/dsh-imagegen` under `packages/dsh-imagegen`.

Read it for:

- a typed tool with canonical output plus durable attachment rendering;
- workspace-relative path resolution, post-resolution containment, media
  signatures, and request byte budgets;
- persisting a generated artifact under `.dsh/` while also registering a DSH
  attachment;
- packing a workspace-owned core into a standalone consumer artifact.

## `kepos-tts`

Package: `@lamplitisles/kepos-tts`.

Read it for:

- trusted Host RPC with per-call settings and credential resolution;
- deterministic, bounded workspace caches and atomic publication;
- a same-origin route that re-resolves session workspace and admits only a
  digest-shaped identifier;
- an end-to-end pack smoke test that installs into a disposable `DSH_HOME`,
  boots real DSH Web, and probes Host activation.

## Boundary with `dsh-plugin-ui`

The packages also contain Client bundles, settings cards, tool views, media
players, and CSS packaging. Those are references for `dsh-plugin-ui`, not this
skill. This skill owns only the Host-to-Client contract, manifest declaration,
RPC/route security, and proof that the declared Client artifact is shipped.
