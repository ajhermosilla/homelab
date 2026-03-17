# Backup Test Procedure

Monthly verification that backups work and can be restored.

## Backup Overview

### Backup Architecture

All backups use Restic with a centralized REST server on the NAS. See `docs/strategy/disaster-recovery.md` for full details.

| Copy | Location | Status |
|------|----------|--------|

| 1 | Original data (live volumes) | Active |
| 2 | NAS Restic REST (`/mnt/purple/backup/restic/`) | Active |
| 3 | Google Drive (rclone crypt) | Not yet configured |

### Backed-Up Services

| Service | Container | Schedule | Repository |
|---------|-----------|----------|------------|

| Headscale | headscale-backup | Hourly (VPS local) | VPS `/backup/` (tar.gz) |
| Vaultwarden | vaultwarden-backup | 2:00 AM daily | `/augusto/vaultwarden` |
| Home Assistant | homeassistant-backup | 2:30 AM daily | `/augusto/homeassistant` |
| Coolify | coolify-backup | 3:30 AM daily | `/augusto/coolify` |

---

## Monthly Test Schedule

**When:** First Sunday of each month
**Duration:** ~1 hour
**Notification:** Set calendar reminder

---

## Test Procedure

### Pre-Test Checklist

- [ ] Notify family of potential brief service interruption
- [ ] Verify test environment is ready (VM or container)
- [ ] Check disk space for restore operations
- [ ] Have ntfy open for notifications

---

### Test 1: Restic Repository Health

**Purpose:** Verify backup integrity

```bash
# Set environment (use the specific service repository)
export RESTIC_REPOSITORY="rest:http://augusto:<PASS>@192.168.0.12:8000/augusto/vaultwarden"
export RESTIC_PASSWORD="<restic-password>"

# Check repository integrity
restic check

# Expected output:
# using temporary cache in /tmp/restic-check-cache-XXXXXX
# repository xxxxxxxx is healthy
# no errors were found
```

**Pass criteria:** "no errors were found"

#### If errors found

```bash
# Attempt repair
restic repair index
restic repair snapshots
restic check
```

---

### Test 2: List Snapshots

**Purpose:** Verify backups are running on schedule

```bash
restic snapshots

# Expected output shows recent snapshots:
# ID        Time                 Host    Tags        Paths
# xxxxxxxx  2026-01-15 03:00:00  docker  headscale   /var/lib/headscale
# xxxxxxxx  2026-01-15 03:00:00  docker  vaultwarden /var/lib/vaultwarden
# xxxxxxxx  2026-01-14 03:00:00  docker  homeassistant /config
```

#### Pass criteria

- [ ] Vaultwarden snapshot within last 25 hours (2:00 AM daily)
- [ ] Home Assistant snapshot within last 25 hours (2:30 AM daily)
- [ ] Coolify snapshot within last 25 hours (3:30 AM daily)

*Note: Headscale backups are VPS-local (hourly tar.gz), not in Restic REST.*

---

### Test 3: Headscale Backup Verify (Critical)

**Purpose:** Verify mesh network can be recovered

Headscale backups are VPS-local tar.gz (not Restic REST). Run this on the VPS:

```bash
ssh vps

# List backups (hourly, 30-day retention)
ls -lt /backup/headscale/*.tar.gz | head -5

# Extract latest to temp
LATEST=$(ls -t /backup/headscale/*.tar.gz | head -1)
mkdir -p /tmp/restore-test/headscale
tar -xzf "$LATEST" -C /tmp/restore-test/headscale

# Verify critical files
ls -la /tmp/restore-test/headscale/

# Expected files:
# - db.sqlite (the critical file)
# - noise_private.key
```

#### Verify database integrity

```bash
sqlite3 /tmp/restore-test/headscale/db.sqlite "SELECT COUNT(*) FROM nodes;"

# Should return number of registered nodes (e.g., 8)
```

#### Pass criteria

- [ ] db.sqlite exists and is not empty
- [ ] SQLite query returns expected node count
- [ ] noise_private.key exists
- [ ] Latest backup is less than 2 hours old

#### Cleanup

```bash
rm -rf /tmp/restore-test/headscale
```

---

### Test 4: Vaultwarden Restore

**Purpose:** Verify password vault can be recovered

```bash
# Set Restic environment for Vaultwarden
export RESTIC_REPOSITORY="rest:http://augusto:<PASS>@192.168.0.12:8000/augusto/vaultwarden"
export RESTIC_PASSWORD="<restic-password>"

# Create test restore directory
mkdir -p /tmp/restore-test/vaultwarden

# Restore latest Vaultwarden backup
restic restore latest --target /tmp/restore-test/vaultwarden --tag vaultwarden

# Verify files exist (paths match volume mount in container)
ls -la /tmp/restore-test/vaultwarden/data/

# Expected files:
# - db.sqlite3 (main database)
# - config.json
# - rsa_key.pem / rsa_key.pub.pem
# - attachments/ (if any)
# - sends/ (if any)
```

#### Verify database

```bash
sqlite3 /tmp/restore-test/vaultwarden/data/db.sqlite3 "SELECT COUNT(*) FROM users;"

# Should return number of users (e.g., 1)
```

#### Pass criteria

- [ ] db.sqlite3 exists
- [ ] RSA keys exist
- [ ] User count matches expected

#### Cleanup

```bash
rm -rf /tmp/restore-test/vaultwarden
```

---

### Test 5: Home Assistant Restore

**Purpose:** Verify automations and history can be recovered

```bash
# Set Restic environment for Home Assistant
export RESTIC_REPOSITORY="rest:http://augusto:<PASS>@192.168.0.12:8000/augusto/homeassistant"
export RESTIC_PASSWORD="<restic-password>"

# Create test restore directory
mkdir -p /tmp/restore-test/homeassistant

# Restore latest Home Assistant backup
restic restore latest --target /tmp/restore-test/homeassistant --tag homeassistant

# Verify critical files (paths match volume mount)
ls -la /tmp/restore-test/homeassistant/config/

# Expected files:
# - configuration.yaml
# - automations.yaml
# - secrets.yaml
# - .storage/ directory
# Note: home-assistant_v2.db is excluded from backups (*.db-shm, *.db-wal, home-assistant_v2.db)
```

#### Pass criteria

- [ ] configuration.yaml exists
- [ ] automations.yaml exists
- [ ] .storage/ directory exists
- [ ] custom_components/ directory exists (HACS integrations)

#### Cleanup

```bash
rm -rf /tmp/restore-test/homeassistant
```

---

### Test 6: Offsite Backup Verification

**Purpose:** Verify Google Drive encrypted backup

**Status:** Not yet configured. Google Drive offsite via rclone crypt is planned but not active.

When configured:

```bash
# List remote files
rclone ls gdrive-crypt:homelab/ | head -20

# Check sync status
rclone check /srv/backup/critical gdrive-crypt:homelab --one-way

# Expected: No differences found
```

#### Pass criteria

- [ ] Files exist on remote
- [ ] No sync differences

*Skip this test until offsite backup is configured.*

---

### Test 7: Full Restore Drill (Quarterly)

**Purpose:** Complete disaster recovery simulation

**Do this quarterly** (every 3 months) in a test VM.

1. Spin up fresh Docker VM
2. Install Docker and dependencies
3. Restore Headscale from backup
4. Restore Vaultwarden from backup
5. Verify services start and function
6. Access Vaultwarden, verify login works
7. Connect a test Tailscale client

#### Pass criteria

- [ ] Services start without errors
- [ ] Vaultwarden login successful
- [ ] Tailscale client connects

---

## Test Results Template

Copy this template for each monthly test:

```markdown
## Backup Test Results - YYYY-MM-DD

**Tester:** Augusto
**Duration:** XX minutes

### Results

| Test | Status | Notes |
|------|--------|-------|
| 1. Restic health | ✅/❌ | |
| 2. Snapshot check | ✅/❌ | |
| 3. Headscale restore | ✅/❌ | |
| 4. Vaultwarden restore | ✅/❌ | |
| 5. Home Assistant restore | ✅/❌ | |
| 6. Offsite verification | ✅/❌ | |

### Issues Found

- None / List issues

### Actions Taken

- None / List actions

### Next Test

- YYYY-MM-DD (first Sunday of next month)
```

---

## Automated Monitoring

### Backup Job Alerts

Configure backup scripts to notify on completion/failure:

```bash
#!/bin/bash
# End of backup script

if [ $? -eq 0 ]; then
    curl -d "Backup completed successfully" \
         -H "Priority: low" \
         https://notify.cronova.dev/cronova-info
else
    curl -d "BACKUP FAILED - check logs" \
         -H "Priority: urgent" \
         https://notify.cronova.dev/cronova-critical
fi
```

### Uptime Kuma Checks

Add monitors for backup infrastructure:

| Check | Type | Target |
|-------|------|--------|

| Restic REST (NAS) | HTTP | `http://100.82.77.97:8000/` (expect 401) |

---

## Recovery Time Objectives

| Service | RTO | RPO | Notes |
|---------|-----|-----|-------|

| Headscale | 30 min | 1 hour | Mesh depends on this |
| Vaultwarden | 1 hour | 24 hours | Can use cached passwords |
| Home Assistant | 2 hours | 24 hours | Automations can wait |
| Frigate | 4 hours | 7 days | Recordings less critical |

**RTO** = Recovery Time Objective (how fast to restore)
**RPO** = Recovery Point Objective (max data loss acceptable)

---

## Emergency Contacts

If backup restore fails during actual disaster:

| Issue | Action |
|-------|--------|

| Restic corruption | Run `restic repair index` + `restic repair snapshots` |
| Restic REST unreachable | Check NAS, Docker, `/data/docker` filesystem |
| All local backups lost | Restore from Google Drive (when configured) |
| Encryption key lost | Check Vaultwarden (paper backup) — all stacks share one password |

See `docs/strategy/disaster-recovery.md` for full recovery procedures.

---

## Revision History

| Date | Change |
|------|--------|

| 2026-01-16 | Initial document |
