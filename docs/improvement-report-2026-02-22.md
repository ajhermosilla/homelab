# Improvement Report - 2026-02-22

Issues and improvements identified during boot orchestrator deployment and testing.
Updated: 2026-02-23 (evening).

## Critical

### ~~Vaultwarden secrets placeholder~~ RESOLVED (2026-02-22)
- ~~`secrets/admin_token.txt` at repo path is a placeholder — Docker needs the file for the bind mount~~
- No `secrets:` section in current compose — ADMIN_TOKEN comes from `.env` via Compose v5 auto-injection

### ~~Missing .env vars on Docker VM~~ RESOLVED (2026-02-23)
- ~~FRIGATE_RTSP_PASSWORD~~ — Replaced with per-camera vars: `FRIGATE_FRONT_PASS`, `FRIGATE_BACK_PASS`, `FRIGATE_TAPO_USER`, `FRIGATE_TAPO_PASS`
- ~~Automation `.env` missing~~ — Created with `TZ` and `FRIGATE_MQTT_PASS`
- ~~RESTIC_PASSWORD, RESTIC_USER, RESTIC_PASS~~ — Restic REST server deployed on NAS, backup sidecars configured and verified

### ~~Media stack broken upstream~~ RESOLVED (2026-02-22)
- ~~Prowlarr image tag `lscr.io/linuxserver/prowlarr:1.0` — manifest unknown~~
- Updated to `prowlarr:latest`

## High

### ~~Home Assistant unhealthy~~ RESOLVED (2026-02-23)
- ~~Shows `unhealthy` in every `docker ps` check~~
- Now healthy (0 failing streak, 16h uptime as of 2026-02-23)
- ~~Reverse proxy `trusted_proxies` warnings~~ — `172.16.0.0/12` in `configuration.yaml` covers Caddy's Docker bridge IP. Errors stopped after restart

### ~~Proxmox VM 101 startup delay~~ RESOLVED (2026-02-23)
- ~~Currently 30s — OPNsense (gateway) may not be ready when Docker VM boots~~
- Bumped to 120s: `startup: order=2,up=120` in `/etc/pve/qemu-server/101.conf`

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
