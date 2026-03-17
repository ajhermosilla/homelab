# Red 8TB Data Recovery - 2026-02-22

WD Red 8TB (WDC WD80EFBX-68AZZN0) GPT partition table destroyed. Drive was used in a Sabrent USB-C 3.0 enclosure connected to MacBook Air M1 via Parallels and VMware Fusion (3 connections total). Now installed directly via SATA in the NAS (ASUS P8H77-I, i3-3220T).

## Drive Details

| Field | Value |
|-------|-------|

| Model | WDC WD80EFBX-68AZZN0 |
| Capacity | 8001 GB / 7452 GiB |
| Sectors | 15,628,053,168 (512-byte logical) |
| Sector Size | 512e (512 logical / 4096 physical) |
| Interface | SATA (now), was USB-C 3.0 via Sabrent enclosure |
| Device | /dev/sdc (NAS) |
| CHS | 972801 / 255 / 63 |

## Symptoms

- GPT partition table completely destroyed (primary + backup)
- Protective MBR remains (`PTTYPE="PMBR"`)
- No `/dev/sdc1` partition node
- `gdisk -l` shows: GPT not present, 15.6 billion sectors free
- `file -s -k` found stale GPT reference with 4096-byte sectors
- Primary ext4 superblock at byte 1080: zeros
- Backup ext4 superblocks not found at standard offsets
- TestDisk found "Linux filesys. data" signatures but couldn't reconstruct valid partitions (sector calculations exceeded disk boundaries)
- `grep` found `0x53EF` (ext4 magic) scattered across disk but not at standard superblock locations
- File data appears physically intact on disk

## Root Cause Analysis

### Most Likely: Sabrent USB Enclosure Sector Size Translation (HIGH probability)

The WD80EFBX is a **512e drive**(512-byte logical, 4096-byte physical). Sabrent USB enclosures with JMicron controllers are documented to**silently translate drives >2TB to report 4096-byte logical sectors** to the host OS.

- GPT partition tables use sector numbers for addresses
- If the sector size changes from 512 to 4096 (or vice versa), every address is off by 8x
- Both primary AND backup GPT get destroyed
- The filesystem data itself is untouched — only metadata is corrupted

This exactly matches the symptoms: GPT gone, backup GPT gone, but testdisk found Linux filesystem data.

#### Sources

- [Klennet: USB adapters silently change the sector size](https://www.klennet.com/notes/2018-04-14-usb-and-sector-size.aspx) — "Partition tables use physical sector size to compute addresses. Changing the physical sector size invalidates partition tables."
- [Sabrent Community: EC-DFLT 4096 Bytes sector problem](https://sabrent.com/community/xenforum/topic/88640/ec-dflt-4096-bytes-sector-problem-firmware-update) — JMicron controller "changes the reported size for drives >2TB back to 4096 Bytes." Firmware update available but must be requested from Sabrent support.
- [Level1Techs: PSA don't change sector size of external USB WD drives](https://forum.level1techs.com/t/psa-dont-change-sector-size-of-external-usb-wd-drives/191317) — "Changing sector sizes will most likely brick your drive."
- [Ubuntu Forums: GPT Lost changing from USB3 to SATA](https://ubuntuforums.org/showthread.php?t=2489422) — Documented case of GPT destruction when USB interface translates logical sector size.
- [Arch Linux Forums: GPT partitions gone (solved)](https://bbs.archlinux.org/viewtopic.php?id=188873), [GPT detected or not depending on access method (solved)](https://bbs.archlinux.org/viewtopic.php?id=174501) — Multiple confirmed cases.
- [Windows 10 Forums: GPT HDD after enclosure change (solved)](https://www.tenforums.com/drivers-hardware/174989-gpt-hdd-cannot-modify-partitions-read-data-after-enclosure-change.html)

### Contributing: VM Hypervisor Conflicts (MODERATE-HIGH probability)

Multiple factors from using Parallels and VMware Fusion on the same USB disk:

- **Parallels caches partition tables** — stores copies in `PhysicalMbr.hds`, `PhysicalGpt.hds`, `PhysicalGptCopy.hds`. Cached version can diverge from reality and be written back. ([GitHub Gist](https://gist.github.com/Obbut/b0a94d96bf2a8069f1c470696ab7f9f2))
- **Parallels auto-unmounts non-native volumes** — `prl_disp_service` daemon unmounts ext4 volumes upon detection. ([Paragon KB](https://kb.paragon-software.com/article/2891))
- **Parallels destroyed EFI partition** — documented case where Parallels 15 wiped EFI partition during Boot Camp VM restart. ([Parallels Forum](https://forum.parallels.com/threads/parallels-15-destroyed-efi-partition.347732/))
- **VMware Fusion raw disk sync issues** — VMware requires `suspend.disabled = "TRUE"` to prevent sync issues. ([Broadcom KB](https://knowledge.broadcom.com/external/article/341099/creating-a-raw-disk-vmdk-and-adding-it-t.html))
- **Multiple VMs = unsynchronized disk access** — each VM kernel has its own filesystem driver; no coordination between Parallels and VMware Fusion. ([QubesOS Issue #6396](https://github.com/QubesOS/qubes-issues/issues/6396), [Red Hat docs](https://docs.redhat.com/en/documentation/red_hat_virtualization/4.4/html/administration_guide/chap-virtual_machine_disks))

### Contributing: macOS Disk Arbitration (MODERATE probability)

- macOS `diskarbitrationd` probes USB disks on connect and shows "Initialize" dialog for unrecognized (ext4) filesystems — one accidental click creates a new partition scheme. ([Jeff Geerling](https://www.jeffgeerling.com/blog/2024/mounting-ext4-linux-usb-drive-on-macos-2024))
- Prior to macOS 10.13, Disk Utility automatically created hybrid MBRs on GPT disks with non-HFS+ partitions. ([macOS Disk Utility details](https://ericfromcanada.github.io/output/2019/disk-utility-partitioning-details.html))
- macOS Sonoma has documented external disk handling bugs. ([MacRumors](https://forums.macrumors.com/threads/corrupted-partition-table-from-sonoma.2425777/), [AppleInsider](https://forums.appleinsider.com/discussion/235967/external-drive-support-in-macos-sonoma-is-partially-broken-and-its-probably-apples-faul))

### Probability Summary

| Rank | Cause | Probability |
|------|-------|-------------|

| 1 | Sabrent enclosure sector size translation (512e -> 4096) misaligning GPT writes | **High** |
| 2 | Multiple VMs (Parallels + VMware Fusion) with unsynchronized disk access | **Moderate-High** |
| 3 | macOS disk arbitration writing stale/incorrect metadata during VM handoff | **Moderate** |
| 4 | Parallels caching and writing back stale GPT copies | **Moderate** |
| 5 | macOS Sonoma external disk handling bug | **Low-Moderate** |

### Conclusion

Most probable scenario: the Sabrent enclosure's sector size translation caused the GPT to be written at wrong byte offsets, and having multiple VMs across two different hypervisors amplified the damage by writing conflicting partition table data through an already-broken sector size abstraction layer.

---

## Recovery Log

### Step 1: Initial Assessment (2026-02-21)

Ran during NAS deployment. Drive connected via SATA as `/dev/sdc`.

```bash
$ lsblk -f /dev/sdc
NAME FSTYPE FSVER LABEL UUID FSAVAIL FSUSE% MOUNTPOINTS
sdc

$ sudo parted /dev/sdc print
# GPT PMBR size mismatch, partition table unrecognizable
```

### Step 2: TestDisk Full Scan (2026-02-21 to 2026-02-22)

TestDisk 7.2 full disk analysis. Ran for ~12 hours on the 8TB drive.

```text
Disk /dev/sdc - 8001 GB / 7452 GiB - CHS 972801 255 63

The hard disk (8001 GB / 7452 GiB) seems too small! (< 9831486 TB / 8941685 TiB)

The following partitions can't be recovered:
     Partition               Start        End    Size in sectors
>  BeFS                  2707132674 14638170357993729 14638167650861056
   Linux filesys. data   7809335318 23437304621 15627969304
   Linux filesys. data   7809335320 23437304623 15627969304
   Linux filesys. data   7809859598 23437828901 15627969304
   Linux filesys. data   7809859600 23437828903 15627969304
   Linux filesys. data   7810121736 23438091039 15627969304
   Linux filesys. data   7810127544 23438096847 15627969304
   Linux filesys. data   7810134192 23438103495 15627969304
   Linux filesys. data   7810134240 23438103543 15627969304
   Linux filesys. data   7810292432 23438261735 15627969304
```

**Analysis:** All "Linux filesys. data" entries have size ~15.6 billion sectors (~8TB), matching the disk. But start/end sectors exceed disk boundaries — consistent with testdisk using 512-byte sector math on data originally written with 4096-byte sector addressing. The BeFS entry is a false positive (garbage data interpreted as Be File System).

### Step 3: Filesystem Signature Search (2026-02-22)

```bash
$ sudo file -s /dev/sdc
/dev/sdc: DOS/MBR boot sector; partition 1 : ID=0xee, start-CHS (0x0,0,1),
end-CHS (0x3ff,254,63), startsector 1, 1953506645 sectors, extended partition
table (last)

$ sudo file -s -k /dev/sdc -b
# Found stale GPT reference:
# GPT partition table, version 1.0, GUID: a3f965ea-bc79-442e-b5e3-9f74f1357cd1,
# disk size: 1953506646 sectors of 4096 bytes

$ sudo blkid /dev/sdc
/dev/sdc: PTTYPE="PMBR"

$ sudo gdisk -l /dev/sdc
# GPT: not present
# Sector size (logical/physical): 512/4096 bytes
# Total free space is 15628053101 sectors (7.3 TiB)
```

**Key finding:**`file -s -k` found a stale GPT header referencing**1,953,506,646 sectors of 4096 bytes**. But `gdisk` reads the drive as **15,628,053,168 sectors of 512 bytes**. These are the same total capacity (8TB) expressed in different sector sizes. This confirms the **sector size translation** theory — the GPT was written when the enclosure reported 4096-byte sectors.

### Step 4: Superblock Search (2026-02-22)

```bash
# Primary superblock (byte 1080) — zeros
$ sudo hexdump -C -s 1080 -n 2 /dev/sdc
00000438  00 00

# Standard GPT partition start + superblock (byte 1049600) — zeros
$ sudo hexdump -C -s 1049600 -n 2 /dev/sdc
00100400  00 00

# 4K-sector partition start + superblock (byte 8389632) — zeros
$ sudo hexdump -C -s 8389632 -n 128 /dev/sdc
00800400  00 00 00 00 ...

# Brute-force search for ext4 magic (0x53EF) — found scattered hits
$ sudo grep -boa -P '\x53\xef' /dev/sdc | head -20
190809374:...
235147320:...
269330892:...
# (none at standard superblock offsets)
```

**Analysis:** No ext4 superblock at any standard offset. The scattered `0x53EF` matches are within file data, not superblock copies. This suggests either:

- The ext4 superblock was at a non-standard offset (due to 4096-byte sector addressing during format)
- The superblock area was overwritten by the corrupted GPT writes

### Step 5: Sector Size Verification (2026-02-22)

```bash
$ sudo lsblk -o NAME,PHY-SEC,LOG-SEC /dev/sdc
NAME PHY-SEC LOG-SEC
sdc     4096     512
```

Confirmed: 512e drive (512 logical / 4096 physical) via SATA. The Sabrent enclosure had been reporting 4096-byte logical sectors, causing the sector size mismatch.

### Step 6: GPT Header Discovery (2026-02-22)

Key insight: if the GPT was written with 4096-byte sectors, the GPT header is at **byte 4096**(LBA 1* 4096), not byte 512 (where `gdisk` looks with 512-byte sectors).

```bash
$ sudo hexdump -C -s 4096 -n 128 /dev/sdc
00001000  45 46 49 20 50 41 52 54  00 00 01 00 5c 00 00 00  |EFI PART....\...|
```

**GPT header found intact at byte 4096!** Also found partition entry at byte 8192 — Linux filesystem partition named "primary".

### Step 7: Loop Device with Correct Sector Size (2026-02-22)

Created a loop device presenting the disk with 4096-byte sectors so tools read the GPT natively:

```bash
$ sudo losetup --sector-size 4096 -r /dev/loop0 /dev/sdc
$ sudo gdisk -l /dev/loop0
GPT fdisk (gdisk) version 1.0.10

Partition table scan:
  MBR: protective
  BSD: not present
  APM: not present
  GPT: present

Found valid GPT with protective MBR; using GPT.
Disk /dev/loop0: 1953506646 sectors, 7.3 TiB
Sector size (logical/physical): 4096/4096 bytes
Disk identifier (GUID): A3F965EA-BC79-442E-B5E3-9F74F1357CD1

Number  Start (sector)    End (sector)  Size       Code  Name
   1            8191      1953504353   7.3 TiB     8300  primary
```

#### GPT is fully intact when read with correct sector size

### Step 8: Filesystem Recovery — SUCCESS (2026-02-22)

```bash
$ sudo partprobe /dev/loop0
$ sudo blkid /dev/loop0p1
/dev/loop0p1: UUID="d42d005e-d53e-4224-b93d-7a9467e11174" BLOCK_SIZE="4096"
TYPE="ext4" PARTLABEL="primary" PARTUUID="ed37e2fd-2fb9-47d3-952e-33826a1f9455"

$ sudo mount -o ro /dev/loop0p1 /mnt/red8
$ ls /mnt/red8
Data  lost+found

$ ls -la /mnt/red8/Data/
drwxrwxr-x   2 augusto augusto  4096 Oct  8 08:04 backup
drwxr-xr-x 126 root    root    12288 Sep 15  2021 etc
drwxr-xr-x   4 root    root     4096 Nov 22  2020 home
drwxr-xr-x  15 root    root     4096 Sep 14  2021 storage
```

**ALL DATA RECOVERED.** Filesystem intact, all directories and files accessible.

### Step 9: Data Inventory (2026-02-22)

```bash
$ du -sh /mnt/red8/Data
5.2T    /mnt/red8/Data

$ sudo du -sh /mnt/red8/Data/*/ | sort -rh
4.8T    /mnt/red8/Data/storage/
473G    /mnt/red8/Data/home/
7.9M    /mnt/red8/Data/etc/
4.0K    /mnt/red8/Data/backup/

$ sudo du -sh /mnt/red8/Data/storage/*/ | sort -rh
2.6T    /mnt/red8/Data/storage/movies/
799G    /mnt/red8/Data/storage/disco2TB/
575G    /mnt/red8/Data/storage/raidmain/
346G    /mnt/red8/Data/storage/music/
327G    /mnt/red8/Data/storage/games/
145G    /mnt/red8/Data/storage/videos/
26G     /mnt/red8/Data/storage/unprotected/
19G     /mnt/red8/Data/storage/tvshows/
9.3G    /mnt/red8/Data/storage/temporal/
40M     /mnt/red8/Data/storage/scanner/
```

### Step 10: Critical Data Backup to Purple (2026-02-22)

Copying critical data to `/mnt/purple/red-recovery/` before reformatting Red.
Purple has 1.7TB free, selected ~1.2TB of critical data:

| Directory | Size | Priority |
|-----------|------|----------|

| etc/ | 7.9M | Critical — old system configs |
| scanner/ | 40M | Critical — scanned documents |
| videos/ | 145G | Critical — family memories |
| home/ | 473G | Critical — personal files |
| raidmain/ | 575G | Medium — if space allows |

Skipped (re-downloadable or low priority): movies (2.6T), games (327G), music (346G), disco2TB (799G).

```bash
sudo rsync -a --info=progress2 /mnt/red8/Data/etc/ /mnt/purple/red-recovery/etc/
sudo rsync -a --info=progress2 /mnt/red8/Data/storage/scanner/ /mnt/purple/red-recovery/scanner/
sudo rsync -a --info=progress2 /mnt/red8/Data/storage/videos/ /mnt/purple/red-recovery/videos/
sudo rsync -a --info=progress2 /mnt/red8/Data/home/ /mnt/purple/red-recovery/home/
sudo rsync -a --info=progress2 /mnt/red8/Data/storage/raidmain/ /mnt/purple/red-recovery/raidmain/
```

**STATUS:** IN PROGRESS

### Next Steps (after backup completes)

1. Verify backup integrity
2. Unmount Red: `sudo umount /mnt/red8`
3. Destroy loop devices: `sudo losetup -d /dev/loop0`
4. Reformat Red 8TB with clean GPT via SATA (correct 512-byte sector addressing)
5. Move data back to freshly formatted Red drive
6. Set up /srv symlinks and continue NAS deployment

---

## Lessons Learned

1. **Never use USB enclosures for drives >2TB with Linux filesystems** — JMicron controllers silently change sector sizes
2. **Never pass USB storage through multiple VM hypervisors** — unsynchronized access corrupts metadata
3. **Always click "Ignore" on macOS "Initialize disk" dialogs** for Linux-formatted drives
4. **Keep partition table backups** — `sgdisk --backup=table.gpt /dev/sdX` before risky operations
5. **Use SATA directly** for Linux server drives — no translation layer, no surprises
