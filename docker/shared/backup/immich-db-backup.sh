#!/bin/sh
# Immich Database Backup Script
# Runs pg_dump against immich-db, then backs up the dump with restic.
#
# Unlike the generic restic-backup.sh, this script creates a consistent
# PostgreSQL dump before backing up, which is safer for a live database
# with vector extensions (VectorChord) and face recognition embeddings.
#
# Required env vars:
#   RESTIC_REPOSITORY      - restic repo URL
#   RESTIC_PASSWORD        - encryption password
#   PGHOST                 - PostgreSQL host (immich-db)
#   PGUSER                 - PostgreSQL user (immich)
#   PGPASSWORD             - PostgreSQL password
#   PGDATABASE             - PostgreSQL database name (immich)
#
# Optional env vars:
#   KEEP_DAILY             - daily snapshots to keep (default: 7)
#   KEEP_WEEKLY            - weekly snapshots to keep (default: 4)
#   KEEP_MONTHLY           - monthly snapshots to keep (default: 12)

set -e

KEEP_DAILY=${KEEP_DAILY:-7}
KEEP_WEEKLY=${KEEP_WEEKLY:-4}
KEEP_MONTHLY=${KEEP_MONTHLY:-12}
DUMP_DIR="/backup"
DUMP_FILE="${DUMP_DIR}/immich-db.sql.gz"
BACKUP_TAG="immich-db"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Validate required variables
if [ -z "$RESTIC_REPOSITORY" ] || [ -z "$PGHOST" ] || [ -z "$PGUSER" ] || [ -z "$PGDATABASE" ]; then
    log "ERROR: Missing required environment variables"
    log "Required: RESTIC_REPOSITORY, PGHOST, PGUSER, PGDATABASE"
    exit 1
fi

if [ -z "$RESTIC_PASSWORD" ] && [ -z "$RESTIC_PASSWORD_FILE" ]; then
    log "ERROR: Missing password - set RESTIC_PASSWORD or RESTIC_PASSWORD_FILE"
    exit 1
fi

# Step 1: pg_dump
log "Starting pg_dump: ${PGDATABASE}@${PGHOST}"
mkdir -p "$DUMP_DIR"

if ! pg_dump -h "$PGHOST" -U "$PGUSER" -d "$PGDATABASE" --no-owner --no-privileges | gzip > "$DUMP_FILE"; then
    log "ERROR: pg_dump failed"
    rm -f "$DUMP_FILE"
    exit 1
fi

DUMP_SIZE=$(du -h "$DUMP_FILE" | cut -f1)
log "pg_dump complete: ${DUMP_FILE} (${DUMP_SIZE})"

# Step 2: Initialize restic repo if needed
restic init 2>/dev/null || true

# Step 3: Back up the dump file
log "Backing up dump to restic"
if ! restic backup "$DUMP_DIR" --tag "$BACKUP_TAG"; then
    log "ERROR: Restic backup failed"
    rm -f "$DUMP_FILE"
    exit 1
fi

# Step 4: Verify backup
log "Verifying backup snapshot exists"
LATEST_SNAPSHOT=$(restic snapshots --tag "$BACKUP_TAG" --latest 1 --json 2>/dev/null | jq -r '.[0].short_id // empty')
if [ -z "$LATEST_SNAPSHOT" ]; then
    log "ERROR: Could not verify backup snapshot"
    rm -f "$DUMP_FILE"
    exit 1
fi
log "Verified: Latest snapshot $LATEST_SNAPSHOT"

# Step 5: Prune old snapshots
log "Pruning old snapshots (keep: $KEEP_DAILY daily, $KEEP_WEEKLY weekly, $KEEP_MONTHLY monthly)"
if ! restic forget --tag "$BACKUP_TAG" \
    --keep-daily "$KEEP_DAILY" \
    --keep-weekly "$KEEP_WEEKLY" \
    --keep-monthly "$KEEP_MONTHLY" \
    --prune; then
    log "WARNING: Prune failed, but backup succeeded"
fi

# Step 6: Weekly integrity check (Sundays)
if [ "$(date +%u)" = "7" ]; then
    log "Running weekly integrity check"
    if ! restic check; then
        log "WARNING: Integrity check failed - investigate manually"
    fi
fi

# Cleanup
rm -f "$DUMP_FILE"

SNAPSHOT_COUNT=$(restic snapshots --tag "$BACKUP_TAG" --json 2>/dev/null | jq 'length')
log "Backup complete: $BACKUP_TAG (Total snapshots: $SNAPSHOT_COUNT)"
