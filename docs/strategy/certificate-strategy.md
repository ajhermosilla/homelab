# Certificate Strategy

SSL/TLS certificate management for homelab services.

## Decision Summary

| Service Type | Method | Provider |
|--------------|--------|----------|

| Public (VPS) | Let's Encrypt (HTTP-01) | Caddy ACME |
| Public (Static) | Cloudflare | Edge certificates |
| Internal (Docker VM) | Let's Encrypt (DNS-01) | Caddy + Cloudflare DNS |

**Decision:**Use**Let's Encrypt via Cloudflare DNS-01** for internal services. No ports open to internet required.

---

## Current Status (as of 2026-02-22)

| Component | Status | Notes |
|-----------|--------|-------|

| VPS Caddy + Let's Encrypt (HTTP-01) | Deployed | cronova.dev, hs, status, notify |
| Cloudflare Edge | Deployed | DNS proxied |
| Docker VM Caddy + Let's Encrypt (DNS-01) | Deployed | home, media, frigate, sonarr, radarr, prowlarr |
| NAS Traefik + Let's Encrypt (DNS-01) | Planned | tajy (Coolify) |

**Previous limitation:** `tailscale cert` doesn't work with self-hosted Headscale.

**Solution:** Custom Caddy build with `caddy-dns/cloudflare` plugin. Certificates obtained via DNS-01 challenge through Cloudflare API — no public ports needed.

---

## Why DNS-01 via Cloudflare?

| Factor | DNS-01 (Cloudflare) | Internal CA | Tailscale HTTPS |
|--------|---------------------|-------------|-----------------|

| Headscale compatible | Yes | Yes | No |
| Setup complexity | Low | Medium | N/A |
| Device trust setup | None | Install CA on each device | None |
| Auto-renewal | Yes (Caddy) | Manual/scripted | Yes |
| Browser warnings | None | None (after CA trust) | None |
| Public ports required | No | No | No |
| Guest device access | Works | Requires CA install | Works |

**Winner:** DNS-01 via Cloudflare — browser-trusted certs, no open ports, works with Headscale.

---

## Architecture

```text
┌─────────────────────────────────────────────────────────────────────┐
│                           INTERNET                                   │
└────────────────────────────────┬────────────────────────────────────┘
                                 │
              ┌──────────────────┼──────────────────┬──────────────────┐
              │                  │                  │                  │
       [Cloudflare]        [VPS Caddy]       [Docker VM Caddy]  [NAS Traefik]
       Edge Certs          LE (HTTP-01)       LE (DNS-01 via CF) LE (DNS-01 via CF)
              │                  │                  │                  │
    ┌─────────┴─────────┐       │           ┌──────┴──────┐          │
    │                   │       │           │             │          │
www.cronova.dev    docs.cronova.dev    jara.cronova.dev  yrasema  tajy.cronova.dev
(Cloudflare Pages)                     taguato.cronova.dev        (Coolify apps)
                                       sonarr/radarr/aoao
```

---

## Public Services (Let's Encrypt)

### VPS Caddy Configuration

Caddy automatically obtains Let's Encrypt certificates.

```caddyfile
# Automatic HTTPS - Caddy handles everything
status.cronova.dev {
    reverse_proxy localhost:3001
}

notify.cronova.dev {
    reverse_proxy localhost:80
}

vault.cronova.dev {
    reverse_proxy 100.68.63.168:8843
}
```

#### How it works

1. Caddy detects HTTPS is needed
2. Requests certificate from Let's Encrypt
3. Completes HTTP-01 challenge automatically
4. Renews 30 days before expiry

#### Requirements

- Port 80/443 open to internet
- DNS A record pointing to VPS IP
- Valid email in Caddy global config

---

## Internal Services (DNS-01 via Cloudflare)

### How It Works

Docker VM runs a custom Caddy build with the `caddy-dns/cloudflare` plugin. Caddy proves domain ownership by creating a DNS TXT record via the Cloudflare API, then Let's Encrypt issues the certificate. No public ports required.

```text
Caddy → Cloudflare API → _acme-challenge TXT record → Let's Encrypt validates → cert issued
```

### Requirements

- Cloudflare API Token with Zone/DNS/Edit + Zone/Zone/Read for cronova.dev
- Pi-hole local DNS: `*.cronova.dev → 192.168.0.10` (Docker VM LAN IP)
- Custom Caddy image built from `docker/fixed/docker-vm/networking/caddy/Dockerfile`

### Docker VM Caddy Configuration

```caddyfile
{
    email augusto@cronova.dev
}

(internal_tls) {
    tls {
        dns cloudflare {env.CLOUDFLARE_API_TOKEN}
    }
}

jara.cronova.dev {
    import internal_tls
    reverse_proxy host.docker.internal:8123
}

yrasema.cronova.dev {
    import internal_tls
    reverse_proxy host.docker.internal:8096
}

taguato.cronova.dev {
    import internal_tls
    reverse_proxy host.docker.internal:5000
}
```

### Certificate Renewal

Caddy handles renewal automatically — no cron jobs needed. Certificates renew 30 days before expiry.

### Headscale Note

`tailscale cert` is NOT available with self-hosted Headscale. DNS-01 via Cloudflare is the chosen alternative.

---

## Cloudflare (Static Sites)

### Edge Certificates

Cloudflare provides free edge certificates for:

- `<www.cronova.dev>` (Cloudflare Pages)
- `docs.cronova.dev` (Cloudflare Pages)

#### Settings

| Option | Value |
|--------|-------|

| SSL/TLS Mode | Full (strict) |
| Always Use HTTPS | On |
| Minimum TLS | 1.2 |
| TLS 1.3 | On |

### Origin Certificates (VPS)

For VPS behind Cloudflare proxy:

1. Cloudflare Dashboard → SSL/TLS → Origin Server
2. Create Certificate (15 years validity)
3. Install on VPS
4. Configure Caddy to use origin cert

```caddyfile
# If using Cloudflare origin cert
www.verava.ai {
    tls /etc/ssl/cloudflare/verava.ai.pem /etc/ssl/cloudflare/verava.ai.key
    root * /var/www/verava
    file_server
}
```

---

## Certificate Inventory

| Domain | Type | Provider | Challenge | Auto-Renew |
|--------|------|----------|-----------|------------|

| status.cronova.dev | Let's Encrypt | VPS Caddy | HTTP-01 | Yes |
| notify.cronova.dev | Let's Encrypt | VPS Caddy | HTTP-01 | Yes |
| vault.cronova.dev | Let's Encrypt | VPS Caddy | HTTP-01 | Yes |
| <www.cronova.dev> | Edge | Cloudflare | N/A | Yes |
| docs.cronova.dev | Edge | Cloudflare | N/A | Yes |
| jara.cronova.dev | Let's Encrypt | Docker VM Caddy | DNS-01 (CF) | Yes |
| yrasema.cronova.dev | Let's Encrypt | Docker VM Caddy | DNS-01 (CF) | Yes |
| taguato.cronova.dev | Let's Encrypt | Docker VM Caddy | DNS-01 (CF) | Yes |
| japysaka.cronova.dev | Let's Encrypt | Docker VM Caddy | DNS-01 (CF) | Yes |
| taanga.cronova.dev | Let's Encrypt | Docker VM Caddy | DNS-01 (CF) | Yes |
| aoao.cronova.dev | Let's Encrypt | Docker VM Caddy | DNS-01 (CF) | Yes |
| tajy.cronova.dev | Let's Encrypt | NAS Traefik (Coolify) | DNS-01 (CF) | Yes |

---

## Monitoring

### Uptime Kuma SSL Checks

Add certificate expiry monitoring:

| Monitor | Type | Alert Threshold |
|---------|------|-----------------|

| status.cronova.dev | HTTPS | 14 days |
| vault.cronova.dev | HTTPS | 14 days |
| jara.cronova.dev | HTTPS | 14 days |
| yrasema.cronova.dev | HTTPS | 14 days |
| taguato.cronova.dev | HTTPS | 14 days |

### Manual Check

```bash
# Check certificate expiry for any domain
echo | openssl s_client -connect jara.cronova.dev:443 -servername jara.cronova.dev 2>/dev/null | openssl x509 -noout -dates
```

---

## Troubleshooting

### Let's Encrypt Issues

```bash
# Check Caddy logs
journalctl -u caddy -f | grep -i acme

# Force renewal
caddy reload --config /etc/caddy/Caddyfile --force

# Test HTTP challenge
curl http://status.cronova.dev/.well-known/acme-challenge/test
```

### DNS-01 Challenge Issues

```bash
# Check Caddy logs for certificate errors
docker logs caddy 2>&1 | grep -i "tls\|cert\|acme\|dns"

# Verify Cloudflare token works
curl -X GET "https://api.cloudflare.com/client/v4/zones" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  -H "Content-Type: application/json"

# Force certificate renewal
docker exec caddy caddy reload --config /etc/caddy/Caddyfile

# Check certificate details
echo | openssl s_client -connect jara.cronova.dev:443 -servername jara.cronova.dev 2>/dev/null | openssl x509 -noout -dates -issuer
```

### Cloudflare Issues

```bash
# Verify SSL mode
# Dashboard → SSL/TLS → Overview → Should show "Full (strict)"

# Check origin cert validity
openssl x509 -in /etc/ssl/cloudflare/verava.ai.pem -noout -dates
```

---

## Implementation Checklist

### VPS (Let's Encrypt)

- [x] Verify ports 80/443 open
- [x] Configure Caddy with email
- [x] Deploy Caddyfile
- [x] Verify auto-cert: `curl -I <https://status.cronova.dev`>

### Fixed Homelab (DNS-01 via Cloudflare)

- [x] Custom Caddy build with caddy-dns/cloudflare plugin
- [x] Cloudflare API Token (Zone/DNS/Edit + Zone/Zone/Read)
- [x] Pi-hole local DNS entries for *.cronova.dev → 192.168.0.10
- [x] Caddy Caddyfile with DNS-01 TLS snippets
- [x] HTTPS working for home, media, frigate, sonarr, radarr, prowlarr

### Cloudflare

- [x] Set SSL mode to Full (strict)
- [x] Enable Always Use HTTPS
- [ ] (Optional) Create origin certificate for VPS

---

## Reference

- [Tailscale HTTPS](https://tailscale.com/kb/1153/enabling-https/)
- [Caddy Automatic HTTPS](https://caddyserver.com/docs/automatic-https)
- [Let's Encrypt](https://letsencrypt.org/docs/)
- [Cloudflare SSL](https://developers.cloudflare.com/ssl/)
