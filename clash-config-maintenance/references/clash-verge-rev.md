# Clash Verge Rev and Mihomo Reference

## Layer Map

| Concern | Persistent owner | Evidence only |
| --- | --- | --- |
| Shared rules, groups, profile DNS edits | `profiles/Script.js` | generated `clash-verge.yaml` |
| One profile's transform | profile-specific helper | generated profile output |
| PAC content and system proxy mode | UI or `verge.yaml` | PAC served by the local endpoint |
| TUN, DNS, fake-IP | persistent app/profile source | runtime YAML and logs |
| Subscription content | provider or subscription source | downloaded YAML |

On macOS, a common app directory is:

    $HOME/Library/Application Support/io.github.clash-verge-rev.clash-verge-rev

Discover the path and active profile instead of assuming them.

## Read-Only Discovery

Use narrow commands and redact their output:

    pgrep -afil 'clash|mihomo|clash-verge|cloudflared|openvpn'
    scutil --proxy
    route -n get <target-ip>
    curl -v --noproxy '*' <url>
    curl -v <url>

Inspect only the needed keys from YAML. Avoid printing proxy nodes, providers, subscription URLs, authentication fields, or cloudflared arguments.

## PAC and VPN Failures

Typical sign: a direct request works, but a browser in PAC mode gets 502 or times out.

Check in this order:

1. Confirm OpenVPN owns the target route.
2. Fetch the PAC currently served to macOS; do not rely only on its template.
3. Check whether the target host or subnet returns `DIRECT` before the general proxy return.
4. Check the request in the browser after refreshing the system proxy or restarting the app.
5. Confirm the bypassed request does not appear as a proxied request in Mihomo logs.

For an IP subnet, use an early `isInNet` test. One CIDR rule covers its member IPs; do not add redundant host rules.

PAC `DIRECT` means “leave Clash and let macOS route it.” A Mihomo `IP-CIDR,...,DIRECT` rule is too late when the request must bypass Clash to use the VPN route.

If the PAC proxy chain ends in `DIRECT`, it is fail-open: traffic connects without Clash when its proxy listeners are down. Record that tradeoff.

Ports and placeholders vary by app version. `%mixed-port%` may expand while another placeholder does not. After reload, fetch the active PAC and reject it if `%...%` remains or the listener is wrong.

## Cloudflare Tunnel and Fake-IP

Tunnel edge discovery commonly uses `argotunnel.com` and `cftunnel.com`. If Mihomo returns an address from its fake-IP range, cloudflared may cache the fake edge and report TLS EOF or no free edge addresses.

The durable fix normally needs both:

- fake-IP exclusions for `+.argotunnel.com` and `+.cftunnel.com`;
- early direct suffix rules for `argotunnel.com` and `cftunnel.com`.

After regenerating the config:

1. verify both exclusions and rules exist in the live YAML;
2. resolve an edge discovery hostname and reject fake-IP results;
3. check the route to the real address;
4. restart cloudflared only if stale addresses may be cached;
5. confirm stable connector sessions in redacted logs.

Do not expose tunnel tokens from process arguments or credential files.

## Rule and Reload Checks

Rule order is behavior. Put narrow infrastructure and LAN/VPN exceptions before broad proxy rules, then inspect the generated order.

After any change:

1. run the syntax or parser check suitable for the source, such as `node --check` for JavaScript;
2. reload the profile, core, PAC, or app layer that owns the change;
3. inspect the generated YAML or served PAC;
4. confirm the expected listener, DNS answer, rule hit, and route;
5. repeat the user's original request.

Do not use a successful syntax check as proof that traffic follows the intended path.
