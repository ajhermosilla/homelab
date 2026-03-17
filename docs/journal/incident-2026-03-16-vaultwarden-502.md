# Incident: Vaultwarden 502 — 2026-03-16

**Duration**: Unknown start — resolved ~07:30 PYT
**Impact**: Vaultwarden (vault.cronova.dev) returning 502 Bad Gateway. Password manager inaccessible for all users.
**Severity**: High — critical service, affects all authenticated workflows

## Root Cause

Caddy reverse proxy could not reach Vaultwarden due to a network routing issue.

#### Chain of events

1. Vaultwarden binds to `127.0.0.1:8843` on the Docker VM host (localhost only)
2. Caddy (running in a container) proxied via `host.docker.internal:8843`, which resolves to `172.17.0.1` (docker0 bridge)
3. Traffic from Caddy container → `172.17.0.1:8843` must traverse the host's network stack
4. Docker VM has UFW with `INPUT DROP` policy — this blocks container→host traffic through the docker0 bridge
5. This configuration was fragile — it may have worked previously due to transient iptables rules inserted by Docker, which got cleared after a Docker daemon restart or container recreation

**Why it broke now:** The mass container recreation on 2026-03-15 (deploying all stacks with cap_drop fixes) likely caused Docker to regenerate iptables rules, dropping whatever transient rule was allowing this traffic.

**Contributing factor:** Vaultwarden was the only `caddy-net` service still using the `host.docker.internal` pattern. All other localhost-bound services (authelia, grafana, dozzle, immich, paperless, homepage, bentopdf) were already on `caddy-net` with direct container name routing.

## Fix Applied

1. Added Vaultwarden to `caddy-net` external network (security stack `docker-compose.yml`)
2. Updated Caddyfile: `reverse_proxy host.docker.internal:8843` → `reverse_proxy vaultwarden:80`
3. Restarted both containers

This routes traffic directly over the Docker overlay network, bypassing UFW entirely — same pattern as all other Caddy-proxied services.

## Lessons Learned

1. **Never use `host.docker.internal` for services behind a firewall with INPUT DROP.** Docker's bridge traffic is subject to host iptables/UFW rules. Use `caddy-net` with container names instead — this is reliable and firewall-independent.

2. **The `host.docker.internal` pattern is only safe for services that bind to `0.0.0.0`**(like Home Assistant, Jellyfin,*arr stack), where the port is accessible on all interfaces including the docker0 bridge. For `127.0.0.1`-bound services, always use a shared Docker network.

3. **After mass container recreation, verify all services are reachable** — not just that containers are healthy. A container can be healthy internally but unreachable from the reverse proxy.

4. **Audit remaining `host.docker.internal` references in Caddyfile** to ensure none are at risk of the same failure. Current safe uses: Home Assistant (0.0.0.0:8123), Jellyfin (0.0.0.0:8096) — these bind to all interfaces so bridge traffic works regardless of UFW.
