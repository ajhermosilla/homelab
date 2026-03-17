# Incident Report: Uptime Kuma Monitors All Down

**Date**: 2026-03-13
**Duration**: ~5 days (undetected), ~30 minutes (active troubleshooting)
**Severity**: Medium — monitoring blind spot, no alerting for actual outages
**Services affected**: All 10+ Uptime Kuma monitors showing DOWN despite services being healthy

## Timeline (PYT)

| Time | Event |
|------|-------|

| ~Mar 7 | Uptime Kuma and ntfy containers started on VPS. Host `resolv.conf` pointed to `100.100.100.100` (MagicDNS). Docker embedded DNS cached this as `ExtServers: [host(100.100.100.100)]` |
| Mar 12 ~21:50 | DNS incident fix: `accept-dns=false` applied, host `resolv.conf` changed to `127.0.0.1` (AdGuard). Headscale, Caddy, AdGuard containers restarted — but Uptime Kuma and ntfy were NOT restarted |
| Mar 12 ~21:50 | Uptime Kuma container retains stale `ExtServers: [host(100.100.100.100)]`. All hostname-based monitors begin failing silently |
| Mar 13 ~10:30 | User notices all Uptime Kuma monitors showing DOWN with ~11-14% uptime |
| Mar 13 ~10:35 | Investigation: VPS containers all healthy, DNS resolves from host, headscale/ntfy respond 200 from host |
| Mar 13 ~10:40 | Container `resolv.conf` inspected: `ExtServers: [host(100.100.100.100)]` — stale MagicDNS upstream |
| Mar 13 ~10:42 | `docker restart uptime-kuma` — ExtServers updates to `[host(127.0.0.1)]` (AdGuard) |
| Mar 13 ~10:43 | VPS-local monitors recover (cronova.dev, headscale, ntfy, hermosilla.me → 200) |
| Mar 13 ~10:45 | Internal `*.cronova.dev` monitors still failing — `vault.cronova.dev` → `ENOTFOUND` |
| Mar 13 ~10:50 | Root cause 2 identified: AdGuard has no DNS rewrites for internal hostnames. These only exist in headscale extra_records (MagicDNS), not in public DNS |
| Mar 13 ~10:55 | 18 DNS rewrites added to AdGuard config for all internal `*.cronova.dev` → Tailscale IPs |
| Mar 13 ~10:57 | Rewrites not working — AdGuard auto-set `enabled: false` on each entry |
| Mar 13 ~11:00 | Fixed to `enabled: true`, AdGuard restarted, Uptime Kuma restarted |
| Mar 13 ~11:02 | All reachable monitors confirmed green (vault, jara, taguato, git → 200) |

## Root Cause

Two independent issues compounded to create a complete monitoring blind spot:

### Cause 1: Stale Docker DNS cache

Docker's embedded DNS (`127.0.0.11`) caches the host's upstream DNS servers (`ExtServers`) at container startup and **never refreshes them**. When the VPS host's `resolv.conf` was changed from `100.100.100.100` (MagicDNS) to `127.0.0.1` (AdGuard) during the Mar 12 DNS incident fix, the Uptime Kuma container kept the old MagicDNS upstream.

MagicDNS on the VPS (with `accept-dns=false`) forwards to the headscale global nameservers:

1. `100.68.63.168` (Docker VM Pi-hole) — returns LAN IPs unreachable from VPS
2. `1.1.1.1` (Cloudflare fallback)

This intermittent/broken resolution caused all hostname-based monitors to fail with connection timeouts.

```text
Container: 127.0.0.11 → 100.100.100.100 (MagicDNS, stale)
                              ↓
                    100.68.63.168 (Pi-hole)
                              ↓
                    192.168.0.10 (LAN IP) ← unreachable from VPS
                              ↓
                         TIMEOUT → monitor DOWN
```

### Cause 2: Internal hostnames not in public DNS

After fixing Cause 1, monitors checking `*.cronova.dev` internal services (vault, jara, taguato, etc.) still failed with `ENOTFOUND`. These hostnames only exist in headscale `extra_records`, which are served by MagicDNS to Tailscale clients. The VPS, with `accept-dns=false`, uses AdGuard → Unbound → root servers for DNS — a fully public resolution path that has no knowledge of internal records.

```text
Container: 127.0.0.11 → 127.0.0.1 (AdGuard, correct)
                              ↓
                    Unbound → root servers
                              ↓
                    vault.cronova.dev → NXDOMAIN (no public record)
                              ↓
                         ENOTFOUND → monitor DOWN
```

## Impact

- **Monitoring gap**: ~5 days with zero working monitors. If any service had actually gone down, there would have been no alert via ntfy.
- **False perception**: Dashboard showed everything red, making it impossible to distinguish real failures from monitoring failures.
- **No alerting about the monitoring failure itself**: Uptime Kuma has no meta-monitoring to detect when its own checks are broken.

## Fix Applied

### Fix 1: Container restart

```bash
docker restart uptime-kuma
```

Updated `ExtServers` from stale `100.100.100.100` to current `127.0.0.1` (AdGuard).

### Fix 2: AdGuard DNS rewrites

Added 18 DNS rewrites to `/var/lib/docker/volumes/adguard-conf/_data/AdGuardHome.yaml` matching all headscale `extra_records`:

| Domain | Answer (Tailscale IP) |
|--------|----------------------|

| vault.cronova.dev | 100.68.63.168 |
| jara.cronova.dev | 100.68.63.168 |
| taguato.cronova.dev | 100.68.63.168 |
| auth.cronova.dev | 100.68.63.168 |
| yrasema.cronova.dev | 100.68.63.168 |
| papa.cronova.dev | 100.68.63.168 |
| vera.cronova.dev | 100.68.63.168 |
| ysyry.cronova.dev | 100.68.63.168 |
| kuatia.cronova.dev | 100.68.63.168 |
| mbyja.cronova.dev | 100.68.63.168 |
| japysaka.cronova.dev | 100.68.63.168 |
| taanga.cronova.dev | 100.68.63.168 |
| aoao.cronova.dev | 100.68.63.168 |
| aranduka.cronova.dev | 100.68.63.168 |
| git.cronova.dev | 100.68.63.168 |
| javya.cronova.dev | 100.82.77.97 |
| javya-api.cronova.dev | 100.82.77.97 |
| tajy.cronova.dev | 100.82.77.97 |

Each rewrite required explicit `enabled: true` — AdGuard defaults new rewrites to disabled when added via config file.

### Remaining DOWN monitors (legitimate)

| Monitor | Reason | Action |
|---------|--------|--------|

| Jellyfin | Container not in current compose up | Pause until when-home deployment |
| OPNsense | Offline on Tailscale | Pause — home-only device |
| Beryl AX | Not connected | Pause — mobile device |
| VPS Pi-hole | Container not started | Pause or remove (replaced by AdGuard) |

## Lessons Learned

### 1. Restart all containers after host DNS changes

Docker's embedded DNS caches upstream servers at startup and never refreshes. Any change to the host's `resolv.conf` requires restarting containers that depend on DNS resolution.

**Action**: Add to the DNS change checklist:

```bash
# After any change to /etc/resolv.conf or DNS infrastructure:
docker restart $(docker ps -q)  # or at minimum, restart monitoring containers
```

This gotcha was already documented in memory (`networking-notes.md`) but was not applied during the Mar 12 DNS incident fix because only the directly-affected containers (headscale, caddy, adguard) were restarted.

### 2. Keep AdGuard DNS rewrites in sync with headscale extra_records

The VPS runs a separate DNS path (AdGuard → public resolvers) from MagicDNS. Internal `*.cronova.dev` hostnames need to exist in both:

- **Headscale `extra_records`** — for all Tailscale clients via MagicDNS
- **AdGuard DNS rewrites** — for VPS-local containers (which bypass MagicDNS)

**Action**: When adding a new internal service:

1. Add to headscale `extra_records` in `config.yaml`
2. Add matching DNS rewrite in AdGuard (via web UI or config file)
3. Verify with `dig <hostname> @127.0.0.1` from VPS

### 3. AdGuard rewrites default to disabled via config file

When adding rewrites by editing `AdGuardHome.yaml` directly, AdGuard serializes them with `enabled: false` if the field is omitted. Always include `enabled: true` explicitly, or add rewrites through the web UI instead.

### 4. Monitoring needs meta-monitoring

Uptime Kuma had no way to alert that its own monitors were broken. Consider:

- A simple external health check (e.g., a cron on another host that checks if Uptime Kuma's status page reports any UP monitors)
- Or at minimum: check Uptime Kuma dashboard after any infrastructure DNS change

### 5. Pause monitors for undeployed services

Monitors for services that aren't running yet (Jellyfin, VPS Pi-hole) or devices that are offline (OPNsense, Beryl AX) create noise that masks real issues. Pause them until deployment, then enable.

## Prevention Checklist

Use this checklist after any VPS DNS infrastructure change:

- [ ] Verify host DNS: `dig +short cronova.dev @127.0.0.1`
- [ ] Restart all VPS containers: `docker restart $(docker ps -q)`
- [ ] Verify container DNS: `docker exec uptime-kuma cat /etc/resolv.conf | grep ExtServers`
- [ ] Test internal resolution from container: `docker exec uptime-kuma node -e "require('dns').resolve4('vault.cronova.dev',(e,a)=>console.log(e||a))"`
- [ ] Check AdGuard rewrites match headscale extra_records
- [ ] Wait 2 minutes, verify Uptime Kuma dashboard shows expected UP/DOWN states

## Related Incidents

- [MagicDNS Recursive Loop on VPS (2026-03-12)](incident-2026-03-12-dns-loop.md) — the DNS change that triggered this monitoring failure
