# Docker Configuration

Docker Compose configurations for all homelab services.

## Directory Structure

```
docker/
├── fixed/                    # Fixed Homelab (24/7)
│   ├── docker-vm/           # Docker VM on Proxmox
│   │   ├── networking/      # Pi-hole, Caddy
│   │   ├── media/           # Jellyfin, *arr stack
│   │   ├── automation/      # Home Assistant, Mosquitto
│   │   └── security/        # Vaultwarden, Frigate
│   └── nas/                 # NAS (Debian)
│       ├── storage/         # Samba, Syncthing
│       ├── backup/          # Restic REST
│       └── git/             # Forgejo
├── mobile/                   # Mobile Kit (On-Demand)
│   └── rpi5/
│       └── networking/      # Pi-hole
├── vps/                      # VPS (24/7)
│   ├── networking/          # Headscale, Caddy, DERP, Pi-hole
│   ├── monitoring/          # Uptime Kuma, ntfy
│   ├── scraping/            # changedetection.io
│   └── backup/              # Restic REST
└── shared/                   # Shared env files
```

## Network Strategy

### Docker VM - Inter-Service Communication

Services on Docker VM need to communicate:

```
┌─────────────────────────────────────────────────────────────┐
│                      Docker VM                               │
│                                                              │
│  ┌─────────┐    ┌──────────┐    ┌──────────┐               │
│  │ Caddy   │───▶│ Services │    │ Frigate  │               │
│  │ :80/443 │    │ (various)│    │ :5000    │               │
│  └─────────┘    └──────────┘    └────┬─────┘               │
│       │                              │                      │
│       │ host.docker.internal         │ MQTT                 │
│       ▼                              ▼                      │
│  ┌─────────────────────────────────────────┐               │
│  │              Host Network               │               │
│  │  localhost:8096 (Jellyfin)              │               │
│  │  localhost:8123 (Home Assistant)        │               │
│  │  localhost:1883 (Mosquitto)             │               │
│  │  localhost:8843 (Vaultwarden)           │               │
│  └─────────────────────────────────────────┘               │
└─────────────────────────────────────────────────────────────┘
```

**Approach:** Use `host.docker.internal` for Caddy to reach services.

Each compose file creates its own network, but services are exposed on host ports.
Caddy uses `extra_hosts: ["host.docker.internal:host-gateway"]` to resolve localhost.

### Cross-Service Communication

| From | To | Method |
|------|-----|--------|
| Caddy | All services | `host.docker.internal:PORT` |
| Frigate | Mosquitto | Same compose (automation-net) or `host.docker.internal:1883` |
| Home Assistant | Mosquitto | Same compose (automation-net) |
| *arr stack | qBittorrent | Same compose (media-net) |

### Option: Shared External Network

For tighter integration, create a shared network:

```bash
# Create external network
docker network create homelab-net

# In each docker-compose.yml, add:
networks:
  homelab-net:
    external: true
```

Then services can communicate by container name (e.g., `http://jellyfin:8096`).

**Current approach:** Host port binding (simpler, works across compose files).

## Deployment Order

### VPS (First)

1. `networking/headscale` - Mesh coordination
2. `networking/caddy` - Reverse proxy
3. `networking/derp` - NAT traversal
4. `monitoring/` - Uptime Kuma + ntfy
5. `backup/` - Restic REST

### Fixed Homelab - Docker VM

1. `networking/pihole` - DNS
2. `networking/caddy` - Internal reverse proxy
3. `automation/` - Home Assistant + Mosquitto
4. `security/` - Vaultwarden + Frigate
5. `media/` - Jellyfin + *arr stack

### Fixed Homelab - NAS

1. `storage/` - Samba + Syncthing
2. `backup/` - Restic REST

### Mobile Kit

1. `networking/pihole` - DNS only (Headscale on VPS)

## Environment Files

Each directory has a `.env.example` template:

```bash
# Copy and customize
cp .env.example .env
nano .env

# Start services
docker compose up -d
```

## Common Commands

```bash
# Start all services in a stack
docker compose up -d

# View logs
docker compose logs -f

# Stop services
docker compose down

# Update images
docker compose pull && docker compose up -d

# View running containers
docker ps

# Interactive management
lazydocker
```

## Secrets Management

Sensitive values in `.env` files:
- Passwords, API keys, tokens
- Not committed to git (in .gitignore)

Future: SOPS + age encryption for secrets in git.

## Backup

Docker volumes are backed up via Restic:

```bash
# Backup all volumes
docker run --rm -v volume_name:/data alpine tar -czf - /data | \
  restic -r rest:http://$RESTIC_USER:$RESTIC_HTPASSWD@nas:8000/docker backup --stdin

# Or backup specific paths
restic backup /var/lib/docker/volumes/
```

See `docs/disaster-recovery.md` for full backup procedures.
