# Secrets Setup

This directory contains secret files for Docker Compose secrets.

## Required Files

Create these files with your actual secrets (they are gitignored):

```bash
# Vaultwarden admin token
openssl rand -base64 32 > admin_token.txt

# Restic encryption password (for backup sidecar)
openssl rand -base64 32 > restic_password.txt
```

## File Permissions

Ensure proper permissions:

```bash
chmod 600 *.txt
```

## How It Works

Docker Compose mounts these files at `/run/secrets/<name>` inside containers.
Services read secrets from files instead of environment variables.

Benefits over env vars:
- Not visible in `docker inspect`
- Not logged in process lists
- Not passed to child processes
- Can be rotated without rebuild

## Verification

Check secrets are mounted:

```bash
docker exec vaultwarden cat /run/secrets/admin_token
```
