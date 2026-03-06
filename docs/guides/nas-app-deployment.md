# NAS App Deployment Guide

How to deploy FastAPI + React + PostgreSQL apps on the NAS using manual Docker Compose with Coolify's Traefik for routing and TLS.

## Background

The NAS runs Coolify (tajy) as its PaaS, but Coolify v4 beta cannot deploy from a local Forgejo instance (see [Lessons Learned](#lessons-learned)). Instead, apps are deployed as standalone Docker Compose stacks that share Coolify's `coolify` Docker network and Traefik reverse proxy.

**Deployed apps using this pattern:**
- **Katupyry** — Personal finance (FastAPI + React + PostgreSQL)
- **Javya** — Worship planning (FastAPI + React + PostgreSQL)

## Architecture

```
Internet → Cloudflare DNS → Tailscale (Headscale) → NAS
  → Traefik (Coolify) :443 → coolify Docker network
    → app-frontend:80     (javya.cronova.dev)
    → app-backend:8000    (javya-api.cronova.dev, if exposed)
    → app-frontend:80     (katupyry.cronova.dev, backend internal only)
```

Key points:
- **No published ports** — containers are only reachable via Traefik through the `coolify` network
- **TLS termination** — Traefik handles Let's Encrypt certificates (DNS-01 via Cloudflare)
- **Two routing patterns**: frontend-only (Katupyry) or frontend + API (Javya)

## Prerequisites

Before deploying, ensure:
- [ ] App repo exists on Forgejo (`git.cronova.dev`)
- [ ] App has a `docker-compose.prod.yml` (or similar) and Dockerfiles for backend/frontend
- [ ] DNS records exist in **Pi-hole** (LAN) and **Headscale extra_records** (Tailscale)
- [ ] Secrets generated and stored in Vaultwarden
- [ ] NAS has enough resources (~900MB RAM per app: 512M DB + 256M backend + 128M frontend)

## Step-by-Step Deployment

### 1. Clone the repo on NAS

```bash
ssh nas
cd ~/deploy
git clone http://localhost:3000/augusto/<app>.git
cd <app>
```

> Forgejo runs on NAS at `localhost:3000` (HTTP). No SSH key needed for clone.

### 2. Create the .env file

Generate secrets:

```bash
openssl rand -hex 32  # POSTGRES_PASSWORD
openssl rand -hex 32  # SECRET_KEY
```

Create `.env`:

```bash
cat > .env << 'EOF'
POSTGRES_PASSWORD=<generated>
SECRET_KEY=<generated>
CORS_ORIGINS=https://<app>.cronova.dev
VITE_API_URL=https://<app>-api.cronova.dev/api/v1
EOF
```

Store all secrets in Vaultwarden immediately.

### 3. Modify docker-compose.prod.yml

Adapt the compose file for the Coolify/Traefik pattern:

**Remove** from all services:
- `ports:` — Traefik routes traffic, no host port publishing needed

**Add** to services that Traefik needs to reach (frontend always, backend if API is exposed externally):

```yaml
services:
  backend:  # only if API is exposed externally
    # ... existing config ...
    networks:
      default:
      coolify:
        aliases:
          - <app>-backend

  frontend:
    # ... existing config ...
    networks:
      default:
      coolify:
        aliases:
          - <app>-frontend

networks:
  coolify:
    external: true
```

**Remove** `version: '3.8'` (deprecated in Compose v5).

**Fix healthchecks** — `python:3.12-slim` images don't have `curl`. Use Python:

```yaml
# Bad (curl not available in slim images)
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:8000/health"]

# Good
healthcheck:
  test: ["CMD", "python", "-c", "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')"]
```

### 4. Create Traefik dynamic config

Create via a Docker alpine container (NAS sudo requires password):

```bash
docker run --rm -v /data/coolify/proxy/dynamic:/dynamic alpine sh -c 'cat > /dynamic/<app>.yaml << "EOF"
http:
  routers:
    <app>-http:
      entryPoints:
        - http
      service: <app>-frontend
      rule: Host(`<app>.cronova.dev`)
      middlewares:
        - redirect-to-https
    <app>-https:
      entryPoints:
        - https
      service: <app>-frontend
      rule: Host(`<app>.cronova.dev`)
      tls:
        certresolver: letsencrypt
  services:
    <app>-frontend:
      loadBalancer:
        servers:
          - url: http://<app>-frontend:80
EOF'
```

If the backend API is exposed externally (like Javya), add additional routers/services for `<app>-api.cronova.dev` pointing to `<app>-backend:8000`.

Traefik picks up new files automatically — no restart needed.

### 5. Configure DNS

**Pi-hole** (LAN resolution) — add entries pointing to NAS LAN IP:

```bash
ssh docker-vm "docker exec pihole pihole-FTL --config dns.hosts"
# Add: "192.168.0.12 <app>.cronova.dev" (and <app>-api.cronova.dev if needed)
```

**Headscale** (Tailscale resolution) — add extra_records pointing to NAS Tailscale IP:

```bash
ssh vps "sudo vi /opt/homelab/headscale/config/config.yaml"
# Add under dns_config.extra_records:
#   - name: "<app>.cronova.dev"
#     type: "A"
#     value: "100.82.77.97"
ssh vps "cd /opt/homelab/headscale && sudo docker compose restart headscale"
```

### 6. Build and deploy

```bash
ssh nas "cd ~/deploy/<app> && docker compose -f docker-compose.prod.yml up -d --build"
```

Wait ~60s, then verify:

```bash
# Check health
ssh nas "docker ps --filter name=<app> --format 'table {{.Names}}\t{{.Status}}'"

# Test HTTPS
curl -s -o /dev/null -w '%{http_code}' https://<app>.cronova.dev
```

### 7. Add Uptime Kuma monitors

Add via the web UI at `https://status.cronova.dev` (username: `ajhermosilla`):

| Field | Value |
|-------|-------|
| Type | HTTP(s) |
| URL | `https://<app>.cronova.dev` |
| Interval | 60s |
| Notification | ntfy (Warning) |

> kuma-cli v2.0.0 is installed on VPS but incompatible with Uptime Kuma 1.23.17 (`conditions` column mismatch). Use the web UI until Uptime Kuma is upgraded.

### 8. Commit config to homelab repo

Add compose and Traefik config under `docker/fixed/nas/<app>/`:

```
docker/fixed/nas/<app>/
├── docker-compose.yml    # Reference copy of production compose
├── .env.example          # Template (no secrets)
└── traefik-dynamic.yaml  # Copy of /data/coolify/proxy/dynamic/<app>.yaml
```

## Updating an App

```bash
ssh nas
cd ~/deploy/<app>
git pull
docker compose -f docker-compose.prod.yml up -d --build
```

For `.env` changes, force-recreate (Compose v5 doesn't detect `.env` changes):

```bash
docker compose -f docker-compose.prod.yml up -d --force-recreate
```

## Deployed Apps Reference

| App | URL | API URL | Deploy Path | Traefik Config |
|-----|-----|---------|-------------|----------------|
| Katupyry | katupyry.cronova.dev | (internal) | ~/deploy/katupyry/ | /data/coolify/proxy/dynamic/katupyry.yaml |
| Javya | javya.cronova.dev | javya-api.cronova.dev | ~/deploy/javya/ | /data/coolify/proxy/dynamic/javya.yaml |

### Differences Between Apps

| Aspect | Katupyry | Javya |
|--------|----------|-------|
| API routing | Internal only (frontend proxies) | External (`javya-api.cronova.dev`) |
| Coolify network | Frontend only | Frontend + backend |
| Container names | Default (compose-generated) | Explicit (`container_name:`) |
| Backend healthcheck | Python urllib | Python urllib |
| Extra volumes | `uploads_data` | None |

## Lessons Learned

### Coolify v4 Beta Is Not Viable for Local Forgejo

We spent significant time trying to deploy Javya via Coolify's UI. The blockers are architectural:

1. **URL validation** — Rejects `localhost`, IP addresses, and `ssh://` scheme. Only accepts `https://`, `http://`, `git://`, or `git@host:repo` format.
2. **SSH helper containers** — Coolify clones repos inside helper containers that use Docker's embedded DNS, not the host's `/etc/hosts`. Adding `192.168.0.12 git.cronova.dev` to NAS `/etc/hosts` doesn't help.
3. **GIT_SSH_COMMAND wrapping** — Even HTTP URLs get wrapped with SSH when a Deploy Key is configured, making HTTP-based workarounds fail too.
4. **Port mismatch** — Forgejo SSH runs on port 2222, but `git@git.cronova.dev:2222/...` syntax doesn't work as expected in Coolify.

**Conclusion**: Until Coolify v4 supports local/private git servers properly, use manual Docker Compose. The manual approach is actually simpler and more transparent.

### Healthcheck Gotchas

- `python:3.12-slim` does not include `curl`. Use `python -c "import urllib.request; ..."` for healthchecks.
- `nginx:alpine` includes `curl` — frontend healthchecks with curl are fine.
- An unhealthy container still serves traffic — healthcheck status is informational for Docker and monitoring, not a circuit breaker.

### NAS-Specific Issues

- **sudo requires password** — Use `docker run --rm -v /path:/mount alpine` to write root-owned files.
- **`sed -i` creates new inode** — Can't use it on bind-mounted files like `/etc/hosts`. Use `grep -v > tmp && cat tmp > file` pattern instead.
- **Docker data-root is `/data/docker`** — Not the default `/var/lib/docker` (only 6G on `/var`).

### Compose v5 Behavior

- `.env` changes are not detected by `docker compose up -d`. Use `--force-recreate`.
- `.env` vars auto-inject into containers. Escape `$` as `$$` for Argon2 hashes.
- `version:` key is deprecated — omit it.

## Quick Reference: Deploy a New App

```bash
# 1. Clone
ssh nas "cd ~/deploy && git clone http://localhost:3000/augusto/<app>.git"

# 2. Create .env (from Mac, paste secrets)
ssh nas 'printf "POSTGRES_PASSWORD=<pw>\nSECRET_KEY=<key>\nCORS_ORIGINS=https://<app>.cronova.dev\nVITE_API_URL=https://<app>-api.cronova.dev/api/v1\n" > ~/deploy/<app>/.env'

# 3. Edit compose: remove ports, add coolify network + aliases, fix healthchecks

# 4. Create Traefik config
ssh nas "docker run --rm -v /data/coolify/proxy/dynamic:/dynamic alpine sh -c 'cat > /dynamic/<app>.yaml << \"EOF\"
...
EOF'"

# 5. DNS: add to Pi-hole (LAN) + Headscale extra_records (Tailscale), restart Headscale

# 6. Deploy
ssh nas "cd ~/deploy/<app> && docker compose -f docker-compose.prod.yml up -d --build"

# 7. Verify
curl -s -o /dev/null -w '%{http_code}' https://<app>.cronova.dev

# 8. Add Uptime Kuma monitors via UI

# 9. Commit config to homelab repo under docker/fixed/nas/<app>/
```
