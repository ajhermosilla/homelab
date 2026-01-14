#!/bin/sh
# Headscale hourly backup script
# Runs via cron in the headscale-backup sidecar container

set -e

TIMESTAMP=$(date +%Y%m%d_%H%M)
BACKUP_DIR="/backups"
RETENTION_HOURS="${BACKUP_RETENTION_HOURS:-720}"  # 30 days default

# Ensure backup directory exists
mkdir -p "${BACKUP_DIR}"

# Backup SQLite database with proper locking
# Using sqlite3 .backup for consistency (no corruption during write)
if [ -f /var/lib/headscale/db.sqlite ]; then
    sqlite3 /var/lib/headscale/db.sqlite ".backup '${BACKUP_DIR}/db_${TIMESTAMP}.sqlite'"
    echo "[$(date)] Database backed up: db_${TIMESTAMP}.sqlite"
else
    echo "[$(date)] WARNING: db.sqlite not found"
fi

# Backup config files
tar -czf "${BACKUP_DIR}/config_${TIMESTAMP}.tar.gz" \
    -C /etc headscale/ 2>/dev/null || true
echo "[$(date)] Config backed up: config_${TIMESTAMP}.tar.gz"

# Cleanup old backups (keep last N hours worth)
# RETENTION_HOURS=720 = 30 days * 24 hours
find "${BACKUP_DIR}" -name "db_*.sqlite" -mmin +$((RETENTION_HOURS * 60)) -delete 2>/dev/null || true
find "${BACKUP_DIR}" -name "config_*.tar.gz" -mmin +$((RETENTION_HOURS * 60)) -delete 2>/dev/null || true

# Log backup count
DB_COUNT=$(ls -1 "${BACKUP_DIR}"/db_*.sqlite 2>/dev/null | wc -l)
echo "[$(date)] Backup complete. ${DB_COUNT} database backups retained."
