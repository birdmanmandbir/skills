---
name: dsh-plugin-ui
description: Build or review DeepSeek Harness web-plugin UI, including tool views and plugin settings, with native styling and theme integration.
---

# DeepSeek Harness Plugin UI

Use this skill for browser-facing DeepSeek Harness plugin UI: keyed tool views,
settings entries, image previews, dialogs, and other React surfaces. Do not use
it for non-UI host-side plugin behavior.

## Extension seams

- Register a per-tool renderer through the keyed `tool.call.toolview` slot.
  Handle both running and settled blocks; derive rendered state from the
  supplied durable block so replay works.
- Register plugin settings in the appropriate settings slot and keep the
  visual treatment consistent with the same theme rules.
- Use supported client services and declared `dsh.client.inject` dependencies.
  Do not reach into the host DOM or conversation implementation to replace an
  unrelated view.

## Native plugin settings cards

Treat DSH's current `PluginCard` behavior and `SettingsScope` contract as the
baseline even when the card is not exported as a reusable component.

- Do not render a settings card until its snapshot status is `ready`. When the
  snapshot is ready but not writable, disable writes and show a concise
  `role="status"` read-only explanation inside the expanded card.
- Keep a local draft and its saved baseline as separate state. A rejected or
  revision-conflicted `SettingsScope.set` reloads Host state; that reload must
  not overwrite a dirty draft. Clean fields follow new Host values. Reset a
  draft only after a successful write or an explicit Discard action.
- Match the native card structure: one list-item shell, a two-line header,
  chevron, body, and footer. Start collapsed, keep drafts while collapsed, mark
  unsaved work in the header, and collapse after a Host-confirmed successful
  save. Put shared Discard and Save actions in the footer instead of adding
  per-field controls or decorative sections.
- Keep the card spatially modest. Include only controls and concise guidance
  needed to operate them; omit plugin branding, banners, duplicate summaries,
  bespoke section chrome, and explanatory panels that make one plugin consume
  more space than native peers.
- Associate every field hint or validation message with its control using
  `aria-describedby`. Preserve native hover, keyboard-focus, disabled, error,
  and reduced-motion behavior for header and footer controls.
- Test observable state transitions: unavailable snapshots are hidden,
  read-only snapshots cannot write, failed or conflicted writes retain staged
  edits, clean snapshots follow external updates, and Discard restores the
  latest saved baseline.
- Compare the finished card directly with the current native card at the same
  viewport and theme in both collapsed and expanded states. Inspect computed
  geometry and state colours; matching tokens, an injected stylesheet, or
  generated class names are insufficient when presentation still differs.

## Styling

- Put component presentation in a co-located CSS Module and use its generated
  class names. Do not build a component's theme in React inline `style`
  objects.
- Use DSH semantic theme variables (`--dsw-alias-*`, `--dsw-specific-*`, and
  `--dsw-shadow-*`) for surfaces, borders, labels, interactive states, masks,
  and shadows. Confirm each variable used by a visible state exists in the
  target DSH version, because an unresolved custom property can silently expose
  browser defaults. Avoid literal light/dark colours and manual theme branching.
- Follow native interaction affordances: visible keyboard focus, sensible
  hover/disabled states, Escape and backdrop dismissal for modal previews,
  and `prefers-reduced-motion` for nonessential animation.
- Prefer DSH UI primitives and icons when they fit the need; do not recreate a
  generic control solely to alter its appearance.

## Client-bundle check

DSH loads the declared `./client` bundle; it does not fetch arbitrary CSS
sidecars. After styling a plugin, inspect the packed client artifact and verify
the stylesheet is injected with the client bundle. DSH's CSS Module build may
inject a plugin-owned `<style data-plugin-css>` when the client module is
evaluated; this matches native plugin UI and does not require an effect
disposer. If the package's build pipeline cannot inline a CSS Module, use a
narrowly scoped plugin stylesheet imported as `?inline`, insert it through
`ctx.effect`, and remove it in that effect's disposer. Do not add global theme
overrides for a single tool or settings card.

Use `dsh-plugin-verify` for packed, served, cold-browser, and live-deployment
checks; this skill defines the UI contract rather than the delivery workflow.

## Primary references

Use the current DSH source as the authority:

- `docs/web-styling.md` for the client styling contract.
- `packages/client/ui-skill/src/client/SkillRow.tsx` and
  `SkillRow.module.css` for a keyed tool-view CSS Module.
- `packages/client/ui-settings-plugins/src/client/PluginCard.tsx`, its CSS
  Module, and its field components for native settings-card state and styling.
- The `SettingsScope` contract and binder in
  `packages/client/ui-settings/src/client/settings-contract.ts` and
  `settings-scope.ts` for snapshot, write, rejection, and revision-refresh
  behavior.
- `packages/client/ui-attachment/src/ImageLightbox.tsx` and its CSS Module for
  image preview and lightbox behavior.
- `packages/client/ui-theme/src/client/styles.ts` only when a genuinely global
  plugin-owned stylesheet is needed.
