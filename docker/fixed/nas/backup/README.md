# Backup Stack

Restic REST server as local backup target.

## Services

| Service | Port | Purpose |
|---------|------|---------|
| Restic REST | 8000 | Backup repository server |

## Quick Start

```bash
# 1. Create backup directory
sudo mkdir -p /srv/backup/restic
sudo chown -R 1000:1000 /srv/backup

# 2. Create htpasswd file
sudo apt install apache2-utils
htpasswd -B -c htpasswd augusto

# 3. Start service
docker compose up -d

# 4. Initialize repository (from client)
export RESTIC_REPOSITORY="rest:http://augusto:$PASSWORD@192.168.0.12:8000/homelab"
export RESTIC_PASSWORD_FILE=/root/.restic-password
restic init
```

## Client Usage

```bash
# Environment setup
export RESTIC_REPOSITORY="rest:http://$USER:$PASS@192.168.0.12:8000/homelab"
export RESTIC_PASSWORD_FILE=/root/.restic-password

# Backup
restic backup /var/lib/headscale --tag headscale

# List snapshots
restic snapshots

# Restore
restic restore latest --target /tmp/restore

# Prune old snapshots
restic forget --keep-daily 7 --keep-weekly 4 --keep-monthly 12 --prune
```

## Backup Sources

| Service | Path | Frequency |
|---------|------|-----------|
| Headscale | /var/lib/headscale/ | Hourly |
| Vaultwarden | /var/lib/vaultwarden/ | Daily |
| Home Assistant | /config/ | Daily |
| Frigate config | /config/ | Weekly |
| Pi-hole | /etc/pihole/ | Weekly |

## 3-2-1 Strategy

- **3 copies**: NAS + Restic + Google Drive
- **2 media**: NAS drives + external WD Red 3TB
- **1 offsite**: Google Drive (rclone crypt)

## Monitoring

Prometheus metrics: http://192.168.0.12:8000/metrics
