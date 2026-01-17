# Backup Stack

Restic REST server as offsite backup target.

## Services

| Service | Port | Purpose |
|---------|------|---------|
| Restic REST | 8000 | Backup repository server |

## Quick Start

```bash
# 1. Create htpasswd file
htpasswd -B -c htpasswd augusto

# 2. Start service
docker compose up -d

# 3. Initialize repository (from client)
export RESTIC_REPOSITORY="rest:http://augusto:$PASSWORD@100.64.0.100:8000/homelab"
export RESTIC_PASSWORD_FILE=/root/.restic-password
restic init
```

## Security Notes

- Only accessible via Tailscale (not exposed to internet)
- Data encrypted client-side before upload
- Even if server compromised, data remains encrypted
- Use strong RESTIC_PASSWORD (different from htpasswd)

### Tailscale-only Access

For extra security, bind to localhost only:
```yaml
ports:
  - "127.0.0.1:8000:8000"
```
Access via Tailscale IP: `100.64.0.100:8000`

## Client Usage

```bash
# Environment
export RESTIC_REPOSITORY="rest:http://$USER:$PASS@100.64.0.100:8000/homelab"
export RESTIC_PASSWORD_FILE=/root/.restic-password

# Backup critical data
restic backup /etc/headscale --tag headscale

# List snapshots
restic snapshots

# Restore
restic restore latest --target /tmp/restore
```

## Backup Sources

| Service | Path | Frequency |
|---------|------|-----------|
| Headscale DB | /var/lib/headscale/db.sqlite | Hourly |
| Vaultwarden | /var/lib/vaultwarden/ | Daily |
| Home Assistant | /config/ | Daily |

## Monitoring

Prometheus metrics: http://localhost:8000/metrics
