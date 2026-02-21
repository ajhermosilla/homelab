#!/bin/bash
# nas-prep-env.sh - Generate .env files for NAS deployment
# Usage: bash scripts/nas-prep-env.sh
#
# Creates:
#   docker/fixed/nas/storage/.env  (with generated Samba password)
#   docker/fixed/nas/backup/.env   (from template, no secrets)
#   docker/fixed/nas/backup/htpasswd (Restic REST server auth)
#
# Run this once before deployment day. Save the Samba password in Vaultwarden.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
STORAGE_DIR="$REPO_ROOT/docker/fixed/nas/storage"
BACKUP_DIR="$REPO_ROOT/docker/fixed/nas/backup"

# --- Pre-flight checks ---

if [ -f "$STORAGE_DIR/.env" ] || [ -f "$BACKUP_DIR/.env" ]; then
    echo "ERROR: .env files already exist. Remove them first if you want to regenerate."
    echo "  $STORAGE_DIR/.env"
    echo "  $BACKUP_DIR/.env"
    exit 1
fi

if ! command -v htpasswd &>/dev/null; then
    echo "ERROR: htpasswd not found. Install apache2-utils (Linux) or use: brew install httpd (macOS)"
    exit 1
fi

# --- Generate Samba password ---

SAMBA_PASSWORD="$(openssl rand -base64 24)"

# --- Create storage/.env ---

sed "s|your-secure-samba-password|${SAMBA_PASSWORD}|" "$STORAGE_DIR/.env.example" > "$STORAGE_DIR/.env"
echo "Created $STORAGE_DIR/.env"

# --- Create backup/.env ---

cp "$BACKUP_DIR/.env.example" "$BACKUP_DIR/.env"
echo "Created $BACKUP_DIR/.env"

# --- Generate backup/htpasswd ---

echo ""
echo "Creating htpasswd for Restic REST server (user: augusto)"
echo "Enter a password for Restic backups:"
htpasswd -B -c "$BACKUP_DIR/htpasswd" augusto
echo "Created $BACKUP_DIR/htpasswd"

# --- Summary ---

echo ""
echo "=== NAS .env files ready ==="
echo ""
echo "Samba password (save in Vaultwarden):"
echo "  $SAMBA_PASSWORD"
echo ""
echo "Files created:"
echo "  $STORAGE_DIR/.env"
echo "  $BACKUP_DIR/.env"
echo "  $BACKUP_DIR/htpasswd"
echo ""
echo "IMPORTANT: These files are gitignored. Do not commit them."
