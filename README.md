# Homelab

[![CI](https://github.com/ajhermosilla/homelab/actions/workflows/ci.yml/badge.svg)](https://github.com/ajhermosilla/homelab/actions/workflows/ci.yml)
[![Docs](https://img.shields.io/badge/docs-docs.cronova.dev-00d4aa)](https://docs.cronova.dev)

Personal infrastructure as code. Self-hosted services across three environments, connected by a Tailscale mesh network over cronova.dev.

All services are named in **Guarani** (the indigenous language of Paraguay) as a nod to home. English descriptions follow each name.

> 68 services | 66+ containers | 3 environments | 8 Tailscale nodes

## Architecture

```
[Mobile Kit]              [Fixed Homelab]                     [VPS - Vultr]
On-demand                 24/7                                24/7
├── MacBook Air M1        ├── Oga — Proxmox VE (Mini PC)     ├── Headscale
├── Beryl AX Router       │   ├── OPNsense VM (gateway)      ├── Caddy
└── Samsung A13/A16       │   └── Docker VM (9GB RAM)         ├── Uptime Kuma
                          │       ├── Pi-hole (DNS)           ├── ntfy
                          │       ├── Caddy (reverse proxy)   └── headscale-backup
                          │       ├── Taguato — Frigate NVR
                          │       ├── Jara — Home Assistant
                          │       ├── Okẽ — Authelia (SSO)
                          │       ├── Vault — Vaultwarden
                          │       ├── Yrasema — Jellyfin
                          │       ├── Mbyja — Homepage
                          │       ├── Ysyry — Dozzle
                          │       ├── Kuatia — BentoPDF
                          │       ├── Papa — VictoriaMetrics + Grafana
                          │       ├── Vera — Immich
                          │       ├── Aranduka — Paperless-ngx
                          │       ├── Mosquitto, Watchtower
                          │       └── Backup containers
                          ├── NAS (Mini-ITX i3)
                          │   ├── Forgejo (git)
                          │   ├── Tajy — Coolify PaaS
                          │   ├── Samba, Syncthing, NFS
                          │   ├── Restic REST, Glances
                          │   └── Coolify sub-containers
                          ├── RPi 5 — OpenClaw (pending)
                          └── Networking gear
                              ├── MokerLink 2.5G switch
                              ├── TP-Link PoE switch + 3 cameras
                              └── TP-Link Archer AX50 AP
```

## Environments

| Environment | Host | Status | Containers |
|-------------|------|--------|------------|
| **VPS** | Vultr (1 vCPU, 1GB) | Active | 12 |
| **Docker VM** | Proxmox VM 101 (9GB RAM) | Active | 36 |
| **NAS** | Mini-ITX i3-3220T | Active | 19 |
| **RPi 5** | OpenClaw | Pending (PSU in transit) | - |
| **Mobile Kit** | MacBook + Beryl AX | Active | - |

## Key Services

| Guarani Name | Service | Subdomain | Purpose |
|--------------|---------|-----------|---------|
| — | Headscale | hs.cronova.dev | Tailscale coordination server |
| — | Pi-hole | local | DNS ad-blocking |
| — | Caddy | — | Reverse proxy, auto-TLS |
| Taguato | Frigate NVR | taguato.cronova.dev | AI camera surveillance |
| Jara | Home Assistant | jara.cronova.dev | Home automation |
| Okẽ | Authelia | auth.cronova.dev | SSO / forward auth |
| — | Vaultwarden | vault.cronova.dev | Password manager |
| Yrasema | Jellyfin | yrasema.cronova.dev | Media streaming |
| Mbyja | Homepage | mbyja.cronova.dev | Dashboard |
| Ysyry | Dozzle | ysyry.cronova.dev | Container log viewer |
| Kuatia | BentoPDF | kuatia.cronova.dev | PDF tools |
| Papa | VictoriaMetrics | papa.cronova.dev | Metrics + Grafana |
| Vera | Immich | vera.cronova.dev | Photo management |
| Aranduka | Paperless-ngx | aranduka.cronova.dev | Document management |
| Tajy | Coolify | tajy.cronova.dev | PaaS (NAS) |
| — | Forgejo | git.cronova.dev | Git server |
| — | Uptime Kuma | tailscale only | External monitoring |
| — | ntfy | tailscale only | Push notifications |

Full inventory: [docs/architecture/services.md](docs/architecture/services.md)

## Network

- **Domain**: cronova.dev (Cloudflare DNS)
- **Gateway**: OPNsense VM (replaced ISP router 2026-02-21)
- **Mesh**: Headscale (self-hosted Tailscale) — 8 nodes
- **DNS**: Pi-hole (Docker VM) + AdGuard Home (Beryl AX mobile)
- **Reverse Proxy**: Caddy with DNS-01 Cloudflare TLS (Docker VM), Caddy (VPS), Traefik (Coolify/NAS)
- **VLANs**: Management (default), IoT (VLAN 10), Guest (VLAN 20)
- **LAN**: 192.168.0.0/24 via MokerLink 2.5G switch
- **Auth**: Authelia (Okẽ) protects services behind Caddy forward_auth

## Directory Structure

```
homelab/
├── docker/                    # Docker Compose files
│   ├── fixed/
│   │   ├── docker-vm/         # Docker VM stacks
│   │   │   ├── networking/    #   Pi-hole, Caddy
│   │   │   ├── security/      #   Vaultwarden, Frigate
│   │   │   ├── automation/    #   Home Assistant, Mosquitto
│   │   │   ├── media/         #   Jellyfin, *arr stack
│   │   │   ├── auth/          #   Authelia (Okẽ)
│   │   │   ├── tools/         #   Dozzle, BentoPDF, Homepage
│   │   │   ├── monitoring/    #   VictoriaMetrics, Grafana
│   │   │   ├── photos/        #   Immich (Vera)
│   │   │   ├── documents/     #   Paperless-ngx (Aranduka)
│   │   │   └── maintenance/   #   Watchtower
│   │   └── nas/               # NAS stacks
│   │       ├── storage/       #   Samba, Syncthing
│   │       ├── backup/        #   Restic REST
│   │       ├── git/           #   Forgejo
│   │       ├── monitoring/    #   Glances
│   │       └── paas/          #   Coolify (Tajy)
│   ├── mobile/                # Mobile kit
│   ├── vps/                   # VPS services
│   └── shared/                # Shared env files
├── ansible/                   # Automation playbooks
├── docs/                      # Documentation
│   ├── architecture/          #   Core infra docs
│   ├── guides/                #   Setup & operational guides
│   ├── strategy/              #   Design decisions
│   ├── reference/             #   Device guides, research
│   ├── plans/                 #   Future plans (dated)
│   ├── journal/               #   Execution logs, sessions
│   └── html/                  #   Generated HTML
├── scripts/                   # Utility scripts
└── CLAUDE.md                  # AI assistant context
```

## Documentation

| Category | Path | Contents |
|----------|------|----------|
| **Architecture** | [docs/architecture/](docs/architecture/) | Services inventory, hardware, network topology |
| **Guides** | [docs/guides/](docs/guides/) | Proxmox, OPNsense, NFS, Caddy, NAS setup |
| **Strategy** | [docs/strategy/](docs/strategy/) | DNS, certificates, monitoring, DR, security |
| **Reference** | [docs/reference/](docs/reference/) | Guarani naming, devices, Tailscale primer |
| **Plans** | [docs/plans/](docs/plans/) | iGPU passthrough, HA dashboard, expansion ideas |
| **Journal** | [docs/journal/](docs/journal/) | Cutover logs, recovery reports, session notes |

See [docs/README.md](docs/README.md) for the full documentation index.

## Tech Stack

| Layer | Tools |
|-------|-------|
| **Virtualization** | Proxmox VE 8 |
| **Firewall** | OPNsense |
| **Containers** | Docker, Docker Compose v5 |
| **PaaS** | Coolify (Tajy) |
| **Reverse Proxy** | Caddy (DNS-01 Cloudflare), Traefik (Coolify) |
| **DNS** | Pi-hole v6, AdGuard Home |
| **VPN/Mesh** | Headscale (self-hosted Tailscale) |
| **Auth** | Authelia, Vaultwarden |
| **Monitoring** | VictoriaMetrics, Grafana, Uptime Kuma, Dozzle, Glances |
| **Backup** | Restic REST Server |
| **Automation** | Ansible, Home Assistant |
| **Git** | Forgejo (self-hosted) |
| **IaC** | This repo |

## Deployment

1. **VPS** first — Headscale enables the mesh network
2. **Fixed Homelab** — Proxmox → OPNsense → Docker VM → NAS
3. **Mobile Kit** — Beryl AX connects via Tailscale

See [docs/guides/deployment-order.md](docs/guides/deployment-order.md) for the full sequence.

## For External Readers

This is a personal infrastructure repo, not a deployable template. It documents a specific homelab setup and may reference private infrastructure. Feel free to browse the [documentation](https://docs.cronova.dev), borrow ideas, and adapt patterns to your own setup.

---

**Owner**: Augusto Hermosilla — augusto@hermosilla.me
