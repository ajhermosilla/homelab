# VPS - Helper Node

Docker services for the VPS helper node running on Vultr.

## Services

| Service | Port(s) | Purpose |
|---------|---------|---------|
| Caddy | 80, 443 | Reverse proxy, auto-SSL |
| Pi-hole | 53, 8053 | DNS (US fallback) |
| DERP | 3478, 8443 | Tailscale relay |
| Uptime Kuma | 3001 | Status monitoring |
| ntfy | 8080 | Push notifications |
| changedetection | 5000 | Website monitoring |
| Restic REST | 8000 | Backup target |

## Quick Start

```bash
# 1. Copy environment file
cp .env.example .env

# 2. Edit environment variables
nano .env

# 3. Start networking stack first
cd networking/caddy && docker compose up -d
cd ../pihole && docker compose up -d

# 4. Join Tailscale mesh
tailscale up --login-server=https://hs.cronova.dev --authkey=<key>

# 5. Start monitoring
cd ../../monitoring && docker compose up -d

# 6. Start remaining services
cd ../scraping && docker compose up -d
cd ../backup && docker compose up -d
```

## Deployment Order

1. **Caddy** - Reverse proxy (required for HTTPS)
2. **Pi-hole** - DNS
3. **Tailscale** - Join mesh (for homelab access)
4. **Monitoring** - Uptime Kuma + ntfy
5. **DERP** - Tailscale relay (optional)
6. **Scraping** - changedetection
7. **Backup** - Restic REST

## Directory Structure

```
vps/
├── .env.example          # Environment template
├── .env                  # Your environment (gitignored)
├── README.md
├── networking/
│   ├── caddy/
│   │   ├── docker-compose.yml
│   │   └── Caddyfile
│   ├── pihole/
│   │   └── docker-compose.yml
│   └── derp/
│       └── docker-compose.yml
├── monitoring/
│   └── docker-compose.yml  # Uptime Kuma + ntfy
├── scraping/
│   └── docker-compose.yml  # changedetection
└── backup/
    └── docker-compose.yml  # Restic REST
```

## Public Endpoints

| URL | Service |
|-----|---------|
| https://status.cronova.dev | Uptime Kuma |
| https://notify.cronova.dev | ntfy |
| https://vault.cronova.dev | Vaultwarden (proxied to homelab) |
| https://www.verava.ai | Business website |
| https://app.verava.ai | Customer app |

## Tailscale Integration

The VPS joins the Tailscale mesh to:
- Proxy requests to homelab services (vault.cronova.dev → 100.64.0.10)
- Monitor internal services via Uptime Kuma
- Receive backups from homelab via Restic

```bash
# Join mesh
tailscale up --login-server=https://hs.cronova.dev --authkey=<key>

# Verify connectivity
tailscale status
ping 100.64.0.10  # Should reach Docker VM
```

## Cloudflare DNS

Point these records to VPS IP:

| Type | Name | Proxy |
|------|------|-------|
| A | @ | Yes |
| A | status | Yes |
| A | notify | Yes |
| A | vault | Yes |
| A | www.verava.ai | Yes |
| A | app.verava.ai | Yes |

## Initial Server Setup

```bash
# Update system
apt update && apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com | sh
usermod -aG docker $USER

# Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# Create directories
mkdir -p /var/www/verava /var/www/verava-docs

# Clone homelab repo
git clone git@github.com:cronova/homelab.git /opt/homelab
cd /opt/homelab/docker/vps

# Continue with Quick Start above
```

## Firewall (UFW)

```bash
# Allow SSH
ufw allow 22/tcp

# Allow HTTP/HTTPS
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 443/udp  # HTTP/3

# Allow DNS
ufw allow 53/tcp
ufw allow 53/udp

# Allow STUN
ufw allow 3478/udp

# Allow Tailscale
ufw allow 41641/udp

# Enable
ufw enable
```

## Monitoring Checklist

After deployment, configure Uptime Kuma monitors:

- [ ] Headscale (https://hs.cronova.dev)
- [ ] Vaultwarden (https://vault.cronova.dev/alive)
- [ ] Home Assistant (100.64.0.10:8123)
- [ ] Pi-hole RPi 5 (100.64.0.1:53)
- [ ] Start9 (100.64.0.11)
- [ ] cronova.dev (https://cronova.dev)

## Useful Commands

```bash
# View all containers
docker ps -a

# Logs
docker logs -f caddy
docker logs -f uptime-kuma

# Restart stack
cd /opt/homelab/docker/vps/monitoring
docker compose restart

# Update images
docker compose pull
docker compose up -d
```

## References

- [Caddy](https://caddyserver.com/)
- [Pi-hole](https://pi-hole.net/)
- [DERP](https://tailscale.com/kb/1118/custom-derp-servers/)
- [Uptime Kuma](https://github.com/louislam/uptime-kuma)
- [ntfy](https://ntfy.sh/)
- [changedetection.io](https://changedetection.io/)
- [Restic](https://restic.net/)
