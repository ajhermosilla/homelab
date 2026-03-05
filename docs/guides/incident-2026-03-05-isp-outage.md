# Incident Report: ISP Outage & Post-Recovery Failures

**Date**: 2026-03-05
**Duration**: ~4 hours (ISP) + ~30 minutes (recovery)
**Severity**: High — all homelab services unreachable externally
**ISP**: Tigo Paraguay (ARRIS modem, bridge mode)

---

## Summary

A 4-hour ISP outage took the entire homelab offline. After the ISP restored service, OPNsense re-acquired its WAN DHCP lease automatically and internet connectivity was restored to all hosts. However, 3 Docker containers on the Docker VM were found crash-looping due to **missing `.env` secret files** — a pre-existing configuration gap exposed by the outage investigation. Remote access via Tailscale was impossible during the outage because all homelab nodes depend on internet to reach the Headscale coordinator.

---

## Timeline (PYT, UTC-3)

| Time | Event |
|------|-------|
| ~01:00 | ISP outage begins (Tigo) |
| ~01:00 | All Tailscale tunnels to homelab nodes drop (no internet → no DERP relay) |
| ~01:00 | Uptime Kuma on VPS detects all homelab monitors as DOWN |
| ~05:00 | ISP restores service |
| ~05:00 | OPNsense WAN auto-renews DHCP lease (181.127.152.105) |
| ~05:00 | Tailscale tunnels begin reconnecting on Docker VM, NAS, Proxmox |
| 05:20 | Investigation begins — Mac on phone hotspot, USB-C ethernet to MokerLink switch |
| 05:22 | Mac gets 192.168.2.100 on LAN (OPNsense DHCP not responding to new adapter) — manually set 192.168.0.200 |
| 05:25 | Confirmed: OPNsense has WAN IP, can ping 8.8.8.8. Proxmox and Docker VM also have internet |
| 05:28 | Found 3 containers crash-looping: `immich-db`, `paperless-db`, `authelia` |
| 05:30 | Root cause: missing `.env` files for 5 stacks (photos, documents, auth, media, monitoring) |
| 05:32 | Generated secrets, created `.env` files, fixed Authelia volume permissions |
| 05:33 | All containers recovered. Authelia schema migrated (v0→v23), listening on :9091 |
| 05:40 | All Tailscale nodes online. Full homelab operational |

---

## Root Causes

### 1. ISP Outage (external, uncontrollable)

Tigo Paraguay had a ~4-hour service interruption. The ARRIS modem in bridge mode passes through the ISP connection to OPNsense WAN. No local mitigation possible for this.

### 2. No Remote Access During Outage

All homelab nodes connect to the self-hosted Headscale coordinator (`hs.cronova.dev`) on the VPS via the internet. When the ISP goes down:
- Tailscale tunnels on Docker VM, NAS, and Proxmox cannot reach Headscale
- Existing tunnels expire within minutes
- The only access path is **physical LAN** — requiring the operator to be on-site and connected to the MokerLink switch

**Impact**: Cannot diagnose or fix any issue remotely during an ISP outage.

### 3. Missing `.env` Files (pre-existing)

Five Docker Compose stacks on the Docker VM had no `.env` files:
- `photos/.env` (Immich) — `POSTGRES_PASSWORD` empty → `immich-db` crash loop
- `documents/.env` (Paperless) — `POSTGRES_PASSWORD` empty → `paperless-db` crash loop
- `auth/config/secrets/` (Authelia) — missing JWT, session, encryption keys → crash loop
- `media/.env` (Jellyfin/arr stack) — not actively running
- `monitoring/.env` (Grafana) — Grafana running with defaults

These stacks were committed as templates but **never fully deployed with secrets**. The containers had been started previously with stale or Docker-cached environment, and the outage-triggered restarts exposed the missing configuration.

### 4. Authelia Volume Permissions

The `authelia-data` named volume was owned by `root`, but Authelia runs as UID 1000. After generating the secret files, the container couldn't write its SQLite database to `/data`. Required `chown 1000:1000 /data`.

### 5. Authelia Healthcheck Command Outdated

The Docker Compose healthcheck uses `authelia healthcheck`, which doesn't exist in Authelia v4.39.x. The correct check is `curl -f http://localhost:9091/api/health`. This causes the container to report `unhealthy` despite functioning correctly.

### 6. OPNsense WAN MTU Anomaly

During investigation, OPNsense WAN (`vtnet0`) showed `mtu 576` — far below the standard 1500. This is likely ISP-imposed or a DHCP option from the ARRIS modem. While not blocking connectivity, it causes:
- Packet fragmentation for anything >576 bytes
- Reduced throughput
- Potential issues with services that set DF (Don't Fragment) bit

---

## Actions Taken

| # | Action | Status |
|---|--------|--------|
| 1 | Power-cycled ARRIS modem | Done |
| 2 | Set static IP on Mac (192.168.0.200) for LAN access | Done |
| 3 | Verified OPNsense WAN lease and internet via `ping 8.8.8.8` | Done |
| 4 | Verified Proxmox and Docker VM have internet | Done |
| 5 | Generated `photos/.env` with DB credentials | Done |
| 6 | Generated `documents/.env` with admin + DB credentials | Done |
| 7 | Generated `monitoring/.env` with Grafana admin password | Done |
| 8 | Generated `media/.env` with paths and UIDs | Done |
| 9 | Generated Authelia secrets (JWT, session, encryption) | Done |
| 10 | Generated Authelia user password hashes (augusto, andre) | Done |
| 11 | Fixed `authelia-data` volume ownership (root → 1000:1000) | Done |
| 12 | Restarted `immich-db`, `paperless-db`, `authelia` | Done |
| 13 | Verified all containers healthy and Tailscale reconnected | Done |

---

## Secrets Generated (store in Vaultwarden)

| Service | Credential | Note |
|---------|-----------|------|
| Authelia | augusto user password | Saved to KeePassXC |
| Authelia | andre user password | Saved to KeePassXC |
| Paperless | admin password | Saved to KeePassXC |
| Paperless | DB password | Saved to KeePassXC |
| Grafana | admin password | Saved to KeePassXC |
| Immich | DB password | Saved to KeePassXC |
| Authelia | JWT / session / encryption keys | On disk at `auth/config/secrets/`, backed up via `backup-env.sh` |

---

## Prevention Plan

### P0 — Immediate (this week)

#### 1. Store All Secrets in Vaultwarden
Every `.env` file and secret must have a corresponding entry in Vaultwarden. Create a "Homelab Secrets" folder with entries for each stack. This is the single source of truth for disaster recovery.

#### 2. Backup `.env` Files via Restic
Add the `.env` files and `auth/config/secrets/` to the Docker VM backup sidecar. These are currently **not backed up anywhere** — losing them means regenerating all credentials and reconfiguring every service.

Recommended: create a backup script that copies all `.env` files to a single directory, then Restic backs up that directory:
```bash
# /opt/homelab/scripts/backup-env.sh
mkdir -p /opt/homelab/repo/env-backup
for stack in /opt/homelab/repo/docker/fixed/docker-vm/*/; do
  name=$(basename "$stack")
  [ -f "$stack/.env" ] && cp "$stack/.env" "/opt/homelab/repo/env-backup/${name}.env"
done
cp -r /opt/homelab/repo/docker/fixed/docker-vm/auth/config/secrets/ /opt/homelab/repo/env-backup/authelia-secrets/
```

#### 3. Fix Authelia Healthcheck
Update `auth/docker-compose.yml` healthcheck to (Authelia image has no `curl`, use `wget`):
```yaml
healthcheck:
  test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:9091/api/health"]
  interval: 30s
  timeout: 3s
  retries: 3
```

#### 4. Investigate OPNsense WAN MTU 576
From OPNsense web UI: **Interfaces → WAN → MTU** — verify if this is ISP-imposed (DHCP option) or misconfigured. If ISP-imposed, set MSS clamping. If misconfigured, set to 1500.

### P1 — Short Term (this month)

#### 5. 4G/LTE Failover WAN (~$30-50)

The single biggest resilience improvement. Add a USB LTE modem or tethered phone as a secondary WAN on OPNsense. This provides:
- Remote access via Tailscale during ISP outages
- Automatic failover for critical services (Headscale, Vaultwarden, DNS)
- No need to be physically present to diagnose issues

**Options (cheapest first):**

| Option | Cost | Pros | Cons |
|--------|------|------|------|
| **USB tethering (existing phone)** | $0 | Free, already have Samsung A13/A16 | Manual, phone must stay plugged in |
| **GL.iNet Beryl AX as WAN2** | $0 (already own) | Can bridge cellular to ethernet | Repurposes travel router |
| **USB LTE dongle (Huawei E3372)** | ~$25 | Plug-and-play, OPNsense detects as `ue0` | Needs SIM with data plan |
| **Dedicated 4G router** | ~$40 | Always-on, no config | Extra device, power draw |

**Recommended**: USB LTE dongle with a cheap prepaid SIM (Tigo/Personal, 5GB/month for ~$3). Configure OPNsense multi-WAN with the LTE interface as failover (gateway group, tier 2). Only Tailscale and DNS traffic need to flow over LTE during failover — not high bandwidth.

**OPNsense configuration:**
```
Interfaces → Assign → New: LTE_WAN (ue0)
System → Gateways → Groups → WAN_FAILOVER:
  - ISP_WAN: Tier 1 (primary)
  - LTE_WAN: Tier 2 (failover)
System → Routes → Default Gateway: WAN_FAILOVER group
```

#### 6. UPS for Network Stack (~$40-60)

The ARRIS modem, MokerLink switch, and Proxmox host should survive brief power outages. A small UPS (APC BE425M or similar, ~$40) provides 10-15 minutes of runtime — enough to ride out flickers and allow graceful shutdowns.

**Power budget:**
| Device | Watts |
|--------|-------|
| ARRIS modem | ~10W |
| MokerLink switch | ~5W |
| Proxmox (P8H77-I, i3-3220T) | ~35W idle |
| NAS (if separate) | ~25W idle |
| **Total** | **~75W** |

With a 425VA UPS: ~10 minutes runtime at 75W. Enough for power flickers. For extended outages, configure NUT (already have `nut-config.md`) to gracefully shut down VMs after 5 minutes on battery.

#### 7. OPNsense SSH Key Authentication

Currently OPNsense only accepts password authentication, which makes automated recovery impossible. Add the Mac's SSH public key to OPNsense:
```
System → Access → Users → root → Authorized Keys → paste ~/.ssh/id_ed25519.pub
```

This enables scripted recovery like `ssh root@192.168.0.1 "configctl interface reconfigure wan"`.

### P2 — Medium Term (next quarter)

#### 8. Automated Recovery Script

Create a script that runs on the Mac (or any LAN device) to diagnose and recover from common outage scenarios:

```bash
#!/bin/bash
# scripts/homelab-recovery.sh
# Run from any device on LAN 192.168.0.0/24

echo "=== Checking OPNsense ==="
ping -c 2 -W 2 192.168.0.1 || { echo "OPNsense unreachable — check Proxmox"; exit 1; }

echo "=== Checking WAN ==="
ssh root@192.168.0.1 "ping -c 2 -W 2 8.8.8.8" || {
  echo "WAN down — renewing DHCP..."
  ssh root@192.168.0.1 "configctl interface reconfigure wan"
  sleep 5
  ssh root@192.168.0.1 "ping -c 2 8.8.8.8" || echo "WAN still down — check modem"
}

echo "=== Checking Docker VM ==="
ssh augusto@192.168.0.10 "docker ps --format '{{.Names}}\t{{.Status}}' | grep Restarting" && {
  echo "Crash-looping containers found — check .env files"
}

echo "=== Checking Tailscale ==="
ssh augusto@192.168.0.10 "tailscale status | head -5"
```

#### 9. Monitoring Gap: No LAN-Side Monitoring

Uptime Kuma runs on the VPS — it monitors via Tailscale, which itself depends on internet. During an ISP outage, **there is zero monitoring of internal services**. Options:
- Run a lightweight monitor on Proxmox or the RPi 5 (when set up) that checks LAN services and sends alerts via LTE failover
- Home Assistant can monitor services and send notifications via the Companion app (local push, no internet needed)

#### 10. Document the Recovery Runbook

Add a quick-reference card to `docs/guides/`:
```
ISP Outage Recovery Checklist:
1. Connect to LAN (ethernet or home WiFi)
2. Set static IP if DHCP not working: sudo ifconfig en16 192.168.0.200/24
3. Ping OPNsense: ping 192.168.0.1
4. SSH to OPNsense: ssh root@192.168.0.1
5. Check WAN: ifconfig vtnet0 | grep inet
6. Renew WAN: configctl interface reconfigure wan
7. Check Docker VM: ssh augusto@192.168.0.10 "docker ps"
8. Check NAS: ssh augusto@192.168.0.12 "docker ps"
```

---

## Architecture Gap Analysis

```
CURRENT STATE:
                    ┌──────────┐
   ISP ────────────►│  ARRIS   │──── SINGLE POINT OF FAILURE
                    │ (bridge) │
                    └────┬─────┘
                         │
                    ┌────▼─────┐
                    │ OPNsense │──── WAN auto-DHCP ✓
                    │  (VM)    │──── No failover WAN ✗
                    └────┬─────┘
                         │
                    ┌────▼─────┐
                    │ MokerLink│──── No UPS ✗
                    │ switch   │
                    └────┬─────┘
                         │
           ┌─────────────┼──────────────┐
           │             │              │
      ┌────▼───┐   ┌────▼────┐   ┌────▼───┐
      │Proxmox │   │Docker VM│   │  NAS   │
      │  host  │   │ (VM101) │   │        │
      └────────┘   └─────────┘   └────────┘


PROPOSED STATE:
                    ┌──────────┐    ┌──────────┐
   ISP ────────────►│  ARRIS   │    │ LTE USB  │◄──── Failover WAN ($25)
                    │ (bridge) │    │  dongle  │
                    └────┬─────┘    └────┬─────┘
                         │               │
                    ┌────▼───────────────▼┐
                    │     OPNsense        │──── Multi-WAN failover
                    │  (gateway group)    │──── SSH key auth
                    └─────────┬───────────┘
                              │
                    ┌─────────▼───────────┐
             ┌──────┤   MokerLink switch  ├──────┐
             │      │     (on UPS)        │      │
             │      └─────────────────────┘      │
             │                │                  │
        ┌────▼───┐      ┌────▼────┐        ┌────▼───┐
        │Proxmox │      │Docker VM│        │  NAS   │
        │(on UPS)│      │ (VM101) │        │(on UPS)│
        └────────┘      └─────────┘        └────────┘
```

---

## Cost Summary

| Item | Cost | Priority | Impact |
|------|------|----------|--------|
| USB LTE dongle + prepaid SIM | ~$28 | P1 | Eliminates remote access blackout |
| Small UPS (APC BE425M or similar) | ~$45 | P1 | Survives power flickers, graceful shutdown |
| **Total** | **~$73** | | |

---

## References

- [OPNsense Multi-WAN](https://docs.opnsense.org/manual/how-tos/multiwan.html)
- [OPNsense Gateway Groups](https://docs.opnsense.org/manual/gateways.html)
- [NUT on Proxmox](https://pve.proxmox.com/wiki/Network_UPS_Tools)
- `docs/guides/nut-config.md` — existing UPS configuration guide
- `docs/strategy/monitoring-strategy.md` — monitoring architecture
- `docs/guides/deployment-order.md` — service dependency graph
