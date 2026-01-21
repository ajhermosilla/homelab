# Caddy - Reverse Proxy

Automatic HTTPS reverse proxy for all VPS services.

## Services

| Domain | Service | Port |
|--------|---------|------|
| hs.cronova.dev | Headscale | 8080 |
| status.cronova.dev | Uptime Kuma | 3001 |
| notify.cronova.dev | ntfy | 80 |
| watch.cronova.dev | changedetection | 5000 |

## Quick Start

```bash
# Create required external networks
docker network create headscale-net || true
docker network create monitoring-net || true

# Start Caddy
docker compose up -d
```

## Adding Services

1. Edit `Caddyfile`:
   ```
   newservice.cronova.dev {
       reverse_proxy container:port
   }
   ```

2. Reload Caddy:
   ```bash
   docker exec caddy caddy reload --config /etc/caddy/Caddyfile
   ```

## Commands

```bash
# Reload config
docker exec caddy caddy reload --config /etc/caddy/Caddyfile

# Validate config
docker exec caddy caddy validate --config /etc/caddy/Caddyfile

# View logs
docker logs -f caddy
```
