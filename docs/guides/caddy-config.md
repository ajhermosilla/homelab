# Caddy Reverse Proxy Configuration

Caddy configuration for cronova.dev and verava.ai across all environments. Created 2026-01-14.

> **WARNING (2026-03-10):** This doc is a pre-deployment design from January 2026 and does NOT reflect the current Caddyfile. Key differences:
>
> - Docker VM Caddy is a **custom build** with `caddy-dns/cloudflare` for DNS-01 TLS (not Let's Encrypt ACME)
> - **Authelia forward auth** protects 6 services (not shown below)
> - **BentoPDF** replaced Stirling-PDF (Kuatia)
> - Many subdomains below (api.cronova.dev, saas.cronova.dev, app.verava.ai) are speculative and don't exist
> - Actual Caddyfile: `docker/fixed/docker-vm/networking/caddy/Caddyfile`
> - See `services.md` for the current access matrix

## Overview

```text
┌─────────────────────────────────────────────────────────────────────────┐
│                              INTERNET                                    │
└───────────────────────────────────┬─────────────────────────────────────┘
                                    │
                             [Cloudflare]
                              DNS + CDN
                                    │
                    ┌───────────────┼───────────────┐
                    │               │               │
             [Cloudflare      [VPS Caddy]    [Tailscale]
               Pages]         Public Proxy    Internal Only
                    │               │               │
              ┌─────┴─────┐   ┌─────┴─────┐   ┌─────┴─────┐
              │           │   │           │   │           │
         www.cronova  docs.  vault.    www.   home.    media.
         cronova.dev  cronova status.  verava cronova  cronova
                             notify.   app.   btc.     nas.
                             api.      api.   git.
                             saas.
└─────────────────────────────────────────────────────────────────────────┘
```

## Traffic Routing

| Subdomain | Destination | Access |
|-----------|-------------|--------|

| `<www.cronova.dev>` | Cloudflare Pages | Public |
| `docs.cronova.dev` | Cloudflare Pages | Public |
| `vault.cronova.dev` | VPS → Fixed Homelab (Tailscale) | Public |
| `status.cronova.dev` | VPS localhost:3001 | Public |
| `notify.cronova.dev` | VPS localhost:80 | Public |
| `api.cronova.dev` | VPS localhost:8080 | Public |
| `saas.cronova.dev` | VPS localhost:3000 | Public |
| `<www.verava.ai>` | VPS static files | Public |
| `app.verava.ai` | VPS localhost:4000 | Public |
| `api.verava.ai` | VPS localhost:4001 | Public |
| `jara.cronova.dev` | Fixed Homelab (Tailscale only) | Private |
| `yrasema.cronova.dev` | Fixed Homelab (Tailscale only) | Private |
| `btc.cronova.dev` | RPi 4 Start9 (Tailscale only) | Private |
| `nas.cronova.dev` | NAS (Tailscale only) | Private |
| `git.cronova.dev` | MacBook (Tailscale only) | Private |

---

## VPS Caddyfile

Primary reverse proxy for all public services.

```caddyfile
# =============================================================================
# VPS Caddyfile - cronova.dev + verava.ai
# Location: /etc/caddy/Caddyfile
# =============================================================================

# Global options
{
    email augusto@cronova.dev

    # Staging for testing (uncomment to avoid rate limits)
    # acme_ca https://acme-staging-v02.api.letsencrypt.org/directory
}

# =============================================================================
# CRONOVA.DEV - Developer/Homelab Services
# =============================================================================

# Root redirect
cronova.dev {
    redir https://www.cronova.dev{uri} permanent
}

# Vault - Password manager (proxied to Fixed Homelab via Tailscale)
vault.cronova.dev {
    reverse_proxy 100.68.63.168:8843 {
        # Health check
        health_uri /alive
        health_interval 30s

        # Timeouts
        transport http {
            dial_timeout 10s
            response_header_timeout 30s
        }
    }

    # Security headers
    header {
        Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
        X-Content-Type-Options "nosniff"
        X-Frame-Options "SAMEORIGIN"
        Referrer-Policy "strict-origin-when-cross-origin"
    }
}

# Status - Uptime monitoring
status.cronova.dev {
    reverse_proxy localhost:3001

    header {
        Strict-Transport-Security "max-age=31536000; includeSubDomains"
        X-Content-Type-Options "nosniff"
    }
}

# Notify - Push notifications
notify.cronova.dev {
    reverse_proxy localhost:80

    header {
        Strict-Transport-Security "max-age=31536000; includeSubDomains"
        X-Content-Type-Options "nosniff"
    }
}

# API - Public developer APIs
api.cronova.dev {
    reverse_proxy localhost:8080

    header {
        Strict-Transport-Security "max-age=31536000; includeSubDomains"
        X-Content-Type-Options "nosniff"
        # CORS for API
        Access-Control-Allow-Origin "*"
        Access-Control-Allow-Methods "GET, POST, OPTIONS"
        Access-Control-Allow-Headers "Content-Type, Authorization"
    }
}

# SaaS - Micro SaaS applications
saas.cronova.dev {
    reverse_proxy localhost:3000

    header {
        Strict-Transport-Security "max-age=31536000; includeSubDomains"
        X-Content-Type-Options "nosniff"
        X-Frame-Options "SAMEORIGIN"
    }
}

# =============================================================================
# VERAVA.AI - Business/Supply Chain Services
# =============================================================================

# Root redirect
verava.ai {
    redir https://www.verava.ai{uri} permanent
}

# Main website
www.verava.ai {
    root * /var/www/verava
    file_server

    # Try files, then index
    try_files {path} /index.html

    header {
        Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
        X-Content-Type-Options "nosniff"
        X-Frame-Options "DENY"
        Referrer-Policy "strict-origin-when-cross-origin"
        Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'"
    }

    # Cache static assets
    @static {
        path *.css *.js *.png *.jpg *.jpeg *.gif *.ico *.svg *.woff *.woff2
    }
    header @static Cache-Control "public, max-age=31536000"
}

# Customer application
app.verava.ai {
    reverse_proxy localhost:4000

    header {
        Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
        X-Content-Type-Options "nosniff"
        X-Frame-Options "SAMEORIGIN"
        Referrer-Policy "strict-origin-when-cross-origin"
    }
}

# Customer API
api.verava.ai {
    reverse_proxy localhost:4001

    header {
        Strict-Transport-Security "max-age=31536000; includeSubDomains"
        X-Content-Type-Options "nosniff"
        # CORS for authenticated API
        Access-Control-Allow-Origin "https://app.verava.ai"
        Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS"
        Access-Control-Allow-Headers "Content-Type, Authorization"
        Access-Control-Allow-Credentials "true"
    }
}

# Documentation
docs.verava.ai {
    root * /var/www/verava-docs
    file_server

    try_files {path} /index.html

    header {
        Strict-Transport-Security "max-age=31536000; includeSubDomains"
        X-Content-Type-Options "nosniff"
    }
}
```

---

## Fixed Homelab Caddyfile

Internal reverse proxy for Tailscale-only services.

```caddyfile
# =============================================================================
# Fixed Homelab Caddyfile - Internal Services
# Location: Docker VM /etc/caddy/Caddyfile
# Access: Tailscale network only (100.64.0.0/10)
# =============================================================================

{
    email augusto@cronova.dev

    # Use internal CA for Tailscale-only services
    # Or use tailscale cert integration
}

# Home Assistant
jara.cronova.dev {
    reverse_proxy localhost:8123

    # WebSocket support for HA
    @websockets {
        header Connection *Upgrade*
        header Upgrade websocket
    }
    reverse_proxy @websockets localhost:8123
}

# Jellyfin Media Server
yrasema.cronova.dev {
    reverse_proxy localhost:8096

    # Large file uploads for media
    request_body {
        max_size 100GB
    }
}

# Sonarr
japysaka.cronova.dev {
    reverse_proxy localhost:8989
}

# Radarr
taanga.cronova.dev {
    reverse_proxy localhost:7878
}

# Prowlarr
aoao.cronova.dev {
    reverse_proxy localhost:9696
}

# qBittorrent
qbit.cronova.dev {
    reverse_proxy localhost:8080
}

# Pi-hole Admin
dns.cronova.dev {
    reverse_proxy localhost:80
}
```

---

## NAS Caddyfile (Optional)

For NAS services if you want pretty URLs.

```caddyfile
# =============================================================================
# NAS Caddyfile - Storage Services
# Location: NAS /etc/caddy/Caddyfile
# Access: Tailscale network only
# =============================================================================

# Syncthing
sync.cronova.dev {
    reverse_proxy localhost:8384
}

# Frigate NVR
nvr.cronova.dev {
    reverse_proxy localhost:5000

    # WebSocket for live streams
    @websockets {
        header Connection *Upgrade*
        header Upgrade websocket
    }
    reverse_proxy @websockets localhost:5000
}
```

---

## Docker Compose (VPS)

```yaml
# docker/vps/networking/caddy/docker-compose.yml

services:
  caddy:
    image: caddy:latest
    container_name: caddy
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
      - "443:443/udp"  # HTTP/3
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile:ro
      - caddy-data:/data
      - caddy-config:/config
      - /var/www:/var/www:ro
    environment:
      - TZ=${TZ:-America/Asuncion}
    networks:
      - caddy-net
      - tailscale-net  # For proxying to homelab

volumes:
  caddy-data:
    name: caddy-data
  caddy-config:
    name: caddy-config

networks:
  caddy-net:
    name: caddy-net
  tailscale-net:
    external: true
```

---

## Cloudflare DNS Configuration

### cronova.dev

| Type | Name | Content | Proxy |
|------|------|---------|-------|

| A | @ | VPS_IP | Yes |
| CNAME | www | cronova.pages.dev | Yes |
| CNAME | docs | cronova-docs.pages.dev | Yes |
| A | vault | VPS_IP | Yes |
| A | status | VPS_IP | Yes |
| A | notify | VPS_IP | Yes |
| A | api | VPS_IP | Yes |
| A | saas | VPS_IP | Yes |
| A | hs | RPi5_PUBLIC_IP | No (DNS only) |
| A | home | 100.68.63.168 | No (internal) |
| A | media | 100.68.63.168 | No (internal) |
| A | btc | 100.64.0.11 | No (internal) |
| A | nas | 100.82.77.97 | No (internal) |
| A | git | 100.64.0.2 | No (internal) |

### verava.ai

| Type | Name | Content | Proxy |
|------|------|---------|-------|

| A | @ | VPS_IP | Yes |
| A | www | VPS_IP | Yes |
| A | app | VPS_IP | Yes |
| A | api | VPS_IP | Yes |
| A | docs | VPS_IP | Yes |

---

## SSL/TLS Strategy

### Public Services (VPS)

- **Method**: Let's Encrypt via Caddy ACME
- **Renewal**: Automatic (Caddy handles it)
- **Cloudflare**: Full (strict) SSL mode

### Internal Services (Tailscale)

#### Option A: Tailscale HTTPS (Recommended)

```bash
# Enable Tailscale HTTPS
tailscale cert jara.cronova.dev
```

Caddy config for Tailscale certs:

```caddyfile
jara.cronova.dev {
    tls /var/lib/tailscale/certs/jara.cronova.dev.crt /var/lib/tailscale/certs/jara.cronova.dev.key
    reverse_proxy localhost:8123
}
```

#### Option B: Internal CA

Use Caddy's internal CA for Tailscale-only services (simpler but requires trusting CA on devices).

---

## Security Hardening

### Cloudflare Settings

| Setting | Value |
|---------|-------|

| SSL/TLS | Full (strict) |
| Always Use HTTPS | On |
| Minimum TLS Version | TLS 1.2 |
| Opportunistic Encryption | On |
| TLS 1.3 | On |
| Automatic HTTPS Rewrites | On |

### Caddy Security Headers

All responses include:

- `Strict-Transport-Security` (HSTS)
- `X-Content-Type-Options: nosniff`
- `X-Frame-Options` (DENY or SAMEORIGIN)
- `Referrer-Policy`

### Rate Limiting (Optional)

```caddyfile
# Add to specific routes
api.cronova.dev {
    rate_limit {
        zone api {
            key {remote_host}
            events 100
            window 1m
        }
    }
    reverse_proxy localhost:8080
}
```

---

## Deployment Checklist

### VPS

- [ ] Install Caddy: `apt install caddy`
- [ ] Copy Caddyfile to `/etc/caddy/Caddyfile`
- [ ] Create web directories: `mkdir -p /var/www/verava /var/www/verava-docs`
- [ ] Validate config: `caddy validate --config /etc/caddy/Caddyfile`
- [ ] Reload Caddy: `systemctl reload caddy`
- [ ] Test SSL: `curl -I <https://status.cronova.dev`>

### Fixed Homelab

- [ ] Install Caddy in Docker VM
- [ ] Configure Tailscale certificates
- [ ] Copy Caddyfile
- [ ] Test internal access via Tailscale

### Cloudflare

- [ ] Add all DNS records
- [ ] Set SSL mode to Full (strict)
- [ ] Enable "Always Use HTTPS"
- [ ] Configure page rules if needed

---

## Troubleshooting

### Certificate Issues

```bash
# Check Caddy logs
journalctl -u caddy -f

# Force certificate renewal
caddy reload --config /etc/caddy/Caddyfile --force

# Test with curl
curl -vI https://status.cronova.dev
```

### 502 Bad Gateway

```bash
# Check if backend is running
curl localhost:3001  # For Uptime Kuma

# Check Caddy can reach backend
docker exec caddy curl localhost:3001
```

### Tailscale Proxy Issues

```bash
# Verify Tailscale connectivity
tailscale ping 100.68.63.168

# Check if service is reachable
curl http://100.68.63.168:8843
```

---

## Useful Commands

```bash
# Validate Caddyfile
caddy validate --config /etc/caddy/Caddyfile

# Reload without downtime
caddy reload --config /etc/caddy/Caddyfile

# Format Caddyfile
caddy fmt --overwrite /etc/caddy/Caddyfile

# View current config
caddy adapt --config /etc/caddy/Caddyfile

# Test certificate
openssl s_client -connect status.cronova.dev:443 -servername status.cronova.dev
```

---

## References

- [Caddy Documentation](https://caddyserver.com/docs/)
- [Caddy Reverse Proxy](https://caddyserver.com/docs/caddyfile/directives/reverse_proxy)
- [Caddy HTTPS](https://caddyserver.com/docs/automatic-https)
- [Cloudflare SSL](https://developers.cloudflare.com/ssl/)
- [Tailscale HTTPS](https://tailscale.com/kb/1153/enabling-https/)
