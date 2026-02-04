# Certificate Strategy

SSL/TLS certificate management for homelab services.

## Decision Summary

| Service Type | Method | Provider |
|--------------|--------|----------|
| Public (VPS) | Let's Encrypt | Caddy ACME |
| Public (Static) | Cloudflare | Edge certificates |
| Internal (Tailscale) | Tailscale HTTPS | MagicDNS certs |

**Decision:** Use **Tailscale HTTPS** for internal services (not Internal CA).

---

## Current Status (as of 2026-02-04)

| Component | Status | Notes |
|-----------|--------|-------|
| VPS Caddy + Let's Encrypt | Deployed | cronova.dev, hs, status, notify |
| Cloudflare Edge | Deployed | DNS proxied |
| Docker VM Tailscale certs | Not available | Headscale doesn't support this feature |
| Headscale MagicDNS | Partial | Enabled but name resolution unreliable |

**Headscale limitation:** `tailscale cert` returns "your Tailscale account does not support getting TLS certs" - this feature requires Tailscale's commercial infrastructure and is not available with self-hosted Headscale.

**Revised approach:** Use HTTP for internal services accessed via Tailscale. The WireGuard tunnel provides encryption, making HTTPS redundant for internal access.

---

## Why Tailscale HTTPS?

| Factor | Tailscale HTTPS | Internal CA |
|--------|-----------------|-------------|
| Setup complexity | Low | Medium |
| Device trust setup | None | Install CA on each device |
| Auto-renewal | Yes | Manual/scripted |
| Browser warnings | None | None (after CA trust) |
| Mobile support | Automatic | Manual CA install |
| Guest device access | Works | Requires CA install |

**Winner:** Tailscale HTTPS - zero config on clients, automatic renewal.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                           INTERNET                                   │
└────────────────────────────────┬────────────────────────────────────┘
                                 │
              ┌──────────────────┼──────────────────┐
              │                  │                  │
       [Cloudflare]        [VPS Caddy]       [Tailscale]
       Edge Certs          Let's Encrypt      MagicDNS Certs
              │                  │                  │
    ┌─────────┴─────────┐       │           ┌──────┴──────┐
    │                   │       │           │             │
www.cronova.dev    docs.cronova.dev    home.cronova.dev  media.cronova.dev
(Cloudflare Pages)                     vault.cronova.dev btc.cronova.dev
                                       (internal)        nas.cronova.dev
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

**How it works:**
1. Caddy detects HTTPS is needed
2. Requests certificate from Let's Encrypt
3. Completes HTTP-01 challenge automatically
4. Renews 30 days before expiry

**Requirements:**
- Port 80/443 open to internet
- DNS A record pointing to VPS IP
- Valid email in Caddy global config

---

## Internal Services (Tailscale Access)

### Headscale Limitation

**Important:** Tailscale HTTPS (`tailscale cert`) is NOT available with self-hosted Headscale. This feature requires Tailscale's commercial backend infrastructure.

```bash
# This does NOT work with Headscale:
tailscale cert docker.hs.net
# Error: 500 Internal Server Error: your Tailscale account does not support getting TLS certs
```

### Recommended Approach: HTTP via Tailscale

For internal services accessed only via Tailscale, use HTTP:
- WireGuard tunnel provides end-to-end encryption
- No certificate management overhead
- Works with any Tailscale/Headscale setup

Access internal services via Tailscale IPs:
```
http://100.68.63.168:8123  # Home Assistant
http://100.68.63.168:8096  # Jellyfin
http://100.68.63.168:5000  # Frigate
```

### Headscale Configuration

Enable MagicDNS in Headscale config:

```yaml
# /etc/headscale/config.yaml
dns_config:
  magic_dns: true
  base_domain: hs.net
  nameservers:
    - 100.68.63.168   # Pi-hole (Docker VM)
```

**Note:** MagicDNS with Headscale has known limitations - name resolution may not work reliably. Use Tailscale IPs directly as fallback.

### Caddy with Tailscale Certs

```caddyfile
# Fixed Homelab Caddyfile
{
    email augusto@cronova.dev
}

home.cronova.dev {
    tls /var/lib/tailscale/certs/home.cronova.dev.crt /var/lib/tailscale/certs/home.cronova.dev.key
    reverse_proxy localhost:8123
}

media.cronova.dev {
    tls /var/lib/tailscale/certs/media.cronova.dev.crt /var/lib/tailscale/certs/media.cronova.dev.key
    reverse_proxy localhost:8096
}

frigate.cronova.dev {
    tls /var/lib/tailscale/certs/frigate.cronova.dev.crt /var/lib/tailscale/certs/frigate.cronova.dev.key
    reverse_proxy localhost:5000
}
```

### Certificate Renewal Script

Tailscale certs expire after 90 days. Auto-renew with cron:

```bash
#!/bin/bash
# /usr/local/bin/renew-tailscale-certs.sh

DOMAINS="home.cronova.dev media.cronova.dev frigate.cronova.dev"

for domain in $DOMAINS; do
    tailscale cert $domain
done

# Reload Caddy to pick up new certs
systemctl reload caddy

# Notify
curl -d "Tailscale certs renewed" https://notify.cronova.dev/cronova-info
```

Cron entry:
```bash
# Renew monthly (certs valid 90 days)
0 3 1 * * /usr/local/bin/renew-tailscale-certs.sh
```

---

## Cloudflare (Static Sites)

### Edge Certificates

Cloudflare provides free edge certificates for:
- `www.cronova.dev` (Cloudflare Pages)
- `docs.cronova.dev` (Cloudflare Pages)

**Settings:**
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

| Domain | Type | Provider | Expiry | Auto-Renew |
|--------|------|----------|--------|------------|
| status.cronova.dev | Let's Encrypt | Caddy | 90 days | Yes |
| notify.cronova.dev | Let's Encrypt | Caddy | 90 days | Yes |
| vault.cronova.dev | Let's Encrypt | Caddy | 90 days | Yes |
| www.cronova.dev | Edge | Cloudflare | N/A | Yes |
| docs.cronova.dev | Edge | Cloudflare | N/A | Yes |
| home (100.68.63.168:8123) | HTTP | Tailscale tunnel | N/A | N/A |
| media (100.68.63.168:8096) | HTTP | Tailscale tunnel | N/A | N/A |
| frigate (100.68.63.168:5000) | HTTP | Tailscale tunnel | N/A | N/A |
| nas (100.64.0.12) | HTTP | Tailscale tunnel | N/A | N/A |
| btc (100.64.0.11) | HTTP | Tailscale tunnel | N/A | N/A |

---

## Monitoring

### Uptime Kuma SSL Checks

Add certificate expiry monitoring:

| Monitor | Type | Alert Threshold |
|---------|------|-----------------|
| status.cronova.dev | HTTPS | 14 days |
| vault.cronova.dev | HTTPS | 14 days |
| home.cronova.dev | HTTPS (Tailscale) | 14 days |

### Manual Check

```bash
# Check certificate expiry
echo | openssl s_client -connect status.cronova.dev:443 -servername status.cronova.dev 2>/dev/null | openssl x509 -noout -dates

# Check Tailscale cert
openssl x509 -in /var/lib/tailscale/certs/home.cronova.dev.crt -noout -dates
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

### Tailscale Cert Issues

```bash
# Check Tailscale status
tailscale status

# Verify MagicDNS is working
tailscale dns status

# Re-generate cert
tailscale cert --force home.cronova.dev

# Check cert file permissions
ls -la /var/lib/tailscale/certs/
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
- [x] Verify auto-cert: `curl -I https://status.cronova.dev`

### Fixed Homelab (Internal Access)
- [x] Enable MagicDNS in Headscale (partial - has limitations)
- [x] Tailscale HTTPS: Not available with Headscale (use HTTP instead)
- [x] Internal services accessible via HTTP over Tailscale tunnel (encrypted by WireGuard)

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
