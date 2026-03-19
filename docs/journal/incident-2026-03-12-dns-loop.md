# Incident Report: MagicDNS Recursive Loop on VPS

**Date**: 2026-03-12
**Duration**: ~10 hours (undetected), ~30 minutes (active troubleshooting)
**Severity**: High — all DNS resolution broken on VPS, affecting phone exit node
**Services affected**: ntfy (push notifications), all `*.cronova.dev` resolution via VPS exit node

## Timeline (PYT)

| Time | Event |
|------|-------|
| ~11:45 | Headscale container restarts (cause unknown, possibly Watchtower or OOM) |
| ~11:45 | Tailscaled on VPS re-fetches DNS config, split DNS loop begins |
| ~11:45 | DNS request queue floods — all VPS DNS resolution fails |
| ~11:45–21:30 | Latent failure — undetected because SSH uses IPs, Caddy uses Docker DNS |
| 21:30 | User reports ntfy not working on phone |
| 21:35 | Investigation begins — ntfy container healthy, Caddy healthy |
| 21:38 | `curl <https://notify.cronova.dev`> from VPS returns 000 — DNS timeout |
| 21:40 | VPS `/etc/resolv.conf` points to `100.100.100.100` (MagicDNS) — all queries timeout |
| 21:42 | tailscaled logs: `dns: tcp query: request queue full` (thousands of dropped queries) |
| 21:45 | Root cause identified: split DNS `cronova.dev → 100.100.100.100` creates recursive loop |
| 21:50 | Fix applied: removed split DNS from headscale config |
| 21:52 | Headscale + tailscaled restarted |
| 21:53 | DNS resolution restored — ntfy 200 OK from VPS and Mac |
| 21:55 | Phone confirmed working |

## Root Cause

The headscale DNS configuration contained a split DNS route:

```yaml
dns:
  nameservers:
    global:
      - 1.1.1.1
      - 9.9.9.9
    split:
      cronova.dev:
        - 100.100.100.100  # MagicDNS
```

This told every Tailscale node: "resolve `*.cronova.dev` by querying `100.100.100.100`."

`100.100.100.100` is a virtual address handled by each node's **local** tailscaled process. On client nodes (Mac, phone), MagicDNS received the query, checked `extra_records`, and responded with the correct Tailscale IP. This worked fine.

On the **VPS**, MagicDNS received the query, matched the split DNS route for `cronova.dev`, and forwarded it to... `100.100.100.100` — itself. This created an infinite recursive loop:

```text
query cronova.dev → MagicDNS → split route → 100.100.100.100 → MagicDNS → split route → ...
```

The loop flooded tailscaled's internal DNS queue. Once the queue was full, **all** DNS queries failed — not just `cronova.dev`, but everything (`google.com`, etc.), because the single queue serves all DNS.

## Why It Wasn't Detected Sooner

1. **SSH uses IP addresses** — all SSH aliases resolve via `~/.ssh/config`, not DNS
2. **Caddy→ntfy uses Docker DNS** — `reverse_proxy ntfy:80` resolves via Docker's internal DNS, not system DNS
3. **Phone websocket** — ntfy app maintains a persistent connection; it doesn't need DNS until the connection drops
4. **No DNS monitoring** — Uptime Kuma checks `https://notify.cronova.dev` from the VPS, but VPS couldn't resolve the domain either, so the check itself was failing silently (or using a cached result)

The headscale restart ~10 hours before detection was the trigger. It caused tailscaled to re-establish its DNS configuration, activating the loop. Before that, tailscaled may have had a working cached state.

## Fix Applied

Removed the split DNS entry from headscale config (`/opt/homelab/headscale/config/config.yaml`):

```yaml
# Before
dns:
  nameservers:
    global:
      - 1.1.1.1
      - 9.9.9.9
    split:
      cronova.dev:
        - 100.100.100.100

# After
dns:
  nameservers:
    global:
      - 1.1.1.1
      - 9.9.9.9
```

**Why this works**: headscale's `extra_records` are served by MagicDNS directly — they are checked **before** any forwarding decision. A query for `vault.cronova.dev` hits MagicDNS, matches an `extra_record`, and returns the Tailscale IP immediately. No split DNS route is needed.

For domains without an `extra_record` (e.g., `notify.cronova.dev` when queried from a non-VPS node), the query falls through to the global nameservers (`1.1.1.1`), which return the VPS public IP. This is the correct behavior — the phone reaches ntfy via the public IP through Caddy.

**Verification after fix**:

- `dig notify.cronova.dev @100.100.100.100` → `<VPS_PUBLIC_IP>` (VPS public IP via global DNS)
- `dig vault.cronova.dev @100.100.100.100` → `100.68.63.168` (Tailscale IP via extra_records)
- `curl <https://notify.cronova.dev/`> → 200 OK (from VPS, Mac, and phone)

## Impact

- **Push notifications**: Dead for ~10 hours. Any alertmanager alerts during this window would have failed delivery to ntfy (alertmanager reaches ntfy via `https://notify.cronova.dev` through Caddy, which uses Docker DNS — actually would have worked). However, the phone couldn't receive them because the ntfy websocket was broken.
- **Phone internet**: All DNS on the phone (via VPS exit node) was broken. User likely noticed general connectivity issues beyond just ntfy.
- **No data loss**: No services were down, only DNS resolution was affected.

## Lessons Learned

1. **Never route split DNS to `100.100.100.100`** — this is a local virtual address, not a real server. On the node that runs headscale, it creates a recursive loop. Use split DNS only to point at real upstream resolvers (e.g., Pi-hole at `100.68.63.168`).

2. **`extra_records` don't need split DNS** — headscale's MagicDNS checks `extra_records` before forwarding. The split DNS route was entirely unnecessary.

3. **Exit nodes amplify DNS failures** — when the VPS is an exit node, its DNS breaks affect all clients using it. DNS health on exit nodes is critical.

4. **Add DNS health monitoring** — Uptime Kuma should have a DNS-specific check that verifies resolution works, not just HTTPS reachability. A monitor that runs `dig` from the VPS would have caught this immediately.

5. **Test config changes from the affected node** — the split DNS was tested from the Mac (where it worked) but never from the VPS (where it loops). Always test DNS changes from every node type, especially exit nodes.

6. **Headscale restarts can trigger latent issues** — any DNS config bug may lie dormant until headscale or tailscaled restarts. After DNS config changes, proactively restart tailscaled on all nodes and verify.

## Action Items

- [x] Remove split DNS from headscale config
- [x] Restart headscale + tailscaled on VPS
- [x] Verify extra_records still resolve correctly
- [x] Verify ntfy working from phone
- [x] Sync headscale config to repo (`96461e0`)
- [x] Add Uptime Kuma DNS resolution monitor — "DNS - cronova.dev (VPS)", queries 100.100.100.100 for notify.cronova.dev A record, 60s interval, Warning (ntfy) notification
- [ ] Consider adding a fallback resolver to VPS `/etc/resolv.conf` via systemd-resolved (so DNS survives MagicDNS failures)
- [ ] Add backup notification channel (email/Telegram) for when ntfy itself is unreachable
