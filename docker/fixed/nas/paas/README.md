# PaaS Stack - Coolify (tajy)
# Fixed Homelab - NAS (Debian)
# Self-hosted PaaS for deploying web applications

## Overview

Coolify is a self-hosted PaaS (Heroku/Vercel alternative) running on the NAS.
It manages its own compose files, PostgreSQL, Redis, and Traefik dynamically.

**We do NOT use a custom docker-compose.yml for Coolify itself** — that would
break its self-update mechanism. Instead, we use the official manual install
and version-control this documentation + backup sidecar.

- **Guarani name:** tajy (lapacho tree)
- **URL:** `https://tajy.cronova.dev`
- **UI port:** 8888 (changed from default 8000 to avoid conflict with Restic REST)
- **Proxy:** Coolify's built-in Traefik (ports 80/443 on NAS)
- **Data:** `/data/coolify/` (NAS SSD boot drive)

---

## Prerequisites

- Docker and Docker Compose installed on NAS
- Cloudflare API token (Zone/DNS/Edit + Zone/Zone/Read for cronova.dev)
- Pi-hole DNS: `tajy.cronova.dev -> 192.168.0.12` (NAS LAN IP)

---

## Installation (Manual Method)

The official one-liner (`curl ... | bash`) does everything below automatically.
These steps document the same process for full control.

### 1. Create directory structure

```bash
sudo mkdir -p /data/coolify/{source,ssh/{keys,mux},applications,databases,backups,services,proxy,metrics,webhooks-during-maintenance}
sudo mkdir -p /data/coolify/ssh/keys
```

### 2. Generate SSH key for localhost management

Coolify manages the local Docker engine via SSH to itself:

```bash
ssh-keygen -f /data/coolify/ssh/keys/id.root@host.docker.internal -t ed25519 -N '' -C root@coolify
cat /data/coolify/ssh/keys/id.root@host.docker.internal.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

### 3. Download official compose files

```bash
curl -fsSL "https://cdn.coollabs.io/coolify/docker-compose.yml" -o /data/coolify/source/docker-compose.yml
curl -fsSL "https://cdn.coollabs.io/coolify/docker-compose.prod.yml" -o /data/coolify/source/docker-compose.prod.yml
curl -fsSL "https://cdn.coollabs.io/coolify/.env.production" -o /data/coolify/source/.env
```

### 4. Configure environment

Edit `/data/coolify/source/.env`:

```bash
# Generate secrets
sed -i "s|APP_ID=.*|APP_ID=$(openssl rand -hex 16)|" /data/coolify/source/.env
sed -i "s|APP_KEY=.*|APP_KEY=base64:$(openssl rand -base64 32)|" /data/coolify/source/.env
sed -i "s|DB_PASSWORD=.*|DB_PASSWORD=$(openssl rand -base64 32)|" /data/coolify/source/.env
sed -i "s|REDIS_PASSWORD=.*|REDIS_PASSWORD=$(openssl rand -base64 32)|" /data/coolify/source/.env
sed -i "s|PUSHER_APP_ID=.*|PUSHER_APP_ID=$(openssl rand -hex 8)|" /data/coolify/source/.env
sed -i "s|PUSHER_APP_KEY=.*|PUSHER_APP_KEY=$(openssl rand -hex 16)|" /data/coolify/source/.env
sed -i "s|PUSHER_APP_SECRET=.*|PUSHER_APP_SECRET=$(openssl rand -hex 16)|" /data/coolify/source/.env

# Change port from 8000 (conflicts with Restic REST) to 8888
sed -i "s|APP_PORT=.*|APP_PORT=8888|" /data/coolify/source/.env
```

### 5. Create Docker network and start

```bash
docker network create --attachable coolify
cd /data/coolify/source
docker compose up -d --pull always --remove-orphans --force-recreate
```

### 6. Initial setup

1. Open `http://192.168.0.12:8888`
2. Create admin account: `augusto` / `augusto@cronova.dev`
3. Verify localhost server connection works (Settings > Servers)

---

## Traefik DNS-01 Configuration (Cloudflare)

Coolify uses its built-in Traefik for HTTPS. Configure DNS-01 via Cloudflare:

1. Go to Settings > Configuration in Coolify UI
2. Set instance domain to `https://tajy.cronova.dev`
3. Add Cloudflare API token in Settings > Configuration > SSL/TLS
4. Coolify will configure Traefik to use DNS-01 challenge automatically

Alternatively, configure Traefik directly via the Coolify UI dynamic configuration.

---

## Forgejo Integration

Deploy apps directly from the self-hosted Forgejo git server:

### Add Forgejo as Git Source

1. Coolify UI > Sources > Add
2. Type: Custom/Self-hosted
3. URL: `https://git.cronova.dev`
4. API URL: `https://git.cronova.dev/api/v1`
5. Create an OAuth2 Application in Forgejo:
   - Forgejo > Site Administration > Applications
   - Redirect URI: `https://tajy.cronova.dev/webhooks/source`

### Deploy Key (per-repo)

1. Generate key in Coolify when adding a project
2. Add the public key to Forgejo repo > Settings > Deploy Keys
3. Configure webhook: Forgejo repo > Settings > Webhooks > Add Coolify URL

---

## Backup Strategy

### Coolify's Built-in Backups

Coolify includes built-in PostgreSQL database backup (Settings > Backup).
Configure it to dump to `/data/coolify/backups/`.

### Restic Backup Sidecar

The `docker-compose.backup.yml` in this directory runs a restic sidecar that:
- Mounts `/data/coolify/backups` (PostgreSQL dumps) read-only
- Mounts `/data/coolify/ssh/keys` (SSH keys for server management) read-only
- Runs at 3:30 AM PYT (staggered: Vaultwarden 2:00, HA 2:30, Coolify 3:30)
- Pushes to restic REST server at `rest:http://augusto:<pass>@192.168.0.12:8000/augusto/coolify`

Start the backup sidecar:

```bash
cd /opt/homelab/repo/docker/fixed/nas/paas
docker compose -f docker-compose.backup.yml up -d
```

Initialize the restic repo (first time only):

```bash
docker exec coolify-backup restic init
```

---

## Port Allocation

| Port | Service | Notes |
|------|---------|-------|
| 8888 | Coolify UI | Changed from default 8000 (Restic REST conflict) |
| 80 | Traefik HTTP | Redirect to HTTPS |
| 443 | Traefik HTTPS | DNS-01 via Cloudflare |
| 6001 | Coolify WebSocket | Internal (realtime container) |
| 5432 | PostgreSQL | Internal (coolify-db) |
| 6379 | Redis | Internal (coolify-redis) |

---

## Containers

Coolify creates these containers (managed by its own compose):

| Container | Purpose |
|-----------|---------|
| `coolify` | Main application (Laravel) |
| `coolify-db` | PostgreSQL database |
| `coolify-redis` | Redis cache/queue |
| `coolify-realtime` | WebSocket server |
| `coolify-proxy` | Traefik reverse proxy |

Plus the backup sidecar from this repo:

| Container | Purpose |
|-----------|---------|
| `coolify-backup` | Restic backup sidecar |

---

## Verification Checklist

After deployment:

- [ ] All 5 Coolify containers running: `docker ps --filter "name=coolify"`
- [ ] UI accessible: `curl -s -o /dev/null -w "%{http_code}" http://192.168.0.12:8888` (200 or 302)
- [ ] HTTPS working: `curl -s -o /dev/null -w "%{http_code}" https://tajy.cronova.dev` (valid TLS)
- [ ] Existing services unaffected: Forgejo (3000), Glances (61208), Restic (8000)
- [ ] DNS resolves: `dig tajy.cronova.dev @192.168.0.10` returns `192.168.0.12`
- [ ] Admin account created with `augusto@cronova.dev`
- [ ] Forgejo webhook triggers build on `git push`
- [ ] Backup sidecar running: `docker ps --filter "name=coolify-backup"`
- [ ] Restic repo initialized: `docker exec coolify-backup restic snapshots`

---

## Troubleshooting

### Port conflict

If port 8000 error: Restic REST is already using 8000. Verify `APP_PORT=8888` in `.env`.

### Traefik port conflict

If ports 80/443 are in use, check no other proxy is running on the NAS.
The NAS currently has no reverse proxy — Forgejo serves directly on 3000.

### SSH connection to localhost fails

```bash
# Test SSH from Coolify container
docker exec coolify ssh -i /var/www/html/storage/app/ssh/keys/id.root@host.docker.internal root@host.docker.internal
```

### View Coolify logs

```bash
cd /data/coolify/source
docker compose logs -f coolify
docker compose logs -f coolify-proxy
```

### Update Coolify

Coolify has a built-in auto-update mechanism. You can also manually update:

```bash
cd /data/coolify/source
docker compose pull
docker compose up -d --remove-orphans --force-recreate
```
