# 8TB WD Red Recovery Plan — 2026-03-12

## Status: Pending (requires home access)

## Background

On 2026-02-22, the 8TB WD Red Plus (WDC WD80EFBX-68AZZN0) suffered GPT partition table corruption caused by the Sabrent EC-DFLT USB enclosure's JMicron controller silently translating sector sizes (512e → 4096). Data was recovered via `losetup --sector-size 4096` and copied to the Purple drive. The 8TB drive remains in the NAS with no partition table and no mount.

## Current Drive Inventory

| Device | Model | Size | Mount | Status |
|--------|-------|------|-------|--------|
| sda | Lexar NQ100 SSD | 240GB | / (LVM) | Healthy — OS + Docker |
| sdb | WD Purple (WD23PURZ) | 2TB | /mnt/purple | **98% full** (1.7TB/1.8TB) |
| sdc | WD Red Plus (WD80EFBX) | 8TB | **unmounted** | No partition table — needs recovery |
| sdd | 512GB SSD | 476GB | **unmounted** | ext4 partition exists, not in fstab |
| sde | Generic Flash Disk | 3.7GB | /boot/efi, /boot | Boot USB (permanent) |

**Free SATA ports: 2** (ASUS P8H77-I has 4 SATA total, 2 occupied by sda + sdb)

Wait — sdc, sdd are also connected. The board may have more ports or sdd is via a different interface. Verify physical SATA topology when home.

## Available Spare Drives (at home)

| Drive | Size | Location | Interface |
|-------|------|----------|-----------|
| WD Red 3TB (#1) | 3TB | Sabrent USB dock | SATA |
| WD Red 3TB (#2) | 3TB | Spare | SATA |
| Old drive | 1TB | Spare | SATA |
| Old drive | 2TB | Spare | SATA |

## Recovered Data on Purple (`/mnt/purple/red-recovery/`)

| Directory | Size | Criticality | Replaceable? |
|-----------|------|-------------|-------------|
| `raidmain/videos/` | 45GB | **CRITICAL** | No — family home videos (weddings, birthdays, 2010-2013) |
| `raidmain/photos/` | 168GB | **CRITICAL** | No — family photos 2006-2014, multiple cameras |
| `home/` | 473GB | Medium | Mostly — old laptop backups (Andre, XPS) |
| `music/` | 346GB | Low | Yes — re-downloadable |
| `videos/` | 145GB | Low | Partially — BD rips, music videos |
| `scanner/` | 40MB | Medium | Physical originals exist |
| `etc/` | 8MB | Low | Old system configs |
| **Total**|**~1.5TB** | | |

### Critical irreplaceable data: 213GB (videos + photos)

## Purple Drive Space Crisis

```text
/dev/sdb1  1.8T  1.7T  45GB  98%  /mnt/purple
```

Breakdown:

- red-recovery: ~1.5TB
- frigate recordings: ~158GB
- restic backups: ~8KB (just initialized)
- **Free: 45GB**

Purple is nearly full. Frigate will stop recording when it runs out of space. This is the immediate problem.

---

## Recovery Plan (8TB Physically Healthy Scenario)

### Prerequisites

- Physical access to NAS (sudo password required)
- All critical services stopped or paused during disk operations
- Terminal session via SSH (not browser-based to avoid timeouts)

### Phase 1: Verify 8TB Drive Health

```bash
# Run SMART health check
sudo smartctl -a /dev/sdc

# Check for reallocated sectors, pending sectors, uncorrectable errors
sudo smartctl -A /dev/sdc | grep -E 'Reallocated|Current_Pending|Offline_Uncorrectable'

# If SMART looks clean, run extended self-test (~14 hours for 8TB)
sudo smartctl -t long /dev/sdc

# Check result after test completes
sudo smartctl -l selftest /dev/sdc
```

#### Decision point

- Reallocated_Sector_Ct > 0 OR Current_Pending_Sector > 0 → drive is degrading, go to "Failing Drive" plan
- All zeros + extended test passes → drive is healthy, continue to Phase 2

### Phase 2: Repartition 8TB Drive

```bash
# Verify there's no remaining data we missed
# Try the old losetup trick to check if more data exists
sudo losetup --sector-size 4096 -f --show /dev/sdc
# Mount read-only and compare with red-recovery
sudo mount -o ro /dev/loop0 /mnt/temp
# diff or ls to verify nothing was missed
sudo umount /mnt/temp
sudo losetup -d /dev/loop0

# Once confirmed all data is safe, create fresh partition table
sudo parted /dev/sdc mklabel gpt
sudo parted /dev/sdc mkpart primary ext4 0% 100%

# Create filesystem (ext4, optimized for large drive)
sudo mkfs.ext4 -L red8 -m 1 -T largefile4 /dev/sdc1
# -m 1: reserve only 1% for root (vs default 5% = 400GB wasted)
# -T largefile4: optimize inode ratio for media storage

# Create mount point and mount
sudo mkdir -p /mnt/red8
sudo mount /dev/sdc1 /mnt/red8
sudo chown augusto:augusto /mnt/red8
```

### Phase 3: Restore Data to 8TB

```bash
# Create directory structure
mkdir -p /mnt/red8/{media,downloads,data,sync,backup}

# Copy critical data FIRST (most important)
rsync -avh --progress /mnt/purple/red-recovery/raidmain/videos/ /mnt/red8/data/family-videos/
rsync -avh --progress /mnt/purple/red-recovery/raidmain/photos/ /mnt/red8/data/family-photos/

# Verify critical data integrity
diff -rq /mnt/purple/red-recovery/raidmain/videos/ /mnt/red8/data/family-videos/
diff -rq /mnt/purple/red-recovery/raidmain/photos/ /mnt/red8/data/family-photos/

# Copy remaining data
rsync -avh --progress /mnt/purple/red-recovery/home/ /mnt/red8/data/home-backup/
rsync -avh --progress /mnt/purple/red-recovery/music/ /mnt/red8/media/music/
rsync -avh --progress /mnt/purple/red-recovery/videos/ /mnt/red8/media/videos/
rsync -avh --progress /mnt/purple/red-recovery/scanner/ /mnt/red8/data/scanner/
```

### Phase 4: Add to fstab

```bash
# Get UUID
sudo blkid /dev/sdc1

# Add to /etc/fstab
echo 'UUID=<uuid-from-above>  /mnt/red8  ext4  defaults,noatime  0  2' | sudo tee -a /etc/fstab

# Test mount
sudo umount /mnt/red8
sudo mount -a
df -h /mnt/red8
```

### Phase 5: Recreate Symlinks

```bash
# Restore /srv/ symlinks (adjust paths to match new layout)
sudo ln -sfn /mnt/red8/media /srv/media
sudo ln -sfn /mnt/red8/downloads /srv/downloads
sudo ln -sfn /mnt/red8/data /srv/data
sudo ln -sfn /mnt/red8/sync /srv/sync
sudo ln -sfn /mnt/red8/backup /srv/backup
```

### Phase 6: Free Purple Drive

```bash
# ONLY after verifying all data is safely on the 8TB
# Double-check critical data exists on red8
ls -la /mnt/red8/data/family-videos/
ls -la /mnt/red8/data/family-photos/

# Remove recovery data from Purple
sudo rm -rf /mnt/purple/red-recovery/

# Verify Purple has space again
df -h /mnt/purple
# Should show ~1.5TB free (back to ~15% usage)
```

### Phase 7: Backup Critical Data (213GB)

The 512GB SSD (sdd) already in the NAS is perfect for this.

```bash
# Mount the 512GB SSD
sudo mkdir -p /mnt/backup-ssd
sudo mount /dev/sdd1 /mnt/backup-ssd

# Copy critical irreplaceable data
rsync -avh --progress /mnt/red8/data/family-videos/ /mnt/backup-ssd/family-videos/
rsync -avh --progress /mnt/red8/data/family-photos/ /mnt/backup-ssd/family-photos/

# Verify
diff -rq /mnt/red8/data/family-videos/ /mnt/backup-ssd/family-videos/
diff -rq /mnt/red8/data/family-photos/ /mnt/backup-ssd/family-photos/

# Add to fstab
echo 'UUID=<uuid>  /mnt/backup-ssd  ext4  defaults,noatime  0  2' | sudo tee -a /etc/fstab
```

This gives you **2 copies** of critical data (8TB + 512GB SSD) plus offsite via rclone to Google Drive.

### Phase 8: Restart Services

```bash
# Restart Docker containers that depend on /mnt/red8 or /srv/ paths
cd /opt/homelab/repo/docker/fixed/nas/storage && docker compose up -d
cd /opt/homelab/repo/docker/fixed/nas/backup && docker compose up -d

# Verify NFS exports if Docker VM mounts from NAS
sudo exportfs -ra

# On Docker VM: verify NFS mounts
ssh docker-vm "df -h /mnt/nas/*"
```

---

## Alternative: Failing Drive Plan

If SMART shows bad sectors or extended test fails:

1. **Do NOT write to the 8TB** — any writes risk further damage
2. Check if more data needs recovery via losetup (read-only)
3. Install 3TB drives in free SATA ports
4. Distribute data:
   - 512GB SSD (sdd): family videos (45GB) + photos (168GB) = 213GB
   - 3TB drive #1: home backups (473GB) + music (346GB) = 819GB
   - 3TB drive #2: videos (145GB) + service data + Restic target
5. Decommission 8TB or use as non-critical scratch space
6. Purchase replacement 8TB WD Red Plus when budget allows

---

## Post-Recovery Checklist

- [ ] SMART extended test passes on 8TB
- [ ] Fresh GPT + ext4 on 8TB
- [ ] All red-recovery data restored and verified (diff -rq)
- [ ] Critical data (213GB) duplicated to 512GB SSD
- [ ] Critical data synced to Google Drive via rclone
- [ ] Purple drive freed (should be ~15% used)
- [ ] Frigate recording unblocked
- [ ] fstab updated for both red8 and backup-ssd
- [ ] /srv/ symlinks recreated
- [ ] NAS Docker services restarted
- [ ] NFS exports verified from Docker VM
- [ ] Update MEMORY.md with new drive layout

## Estimated Time

- Phase 1 (SMART test): ~14 hours (run overnight)
- Phase 2 (repartition): ~10 minutes
- Phase 3 (restore 1.5TB): ~3-4 hours (SATA-to-SATA)
- Phase 4-6 (fstab, symlinks, cleanup): ~15 minutes
- Phase 7 (backup 213GB to SSD): ~30 minutes
- Phase 8 (restart services): ~15 minutes

#### Total active time: ~1 hour (plus overnight SMART test)
