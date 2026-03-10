# Uptime Kuma Monitor Setup Plan

**Date**: 2026-03-02
**Updated**: 2026-03-10
**Status**: Complete — 35 monitors, all managed via `scripts/setup-uptime-kuma.py` (single source of truth)
**Tool**: Python `uptime-kuma-api` library (WebSocket API) — replaced kuma-cli which was incompatible with Kuma 1.23
**Uptime Kuma**: v1.23.17 on VPS at `https://status.cronova.dev`, username `ajhermosilla`

## Prerequisites

1. Install kuma-cli: `cargo install kuma-cli` or download from GitHub releases
2. Create config file:

```toml
# ~/.config/kuma/kuma.toml
url = "https://status.cronova.dev"
username = "augusto"
password = "<from-vaultwarden>"
```

3. Test connection: `kuma monitor list`

## Phase 1 — Critical (60s interval, ntfy urgent)

```bash
kuma monitor add ping --name "OPNsense Gateway" --hostname "192.168.0.1" --interval 60
kuma monitor add tcp --name "Pi-hole DNS" --hostname "100.68.63.168" --port 53 --interval 60
kuma monitor add http --name "Vaultwarden" --url "https://vault.cronova.dev/alive" --interval 60
kuma monitor add http --name "Caddy (Docker VM)" --url "https://100.68.63.168" --interval 60
kuma monitor add http --name "Headscale" --url "https://hs.cronova.dev/health" --interval 60
```

## Phase 2 — High Priority (5m interval, ntfy high)

```bash
kuma monitor add http --name "Home Assistant" --url "https://jara.cronova.dev" --interval 300
kuma monitor add http --name "Frigate" --url "https://taguato.cronova.dev/api/version" --interval 300
kuma monitor add http --name "Forgejo" --url "https://git.cronova.dev/api/healthz" --interval 300
kuma monitor add tcp --name "NAS Samba" --hostname "100.82.77.97" --port 445 --interval 300
kuma monitor add http --name "Restic REST" --url "http://100.82.77.97:8000" --interval 300
kuma monitor add http --name "Coolify" --url "https://tajy.cronova.dev" --interval 300
kuma monitor add http --name "Authelia" --url "https://auth.cronova.dev" --interval 300
```

Note: Restic REST returns 401 (auth required) — configure expected status code 401.

## Phase 3 — Standard (5m interval, ntfy default)

```bash
kuma monitor add http --name "Jellyfin" --url "https://yrasema.cronova.dev/health" --interval 300
kuma monitor add http --name "Grafana" --url "https://papa.cronova.dev" --interval 300
kuma monitor add http --name "Immich" --url "https://vera.cronova.dev" --interval 300
kuma monitor add http --name "Syncthing" --url "http://100.82.77.97:8384/rest/noauth/health" --interval 300
kuma monitor add http --name "Glances" --url "http://100.82.77.97:61208/api/4/cpu" --interval 300
```

## Phase 4 — External (15m interval)

```bash
kuma monitor add http --name "cronova.dev" --url "https://cronova.dev" --interval 900
kuma monitor add http --name "verava.ai" --url "https://verava.ai" --interval 900
```

## ntfy Notification Setup

Configure in Uptime Kuma UI (Settings → Notifications) before adding monitors:

| Notification | ntfy Topic | Priority |
|---|---|---|
| Critical Alerts | `cronova-critical` | urgent (5) |
| Warning Alerts | `cronova-warning` | high (4) |
| Info Alerts | `cronova-info` | default (3) |

Server: `https://notify.cronova.dev`, auth: username `augusto` + password or bearer token.

Assign notification profiles to monitors by tier after creation.

## Notes

- kuma-cli exact syntax may vary — run `kuma monitor add --help` for each type
- Uptime Kuma API is WebSocket-only — kuma-cli handles this transparently
- SSL certificate expiry alerts are automatic for all HTTPS monitors
- Some services behind Authelia may need accepted status codes adjusted (302 redirect)
- Monitor from VPS means testing external reachability via Tailscale IPs
