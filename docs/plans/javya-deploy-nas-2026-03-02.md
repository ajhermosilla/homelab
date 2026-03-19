# Deploy Javya to NAS

**Date**: 2026-03-02
**Status**: Deployed
**Domain**: `javya.cronova.dev`
**Stack**: FastAPI + React 19 + PostgreSQL 16
**Repo**: Forgejo `augusto/javya` (primary), GitHub `ajhermosilla/javya` (private mirror)

## Overview

Javya is a worship planning tool for church teams. Deploy follows the same pattern as Katupyry: Docker Compose on NAS, Caddy reverse proxy on Docker VM.

## Prerequisites

- [ ] Javya repo exists on Forgejo (`git.cronova.dev`)
- [ ] `docker-compose.prod.yml` tested locally
- [ ] NAS `~/deploy/` directory exists (created for Katupyry)
- [ ] Secrets generated and stored in Vaultwarden

## Step 1: Clone to NAS

```bash
ssh nas
cd ~/deploy
git clone git@git.cronova.dev:augusto/javya.git
cd javya
```

## Step 2: Create .env

```bash
cp .env.example .env
```

Edit `.env` with production values:

```bash
# Database
POSTGRES_USER=javya
POSTGRES_PASSWORD=<openssl rand -hex 32>
POSTGRES_DB=javya

# Backend
DEBUG=false
SECRET_KEY=<openssl rand -hex 32>
CORS_ORIGINS=https://javya.cronova.dev

# Frontend
VITE_API_URL=https://javya.cronova.dev/api/v1
VITE_DEFAULT_LANGUAGE=es
```

Store `POSTGRES_PASSWORD` and `SECRET_KEY` in Vaultwarden (tag: `javya`).

## Step 3: Build and Start

```bash
docker compose -f docker-compose.prod.yml build
docker compose -f docker-compose.prod.yml up -d
docker compose -f docker-compose.prod.yml ps
```

Verify:

```bash
# Check containers
docker ps --filter name=javya --format 'table {{.Names}}\t{{.Status}}'

# Check backend health
curl -f http://localhost:8000/docs

# Check logs
docker compose -f docker-compose.prod.yml logs -f
```

## Step 4: DNS (Pi-hole)

Add to Pi-hole custom DNS (same as other `*.cronova.dev` services):

```text
javya.cronova.dev → 192.168.0.10
```

Pi-hole already resolves `*.cronova.dev` to Docker VM Caddy (192.168.0.10) if a wildcard is set. Verify:

```bash
ssh docker-vm "dig javya.cronova.dev @127.0.0.1 +short"
```

If no wildcard, add manually via `pihole.toml` `dns.hosts` entry.

## Step 5: Caddy Reverse Proxy (Docker VM)

Add to Caddyfile on Docker VM (`docker/fixed/docker-vm/networking/caddy/Caddyfile`):

```caddy
# Javya - Worship Planning
# Deployed on NAS, proxied via Docker VM Caddy
javya.cronova.dev {
    import internal_tls
    import security_headers
    reverse_proxy 100.82.77.97:<PORT> {
        header_up X-Real-IP {remote_host}
    }
}
```

Note: Replace `<PORT>` with the port exposed by `docker-compose.prod.yml` frontend container.

Then reload Caddy:

```bash
ssh docker-vm "cd /opt/homelab/repo/docker/fixed/docker-vm/networking/caddy && docker compose restart caddy"
```

## Step 6: Cloudflare DNS

Add `javya.cronova.dev` CNAME or A record in Cloudflare pointing to the VPS/Caddy (if external access needed), or skip if internal-only via Pi-hole.

## Step 7: Verify End-to-End

```bash
# From Mac (via Tailscale/Pi-hole)
curl -s https://javya.cronova.dev | head -5

# Open in browser
open https://javya.cronova.dev
```

Create first admin user via the web UI.

## Step 8: GitHub Mirror

Set up push mirror on Forgejo (same pattern as homelab/notes):

1. Create private repo: `gh repo create ajhermosilla/javya --private -d "Worship planning tool for church teams"`
2. Add SSH push mirror in Forgejo settings for `augusto/javya`
3. Add deploy key (write access) on GitHub
4. Enable `sync_on_commit` (via SQLite if needed)

## Step 9: Mobile Access (Beryl AX)

Add AdGuard DNS rewrite:

```text
javya.cronova.dev → 100.82.77.97
```

Or if routed through Docker VM Caddy:

```text
javya.cronova.dev → 100.68.63.168
```

## Step 10: Restic Backup

Add backup sidecar or cron job for `javya_postgres_data` volume:

```bash
# Manual test
docker run --rm -v javya_postgres_data:/data:ro \
  -e RESTIC_REPOSITORY=rest:http://augusto:<pass>@192.168.0.12:8000/augusto/javya \
  -e RESTIC_PASSWORD=<restic-pass> \
  restic/restic:0.16.4 backup /data --tag javya
```

Schedule: 3:00 AM PYT (between HA 2:30 AM and Coolify 3:30 AM).

## Post-Deploy Checklist

- [ ] All 3 containers healthy (`javya-db`, `javya-backend`, `javya-frontend`)
- [ ] HTTPS working at `javya.cronova.dev`
- [ ] Admin user created
- [ ] Credentials in Vaultwarden (tag: `javya`)
- [ ] GitHub mirror configured
- [ ] Beryl AX DNS rewrite added
- [ ] Restic backup scheduled
- [ ] Update MEMORY.md and session notes
- [ ] Add to Uptime Kuma monitors (Phase 2: high priority)

## Resource Estimates

| Container | RAM | CPU |
|-----------|-----|-----|
| javya-db | 512M | 1.0 |
| javya-backend | 256M | 0.5 |
| javya-frontend | 128M | 0.25 |
| **Total**|**~900M**|**1.75** |

NAS (i3-3220T, 8GB RAM) can handle this alongside existing 16 containers.

## Reference: Katupyry Pattern

| Aspect | Katupyry | Javya |
|--------|----------|-------|
| NAS path | `~/deploy/katupyry/` | `~/deploy/javya/` |
| Domain | `katupyry.cronova.dev` | `javya.cronova.dev` |
| DB volume | `katupyry_postgres_data` | `javya_postgres_data` |
| Compose | `docker-compose.prod.yml` | `docker-compose.prod.yml` |
| Proxy | Caddy (Docker VM) → NAS | Caddy (Docker VM) → NAS |
