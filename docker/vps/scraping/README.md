# Scraping Stack

changedetection.io for website change monitoring.

## Services

| Service | Port | Purpose |
|---------|------|---------|
| changedetection | 5000 | Web change monitoring |
| Playwright | 3000 | JavaScript rendering |

## Quick Start

```bash
# 1. Start services
docker compose up -d

# 2. Access web interface
# http://vps-ip:5000 (or via Caddy at watch.cronova.dev)

# 3. SET PASSWORD IMMEDIATELY
# Settings → Security → Set Password
# This service has NO AUTH by default!
```

## Use Cases

- Price tracking on e-commerce sites
- Documentation changes for tools
- Job postings on company career pages
- Government/regulatory announcements
- Software release notes
- Stock availability for hardware

## Notifications

Configure ntfy notifications:
- Settings → Notifications → Add
- URL: `https://notify.cronova.dev/cronova-info`

## Playwright

The Playwright container handles JavaScript-heavy sites automatically.

Resource limits:
- Memory: 2GB
- CPUs: 2

## Caddy Integration (Optional)

Add to Caddyfile for HTTPS access:

```
watch.cronova.dev {
    basicauth * {
        augusto $2a$14$...  # caddy hash-password
    }
    reverse_proxy localhost:5000
}
```

## Data

- Stored in `changedetection-data` volume
- Can export/import watches via JSON
- Backup: Settings → Backup
