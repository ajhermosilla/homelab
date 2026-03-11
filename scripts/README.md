# Scripts

Utility scripts for homelab operations.

## Setup

Make scripts executable after cloning:

```bash
chmod +x scripts/*.sh
```

## Available Scripts

### backup-verify.sh

Monthly backup verification script. Tests backup integrity and restore capability.

```bash
# Standard monthly verification
./scripts/backup-verify.sh

# Full quarterly drill (includes more extensive tests)
./scripts/backup-verify.sh --full
```

**What it tests (8 suites):**
1. Restic repository health
2. Snapshot freshness (Headscale, Vaultwarden, HA, Paperless, Immich)
3. Headscale restore (db.sqlite, keys)
4. Vaultwarden restore (db, RSA keys)
5. Home Assistant restore (config, storage)
6. Paperless-ngx restore (data + media directories)
7. Immich DB restore (pg_dump gzip integrity + SQL header)
8. Offsite backup accessibility (rclone)

**Environment variables:**
```bash
export RESTIC_REPOSITORY="rest:http://$RESTIC_USER:$RESTIC_HTPASSWD@192.168.0.12:8000/homelab"
export RESTIC_PASSWORD_FILE="/root/.restic-password"
export NTFY_URL="https://notify.cronova.dev"
export NTFY_TOPIC="cronova-info"
export RCLONE_REMOTE="gdrive-crypt:homelab"
```

**Schedule:** First Sunday of each month (add to cron or systemd timer)

```bash
# Cron example (run at 3 AM on first Sunday)
0 3 1-7 * 0 /path/to/scripts/backup-verify.sh >> /var/log/backup-verify.log 2>&1
```

### backup-notify.sh

Notification helper for backup job completion/failure.

```bash
# Success notification
./scripts/backup-notify.sh headscale success "Backup completed in 5s"

# Failure notification (sends to critical topic)
./scripts/backup-notify.sh vaultwarden failed "Connection refused"

# Warning notification
./scripts/backup-notify.sh homeassistant warning "Slow backup (2m)"
```

**Use in backup scripts:**
```bash
#!/bin/bash
# Example backup script

SERVICE="headscale"
BACKUP_START=$(date +%s)

# Run backup
if restic backup /var/lib/headscale --tag headscale; then
    DURATION=$(($(date +%s) - BACKUP_START))
    /path/to/scripts/backup-notify.sh "$SERVICE" success "Completed in ${DURATION}s"
else
    /path/to/scripts/backup-notify.sh "$SERVICE" failed "Restic backup failed"
    exit 1
fi
```

**Environment variables:**
```bash
export NTFY_URL="https://notify.cronova.dev"
export NTFY_TOPIC_INFO="cronova-info"
export NTFY_TOPIC_CRITICAL="cronova-critical"
```

### docker-boot-orchestrator.sh

Post-boot Docker stack orchestration for Docker VM. Starts all 10 stacks in correct dependency order (14 phases). Runs automatically via systemd on boot.

```bash
# Manual re-run (stops everything, then starts in order)
sudo /opt/homelab/repo/scripts/docker-boot-orchestrator.sh
```

**Solves:** mqtt-net race condition (Frigate needs Mosquitto's network) and NFS mount race (NAS may boot slower than Docker VM).

**Location:** Deployed to Docker VM at `/opt/homelab/repo/scripts/`

### homelab-recovery.sh

Diagnoses and recovers from common outage scenarios. Run from any device on LAN or via Tailscale.

```bash
# Full check (WAN, Docker, Tailscale)
./scripts/homelab-recovery.sh

# Just check/fix WAN
./scripts/homelab-recovery.sh --wan-only

# Just check Docker containers
./scripts/homelab-recovery.sh --docker-only
```

### nas-prep-env.sh

One-time setup script to generate `.env` files for NAS deployment.

```bash
# Run once before first NAS deployment
bash scripts/nas-prep-env.sh
```

**Creates:** Samba `.env` with generated password, backup `.env` from template, Restic REST htpasswd file. Save the Samba password in Vaultwarden.

## Dependencies

- `restic` - Backup tool
- `sqlite3` - Database verification
- `jq` - JSON parsing
- `curl` - Notifications
- `rclone` - Offsite backup verification (optional)

Install on Debian/Ubuntu:
```bash
apt install restic sqlite3 jq curl rclone
```

## Adding New Scripts

1. Create script in `scripts/` directory
2. Add shebang: `#!/bin/bash`
3. Make executable: `chmod +x scripts/newscript.sh`
4. Document in this README
5. Add to git: `git add scripts/newscript.sh`
