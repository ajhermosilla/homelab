# Networking Stack

Headscale + DERP + Caddy + Pi-hole for VPS networking.

## Services

| Service | Port | Purpose |
|---------|------|---------|
| Headscale | 8080 | Tailscale coordination server |
| DERP | 3478/udp, 8443 | NAT traversal relay |
| Caddy | 80, 443 | Reverse proxy + SSL |
| Pi-hole | 53, 8053 | DNS ad-blocking |

## Directory Structure

```
networking/
├── headscale/     # Tailscale coordination
├── derp/          # NAT traversal relay
├── caddy/         # Reverse proxy
└── pihole/        # DNS ad-blocking
```

## Headscale

```bash
cd headscale/
docker compose up -d

# Create user
docker exec headscale headscale users create augusto

# Generate auth key
docker exec headscale headscale preauthkeys create --user augusto
```

Connect devices:
```bash
tailscale up --login-server=https://hs.cronova.dev --authkey=<key>
```

## DERP Relay

Custom DERP server reduces latency for relay connections.

```bash
cd derp/
docker compose up -d

# Verify
tailscale netcheck
```

## Caddy

```bash
cd caddy/
# Edit Caddyfile with your domains
docker compose up -d
```

## Pi-hole

US-based fallback DNS for when traveling.

```bash
cd pihole/
docker compose up -d
```

Web UI: http://vps-ip:8053/admin

## Startup Order

1. **Pi-hole** - DNS (no dependencies)
2. **Caddy** - Reverse proxy (no dependencies)
3. **Headscale** - Needs Caddy for HTTPS
4. **DERP** - Needs Caddy for TLS termination

## DNS Flow

```
Device → Tailscale DNS → Pi-hole (VPS) → Upstream (Cloudflare/Quad9)
```
