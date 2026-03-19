# Storage Strategy

Drive layout, backup topology, and data protection across all hosts.

---

## Drive Inventory

### NAS (ASUS P8H77-I — 4 SATA ports)

| Device | Model | Size | Mount | Role | Status |
|--------|-------|------|-------|------|--------|
| sda | Lexar NQ100 SSD | 240GB | `/` (LVM) | OS, Docker data-root (`/data/docker`) | Healthy |
| sdb | WD Purple (WD23PURZ) | 2TB | `/mnt/purple` | Frigate recordings, Restic repos | **98% full** |
| sdc | WD Red Plus (WD80EFBX) | 8TB | `/mnt/red8` (planned) | Media, downloads, family data, service data | Recovery pending |
| sdd | Generic SSD | 512GB | `/mnt/backup-ssd` (planned) | Critical data backup (family photos/videos) | Unmounted |
| sde | Generic Flash Disk | 3.7GB | `/boot/efi`, `/boot` | Boot USB (permanent) | Healthy |

### Docker VM (VM 101)

| Disk | Size | Role |
|------|------|------|
| virtio0 | 100GB | Debian OS, Docker volumes, container data |

### VPS (Vultr)

| Disk | Size | Role |
|------|------|------|
| NVMe | 32GB | OS, Headscale DB, container data |

### Spare Drives (at home)

| Drive | Size | Interface | Location |
|-------|------|-----------|----------|
| WD Red 3TB (#1) | 3TB | SATA | Sabrent USB dock |
| WD Red 3TB (#2) | 3TB | SATA | Spare |
| Old drive | 1TB | SATA | Spare |
| Old drive | 2TB | SATA | Spare |

---

## Storage Architecture

### NAS Filesystem Layout

```text
NAS Drives
├── sda (240GB SSD) ─── LVM root (/)
│   ├── /data/docker/          # Docker data-root (images, volumes)
│   ├── /srv/forgejo/          # Forgejo git data
│   └── /data/coolify/         # Coolify PaaS data
│
├── sdb (2TB Purple) ─── /mnt/purple
│   ├── /mnt/purple/frigate/          # Frigate NVR recordings
│   ├── /mnt/purple/backup/restic/    # Restic REST server data
│   └── /mnt/purple/red-recovery/     # 8TB recovery data (temporary, 1.5TB)
│
├── sdc (8TB Red) ─── /mnt/red8 (after recovery)
│   ├── /mnt/red8/media/        # Music, videos, BD rips
│   ├── /mnt/red8/downloads/    # *arr stack downloads
│   ├── /mnt/red8/data/         # Family photos/videos, old backups
│   ├── /mnt/red8/sync/         # Syncthing data
│   └── /mnt/red8/backup/       # Service backups
│
└── sdd (512GB SSD) ─── /mnt/backup-ssd (after recovery)
    ├── /mnt/backup-ssd/family-videos/   # 45GB (irreplaceable)
    └── /mnt/backup-ssd/family-photos/   # 168GB (irreplaceable)
```

### NAS Symlink Layer (`/srv/`)

Services access data through `/srv/` symlinks, decoupling mount points from service paths:

```text
/srv/frigate      → /mnt/purple/frigate
/srv/media        → /mnt/red8/media
/srv/downloads    → /mnt/red8/downloads
/srv/data         → /mnt/red8/data
/srv/sync         → /mnt/red8/sync
/srv/backup       → /mnt/red8/backup
```

### NFS Exports (NAS → Docker VM)

| NAS Export | Docker VM Mount | Used By | Mode |
|------------|-----------------|---------|------|
| `/srv/frigate` | `/mnt/nas/frigate` | Frigate NVR | rw |
| `/srv/media` | `/mnt/nas/media` | Jellyfin, \*arr stack | ro |
| `/srv/downloads` | `/mnt/nas/downloads` | qBittorrent, \*arr stack | rw |
| `/srv/photos` | `/mnt/nas/photos` | Immich (external library) | ro |

Docker VM fstab entries use `defaults,_netdev,nofail` to handle NAS unavailability gracefully.

---

## Backup Topology

### 3-2-1 Strategy

```text
[Docker VM]                    [NAS]                        [Google Drive]
 Live data                      Restic REST                  rclone crypt
 (Docker volumes)               (/mnt/purple/backup/restic)  (gdrive-crypt:homelab/)
     │                               │                            │
     │  restic backup (nightly) ─────┘                            │
     │                                                            │
     │                          offsite-sync (4:30 AM) ───────────┘
     │
     └── Copy 1 (production)    Copy 2 (local backup)        Copy 3 (offsite)
```

### Backup Schedule (PYT — America/Asuncion)

| Time | Service | Container | Restic Repo | What's Backed Up |
|------|---------|-----------|-------------|------------------|
| Hourly | Headscale | headscale-backup | Local tar.gz (VPS) | SQLite DB, noise key, config |
| 2:00 AM | Vaultwarden | vaultwarden-backup | `/augusto/vaultwarden` | vaultwarden-data volume |
| 2:15 AM | Caddy | caddy-backup | `/augusto/caddy` | TLS certificates, ACME state |
| 2:30 AM | Home Assistant | homeassistant-backup | `/augusto/homeassistant` | homeassistant-config volume |
| 2:45 AM | Pi-hole | pihole-backup | `/augusto/pihole` | DNS config, blocklists, local DNS entries |
| 3:00 AM | Paperless-ngx | paperless-backup | `/augusto/paperless` | Data + media volumes |
| 3:15 AM | Immich | immich-backup | `/augusto/immich` | PostgreSQL pg_dump (metadata only) |
| 3:30 AM | Coolify | coolify-backup | `/augusto/coolify` | PostgreSQL dumps + SSH keys |
| 4:30 AM | Offsite | offsite-sync | — | Restic repos + Headscale → Google Drive |

### Retention Policy

All Restic sidecars use the same retention:

| Period | Keep |
|--------|------|
| Daily | 7 |
| Weekly | 4 |
| Monthly | 12 |

Automatic pruning runs after every backup. Weekly integrity checks on Sundays.

### Restic REST Server

```yaml
# NAS — /mnt/purple/backup/restic/
restic-rest:
  image: restic/rest-server:0.14.0
  ports: "8000:8000"
  options: --private-repos --prometheus
  auth: htpasswd (forces /username/ prefix per repo)
  limits: 256M RAM, 0.5 CPU
```

All Docker VM sidecars connect to `rest:http://augusto:<pass>@192.168.0.12:8000/augusto/<service>`.

### Offsite Sync Details

```text
offsite-sync (NAS container, 4:30 AM)
├── 1. rsync Headscale backups from VPS (SSH, last 48h only)
├── 2. rclone sync Restic repos → gdrive-crypt:homelab/restic/
├── 3. rclone sync Headscale staging → gdrive-crypt:homelab/headscale/
├── 4. ntfy notification (success → cronova-info, failure → cronova-critical)
└── Bandwidth limit: 5 MB/s (RCLONE_BWLIMIT)
```

**Encryption:**rclone crypt wraps Google Drive with AES-256. Restore requires**three secrets**: rclone password, rclone salt, and RESTIC_PASSWORD. All stored in Vaultwarden.

---

## Data Criticality

| Data | Size | Irreplaceable | Copies | Location(s) |
|------|------|---------------|--------|-------------|
| Family videos (2010-2013) | 45GB | **Yes** | 2 (pending 3) | Purple recovery, 8TB (planned), SSD (planned), GDrive |
| Family photos (2006-2014) | 168GB | **Yes** | 2 (pending 3) | Purple recovery, 8TB (planned), SSD (planned), GDrive |
| Vaultwarden DB | ~50MB | Yes (passwords) | 3 | Docker VM, Restic, GDrive |
| HA config | ~200MB | Hard to recreate | 3 | Docker VM, Restic, GDrive |
| Paperless documents | Variable | Yes (scanned docs) | 3 | Docker VM, Restic, GDrive |
| Immich metadata | ~500MB | Yes (tags, albums) | 3 | Docker VM, Restic, GDrive |
| Forgejo repos | Variable | Yes (git history) | 3 | NAS, local clones, GitHub mirror |
| Frigate recordings | ~158GB | No (7-day retention) | 1 | NAS Purple only |
| Music collection | 346GB | No (re-downloadable) | 1 | Purple recovery (pending 8TB) |
| Old laptop backups | 473GB | Mostly no | 1 | Purple recovery (pending 8TB) |

### Protection Gaps

| Gap | Risk | Mitigation |
|-----|------|------------|
| ~~Forgejo has no offsite mirror~~ | ~~Single point of failure for git~~ | **Resolved** — GitHub push mirror active (sync on commit + 8h interval) |
| Frigate recordings = 1 copy | Loss if Purple fails | Acceptable — recordings are ephemeral |
| Family media pending 8TB recovery | Currently only on 98%-full Purple | Execute recovery plan ASAP |
| Encryption keys only in Vaultwarden | Lose Vaultwarden = lose offsite | Paper backup recommended |

---

## Capacity Planning

### Current Usage

| Drive | Total | Used | Free | Pressure |
|-------|-------|------|------|----------|
| NAS SSD (sda) | 240GB | ~60GB | ~180GB | Low |
| NAS Purple (sdb) | 2TB | 1.7TB | 45GB | **Critical** |
| NAS Red (sdc) | 8TB | — | — | Recovery pending |
| NAS SSD (sdd) | 512GB | ~0 | 512GB | Unmounted |
| Docker VM | 100GB | ~40GB | ~60GB | Low |
| VPS | 32GB | ~10GB | ~22GB | Low |

### Post-Recovery Projections

After 8TB recovery and Purple cleanup:

| Drive | Projected Used | Projected Free | Growth Rate |
|-------|---------------|----------------|-------------|
| Purple (sdb) | ~170GB | ~1.6TB | ~5GB/week (Frigate) |
| Red (sdc) | ~1.5TB | ~5.8TB | Slow (media additions) |
| Backup SSD (sdd) | ~213GB | ~263GB | Static (critical data only) |

Purple will sustain Frigate for **~6 years** at current recording rates after recovery frees 1.5TB.

### Growth Triggers

| Trigger | When | Action |
|---------|------|--------|
| Purple > 80% | ~2028 | Review Frigate retention or add camera exclusions |
| Red > 70% (5.6TB) | Years away | Consider SnapRAID parity with spare 3TB drives |
| Restic repos > 500GB | Monitor quarterly | Review retention or move to Red |
| Docker VM > 80GB | Monitor | Prune images, review volumes |

---

## Recovery Procedures

### Quick Reference

| Scenario | Recovery Source | Procedure | RTO |
|----------|---------------|-----------|-----|
| Single service (VW, HA, Paperless) | Restic REST on NAS | `restic restore latest` | 15 min |
| Docker VM failure | Restic REST + compose files | Rebuild VM, restore volumes | 2-4 hours |
| NAS failure | Google Drive + Forgejo | Rebuild Debian, restore from offsite | 4-8 hours |
| VPS failure | Local Headscale backup | Rebuild Vultr, restore config | 1 hour |
| Complete site failure | Google Drive (rclone crypt) | VPS first, then NAS, then Docker VM | 8-12 hours |
| Restic password lost | **UNRECOVERABLE** | AES-256, no backdoor | N/A |

**Full procedures:** [disaster-recovery.md](disaster-recovery.md)

**Backup verification:** [backup-test-procedure.md](../guides/backup-test-procedure.md)

**8TB recovery plan:** [8tb-recovery-plan-2026-03-12.md](../plans/8tb-recovery-plan-2026-03-12.md)

---

## Backup Scripts

All backup scripts live in `docker/shared/backup/`:

| Script | Used By | Purpose |
|--------|---------|---------|
| `restic-backup.sh` | VW, HA, Paperless, Coolify sidecars | Generic Restic backup with retention + integrity |
| `immich-db-backup.sh` | Immich sidecar | pg_dump → compress → Restic |
| `offsite-sync.sh` | offsite-sync container | rsync VPS + rclone to Google Drive |
| `backup-env.sh` | Manual | Collect .env files to `/opt/homelab/env-backup/` |

---

## Verification Schedule

| Frequency | Check | Method |
|-----------|-------|--------|
| Daily | Backup ran successfully | ntfy notifications (automatic) |
| Weekly | Restic integrity | `restic check` in backup script (automatic) |
| Monthly (1st Sunday) | Snapshot freshness | `restic snapshots` — verify recent entries |
| Monthly (1st Sunday) | Test restore | Restore VW, HA, Headscale to temp directory |
| Quarterly | Full restore drill | Restore service to test VM, verify functionality |

---

## References

- [Disaster Recovery Runbook](disaster-recovery.md)
- [Backup Test Procedure](../guides/backup-test-procedure.md)
- [8TB Recovery Plan](../plans/8tb-recovery-plan-2026-03-12.md)
- [NFS Setup Guide](../guides/nfs-setup.md)
- [Secrets Management](secrets-management.md)
