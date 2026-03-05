#!/bin/sh
# Backup .env files and secret directories from Docker VM stacks
# Run on Docker VM: /opt/homelab/repo/docker/shared/backup/backup-env.sh
#
# Collects all .env files and auth secrets into /opt/homelab/env-backup/
# This directory should be included in a Restic backup job.

set -e

STACKS_DIR="/opt/homelab/repo/docker/fixed/docker-vm"
BACKUP_DIR="/opt/homelab/repo/env-backup"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

mkdir -p "$BACKUP_DIR"

count=0
for stack in "$STACKS_DIR"/*/; do
    name=$(basename "$stack")

    # Backup .env file
    if [ -f "$stack/.env" ]; then
        cp "$stack/.env" "$BACKUP_DIR/${name}.env"
        count=$((count + 1))
    fi

    # Backup secrets directories (e.g., auth/config/secrets/)
    if [ -d "$stack/config/secrets" ]; then
        mkdir -p "$BACKUP_DIR/${name}-secrets"
        cp -r "$stack/config/secrets/"* "$BACKUP_DIR/${name}-secrets/"
        count=$((count + 1))
    fi
done

# Also backup shared common.env
if [ -f "$STACKS_DIR/../../shared/common.env" ]; then
    cp "$STACKS_DIR/../../shared/common.env" "$BACKUP_DIR/shared-common.env"
    count=$((count + 1))
fi

log "Backed up $count items to $BACKUP_DIR"
ls -la "$BACKUP_DIR/"
