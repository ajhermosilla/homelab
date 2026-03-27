# 8TB Full Recovery Plan — 2026-03-26 (Holy Week Edition)

> **Status**: Ready to execute. 8TB mounted read-only, SMART passed, Google Drive uploads in progress.
> **Timeline**: 2-3 days across Holy Week (mostly waiting for copies)
> **Risk**: LOW — all operations are read-only until final repartition step

## Current State

| Drive | Size | Mount | Status |
|-------|------|-------|--------|
| sda | 240 GB SSD | / (LVM) | OS + Docker — healthy |
| sdb | 8 TB WD Red | /mnt/red8 (losetup, ro) | Mounted read-only, SMART passed, 5.3 TB data |
| sdc | 2 TB Purple | /mnt/purple | 97% full — frigate + restic + red-recovery |
| sdd | 512 GB SSD | /mnt/test | 100% full — old Linux/Mac/music backups |
| sde | 4 GB USB | /boot | Boot drive |

## Data Inventory (8TB)

| Data | Size | Irreplaceable? | Current Backup | Action |
|------|------|---------------|----------------|--------|
| raidmain/photos | 168 GB | Yes | Purple + Google Drive | Already safe |
| raidmain/videos | 45 GB | Yes | Purple + Google Drive | Already safe |
| raidmain/archive (thesis, old backups) | 121 GB | Partially | Purple (thesis only) | Upload to Google Drive |
| disco2tb/augusto/Documents + Pictures | 125 GB | Partially | Uploading to Google Drive now | Wait for completion |
| movies | 2.6 TB | Re-downloadable but months of curation | None | Copy to 3TB Red #1 |
| music | 346 GB | Re-downloadable | On Purple + 512GB SSD | Copy to 3TB Red #2 |
| games | 327 GB | Re-downloadable but curated | None | Copy to 3TB Red #2 |
| tvshows | 19 GB | Re-downloadable | None | Copy to 3TB Red #2 |
| videos (BD rips) | 145 GB | Partially re-rippable | On Purple | Copy to 3TB Red #2 |
| home (old laptop backups) | 473 GB | Partially | On Purple | Already safe |
| disco2tb/Data/storage | 459 GB | Unknown | None | Copy to 3TB Red #2 |
| **Total** | **~5.3 TB** | | | |

---

## Phase 0 — Wait for Google Drive Uploads (no action needed)

Two uploads must complete before repartitioning:

| Upload | Size | Status | ETA |
|--------|------|--------|-----|
| disco2tb/augusto/Documents + Pictures | ~125 GB | Running | ~7h from start |
| raidmain/archive (thesis + old backups) | ~121 GB | Queue after above | ~7h |

**Check disco2tb upload:**

```bash
docker logs disco2tb-backup 2>&1 | tail -10
```

**After disco2tb completes, start archive upload:**

```bash
docker rm disco2tb-backup
docker run -d --name archive-backup \
  -v rclone-config:/config/rclone \
  -v "/mnt/red8/Data/storage/raidmain/archive:/data/archive:ro" \
  rclone/rclone:1.73.2 \
  copy /data gdrive-crypt:family/raidmain-archive \
  --config /config/rclone/rclone.conf \
  --transfers 2 \
  --bwlimit 5M \
  --stats 5m \
  --stats-log-level NOTICE
```

**Check archive upload:**

```bash
docker logs archive-backup 2>&1 | tail -10
```

**Do NOT proceed to Phase 1 until both uploads show 100% complete with exit code 0.**

---

## Phase 1 — Install 3TB Drives (30 min, requires NAS shutdown)

### 1.1 Preparation

```bash
# Stop all NAS containers gracefully
ssh nas "cd /opt/homelab/repo/docker/fixed/nas/git && docker compose down"
ssh nas "cd /opt/homelab/repo/docker/fixed/nas/storage && docker compose down"
ssh nas "cd /opt/homelab/repo/docker/fixed/nas/backup && docker compose down"
ssh nas "cd /opt/homelab/repo/docker/fixed/nas/monitoring && docker compose down"
# Coolify: cd /data/coolify/source && docker compose down

# Unmount 8TB loop device
ssh nas "sudo umount /mnt/red8 && sudo losetup -d /dev/loop0"

# Shutdown NAS
ssh nas "sudo shutdown now"
```

### 1.2 Physical Installation

1. Unplug NAS power
2. Open case
3. Connect 3TB WD Red #1 to free SATA port + power
4. Connect 3TB WD Red #2 to free SATA port + power
5. Close case
6. Power on NAS
7. Wait for boot (~2 min)

### 1.3 Verify Drives Detected

```bash
ssh nas
lsblk -o NAME,SIZE,TYPE,MODEL
```

Expected: two new drives (~2.7 TB each) appearing as sdf, sdg or similar.

### 1.4 Check Drive Health

```bash
sudo smartctl -H /dev/sdX  # replace X with new drive letters
sudo smartctl -H /dev/sdY
```

Both should show "PASSED".

---

## Phase 2 — Format and Mount 3TB Drives (15 min)

### 2.1 Partition and Format

```bash
# Drive #1 (movies)
sudo parted /dev/sdX mklabel gpt
sudo parted /dev/sdX mkpart primary ext4 0% 100%
sudo mkfs.ext4 -L media-movies -m 1 /dev/sdX1

# Drive #2 (everything else)
sudo parted /dev/sdY mklabel gpt
sudo parted /dev/sdY mkpart primary ext4 0% 100%
sudo mkfs.ext4 -L media-misc -m 1 /dev/sdY1
```

### 2.2 Create Mount Points and Mount

```bash
sudo mkdir -p /mnt/media-movies /mnt/media-misc
sudo mount /dev/sdX1 /mnt/media-movies
sudo mount /dev/sdY1 /mnt/media-misc
sudo chown augusto:augusto /mnt/media-movies /mnt/media-misc
```

### 2.3 Add to fstab

```bash
# Get UUIDs
sudo blkid /dev/sdX1 /dev/sdY1

# Add to fstab (replace UUIDs)
echo 'UUID=<uuid-drive1>  /mnt/media-movies  ext4  defaults,noatime,nofail  0  2' | sudo tee -a /etc/fstab
echo 'UUID=<uuid-drive2>  /mnt/media-misc    ext4  defaults,noatime,nofail  0  2' | sudo tee -a /etc/fstab

# Verify
sudo umount /mnt/media-movies /mnt/media-misc
sudo mount -a
df -h /mnt/media-movies /mnt/media-misc
```

---

## Phase 3 — Remount 8TB and Copy Media (8-10 hours)

### 3.1 Remount 8TB Read-Only

```bash
sudo losetup --sector-size 4096 -f --show /dev/sdb
sudo partprobe /dev/loop0
sudo mount -o ro /dev/loop0p1 /mnt/red8
```

### 3.2 Copy Movies to 3TB #1

```bash
# Movies: 2.6 TB → 3TB drive
nohup rsync -avh --progress /mnt/red8/Data/storage/movies/ /mnt/media-movies/movies/ > /tmp/copy-movies.log 2>&1 &

# Monitor progress
tail -f /tmp/copy-movies.log
```

ETA: ~7 hours at ~100 MB/s SATA-to-SATA.

### 3.3 Copy Everything Else to 3TB #2

```bash
# Music: 346 GB
rsync -avh --progress /mnt/red8/Data/storage/music/ /mnt/media-misc/music/

# Games: 327 GB
rsync -avh --progress /mnt/red8/Data/storage/games/ /mnt/media-misc/games/

# TV Shows: 19 GB
rsync -avh --progress /mnt/red8/Data/storage/tvshows/ /mnt/media-misc/tvshows/

# Videos (BD rips): 145 GB
rsync -avh --progress /mnt/red8/Data/storage/videos/ /mnt/media-misc/videos/

# disco2TB/Data/storage: 459 GB
rsync -avh --progress /mnt/red8/Data/storage/disco2TB/Data/storage/ /mnt/media-misc/disco2tb-storage/
```

Or run all in one nohup:

```bash
nohup sh -c '
rsync -avh /mnt/red8/Data/storage/music/ /mnt/media-misc/music/ &&
rsync -avh /mnt/red8/Data/storage/games/ /mnt/media-misc/games/ &&
rsync -avh /mnt/red8/Data/storage/tvshows/ /mnt/media-misc/tvshows/ &&
rsync -avh /mnt/red8/Data/storage/videos/ /mnt/media-misc/videos/ &&
rsync -avh /mnt/red8/Data/storage/disco2TB/Data/storage/ /mnt/media-misc/disco2tb-storage/
' > /tmp/copy-misc.log 2>&1 &

# Monitor
tail -f /tmp/copy-misc.log
```

ETA: ~3-4 hours for ~1.3 TB.

### 3.4 Verify Copies

```bash
# Check sizes match
echo "=== Movies ===" && command du -sh /mnt/media-movies/movies/ && command du -sh /mnt/red8/Data/storage/movies/
echo "=== Music ===" && command du -sh /mnt/media-misc/music/ && command du -sh /mnt/red8/Data/storage/music/
echo "=== Games ===" && command du -sh /mnt/media-misc/games/ && command du -sh /mnt/red8/Data/storage/games/
```

---

## Phase 4 — Repartition 8TB (10 min)

**DO NOT proceed until:**

- [ ] Google Drive uploads completed (disco2tb + archive)
- [ ] 3TB drives have all media copied and verified
- [ ] Thesis confirmed on Purple (/mnt/purple/thesis-vrptw-2006)
- [ ] raidmain/photos + videos confirmed on Google Drive

### 4.1 Unmount and Repartition

```bash
sudo umount /mnt/red8
sudo losetup -d /dev/loop0

# Create fresh partition table
sudo parted /dev/sdb mklabel gpt
sudo parted /dev/sdb mkpart primary ext4 0% 100%

# Format (optimized for large files)
sudo mkfs.ext4 -L red8 -m 1 -T largefile4 /dev/sdb1

# Mount
sudo mkdir -p /mnt/red8
sudo mount /dev/sdb1 /mnt/red8
sudo chown augusto:augusto /mnt/red8
```

### 4.2 Create Directory Structure

```bash
mkdir -p /mnt/red8/{media,downloads,data,sync,backup}
mkdir -p /mnt/red8/data/{family-photos,family-videos}
```

### 4.3 Add to fstab

```bash
sudo blkid /dev/sdb1
echo 'UUID=<uuid>  /mnt/red8  ext4  defaults,noatime  0  2' | sudo tee -a /etc/fstab
```

---

## Phase 5 — Restore Critical Data to 8TB (4-5 hours)

### 5.1 Critical Data First

```bash
# Family photos (168 GB)
rsync -avh --progress /mnt/purple/red-recovery/raidmain/photos/ /mnt/red8/data/family-photos/

# Family videos (45 GB)
rsync -avh --progress /mnt/purple/red-recovery/raidmain/videos/ /mnt/red8/data/family-videos/

# Thesis
rsync -avh --progress /mnt/purple/thesis-vrptw-2006/ /mnt/red8/data/thesis-vrptw-2006/
```

### 5.2 Verify Critical Data

```bash
diff -rq /mnt/purple/red-recovery/raidmain/photos/ /mnt/red8/data/family-photos/
diff -rq /mnt/purple/red-recovery/raidmain/videos/ /mnt/red8/data/family-videos/
```

### 5.3 Remaining Data

```bash
# Home backups (473 GB)
rsync -avh --progress /mnt/purple/red-recovery/home/ /mnt/red8/data/home-backup/

# Scanner
rsync -avh --progress /mnt/purple/red-recovery/scanner/ /mnt/red8/data/scanner/
```

---

## Phase 6 — Free Purple Drive (5 min)

**ONLY after verifying all data on 8TB:**

```bash
# Double check
ls /mnt/red8/data/family-photos/ | wc -l
ls /mnt/red8/data/family-videos/ | wc -l

# Remove recovery data from Purple
sudo rm -rf /mnt/purple/red-recovery/

# Verify space freed
df -h /mnt/purple
# Should show ~85% free (from 97%)
```

---

## Phase 7 — Backup Critical Data to 512GB SSD (30 min)

The 512GB SSD (sdd) is currently full with old data. Wipe and use for critical backup:

```bash
# Wipe SSD
sudo umount /mnt/test
sudo mkfs.ext4 -L backup-ssd /dev/sdd1
sudo mkdir -p /mnt/backup-ssd
sudo mount /dev/sdd1 /mnt/backup-ssd
sudo chown augusto:augusto /mnt/backup-ssd

# Copy critical irreplaceable data
rsync -avh --progress /mnt/red8/data/family-photos/ /mnt/backup-ssd/family-photos/
rsync -avh --progress /mnt/red8/data/family-videos/ /mnt/backup-ssd/family-videos/
rsync -avh --progress /mnt/red8/data/thesis-vrptw-2006/ /mnt/backup-ssd/thesis-vrptw-2006/

# Verify
diff -rq /mnt/red8/data/family-photos/ /mnt/backup-ssd/family-photos/
diff -rq /mnt/red8/data/family-videos/ /mnt/backup-ssd/family-videos/

# Add to fstab
echo 'UUID=<uuid>  /mnt/backup-ssd  ext4  defaults,noatime,nofail  0  2' | sudo tee -a /etc/fstab
```

---

## Phase 8 — Create Symlinks and Restart Services (15 min)

```bash
# Create /srv symlinks
sudo ln -sfn /mnt/red8/media /srv/media
sudo ln -sfn /mnt/red8/downloads /srv/downloads
sudo ln -sfn /mnt/red8/data /srv/data
sudo ln -sfn /mnt/red8/sync /srv/sync
sudo ln -sfn /mnt/red8/backup /srv/backup

# Restart NAS Docker services
cd /opt/homelab/repo/docker/fixed/nas/storage && docker compose up -d
cd /opt/homelab/repo/docker/fixed/nas/backup && docker compose up -d
cd /opt/homelab/repo/docker/fixed/nas/git && docker compose up -d
cd /opt/homelab/repo/docker/fixed/nas/monitoring && docker compose up -d

# Restart NFS exports (if configured)
sudo exportfs -ra

# On Docker VM: verify NFS mounts
ssh docker-vm "df -h /mnt/nas/*"
```

---

## Final State

| Drive | Mount | Contents | Size Used |
|-------|-------|----------|-----------|
| sda (240G SSD) | / | OS + Docker | ~30 GB |
| sdb (8TB Red) | /mnt/red8 | Primary storage: family data, downloads, sync, backups | ~700 GB initially |
| sdc (2TB Purple) | /mnt/purple | Frigate recordings + Restic repos | ~200 GB (freed from 97%) |
| sdd (512G SSD) | /mnt/backup-ssd | Critical data backup (photos, videos, thesis) | ~215 GB |
| sdX (3TB Red #1) | /mnt/media-movies | Movies archive | ~2.6 TB |
| sdY (3TB Red #2) | /mnt/media-misc | Music, games, tvshows, videos, disco2tb | ~1.3 TB |
| sde (4G USB) | /boot | Boot | ~100 MB |

**3-2-1 for critical data:**

- Copy 1: 8TB Red (/mnt/red8/data/)
- Copy 2: 512GB SSD (/mnt/backup-ssd/)
- Copy 3: Google Drive (gdrive-crypt:family/)

---

## Execution Schedule (Holy Week)

| Day | Phase | Time | Active Work |
|-----|-------|------|-------------|
| Wed evening | Phase 0 | — | Check uploads, start archive upload |
| Thu morning | Phase 0 | — | Verify both uploads complete |
| Thu afternoon | Phase 1 | 30 min | Install 3TB drives, reboot NAS |
| Thu afternoon | Phase 2 | 15 min | Format, mount, fstab |
| Thu evening | Phase 3 | Start rsync | Kick off movies + misc copies, run overnight |
| Fri morning | Phase 3 | — | Verify copies complete |
| Fri afternoon | Phase 4 | 10 min | Repartition 8TB |
| Fri afternoon | Phase 5 | Start rsync | Restore critical data to 8TB |
| Fri evening | Phase 6 | 5 min | Free Purple drive |
| Fri evening | Phase 7 | 30 min | Backup to SSD |
| Sat morning | Phase 8 | 15 min | Symlinks, restart services |

**Total active work: ~2 hours.** Most time is waiting for rsync.

---

## Rollback Plan

**If 3TB drives fail or aren't detected:**

- Skip Phase 1-3, proceed directly to Phase 4 (repartition 8TB)
- Accept loss of re-downloadable media (movies, games, music)
- Critical data is safe on Google Drive

**If 8TB repartition fails:**

- Drive is still readable via losetup (current method)
- All important data already on Google Drive + Purple

**If anything feels wrong:**

- STOP. The 8TB is mounted read-only — nothing can be lost.
- All critical data has offsite copies on Google Drive.

---

## Pre-Flight Checklist

- [ ] disco2tb Google Drive upload complete
- [ ] raidmain/archive Google Drive upload complete
- [ ] Thesis on Purple (/mnt/purple/thesis-vrptw-2006) verified
- [ ] 3TB WD Red drives physically available
- [ ] SATA cables available (2 needed)
- [ ] NAS case can be opened
- [ ] No family streaming/gaming during NAS shutdown phases
