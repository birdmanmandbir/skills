---
name: clash-config-maintenance
description: Use when maintaining or debugging Clash Verge Rev or Mihomo configuration, especially profile scripts, generated YAML, PAC or system proxy bypass, TUN and fake-IP, VPN route conflicts, Cloudflare Tunnel connectivity, rule order, reloads, or proxy-related 502 and timeout errors.
---

# Clash Config Maintenance

Treat configuration as three separate things:

1. the persistent source the user owns;
2. the generated or served artifact;
3. the live behavior.

Do not call a change complete until all three agree.

## Workflow

1. Read the nearest `AGENTS.md`.
2. Find the active client, mode, profile, ports, config directory, and running process. Do not assume the common macOS paths are in use.
3. Reproduce the fault and trace the request:

   application → PAC/system proxy/TUN → Mihomo rule → OS route or VPN → target

4. Identify the owner layer before editing:

   - shared profile transforms and rule order: persistent `profiles/Script.js`;
   - one subscription profile: its persistent profile helper;
   - PAC and app-level proxy settings: Clash Verge UI or persistent `verge.yaml`;
   - TUN, DNS, and fake-IP: their persistent source;
   - generated runtime YAML and downloaded subscriptions: inspect, but do not hand-edit.

5. Compare a failing request with a direct or bypassed request. Check active PAC, Mihomo logs, DNS result, rule match, and OS route as relevant.
6. Make the smallest persistent change. Preserve unrelated settings and comments.
7. Reload only the needed layer. A file edit is not a live change.
8. Inspect the regenerated or served artifact, then repeat the original request end to end.

## Keep These Distinctions Clear

- PAC `DIRECT` bypasses Clash. The OS may then send the request through OpenVPN.
- Mihomo `DIRECT` happens after traffic has entered Clash. It is not a substitute for a PAC bypass.
- In PAC mode, static system proxy exceptions may not affect a PAC function that always returns a proxy.
- A direct domain rule alone may be insufficient under fake-IP. Exclude infrastructure domains from fake-IP when they need real addresses.
- A proxy group set to `DIRECT` does not prove DNS, PAC, TUN, or an earlier rule uses the direct path.
- Fix the machine running the connector. A local Clash edit cannot repair a connector running in WSL or on a server.

## Safety

- Never dump subscription URLs, node credentials, access tokens, credential JSON, or full process arguments.
- Prefer narrow queries and redact output before showing it.
- Treat generated files as evidence, not sources of truth.
- For PAC templates, fetch the active PAC and confirm every placeholder was expanded. Do not assume placeholder support.
- State fail-open behavior when a PAC ends with `DIRECT`.

Read [references/clash-verge-rev.md](references/clash-verge-rev.md) for the layer map, diagnostic recipes, and verification checks.
