---
name: dsh-plugin-dev
description: "Build or review packaged DeepSeek Harness plugins: Cordis Host behavior, bundle manifests and patches, tools, settings, credentials, RPC, lifecycle, and packaging. Use dsh-plugin-ui for browser-facing UI and dsh-plugin-verify for artifact, Loader, deployment, or live verification."
---

# DSH Plugin Development

Use this skill for installable DSH packages loaded through `dsh plugin` and a
Cordis bundle patch. It covers the Host and shipping contract. For tool views,
settings cards, React surfaces, styling, or other browser UI, also load
`dsh-plugin-ui` and keep those decisions there.

## Establish the contract

1. Resolve the target checkout and `deepseek-harness` through the project
   registry. Read the target lockfile and package manifest before choosing a
   package manager or DSH version family.
2. Inspect the exact current DSH docs, types, and an in-box implementation for
   every service, event, tool, RPC, or package field the plugin will use. Treat
   the four known plugins as worked examples, not API authority; read
   [references/known-plugins.md](references/known-plugins.md) only for the
   relevant capability.
3. Decide the data owner and the narrow extension seam. Keep `apply()` as
   wiring around independently testable domain logic. Build the first slice all
   the way through package, patch, Host activation, and an observable check.

Useful current DSH references include:

- `apps/cli/reference/README.md` for profile composition and `dsh plugin`;
- `docs/cordis-primer.md` and `docs/user/develop/framework/` for dependencies,
  effects, and events;
- `docs/subsystems/{tools,settings,credentials}.md` for Host contracts;
- `docs/user/develop/basic/` for the supported package shape.

## Package and composition

- Export a namespace plugin through named `name`, `inject`, and `apply`
  exports. A namespace plugin must not default-export the bare `apply`
  function: the real Loader prefers the default and would discard sibling
  metadata such as `inject`.
- Declare hard service dependencies in both the exported `inject` list and the
  inserted Cordis row. Read a truly optional service through `ctx.get(name)`;
  direct `ctx.<name>` access belongs to declared injections.
- Give the package a root Host export and declare
  `dsh.bundle.patch: "./cordis.patch.yml"`. Export and ship the patch itself.
  Add `./client` and `dsh.client` only when the plugin actually has a browser
  client; use `dsh-plugin-ui` for that branch.
- Keep the bundle patch narrow: normally insert one stable, namespaced row with
  the package name and exact injections. Patch an existing row only when the
  plugin intentionally replaces it. A patch replaces a targeted row's complete
  `config`; later profile and home layers override bundle layers.
- Pin one compatible DSH contract family across Host-provided peer and dev
  dependencies. Keep Cordis, React, and DSH packages external to built output.
  Bundle plugin-owned workspace libraries or ship ordinary runtime
  dependencies deliberately; prove the selected form from the packed artifact.
- Do not rely on a consumer workspace, `workspace:` ranges, undeclared files,
  stale local builds, or a globally installed dependency.

## Host behavior

### Lifecycle and state

- Install registrations through Cordis-owned APIs such as `ctx.on()`, service
  `register()` methods, and `ctx.effect()`. An external subscription, route,
  process, watcher, or other resource must return a disposer owned by the
  plugin fiber.
- Keep order-dependent cleanup in one effect and await it serially. Respect
  caller `AbortSignal`s in network, file, subprocess, and long-running work.
- Scope mutable state to the plugin instance or another explicit owner. Session
  maps, queues, caches, and in-flight work need cleanup on both session disposal
  and plugin unload; module-level state otherwise survives reloads.
- Define the failure role. Supplementary capabilities may fail open with a
  bounded fallback; requested tools and mutations should fail explicitly with
  safe, actionable errors. Do not leak secrets or raw provider responses.

### Settings and credentials

- Put user-editable, non-secret values in one validated lowercase kebab-case
  settings namespace. Composition config stays in the Cordis patch rather than
  being copied into settings.
- Use schema defaults for product defaults and `base` for deployment-owned
  values. Declare `applies: "live"` only when operations read the current scope
  or a registered watcher updates runtime state; otherwise use restart
  semantics.
- Use `credentialRef()` for secrets and resolve the credential for each
  operation so rotation reaches the next request. Never cache credential
  values, place them in settings, materialize them into `process.env`, return
  them over RPC, or log them.

### Tools, RPC, and files

- Prefer `defineTool()` with a closed, narrow input schema and a canonical
  output schema. `execute` returns the canonical value; `output.render`
  separately produces durable model-facing content. Validate untrusted input
  again at external boundaries where size, path, media, or cross-field rules
  exceed the schema.
- Propagate cancellation and set a timeout appropriate to the operation. Keep
  model-visible descriptions precise about when the tool should be called and
  what it changes.
- For Client-to-Host work, use a package-owned RPC channel and the narrowest
  available authority. Validate every payload and return a bounded structured
  result. Resolve settings and credentials on the Host at admission time.
- Derive workspace identity from the live Host session, not a client-supplied
  directory. Resolve relative paths through the DSH filesystem seam, verify
  containment after resolution, require expected file types and bounded byte
  counts, and write outputs atomically under a plugin-owned `.dsh/<id>/`
  directory when persistence is appropriate.
- A same-origin artifact route should accept an opaque bounded identifier,
  re-resolve its session/workspace server-side for every request, restrict
  methods and media type, and never become an arbitrary path or URL reader.

## Delivery verification

Load `dsh-plugin-verify` before claiming a new or materially changed plugin is
ready, installing it, deploying it, diagnosing Loader activation, or handing a
live UI to the user. That skill owns packed-path, real-Loader, client-bundle,
and live-link completion criteria.
