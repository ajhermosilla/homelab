#!/bin/sh
# Restic Backup Script for Docker Sidecars
# Usage: Set environment variables and run
#
# Required env vars:
#   RESTIC_REPOSITORY      - restic repo URL (rest:http://user:pass@host:8000/repo)
#   RESTIC_PASSWORD        - encryption password
#     OR RESTIC_PASSWORD_FILE - path to file containing password (Docker secrets)
#   BACKUP_PATH            - path to backup (e.g., /data)
#   BACKUP_TAG             - tag for snapshots (e.g., vaultwarden)
#
# Optional env vars:
#   BACKUP_EXCLUDE    - exclude pattern (comma-separated)
#   KEEP_DAILY        - daily snapshots to keep (default: 7)
#   KEEP_WEEKLY       - weekly snapshots to keep (default: 4)
#   KEEP_MONTHLY      - monthly snapshots to keep (default: 12)

set -e

# Defaults
KEEP_DAILY=${KEEP_DAILY:-7}
KEEP_WEEKLY=${KEEP_WEEKLY:-4}
KEEP_MONTHLY=${KEEP_MONTHLY:-12}

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Validate required variables
if [ -z "$RESTIC_REPOSITORY" ] || [ -z "$BACKUP_PATH" ] || [ -z "$BACKUP_TAG" ]; then
    log "ERROR: Missing required environment variables"
    log "Required: RESTIC_REPOSITORY, BACKUP_PATH, BACKUP_TAG"
    exit 1
fi

# Check for password (either direct or file-based)
if [ -z "$RESTIC_PASSWORD" ] && [ -z "$RESTIC_PASSWORD_FILE" ]; then
    log "ERROR: Missing password - set RESTIC_PASSWORD or RESTIC_PASSWORD_FILE"
    exit 1
fi

log "Starting backup: $BACKUP_TAG"

# Initialize repo if needed (will fail silently if already initialized)
restic init 2>/dev/null || true

# Build exclude args
EXCLUDE_ARGS=""
if [ -n "$BACKUP_EXCLUDE" ]; then
    for pattern in $(echo "$BACKUP_EXCLUDE" | tr ',' ' '); do
        EXCLUDE_ARGS="$EXCLUDE_ARGS --exclude $pattern"
    done
fi

# Run backup
log "Backing up $BACKUP_PATH"
restic backup "$BACKUP_PATH" --tag "$BACKUP_TAG" $EXCLUDE_ARGS

# Prune old snapshots
log "Pruning old snapshots (keep: $KEEP_DAILY daily, $KEEP_WEEKLY weekly, $KEEP_MONTHLY monthly)"
restic forget --tag "$BACKUP_TAG" \
    --keep-daily "$KEEP_DAILY" \
    --keep-weekly "$KEEP_WEEKLY" \
    --keep-monthly "$KEEP_MONTHLY" \
    --prune

# Verify integrity (weekly - check if day of week is Sunday)
if [ "$(date +%u)" = "7" ]; then
    log "Running weekly integrity check"
    restic check
fi

log "Backup complete: $BACKUP_TAG"
