#!/bin/sh
# Offsite Sync Script — Google Drive via rclone crypt
# Runs as cron job inside offsite-sync sidecar on NAS
#
# Flow:
#   1. Pull Headscale backups from VPS (rsync over SSH, last 48h only)
#   2. Sync Restic repos to encrypted Google Drive (rclone sync)
#   3. Sync Headscale staging to encrypted Google Drive
#   4. Send ntfy notification on success/failure
#
# Required env vars:
#   RCLONE_REMOTE    - rclone crypt remote (e.g., gdrive-crypt:homelab)
#   VPS_HOST         - VPS Tailscale IP
#   VPS_USER         - VPS SSH user
#   VPS_BACKUP_PATH  - Headscale backup dir on VPS
#   NTFY_URL         - ntfy server URL
#
# Optional env vars:
#   RCLONE_BWLIMIT   - bandwidth limit (default: 5M)

set -e

RCLONE_BWLIMIT=${RCLONE_BWLIMIT:-5M}
NTFY_URL=${NTFY_URL:-https://notify.cronova.dev}
RESTIC_DIR="/data/restic"
HEADSCALE_DIR="/data/headscale"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

notify() {
    local priority="$1"
    local title="$2"
    local message="$3"
    local topic="cronova-info"
    local tags="white_check_mark"

    if [ "$priority" = "failure" ]; then
        topic="cronova-critical"
        tags="rotating_light"
        priority="urgent"
    else
        priority="default"
    fi

    curl -sf \
        -H "Title: $title" \
        -H "Priority: $priority" \
        -H "Tags: $tags" \
        -d "$message" \
        "${NTFY_URL}/${topic}" >/dev/null 2>&1 || log "WARNING: ntfy notification failed"
}

# Validate required variables
for var in RCLONE_REMOTE VPS_HOST VPS_USER VPS_BACKUP_PATH; do
    eval val=\$$var
    if [ -z "$val" ]; then
        log "ERROR: Missing required env var: $var"
        notify "failure" "Offsite Sync Failed" "Missing env var: $var"
        exit 1
    fi
done

ERRORS=""
START_TIME=$(date +%s)

# --- Step 1: Pull Headscale backups from VPS (last 48h only) ---
log "Step 1: Pulling Headscale backups from VPS ($VPS_HOST)"

mkdir -p "$HEADSCALE_DIR"

if rsync -az --delete \
    -e "ssh -i /root/.ssh/id_ed25519 -o StrictHostKeyChecking=accept-new -o ConnectTimeout=30" \
    --include='*/' \
    --include='*.tar.gz' \
    --include='*.sqlite' \
    --exclude='*' \
    "${VPS_USER}@${VPS_HOST}:${VPS_BACKUP_PATH}/" \
    "$HEADSCALE_DIR/"; then

    # Remove files older than 48h from staging (keep offsite lean)
    find "$HEADSCALE_DIR" -type f -mtime +2 -delete 2>/dev/null || true
    HEADSCALE_COUNT=$(find "$HEADSCALE_DIR" -type f | wc -l | tr -d ' ')
    log "Headscale pull complete: $HEADSCALE_COUNT files staged"
else
    log "ERROR: Headscale rsync failed"
    ERRORS="${ERRORS}Headscale rsync failed. "
fi

# --- Step 2: Sync Restic repos to Google Drive ---
log "Step 2: Syncing Restic repos to ${RCLONE_REMOTE}/restic/"

if [ -d "$RESTIC_DIR" ] && [ "$(ls -A "$RESTIC_DIR" 2>/dev/null)" ]; then
    if rclone sync "$RESTIC_DIR/" "${RCLONE_REMOTE}/restic/" \
        --bwlimit "$RCLONE_BWLIMIT" \
        --transfers 4 \
        --log-level INFO \
        --stats 1m; then
        RESTIC_SIZE=$(rclone size "${RCLONE_REMOTE}/restic/" --json 2>/dev/null | grep -o '"bytes":[0-9]*' | cut -d: -f2 || true)
        RESTIC_SIZE_MB=$((${RESTIC_SIZE:-0} / 1048576))
        log "Restic sync complete: ${RESTIC_SIZE_MB}MB on GDrive"
    else
        log "ERROR: Restic rclone sync failed"
        ERRORS="${ERRORS}Restic sync failed. "
    fi
else
    log "WARNING: Restic directory empty or missing ($RESTIC_DIR)"
    ERRORS="${ERRORS}Restic dir empty. "
fi

# --- Step 3: Sync Headscale staging to Google Drive ---
log "Step 3: Syncing Headscale staging to ${RCLONE_REMOTE}/headscale/"

if [ -d "$HEADSCALE_DIR" ] && [ "$(ls -A "$HEADSCALE_DIR" 2>/dev/null)" ]; then
    if rclone sync "$HEADSCALE_DIR/" "${RCLONE_REMOTE}/headscale/" \
        --bwlimit "$RCLONE_BWLIMIT" \
        --transfers 4 \
        --log-level INFO \
        --stats 1m; then
        log "Headscale sync complete"
    else
        log "ERROR: Headscale rclone sync failed"
        ERRORS="${ERRORS}Headscale sync failed. "
    fi
else
    log "WARNING: Headscale staging empty ($HEADSCALE_DIR)"
fi

# --- Step 4: Report results ---
END_TIME=$(date +%s)
DURATION=$(( (END_TIME - START_TIME) / 60 ))

if [ -z "$ERRORS" ]; then
    log "Offsite sync completed successfully in ${DURATION}m"
    notify "success" "Offsite Sync OK" "Completed in ${DURATION}m. Restic: ${RESTIC_SIZE_MB:-?}MB on GDrive."
else
    log "Offsite sync completed with errors in ${DURATION}m: $ERRORS"
    notify "failure" "Offsite Sync FAILED" "Errors: ${ERRORS}Duration: ${DURATION}m"
    exit 1
fi
