# Security Hardening Guide

Security configuration to protect against script kiddies, malware, and DoS attacks.

## Threat Model

| Threat | Likelihood | Mitigation |
|--------|------------|------------|
| Script kiddies | High | Fail2ban, rate limiting, no exposed ports |
| Malware/botnets | Medium | 2FA, updates, network segmentation |
| DoS attacks | Medium | Cloudflare, rate limiting, geo-blocking |
| Credential stuffing | Medium | 2FA, strong passwords, Vaultwarden |
| Doxxing | Low | WHOIS privacy, Cloudflare proxy |

---

## Attack Surface Minimization

### Public Exposure

Multiple services on the VPS are exposed to the internet via Caddy reverse proxy. All fixed homelab services are behind Tailscale (no public ports).

```text
Internet Access (VPS — Caddy reverse proxy):
├── hs.cronova.dev (Headscale) ← Tailscale coordination
│   └── Port 443 (HTTPS)
│   └── Port 3478 (STUN/DERP)
├── status.cronova.dev (Uptime Kuma) ← Public status page
├── notify.cronova.dev (ntfy) ← Push notifications
├── cronova.dev (Landing page) ← Static HTML
│
└── Everything else via Tailscale mesh (no public ports)
    ├── Home Assistant
    ├── Jellyfin
    ├── Vaultwarden
    ├── Frigate
    └── All internal services
```

### VPS Firewall (UFW)

```bash
# Reset and configure UFW
sudo ufw reset
sudo ufw default deny incoming
sudo ufw default allow outgoing

# SSH (consider changing port)
sudo ufw allow 22/tcp

# Headscale only
sudo ufw allow 443/tcp
sudo ufw allow 3478/udp

# Tailscale (auto-managed, but explicit)
sudo ufw allow in on tailscale0

# Enable
sudo ufw enable
sudo ufw status verbose
```

### Fixed Homelab Firewall (OPNsense)

All traffic filtered through OPNsense VM (gateway since 2026-02-21):

- WAN: Block all inbound (no port forwards)
- LAN: Allow outbound, block inter-VLAN
- IoT VLAN (10): Configured, rules pending
- Guest VLAN (20): Configured, rules pending
- Access via Tailscale only

### Authelia Forward Auth — Deployed

Authelia (Okẽ) provides SSO + TOTP 2FA for services behind Caddy on Docker VM:

- **Protected:** Ysyry (Dozzle), Kuatia (BentoPDF), Mbyja (Homepage), Papa (Grafana), Aranduka (Paperless-ngx)
- **Own auth (not protected):** Jara (HA), Taguato (Frigate), Vaultwarden, Vera (Immich), Forgejo, Yrasema (Jellyfin — mobile/TV clients can't handle redirects)
- **Notifier:** Filesystem (writes codes to `/data/notification.txt`), not SMTP
- **2FA:** TOTP via Authy app

---

## Two-Factor Authentication (2FA)

### Hardware Key

**YubiKey 5C NFC** available for hardware-based 2FA:

- USB-C + NFC for phone/laptop
- Supports FIDO2, WebAuthn, TOTP
- Use for most critical accounts (Vaultwarden master, Cloudflare, GitHub)

### Service 2FA Matrix

| Service | 2FA Method | Priority | Status |
|---------|------------|----------|--------|
| Vaultwarden | TOTP or YubiKey | Critical | Available |
| Authelia (Okẽ) | TOTP via Authy | Critical | Active (protects 6 services) |
| Headscale | OIDC + 2FA | Critical | Pending (CLI-only for now) |
| Proxmox | TOTP or YubiKey | Critical | Available |
| Home Assistant | TOTP | High | Available |
| OPNsense | TOTP | High | Pending |
| Start9 | TOTP | High | Pending |
| Jellyfin | None (behind Authelia) | Low | Protected via forward auth |
| *arr stack | None (internal only) | Low | — |

### Vaultwarden 2FA Setup

```bash
# Already enabled by default
# Users enable in: Settings → Two-step Login → Authenticator App
```

#### Enforce 2FA for all users

Add to `docker-compose.yml` environment:

```yaml
environment:
  - SIGNUPS_ALLOWED=false
  - REQUIRE_DEVICE_EMAIL=true
```

### Headscale OIDC Integration

For web-based admin with 2FA, integrate with an OIDC provider.

#### Option 1: Authelia (self-hosted)

```yaml
# docker-compose.yml addition
authelia:
  image: authelia/authelia:latest
  volumes:
    - ./authelia:/config
  environment:
    - TZ=America/Asuncion
```

#### Option 2: Use pre-auth keys only (simpler)

No web admin exposed. Manage via CLI:

```bash
# All admin via SSH + CLI
docker exec headscale headscale users list
docker exec headscale headscale nodes list
```

### Proxmox 2FA Setup

1. **Datacenter → Permissions → Two Factor**
2. Add TOTP for root user
3. Require 2FA for all admin users

```bash
# Or via CLI
pveum user modify root@pam -totp "otpauth://totp/Proxmox:root?secret=XXXX"
```

### Home Assistant 2FA

1. **Profile → Multi-factor Authentication**
2. Enable "Authenticator app"
3. Scan QR code with authenticator

### OPNsense 2FA

1. **System → Access → Servers → Add**
   - Type: Local + Timebased One-time Password
1. **System → Access → Users → Edit**
   - OTP seed: Generate new

---

## Fail2ban Configuration

### VPS Installation

```bash
sudo apt install fail2ban
sudo systemctl enable fail2ban
```

### SSH Protection

```ini
# /etc/fail2ban/jail.local

[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 3
banaction = ufw

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 24h
```

### Headscale Protection

```ini
# /etc/fail2ban/jail.local

[headscale]
enabled = true
port = 443
filter = headscale
logpath = /var/log/headscale/headscale.log
maxretry = 5
bantime = 1h
```

```ini
# /etc/fail2ban/filter.d/headscale.conf

[Definition]
failregex = ^.*Failed authentication.*from <HOST>.*$
            ^.*Invalid token.*from <HOST>.*$
ignoreregex =
```

### Docker Container Protection

For services in Docker, use fail2ban with Docker logs:

```ini
# /etc/fail2ban/jail.local

[vaultwarden]
enabled = true
port = 443
filter = vaultwarden
logpath = /var/lib/docker/containers/*vaultwarden*/*-json.log
maxretry = 3
bantime = 24h
```

```ini
# /etc/fail2ban/filter.d/vaultwarden.conf

[Definition]
failregex = ^.*"Username or password is incorrect".*"Client":\s*"<HOST>".*$
ignoreregex =
```

### Fail2ban Commands

```bash
# Check status
sudo fail2ban-client status

# Check specific jail
sudo fail2ban-client status sshd

# Unban IP
sudo fail2ban-client set sshd unbanip 1.2.3.4

# View banned IPs
sudo fail2ban-client get sshd banned
```

---

## Rate Limiting

### Caddy Rate Limiting

```caddyfile
# VPS Caddyfile - rate limit Headscale
hs.cronova.dev {
    rate_limit {
        zone headscale {
            key {remote_host}
            events 100
            window 1m
        }
    }
    reverse_proxy localhost:8080
}
```

### OPNsense Rate Limiting

1. **Firewall → Settings → Advanced**
2. Enable "Firewall Adaptive Timeouts"
3. **Firewall → Aliases → Add**
   - Name: rate_limit_block
   - Type: URL Table (IPs)

---

## DNS Privacy

### Pi-hole Upstream (DNS-over-HTTPS)

Use Cloudflared for encrypted DNS:

```yaml
# Add to Pi-hole docker-compose.yml
cloudflared:
  image: cloudflare/cloudflared:latest
  container_name: cloudflared
  restart: unless-stopped
  command: proxy-dns
  environment:
    - TUNNEL_DNS_UPSTREAM=https://1.1.1.1/dns-query,https://1.0.0.1/dns-query
    - TUNNEL_DNS_PORT=5053
    - TUNNEL_DNS_ADDRESS=0.0.0.0
  networks:
    - pihole-net
```

Pi-hole configuration:

- Custom upstream DNS: `cloudflared#5053`

### Alternative: Unbound with DoT

```bash
# /etc/unbound/unbound.conf.d/dns-over-tls.conf
forward-zone:
    name: "."
    forward-tls-upstream: yes
    forward-addr: 1.1.1.1@853#cloudflare-dns.com
    forward-addr: 1.0.0.1@853#cloudflare-dns.com
```

---

## IP Privacy & Anti-Doxxing

### Cloudflare Proxy

All public domains use Cloudflare proxy (orange cloud):

| Domain | Proxy | Notes |
|--------|-------|-------|
| cronova.dev | Yes | Static site |
| hs.cronova.dev | **No** | Headscale needs direct IP |
| verava.ai | Yes | When purchased |

**For Headscale:** IP is exposed, but:

- Only serves Tailscale clients
- Fail2ban protects against abuse
- Can geo-block if needed

### WHOIS Privacy

Ensure WHOIS privacy is enabled:

1. **Cloudflare Registrar** - Privacy included free
2. **Other registrars** - Enable WHOIS privacy/redaction

Verify:

```bash
whois cronova.dev | grep -i registrant
# Should show privacy service, not personal info
```

### Email Privacy

- Don't use personal email in public configs
- Use domain email: `<admin@cronova.dev>`
- Forward to personal email privately

### Git Privacy

Check for exposed info:

```bash
# Search for emails in repo
git log --all --format='%ae' | sort -u

# Search for potential secrets
grep -r "password\|secret\|key\|token" --include="*.yml" --include="*.md"
```

---

## Container Security

### Docker Hardening

```yaml
# docker-compose.yml security options
services:
  app:
    security_opt:
      - no-new-privileges:true
    read_only: true  # Where possible
    user: "1000:1000"  # Non-root
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE  # Only if needed
```

### Image Security

```bash
# Use specific tags, not :latest in production
image: vaultwarden/server:1.30.1

# Scan images for vulnerabilities
docker scout cves vaultwarden/server:latest
```

### Network Isolation

```yaml
# Separate networks per service group
networks:
  frontend:
    internal: false
  backend:
    internal: true  # No internet access
```

---

## Update Strategy

### Automatic Security Updates

```bash
# Install unattended-upgrades
sudo apt install unattended-upgrades

# Configure
sudo dpkg-reconfigure unattended-upgrades

# /etc/apt/apt.conf.d/50unattended-upgrades
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
};
Unattended-Upgrade::Automatic-Reboot "false";
```

### Container Updates

```bash
# Weekly container update script
#!/bin/bash
cd /opt/homelab/docker/vps
docker compose pull
docker compose up -d

# Notify
curl -d "VPS containers updated" https://notify.cronova.dev/cronova-info
```

### Watchtower (Automated) — Deployed

```yaml
# Deployed on Docker VM (maintenance stack)
watchtower:
  image: nicholas-fedor/watchtower:1.14.2  # Maintained fork (containrrr abandoned/Docker 29+ incompatible)
  volumes:
    - /var/run/docker.sock:/var/run/docker.sock
  environment:
    - WATCHTOWER_CLEANUP=true
    - WATCHTOWER_SCHEDULE=0 0 4 * * 0  # Sundays 4 AM
    - WATCHTOWER_LABEL_ENABLE=true       # Opt-in via container labels
```

**Update strategy** (opt-in via `com.centurylinklabs.watchtower.enable=true` label):

| Category | Services | Strategy |
|----------|----------|----------|
| **Pinned (manual bump)** | victoriametrics, vmagent, vmalert, alertmanager, grafana, authelia, paperless-ngx | Version pinned in compose — Watchtower label present but no-op |
| **Excluded (no label)** | vaultwarden, frigate, homeassistant, immich-db, immich-valkey, paperless-db, paperless-redis | No Watchtower label — manual only |
| **Excluded (label=false)** | caddy (Docker VM) | Explicitly disabled — custom build with Cloudflare plugin |
| **Auto-updated** | dozzle, bentopdf, homepage, cadvisor, glances, sonarr, radarr, prowlarr, qbittorrent, jellyfin, mosquitto, pihole, immich-server, immich-ml + backup sidecars | Low-risk or stateless — Watchtower updates on schedule |

---

## Monitoring & Alerts

### Security Alerts in Uptime Kuma

Add monitors for security events:

| Monitor | Type | Alert |
|---------|------|-------|
| VPS SSH | TCP 22 | If down, possible attack |
| Fail2ban status | Push | On ban events |
| UFW logs | Push | On blocked connections |

### Log Monitoring

```bash
# Watch auth failures
sudo tail -f /var/log/auth.log | grep -i "failed\|invalid"

# Watch UFW blocks
sudo tail -f /var/log/ufw.log
```

### Fail2ban Notifications

```bash
# /etc/fail2ban/action.d/ntfy.conf
[Definition]
actionban = curl -d "Banned <ip> from <name> jail" https://notify.cronova.dev/cronova-warning
actionunban = curl -d "Unbanned <ip> from <name> jail" https://notify.cronova.dev/cronova-info
```

```ini
# /etc/fail2ban/jail.local
[DEFAULT]
action = %(action_)s
         ntfy
```

---

## Backup Security

### Encrypted Backups

Restic encrypts by default:

```bash
# Repository is AES-256 encrypted
restic init  # Prompts for password
```

### Backup Key Storage

1. Store restic password in Vaultwarden
2. Paper backup in secure location
3. Never commit password to git

### Offsite Encryption

rclone crypt adds additional layer:

```bash
# Google Drive data is encrypted client-side
rclone config
# Type: crypt
# Remote: gdrive:homelab-backup
# Password: (different from restic password)
```

---

## Incident Response

### If VPS Compromised

1. **Isolate**: Remove from Tailscale

   ```bash
   tailscale down
   ```

2. **Revoke**: Invalidate all Headscale auth keys
3. **Rotate**: Change all passwords/keys
4. **Rebuild**: Fresh VPS from backup
5. **Audit**: Check access logs

### If Credentials Leaked

1. **Change** Vaultwarden master password
2. **Rotate** all stored passwords
3. **Revoke** all Tailscale pre-auth keys
4. **Check** for unauthorized devices in mesh

### If DoS Attack

1. **Cloudflare**: Enable "Under Attack" mode
2. **Geo-block**: Block attacking countries
3. **Rate limit**: Increase restrictions
4. **Report**: To VPS provider

---

## Security Checklist

### Initial Setup

- [ ] UFW configured and enabled
- [ ] SSH key-only authentication
- [ ] SSH root login disabled
- [ ] Fail2ban installed and configured
- [ ] 2FA enabled on Vaultwarden
- [ ] 2FA enabled on Proxmox
- [ ] WHOIS privacy verified
- [ ] Cloudflare proxy enabled (where applicable)

### Monthly Review

- [ ] Check fail2ban ban logs
- [ ] Review Uptime Kuma alerts
- [ ] Verify backups are encrypted
- [ ] Check for system updates
- [ ] Review Tailscale device list
- [ ] Rotate any compromised credentials

### After Incident

- [ ] Document what happened
- [ ] Identify root cause
- [ ] Implement fixes
- [ ] Update this document

---

## Quick Reference

### Emergency Commands

```bash
# Block IP immediately
sudo ufw deny from 1.2.3.4

# Check active connections
sudo netstat -tulpn

# Kill suspicious process
sudo kill -9 <pid>

# Check for rootkits
sudo rkhunter --check

# View recent logins
last -n 20

# Check for unauthorized SSH keys
cat ~/.ssh/authorized_keys
```

### Security Tools

| Tool | Purpose | Install |
|------|---------|---------|
| fail2ban | Ban brute forcers | `apt install fail2ban` |
| ufw | Firewall | `apt install ufw` |
| rkhunter | Rootkit detection | `apt install rkhunter` |
| lynis | Security audit | `apt install lynis` |
| clamav | Antivirus | `apt install clamav` |

---

## References

- [Fail2ban Documentation](https://www.fail2ban.org/)
- [UFW Guide](https://help.ubuntu.com/community/UFW)
- [Docker Security](https://docs.docker.com/engine/security/)
- [Cloudflare DDoS Protection](https://www.cloudflare.com/ddos/)
- [Vaultwarden Security](https://github.com/dani-garcia/vaultwarden/wiki)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
