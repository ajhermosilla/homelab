# Fixed Homelab Architecture

Always-on infrastructure at home. Proxmox hypervisor runs OPNsense (gateway) and a Docker VM (services). A DIY NAS handles storage, git, and PaaS. All connected via Tailscale mesh.

## Overview

| Component | Hardware | Role | Containers |
|-----------|----------|------|------------|
| Oga (Proxmox) | AOOSTAR Mini PC, Intel N150, 12GB RAM | Hypervisor: OPNsense VM + Docker VM | — |
| Docker VM (101) | 4 vCPU, 9GB RAM, 100GB disk | Services: 10 stacks, 28 containers | 28 |
| NAS | i3-3220T, 8GB DDR3, Mini-ITX | Storage, git, PaaS: 5 stacks + Coolify | 12 |
| OPNsense (100) | 2 vCPU, 2GB RAM, 20GB disk | Gateway, DHCP, VLANs, Tailscale | — |

*Full hardware specs: [hardware.md](hardware.md)*

---

## Network Topology

```
          [ISP Modem — ARRIS bridge mode]
                       |
              [Oga — Proxmox VE]
                 nic0 / vmbr0 (WAN)
                       |
                [OPNsense VM 100]
                 nic1 / vmbr1 (LAN 192.168.0.1/24)
                       |
              [MokerLink 2.5G Switch]
                       |
   +----------+--------+----------+----------+----------+
   |          |        |          |          |          |
[Docker VM] [NAS]   [RPi 5]   [WiFi AP]  [PoE SW]  [Proxmox mgmt]
  .0.10     .0.12   .0.20     AX50                   .0.237
  28 cnt    12 cnt  pending                              |
                                             +-----------+-----------+
                                             |           |           |
                                        [front_door] [back_yard]  [indoor]
                                         .0.110       .0.111     .0.101 (WiFi)

                      [Tailscale Mesh — 8 nodes via Headscale on VPS]
```

**Network flow:** Docker VM → vmbr1 → OPNsense LAN → OPNsense WAN → vmbr0 → ISP

**VLANs:** Management (default), IoT (VLAN 10), Guest (VLAN 20) — configured in OPNsense

**DNS:** Pi-hole on Docker VM (192.168.0.10:53), OPNsense forwards DNS to Pi-hole

**Reverse proxy:** Caddy on Docker VM with DNS-01 TLS via Cloudflare, Authelia forward auth

---

## Docker VM (VM 101)

Debian 13 (Trixie) | 4 vCPU | 9GB RAM | 100GB disk | vmbr1 (LAN only)

### Stack Directory Structure

```
/opt/homelab/repo/docker/fixed/docker-vm/
├── networking/
│   ├── pihole/          # Pi-hole (DNS)
│   └── caddy/           # Caddy (reverse proxy, DNS-01 TLS)
├── automation/          # Home Assistant (Jara), Mosquitto, HA backup sidecar
├── security/            # Vaultwarden, Frigate (Taguato), Vaultwarden backup sidecar
├── auth/                # Authelia (Okẽ)
├── tools/               # Dozzle (Ysyry), Stirling-PDF (Kuatia), Homepage (Mbyja)
├── documents/           # Paperless-ngx (Aranduka), PostgreSQL, Redis
├── monitoring/          # VictoriaMetrics, vmagent, Grafana (Papa)
├── photos/              # Immich (Vera): server, ML, Valkey, PostgreSQL
├── media/               # Jellyfin (Yrasema), Sonarr, Radarr, Prowlarr, qBittorrent
└── maintenance/         # Watchtower
```

### Containers by Stack

| Stack | Containers | Ports |
|-------|-----------|-------|
| **networking** | pihole, caddy | 53 (DNS), 80/443 (HTTP/S) |
| **automation** | homeassistant, mosquitto, homeassistant-backup | 8123 (HA), 1883 (MQTT) |
| **security** | vaultwarden, frigate, vaultwarden-backup | 8843 (VW), 5000/8554/8555 (Frigate) |
| **auth** | authelia | 9091 |
| **tools** | dozzle, stirling-pdf, homepage | 9999, 8580, 3030 |
| **documents** | paperless-ngx, paperless-db, paperless-redis | 8000 |
| **monitoring** | victoriametrics, vmagent, grafana | 8428, 3000 (localhost only) |
| **photos** | immich-server, immich-ml, immich-valkey, immich-db | 2283 |
| **media** | jellyfin, sonarr, radarr, prowlarr, qbittorrent | 8096, 8989, 7878, 9696, 8081 |
| **maintenance** | watchtower | — |

**Total: 10 stacks, 28 containers**

### Boot Orchestrator

`scripts/docker-boot-orchestrator.sh` — 14-phase startup sequence ensuring correct dependency order.

| Phase | Action | Why |
|-------|--------|-----|
| 1 | Wait for Docker daemon | 60s timeout |
| 2 | Wait for NFS mount | 300s timeout, non-fatal if unavailable |
| 3 | Stop all containers | Clean state |
| 4 | Networking (Pi-hole + Caddy) | DNS + reverse proxy first |
| 5 | Automation (HA + Mosquitto) | Creates mqtt-net, waits for Mosquitto healthy |
| 6 | Security (Vaultwarden + Frigate) | Frigate joins mqtt-net |
| 7 | Auth (Authelia) | Must be up before forward_auth services |
| 8 | Tools (Dozzle, Stirling-PDF, Homepage) | — |
| 9 | Documents (Paperless-ngx) | — |
| 10 | Monitoring (VictoriaMetrics, Grafana) | — |
| 11 | Photos (Immich) | — |
| 12 | Media (Jellyfin, *arr stack) | NFS-dependent |
| 13 | Maintenance (Watchtower) | Always last |
| 14 | Final status report | Log container count |

### NFS Mounts

Docker VM mounts NAS storage for services that need shared data:

| Mount Point | NAS Export | Used By |
|-------------|-----------|---------|
| `/mnt/nas/frigate` | `/srv/frigate` (Purple 2TB) | Frigate recordings |
| `/mnt/nas/media` | NAS media share | Jellyfin, *arr stack |
| `/mnt/nas/downloads` | NAS downloads share | qBittorrent, *arr stack |
| `/mnt/nas/photos` | NAS photos share | Immich |

### Caddy Reverse Proxy

Custom build: `caddy:2` + `caddy-dns/cloudflare` for DNS-01 TLS challenges.

- All `.cronova.dev` subdomains terminate TLS at Caddy
- Authelia forward auth protects: Yrasema, Ysyry, Kuatia, Mbyja, Papa, Aranduka
- Services with own auth (not protected): Jara (HA), Taguato (Frigate), Vaultwarden, Vera (Immich), Forgejo

---

## NAS

Debian 13 (Trixie) | i3-3220T | 8GB DDR3 | Boots from USB

### Boot Process

USB UEFI → GRUB → kernel/initramfs → SSD LVM root

**Boot USB:** Generic Flash Disk 3.7GB — EFI (512M FAT32) + /boot (3.1G ext4). **Must stay plugged in.**

Rescue USB: SystemRescue 12.03 on Lexar 128GB USB.

### Docker Configuration

- Docker data-root: `/data/docker` (on SSD, NOT `/var/lib/docker`)
- Configured via `/etc/docker/daemon.json`
- `/var` is only 6.1G — too small for Docker images

### Storage

| Drive | Model | Size | Mount | Purpose | Status |
|-------|-------|------|-------|---------|--------|
| SSD | Lexar NQ100 | 240GB | `/` (LVM) | OS, Docker data-root (`/data/docker`) | Active |
| HDD | WD Purple | 2TB | `/mnt/purple` | Frigate recordings, Restic backups | Active (97% full) |
| HDD | WD Red Plus | 8TB | — | Media, backups | Partition recovery pending |

### Containers (12 total)

| Stack | Containers | Compose Path |
|-------|-----------|-------------|
| **backup** | restic-rest | `docker/fixed/nas/backup/` |
| **git** | forgejo | `docker/fixed/nas/git/` |
| **storage** | samba, syncthing | `docker/fixed/nas/storage/` |
| **monitoring** | glances | `docker/fixed/nas/monitoring/` |
| **paas** | coolify, coolify-db, coolify-redis, coolify-realtime, coolify-proxy, coolify-sentinel, coolify-backup | `/data/coolify/source/` + `docker/fixed/nas/paas/` |

**Key services:**
- **Forgejo** — Git server at `git.cronova.dev`, data at `/srv/forgejo`, SSH on port 2222
- **Restic REST** — Backup target on port 8000, data at `/mnt/purple/backup/restic/`, `--private-repos`
- **Coolify (Tajy)** — PaaS at `tajy.cronova.dev`, port 8888, Traefik on 80/443
- **Samba** — Network shares (justinpatchett/samba, migrated from abandoned dperson/samba)
- **Syncthing** — File sync, version 2.0.14
- **Glances** — System monitoring, integrated with Home Assistant

### NFS Exports

```
/srv/frigate    → Docker VM (Frigate recordings)
```

---

## OPNsense (VM 100)

Gateway since 2026-02-21. Replaced ISP router.

| Setting | Value |
|---------|-------|
| vCPU | 2 |
| RAM | 2GB |
| Disk | 20GB |
| WAN | vmbr0 (NIC0, ARRIS bridge) |
| LAN | vmbr1 (NIC1, 192.168.0.1/24) |

**Services:** Firewall, NAT, DHCP server, DNS forwarding to Pi-hole, Tailscale node

**VLANs:** IoT (VLAN 10), Guest (VLAN 20) — interfaces configured, rules pending

**Access:** SSH `root` (password only), web UI via tunnel:
```bash
ssh -L 8443:192.168.0.1:443 augusto@100.78.12.241
# Then browse https://localhost:8443
```

---

## Deployment Status

| Phase | Task | Status |
|-------|------|--------|
| 1 | Proxmox VE on Mini PC | Done |
| 2 | Network bridges (vmbr0 WAN, vmbr1 LAN) | Done |
| 3 | OPNsense VM (gateway, DHCP) | Done |
| 4 | Docker VM (Debian 13, Docker) | Done |
| 5 | Pi-hole + Caddy (networking) | Done |
| 6 | Vaultwarden + Frigate (security) | Done |
| 7 | Home Assistant + Mosquitto (automation) | Done |
| 8 | NAS: Debian 13, Docker, Samba, Syncthing | Done |
| 9 | NAS: Restic REST, Forgejo | Done |
| 10 | NAS: NFS export for Frigate | Done |
| 11 | Frigate cameras + MQTT → HA | Done |
| 12 | Tailscale mesh (8 nodes) | Done |
| 13 | Backup sidecars (Vaultwarden, HA, Coolify) | Done |
| 14 | Authelia (SSO) | Done |
| 15 | Tools (Dozzle, Stirling-PDF, Homepage) | Done |
| 16 | Monitoring (VictoriaMetrics, Grafana) | Config ready |
| 17 | Photos (Immich) | Config ready |
| 18 | Documents (Paperless-ngx) | Config ready |
| 19 | Media (Jellyfin, *arr stack) | Config ready (NFS mounts pending) |
| 20 | Coolify PaaS on NAS | Done |
| 21 | Boot orchestrator (systemd) | Done |
| — | RPi 5 (OpenClaw) | Pending (PSU in transit) |
| — | OPNsense firewall rules, CrowdSec | Pending |
| — | VLAN hardening | Pending |
| — | iGPU passthrough (SR-IOV) for Frigate | Pending |

---

## Power & UPS

All critical devices connected to **CyberPower 1500VA UPS**.

| Device | Power | UPS Protected |
|--------|-------|---------------|
| Mini PC (Proxmox) | ~35W | Yes |
| NAS | ~50W idle | Yes |
| MokerLink Switch | ~15W | Yes |
| TP-Link PoE Switch | ~65W max | Yes |
| Archer AX50 AP | ~15W | Yes |

**Total estimated load:** ~180W

Mini PC BIOS set to "Power On" on AC power restore for auto-boot after outage.

---

## References

- [Proxmox VE](https://www.proxmox.com/en/proxmox-ve)
- [OPNsense](https://opnsense.org/)
- [Docker Compose](https://docs.docker.com/compose/)
- [Caddy](https://caddyserver.com/)
- [Frigate NVR](https://frigate.video/)
- [Home Assistant](https://www.home-assistant.io/)
- [Forgejo](https://forgejo.org/)
- [Coolify](https://coolify.io/)
- [Restic](https://restic.net/)
- [VictoriaMetrics](https://victoriametrics.com/)
