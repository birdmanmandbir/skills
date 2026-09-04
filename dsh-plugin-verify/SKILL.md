---
name: dsh-plugin-verify
description: Verify or deploy a packaged DeepSeek Harness plugin through its real artifact, Cordis Loader, client bundle, link installation, live service, or browser UI. Use for release smoke checks, installation failures, live NUC deployment, or claims that a DSH plugin is ready for human testing; use dsh-plugin-dev and dsh-plugin-ui for implementation decisions.
---

# DSH Plugin Verification

Verify the path the user will actually run. A unit-mounted `{ name, inject,
apply }` object proves domain behavior; it does not prove package exports,
bundle reconciliation, Loader metadata, client assembly, CSS, or deployment.

## Set the boundary

- For ordinary implementation verification, use a packed artifact, a
  disposable `DSH_HOME`, fake providers, and test-owned credentials. Leave the
  user's profiles, sessions, credential store, installed executables, and
  services untouched.
- Touch a live profile or service only when the user asks for deployment or
  verification of that named environment. Resolve the exact `DSH_HOME`,
  profile, service, and source checkout before mutation.
- Treat live smoke checks as operations, not tests. Never enter, print, return,
  or capture a secret. If the user will supply credentials, finish at a usable
  settings surface and report the expected incomplete-configuration state.
- Redact launch URLs, cookies, authorization headers, credential values, HAR
  files, and screenshots containing secrets from tool output and reports.

## Prove artifact identity

1. Read the target lockfile, package manifest, DSH profile docs, and the live
   service definition when deployment is in scope.
2. Build before installing or restarting. Record the source checkout and prove
   the served package resolves to that checkout or to the newly packed
   artifact; do not infer freshness from a successful command.
3. Inspect the publishable tarball for the manifest, Host entry, declarations,
   Cordis patch, client entry, and intended runtime dependency closure.

Completion criterion: the artifact under test is exact, current, and
independent of an undeclared consumer workspace or global dependency.

## Exercise the real Loader

1. Install the tarball into a disposable profile and inspect the reconciled
   config with the current DSH CLI.
2. Activate the plugin through the real Loader. Assert its package export
   unwrapping, Cordis row, and every direct service access: `ctx.foo` requires
   `foo`; `ctx.remote.bar` requires both `remote` and `remote.bar`.
3. Exercise one headline Host behavior without a model or real secret when
   feasible, then unload it and confirm owned resources stop.

Completion criterion: the real Loader activates the declared row and the
observable Host behavior succeeds from the installed artifact.

## Verify a browser client

Host success does not prove Client success. In a served browser build:

1. Assert the plugin client request succeeds and the page contains no plugin
   Loader failure. Confirm the expected slot contribution appears.
2. Confirm the plugin stylesheet is present and its generated class selectors
   match the DOM. A style tag or class name alone is not a visual pass.
3. Start a cold, isolated browser session after the final service restart.
   Reusing a page across restarts can preserve stale slot or connection state.
4. For settings cards, capture and inspect both collapsed and expanded states
   beside a current native card at the same viewport and theme. Check default
   collapse, one card shell, two-line header, chevron, field density, footer,
   focus/disabled/error states, and reduced motion.
5. Compare the few computed properties that carry the native geometry, such
   as display, padding, height, radius, font size, and border colour. Confirm
   every semantic CSS variable used by a visible state resolves in the target
   DSH version; an undefined custom property can silently restore browser
   defaults.

Completion criterion: a cold browser loads the contribution without error and
the relevant collapsed, expanded, and stateful UI matches the current native
surface in structure and computed presentation.

## Verify an authorized live link deployment

1. Use the repository's and DSH CLI's documented `link:` installation path.
   Prove the installed package symlink resolves to the intended checkout.
2. Restart the exact documented service after the production build. Wait on a
   bounded readiness signal and confirm the process remains active.
3. Repeat the real Host and cold-browser checks against the live service. A
   `missing-settings` or `missing-credential` readiness result is acceptable
   only when the settings UI is usable and the user intentionally owns the
   remaining configuration.
4. Report the exact observable state the user can verify next. Do not call a
   deployment complete while the UI is absent, the Loader reports an error, or
   only an unauthenticated/static endpoint has responded.

Completion means the intended live profile resolves the intended build, the
service is healthy, the Host and Client both load through their real paths, and
the user's next manual action is possible without another deployment repair.
