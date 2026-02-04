# Uptime Kuma Monitors

Monitor configuration for the homelab. Create these after deploying Uptime Kuma.

## Monitor Groups

### Critical (60s interval)

Services that must be available 24/7. Alert immediately on failure.

| Monitor | Type | Target | Notes |
|---------|------|--------|-------|
| Headscale | HTTP | `https://hs.cronova.dev/health` | Mesh coordination |
| VPS Pi-hole | TCP | `100.64.0.100:53` | DNS fallback |
| Vaultwarden | HTTP | `https://vault.cronova.dev/alive` | Password manager |

### High Priority (5m interval)

Core homelab services. Alert after 2 failures.

| Monitor | Type | Target | Notes |
|---------|------|--------|-------|
| Docker VM | Ping | `100.68.63.168` | Tailscale IP |
| Pi-hole (Fixed) | TCP | `100.68.63.168:53` | Local DNS |
| Home Assistant | HTTP | `http://100.68.63.168:8123` | Automation |
| Jellyfin | HTTP | `http://100.68.63.168:8096` | Media |
| Frigate | HTTP | `http://100.68.63.168:5000` | NVR |
| NAS | TCP | `100.64.0.12:445` | Samba |
| NAS Syncthing | HTTP | `http://100.64.0.12:8384` | File sync |
| Start9 (RPi 4) | HTTP | `http://100.64.0.11` | Bitcoin node |
| OPNsense | HTTPS | `https://100.64.0.14` | Router |

### Mobile Kit (5m interval, info-level alerts)

On-demand services. Not critical if offline during sleep hours.

| Monitor | Type | Target | Notes |
|---------|------|--------|-------|
| RPi 5 | Ping | `100.64.0.1` | Mobile DNS |
| Pi-hole (Mobile) | TCP | `100.64.0.1:53` | DNS |

### External Sites (15m interval)

Public websites and services.

| Monitor | Type | Target | Notes |
|---------|------|--------|-------|
| cronova.dev | HTTP | `https://cronova.dev` | Main domain |
| verava.ai | HTTP | `https://verava.ai` | When purchased |

### Certificates (1d interval)

TLS certificate expiration monitoring.

| Monitor | Type | Target | Days Warning |
|---------|------|--------|--------------|
| hs.cronova.dev | Cert | `https://hs.cronova.dev` | 14 |
| vault.cronova.dev | Cert | `https://vault.cronova.dev` | 14 |
| cronova.dev | Cert | `https://cronova.dev` | 14 |

---

## Notification Setup

### ntfy Topics

| Topic | Purpose | Priority |
|-------|---------|----------|
| `cronova-critical` | Headscale, Vaultwarden, VPS down | urgent |
| `cronova-warning` | Home services degraded | high |
| `cronova-info` | Backups, mobile kit, maintenance | default |

### Notification Configuration

In Uptime Kuma → Settings → Notifications → Add:

```
Type: ntfy
Server URL: https://notify.cronova.dev
Topic: cronova-critical
Priority: urgent
Username: augusto
Password: <ntfy-password>
```

Create three notifications (critical, warning, info) with different topics.

### Assign Notifications to Monitors

| Monitor Group | Notification |
|---------------|--------------|
| Critical | cronova-critical |
| High Priority | cronova-warning |
| Mobile Kit | cronova-info |
| External Sites | cronova-warning |
| Certificates | cronova-warning |

---

## Status Pages

Create a status page at `/status` for public visibility (optional).

### Page Configuration

- **Title**: Cronova Status
- **Description**: Service status for cronova.dev infrastructure
- **Show Tags**: Yes
- **Show Powered By**: No

### Groups on Status Page

1. **Core Infrastructure**
   - Headscale
   - VPS Pi-hole

2. **Home Services**
   - Home Assistant
   - Jellyfin
   - Vaultwarden

3. **Storage**
   - NAS
   - Syncthing

4. **Bitcoin**
   - Start9

---

## Manual Setup Steps

1. **Access Uptime Kuma**
   ```
   https://status.cronova.dev
   ```
   Create admin account on first visit.

2. **Add Notifications**
   - Settings → Notifications → Add
   - Create 3 ntfy notifications (critical, warning, info)

3. **Create Monitor Groups**
   - Add tag: "Critical"
   - Add tag: "High Priority"
   - Add tag: "Mobile"
   - Add tag: "External"
   - Add tag: "Certificates"

4. **Add Monitors**
   - Use tables above for configuration
   - Assign appropriate tags
   - Assign appropriate notifications

5. **Create Status Page** (optional)
   - Status Pages → New Status Page
   - Add monitor groups

6. **Test Notifications**
   ```bash
   # Manually trigger test
   curl -d "Test from Uptime Kuma setup" \
     -H "Authorization: Bearer <token>" \
     https://notify.cronova.dev/cronova-critical
   ```

---

## Maintenance Windows

Schedule maintenance windows to suppress alerts:

| Window | Schedule | Services |
|--------|----------|----------|
| Weekly updates | Sunday 03:00-05:00 | All VPS services |
| Mobile kit sleep | Daily 22:00-07:00 | RPi 5, Pi-hole Mobile |

---

## Backup

Uptime Kuma data is stored in Docker volume `uptime-kuma-data`.

Export configuration periodically:
- Settings → Backup → Export

Store exports in: `/mnt/data/backups/uptime-kuma/`
