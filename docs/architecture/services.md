# Services

50+ services across 3 environments. Guarani names are primary identifiers.

## Service Matrix

| # | Guarani Name | Service | Category | Host | Status |
|---|--------------|---------|----------|------|--------|
| 1 | — | Headscale | Networking | VPS | Active |
| 2 | — | Caddy (VPS) | Networking | VPS | Active |
| 3 | — | headscale-backup | Backup | VPS | Active |
| 4 | — | Uptime Kuma | Monitoring | VPS | Active |
| 5 | — | ntfy | Notifications | VPS | Active |
| 6 | Yvága | AdGuard Home | DNS | VPS | Active |
| 7 | Yvága | Unbound | DNS | VPS | Active |
| 8 | — | DERP Relay | Networking | VPS | Active |
| 9 | — | Pi-hole (VPS) | DNS | VPS | Active |
| 10 | — | changedetection | Scraping | VPS | Active |
| 11 | — | Playwright | Scraping | VPS | Active |
| 12 | — | Restic REST (VPS) | Backup | VPS | Active |
| 13 | — | Pi-hole | DNS | Docker VM | Active |
| 7 | — | Caddy (Docker VM) | Networking | Docker VM | Active |
| 8 | — | Watchtower | Maintenance | Docker VM | Active |
| 9 | — | Vaultwarden | Security | Docker VM | Active |
| 10 | — | vaultwarden-backup | Backup | Docker VM | Active |
| 11 | Taguato | Frigate NVR | Surveillance | Docker VM | Active |
| 12 | Jara | Home Assistant | Automation | Docker VM | Active |
| 13 | — | homeassistant-backup | Backup | Docker VM | Active |
| 14 | — | Mosquitto | Messaging | Docker VM | Active |
| 15 | Okẽ | Authelia | Auth / SSO | Docker VM | Active |
| 16 | Yrasema | Jellyfin | Media | Docker VM | Active |
| 17 | Mbyja | Homepage | Dashboard | Docker VM | Active |
| 18 | Ysyry | Dozzle | Log viewer | Docker VM | Active |
| 19 | Kuatia | BentoPDF | Tools | Docker VM | Active |
| 20 | Papa | VictoriaMetrics | Monitoring | Docker VM | Active |
| 21 | Papa | Grafana | Monitoring | Docker VM | Active |
| 22 | Papa | vmagent | Monitoring | Docker VM | Active |
| 23 | Vera | Immich Server | Photos | Docker VM | Active |
| 24 | Vera | Immich ML | Photos | Docker VM | Active |
| 25 | Vera | Immich Valkey | Photos | Docker VM | Active |
| 26 | Vera | Immich DB | Photos | Docker VM | Active |
| 27 | Aranduka | Paperless-ngx | Documents | Docker VM | Active |
| 28 | — | Sonarr | Media | Docker VM | Active |
| 29 | — | Radarr | Media | Docker VM | Active |
| 30 | — | Prowlarr | Media | Docker VM | Active |
| 31 | — | qBittorrent | Media | Docker VM | Active |
| 32 | — | paperless-db | Documents | Docker VM | Active |
| 33 | — | paperless-redis | Documents | Docker VM | Active |
| 34 | — | paperless-backup | Backup | Docker VM | Active |
| 35 | — | immich-backup | Backup | Docker VM | Active |
| 36 | Papa | vmalert | Monitoring | Docker VM | Active |
| 37 | Papa | Alertmanager | Monitoring | Docker VM | Active |
| 38 | Papa | cAdvisor | Monitoring | Docker VM | Active |
| 39 | — | Samba | Storage | NAS | Active |
| 40 | — | Syncthing | Storage | NAS | Active |
| 41 | — | Restic REST | Backup | NAS | Active |
| 42 | — | Offsite Sync | Backup | NAS | Active |
| 43 | — | Forgejo | Git | NAS | Active |
| 44 | — | NFS | Storage | NAS | Active |
| 45 | — | Glances | Monitoring | NAS | Active |
| 46 | Tajy | Coolify | PaaS | NAS | Active |
| 47 | Tajy | coolify-db | PaaS | NAS | Active |
| 48 | Tajy | coolify-redis | PaaS | NAS | Active |
| 49 | Tajy | coolify-realtime | PaaS | NAS | Active |
| 50 | Tajy | coolify-proxy (Traefik) | PaaS | NAS | Active |
| 51 | Tajy | coolify-sentinel | PaaS | NAS | Active |
| 52 | Tajy | coolify-backup | PaaS | NAS | Active |
| 53 | — | Katupyry App | Finance | NAS | Active |
| 54 | — | Katupyry DB | Finance | NAS | Active |
| 55 | — | Katupyry Redis | Finance | NAS | Active |
| 56 | Javya | Javya App | Worship | NAS | Active |
| 57 | Javya | Javya DB | Worship | NAS | Active |
| 58 | Javya | Javya Redis | Worship | NAS | Active |
| 59 | — | OpenClaw | AI | RPi 5 | Pending |

**Active:** 65 | **Pending:** 1

## By Environment

### VPS (Vultr) — 11 containers, 24/7

| Service | Port(s) | Purpose | Image |
|---------|---------|---------|-------|
| **Headscale** | 443, 3478 | Tailscale coordination (PRIMARY) | headscale/headscale:0.28.0 |
| **Caddy** | 80, 443 | Reverse proxy, auto-TLS | caddy:2.8.4-alpine |
| **headscale-backup** | — | Headscale DB backups | custom script |
| **Uptime Kuma** | 3001 | External monitoring (WebSocket API) | louislam/uptime-kuma:1.23 |
| **ntfy** | 8080 | Push notifications | binwiederhier/ntfy:v2 |
| **AdGuard Home** (Yvága) | 53, 3000 | DNS ad-blocking + filtering | adguard/adguardhome:v0.107.73 |
| **Unbound** (Yvága) | 5335 | Recursive DNS resolver (no third-party) | madnuttah/unbound:1.24.2-1 |
| **DERP Relay** | 443, 3478 | Tailscale relay for NAT traversal | fredliang/derper:1.0 |
| **Pi-hole** (VPS) | 53 | DNS (legacy, secondary to AdGuard) | pihole/pihole:2026.02.0 |
| **changedetection** | 5000 | Web page change monitoring | ghcr.io/dgtlmoon/changedetection.io:latest |
| **Playwright** | — | Browser engine for changedetection | dgtlmoon/sockpuppetbrowser:latest |
| **Restic REST** (VPS) | 8000 | Headscale backup target | restic/rest-server:0.14.0 |

### Docker VM — 33 containers, 24/7

#### Networking

| Service | Port(s) | Subdomain | Image |
|---------|---------|-----------|-------|
| **Pi-hole** | 53, 8053 | local | pihole/pihole (v6.3) |
| **Caddy** | 80, 443 | — | custom (caddy:2 + caddy-dns/cloudflare) |

Caddy on Docker VM is a custom build with the Cloudflare DNS module for DNS-01 TLS challenges. All `*.cronova.dev` services get automatic HTTPS.

#### Security

| Guarani | Service | Port(s) | Subdomain | Image |
|---------|---------|---------|-----------|-------|
| — | **Vaultwarden** | 8843 | vault.cronova.dev | vaultwarden/server:1.35.2 |
| — | **vaultwarden-backup** | — | — | bruceforce/vaultwarden-backup |
| Taguato | **Frigate NVR** | 5000, 8554, 8555, 1984 | taguato.cronova.dev | ghcr.io/blakeblackshear/frigate |

Frigate uses OpenVINO GPU detector (iGPU passthrough, ~15ms inference) with VA-API hwaccel. NFS mount to NAS Purple 2TB for recordings. 3 cameras: front_door (192.168.0.110), back_yard (192.168.0.111), indoor Tapo (192.168.0.101, downscaled to 360x640 for CPU-efficient rotation). Face recognition enabled.

#### Automation

| Guarani | Service | Port(s) | Subdomain | Image |
|---------|---------|---------|-----------|-------|
| Jara | **Home Assistant** | 8123 | jara.cronova.dev | homeassistant/home-assistant:stable |
| — | **homeassistant-backup** | — | — | custom restic script |
| — | **Mosquitto** | 1883 | — | eclipse-mosquitto:2.0 |

HA integrations: System Monitor (Docker VM), Proxmox VE (HACS), Glances (NAS), MQTT (Frigate events), Apple TV, LG TV (webOS), HA Companion App. SgtBatten Frigate blueprint for rich push notifications. HACS v2026.2.3 installed.

#### Auth

| Guarani | Service | Port(s) | Subdomain | Image |
|---------|---------|---------|-----------|-------|
| Okẽ | **Authelia** | 9091 | auth.cronova.dev | authelia/authelia |

Protects: Yrasema (Jellyfin), Ysyry (Dozzle), Kuatia (BentoPDF), Mbyja (Homepage), Papa (Grafana), Aranduka (Paperless-ngx). NOT protecting (own auth): Jara, Taguato, Vault, Vera, Forgejo. TOTP 2FA via Authy, filesystem notifier (not SMTP).

#### Media

| Guarani | Service | Port(s) | Subdomain | Image |
|---------|---------|---------|-----------|-------|
| Yrasema | **Jellyfin** | 8096 | yrasema.cronova.dev | jellyfin/jellyfin |
| — | **Sonarr** | 8989 | — | lscr.io/linuxserver/sonarr |
| — | **Radarr** | 7878 | — | lscr.io/linuxserver/radarr |
| — | **Prowlarr** | 9696 | — | lscr.io/linuxserver/prowlarr |
| — | **qBittorrent** | 8081, 6881 | — | lscr.io/linuxserver/qbittorrent |

#### Tools

| Guarani | Service | Port(s) | Subdomain | Image |
|---------|---------|---------|-----------|-------|
| Mbyja | **Homepage** | 3030 | mbyja.cronova.dev | ghcr.io/gethomepage/homepage |
| Ysyry | **Dozzle** | 9999 | ysyry.cronova.dev | amir20/dozzle |
| Kuatia | **BentoPDF** | 8080 | kuatia.cronova.dev | bentopdf (client-side WASM) |

#### Monitoring

| Guarani | Service | Port(s) | Subdomain | Image |
|---------|---------|---------|-----------|-------|
| Papa | **VictoriaMetrics** | 8428 | papa.cronova.dev | victoriametrics/victoria-metrics |
| Papa | **Grafana** | 3000 | papa.cronova.dev/grafana | grafana/grafana |
| Papa | **vmagent** | 8429 | — | victoriametrics/vmagent |
| Papa | **cAdvisor** | 8080 | — | gcr.io/cadvisor/cadvisor |
| Papa | **vmalert** | 8880 | — | victoriametrics/vmalert |
| Papa | **Alertmanager** | 9093 | — | prom/alertmanager |

#### Photos

| Guarani | Service | Port(s) | Subdomain | Image |
|---------|---------|---------|-----------|-------|
| Vera | **Immich Server** | 2283 | vera.cronova.dev | ghcr.io/immich-app/immich-server |
| Vera | **Immich ML** | — | — | ghcr.io/immich-app/immich-machine-learning |
| Vera | **Immich Valkey** | — | — | valkey/valkey |
| Vera | **Immich DB** | — | — | tensorchord/pgvecto-rs |

#### Documents

| Guarani | Service | Port(s) | Subdomain | Image |
|---------|---------|---------|-----------|-------|
| Aranduka | **Paperless-ngx** | 8010 | aranduka.cronova.dev | ghcr.io/paperless-ngx/paperless-ngx |

#### Maintenance

| Service | Purpose | Image |
|---------|---------|-------|
| **Watchtower** | Automatic container updates | nicholas-fedor/watchtower:1.14.2 |

Watchtower uses the maintained fork (nicholas-fedor) — the original containrrr image is abandoned and incompatible with Docker 29+.

### NAS — 19 containers, 24/7

| Guarani | Service | Port(s) | Purpose | Image |
|---------|---------|---------|---------|-------|
| — | **Samba** | 445 | Network file shares | justinpatchett/samba |
| — | **Syncthing** | 8384, 22000 | Peer-to-peer file sync | syncthing/syncthing:2.0.14 |
| — | **Restic REST** | 8000 | Backup target | restic/rest-server:0.14.0 |
| — | **Forgejo** | 3000, 2222 | Git server (SSH + web) | codeberg.org/forgejo/forgejo:11 |
| — | **NFS** | 2049 | Exports Purple 2TB for Frigate | kernel (not containerized) |
| — | **Glances** | 61208 | System monitoring | nicolargo/glances |
| Tajy | **Coolify** | 8888 | PaaS platform | ghcr.io/coollabsio/coolify |
| Tajy | **coolify-db** | — | PostgreSQL for Coolify | postgres:15 |
| Tajy | **coolify-redis** | — | Redis for Coolify | redis:7 |
| Tajy | **coolify-realtime** | 6001 | WebSocket for Coolify | — |
| Tajy | **coolify-proxy** | 80, 443 | Traefik v3.6, TLS DNS-01 | traefik:v3.6 |
| Tajy | **coolify-sentinel** | — | Health monitoring | — |
| Tajy | **coolify-backup** | — | Backup via restic | — |
| — | **Offsite Sync** | — | rclone crypt to Google Drive | custom script |
| — | **Katupyry App** | 8001 | Personal finance tool | custom (FastAPI) |
| — | **Katupyry DB** | — | PostgreSQL for Katupyry | postgres:16 |
| — | **Katupyry Redis** | — | Redis for Katupyry | redis:7 |
| Javya | **Javya App** | 8002 | Worship planning tool | custom (FastAPI) |
| Javya | **Javya DB** | — | PostgreSQL for Javya | postgres:16 |
| Javya | **Javya Redis** | — | Redis for Javya | redis:7 |

Forgejo web: `https://git.cronova.dev` (via Docker VM Caddy). SSH: `git@git.cronova.dev` (routed directly to NAS:2222 via SSH config).

### RPi 5 — Pending

| Service | Port(s) | Purpose |
|---------|---------|---------|
| **OpenClaw** | 18789 | AI assistant (cloud APIs) |

Blocked: 27W PSU in transit.

### Mobile Kit

No Docker services. DNS handled by Beryl AX AdGuard Home.

## Port Allocation

### Full Port Map

| Port | Service | Host | Subdomain |
|------|---------|------|-----------|
| 53 | Pi-hole DNS | Docker VM | — |
| 80 | Caddy HTTP | Docker VM / VPS | — |
| 443 | Caddy HTTPS | Docker VM / VPS | *.cronova.dev |
| 445 | Samba | NAS | — |
| 1883 | Mosquitto MQTT | Docker VM | — |
| 1984 | Frigate go2rtc API | Docker VM | — |
| 2049 | NFS | NAS | — |
| 2222 | Forgejo SSH | NAS | git.cronova.dev |
| 2283 | Immich (Vera) | Docker VM | vera.cronova.dev |
| 3000 | Forgejo Web / Grafana | NAS / Docker VM | git.cronova.dev / papa.cronova.dev |
| 3001 | Uptime Kuma | VPS | — |
| 3030 | Homepage (Mbyja) | Docker VM | mbyja.cronova.dev |
| 3478 | STUN (Headscale) | VPS | — |
| 5000 | Frigate (Taguato) | Docker VM | taguato.cronova.dev |
| 6001 | Coolify Realtime | NAS | — |
| 8000 | Restic REST | NAS | — |
| 8010 | Paperless-ngx (Aranduka) | Docker VM | aranduka.cronova.dev |
| 8053 | Pi-hole Web | Docker VM | — |
| 8096 | Jellyfin (Yrasema) | Docker VM | yrasema.cronova.dev |
| 8123 | Home Assistant (Jara) | Docker VM | jara.cronova.dev |
| 8384 | Syncthing Web | NAS | — |
| 8428 | VictoriaMetrics (Papa) | Docker VM | papa.cronova.dev |
| 8429 | vmagent | Docker VM | — |
| 8554 | Frigate RTSP | Docker VM | — |
| 8555 | Frigate WebRTC | Docker VM | — |
| 8080 | BentoPDF (Kuatia) | Docker VM | kuatia.cronova.dev |
| 8843 | Vaultwarden | Docker VM | vault.cronova.dev |
| 8888 | Coolify (Tajy) | NAS | tajy.cronova.dev |
| 9091 | Authelia (Okẽ) | Docker VM | auth.cronova.dev |
| 9999 | Dozzle (Ysyry) | Docker VM | ysyry.cronova.dev |
| 22000 | Syncthing Sync | NAS | — |
| 61208 | Glances | NAS | — |

### Reserved Ranges

| Range | Purpose |
|-------|---------|
| 53 | DNS (Pi-hole) |
| 80, 443 | HTTP/HTTPS (Caddy, Traefik) |
| 1000-1999 | Infrastructure (MQTT, NFS, go2rtc) |
| 2000-2999 | Git, Immich, Uptime Kuma |
| 3000-3999 | Web UIs (Forgejo, Grafana, Homepage, STUN) |
| 5000-5999 | Frigate, misc |
| 8000-8999 | Web services (Restic, Jellyfin, HA, Caddy admin, etc.) |
| 9000-9999 | Auth, logging |
| 22000+ | Syncthing, Glances |

## Access Matrix

All HTTPS services go through Caddy on Docker VM (DNS-01 TLS via Cloudflare). Pi-hole provides local DNS resolution for `*.cronova.dev → 192.168.0.10`.

| Service | Subdomain | Authelia | Auth Type |
|---------|-----------|----------|-----------|
| Headscale | hs.cronova.dev | No | API key |
| Vaultwarden | vault.cronova.dev | No | Own auth |
| Jara (HA) | jara.cronova.dev | No | Own auth |
| Taguato (Frigate) | taguato.cronova.dev | No | Own auth |
| Vera (Immich) | vera.cronova.dev | No | Own auth |
| Forgejo | git.cronova.dev | No | Own auth |
| Tajy (Coolify) | tajy.cronova.dev | No | Own auth |
| Yrasema (Jellyfin) | yrasema.cronova.dev | Yes | Forward auth |
| Mbyja (Homepage) | mbyja.cronova.dev | Yes | Forward auth |
| Ysyry (Dozzle) | ysyry.cronova.dev | Yes | Forward auth |
| Kuatia (BentoPDF) | kuatia.cronova.dev | Yes | Forward auth |
| Aranduka (Paperless-ngx) | aranduka.cronova.dev | Yes | Forward auth |
| Papa (Grafana) | papa.cronova.dev | Yes | Forward auth |

## Service Dependencies

```
Headscale (VPS)              ← Deploy first (enables mesh)
    └── All other nodes connect via Tailscale

Pi-hole (Docker VM)          ← DNS resolution for *.cronova.dev
    └── All local services need DNS

Caddy (Docker VM)            ← Reverse proxy + TLS
    ├── Authelia (Okẽ)       ← forward_auth middleware
    │   └── Protected services (Yrasema, Mbyja, Ysyry, Kuatia, Papa, Aranduka)
    └── Direct proxy (Jara, Taguato, Vault, Vera, Forgejo)

Mosquitto                    ← MQTT broker
    ├── Frigate (Taguato)    → Publishes detection events
    └── Home Assistant (Jara)→ Subscribes to events

NFS (NAS)                    ← Storage backend
    └── Frigate (Taguato)    → Stores recordings on Purple 2TB

Coolify (Tajy)               ← PaaS on NAS
    ├── coolify-db           → PostgreSQL
    ├── coolify-redis        → Cache
    ├── coolify-proxy        → Traefik (TLS)
    └── coolify-realtime     → WebSocket
```

### Startup Order

**VPS (deploy first):**
1. Headscale → mesh network
2. AdGuard + Unbound (Yvága) → recursive DNS
3. Caddy → reverse proxy
4. DERP → Tailscale relay
5. headscale-backup → DB backups
6. Pi-hole (VPS) → DNS (secondary)
7. Uptime Kuma → monitoring
8. ntfy → notifications
9. changedetection + Playwright → web scraping
10. Restic REST (VPS) → backup target

**NAS:**
1. NFS → storage for Frigate
2. Samba → file shares
3. Syncthing → file sync
4. Restic REST → backup target
5. Forgejo → git server
6. Glances → monitoring
7. Coolify stack → PaaS

**Docker VM:**
1. Pi-hole → DNS
2. Caddy → reverse proxy
3. Watchtower → auto-updates
4. Mosquitto → MQTT
5. Frigate (Taguato) → NVR (needs NFS + MQTT)
6. Home Assistant (Jara) → automation (needs MQTT)
7. Vaultwarden + backup → passwords
8. Authelia (Okẽ) → SSO
9. Remaining services in any order

## Service Criticality

### Critical (24/7 required)

| Guarani | Service | Host | Impact if Down |
|---------|---------|------|----------------|
| — | Headscale | VPS | Mesh network offline, no remote access |
| — | Pi-hole | Docker VM | DNS resolution fails for all local services |
| — | Caddy | Docker VM | No HTTPS, all subdomains unreachable |
| — | Vaultwarden | Docker VM | Password access lost |
| — | Uptime Kuma | VPS | No external monitoring |
| — | ntfy | VPS | No push notifications |

### Important (business hours)

| Guarani | Service | Host | Impact if Down |
|---------|---------|------|----------------|
| Jara | Home Assistant | Docker VM | Automation offline |
| Taguato | Frigate | Docker VM | No camera recording |
| — | Samba | NAS | File shares unavailable |
| — | Forgejo | NAS | Git server offline |
| Tajy | Coolify | NAS | PaaS deployments unavailable |
| — | Restic REST | NAS | Backups fail |

### Optional (on-demand)

| Guarani | Service | Host | Impact if Down |
|---------|---------|------|----------------|
| Yrasema | Jellyfin | Docker VM | Media streaming unavailable |
| Vera | Immich | Docker VM | Photo management unavailable |
| Aranduka | Paperless-ngx | Docker VM | Document management unavailable |
| Kuatia | BentoPDF | Docker VM | PDF tools unavailable |
| Mbyja | Homepage | Docker VM | Dashboard unavailable |
| Ysyry | Dozzle | Docker VM | Log viewer unavailable |
| Papa | VictoriaMetrics | Docker VM | Metrics collection paused |

## Docker Directory Structure

```
docker/
├── fixed/
│   ├── docker-vm/
│   │   ├── networking/
│   │   │   ├── pihole/           # Pi-hole v6
│   │   │   └── caddy/            # Caddy + caddy-dns/cloudflare
│   │   ├── security/
│   │   │   └── docker-compose.yml  # Vaultwarden, Frigate
│   │   ├── automation/
│   │   │   └── docker-compose.yml  # Home Assistant, Mosquitto
│   │   ├── media/
│   │   │   └── docker-compose.yml  # Jellyfin, *arr stack
│   │   ├── auth/
│   │   │   └── docker-compose.yml  # Authelia (Okẽ)
│   │   ├── tools/
│   │   │   └── docker-compose.yml  # Dozzle, BentoPDF, Homepage
│   │   ├── monitoring/
│   │   │   └── docker-compose.yml  # VictoriaMetrics, Grafana, vmagent
│   │   ├── photos/
│   │   │   └── docker-compose.yml  # Immich (Vera)
│   │   ├── documents/
│   │   │   └── docker-compose.yml  # Paperless-ngx (Aranduka)
│   │   └── maintenance/
│   │       └── docker-compose.yml  # Watchtower
│   └── nas/
│       ├── storage/
│       │   └── docker-compose.yml  # Samba, Syncthing
│       ├── backup/
│       │   └── docker-compose.yml  # Restic REST
│       ├── git/
│       │   └── docker-compose.yml  # Forgejo
│       ├── monitoring/
│       │   └── docker-compose.yml  # Glances
│       └── paas/
│           └── docker-compose.yml  # Coolify (Tajy)
├── mobile/
├── vps/
│   ├── networking/                 # Headscale, Caddy
│   ├── monitoring/                 # Uptime Kuma, ntfy
│   ├── scraping/                   # changedetection
│   └── backup/                     # Restic REST
└── shared/
```

## Service Categories

| Category | Services | Count |
|----------|----------|-------|
| Networking | Headscale, Pi-hole, Caddy (x2) | 4 |
| Surveillance | Frigate (Taguato) | 1 |
| Automation | Home Assistant (Jara), Mosquitto | 2 |
| Auth | Authelia (Okẽ), Vaultwarden | 2 |
| Media | Jellyfin (Yrasema), Sonarr, Radarr, Prowlarr, qBittorrent | 5 |
| Photos | Immich (Vera) — 4 containers | 4 |
| Documents | Paperless-ngx (Aranduka), paperless-db, paperless-redis | 3 |
| Tools | Dozzle (Ysyry), BentoPDF (Kuatia), Homepage (Mbyja) | 3 |
| Monitoring | VictoriaMetrics + Grafana + vmagent + vmalert + Alertmanager + cAdvisor (Papa), Uptime Kuma, ntfy, Glances | 10 |
| Storage | Samba, Syncthing, NFS | 3 |
| Backup | Restic REST, headscale-backup, vaultwarden-backup, homeassistant-backup, paperless-backup, immich-backup, coolify-backup, offsite-sync | 8 |
| Maintenance | Watchtower | 1 |
| Git | Forgejo | 1 |
| PaaS | Coolify (Tajy) — 7 containers | 7 |
| AI | OpenClaw (pending) | 1 |

## Guarani Name Reference

| Guarani | Meaning | Service |
|---------|---------|---------|
| Oga | House | Proxmox host |
| Jara | Owner/Lord | Home Assistant |
| Taguato | Hawk | Frigate NVR |
| Yrasema | Nightingale | Jellyfin |
| Mbyja | Firefly | Homepage |
| Ysyry | Stream/Creek | Dozzle |
| Kuatia | Document/Paper | BentoPDF |
| Okẽ | Door | Authelia (auth gateway) |
| Papa | Ancestor/Wise one | VictoriaMetrics + Grafana |
| Vera | Shine/Glow | Immich |
| Aranduka | Library/Book collection | Paperless-ngx |
| Tajy | Lapacho tree | Coolify PaaS |

See [docs/reference/guarani-naming-convention-2026-02-24.md](../reference/guarani-naming-convention-2026-02-24.md) for the full naming guide.
