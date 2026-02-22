# Improvement Report - 2026-02-22

Issues and improvements identified during boot orchestrator deployment and testing.

## Critical

### Vaultwarden secrets placeholder
- `secrets/admin_token.txt` at repo path is a placeholder — Docker needs the file for the bind mount
- Either put the real Argon2 token there or remove the `secrets:` section from compose (ADMIN_TOKEN comes from `.env` anyway)
- Location: `docker/fixed/docker-vm/security/docker-compose.yml`

### Missing .env vars on Docker VM
- RESTIC_PASSWORD, RESTIC_USER, RESTIC_PASS — backup sidecars silently fail
- FRIGATE_RTSP_PASSWORD — Frigate RTSP restream may not auth to cameras
- These need a `.env` file at `docker/fixed/docker-vm/security/` and `docker/fixed/docker-vm/automation/`

### Media stack broken upstream
- Prowlarr image tag `lscr.io/linuxserver/prowlarr:1.0` — manifest unknown (tag removed upstream)
- Blocks entire media stack (`docker compose up -d` fails and aborts all services)
- Fix: bump to current stable tag

## High

### Home Assistant unhealthy
- Shows `unhealthy` in every `docker ps` check
- May need initial onboarding (first-time setup wizard) or a config issue
- Healthcheck: `curl -f http://localhost:8123/api/`

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

### Caddy and Pi-hole port 80 conflict
- Both Caddy and Pi-hole bind port 80 on the Docker VM host
- Need to verify they use different IPs or one shadows the other
- May need Pi-hole on a different port (e.g. 8080) or Caddy on a non-80 port

## Strategic

### UPS
- Eliminates the entire power outage problem class
- Replace Forza NT-1012U with Forza FX-1500LCD-U (~$100-140)
- Or ESP32 GPIO detector for graceful shutdown signaling
- Deferred pending cost/availability review
