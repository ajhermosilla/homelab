# Network Topology

Docker network architecture and inter-service communication.

## Overview

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
│  ┌──────────────┐  ┌──────────────┐                                         │
│  │ Restic REST  │  │changedetect. │                                         │
│  │  backup-net  │  │ scraping-net │                                         │
│  │    :8000     │  │    :5000     │                                         │
│  └──────────────┘  └──────────────┘                                         │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                            [Tailscale Mesh]
                           100.64.0.x overlay
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
│                           │     :8080      │                                │
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
┌─────────────────────────────────────────────────────────────────────────────┐
│                           Mobile (RPi 5)                                     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────┐                                                           │
│  │   Pi-hole    │                                                           │
│  │  pihole-net  │                                                           │
│  │   :53,:8080  │                                                           │
│  └──────────────┘                                                           │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
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

### Mobile (RPi 5)

| Network | Services | Purpose |
|---------|----------|---------|
| `pihole-net` | Pi-hole | Mobile DNS |

## Inter-Service Communication

### Same Compose File (Direct)

| From | To | Protocol | Port |
|------|-----|----------|------|
| Home Assistant | Mosquitto | MQTT | 1883 |
| Sonarr | Prowlarr | HTTP | 9696 |
| Radarr | Prowlarr | HTTP | 9696 |
| Sonarr | qBittorrent | HTTP | 8080 |
| Radarr | qBittorrent | HTTP | 8080 |
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
| 8080 | qBittorrent Web | TCP |
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

### Mobile (RPi 5)

| Port | Service | Protocol |
|------|---------|----------|
| 53 | Pi-hole DNS | TCP/UDP |
| 8080 | Pi-hole Web | TCP |

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
| home.cronova.dev | Home Assistant | 8123 |
| media.cronova.dev | Jellyfin | 8096 |
| frigate.cronova.dev | Frigate | 5000 |
| hs.cronova.dev | Headscale | 8080 |
| status.cronova.dev | Uptime Kuma | 3001 |

### Via Tailscale (Direct)

All services accessible via Tailscale IPs without port conflicts.

```
http://docker.tail:8096  → Jellyfin
http://nas.tail:8384     → Syncthing
http://vps.tail:8053     → Pi-hole admin
```
