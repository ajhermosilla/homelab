# Network Topology

Complete infrastructure diagram: physical, logical, and overlay networks.

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                   INTERNET                                       │
└────────────────────────────────────┬────────────────────────────────────────────┘
                                     │
         ┌───────────────────────────┼───────────────────────────┐
         │                           │                           │
         ▼                           ▼                           ▼
┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
│   VPS (Vultr)   │       │  Fixed Homelab  │       │   Mobile Kit    │
│   24/7 Cloud    │       │   Home Server   │       │   On-Demand     │
│                 │       │                 │       │                 │
│ • Headscale     │       │ • Proxmox       │       │ • Beryl AX      │
│ • Caddy         │       │ • Docker VM     │       │ • MacBook       │
│ • Pi-hole       │       │ • NAS           │       │ • Samsung A13   │
│ • Uptime Kuma   │       │ • RPi 5         │       │                 │
│                 │       │ • Start9/RPi4   │       │                 │
│ 100.77.172.46   │       │ 100.68.63.168+  │       │ 100.102.244.131 │
└────────┬────────┘       └────────┬────────┘       └────────┬────────┘
         │                         │                         │
         └─────────────────────────┼─────────────────────────┘
                                   │
                    ┌──────────────┴──────────────┐
                    │     TAILSCALE MESH          │
                    │   100.64.0.0/10 overlay     │
                    │   Coordinated by Headscale  │
                    └─────────────────────────────┘
```

## Tailscale Mesh Network

**Coordination:** Headscale on VPS (hs.cronova.dev)
**Network:** 100.64.0.0/10 (CGNAT range)

```
                              ┌─────────────────────────┐
                              │       HEADSCALE         │
                              │    hs.cronova.dev       │
                              │    100.77.172.46        │
                              └───────────┬─────────────┘
                                          │
          ┌───────────────┬───────────────┼───────────────┬───────────────┐
          │               │               │               │               │
          ▼               ▼               ▼               ▼               ▼
   ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌────────────┐
   │    oga     │  │   docker   │  │    nas     │  │   rpi4     │  │   rpi5     │
   │100.78.12.241│ │100.68.63.168│ │100.82.77.97│  │ 100.64.0.11│  │192.168.0.20│
   │  Proxmox   │  │ Docker VM  │  │  Storage   │  │  Start9    │  │  OpenClaw  │
   └────────────┘  └────────────┘  └────────────┘  └────────────┘  └────────────┘
                                          │
          ┌───────────────────────────────┼───────────────────────────────┐
          │                               │                               │
          ▼                               ▼                               ▼
   ┌────────────┐                  ┌────────────┐                  ┌────────────┐
   │  macbook   │                  │  mombeu    │                  │  beryl-ax  │
   │100.86.220.9│                  │100.110.253 │                  │100.102.244 │
   │ Workstation│                  │Samsung A16 │                  │Trav Router │
   └────────────┘                  └────────────┘                  └────────────┘
```

### Tailscale IP Allocation

| Device | Tailscale IP | LAN IP | Role | Location |
|--------|-------------|--------|------|----------|
| oga | 100.78.12.241 | 192.168.0.237 | Proxmox host | Fixed |
| docker | 100.68.63.168 | 192.168.0.10 | Container host | Fixed |
| opnsense | 100.79.230.235 | 192.168.0.1 | Firewall/Router VM | Fixed |
| rpi5 | pending | 192.168.0.20 | OpenClaw AI assistant | Fixed |
| rpi4 | 100.64.0.11 | 192.168.0.11 | Start9 Bitcoin | Fixed |
| nas | 100.82.77.97 | 192.168.0.12 | Storage server | Fixed |
| vultr | 100.77.172.46 | — | VPS / Exit node | Cloud |
| macbook | 100.86.220.9 | — | Workstation | Mobile |
| beryl-ax | 100.102.244.131 | — | Travel router | Mobile |
| mombeu | 100.110.253.126 | — | Phone | Mobile |

## Fixed Homelab - Physical Topology

```
                              ┌─────────────┐
                              │ ISP Modem   │
                              │ Bridge Mode │
                              └──────┬──────┘
                                     │ WAN
                              ┌──────┴──────┐
                              │   Mini PC   │
                              │  (Proxmox)  │
                              │             │
                              │ ┌─────────┐ │
                              │ │OPNsense │ │ ← Firewall/Router VM
                              │ │   VM    │ │
                              │ └─────────┘ │
                              └──────┬──────┘
                                     │ LAN (192.168.0.1)
                                     │
                    ┌────────────────┴────────────────┐
                    │   MokerLink 8-Port 2.5G Switch  │
                    │         (VLAN Trunk)            │
                    └─┬────┬────┬────┬────┬────┬────┬─┘
                      │    │    │    │    │    │    │
     ┌────────────────┘    │    │    │    │    │    └────────────────┐
     │                     │    │    │    │    │                     │
     ▼                     ▼    ▼    ▼    ▼    ▼                     ▼
┌─────────┐          ┌─────────┐  ┌───┐  ┌─────────┐          ┌─────────┐
│Docker VM│          │  RPi 4  │  │NAS│  │  RPi 5  │          │ WiFi AP │
│(Proxmox)│          │ Start9  │  │   │  │OpenClaw │          │Archer   │
│.0.10    │          │ .0.11   │  │.12│  │ .0.20   │          │AX50     │
└─────────┘          └─────────┘  └───┘  └────┬────┘          └─────────┘
                                              │
                                    ┌─────────┴─────────┐
                                    │                   │
                                    ▼                   ▼
                              ┌──────────┐        ┌──────────┐
                              │ Reolink  │        │ Reolink  │
                              │ Camera 1 │        │ Camera 2 │
                              │ (PoE)    │        │ (PoE)    │
                              └──────────┘        └──────────┘
```

### Fixed Hardware Summary

| Device | Model | Specs | IP | Role |
|--------|-------|-------|-----|------|
| Mini PC (oga) | N150 | 12GB RAM, 512GB SSD | 192.168.0.237 | Proxmox host |
| Docker VM | Debian | 9GB RAM, 100GB | 192.168.0.10 | Containers |
| RPi 5 (openclaw) | Raspberry Pi OS | 8GB RAM, 32GB SD | 192.168.0.20 | AI assistant |
| NAS | i3-3220T | 8GB RAM, 10TB total | 192.168.0.12 | Storage |
| RPi 4 | 4GB | 1TB ext SSD | 192.168.0.11 | Start9 Bitcoin |
| Switch | MokerLink | 8-port 2.5G | - | Backbone |
| PoE Switch | TP-Link | 5-port 1G, 4xPoE | - | Camera power |
| WiFi AP | TP-Link | Archer AX50 WiFi 6 (AP mode) | 192.168.0.2 | Wireless |
| UPS | Forza | 1000VA | - | Power backup |

## Mobile Kit - Physical Topology

```
┌─────────────────────────────────────────────────────────────┐
│                    MOBILE KIT BACKPACK                       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│    ┌───────────────┐         USB-C Tethering                │
│    │  Samsung A13  │◄────────────────────┐                  │
│    │ (Claro SIM)   │                     │                  │
│    └───────────────┘                     │                  │
│                                          │                  │
│    ┌───────────────┐              ┌──────┴──────┐          │
│    │   Beryl AX    │◄─────WiFi────│  MacBook    │          │
│    │  GL-MT3000    │   mbohapy    │   Air M1    │          │
│    │  192.168.8.1  │              │ 192.168.8.10│          │
│    │               │              └─────────────┘          │
│    │ • AdGuard DNS │                                        │
│    │ • Tailscale   │  (RPi 5 moved to fixed homelab)       │
│    └───────────────┘                                        │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Mobile Network Flow

```
[4G/LTE Internet]
        │
        ▼
┌───────────────┐
│  Samsung A13  │  USB Tethering
│  Claro SIM    │
└───────┬───────┘
        │
        ▼
┌───────────────┐      ┌───────────────┐
│   Beryl AX    │─────►│   MacBook     │
│  192.168.8.1  │ WiFi │  192.168.8.10 │
│               │      │               │
│  AdGuard Home │      │  soft-serve   │
│  (Primary DNS)│      │  Tailscale    │
└───────────────┘      └───────────────┘
```

## DNS Resolution Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           DNS RESOLUTION PATHS                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  MOBILE KIT                                                                  │
│  ──────────                                                                  │
│  [Device] ──► AdGuard (Beryl 192.168.8.1) ──► Cloudflare/Quad9              │
│                    │                                                         │
│                    (Beryl AX AdGuard handles mobile DNS)                    │
│                                                                              │
│  FIXED HOMELAB                                                               │
│  ─────────────                                                               │
│  [Device] ──► Pi-hole (Docker 192.168.0.10) ──► Unbound (OPNsense)          │
│                                                      │                       │
│                                                      └──► Root DNS Servers   │
│                                                                              │
│  VPS                                                                         │
│  ───                                                                         │
│  [Container] ──► Pi-hole (127.0.0.1) ──► Cloudflare/Quad9                   │
│                                                                              │
│  TAILSCALE MESH (Fallback Chain)                                            │
│  ───────────────────────────────                                            │
│  Primary:  Docker VM  (100.68.63.168)                                       │
│  Fallback: VPS        (100.77.172.46)                                       │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Docker Service Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              VPS (Vultr)                                     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │   Pi-hole    │  │    Caddy     │  │  Headscale   │  │    DERP      │    │
│  │   dns-net    │  │  proxy-net   │  │ headscale-net│  │  derp-net    │    │
│  │    :53,:8053 │  │    :80,:443  │  │    :8080     │  │ :3478,:8443  │    │
│  └──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘    │
│                                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │ Uptime Kuma  │  │     ntfy     │  │ Restic REST  │  │changedetect. │    │
│  │  monitoring  │  │  monitoring  │  │  backup-net  │  │ scraping-net │    │
│  │    :3001     │  │     :80      │  │    :8000     │  │    :5000     │    │
│  └──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘    │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                            [Tailscale Mesh]
                           100.64.0.0/10 overlay
                                    │
┌─────────────────────────────────────────────────────────────────────────────┐
│                         Fixed Homelab (Docker VM)                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐                       │
│  │   Pi-hole    │  │    Caddy     │  │  Vaultwarden │                       │
│  │  pihole-net  │  │  caddy-net   │  │ security-net │                       │
│  │    :53,:8053 │  │   :80,:443   │  │    :8843     │                       │
│  └──────────────┘  └──────────────┘  └──────┬───────┘                       │
│                                              │                               │
│  ┌──────────────┐                    ┌──────┴───────┐                       │
│  │   Mosquitto  │◄───── MQTT ───────►│   Frigate    │                       │
│  │automation-net│      :1883         │ security-net │                       │
│  │  :1883,:9001 │                    │ :5000,:8554  │                       │
│  └──────┬───────┘                    └──────────────┘                       │
│         │                                                                    │
│  ┌──────┴───────┐                                                           │
│  │Home Assistant│                                                           │
│  │automation-net│                                                           │
│  │    :8123     │                                                           │
│  └──────────────┘                                                           │
│                                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │   Jellyfin   │  │    Sonarr    │  │    Radarr    │  │   Prowlarr   │    │
│  │  media-net   │  │  media-net   │  │  media-net   │  │  media-net   │    │
│  │    :8096     │  │    :8989     │  │    :7878     │  │    :9696     │    │
│  └──────────────┘  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘    │
│                           │                 │                 │             │
│                           └────────┬────────┴────────┬────────┘             │
│                                    │                 │                      │
│                           ┌────────┴───────┐         │                      │
│                           │  qBittorrent   │         │                      │
│                           │   media-net    │◄────────┘                      │
│                           │     :8081      │                                │
│                           └────────────────┘                                │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                              [NFS Mounts]
                           /mnt/nas/media
                          /mnt/nas/frigate
                                    │
┌─────────────────────────────────────────────────────────────────────────────┐
│                              NAS (Debian)                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐                       │
│  │    Samba     │  │  Syncthing   │  │ Restic REST  │                       │
│  │ storage-net  │  │ storage-net  │  │  backup-net  │                       │
│  │  :139,:445   │  │    :8384     │  │    :8000     │                       │
│  └──────────────┘  └──────────────┘  └──────────────┘                       │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                            [Tailscale Mesh]
                                    │
*RPi 5 is now in the Fixed Homelab running OpenClaw (not Docker-based, installed via Ansible).*
```

## Docker Networks by Environment

### VPS

| Network | Services | Purpose |
|---------|----------|---------|
| `dns-net` | Pi-hole | DNS resolution |
| `proxy-net` | Caddy | Reverse proxy |
| `headscale-net` | Headscale, backup sidecar | Mesh coordination |
| `derp-net` | DERP relay | NAT traversal |
| `backup-net` | Restic REST | Offsite backup |
| `scraping-net` | changedetection, Playwright | Web monitoring |

### Fixed Homelab (Docker VM)

| Network | Services | Purpose |
|---------|----------|---------|
| `pihole-net` | Pi-hole | DNS resolution |
| `caddy-net` | Caddy | Reverse proxy |
| `security-net` | Vaultwarden, Frigate | Security services |
| `automation-net` | Home Assistant, Mosquitto | Home automation |
| `media-net` | Jellyfin, Sonarr, Radarr, Prowlarr, qBittorrent | Media stack |

### NAS

| Network | Services | Purpose |
|---------|----------|---------|
| `storage-net` | Samba, Syncthing | File sharing |
| `backup-net` | Restic REST | Local backup |

### Mobile

*Mobile kit no longer runs Docker services. Beryl AX AdGuard handles mobile DNS.*

## Inter-Service Communication

### Same Compose File (Direct)

| From | To | Protocol | Port |
|------|-----|----------|------|
| Home Assistant | Mosquitto | MQTT | 1883 |
| Sonarr | Prowlarr | HTTP | 9696 |
| Radarr | Prowlarr | HTTP | 9696 |
| Sonarr | qBittorrent | HTTP | 8081 |
| Radarr | qBittorrent | HTTP | 8081 |
| changedetection | Playwright | WebSocket | 3000 |

### Cross-Compose (Host Network)

| From | To | Protocol | Port | Notes |
|------|-----|----------|------|-------|
| Frigate | Mosquitto | MQTT | 1883 | Via host IP |
| Caddy | All services | HTTP | various | Reverse proxy |
| Home Assistant | Frigate | HTTP | 5000 | Integration |

### Cross-Host (Tailscale)

| From | To | Protocol | Port | Notes |
|------|-----|----------|------|-------|
| Docker VM | NAS Restic | HTTP | 8000 | Backup |
| All hosts | VPS Headscale | HTTPS | 443 | Mesh coordination |
| All hosts | VPS Pi-hole | DNS | 53 | Fallback DNS |

## Port Assignments

### VPS

| Port | Service | Protocol |
|------|---------|----------|
| 53 | Pi-hole DNS | TCP/UDP |
| 80 | Caddy HTTP | TCP |
| 443 | Caddy HTTPS | TCP/UDP |
| 3478 | DERP STUN | UDP |
| 5000 | changedetection | TCP |
| 8000 | Restic REST | TCP |
| 8053 | Pi-hole Web | TCP |
| 8080 | Headscale | TCP |
| 8443 | DERP HTTPS | TCP |

### Docker VM

| Port | Service | Protocol |
|------|---------|----------|
| 53 | Pi-hole DNS | TCP/UDP |
| 80 | Caddy HTTP | TCP |
| 443 | Caddy HTTPS | TCP/UDP |
| 1883 | Mosquitto MQTT | TCP |
| 5000 | Frigate Web | TCP |
| 6881 | qBittorrent | TCP/UDP |
| 7878 | Radarr | TCP |
| 8053 | Pi-hole Web | TCP |
| 8081 | qBittorrent Web | TCP |
| 8096 | Jellyfin | TCP |
| 8123 | Home Assistant | TCP |
| 8554 | Frigate RTSP | TCP |
| 8555 | Frigate WebRTC | TCP/UDP |
| 8843 | Vaultwarden | TCP |
| 8989 | Sonarr | TCP |
| 9001 | Mosquitto WS | TCP |
| 9696 | Prowlarr | TCP |

### NAS

| Port | Service | Protocol |
|------|---------|----------|
| 139 | Samba | TCP |
| 445 | Samba | TCP |
| 8000 | Restic REST | TCP |
| 8384 | Syncthing Web | TCP |
| 22000 | Syncthing Transfer | TCP/UDP |
| 21027 | Syncthing Discovery | UDP |

### RPi 5 (OpenClaw)

| Port | Service | Protocol |
|------|---------|----------|
| 18789 | OpenClaw Gateway | TCP |

## Network Isolation

Each stack uses its own bridge network for isolation:

```bash
# List networks
docker network ls

# Inspect network
docker network inspect media-net

# Services can only communicate within their network
# Cross-network requires host ports or shared networks
```

## External Access

### Via Caddy (HTTPS)

| Domain | Backend | Port |
|--------|---------|------|
| vault.cronova.dev | Vaultwarden | 8843 |
| jara.cronova.dev | Home Assistant | 8123 |
| yrasema.cronova.dev | Jellyfin | 8096 |
| taguato.cronova.dev | Frigate | 5000 |
| hs.cronova.dev | Headscale | 8080 |
| status.cronova.dev | Uptime Kuma | 3001 |

### Via Tailscale (Direct)

All services accessible via Tailscale IPs without port conflicts.

```
http://docker.tail:8096  → Jellyfin
http://nas.tail:8384     → Syncthing
http://vps.tail:8053     → Pi-hole admin
```
