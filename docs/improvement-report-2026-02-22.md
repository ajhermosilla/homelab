# Improvement Report - 2026-02-22

Issues and improvements identified during boot orchestrator deployment and testing.
Updated: 2026-02-23.

## Critical

### ~~Vaultwarden secrets placeholder~~ RESOLVED (2026-02-22)
- ~~`secrets/admin_token.txt` at repo path is a placeholder — Docker needs the file for the bind mount~~
- No `secrets:` section in current compose — ADMIN_TOKEN comes from `.env` via Compose v5 auto-injection

### Missing .env vars on Docker VM — PARTIALLY RESOLVED (2026-02-22)
- ~~FRIGATE_RTSP_PASSWORD~~ — Replaced with per-camera vars: `FRIGATE_FRONT_PASS`, `FRIGATE_BACK_PASS` (Frigate `{VAR}` syntax)
- ~~Automation `.env` missing~~ — Created with `TZ` and `FRIGATE_MQTT_PASS`
- **BLOCKED**: RESTIC_PASSWORD, RESTIC_USER, RESTIC_PASS — backup sidecar targets NAS restic REST server (`192.168.0.12:8000`) which isn't deployed yet. Actionable after NAS deployment

### ~~Media stack broken upstream~~ RESOLVED (2026-02-22)
- ~~Prowlarr image tag `lscr.io/linuxserver/prowlarr:1.0` — manifest unknown~~
- Updated to `prowlarr:latest`

## High

### ~~Home Assistant unhealthy~~ RESOLVED (2026-02-23)
- ~~Shows `unhealthy` in every `docker ps` check~~
- Now healthy (0 failing streak, 16h uptime as of 2026-02-23)
- Remaining: reverse proxy `trusted_proxies` not configured — HA logs warn about forwarded headers from Caddy (172.22.0.1). Non-blocking, cosmetic

### Proxmox VM 101 startup delay
- Currently 30s — OPNsense (gateway) may not be ready when Docker VM boots
- Increase to 120s so network is available before Docker services start
- Change in Proxmox UI: VM 101 → Options → Start/Shutdown order

### Secondary DNS in OPNsense DHCP
- If Pi-hole is down (booting, crashed), all LAN clients lose DNS
- Add fallback DNS (e.g. 1.1.1.1) in OPNsense DHCP settings
- OPNsense web UI: Services → DHCPv4 → LAN → DNS servers

### Full reboot test
- Boot orchestrator ran manually but hasn't been validated through actual `sudo reboot`
- Test: `ssh docker-vm "sudo reboot"`, wait 3 min, verify all containers healthy

## Medium

### Pi-hole outside repo
- Runs from `/opt/homelab/pihole/` with a local `.env` (PIHOLE_PASSWORD)
- Not managed by the repo — Ansible deploys and boot orchestrator use hardcoded path
- Consider moving `.env.example` into repo for consistency

### ~~Caddy and Pi-hole port 80 conflict~~ NO CONFLICT (2026-02-23)
- ~~Both Caddy and Pi-hole bind port 80 on the Docker VM host~~
- Verified: only Caddy binds host port 80. Pi-hole has no host port mappings (accessed via Docker network only)

## Strategic

### UPS
- Eliminates the entire power outage problem class
- Replace Forza NT-1012U with Forza FX-1500LCD-U (~$100-140)
- Or ESP32 GPIO detector for graceful shutdown signaling
- Deferred pending cost/availability review
